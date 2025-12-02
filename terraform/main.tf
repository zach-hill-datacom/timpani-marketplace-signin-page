terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# Random ID for unique resource naming
resource "random_id" "stack_id" {
  byte_length = 8
}

locals {
  stack_id_short = substr(random_id.stack_id.hex, 0, 8)

  # Conditions
  create_entitlement_logic  = contains(["contracts_with_subscription", "contracts"], var.type_of_saas_listing)
  create_subscription_logic = contains(["contracts_with_subscription", "subscriptions"], var.type_of_saas_listing)
  create_web                = var.create_registration_web_page
  buyer_notification_email  = var.marketplace_seller_email != ""
  create_cross_account      = var.create_cross_account_role
  update_fulfillment        = var.update_fulfillment_url
}