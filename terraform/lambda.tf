# Lambda Functions

# Archive Lambda source code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda-deployment.zip"
}

# Register New Marketplace Customer Lambda
resource "aws_lambda_function" "register_new_marketplace_customer" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "RegisterNewMarketplaceCustomer-${local.stack_id_short}"
  role             = aws_iam_role.register_lambda_role.arn
  handler          = "register-new-subscriber.registerNewSubscriber"
  runtime          = "nodejs22.x"
  timeout          = 15
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      NewSubscribersTableName = var.new_subscribers_table_name
      EntitlementQueueUrl     = local.create_entitlement_logic ? aws_sqs_queue.entitlement_sqs_queue[0].url : ""
      MarketplaceSellerEmail  = local.buyer_notification_email ? var.marketplace_seller_email : ""
    }
  }
}

# IAM Role for Register Lambda
resource "aws_iam_role" "register_lambda_role" {
  name = "RegisterLambdaRole-${local.stack_id_short}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  inline_policy {
    name = "DynamoDBWritePolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "dynamodb:DeleteItem"
          ]
          Resource = aws_dynamodb_table.aws_marketplace_subscribers.arn
        }
      ]
    })
  }

  dynamic "inline_policy" {
    for_each = local.create_entitlement_logic ? [1] : []
    content {
      name = "SQSPolicy"
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect   = "Allow"
            Action   = "sqs:SendMessage"
            Resource = aws_sqs_queue.entitlement_sqs_queue[0].arn
          }
        ]
      })
    }
  }

  inline_policy {
    name = "MarketplaceAndSESPolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "aws-marketplace:ResolveCustomer"
          Resource = "*"
        },
        {
          Effect   = "Allow"
          Action   = "ses:SendEmail"
          Resource = "*"
        }
      ]
    })
  }
}

# Entitlement SQS Handler Lambda
resource "aws_lambda_function" "entitlement_sqs_handler" {
  count = local.create_entitlement_logic ? 1 : 0

  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "EntitlementSQSHandler-${local.stack_id_short}"
  role             = aws_iam_role.entitlement_lambda_role[0].arn
  handler          = "entitlement-sqs.handler"
  runtime          = "nodejs22.x"
  timeout          = 15
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      NewSubscribersTableName = var.new_subscribers_table_name
    }
  }
}

# IAM Role for Entitlement Lambda
resource "aws_iam_role" "entitlement_lambda_role" {
  count = local.create_entitlement_logic ? 1 : 0

  name = "EntitlementLambdaRole-${local.stack_id_short}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  inline_policy {
    name = "DynamoDBWritePolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "dynamodb:DeleteItem"
          ]
          Resource = aws_dynamodb_table.aws_marketplace_subscribers.arn
        }
      ]
    })
  }

  inline_policy {
    name = "SQSAndMarketplacePolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "sqs:SendMessage"
          Resource = aws_sqs_queue.entitlement_sqs_queue[0].arn
        },
        {
          Effect   = "Allow"
          Action   = "aws-marketplace:GetEntitlements"
          Resource = "*"
        }
      ]
    })
  }
}

# Subscription SQS Handler Lambda
resource "aws_lambda_function" "subscription_sqs_handler" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "SubscriptionSQSHandler-${local.stack_id_short}"
  role             = aws_iam_role.subscription_lambda_role.arn
  handler          = "subscription-sqs.SQSHandler"
  runtime          = "nodejs22.x"
  timeout          = 15
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      NewSubscribersTableName = var.new_subscribers_table_name
      SupportSNSArn           = aws_sns_topic.support_sns_topic.arn
    }
  }
}

# IAM Role for Subscription Lambda
resource "aws_iam_role" "subscription_lambda_role" {
  name = "SubscriptionLambdaRole-${local.stack_id_short}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  inline_policy {
    name = "DynamoDBWritePolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "dynamodb:DeleteItem"
          ]
          Resource = aws_dynamodb_table.aws_marketplace_subscribers.arn
        }
      ]
    })
  }

  inline_policy {
    name = "SNSPublishPolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "sns:Publish"
          Resource = aws_sns_topic.support_sns_topic.arn
        }
      ]
    })
  }
}

# Grant or Revoke Access Lambda
resource "aws_lambda_function" "grant_revoke_access" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "GrantRevokeAccess-${local.stack_id_short}"
  role             = aws_iam_role.grant_revoke_lambda_role.arn
  handler          = "grant-revoke-access-to-product.dynamodbStreamHandler"
  runtime          = "nodejs22.x"
  timeout          = 15
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SupportSNSArn = aws_sns_topic.support_sns_topic.arn
      LOG_LEVEL     = "info"
    }
  }
}

# IAM Role for Grant/Revoke Lambda
resource "aws_iam_role" "grant_revoke_lambda_role" {
  name = "GrantRevokeLambdaRole-${local.stack_id_short}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole"
  ]

  inline_policy {
    name = "SNSPublishPolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "sns:Publish"
          Resource = aws_sns_topic.support_sns_topic.arn
        }
      ]
    })
  }
}

