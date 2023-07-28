
variable "project" {}
variable "group" {}
variable "env" {}
variable "aws_region" {}
variable "subnets" {}
variable "vpc_id" {}
variable "ecr_webhook_url" {}
variable "dummy_arn" {}
variable "secret_manager_arn" {}
variable "env_variables" {}
variable "route53_zone_api" {}
variable "webhook_bucket" {}
variable "ecs_task_execution_role_name" {
  description = "ECS task execution role name"
  default     = "myEcsTaskExecutionRole"
}

variable "app_port" {
  default = 80
}

variable "fargate_cpu" {
  default = 1024
}

variable "fargate_memory" {
  default = 2048
}
