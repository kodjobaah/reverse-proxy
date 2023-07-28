output "alb_endpoint" {
  value = aws_lb.alb.name
}

output "target_group" {
  value = aws_lb_target_group.alb.name
}

output "target_group_arn" {
  value = aws_lb_target_group.alb.arn
}

output "alb_arn_suffix" {
  value = aws_lb.alb.arn_suffix
}

output "target_group_arn_suffix" {
  value = aws_lb_target_group.alb.arn_suffix
}