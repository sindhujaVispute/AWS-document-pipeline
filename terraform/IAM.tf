# 1. Trust Policy: Allow Lambda to assume this role
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# 2. Create the IAM Role
resource "aws_iam_role" "lambda_role" {
  name               = "doc-pipeline-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Project     = "Intelligent Document Pipeline"
    Environment = "Dev"
  }
}

# 3. Least-Privilege Policy: Only what Lambda actually needs
data "aws_iam_policy_document" "lambda_permissions" {
  # Permission to read the uploaded PDF from our specific S3 bucket
  statement {
    sid       = "AllowS3Read"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.uploads.arn}/*"]
  }

  # Permission to write metadata to our specific DynamoDB table
  statement {
    sid     = "AllowDynamoDBWrite"
    effect  = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem"
    ]
    resources = [aws_dynamodb_table.document_metadata.arn]
  }

  # Permission to write logs to CloudWatch (required for Lambda)
  statement {
    sid     = "AllowCloudWatchLogs"
    effect  = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.aws_region}:*:*"]
  }

  # Permission to read the AI API key from SSM Parameter Store
  statement {
    sid       = "AllowSSMRead"
    effect    = "Allow"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:${var.aws_region}:*:parameter/doc-pipeline/*"]
  }

  # Permission to publish custom metrics to CloudWatch
  # Note: PutMetricData doesn't support resource-level ARNs, so we scope by namespace
  statement {
    sid       = "AllowCloudWatchPutMetricData"
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"
      values   = ["DocPipeline"]
    }
  }
}

# 4. Attach the Policy to the Role
resource "aws_iam_role_policy" "lambda_policy" {
  name   = "doc-pipeline-lambda-policy"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}