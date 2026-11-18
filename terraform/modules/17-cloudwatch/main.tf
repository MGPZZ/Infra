###############################################
# EC2 Health Check Alarm
###############################################

locals {
  alarm_dimensions = var.dimensions != null ? var.dimensions : {
    InstanceId = var.instance_id
  }
}

resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name          = var.alarm_name
  namespace           = var.namespace
  metric_name         = var.metric_name
  statistic           = var.statistic
  period              = var.period_seconds
  evaluation_periods  = var.evaluation_periods
  datapoints_to_alarm = var.datapoints_to_alarm
  threshold           = var.threshold
  comparison_operator = var.comparison_operator
  treat_missing_data  = var.treat_missing_data

  dimensions = local.alarm_dimensions

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions
}
# Lambda 호출 권한 부여
resource "aws_lambda_permission" "cloudwatch" {
  # count는 변수 명이 아니라  lambda_function_name에 값이 없을 때 권한 생성 안하게 하는 예약어
  count         = var.lambda_function_name == null ? 0 : 1
  statement_id  = "AllowCloudWatch-${var.alarm_name}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = aws_cloudwatch_metric_alarm.this.arn
}
