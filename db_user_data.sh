#!/bin/bash
set -e

# EC2 ベースの MySQL データベースセットアップ
# このスクリプトは Amazon Linux 2023 に MySQL をインストールして構成します

echo "EC2 への MySQL のインストールを開始します..." | systemd-cat -t db-setup

# システムの更新
dnf update -y

# MySQL サーバーのインストール
dnf install -y mysql-server

# MySQL の起動と有効化
systemctl start mysqld
systemctl enable mysqld

# MySQL の準備ができるまで待機
sleep 10

# MySQL のセキュリティ設定とデータベースの作成
mysql -u root <<-EOSQL
    -- 匿名ユーザーの削除
    DELETE FROM mysql.user WHERE User='';

    -- リモート root ログインの削除
    DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

    -- テストデータベースの削除
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

    -- アプリケーションデータベースの作成
    CREATE DATABASE IF NOT EXISTS ${db_name};

    -- リモートアクセス可能なアプリケーションユーザーの作成
    CREATE USER IF NOT EXISTS '${db_username}'@'%' IDENTIFIED BY '${db_password}';
    GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_username}'@'%';

    -- モニタリング用の読み取り専用ユーザーの作成
    CREATE USER IF NOT EXISTS 'readonly'@'%' IDENTIFIED BY 'readonly123';
    GRANT SELECT ON ${db_name}.* TO 'readonly'@'%';

    -- 権限のフラッシュ
    FLUSH PRIVILEGES;
EOSQL

# MySQL がすべてのインターフェースでリッスンするように構成 (localhost だけでなく)
cat > /etc/my.cnf.d/custom.cnf <<EOF
[mysqld]
# ネットワーク設定
bind-address = 0.0.0.0
port = 3306

# パフォーマンス設定
max_connections = 200
innodb_buffer_pool_size = 256M

# 文字セット
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# バックアップ用のバイナリログ
log_bin = /var/lib/mysql/mysql-bin
expire_logs_days = 7

# エラーログ
log_error = /var/log/mysql/error.log

# スロークエリログ
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow-query.log
long_query_time = 2
EOF

# ログディレクトリの作成
mkdir -p /var/log/mysql
chown -R mysql:mysql /var/log/mysql

# 構成を適用するために MySQL を再起動
systemctl restart mysqld

# バックアップスクリプトの作成
cat > /usr/local/bin/mysql-backup.sh <<'BACKUP_SCRIPT'
#!/bin/bash
BACKUP_DIR="/var/lib/mysql/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# すべてのデータベースをバックアップ
mysqldump --all-databases --single-transaction --routines --triggers \
  > $BACKUP_DIR/all-databases-$DATE.sql

# 過去 7 日間のバックアップのみ保持
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete

echo "バックアップ完了: all-databases-$DATE.sql"
BACKUP_SCRIPT

chmod +x /usr/local/bin/mysql-backup.sh

# 毎日午前 2 時にバックアップをスケジュール
echo "0 2 * * * root /usr/local/bin/mysql-backup.sh" > /etc/cron.d/mysql-backup

# データベース情報ファイルの作成
cat > /root/database-info.txt <<EOF
==============================================
MySQL データベース情報
==============================================
データベース名: ${db_name}
ユーザー名: ${db_username}
パスワード: ${db_password}
ポート: 3306
プライベート IP: $(hostname -I | awk '{print $1}')

接続文字列の例:
- MySQL CLI: mysql -h $(hostname -I | awk '{print $1}') -u ${db_username} -p${db_password} ${db_name}
- JDBC: jdbc:mysql://$(hostname -I | awk '{print $1}'):3306/${db_name}
- Python: mysql://$(hostname -I | awk '{print $1}'):3306/${db_name}

バックアップ場所: /var/lib/mysql/backups/
バックアップスケジュール: 毎日午前 2 時
==============================================
EOF

# データベース接続テスト
mysql -u ${db_username} -p${db_password} -e "SELECT 'Database setup successful!' as Status; SHOW DATABASES;" ${db_name}

# ステータスチェックスクリプトの作成
cat > /usr/local/bin/db-status.sh <<'STATUS_SCRIPT'
#!/bin/bash
echo "===== MySQL ステータス ====="
systemctl status mysqld --no-pager
echo ""
echo "===== アクティブな接続 ====="
mysql -u root -e "SHOW PROCESSLIST;"
echo ""
echo "===== データベースサイズ ====="
mysql -u root -e "SELECT table_schema AS 'Database',
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
    FROM information_schema.tables
    GROUP BY table_schema;"
STATUS_SCRIPT

chmod +x /usr/local/bin/db-status.sh

echo "MySQL データベースのセットアップが正常に完了しました！" | systemd-cat -t db-setup
echo "データベース情報は /root/database-info.txt に保存されました" | systemd-cat -t db-setup
