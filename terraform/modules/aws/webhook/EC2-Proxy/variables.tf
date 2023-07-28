#######################
### Local variables ###
#######################

variable "project" {
  default = "proxy"
}


#################### Lounch configuration configs ####################

variable "instance_volume_size_gb" {
  default = "8"
}

variable "instance_volume_type" {
  default = "standard"
}

variable "instance_type" {
  default = "t3.nano"
}

variable "ec2_ami_id" {
  description = <<DESCRIPTION
  ubuntu 18.04 amd64            = "ami-09a56048b08f94cdf"
  DESCRIPTION
  default     = "ami-0015a39e4b7c0966f"
}

variable "group" {}
variable "vpc_id" {}
variable "env" {}
variable "subnet-1" {}
variable "bastion_key_pair_name" {}