# DynamoDB Stream Event Source Mapping
resource "aws_lambda_event_source_mapping" "dynamodb_stream" {
  event_source_arn  = aws_dynamodb_table.aws_marketplace_subscribers.stream_arn
  function_name     = aws_lambda_function.grant_revoke_access.arn
  starting_position = "TRIM_HORIZON"
  batch_size        = 1
}

# Hourly Metering Lambda
resource "aws_lambda_function" "hourly" {
  count = local.create_subscription_logic ? 1 : 0

  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "Hourly-${local.stack_id_short}"
  role             = aws_iam_role.hourly_lambda_role[0].arn
  handler          = "metering-hourly-job.job"
  runtime          = "nodejs22.x"
  timeout          = 15
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SQSMeteringRecordsUrl                  = aws_sqs_queue.sqs_metering_records[0].url
      AWSMarketplaceMeteringRecordsTableName = var.aws_marketplace_metering_records_table_name
    }
  }
}

# IAM Role for Hourly Lambda
resource "aws_iam_role" "hourly_lambda_role" {
  count = local.create_subscription_logic ? 1 : 0

  name = "HourlyLambdaRole-${local.stack_id_short}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  inline_policy {
    name = "DynamoDBReadPolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:Query",
            "dynamodb:Scan",
            "dynamodb:GetItem"
          ]
          Resource = aws_dynamodb_table.aws_marketplace_metering_records[0].arn
        }
      ]
    })
  }

  inline_policy {
    name = "SQSSendMessagePolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "sqs:SendMessage"
          Resource = aws_sqs_queue.sqs_metering_records[0].arn
        }
      ]
    })
  }
}

# Metering SQS Handler Lambda
resource "aws_lambda_function" "metering_sqs_handler" {
  count = local.create_subscription_logic ? 1 : 0

  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "MeteringSQSHandler-${local.stack_id_short}"
  role             = aws_iam_role.metering_sqs_lambda_role[0].arn
  handler          = "metering-sqs.handler"
  runtime          = "nodejs22.x"
  timeout          = 15
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      ProductCode                            = "placeholder" # Will be updated by custom resource
      AWSMarketplaceMeteringRecordsTableName = var.aws_marketplace_metering_records_table_name
    }
  }
}

# IAM Role for Metering SQS Lambda
resource "aws_iam_role" "metering_sqs_lambda_role" {
  count = local.create_subscription_logic ? 1 : 0

  name = "MeteringSQSLambdaRole-${local.stack_id_short}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  inline_policy {
    name = "DynamoDBWritePolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:PutItem",
            "dynamodb:UpdateItem",
            "dynamodb:DeleteItem"
          ]
          Resource = aws_dynamodb_table.aws_marketplace_metering_records[0].arn
        }
      ]
    })
  }

  inline_policy {
    name = "MarketplaceMeteringPolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "aws-marketplace:BatchMeterUsage"
          Resource = "*"
        }
      ]
    })
  }
}

# Lambda Redirect Function (for web)
resource "aws_lambda_function" "lambda_redirect_post_requests" {
  count = local.create_web ? 1 : 0

  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "LambdaRedirectPostRequests-${local.stack_id_short}"
  role             = aws_iam_role.redirect_lambda_role[0].arn
  handler          = "redirect.redirecthandler"
  runtime          = "nodejs22.x"
  timeout          = 15
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      RedirectUrl = "https://aws-ia.github.io/cloudformation-aws-marketplace-saas/#_post_deployment_steps"
    }
  }
}

# IAM Role for Redirect Lambda
resource "aws_iam_role" "redirect_lambda_role" {
  count = local.create_web ? 1 : 0

  name = "RedirectLambdaRole-${local.stack_id_short}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}

# Get Product Code Custom Resource Lambda
resource "aws_lambda_function" "get_product_code_custom_resource" {
  filename         = "${path.module}/get-product-code.zip"
  function_name    = "GetProductCodeCustomResource-${local.stack_id_short}"
  role             = aws_iam_role.capi_lambdas_execution_role.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  timeout          = 60
  source_code_hash = data.archive_file.get_product_code_zip.output_base64sha256

  environment {
    variables = {
      ProductCode = "placeholder" # This will be updated by the custom resource
    }
  }
}

# Archive for Get Product Code Lambda
data "archive_file" "get_product_code_zip" {
  type        = "zip"
  output_path = "${path.module}/get-product-code.zip"

  source {
    content  = file("${path.module}/src/get-product-code.js")
    filename = "index.js"
  }
}

# Update Fulfillment URL Custom Resource Lambda
resource "aws_lambda_function" "update_fulfillment_url_custom_resource" {
  count = local.update_fulfillment ? 1 : 0

  filename         = "${path.module}/update-fulfillment-url.zip"
  function_name    = "UpdateFulfillmentURLCustomResource-${local.stack_id_short}"
  role             = aws_iam_role.capi_lambdas_execution_role.arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  timeout          = 60
  source_code_hash = data.archive_file.update_fulfillment_url_zip.output_base64sha256
}

# Archive for Update Fulfillment URL Lambda
data "archive_file" "update_fulfillment_url_zip" {
  type        = "zip"
  output_path = "${path.module}/update-fulfillment-url.zip"

  source {
    content  = file("${path.module}/src/update-fulfillment-url.js")
    filename = "index.js"
  }
}