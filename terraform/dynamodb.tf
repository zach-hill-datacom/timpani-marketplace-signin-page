# DynamoDB Tables
resource "aws_dynamodb_table" "aws_marketplace_metering_records" {
  count = local.create_subscription_logic ? 1 : 0

  name         = var.aws_marketplace_metering_records_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "customerIdentifier"
  range_key    = "create_timestamp"

  attribute {
    name = "customerIdentifier"
    type = "S"
  }

  attribute {
    name = "create_timestamp"
    type = "N"
  }

  attribute {
    name = "metering_pending"
    type = "S"
  }

  global_secondary_index {
    name            = "PendingMeteringRecordsIndex"
    hash_key        = "metering_pending"
    projection_type = "ALL"
  }

  tags = {
    Name = var.aws_marketplace_metering_records_table_name
  }
}

resource "aws_dynamodb_table" "aws_marketplace_subscribers" {
  name         = var.new_subscribers_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "customerIdentifier"

  attribute {
    name = "customerIdentifier"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = {
    Name = var.new_subscribers_table_name
  }
}