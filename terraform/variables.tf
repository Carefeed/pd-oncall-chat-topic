variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-2"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "staging-developers"
}

variable "environment" {
  description = "Environment name (e.g., staging, production)"
  type        = string
  default     = "staging"
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "pagerduty-oncall-chat-topic"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "pd_ssm_key_name" {
  description = "SSM parameter name for PagerDuty API key"
  type        = string
  default     = "pagerduty-oncall-chat-topic"
}

variable "slack_ssm_key_name" {
  description = "SSM parameter name for Slack API key"
  type        = string
  default     = "pagerduty-oncall-chat-topic-slack"
}

variable "pagerduty_api_key" {
  description = "PagerDuty API key (will be stored in SSM)"
  type        = string
  sensitive   = true
}

variable "slack_api_key" {
  description = "Slack bot API key (will be stored in SSM)"
  type        = string
  sensitive   = true
}
