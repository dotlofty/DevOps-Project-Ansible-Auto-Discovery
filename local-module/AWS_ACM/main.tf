#Create ACM Certificate: Create hosted zone on the Console and change register the name servers on your domain name provider
resource "aws_acm_certificate" "dotun_certificate" {
  domain_name       = var.mydomain_name
  validation_method = "DNS"
}

#get details about the manually created R53 Hosted zone
data "aws_route53_zone" "myhostedZ" {
  name         = var.mydomain_name
  private_zone = false
}

#Domain name Validation
resource "aws_route53_record" "r53record" {
  for_each = {
    for dvo in aws_acm_certificate.dotun_certificate.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.myhostedZ.zone_id
}

#Validate ACM Certificate
resource "aws_acm_certificate_validation" "acm_valid_cert" {
  certificate_arn         = aws_acm_certificate.dotun_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.r53record : record.fqdn]
}

# creating Load balancer Listener
resource "aws_lb_listener" "dotun_alb_listener" {
  load_balancer_arn = var.alb-arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate_validation.acm_valid_cert.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = var.albtg-arn
  }
}

resource "aws_lb_listener" "dotun_alb_listener2" {
  load_balancer_arn = var.alb-arn2
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate_validation.acm_valid_cert.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = var.albtg-arn2
  }
}

#Record
resource "aws_route53_record" "myDomain_NS" {
  zone_id = data.aws_route53_zone.myhostedZ.zone_id
  name    = var.mydomain_name1
  type    = var.myrec_type

  alias {
    name                   = var.prod-lb_dns
    zone_id                = var.prod-lb_zoneid
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "myDomain_NS2" {
  zone_id = data.aws_route53_zone.myhostedZ.zone_id
  name    = var.mydomain_name2
  type    = var.myrec_type

  alias {
    name                   = var.stage-lb_dns
    zone_id                = var.stage-lb_zoneid
    evaluate_target_health = false
  }
}