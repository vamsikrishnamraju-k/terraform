output "vpc_id" {
  value = aws_vpc.this.id
}

output "igw_id" {
  description = "internet gateway ID"
  value       = aws_internet_gateway.this.id
}


output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [for subnet in aws_subnet.private : subnet.id]
}