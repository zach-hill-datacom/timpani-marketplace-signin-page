# SNS Topics and Subscriptions

# Support SNS Topic
resource "aws_sns_topic" "support_sns_topic" {
  name = "SupportSNSTopic-${local.stack_id_short}"
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "support_email_subscription" {
  topic_arn = aws_sns_topic.support_sns_topic.arn
  protocol  = "email"
  endpoint  = var.marketplace_tech_admin_email
}

# Note: SNS Topic Subscriptions need to be created after getting the product code
# These will be handled by the custom resource or manual configuration

# Lambda permissions and SQS policies will need to be configured
# after the product code is retrieved from the custom resource