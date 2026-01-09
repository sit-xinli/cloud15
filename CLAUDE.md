# CLAUDE.md

このファイルは、このリポジトリのコードを操作する際の Claude Code (claude.ai/code) へのガイダンスを提供します。

## プロジェクト概要

これは、2つのアベイラビリティゾーンにまたがる高可用性マルチティア AWS インフラストラクチャをデプロイする Terraform プロジェクトです。アーキテクチャは、ロードバランシング、オートスケーリング、マルチ AZ RDS データベースを備えた、本番環境に対応した Web アプリケーション環境を実装しています。

**詳細なアーキテクチャドキュメントについては、[architecture.md](architecture.md) を参照してください。**

**AWS Academy との互換性に関する注意事項については、[AWS_ACADEMY.md](AWS_ACADEMY.md) を参照してください。**

### AWS Academy 互換性

このプロジェクトは、AWS Academy の制限された IAM 権限で動作するように変更されています:
- IAM ロールを作成する代わりに、既存の `EC2InstanceProfile` を使用
- RDS 拡張モニタリング、Performance Insights、カスタムパラメータグループを無効化
- すべてのコアネットワーク、ALB、Auto Scaling、および基本的な RDS 機能は引き続き機能します

詳細な変更点とトラブルシューティングについては、[AWS_ACADEMY.md](AWS_ACADEMY.md) を参照してください。

## Auto Scaling 設定

ASG（Auto Scaling Group）は、負荷に応じて **1 から 5 インスタンス** までスケールするように構成されています:
- **最小**: 1 インスタンス（アイドル時のコスト削減）
- **最大**: 5 インスタンス（ピーク負荷への対応）
- **トリガー**: CPU > 70% または リクエスト数 > 1000/インスタンス

## 一般的なコマンド

### Terraform 操作

```bash
# Terraform の初期化（プロバイダーとモジュールのダウンロード）
terraform init

# Terraform ファイルのフォーマット
terraform fmt -recursive

# 設定の検証
terraform validate

# 変更の計画（ドライラン）
terraform plan

# 変数ファイルを指定して計画
terraform plan -var-file="terraform.tfvars"

# 変更の適用
terraform apply

# 確認プロンプトなしで適用
terraform apply -auto-approve

# インフラストラクチャの破棄
terraform destroy

# 現在の状態を表示
terraform show

# 状態内のリソースをリスト
terraform state list

# 出力値
terraform output
```

### テストとリンティング

```bash
# tflint の実行（インストールされている場合）
tflint

# terraform fmt チェックの実行
terraform fmt -check -recursive

# すべての設定を検証
terraform validate
```

## アーキテクチャクイックリファレンス

インフラストラクチャは、以下の **マルチティア、マルチ AZ アーキテクチャ** パターンに従っています:
- **VPC** (10.0.0.0/16) - 2つのアベイラビリティゾーンにまたがる
- **パブリックサブネット** (10.0.0.0/24, 10.0.2.0/24) - ALB と NAT ゲートウェイ用
- **プライベートサブネット** (10.0.1.0/24, 10.0.3.0/24) - Web インスタンスと RDS 用
- **Application Load Balancer** - Auto Scaling Group にトラフィックを分散
- **マルチ AZ RDS MySQL** - データベースの高可用性用

**完全なアーキテクチャの詳細、トラフィックフロー、設計上の決定事項については、[architecture.md](architecture.md) を参照してください。**

## プロジェクト構造

Terraform コードは、リソースタイプと論理コンポーネントによって整理されています:

```
.
├── CLAUDE.md               # このファイル - 開発ガイダンス
├── architecture.md         # 詳細なアーキテクチャドキュメント
├── README.md               # ユーザー向けプロジェクトドキュメント
├── versions.tf             # Terraform およびプロバイダーのバージョン制約
├── provider.tf             # AWS プロバイダー設定
├── backend.tf              # リモートステート設定 (S3 + DynamoDB)
├── variables.tf            # 入力変数定義
├── outputs.tf              # 出力値定義
├── terraform.tfvars        # 変数値 (git無視)
├── vpc.tf                  # VPC、インターネットゲートウェイ、ルートテーブル
├── subnets.tf              # 両方の AZ にまたがるサブネット定義
├── nat.tf                  # NAT ゲートウェイと Elastic IP
├── security_groups.tf      # 全ティアのセキュリティグループルール
├── alb.tf                  # Application Load Balancer 設定
├── launch_template.tf      # IAM ロールを含む EC2 起動テンプレート
├── user_data.sh            # インスタンス初期化スクリプト
├── asg.tf                  # Auto Scaling Group とスケーリングポリシー
├── db_instance.tf          # EC2 インスタンス上の MySQL
└── db_user_data.sh         # データベース初期化スクリプト
```

