# ============================================================
# SNS: Alert Channel
# ============================================================

resource "aws_sns_topic" "alerts" {
  name = "doc-pipeline-alerts"

  tags = {
    Project     = "Intelligent Document Pipeline"
    Environment = "Dev"
  }
}

# Email subscription — replace with YOUR email
resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "vsindhuja179@gmail.com"   # <-- CHANGE THIS
}

# ============================================================
# CloudWatch Alarm 1: Lambda Errors > 0
# ============================================================

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "doc-pipeline-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Triggers when the Lambda function returns any error"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.processor.function_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# ============================================================
# CloudWatch Alarm 2: Custom ProcessingErrors metric
# ============================================================

resource "aws_cloudwatch_metric_alarm" "processing_errors" {
  alarm_name          = "doc-pipeline-processing-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ProcessingErrors"
  namespace           = "DocPipeline"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Triggers when our custom ProcessingErrors metric > 0"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
}

# ============================================================
# CloudWatch Dashboard
# ============================================================

resource "aws_cloudwatch_dashboard" "pipeline_dashboard" {
  dashboard_name = "doc-pipeline-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Lambda Invocations, Errors, Duration"
          region = var.aws_region
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.processor.function_name],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", ".", { stat = "Average" }]
          ]
          view   = "timeSeries"
          period = 60
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Custom Pipeline Metrics"
          region = var.aws_region
          metrics = [
            ["DocPipeline", "DocumentsProcessed", { stat = "Sum" }],
            [".", "ProcessingErrors", { stat = "Sum" }],
            [".", "ProcessingDuration", { stat = "Average" }]
          ]
          view   = "timeSeries"
          period = 60
        }
      }
    ]
  })
}