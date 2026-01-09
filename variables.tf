# プロジェクト設定
variable "project_name" {
  description = "プロジェクトの名前、リソースの命名とタグ付けに使用されます"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "環境名 (例: dev, staging, prod)"
  type        = string
  default     = "prod"
}

# AWS リージョン設定
variable "aws_region" {
  description = "リソースをデプロイする AWS リージョン"
  type        = string
  default     = "us-east-1"
}

# VPC 設定
variable "vpc_cidr" {
  description = "VPC の CIDR ブロック"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "使用するアベイラビリティゾーンのリスト"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "パブリックサブネットの CIDR ブロック"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "プライベートサブネットの CIDR ブロック"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
}

# EC2 設定
variable "web_instance_type" {
  description = "Web サーバーのインスタンスタイプ"
  type        = string
  default     = "t3.small"
}

variable "ec2_instance_profile_name" {
  description = "EC2 インスタンス用の既存の IAM インスタンスプロファイル名 (AWS Academy: EC2InstanceProfile を使用)"
  type        = string
  default     = "EC2InstanceProfile"
}

# 負荷テスト設定
# 有効にすると、ALB に対して自動的に負荷を生成するテストインスタンスを作成します
variable "run_load_test" {
  description = "テストインスタンスを作成し、ALB に対して継続的な負荷テストを実行します (ASG スケーリングをトリガーします)"
  type        = bool
  default     = false
}

variable "test_instance_type" {
  description = "テスト/負荷生成インスタンスのインスタンスタイプ"
  type        = string
  default     = "t3.micro"
}

variable "load_test_concurrency" {
  description = "負荷テストの同時接続数"
  type        = number
  default     = 100
}

variable "load_test_duration" {
  description = "各負荷テストサイクルの期間 (秒) (0 = 連続)"
  type        = number
  default     = 300
}

# オートスケーリング設定
variable "asg_min_size" {
  description = "オートスケーリンググループ内のインスタンスの最小数"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "オートスケーリンググループ内のインスタンスの最大数"
  type        = number
  default     = 6
}

variable "asg_desired_capacity" {
  description = "オートスケーリンググループ内のインスタンスの希望数"
  type        = number
  default     = 2
}

variable "asg_health_check_grace_period" {
  description = "インスタンスがサービスインしてからヘルスチェックを行うまでの時間 (秒)"
  type        = number
  default     = 300
}

variable "asg_target_cpu_utilization" {
  description = "オートスケーリングのターゲット CPU 使用率 (%)"
  type        = number
  default     = 70
}

# データベース設定 (EC2 上の MySQL)
variable "db_ec2_instance_type" {
  description = "EC2 ベースのデータベースのインスタンスタイプ"
  type        = string
  default     = "t3.small"
}

variable "db_ec2_volume_size" {
  description = "EC2 データベースの EBS ボリュームサイズ (GB)"
  type        = number
  default     = 30
}

variable "db_name" {
  description = "作成するデータベースの名前"
  type        = string
  default     = "webapp"
}

variable "db_username" {
  description = "データベースのマスターユーザー名"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "データベースのマスターパスワード (8 文字以上である必要があります)"
  type        = string
  sensitive   = true
}

# バックエンド設定 (ドキュメント目的)
variable "backend_s3_bucket" {
  description = "Terraform ステート用の S3 バケット名 (backend.tf で更新)"
  type        = string
  default     = ""
}

variable "backend_dynamodb_table" {
  description = "Terraform ステートロック用の DynamoDB テーブル名 (backend.tf で更新)"
  type        = string
  default     = ""
}