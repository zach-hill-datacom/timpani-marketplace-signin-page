# EventBridge (CloudWatch Events) for Hourly Metering

resource "aws_cloudwatch_event_rule" "hourly_metering_schedule" {
  count = local.create_subscription_logic ? 1 : 0

  name                = "MeteringSchedule-${local.stack_id_short}"
  description         = "SaaS Metering"
  schedule_expression = "rate(1 hour)"
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_target" "hourly_lambda_target" {
  count = local.create_subscription_logic ? 1 : 0

  rule      = aws_cloudwatch_event_rule.hourly_metering_schedule[0].name
  target_id = "HourlyLambdaTarget"
  arn       = aws_lambda_function.hourly[0].arn
}

resource "aws_lambda_permission" "allow_eventbridge_hourly" {
  count = local.create_subscription_logic ? 1 : 0

  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hourly[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.hourly_metering_schedule[0].arn
}

# SQS Event Source Mapping for Metering
resource "aws_lambda_event_source_mapping" "metering_sqs_event" {
  count = local.create_subscription_logic ? 1 : 0

  event_source_arn = aws_sqs_queue.sqs_metering_records[0].arn
  function_name    = aws_lambda_function.metering_sqs_handler[0].arn
  batch_size       = 1
}