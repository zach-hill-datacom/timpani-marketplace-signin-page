variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "website_s3_bucket_name" {
  description = "S3 bucket name must follow S3 recommendations https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html"
  type        = string
  default     = "timpani-login-page-bucket"
}

variable "new_subscribers_table_name" {
  description = "DynamoDB table name for new subscribers"
  type        = string
  default     = "AWSMarketplaceSubscribers"
}

variable "aws_marketplace_metering_records_table_name" {
  description = "DynamoDB table name for metering records"
  type        = string
  default     = "AWSMarketplaceMeteringRecords"
}

variable "type_of_saas_listing" {
  description = "Type of SaaS listing"
  type        = string
  default     = "contracts_with_subscription"
  validation {
    condition     = contains(["contracts_with_subscription", "contracts", "subscriptions"], var.type_of_saas_listing)
    error_message = "Type of SaaS listing must be one of: contracts_with_subscription, contracts, subscriptions."
  }
}

variable "sns_account_id" {
  description = "This is the AWS account hosting the SNS Entitlement and Subscription topics for your product"
  type        = string
  default     = "381492046924"
  validation {
    condition     = var.sns_account_id == "381492046924"
    error_message = "SNS Account ID must be 381492046924."
  }
}

variable "sns_region" {
  description = "This is the AWS region of the SNS Entitlement and Subscription topics for your product"
  type        = string
  default     = "us-east-1"
  validation {
    condition     = contains(["ap-southeast-2", "us-east-1"], var.sns_region)
    error_message = "SNS Region must be either ap-southeast-2 or us-east-1."
  }
}

variable "product_id" {
  description = "AWS Marketplace Product ID"
  type        = string
}

variable "marketplace_tech_admin_email" {
  description = "Technical admin email for marketplace notifications"
  type        = string
}

variable "marketplace_seller_email" {
  description = "Seller email for marketplace notifications"
  type        = string
  default     = ""
}

variable "create_cross_account_role" {
  description = "Do you intend to use cross account access with this integration core?"
  type        = bool
  default     = false
}

variable "cross_account_id" {
  description = "Enter the cross AWS account id"
  type        = string
  default     = ""
}

variable "cross_account_role_name" {
  description = "Your Role Name (ex: OrganizationAccountAccessRole); This will need to be the same across all of the Member Accounts"
  type        = string
  default     = ""
}

variable "create_registration_web_page" {
  description = "Create registration web page"
  type        = bool
  default     = true
}

variable "update_fulfillment_url" {
  description = "WARNING: This will update your product's fulfillment URL automatically. Be careful if your product is already public"
  type        = bool
  default     = false
}