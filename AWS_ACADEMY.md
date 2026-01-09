# AWS Academy 互換性に関する注意事項

このドキュメントでは、AWS Academy の制限された権限内でプロジェクトがどのように動作するかについて説明します。

## AWS Academy の制限事項

AWS Academy 環境では、IAM 権限が制限されています。具体的には、以下のことは**できません**:
- IAM ロールまたはポリシーの作成
- RDS 拡張モニタリングの有効化（IAM ロールが必要）
- RDS の一部の高度な機能の使用（Performance Insights、カスタムパラメータグループ）

## 現在のソリューション

このプロジェクトは、RDS の代わりに **専用 EC2 インスタンス上の MySQL** を使用しており、AWS Academy の制約内で完全に動作します。

## AWS Academy 用に加えられた変更

### 1. EC2 IAM インスタンスプロファイル

**オリジナル**: SSM および CloudWatch 権限を持つカスタム IAM ロールを作成
```hcl
resource "aws_iam_role" "web_instance" { ... }
resource "aws_iam_instance_profile" "web" { ... }
```

**変更後**: AWS Academy が提供する既存の `EC2InstanceProfile` を使用
```hcl
data "aws_iam_instance_profile" "lab_profile" {
  name = var.ec2_instance_profile_name  # デフォルト: "EC2InstanceProfile"
}
```

**ファイル**: `launch_template.tf`

### 2. データベースソリューション

**オリジナル**: カスタムパラメータグループと拡張モニタリングを備えた RDS の使用を試行

**変更後**: 代わりに専用 EC2 インスタンス上の MySQL を使用
- IAM 制限なし（既存の EC2InstanceProfile を使用）
- MySQL 構成の完全な制御
- cron ジョブによる自動バックアップ
- 詳細は [EC2_DATABASE.md](EC2_DATABASE.md) を参照

## 一般的な問題と解決策

### 問題: EC2 インスタンスプロファイルが見つからない

**エラー**:
```
Error: Invalid IAM Instance Profile name
```

**解決策**:
AWS Academy 環境でインスタンスプロファイル名を確認してください:
```bash
aws iam list-instance-profiles
```

`terraform.tfvars` を更新します:
```hcl
ec2_instance_profile_name = "YourActualProfileName"  # 一般的な例: EC2InstanceProfile, LabInstanceProfile, Work-Role
```

## AWS Academy で利用可能な機能

すべてのコア機能は AWS Academy の制約内で動作します:

✅ **マルチ AZ VPC アーキテクチャ** - パブリック/プライベートサブネットを持つ2つのアベイラビリティゾーン
✅ **Application Load Balancer** - ヘルスチェック付きのインターネット向けロードバランサー
✅ **Auto Scaling Group** - CPU ベースのスケーリング（2-6 Web インスタンス）
✅ **EC2 上の MySQL データベース** - プライベートサブネット内の2つのインスタンス、自動バックアップ付き
✅ **セキュリティグループ** - 適切なネットワーク分離と最小権限アクセス
✅ **NAT ゲートウェイ** - プライベートサブネット用のアウトバウンドインターネットアクセス
✅ **EBS 暗号化** - すべての EC2 インスタンスのボリュームを暗号化
✅ **CloudWatch メトリクス** - すべてのリソースのモニタリング
✅ **Session Manager** - インスタンスへの SSH レスアクセス

## デプロイメントワークフロー

1. **変数の設定**: AWS Academy の設定に合わせて `terraform.tfvars` を編集
2. **初期化**: `terraform init` を実行
3. **プラン**: `terraform plan` を実行して変更をプレビュー
4. **適用**: `terraform apply` を実行してインフラストラクチャを作成

権限エラーが発生した場合は、EC2 インスタンスプロファイル名が AWS Academy 環境と一致していることを確認してください。

## 比較: フルバージョン vs AWS Academy バージョン

| 機能 | フルバージョン | AWS Academy バージョン |
|---------|-------------|---------------------|
| カスタム IAM ロール | ✅ 作成される | ❌ EC2InstanceProfile を使用 |
| データベース | ✅ RDS マルチ AZ | ✅ EC2 上の MySQL（2インスタンス） |
| RDS 機能 | ✅ 拡張モニタリングなど | ➖ 該当なし（EC2 を使用） |
| VPC & ネットワーク | ✅ 全機能 | ✅ 全機能 |
| ALB & Auto Scaling | ✅ 全機能 | ✅ 全機能 |
| セキュリティグループ | ✅ 全機能 | ✅ 全機能 |
| EBS 暗号化 | ✅ 有効 | ✅ 有効 |
| Session Manager | ✅ 有効 | ✅ 有効 |

## 標準 AWS アカウントへの変換

標準の AWS アカウント（非 Academy）にデプロイする場合、オプションで以下を実行できます:

1. 既存の EC2InstanceProfile を使用する代わりに **カスタム IAM ロールを作成**
2. **RDS マルチ AZ へのアップグレード**: EC2 ベースの MySQL をマネージド RDS に置き換え
   - 自動マルチ AZ フェイルオーバーを提供
   - 拡張モニタリングと Performance Insights
   - 自動バックアップとポイントインタイムリカバリ
3. `terraform plan` を実行して変更を確認

## 追加リソース

- [AWS Academy Learner Lab](https://awsacademy.instructure.com/)
- [AWS Academy IAM 制限](https://docs.aws.amazon.com/academy/)
- [Terraform AWS プロバイダードキュメント](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## サポート

ここでカバーされていない他の AWS Academy の制限に遭遇した場合:
1. 特定の権限拒否についてエラーメッセージを確認してください
2. AWS リソースタイプを探してください（例: `iam:CreateRole`, `rds:CreateDBParameterGroup`）
3. リソースが以下のようにできるか判断してください:
   - 削除（重要でない場合）
   - 既存の AWS Academy リソースへの置き換え
   - デフォルト設定を使用するように簡素化

調査結果を文書化し、将来の参照のためにこのファイルを更新してください。