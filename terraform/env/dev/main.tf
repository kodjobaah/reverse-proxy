provider "aws" {
  profile = "afriex"
  region  = var.aws_region
  version = "~> 4.0"
}

### Backend for S3 and DynamoDB ###
terraform {
  backend "s3" {
    bucket         = "afriex-terraform-webhook-state-dev"
    key            = "terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "webhook-terraform-lock-dev"
    profile        = "afriex"
    encrypt        = true
  }
}

###############################################################


data "terraform_remote_state" "shared" {
  backend = "s3"

  config = {
    bucket         = "afriex-terraform-webhook-state-shared"
    key            = "terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "webhook-terraform-lock-shared"
    profile        = "afriex"
  }
}

locals {
  route53_zone_api = data.terraform_remote_state.shared.outputs.route53_zone_api
}


#######################################################
#####################             #####################
##################### webhook #####################
#####################             #####################
#######################################################

module "route_53_webhook" {
  source = "../../modules/aws/webhook/route53"

  domains = {
    "webhook.afriexapi.com" = {
      zone_id     = local.route53_zone_api.zone_id
      domain_name = "webhook"
      alb         = module.ECS_webhook.service_alb
    }
  }
}

module "VPC" {
  source                  = "../../modules/aws/webhook/VPC"
  project                 = var.project
  group                   = var.group
  env                     = var.env
  vpc_cidr                = var.vpc_cidr
  enable_dns_hostnames    = var.enable_dns_hostnames
  enable_dns_support      = var.enable_dns_support
  azs                     = var.azs
  public_subnets          = var.public_subnets
  private_subnets         = var.private_subnets
  map_public_ip_on_launch = var.map_public_ip_on_launch
}

module "EC2_proxy" {
  source = "../../modules/aws/webhook/EC2-Proxy"

  group                 = var.group
  project               = var.project
  vpc_id                = module.VPC.vpc.id
  env                   = var.env
  subnet-1              = module.VPC.public_subnets_id[0]
  bastion_key_pair_name = module.SecretManager_webhook.bastion_key_pair_name
}

output "bastion_host_public_ip" {
  value = module.EC2_proxy.bastion_host_public_ip
}
output "bastion_host_private_key" {
  value     = module.SecretManager_webhook.bastion-private-key
  sensitive = true
}

module "ALB" {
  source            = "../../modules/aws/webhook/ALB"
  project           = var.project
  group             = var.group
  env               = var.env
  vpc_id            = module.VPC.vpc.id
  public_subnets_id = module.VPC.public_subnets_id
}

module "CodeBuild" {
  source                                = "../../modules/aws/webhook/CodeBuild"
  project                               = var.project
  group                                 = var.group
  env                                   = var.env
  region                                = var.aws_region
  vpc_id                                = module.VPC.vpc
  subnets                               = module.VPC.public_subnets_id
  webhook_uri                           = module.ECR_webhook.ecr_webhook_url
  ecs_cluster_name                      = module.ECS_webhook.cluster_name
  ecs_service_name                      = module.ECS_webhook.service_name
  log_group                             = module.CloudWatch.log_group.name
  github_personal_access_token          = module.SecretManager_webhook.github_personal_access_token
  bastion_host_ip                       = module.EC2_proxy.bastion_host_public_ip
  bastion_private_key                   = module.SecretManager_webhook.bastion-private-key
  bastion-secretmanager_private_key_arn = module.SecretManager_webhook.bastion-secretmanager_private_key_arn
  docker_hub_password                   = module.SecretManager_webhook.docker_hub_password
  depends_on                            = [module.SecretManager_webhook]
}


module "ECR_webhook" {
  source       = "../../modules/aws/webhook/ECR"
  project      = var.project
  group        = var.group
  env          = var.env
  scan_on_push = var.scan_on_push
  image_count  = var.image_count
}

module "ECS_webhook" {
  source             = "../../modules/aws/webhook/ECS"
  project            = var.project
  group              = var.group
  env                = var.env
  aws_region         = var.aws_region
  subnets            = module.VPC.public_subnets_id
  vpc_id             = module.VPC.vpc
  ecr_webhook_url    = module.ECR_webhook.ecr_webhook_url
  secret_manager_arn = module.SecretManager_webhook.environment-variables-arn
  webhook_bucket     = module.S3_webhook.s3_webhook_bucket
  env_variables      = var.env_variables
  route53_zone_api   = local.route53_zone_api
  depends_on         = [module.SecretManager_webhook]
  dummy_arn          = module.SecretManager_webhook.bastion-secretmanager_private_key_arn
}

module "SecretManager_webhook" {
  source = "../../modules/aws/webhook/SecretManager"

  project = var.project
  group   = var.group
  env     = var.env
}
module "CloudWatch" {
  source  = "../../modules/aws/webhook/CloudWatch"
  env     = var.env
  group   = var.group
  project = var.project
}

module "S3_webhook" {
  source = "../../modules/aws/webhook/S3"
  env    = var.env
}

module "Dynamodb_webhook" {
  source = "../../modules/aws/webhook/DynamoDB"
}
output "github_personal_access_token" {
  value     = module.SecretManager_webhook.github_personal_access_token
  sensitive = true
}
