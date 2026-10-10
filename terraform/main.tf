# 1. Tell Terraform which provider we are using (AWS)
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# 2. Configure the AWS Provider using our variable
provider "aws" {
  region = var.aws_region
}

# 3. Create the S3 Bucket
resource "aws_s3_bucket" "uploads" {
  bucket = var.bucket_name

  tags = {
    Name        = "Document Uploads"
    Environment = "Dev"
    Project     = "Intelligent Document Pipeline"
  }
}

# 4. Secure the S3 Bucket (Block all public access)
resource "aws_s3_bucket_public_access_block" "uploads_block" {
  bucket                  = aws_s3_bucket.uploads.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# 5. Create the DynamoDB Table
resource "aws_dynamodb_table" "document_metadata" {
  name         = "DocumentMetadata"
  billing_mode = "PAY_PER_REQUEST" # On-Demand: Free tier friendly
  hash_key     = "documentId"

  attribute {
    name = "documentId"
    type = "S" # S = String
  }

  tags = {
    Name        = "Document Metadata Table"
    Environment = "Dev"
    Project     = "Intelligent Document Pipeline"
  }
}