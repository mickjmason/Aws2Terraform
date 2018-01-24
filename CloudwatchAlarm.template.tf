resource "aws_cloudwatch_metric_alarm" "^name^" {
  alarm_name                = "^name^"
  comparison_operator       = "^comparisonOperator^"
  evaluation_periods        = "^evaluationPeriods^"
  metric_name               = "^metricName^"
  namespace                 = "^nameSpace^"
  period                    = "^period^"
  statistic                 = "^statistic^"
  threshold                 = "^threshold^"
  alarm_description         = "^alarmDescription^"
  insufficient_data_actions = []
}