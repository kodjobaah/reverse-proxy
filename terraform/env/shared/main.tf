provider "aws" {
}

terraform {
  backend "s3" {
    bucket         = "afriex-terraform-webhook-state-shared"
    key            = "terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "webhook-terraform-lock-shared"
    profile        = "webhook"
    encrypt        = true
  }
}

data "aws_route53_zone" "afriexdev" {
  name = var.domain_name
}
