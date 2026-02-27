locals {
  domain_name     = "listell.co.uk"
  www_domain_name = "www.listell.co.uk"
  bucket_name     = "listell-co-uk-origin"

  # AWS-managed CloudFront hosted zone ID — fixed across all regions/accounts
  cloudfront_hosted_zone_id = "Z2FDTNDATAQYW2"
}
