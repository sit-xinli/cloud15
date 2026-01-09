# 負荷テストインスタンス
# ALB に対して自動的に負荷を生成するテストインスタンスを作成します
# var.run_load_test で有効化/無効化

# テストインスタンス用セキュリティグループ
resource "aws_security_group" "test_instance" {
  count       = var.run_load_test ? 1 : 0
  name        = "${var.project_name}-${var.environment}-test-sg"
  description = "Security group for test EC2 instance"
  vpc_id      = aws_vpc.main.id

  # 任意の場所からの SSH を許可 (テスト目的のみ)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access for testing"
  }

  # 任意の場所からの HTTP を許可
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP access for testing"
  }

  # すべての送信トラフィックを許可
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-test-sg"
  }
}

# テスト EC2 インスタンス - 負荷ジェネレーター
resource "aws_instance" "test" {
  count                  = var.run_load_test ? 1 : 0
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.test_instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.test_instance[0].id]
  iam_instance_profile   = data.aws_iam_instance_profile.lab_profile.name
  key_name               = var.key_name

  # 直接アクセスのためにパブリック IP を有効化
  associate_public_ip_address = true

  # 負荷テスト機能を備えた専用のテスト user_data スクリプトを使用
  # インスタンス作成時に負荷テストが常に自動的に開始されます
  user_data = base64encode(templatefile("${path.module}/test_user_data.sh", {
    db_endpoint           = length(aws_instance.db) > 0 ? "${aws_instance.db[0].private_ip}:3306" : "N/A"
    db_primary            = length(aws_instance.db) > 0 ? "${aws_instance.db[0].private_ip}:3306" : "N/A"
    db_secondary          = length(aws_instance.db) > 1 ? "${aws_instance.db[1].private_ip}:3306" : "N/A"
    db_name               = var.db_name
    db_username           = var.db_username
    db_password           = var.db_password
    alb_dns               = aws_lb.main.dns_name
    load_test_concurrency = var.load_test_concurrency
    load_test_duration    = var.load_test_duration
  }))

  # EBS ボリューム設定
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  # 詳細モニタリングを有効化
  monitoring = true

  # IMDSv2 設定 (本番環境と同じ)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-test-instance"
  }
}