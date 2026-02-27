# Adopt manually-provisioned resources into Terraform state.
# Run: terraform init && terraform plan
# Review the plan carefully — no destructive changes expected.

import {
  to = aws_s3_bucket.origin
  id = "listell-co-uk-origin"
}

import {
  to = aws_s3_bucket_public_access_block.origin
  id = "listell-co-uk-origin"
}

import {
  to = aws_s3_bucket_policy.origin
  id = "listell-co-uk-origin"
}

import {
  to = aws_s3_object.index
  id = "listell-co-uk-origin/index.html"
}

import {
  provider = aws.us_east_1
  to       = aws_acm_certificate.listell
  id       = "arn:aws:acm:us-east-1:552644939129:certificate/1dee6ecf-3994-4f24-a948-8b921f93d39b"
}

import {
  to = aws_cloudfront_origin_access_control.listell
  id = "E3O8ZSCPXMMUFI"
}

import {
  to = aws_cloudfront_distribution.listell
  id = "E1B1CZ81Y7ND1M"
}

# Route 53 — apex records
import {
  to = aws_route53_record.apex_a
  id = "Z0437334HZSV61L914JE_listell.co.uk_A"
}

import {
  to = aws_route53_record.apex_aaaa
  id = "Z0437334HZSV61L914JE_listell.co.uk_AAAA"
}

import {
  to = aws_route53_record.www_a
  id = "Z0437334HZSV61L914JE_www.listell.co.uk_A"
}

import {
  to = aws_route53_record.www_aaaa
  id = "Z0437334HZSV61L914JE_www.listell.co.uk_AAAA"
}

# Route 53 — ACM DNS validation CNAMEs
# for_each key = domain name from domain_validation_options
import {
  to = aws_route53_record.acm_validation["listell.co.uk"]
  id = "Z0437334HZSV61L914JE__1350184d18c7f2ca546334fafefcc6cd.listell.co.uk_CNAME"
}

import {
  to = aws_route53_record.acm_validation["www.listell.co.uk"]
  id = "Z0437334HZSV61L914JE__29fa1767377e63042a5354b4a8f60ded.www.listell.co.uk_CNAME"
}
