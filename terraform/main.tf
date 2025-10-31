terraform {
  required_version = ">= 1.0"  # Works with both Terraform >= 1.0 and OpenTofu >= 1.6

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Package Lambda function
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda"
  output_path = "${path.module}/lambda_deployment.zip"
}

# Lambda function
resource "aws_lambda_function" "chat_topic" {
  filename         = data.archive_file.lambda.output_path
  function_name    = var.function_name
  role            = aws_iam_role.lambda_role.arn
  handler         = "main.handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime         = "python3.12"
  timeout         = 120

  environment {
    variables = {
      PD_API_KEY_NAME    = aws_ssm_parameter.pd_key.name
      SLACK_API_KEY_NAME = aws_ssm_parameter.slack_key.name
      CONFIG_TABLE       = aws_dynamodb_table.config.name
    }
  }

  tags = {
    Name        = var.function_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = var.function_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# DynamoDB table for configuration
resource "aws_dynamodb_table" "config" {
  name         = "${var.function_name}-config"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "schedule"

  attribute {
    name = "schedule"
    type = "S"
  }

  ttl {
    attribute_name = "expiretime"
    enabled        = true
  }

  tags = {
    Name        = "${var.function_name}-config"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# EventBridge rule to trigger Lambda every 5 minutes
resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${var.function_name}-schedule"
  description         = "Trigger ${var.function_name} every 5 minutes"
  schedule_expression = "rate(5 minutes)"

  tags = {
    Name        = "${var.function_name}-schedule"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "lambda"
  arn       = aws_lambda_function.chat_topic.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chat_topic.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}

# SSM parameters for API keys
resource "aws_ssm_parameter" "pd_key" {
  name        = var.pd_ssm_key_name
  description = "PagerDuty API key for ${var.function_name}"
  type        = "SecureString"
  value       = var.pagerduty_api_key

  tags = {
    Name        = var.pd_ssm_key_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "slack_key" {
  name        = var.slack_ssm_key_name
  description = "Slack API key for ${var.function_name}"
  type        = "SecureString"
  value       = var.slack_api_key

  tags = {
    Name        = var.slack_ssm_key_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  lifecycle {
    ignore_changes = [value]
  }
}
