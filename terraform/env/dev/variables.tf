variable "aws_region" {
  default = "eu-west-2"
}

variable "project" {
  default = "webhook"
}

variable "group" {
  default = "proxy"
}

variable "env" {
  default = "dev"
}

variable "stage_name" {
  default = "dev"
}


#### webhook ####

### Secrets ###

variable "env_variables" {
  type = list(string)
  default = [
    "webhook_MONGODB_STAGE",
    "webhook_MONGODB_PROD",
    "webhook_MONGODB_LOCAL"
  ]
}


### VPC ###
variable "vpc_cidr" {
  type        = string
  default     = "10.2.0.0/16"
  description = "The CIDR block for the VPC"
}

variable "enable_dns_hostnames" {
  type        = bool
  default     = true
  description = "Enable DNS Hostnames"
}

variable "enable_dns_support" {
  type        = bool
  default     = true
  description = "Enable DNS Support"
}

variable "azs" {
  type        = list(string)
  default     = ["eu-west-2a", "eu-west-2b"]
  description = "List of Availability Zones"
}

variable "public_subnets" {
  type        = list(string)
  default     = ["10.2.1.0/24", "10.2.3.0/24"]
  description = "List of public subnets"
}

variable "private_subnets" {
  type        = list(string)
  default     = ["10.2.2.0/24", "10.2.4.0/24"]
  description = "List of private subnets"
}

variable "map_public_ip_on_launch" {
  description = "Should be false if you do not want to auto-assign public IP on launch"
  type        = bool
  default     = true
}


variable "scan_on_push" {
  default = false
}
variable "image_count" {
  default = 3
}
