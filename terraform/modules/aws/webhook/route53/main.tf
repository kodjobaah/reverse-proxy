resource "aws_route53_record" "subdomain_webhook" {
  for_each = var.domains
  zone_id  = each.value.zone_id
  name     = each.value.domain_name
  type     = "A"

  alias {
    name                   = each.value.alb.dns_name
    zone_id                = each.value.alb.zone_id
    evaluate_target_health = true
  }
}
