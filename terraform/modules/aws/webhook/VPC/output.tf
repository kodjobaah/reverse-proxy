output "vpc" {
  description = "Main VPC details (ID, name, CIDR block, etc.)"
  value       = aws_vpc.main
}

output "public_subnets_id" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public.*.id
}

output "private_subnets_id" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private.*.id
}

output "all_subnets" {
  value = flatten([aws_subnet.private, aws_subnet.public])
}

output "cidr_block" {
  value = aws_vpc.main.cidr_block
}