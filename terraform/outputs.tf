output "s3_bucket_name" {
  description = "Name of the S3 uploads bucket"
  value       = aws_s3_bucket.uploads.id
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB metadata table"
  value       = aws_dynamodb_table.document_metadata.name
}
output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_role.arn
}
output "ssm_parameter_arn" {
  description = "ARN of the AI API key parameter"
  value       = data.aws_ssm_parameter.ai_api_key.arn
  sensitive   = true
}
output "lambda_function_name" {
  description = "Name of the deployed Lambda function"
  value       = aws_lambda_function.processor.function_name
}
output "sns_topic_arn" {
  description = "SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_url" {
  description = "CloudWatch Dashboard URL"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.pipeline_dashboard.dashboard_name}"
}
output "github_actions_role_arn" {
  description = "ARN of the IAM role GitHub Actions will assume"
  value       = aws_iam_role.github_actions.arn
}

#arn:aws:iam::293280994842:role/doc-pipeline-github-actions-role