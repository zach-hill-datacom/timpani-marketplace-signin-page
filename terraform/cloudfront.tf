# CloudFront Distribution and Origin Access Control

# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "cloudfront_origin_access_control" {
  count = local.create_web ? 1 : 0

  name                              = "OAC-${local.stack_id_short}"
  description                       = "Origin Access Control for static website-${local.stack_id_short}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "cloudfront_distribution" {
  count = local.create_web ? 1 : 0

  comment             = "Cloudfront distribution for serverless website-${local.stack_id_short}"
  default_root_object = "index.html"
  enabled             = true
  http_version        = "http2"

  origin {
    domain_name              = aws_s3_bucket.website_s3_bucket[0].bucket_regional_domain_name
    origin_id                = "s3-website"
    origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront_origin_access_control[0].id

    s3_origin_config {
      origin_access_identity = ""
    }
  }

  origin {
    domain_name = "${aws_api_gateway_rest_api.serverless_api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com"
    origin_id   = "api-gateway"
    origin_path = "/Prod"

    custom_origin_config {
      http_port              = 443
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-website"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/redirectmarketplacetoken"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "api-gateway"
    viewer_protocol_policy = "redirect-to-https"

    # Using AWS managed policies
    response_headers_policy_id = "60669652-455b-4ae9-85a4-c4c02393f86c"
    cache_policy_id            = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id   = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  ordered_cache_behavior {
    path_pattern           = "/subscriber"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "api-gateway"
    viewer_protocol_policy = "redirect-to-https"

    # Using AWS managed policies
    response_headers_policy_id = "60669652-455b-4ae9-85a4-c4c02393f86c"
    cache_policy_id            = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id   = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  logging_config {
    bucket          = aws_s3_bucket.website_s3_bucket_log[0].bucket_domain_name
    include_cookies = false
    prefix          = "access-logs"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  depends_on = [aws_api_gateway_deployment.prod]
}