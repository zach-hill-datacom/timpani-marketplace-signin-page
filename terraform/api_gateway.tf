# API Gateway

resource "aws_api_gateway_rest_api" "serverless_api" {
  name        = "ServerlessApi-${local.stack_id_short}"
  description = "AWS Marketplace Serverless SaaS Integration API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "prod" {
  depends_on = [
    aws_api_gateway_method.subscriber_post,
    aws_api_gateway_method.subscriber_options,
    aws_api_gateway_method.redirect_post,
    aws_api_gateway_method.redirect_options,
    aws_api_gateway_integration.subscriber_post,
    aws_api_gateway_integration.subscriber_options,
    aws_api_gateway_integration.redirect_post,
    aws_api_gateway_integration.redirect_options
  ]

  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  stage_name  = "Prod"
}

# CORS Configuration
resource "aws_api_gateway_gateway_response" "cors" {
  rest_api_id   = aws_api_gateway_rest_api.serverless_api.id
  response_type = "DEFAULT_4XX"

  response_templates = {
    "application/json" = "{'message':$context.error.messageString}"
  }

  response_parameters = {
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'*'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
  }
}

# /subscriber resource
resource "aws_api_gateway_resource" "subscriber" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  parent_id   = aws_api_gateway_rest_api.serverless_api.root_resource_id
  path_part   = "subscriber"
}

# /subscriber POST method
resource "aws_api_gateway_method" "subscriber_post" {
  rest_api_id   = aws_api_gateway_rest_api.serverless_api.id
  resource_id   = aws_api_gateway_resource.subscriber.id
  http_method   = "POST"
  authorization = "NONE"
}

# /subscriber OPTIONS method
resource "aws_api_gateway_method" "subscriber_options" {
  rest_api_id   = aws_api_gateway_rest_api.serverless_api.id
  resource_id   = aws_api_gateway_resource.subscriber.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# /subscriber POST integration
resource "aws_api_gateway_integration" "subscriber_post" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.subscriber.id
  http_method = aws_api_gateway_method.subscriber_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.register_new_marketplace_customer.invoke_arn
}

# /subscriber OPTIONS integration
resource "aws_api_gateway_integration" "subscriber_options" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.subscriber.id
  http_method = aws_api_gateway_method.subscriber_options.http_method

  type = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# /subscriber OPTIONS method response
resource "aws_api_gateway_method_response" "subscriber_options_200" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.subscriber.id
  http_method = aws_api_gateway_method.subscriber_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# /subscriber OPTIONS integration response
resource "aws_api_gateway_integration_response" "subscriber_options_200" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.subscriber.id
  http_method = aws_api_gateway_method.subscriber_options.http_method
  status_code = aws_api_gateway_method_response.subscriber_options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# /redirectmarketplacetoken resource
resource "aws_api_gateway_resource" "redirect_marketplace_token" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  parent_id   = aws_api_gateway_rest_api.serverless_api.root_resource_id
  path_part   = "redirectmarketplacetoken"
}

# /redirectmarketplacetoken POST method
resource "aws_api_gateway_method" "redirect_post" {
  rest_api_id   = aws_api_gateway_rest_api.serverless_api.id
  resource_id   = aws_api_gateway_resource.redirect_marketplace_token.id
  http_method   = "POST"
  authorization = "NONE"
}

# /redirectmarketplacetoken OPTIONS method
resource "aws_api_gateway_method" "redirect_options" {
  rest_api_id   = aws_api_gateway_rest_api.serverless_api.id
  resource_id   = aws_api_gateway_resource.redirect_marketplace_token.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# /redirectmarketplacetoken POST integration
resource "aws_api_gateway_integration" "redirect_post" {
  count = local.create_web ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.redirect_marketplace_token.id
  http_method = aws_api_gateway_method.redirect_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_redirect_post_requests[0].invoke_arn
}

# /redirectmarketplacetoken OPTIONS integration
resource "aws_api_gateway_integration" "redirect_options" {
  rest_api_id = aws_api_gateway_rest_api.serverless_api.id
  resource_id = aws_api_gateway_resource.redirect_marketplace_token.id
  http_method = aws_api_gateway_method.redirect_options.http_method

  type = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# Lambda permissions for API Gateway
resource "aws_lambda_permission" "allow_api_gateway_subscriber" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.register_new_marketplace_customer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.serverless_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "allow_api_gateway_redirect" {
  count = local.create_web ? 1 : 0

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_redirect_post_requests[0].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.serverless_api.execution_arn}/*/*"
}