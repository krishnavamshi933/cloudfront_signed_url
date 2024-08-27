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
  bucket        = "my-cloudfront-bucket-krish"
  force_destroy = true
  tags = {
    Name        = "CloudFront S3 Bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_policy" "cloudfront_bucket_policy" {
  bucket    = aws_s3_bucket.cloudfront_bucket.id

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
            "AWS:SourceArn" = var.cloudfront_distribution_arn
          }
        }
      }
    ]
  })
}
variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  type        = string
}

output "cloudfront_bucket_id" {
  value = aws_s3_bucket.cloudfront_bucket.id
}

output "cloudfront_bucket_arn" {
  value = aws_s3_bucket.cloudfront_bucket.arn
}

output "cloudfront_bucket_domain_name" {
  value = aws_s3_bucket.cloudfront_bucket.bucket_regional_domain_name
}

output "cloudfront_key_group_id" {
  value = aws_cloudfront_key_group.key_group.id
}
