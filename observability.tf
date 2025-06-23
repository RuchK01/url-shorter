# ----------------------
# CLOUDWATCH & SNS FOR OBSERVABILITY
# ----------------------

# 1. SNS Topic for Notifications
resource "aws_sns_topic" "api_error_notifications" {
  name = "api-error-notifications"
  display_name = "URL Shortener API Errors"
}

# 2. SNS Topic Email Subscription
# IMPORTANT: You will receive an email to confirm this subscription after Terraform applies.
# You MUST confirm it for notifications to work.
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.api_error_notifications.arn
  protocol  = "email"
  endpoint  = "ruchak997@gmail.com" # <--- REPLACE WITH YOUR EMAIL ADDRESS
}

# 3. CloudWatch Log Group for API Gateway Access Logs
resource "aws_cloudwatch_log_group" "api_gateway_access_logs" {
  name              = "/aws/api-gateway/${aws_apigatewayv2_api.http_api.name}/access-logs"
  retention_in_days = 7 # Adjust retention as needed
}

# 4. API Gateway Stage Logging Configuration
# This links the API Gateway stage to the CloudWatch Log Group
resource "aws_apigatewayv2_stage" "default" {
  # YOU MUST ADD THESE PROPERTIES HERE.
  # These were previously in your apigateway.tf and must be moved here completely.
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true # Keep this if it was in your original apigateway.tf definition

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_access_logs.arn
    # Custom log format for detailed information, including status code
    format = jsonencode({
      requestId = "$context.requestId"
      ip = "$context.identity.sourceIp"
      requestTime = "$context.requestTime"
      httpMethod = "$context.httpMethod"
      path = "$context.path"
      status = "$context.status" # <-- This is crucial for filtering 5xx errors
      protocol = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }
}

# 5. CloudWatch Metric Filter for 5xx Errors
# This filter looks for entries in the API Gateway logs where status is 5xx
resource "aws_cloudwatch_log_metric_filter" "api_5xx_errors" {
  name           = "API_5XX_Errors" # Custom namespace for your metrics
  pattern        = "{ $.status = 5* }" # Matches any status code starting with 5 (e.g., 500, 501, 502)
  log_group_name = aws_cloudwatch_log_group.api_gateway_access_logs.name

  metric_transformation {
    name          = "5xxErrorCount"
    namespace      = "URLShortener/API"
    value         = "1" # Each match counts as 1
    default_value = "0"
  }
}

# 6. CloudWatch Alarm for 5xx Errors
resource "aws_cloudwatch_metric_alarm" "api_5xx_alarm" {
  alarm_name                = "API-5XX-Errors-Alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "1"
  metric_name               = aws_cloudwatch_log_metric_filter.api_5xx_errors.metric_transformation[0].name
  namespace                 = aws_cloudwatch_log_metric_filter.api_5xx_errors.metric_transformation[0].namespace
  period                    = "60" # Check every 60 seconds (1 minute)
  statistic                 = "Sum"
  threshold                 = "5" # Trigger if 5xx errors are > 5 in one minute
  alarm_description         = "Alarm when the number of 5xx errors on the API Gateway exceeds 5 in a minute."
  alarm_actions             = [aws_sns_topic.api_error_notifications.arn]
  ok_actions                = [aws_sns_topic.api_error_notifications.arn] # Send "OK" notification too
  treat_missing_data        = "notBreaching" # Treat missing data as not breaching the threshold
}
# 7. SNS Topic Policy to allow CloudWatch to publish
resource "aws_sns_topic_policy" "allow_cloudwatch_publish" {
  arn = aws_sns_topic.api_error_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        },
        Action    = "sns:Publish",
        Resource  = aws_sns_topic.api_error_notifications.arn,
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_metric_alarm.api_5xx_alarm.arn
          }
        }
      }
    ]
  })
}