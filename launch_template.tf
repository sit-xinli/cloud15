# 最新の Amazon Linux 2023 AMI 用データソース
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

# AWS Academy: IAM ロールを作成する代わりに既存の EC2InstanceProfile を使用する
# AWS Academy は IAM ロールの作成を制限しているため、既存のプロファイルを使用します
data "aws_iam_instance_profile" "lab_profile" {
  name = var.ec2_instance_profile_name
}

# 起動テンプレート
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
    db_endpoint  = "${aws_instance.db[0].private_ip}:3306"
    db_primary   = "${aws_instance.db[0].private_ip}:3306"
    db_secondary = "${aws_instance.db[1].private_ip}:3306"
    db_name      = var.db_name
    db_username  = var.db_username
    db_password  = var.db_password
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