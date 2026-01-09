# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

# NAT Gateway Output
output "nat_gateway_ip" {
  description = "Elastic IP address of NAT Gateway (for whitelisting)"
  value       = aws_eip.nat.public_ip
}

# Application Load Balancer Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer (use this to access the application)"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer (for Route53 alias records)"
  value       = aws_lb.main.zone_id
}

# Auto Scaling Group Outputs
output "web_asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}

output "web_asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.arn
}

# RDS Outputs
output "rds_endpoint" {
  description = "Connection endpoint for RDS database"
  value       = var.create_rds ? aws_db_instance.main[0].endpoint : "RDS not created"
}

output "rds_address" {
  description = "Hostname of the RDS instance"
  value       = var.create_rds ? aws_db_instance.main[0].address : "RDS not created"
}

output "rds_port" {
  description = "Port of the RDS instance"
  value       = var.create_rds ? aws_db_instance.main[0].port : 0
}

output "rds_database_name" {
  description = "Name of the database"
  value       = var.create_rds ? aws_db_instance.main[0].db_name : "RDS not created"
}

output "rds_arn" {
  description = "ARN of the RDS instance"
  value       = var.create_rds ? aws_db_instance.main[0].arn : "RDS not created"
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "web_security_group_id" {
  description = "ID of the web instance security group"
  value       = aws_security_group.web.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}
