# Outputs

output "cross_account_role" {
  description = "This is the cross account role ARN"
  value       = local.create_cross_account ? aws_iam_role.cross_account_role_for_saas_integration[0].arn : "N/A"
}

output "website_s3_bucket" {
  description = "S3 bucket for hosting the static site. You can retrieve the files at https://github.com/aws-samples/aws-marketplace-serverless-saas-integration/tree/master/web"
  value       = local.create_web ? "https://s3.console.aws.amazon.com/s3/buckets/${aws_s3_bucket.website_s3_bucket[0].id}/" : "N/A"
}

output "landing_page_preview_url" {
  description = "URL to preview your landing page. This is NOT the Fulfillment URL for your product"
  value       = local.create_web ? "https://${aws_cloudfront_distribution.cloudfront_distribution[0].domain_name}/index.html" : "N/A"
}

output "marketplace_fulfillment_url" {
  description = "This is the Marketplace fulfillment URL"
  value       = local.create_web ? "https://${aws_cloudfront_distribution.cloudfront_distribution[0].domain_name}/redirectmarketplacetoken" : "https://${aws_api_gateway_rest_api.serverless_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/Prod/redirectmarketplacetoken"
}

output "api_gateway_url" {
  description = "API Gateway URL"
  value       = "https://${aws_api_gateway_rest_api.serverless_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/Prod"
}

output "dynamodb_subscribers_table" {
  description = "DynamoDB Subscribers Table Name"
  value       = aws_dynamodb_table.aws_marketplace_subscribers.name
}

output "dynamodb_metering_table" {
  description = "DynamoDB Metering Records Table Name"
  value       = local.create_subscription_logic ? aws_dynamodb_table.aws_marketplace_metering_records[0].name : "N/A"
}