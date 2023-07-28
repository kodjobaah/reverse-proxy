output "github_personal_access_token" {
  value = data.aws_secretsmanager_secret_version.git_personal_access_token.secret_string
}

output "bastion-private-key" {
  value = tls_private_key.bastion.private_key_pem
}

output "bastion_key_pair_name" {
  value = aws_key_pair.bastion.key_name
}

output "bastion-secretmanager_private_key_arn" {
  value = aws_secretsmanager_secret.bastion.arn
}

output "docker_hub_password" {
  value = aws_secretsmanager_secret.docker_hub_password
}

output "environment-variables-arn" {
  value = aws_secretsmanager_secret.environment-variables.arn
}

