variable "domains" {
  type = map(object({
    zone_id     = string
    domain_name = string
    alb         = any
  }))
}