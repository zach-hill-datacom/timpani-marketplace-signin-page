# AWS Marketplace Serverless SaaS Integration - Terraform

This Terraform configuration converts the original CloudFormation template for AWS Marketplace Serverless SaaS Integration into Infrastructure as Code using Terraform.

## Overview

This infrastructure creates a complete serverless SaaS integration for AWS Marketplace, including:

- **API Gateway**: RESTful API for subscriber registration and marketplace token redirection
- **Lambda Functions**: Serverless functions for handling marketplace events, metering, and customer management
- **DynamoDB Tables**: Storage for subscriber data and metering records
- **S3 & CloudFront**: Static website hosting for customer registration page
- **SNS & SQS**: Event-driven architecture for marketplace notifications
- **IAM Roles**: Secure access controls for all components

## Architecture Components

### Core Services
- **RegisterNewMarketplaceCustomer**: Lambda function to handle new subscriber registration
- **SubscriptionSQSHandler**: Processes subscription events from AWS Marketplace
- **EntitlementSQSHandler**: Handles entitlement notifications (for contracts)
- **GrantRevokeAccess**: DynamoDB stream processor for access management
- **MeteringComponents**: Hourly job and SQS handler for usage metering

### Storage
- **AWSMarketplaceSubscribers**: DynamoDB table for customer data
- **AWSMarketplaceMeteringRecords**: DynamoDB table for usage tracking (subscription models)

### Web Interface (Optional)
- **S3 Bucket**: Hosts static registration website
- **CloudFront**: CDN for global content delivery
- **Registration Page**: Customer onboarding interface

## Prerequisites

1. **Terraform**: Version >= 1.0
2. **AWS CLI**: Configured with appropriate credentials
3. **AWS Marketplace Product**: Existing SaaS product in AWS Marketplace
4. **Node.js Dependencies**: The Lambda functions require AWS SDK v3

## Quick Start

1. **Clone and Navigate**:
   ```bash
   cd terraform
   ```

2. **Configure Variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

3. **Initialize Terraform**:
   ```bash
   terraform init
   ```

4. **Plan Deployment**:
   ```bash
   terraform plan
   ```

5. **Deploy Infrastructure**:
   ```bash
   terraform apply
   ```

## Configuration Variables

### Required Variables
- `product_id`: Your AWS Marketplace Product ID
- `marketplace_tech_admin_email`: Email for technical notifications

### Optional Variables
- `website_s3_bucket_name`: S3 bucket name for static website (default: "timpani-login-page-bucket")
- `type_of_saas_listing`: SaaS model type (default: "contracts_with_subscription")
- `create_registration_web_page`: Enable/disable web interface (default: true)
- `create_cross_account_role`: Enable cross-account access (default: false)
- `update_fulfillment_url`: Auto-update marketplace fulfillment URL (default: false)

### SaaS Listing Types
- `contracts_with_subscription`: Both contracts and subscription billing
- `contracts`: Contract-based billing only
- `subscriptions`: Subscription-based billing only

## File Structure

```
terraform/
├── main.tf                    # Provider and core configuration
├── variables.tf               # Input variable definitions
├── outputs.tf                 # Output values
├── dynamodb.tf               # DynamoDB table configurations
├── iam.tf                    # IAM roles and policies
├── lambda.tf                 # Lambda function definitions
├── api_gateway.tf            # API Gateway configuration
├── s3.tf                     # S3 bucket setup
├── cloudfront.tf             # CloudFront distribution
├── sns.tf                    # SNS topics and subscriptions
├── sqs.tf                    # SQS queue configurations
├── eventbridge.tf            # EventBridge rules for scheduling
├── custom_resources.tf       # Custom resource implementations
├── src/                      # Lambda function source code
│   ├── entitlement-sqs.js
│   ├── grant-revoke-access-to-product.js
│   ├── metering-hourly-job.js
│   ├── metering-sqs.js
│   ├── redirect.js
│   ├── register-new-subscriber.js
│   ├── subscription-sqs.js
│   ├── get-product-code.js
│   ├── update-fulfillment-url.js
│   └── s3-content-custom-resource.js
└── web-content/              # Static website files
    ├── index.html
    ├── script.js
    └── style.css
```

## Key Differences from CloudFormation

### Terraform Advantages
1. **State Management**: Terraform tracks resource state for reliable updates
2. **Modularity**: Better code organization with separate files per service
3. **Variables**: More flexible variable system with validation
4. **Dependencies**: Explicit dependency management
5. **Loops and Conditionals**: More powerful conditional resource creation

### Implementation Notes
1. **Custom Resources**: Replaced CloudFormation custom resources with `null_resource` and AWS CLI
2. **Inline Code**: Extracted embedded Lambda code to separate files in `src/`
3. **Web Content**: Static files moved to `web-content/` directory
4. **Conditions**: CloudFormation conditions converted to Terraform `count` parameters

## Deployment Outputs

After successful deployment, you'll receive:

- **marketplace_fulfillment_url**: URL to configure in AWS Marketplace
- **landing_page_preview_url**: Preview URL for customer registration page
- **api_gateway_url**: Direct API endpoint URL
- **cross_account_role**: ARN for cross-account access (if enabled)

## Post-Deployment Steps

1. **Configure Marketplace**: Update your AWS Marketplace product with the fulfillment URL
2. **Test Registration**: Use the preview URL to test customer registration flow
3. **Monitor Logs**: Check CloudWatch logs for Lambda function execution
4. **Verify SNS**: Confirm SNS topic subscriptions are active

## Troubleshooting

### Common Issues
1. **S3 Bucket Names**: Must be globally unique
2. **Product ID**: Ensure correct AWS Marketplace Product ID
3. **Email Verification**: SNS email subscriptions require confirmation
4. **Permissions**: Verify AWS credentials have necessary permissions

### Debugging
- Check CloudWatch logs for Lambda function errors
- Verify DynamoDB table creation and stream configuration
- Confirm API Gateway deployment and CORS settings
- Test SNS/SQS message flow

## Security Considerations

- All Lambda functions use least-privilege IAM roles
- S3 bucket access restricted to CloudFront
- API Gateway configured with CORS for web integration
- Cross-account access requires explicit configuration

## Cost Optimization

- DynamoDB uses on-demand billing
- Lambda functions have 15-second timeout
- CloudWatch logs have 7-day retention
- S3 intelligent tiering for log storage

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

**Warning**: This will permanently delete all data in DynamoDB tables and S3 buckets.

## Support

For issues related to:
- **Terraform Configuration**: Check the GitHub repository
- **AWS Marketplace Integration**: Consult AWS Marketplace documentation
- **Lambda Functions**: Review CloudWatch logs and function code

## License

This project maintains the same license as the original CloudFormation template.