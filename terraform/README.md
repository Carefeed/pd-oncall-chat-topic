# Terraform Deployment for PagerDuty On-Call Slack Topic Updater

This directory contains Terraform configuration to deploy the PagerDuty on-call Slack integration Lambda function.

## Prerequisites

1. **Terraform** >= 1.0 installed
2. **AWS CLI** configured with appropriate profile
3. **Slack Bot** created with these scopes:
   - `channels:read`
   - `channels:write.topic`
4. **PagerDuty API key** (read-only access)
5. **AWS Permissions** - Your AWS user/role needs:
   - Lambda: Create/update functions
   - IAM: Create/manage roles
   - DynamoDB: Create/manage tables
   - SSM: Create/manage parameters
   - KMS: Decrypt SSM parameters
   - EventBridge: Create/manage rules
   - CloudWatch Logs: Create/manage log groups

## Quick Start

### 1. Configure Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:
- AWS region and profile
- PagerDuty API key
- Slack bot token

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review Plan

```bash
terraform plan
```

### 4. Deploy

```bash
terraform apply
```

Type `yes` when prompted.

## Post-Deployment Configuration

After deployment, you need to configure the DynamoDB table with your schedule mappings.

### Add Schedule Mapping

Use the AWS CLI to add an item to the DynamoDB table:

```bash
aws dynamodb put-item \
  --table-name pagerduty-oncall-chat-topic-config \
  --item '{
    "schedule": {"S": "P123456"},
    "slack": {"S": "C123456789"},
    "sched_name": {"S": "Engineering On-Call"}
  }' \
  --profile YOUR_AWS_PROFILE \
  --region YOUR_AWS_REGION
```

**Field descriptions:**
- `schedule`: PagerDuty schedule ID (format: `P` followed by 6-7 alphanumeric characters)
- `slack`: Slack channel ID (format: `C` followed by 9-10 alphanumeric characters)
- `sched_name`: Optional display name for the schedule

**Multiple schedules:**
If you have split on-call rotations, use comma-separated values:
```json
{
  "schedule": {"S": "P123456,P789ABC"},
  "slack": {"S": "C123456789"},
  "sched_name": {"S": "Engineering Primary,Engineering Secondary"}
}
```

**Multiple channels:**
To update multiple Slack channels with the same schedule:
```json
{
  "schedule": {"S": "P123456"},
  "slack": {"S": "C123456789 C987654321"},
  "sched_name": {"S": "Engineering On-Call"}
}
```

## Verification

### 1. Check Lambda Function

```bash
terraform output lambda_function_name
aws lambda get-function --function-name $(terraform output -raw lambda_function_name) --profile YOUR_AWS_PROFILE --region YOUR_AWS_REGION
```

### 2. Invoke Lambda Manually (Test)

```bash
aws lambda invoke \
  --function-name $(terraform output -raw lambda_function_name) \
  --profile YOUR_AWS_PROFILE \
  --region YOUR_AWS_REGION \
  /tmp/lambda-output.json

cat /tmp/lambda-output.json
```

### 3. Check Slack Channel Topic

The Lambda runs every 5 minutes. Wait a few minutes and check your Slack channel topic. It should show:
```
[Name] is on-call for [Schedule Name] | [rest of topic]
```

### 4. View Lambda Logs

```bash
aws logs tail /aws/lambda/pagerduty-oncall-chat-topic \
  --follow \
  --profile YOUR_AWS_PROFILE \
  --region YOUR_AWS_REGION
```

## Updating API Keys

If you need to update the API keys after deployment:

```bash
# Update PagerDuty key
aws ssm put-parameter \
  --name pagerduty-oncall-chat-topic \
  --value "NEW_API_KEY" \
  --type SecureString \
  --overwrite \
  --profile YOUR_AWS_PROFILE \
  --region YOUR_AWS_REGION

# Update Slack key
aws ssm put-parameter \
  --name pagerduty-oncall-chat-topic-slack \
  --value "NEW_SLACK_TOKEN" \
  --type SecureString \
  --overwrite \
  --profile YOUR_AWS_PROFILE \
  --region YOUR_AWS_REGION
```

## Resources Created

- **Lambda Function**: `pagerduty-oncall-chat-topic`
- **IAM Role**: `pagerduty-oncall-chat-topic-role`
- **DynamoDB Table**: `pagerduty-oncall-chat-topic-config`
- **EventBridge Rule**: `pagerduty-oncall-chat-topic-schedule` (runs every 5 minutes)
- **CloudWatch Log Group**: `/aws/lambda/pagerduty-oncall-chat-topic`
- **SSM Parameters**:
  - `pagerduty-oncall-chat-topic` (PagerDuty API key)
  - `pagerduty-oncall-chat-topic-slack` (Slack bot token)

## Cost Estimate

- **Lambda**: ~$0.20/month (12 invocations/hour * 720 hours * $0.0000002/request)
- **DynamoDB**: ~$0.30/month (pay-per-request mode, minimal usage)
- **CloudWatch Logs**: ~$0.50/month (7-day retention)
- **Total**: ~$1/month

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted.

## Troubleshooting

### Lambda function fails with permission errors

Check that the IAM role has the correct permissions:
```bash
aws iam get-role-policy \
  --role-name pagerduty-oncall-chat-topic-role \
  --policy-name pagerduty-oncall-chat-topic-policy \
  --profile YOUR_AWS_PROFILE
```

### Slack channel topic not updating

1. Check Lambda logs for errors
2. Verify the Slack bot is a member of the channel
3. Verify the Slack bot has `channels:write.topic` scope
4. Verify the DynamoDB table has the correct channel ID

### PagerDuty API errors

1. Verify the API key is correct in SSM
2. Verify the schedule ID exists in PagerDuty
3. Check Lambda logs for specific API error messages

## Architecture

```
CloudWatch Events (every 5 minutes)
          ↓
    Lambda Function
          ↓
    ┌─────┴─────┐
    ↓           ↓
DynamoDB    SSM Parameters
(config)    (API keys)
    ↓           ↓
    └─────┬─────┘
          ↓
   PagerDuty API → Slack API
```

## Contributing

Contributions are welcome! Please open an issue or pull request.
