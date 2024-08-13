provider "aws" {
  region = "ap-southeast-1"
}

# Generate an RSA Private Key
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Save the private key to a file (optional)
resource "local_file" "private_key" {
  content  = tls_private_key.example.private_key_pem
  filename = "${path.module}/private_key.pem"
}

# Extract the public key from the private key
resource "local_file" "public_key" {
  content  = tls_private_key.example.public_key_pem
  filename = "${path.module}/public_key.pem"
}

# CloudFront Public Key
resource "aws_cloudfront_public_key" "cloudfront_public_key" {
  name        = "my-cloudfront-public-key"
  encoded_key = tls_private_key.example.public_key_pem
  comment     = "Public key for CloudFront"
}

# CloudFront Key Group
resource "aws_cloudfront_key_group" "key_group" {
  name    = "my-cloudfront-key-group"
  comment = "Key Group for CloudFront"

  items = [aws_cloudfront_public_key.cloudfront_public_key.id]
}

# S3 Bucket for CloudFront Origin
resource "aws_s3_bucket" "cloudfront_bucket" {
  bucket = "my-cloudfront-bucket-krish"

  tags = {
    Name        = "CloudFront S3 Bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_policy" "cloudfront_bucket_policy" {
  bucket = aws_s3_bucket.cloudfront_bucket.id
  depends_on = [aws_cloudfront_distribution.cloudfront_distribution]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.cloudfront_bucket.arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "${aws_cloudfront_distribution.cloudfront_distribution.arn}"
          }
        }
      }
    ]
  })
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Access Identity for S3"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "cloudfront_distribution" {
  origin {
    domain_name = aws_s3_bucket.cloudfront_bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.cloudfront_bucket.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.cloudfront_bucket.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    # Require signed URLs
    trusted_key_groups = [aws_cloudfront_key_group.key_group.id]
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  depends_on = [aws_cloudfront_key_group.key_group]
}
