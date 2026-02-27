data "aws_route53_zone" "listell" {
  name = "${local.domain_name}."
}

# ACM DNS validation records — keyed by domain name from certificate validation options
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.listell.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.listell.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_route53_record" "apex_a" {
  zone_id = data.aws_route53_zone.listell.zone_id
  name    = local.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.listell.domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apex_aaaa" {
  zone_id = data.aws_route53_zone.listell.zone_id
  name    = local.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.listell.domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_a" {
  zone_id = data.aws_route53_zone.listell.zone_id
  name    = local.www_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.listell.domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_aaaa" {
  zone_id = data.aws_route53_zone.listell.zone_id
  name    = local.www_domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.listell.domain_name
    zone_id                = local.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}
