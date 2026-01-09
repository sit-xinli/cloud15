# Data source for latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# AWS Academy: Use existing EC2InstanceProfile instead of creating IAM roles
# AWS Academy restricts IAM role creation, so we use the pre-existing profile
data "aws_iam_instance_profile" "lab_profile" {
  name = var.ec2_instance_profile_name
}

# Launch Template
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-${var.environment}-web-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.web_instance_type

  iam_instance_profile {
    name = data.aws_iam_instance_profile.lab_profile.name
  }

  vpc_security_group_ids = [aws_security_group.web.id]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    db_endpoint   = var.create_rds ? aws_db_instance.main[0].endpoint : (var.create_ec2_db && length(aws_instance.db) > 0 ? "${aws_instance.db[0].private_ip}:3306" : "localhost:3306")
    db_primary    = var.create_rds ? aws_db_instance.main[0].endpoint : (var.create_ec2_db && length(aws_instance.db) > 0 ? "${aws_instance.db[0].private_ip}:3306" : "localhost:3306")
    db_secondary  = var.create_rds ? aws_db_instance.main[0].endpoint : (var.create_ec2_db && length(aws_instance.db) > 1 ? "${aws_instance.db[1].private_ip}:3306" : (length(aws_instance.db) > 0 ? "${aws_instance.db[0].private_ip}:3306" : "localhost:3306"))
    db_name       = var.db_name
    db_username   = var.db_username
    db_password   = var.db_password
  }))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.project_name}-${var.environment}-web-instance"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name = "${var.project_name}-${var.environment}-web-volume"
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-lt"
  }
}
