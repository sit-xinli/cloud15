# Alternative to RDS: MySQL on EC2 Instance
# This bypasses AWS Academy RDS restrictions by running database on EC2

# Only create if RDS is disabled and EC2 DB is enabled
resource "aws_instance" "db" {
  count = var.create_rds ? 0 : var.create_ec2_db ? 1 : 0

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.db_ec2_instance_type
  subnet_id     = aws_subnet.private[0].id

  vpc_security_group_ids = [aws_security_group.rds.id]

  # AWS Academy: Don't use IAM instance profile for DB instance
  # Database doesn't need AWS API access, only MySQL
  # iam_instance_profile = data.aws_iam_instance_profile.lab_profile.name

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
    Name = "${var.project_name}-${var.environment}-mysql-ec2"
    Role = "Database"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# Output EC2 DB endpoint
output "ec2_db_endpoint" {
  description = "EC2 MySQL instance private IP (use port 3306)"
  value       = var.create_ec2_db && !var.create_rds ? (length(aws_instance.db) > 0 ? "${aws_instance.db[0].private_ip}:3306" : "Not created") : "Using RDS or no DB"
}

output "ec2_db_private_ip" {
  description = "EC2 MySQL instance private IP address"
  value       = var.create_ec2_db && !var.create_rds ? (length(aws_instance.db) > 0 ? aws_instance.db[0].private_ip : "Not created") : "Using RDS or no DB"
}
