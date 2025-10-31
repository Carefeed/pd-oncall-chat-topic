# IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name               = "${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Name        = "${var.function_name}-role"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Attach AWS managed policy for basic Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for SSM, KMS, and DynamoDB access
resource "aws_iam_role_policy" "lambda_custom_policy" {
  name   = "${var.function_name}-policy"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_custom_policy.json
}

data "aws_iam_policy_document" "lambda_custom_policy" {
  # SSM parameter access
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters"
    ]
    resources = [
      aws_ssm_parameter.pd_key.arn,
      aws_ssm_parameter.slack_key.arn
    ]
  }

  # KMS decrypt for SSM parameters
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = [data.aws_kms_key.ssm.arn]
  }

  # DynamoDB scan access
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:Scan"
    ]
    resources = [aws_dynamodb_table.config.arn]
  }
}

# Get the default SSM KMS key
data "aws_kms_key" "ssm" {
  key_id = "alias/aws/ssm"
}
