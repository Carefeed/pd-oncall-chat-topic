output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.chat_topic.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.chat_topic.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB configuration table"
  value       = aws_dynamodb_table.config.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB configuration table"
  value       = aws_dynamodb_table.config.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for Lambda function"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "schedule_rule_arn" {
  description = "ARN of the EventBridge schedule rule"
  value       = aws_cloudwatch_event_rule.schedule.arn
}

output "pd_ssm_parameter_name" {
  description = "SSM parameter name for PagerDuty API key"
  value       = aws_ssm_parameter.pd_key.name
}

output "slack_ssm_parameter_name" {
  description = "SSM parameter name for Slack API key"
  value       = aws_ssm_parameter.slack_key.name
}
