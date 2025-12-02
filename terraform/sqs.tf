# SQS Queues

# Entitlement SQS Queue
resource "aws_sqs_queue" "entitlement_sqs_queue" {
  count = local.create_entitlement_logic ? 1 : 0

  name = "EntitlementSQSQueue-${local.stack_id_short}"
}

# SQS Metering Records Queue
resource "aws_sqs_queue" "sqs_metering_records" {
  count = local.create_subscription_logic ? 1 : 0

  name                        = "${local.stack_id_short}-SQSMeteringRecords.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  message_retention_seconds   = 3000
}