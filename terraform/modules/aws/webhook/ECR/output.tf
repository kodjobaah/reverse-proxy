output "ecr_webhook_url" {
  value = aws_ecr_repository.webhook.repository_url
}