## 開発ガイドライン

### リソース命名規則
すべてのリソースは一貫した命名パターンに従います:
- **形式**: `${var.project_name}-${var.environment}-{resource-type}-{identifier}`
- **例**: `myapp-prod-vpc`, `myapp-prod-web-asg`, `myapp-prod-mysql`
- この命名規則は変数を通じて適用され、一貫性を確保します

### タグ付け戦略
すべてのリソースには自動的に以下のタグが付与されます (provider.tf で設定):
- `Project`: `var.project_name` の値
- `Environment`: `var.environment` の値
- `ManagedBy`: "Terraform"
- 個々のリソースには追加の `Name` タグがある場合があります

### ステート管理
- **バックエンド**: S3 + DynamoDB (backend.tf で設定、初期状態ではコメントアウト)
- **ローカルステート**: `terraform.tfstate` や `terraform.tfvars` をバージョン管理にコミットしないでください
- **ステートロック**: 同時変更を防ぐために DynamoDB 経由で有効化
- リモートステートを有効にする前に、セットアップ手順について backend.tf を参照してください

### セキュリティのベストプラクティス
- データベースのパスワードは `terraform.tfvars` 経由で設定する必要があります（機密情報としてマーク）
- 本番環境では AWS Secrets Manager または SSM Parameter Store の使用を検討してください
- EC2 インスタンスには IAM ロールを使用します（ハードコードされた認証情報は使用しません）
- すべての RDS ストレージは保存時に暗号化されます
- プライベートサブネットには直接のインターネットアクセスはありません（アウトバウンドのみ NAT ゲートウェイ経由）

### 重要な実装上の注意

#### CIDR 割り当て
- VPC: 10.0.0.0/16
- パブリックサブネット: 10.0.0.0/24 (AZ-A), 10.0.2.0/24 (AZ-B)
- プライベートサブネット: 10.0.1.0/24 (AZ-A), 10.0.3.0/24 (AZ-B)

#### コスト最適化
- **シングル NAT ゲートウェイ**: コスト削減のため AZ-A にのみデプロイ（〜$32/月の節約）
- より高い可用性を必要とする本番環境では、nat.tf を変更して両方の AZ に NAT ゲートウェイをデプロイしてください
- Auto Scaling ポリシーは容量を需要に合わせるのに役立ちます

#### ユーザーデータスクリプト
- `user_data.sh` に配置され、launch_template.tf から参照されます
- templatefile() を使用して変数（DB エンドポイント、認証情報）を注入します
- Apache HTTP サーバーをインストールし、基本的なヘルスチェックページを作成します
- 本番環境では、アプリケーションのニーズに合わせてこのスクリプトをカスタマイズしてください

## ドキュメントのメンテナンス

**重要**: インフラストラクチャに変更を加える場合は、関連するドキュメントを同期させてください:

### Terraform コードを変更する場合:

1. **architecture.md を更新**: 変更が以下に影響する場合:
   - ネットワークトポロジまたは IP アドレス指定
   - コンポーネントの関係またはデータフロー
   - セキュリティグループルールまたはアクセスパターン
   - 高可用性または災害復旧設計
   - 新しいコンポーネントまたはサービスの追加

2. **このファイル (CLAUDE.md) を更新**: 変更が以下に影響する場合:
   - 一般的なコマンドまたはワークフロー
   - ファイル構造または構成
   - 開発規則またはパターン
   - 重要な実装上の注意

3. **README.md を更新**: 変更が以下に影響する場合:
   - デプロイ手順または前提条件
   - 変数設定要件
   - コスト見積もりまたはリソースサイジング
   - ユーザー向け機能

### ドキュメントの更新が必要なシナリオ例:

- **新しいコンポーネントの追加** (例: ElastiCache, CloudFront):
  - architecture.md を更新して、コンポーネントの詳細と統合ポイントを追加
  - 必要に応じて CLAUDE.md に関連する Terraform コマンドを追加
  - 新しい出力と使用方法で README.md を更新

- **ネットワークレイアウトの変更** (例: サブネットの追加、CIDR の変更):
  - architecture.md の CIDR テーブルを更新
  - CLAUDE.md の CIDR 参照を更新
  - 可能であればネットワーク図を更新

- **セキュリティグループの変更**:
  - architecture.md のセキュリティグループルールセクションを更新
  - アクセスパターンが変更される場合はセキュリティ上の考慮事項を更新

- **新しい変数の追加**:
  - 変数の説明を README.md に追加
  - terraform.tfvars に新しい変数とコメントを追加

**変更をコミットする前に、3つのドキュメントファイルすべて (CLAUDE.md, architecture.md, README.md) が実装と整合していることを確認してください。**