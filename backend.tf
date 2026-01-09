# Terraform バックエンド設定
#
# 重要: この設定のコメントを解除する前に、以下を行う必要があります:
# 1. バージョニングを有効にしたステート保存用の S3 バケットを作成する
# 2. ステートロック用にパーティションキー "LockID" (String) を持つ DynamoDB テーブルを作成する
# 3. 以下の bucket と dynamodb_table の値を更新する
# 4. 実行: terraform init -migrate-state
#
# リソースを作成するための AWS CLI コマンドの例:
#
# aws s3api create-bucket --bucket YOUR-BUCKET-NAME --region us-east-1
# aws s3api put-bucket-versioning --bucket YOUR-BUCKET-NAME --versioning-configuration Status=Enabled
# aws dynamodb create-table \
#   --table-name YOUR-TABLE-NAME \
#   --attribute-definitions AttributeName=LockID,AttributeType=S \
#   --key-schema AttributeName=LockID,KeyType=HASH \
#   --billing-mode PAY_PER_REQUEST \
#   --region us-east-1

# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "cloud15/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "your-terraform-locks"
#     encrypt        = true
#   }
# }