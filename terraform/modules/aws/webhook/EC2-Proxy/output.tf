output "bastion_host_public_ip" {
  value = aws_instance.instance.public_dns
}

