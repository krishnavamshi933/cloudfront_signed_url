variable "cloudfront_bucket_id" {
  description = "ID of the CloudFront S3 bucket"
  type        = string
}

variable "cloudfront_bucket_arn" {
  description = "ARN of the CloudFront S3 bucket"
  type        = string
}

variable "cloudfront_bucket_domain_name" {
  description = "Domain name of the CloudFront S3 bucket"
  type        = string
}

variable "cloudfront_key_group_id" {
  description = "ID of the CloudFront key group"
  type        = string
}
