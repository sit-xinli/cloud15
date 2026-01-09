# Alternative to RDS: MySQL on EC2 Instance
# This bypasses AWS Academy RDS restrictions by running database on EC2

# Only create if RDS is disabled and EC2 DB is enabled
resource "aws_instance" "db" {
  count = var.create_rds ? 0 : (var.create_ec2_db ? 2 : 0)

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.db_ec2_instance_type
  subnet_id     = aws_subnet.private[count.index % length(aws_subnet.private)].id

  vpc_security_group_ids = [aws_security_group.rds.id]

  iam_instance_profile = data.aws_iam_instance_profile.lab_profile.name

  # EBS volume for database storage
  root_block_device {
    volume_size           = var.db_ec2_volume_size
    volume_type           = "gp3"
    delete_on_termination = false # Preserve data
    encrypted             = true
  }

  user_data = base64encode(templatefile("${path.module}/db_user_data.sh", {
    db_name     = var.db_name
    db_username = var.db_username
    db_password = var.db_password
  }))

  tags = {
    Name = "${var.project_name}-${var.environment}-mysql-ec2-${count.index == 0 ? "primary" : "secondary"}"
    Role = "Database"
    Type = count.index == 0 ? "Primary" : "Secondary"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# Output EC2 DB endpoint
output "ec2_db_endpoints" {
  description = "EC2 MySQL instance private IPs (use port 3306)"
  value       = var.create_ec2_db && !var.create_rds ? [for instance in aws_instance.db : "${instance.private_ip}:3306"] : []
}

output "ec2_db_private_ips" {
  description = "EC2 MySQL instance private IP addresses"
  value       = var.create_ec2_db && !var.create_rds ? aws_instance.db[*].private_ip : []
}

output "ec2_db_primary_endpoint" {
  description = "Primary EC2 MySQL instance endpoint"
  value       = var.create_ec2_db && !var.create_rds && length(aws_instance.db) > 0 ? "${aws_instance.db[0].private_ip}:3306" : "Not created"
}

output "ec2_db_secondary_endpoint" {
  description = "Secondary EC2 MySQL instance endpoint"
  value       = var.create_ec2_db && !var.create_rds && length(aws_instance.db) > 1 ? "${aws_instance.db[1].private_ip}:3306" : "Not created"
}
