# IAM Roles and Policies

# Cross Account Role
resource "aws_iam_role" "cross_account_role_for_saas_integration" {
  count = local.create_cross_account ? 1 : 0

  name = "CrossAccountRoleName-${local.stack_id_short}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.cross_account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.cross_account_role_name
          }
        }
      }
    ]
  })

  inline_policy {
    name = "CrossAccountPolicy-${local.stack_id_short}"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "dynamodb:PutItem",
            "dynamodb:DeleteItem",
            "dynamodb:UpdateItem"
          ]
          Resource = [
            local.create_subscription_logic ? aws_dynamodb_table.aws_marketplace_metering_records[0].arn : "",
            aws_dynamodb_table.aws_marketplace_subscribers.arn
          ]
        }
      ]
    })
  }

  depends_on = [
    aws_dynamodb_table.aws_marketplace_metering_records,
    aws_dynamodb_table.aws_marketplace_subscribers
  ]
}

# Lambda Execution Role for CAPI functions
resource "aws_iam_role" "capi_lambdas_execution_role" {
  name = "CAPILambdasExecutionRole-${local.stack_id_short}"

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
    name = "manage-products"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "aws-marketplace:StartChangeSet",
            "aws-marketplace:DescribeEntity"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:aws-marketplace:us-east-1:${data.aws_caller_identity.current.account_id}:AWSMarketplace/SaaSProduct/${var.product_id}",
            "arn:${data.aws_partition.current.partition}:aws-marketplace:us-east-1:${data.aws_caller_identity.current.account_id}:AWSMarketplace/ChangeSet/*"
          ]
        }
      ]
    })
  }
}

# S3 Content Custom Resource Role
resource "aws_iam_role" "s3_content_custom_resource_role" {
  count = local.create_web ? 1 : 0

  name = "S3ContentCustomResourceRole-${local.stack_id_short}"

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

  inline_policy {
    name = "LambdaExecute"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/S3ContentCustomResource-${local.stack_id_short}*"
        },
        {
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:DeleteObject"
          ]
          Resource = local.create_web ? "${aws_s3_bucket.website_s3_bucket[0].arn}/*" : ""
        }
      ]
    })
  }
}