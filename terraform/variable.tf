variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique name for the S3 bucket"
  type        = string
  # IMPORTANT: Change this to something unique. Include your name or random numbers.
  default     = "doc-pipeline-uploads-sindhuja-2026" 
}