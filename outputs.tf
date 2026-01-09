# VPC 出力
output "vpc_id" {
  description = "VPC の ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC の CIDR ブロック"
  value       = aws_vpc.main.cidr_block
}

# サブネット出力
output "public_subnet_ids" {
  description = "パブリックサブネットの ID"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "プライベートサブネットの ID"
  value       = aws_subnet.private[*].id
}

# NAT ゲートウェイ出力
output "nat_gateway_ip" {
  description = "NAT ゲートウェイの Elastic IP アドレス (ホワイトリスト登録用)"
  value       = aws_eip.nat.public_ip
}

# アプリケーションロードバランサー出力
output "alb_dns_url" {
  description = "アプリケーションロードバランサーの DNS 名 (アプリケーションへのアクセスに使用)"
  value       = "http://${aws_lb.main.dns_name}"
}

output "alb_arn" {
  description = "アプリケーションロードバランサーの ARN"
  value       = aws_lb.main.arn
}

output "alb_zone_id" {
  description = "アプリケーションロードバランサーのゾーン ID (Route53 エイリアスレコード用)"
  value       = aws_lb.main.zone_id
}

# オートスケーリンググループ出力
output "web_asg_name" {
  description = "オートスケーリンググループの名前"
  value       = aws_autoscaling_group.web.name
}

output "web_asg_arn" {
  description = "オートスケーリンググループの ARN"
  value       = aws_autoscaling_group.web.arn
}

# セキュリティグループ出力
output "alb_security_group_id" {
  description = "ALB セキュリティグループの ID"
  value       = aws_security_group.alb.id
}

output "web_security_group_id" {
  description = "Web インスタンスセキュリティグループの ID"
  value       = aws_security_group.web.id
}

output "rds_security_group_id" {
  description = "RDS セキュリティグループの ID"
  value       = aws_security_group.rds.id
}

# 負荷テストインスタンス出力 (var.run_load_test = true の場合のみ利用可能)
output "test_instance_public_ip" {
  description = "負荷テストインスタンスのパブリック IP アドレス (http://TEST_IP 経由でアクセス)"
  value       = var.run_load_test ? aws_instance.test[0].public_ip : null
}

output "test_instance_id" {
  description = "負荷テストインスタンスのインスタンス ID"
  value       = var.run_load_test ? aws_instance.test[0].id : null
}

output "test_instance_url" {
  description = "負荷テストダッシュボードにアクセスするための URL"
  value       = var.run_load_test ? "http://${aws_instance.test[0].public_ip}" : "Load testing disabled - set run_load_test = true to enable"
}