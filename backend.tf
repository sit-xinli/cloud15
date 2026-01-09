# Terraform Backend Configuration
#
# IMPORTANT: Before uncommenting this configuration, you must:
# 1. Create an S3 bucket for state storage with versioning enabled
# 2. Create a DynamoDB table with partition key "LockID" (String) for state locking
# 3. Update the bucket and dynamodb_table values below
# 4. Run: terraform init -migrate-state
#
# Example AWS CLI commands to create resources:
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
