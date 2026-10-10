# Read the SSM parameter that we created via AWS CLI
data "aws_ssm_parameter" "ai_api_key" {
  name = "/doc-pipeline/ai-api-key"
}