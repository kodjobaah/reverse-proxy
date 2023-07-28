output "cluster_name" {
  value = aws_ecs_cluster.webhook.name
}

output "service_name" {
  value = aws_ecs_service.main.name
}


output "service_alb" {
  value = aws_alb.main
}

output "task_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}
