output "zone_id" {
    value = data.aws_route53_zone.myhostedZ.zone_id 
  
}

output "zone_name" {
    value = data.aws_route53_zone.myhostedZ.name
}