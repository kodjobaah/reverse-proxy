data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "webhook_log_group" {
  name              = "/ecs/webhook-reverse-proxy"
  retention_in_days = 30

  tags = {
    Name  = "${var.project}-${var.group}-${var.env}"
    Group = var.group
  }
}
resource "aws_cloudwatch_log_metric_filter" "errors_filter" {
  name           = "webhook-reverse-errors_filter-${var.env}"
  pattern        = "Error"
  log_group_name = aws_cloudwatch_log_group.webhook_log_group.name
  metric_transformation {
    name      = "errors-in-logs-${var.env}"
    namespace = "WebhookProxyLogs-${var.env}"
    value     = 1
  }
}

resource "aws_cloudwatch_metric_alarm" "errors_within_logs" {
  alarm_name                = "webhook-proxy-logs-error-${var.env}"
  comparison_operator       = "GreaterThanThreshold"
  alarm_description         = "Log errors are too high"
  evaluation_periods        = 1
  threshold                 = 0
  period                    = 60
  statistic                 = "Sum"
  insufficient_data_actions = []

  metric_name   = aws_cloudwatch_log_metric_filter.errors_filter.metric_transformation[0].name
  namespace     = aws_cloudwatch_log_metric_filter.errors_filter.metric_transformation[0].namespace
  alarm_actions = ["arn:aws:sns:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:monitoring-lambda-cloud-watch-${var.env}"]
  tags = {
    LogGroup = aws_cloudwatch_log_group.webhook_log_group.name
  }
}