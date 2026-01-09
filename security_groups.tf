# アプリケーションロードバランサー用セキュリティグループ
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "アプリケーションロードバランサー用セキュリティグループ"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}

# ALB セキュリティグループルール - 受信
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "任意の場所からの HTTP を許可"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "任意の場所からの HTTPS を許可"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

# ALB セキュリティグループルール - 送信
resource "aws_vpc_security_group_egress_rule" "alb_to_web" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Web インスタンスへのトラフィックを許可"
  referenced_security_group_id = aws_security_group.web.id
  ip_protocol                  = "-1"
}

# Web インスタンス用セキュリティグループ
resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Web インスタンス用セキュリティグループ"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-web-sg"
  }
}

# Web セキュリティグループルール - 受信
resource "aws_vpc_security_group_ingress_rule" "web_http_from_alb" {
  security_group_id            = aws_security_group.web.id
  description                  = "ALB からの HTTP を許可"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "web_https_from_alb" {
  security_group_id            = aws_security_group.web.id
  description                  = "ALB からの HTTPS を許可"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

# Web セキュリティグループルール - 送信
resource "aws_vpc_security_group_egress_rule" "web_to_rds" {
  security_group_id            = aws_security_group.web.id
  description                  = "RDS への MySQL トラフィックを許可"
  referenced_security_group_id = aws_security_group.rds.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "web_http_internet" {
  security_group_id = aws_security_group.web.id
  description       = "インターネットへの HTTP を許可 (更新および API 呼び出し用)"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "web_https_internet" {
  security_group_id = aws_security_group.web.id
  description       = "インターネットへの HTTPS を許可 (更新および API 呼び出し用)"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

# RDS 用セキュリティグループ
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "RDS データベース用セキュリティグループ"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  }
}

# RDS セキュリティグループルール - 受信
resource "aws_vpc_security_group_ingress_rule" "rds_from_web" {
  security_group_id            = aws_security_group.rds.id
  description                  = "Web インスタンスからの MySQL を許可"
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 3306
  to_port                      = 3306
  ip_protocol                  = "tcp"
}