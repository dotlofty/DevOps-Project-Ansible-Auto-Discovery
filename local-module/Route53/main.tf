#Create Route 53
data "aws_route53_zone" "myhostedZ" {
  name         = var.mydomain_name
  private_zone = false
}

#Route53 Record
resource "aws_route53_record" "myDomain_NS" {
  zone_id = data.aws_route53_zone.myhostedZ.zone_id
  name    = var.mydomain_name
  type    = var.myrec_type

  alias {
    name                   = var.lb_dns
    zone_id                = var.lb_zoneid
    evaluate_target_health = true
  }
}