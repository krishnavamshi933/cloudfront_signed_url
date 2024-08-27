provider "aws" {
  region = "ap-southeast-1"
}

module "s3" {
  source = "./module1"
  cloudfront_distribution_arn = module.cloudfront.cloudfront_distribution_arn

}

module "cloudfront" {
  source = "./module2"
  cloudfront_bucket_id         = module.s3.cloudfront_bucket_id
  cloudfront_bucket_arn        = module.s3.cloudfront_bucket_arn
  cloudfront_bucket_domain_name = module.s3.cloudfront_bucket_domain_name
  cloudfront_key_group_id      = module.s3.cloudfront_key_group_id
}
