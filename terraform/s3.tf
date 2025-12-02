# S3 Buckets and Website Configuration

# Website S3 Bucket
resource "aws_s3_bucket" "website_s3_bucket" {
  count = local.create_web ? 1 : 0

  bucket = var.website_s3_bucket_name
}

# Website S3 Bucket Log
resource "aws_s3_bucket" "website_s3_bucket_log" {
  count = local.create_web ? 1 : 0

  bucket = "${var.website_s3_bucket_name}-log"
}

# S3 Bucket Ownership Controls for Log Bucket
resource "aws_s3_bucket_ownership_controls" "website_s3_bucket_log_ownership" {
  count = local.create_web ? 1 : 0

  bucket = aws_s3_bucket.website_s3_bucket_log[0].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# S3 Bucket Intelligent Tiering for Log Bucket
resource "aws_s3_bucket_intelligent_tiering_configuration" "website_s3_bucket_log_tiering" {
  count = local.create_web ? 1 : 0

  bucket = aws_s3_bucket.website_s3_bucket_log[0].id
  name   = "${var.website_s3_bucket_name}-log"
  status = "Enabled"

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  count = local.create_web ? 1 : 0

  bucket = aws_s3_bucket.website_s3_bucket[0].id

  policy = jsonencode({
    Statement = [
      {
        Effect   = "Allow"
        Sid      = "AllowCloudFrontServicePrincipal"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website_s3_bucket[0].arn}/*"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cloudfront_distribution[0].arn
          }
        }
      }
    ]
  })
}