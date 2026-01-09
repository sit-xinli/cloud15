# EC2 インスタンス上の MySQL
# 専用 EC2 インスタンスを使用してデータベース層を提供

resource "aws_instance" "db" {
  count = 2

  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.db_ec2_instance_type
  subnet_id     = aws_subnet.private[count.index % length(aws_subnet.private)].id

  vpc_security_group_ids = [aws_security_group.rds.id]

  iam_instance_profile = data.aws_iam_instance_profile.lab_profile.name

  # データベースストレージ用の EBS ボリューム
  root_block_device {
    volume_size           = var.db_ec2_volume_size
    volume_type           = "gp3"
    delete_on_termination = false # データを保持
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


output "db_private_ips" {
  description = "MySQL instance private IP addresses"
  value       = aws_instance.db[*].private_ip
}

output "db_primary_endpoint" {
  description = "Primary database endpoint"
  value       = "${aws_instance.db[0].private_ip}:3306"
}

output "db_secondary_endpoint" {
  description = "Secondary database endpoint"
  value       = "${aws_instance.db[1].private_ip}:3306"
}