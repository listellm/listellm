resource "aws_acm_certificate" "listell" {
  provider = aws.us_east_1

  domain_name               = local.domain_name
  validation_method         = "DNS"
  subject_alternative_names = [local.www_domain_name]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = local.domain_name
  }
}

resource "aws_acm_certificate_validation" "listell" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.listell.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}
