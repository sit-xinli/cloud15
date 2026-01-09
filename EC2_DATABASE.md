# EC2 ベースの MySQL データベース

## 概要

このプロジェクトでは、RDS の代わりに専用 EC2 インスタンス上で実行される MySQL を使用します。このアプローチは、完全なデータベース層を提供しながら、AWS Academy の制約内で機能します。

**アーキテクチャ:**
```
インターネット → ALB (パブリックサブネット)
           ↓
       Web インスタンス (プライベートサブネット)
           ↓
       MySQL on EC2 (プライベートサブネット)
```

## 構成

`terraform.tfvars` 内:
```hcl
# データベースは常に作成されます - フラグは不要です
db_ec2_instance_type = "t3.small"
db_ec2_volume_size   = 30  # GB
db_name              = "webapp"
db_username          = "admin"
db_password          = "YourStrongPassword123!"  # 変更してください！
```

## 作成されるもの

- プライベートサブネット内の **2つの EC2 インスタンス** (プライマリ + セカンダリ)
- 自動的にインストールおよび構成される **MySQL 8.0 サーバー**
- データストレージ用の **暗号化された EBS ボリューム**
- 7日間の保持期間を持つ、午前 2 時の **自動日次バックアップ**
- Web インスタンスからの MySQL アクセスのみを許可する **セキュリティグループ**

## データベースへのアクセス

### Web インスタンスから (自動)

Web インスタンスは user_data 経由で DB エンドポイントを受け取り、自動的に接続できます。

### コンピューターから (Session Manager 経由)

```bash
# DB インスタンス ID の取得
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=*mysql-ec2-primary" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text

# SSM 経由で接続
aws ssm start-session --target <instance-id>

# データベースステータスの確認
sudo /usr/local/bin/db-status.sh

# MySQL に接続
mysql -u admin -p webapp
```

## データベース管理

### 手動バックアップ
```bash
# DB インスタンスへの SSH 接続
aws ssm start-session --target <db-instance-id>

# バックアップの実行
sudo /usr/local/bin/mysql-backup.sh

# バックアップの表示
ls -lh /var/lib/mysql/backups/
```

### ステータス確認
```bash
systemctl status mysqld
sudo /usr/local/bin/db-status.sh
```

## 利点と欠点

### ✅ 利点
- AWS Academy で動作 (IAM 制限なし)
- 低コスト (RDS の ~$75 に対して ~$15/月)
- MySQL 構成の完全な制御
- トラブルシューティングのための直接 SSH アクセス

### ❌ 欠点
- 手動管理 (バックアップ、更新)
- 自動マルチ AZ フェイルオーバーなし
- インスタンスごとの単一障害点

## セキュリティ

- **ネットワーク**: プライベートサブネット内のデータベース、直接のインターネットアクセスなし
- **アクセス**: Web インスタンスのみ接続可能 (セキュリティグループ経由)
- **暗号化**: 保存時に暗号化された EBS ボリューム
- **認証情報**: 強力なパスワードが必要

## モニタリング

CloudWatch 経由で利用可能:
- CPU 使用率
- ディスク I/O
- ネットワークトラフィック
- ディスク容量使用率

## トラブルシューティング

### MySQL が実行されていない
```bash
systemctl status mysqld
sudo tail -f /var/log/mysql/error.log
sudo systemctl restart mysqld
```

### Web インスタンスから接続できない
```bash
# MySQL がすべてのインターフェースでリッスンしていることを確認
mysql -u root -e "SHOW VARIABLES LIKE 'bind_address';"
# 表示されるはずです: 0.0.0.0

# 接続テスト
mysql -h <db-private-ip> -u admin -p -e "SELECT 1;"
```

## RDS への移行

後でマネージド RDS を使用する場合:

1. データのエクスポート: `mysqldump --all-databases > backup.sql`
2. Terraform または AWS コンソール経由で RDS インスタンスを作成
3. データのインポート: `mysql -h <rds-endpoint> -u admin -p < backup.sql`
4. Terraform を更新して EC2 データベースインスタンスを削除
5. launch_template.tf を構成して RDS エンドポイントを使用
6. `terraform apply` を実行

## コスト比較

| オプション | 月額コスト |
|--------|--------------|
| EC2 t3.small DB | ~$15 |
| RDS Single-AZ db.t3.small | ~$75 |
| RDS Multi-AZ db.t3.small | ~$150 |

## まとめ

**現在の構成** は、専用 EC2 インスタンス上で MySQL を使用しています。これは、以下を提供する AWS Academy にとって実用的なソリューションです:
- 完全なデータベース機能
- コスト削減
- IAM 制限なし
- 学習と開発に最適

本番環境では、自動フェイルオーバーとマネージドバックアップのために RDS マルチ AZ へのアップグレードを検討してください。
