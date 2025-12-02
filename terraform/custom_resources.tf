# Custom Resources for S3 Content and Product Code

# S3 Content Custom Resource Lambda
resource "aws_lambda_function" "s3_content_custom_resource" {
  count = local.create_web ? 1 : 0

  filename         = "${path.module}/s3-content-custom-resource.zip"
  function_name    = "S3ContentCustomResource-${local.stack_id_short}"
  role             = aws_iam_role.s3_content_custom_resource_role[0].arn
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  timeout          = 60
  source_code_hash = data.archive_file.s3_content_custom_resource_zip[0].output_base64sha256

  depends_on = [aws_cloudwatch_log_group.s3_content_custom_resource_log_group]
}

# Archive for S3 Content Custom Resource Lambda
data "archive_file" "s3_content_custom_resource_zip" {
  count = local.create_web ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/s3-content-custom-resource.zip"

  source {
    content  = file("${path.module}/src/s3-content-custom-resource.js")
    filename = "index.js"
  }
}

# Log Group for S3 Content Custom Resource
resource "aws_cloudwatch_log_group" "s3_content_custom_resource_log_group" {
  count = local.create_web ? 1 : 0

  name              = "/aws/lambda/S3ContentCustomResource-${local.stack_id_short}"
  retention_in_days = 7
}

# Custom Resource Invocations for S3 Content
resource "null_resource" "s3_content_home" {
  count = local.create_web ? 1 : 0

  provisioner "local-exec" {
    command = <<EOF
aws lambda invoke \
  --function-name ${aws_lambda_function.s3_content_custom_resource[0].function_name} \
  --payload '${jsonencode({
    RequestType = "Create"
    ResourceProperties = {
      BucketName  = aws_s3_bucket.website_s3_bucket[0].id
      Key         = "index.html"
      ContentType = "text/html"
      Body        = file("${path.module}/web-content/index.html")
    }
})}' \
  /tmp/response.json
EOF
}

depends_on = [
  aws_lambda_function.s3_content_custom_resource,
  aws_s3_bucket.website_s3_bucket
]
}

resource "null_resource" "s3_content_script" {
  count = local.create_web ? 1 : 0

  provisioner "local-exec" {
    command = <<EOF
aws lambda invoke \
  --function-name ${aws_lambda_function.s3_content_custom_resource[0].function_name} \
  --payload '${jsonencode({
    RequestType = "Create"
    ResourceProperties = {
      BucketName  = aws_s3_bucket.website_s3_bucket[0].id
      Key         = "script.js"
      ContentType = "text/javascript"
      Body        = file("${path.module}/web-content/script.js")
    }
})}' \
  /tmp/response.json
EOF
}

depends_on = [
  aws_lambda_function.s3_content_custom_resource,
  aws_s3_bucket.website_s3_bucket
]
}

resource "null_resource" "s3_content_style" {
  count = local.create_web ? 1 : 0

  provisioner "local-exec" {
    command = <<EOF
aws lambda invoke \
  --function-name ${aws_lambda_function.s3_content_custom_resource[0].function_name} \
  --payload '${jsonencode({
    RequestType = "Create"
    ResourceProperties = {
      BucketName  = aws_s3_bucket.website_s3_bucket[0].id
      Key         = "style.css"
      ContentType = "text/css"
      Body        = file("${path.module}/web-content/style.css")
    }
})}' \
  /tmp/response.json
EOF
}

depends_on = [
  aws_lambda_function.s3_content_custom_resource,
  aws_s3_bucket.website_s3_bucket
]
}

# Custom Resource for Getting Product Code
resource "null_resource" "get_product_code" {
  provisioner "local-exec" {
    command = <<EOF
aws lambda invoke \
  --function-name ${aws_lambda_function.get_product_code_custom_resource.function_name} \
  --payload '${jsonencode({
    RequestType = "Create"
    ResourceProperties = {
      ProductId = var.product_id
    }
})}' \
  /tmp/product_code_response.json
EOF
}

depends_on = [aws_lambda_function.get_product_code_custom_resource]
}

# Custom Resource for Updating Fulfillment URL
resource "null_resource" "fulfillment_url" {
  count = local.update_fulfillment ? 1 : 0

  provisioner "local-exec" {
    command = <<EOF
aws lambda invoke \
  --function-name ${aws_lambda_function.update_fulfillment_url_custom_resource[0].function_name} \
  --payload '${jsonencode({
    RequestType = "Create"
    ResourceProperties = {
      ProductId      = var.product_id
      FulfillmentUrl = local.create_web ? "https://${aws_cloudfront_distribution.cloudfront_distribution[0].domain_name}/redirectmarketplacetoken" : "https://${aws_api_gateway_rest_api.serverless_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/Prod/redirectmarketplacetoken"
    }
})}' \
  /tmp/fulfillment_response.json
EOF
}

depends_on = [
  aws_lambda_function.update_fulfillment_url_custom_resource,
  aws_cloudfront_distribution.cloudfront_distribution,
  aws_api_gateway_deployment.prod
]
}