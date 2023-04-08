output "alb-TG" {
  value = aws_lb_target_group.dotun-ALB-TG-QA.arn
}

output "alb-DNS" {
  value = aws_lb.dotun-ALB-QA.dns_name
}

output "alb-zone-id"{
    value = aws_lb.dotun-ALB-QA.zone_id
}

output "alb-arn" {
  value = aws_lb.dotun-ALB-QA.arn
}