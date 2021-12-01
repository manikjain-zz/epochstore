resource "aws_acm_certificate" "epochstore" {
  domain_name       = "api.epoch-store.xyz"
  validation_method = "DNS"
}

data "aws_route53_zone" "epochstore" {
  name         = "epoch-store.xyz"
  private_zone = false
}

resource "aws_route53_record" "epochstore" {
  for_each = {
    for dvo in aws_acm_certificate.epochstore.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.epochstore.zone_id
}

resource "aws_acm_certificate_validation" "epochstore" {
  certificate_arn         = aws_acm_certificate.epochstore.arn
  validation_record_fqdns = [for record in aws_route53_record.epochstore : record.fqdn]
}