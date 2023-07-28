# TODO: add parameter for recovery window and have it set as env variable


resource "aws_secretsmanager_secret" "environment-variables" {
  name                    = "${var.project}-${var.group}-${var.env}-environment-variables"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret" "git_personal_access_token" {
  name                    = "${var.project}-${var.group}-${var.env}-git-access-token"
  recovery_window_in_days = 0
}


resource "aws_secretsmanager_secret" "docker_hub_password" {
  name                    = "${var.project}-${var.group}-${var.env}-docker-hub-password"
  recovery_window_in_days = 0
}

data "aws_secretsmanager_secret" "git_personal_access_token" {
  arn = aws_secretsmanager_secret.git_personal_access_token.arn
}

data "aws_secretsmanager_secret_version" "git_personal_access_token" {
  secret_id = data.aws_secretsmanager_secret.git_personal_access_token.arn
}


resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion" {
  key_name   = "afriex-webhook-bastion-${var.env}"
  public_key = tls_private_key.bastion.public_key_openssh
}

resource "aws_secretsmanager_secret" "bastion" {
  name                    = "afriex-webhook-bastion-private-key-${var.env}"
  description             = "Private Key used to access the bastion"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "bastion" {
  secret_id     = aws_secretsmanager_secret.bastion.id
  secret_string = base64encode(tls_private_key.bastion.private_key_pem)
}

data "aws_secretsmanager_secret_version" "bastion" {
  secret_id = aws_secretsmanager_secret.bastion.arn
}

