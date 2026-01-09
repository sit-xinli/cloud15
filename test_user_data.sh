#!/bin/bash
set -e

# システムパッケージの更新
dnf update -y

# Apache HTTP Server と PHP のインストール
dnf install -y httpd php

# データベース接続テスト用の MySQL クライアントのインストール
dnf install -y mariadb105

# 負荷テストツールのインストール
dnf install -y httpd-tools  # Apache Bench (ab)

# Apache の起動と有効化
systemctl start httpd
systemctl enable httpd

# IMDSv2 を使用してインスタンスメタデータを取得
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null)
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null)
AVAILABILITY_ZONE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null)

# ヘルスチェックエンドポイントを含むシンプルな HTML ページを作成
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <title>テストインスタンス - 負荷テストコントローラー</title>
    <style>
        body {
            font-family: "Hiragino Kaku Gothic ProN", "Hiragino Sans", Meiryo, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f4f4f4;
        }
        .container {
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #232f3e;
        }
        .info {
            background-color: #f0f8ff;
            padding: 15px;
            border-left: 4px solid #0073bb;
            margin: 20px 0;
        }
        .warning {
            background-color: #fff3cd;
            padding: 15px;
            border-left: 4px solid #ffc107;
            margin: 20px 0;
        }
        .success {
            background-color: #d4edda;
            padding: 15px;
            border-left: 4px solid #28a745;
            margin: 20px 0;
        }
        .footer {
            margin-top: 30px;
            text-align: center;
            color: #666;
        }
        code {
            background-color: #f4f4f4;
            padding: 2px 6px;
            border-radius: 3px;
            font-family: monospace;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🧪 テストインスタンス - 負荷テストコントローラー</h1>
        <div class="info">
            <p><strong>インスタンス ID:</strong> $INSTANCE_ID</p>
            <p><strong>アベイラビリティゾーン:</strong> $AVAILABILITY_ZONE</p>
            <p><strong>目的:</strong> テストと負荷生成</p>
        </div>

        <h2>負荷テストステータス</h2>
        <div class="success">
            <p><strong>負荷テストサービス:</strong> 有効 (継続実行中)</p>
            <p><strong>ターゲット:</strong> http://${alb_dns}/work.php (CPU 負荷の高いワークロード)</p>
            <p><strong>同時接続数:</strong> ${load_test_concurrency} 接続</p>
            <p><strong>サイクル期間:</strong> ${load_test_duration} 秒 (0 = 連続)</p>
            <p><strong>ワークロード:</strong> 素数計算、MD5 ハッシュ、ソート、数学演算</p>
        </div>

        <h2>手動制御</h2>
        <p>このインスタンスに SSH 接続して負荷テストを制御します:</p>
        <pre><code>
# サービスのステータス確認
sudo systemctl status load-test

# 負荷テストの開始
sudo systemctl start load-test

# 負荷テストの停止
sudo systemctl stop load-test

# 負荷テストログの表示
sudo journalctl -u load-test -f
        </code></pre>

        <h2>ASG スケーリングの監視</h2>
        <p>負荷に対する Auto Scaling Group の反応を監視します:</p>
        <pre><code>
# ASG インスタンス数の確認
aws autoscaling describe-auto-scaling-groups \\
  --auto-scaling-group-names myapp-prod-web-asg \\
  --query 'AutoScalingGroups[0].DesiredCapacity'
        </code></pre>

        <h2>テストエンドポイント</h2>
        <ul>
            <li><a href="/">このダッシュボード</a> (軽量)</li>
            <li><a href="http://${alb_dns}">ALB ホーム</a> (ロードバランス済み)</li>
            <li><a href="http://${alb_dns}/work.php">ALB ワークロード</a> (CPU 負荷が高い - 負荷テストの対象)</li>
        </ul>
    </div>
    <div class="footer">
        <p>テストインスタンス | Terraform でデプロイ済み</p>
    </div>
</body>
</html>
EOF

# ヘルスチェックエンドポイントの作成
cat > /var/www/html/health.html <<'EOF'
OK
EOF

# 適切な権限の設定
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# 設定の保存
cat >> /etc/environment <<EOF
DB_ENDPOINT=${db_endpoint}
DB_PRIMARY=${db_primary}
DB_SECONDARY=${db_secondary}
DB_NAME=${db_name}
DB_USERNAME=${db_username}
ALB_DNS=${alb_dns}
LOAD_TEST_CONCURRENCY=${load_test_concurrency}
LOAD_TEST_DURATION=${load_test_duration}
EOF

# 負荷テストスクリプトの作成
cat > /usr/local/bin/run-load-test.sh <<'SCRIPT'
#!/bin/bash
set -e

# 環境変数の読み込み
source /etc/environment

ALB_URL="http://$ALB_DNS/work.php"  # ターゲットの CPU 負荷の高いエンドポイント
CONCURRENCY=$LOAD_TEST_CONCURRENCY
DURATION=$LOAD_TEST_DURATION

echo "[$(date)] $ALB_URL に対する負荷テストを開始 (CPU 負荷の高いワークロード)"
echo "[$(date)] 同時接続数: $CONCURRENCY"
echo "[$(date)] 期間: サイクルあたり $DURATION 秒"

# 継続的な負荷テストの実行
while true; do
    echo "[$(date)] 負荷テストサイクルを実行中..."

    # Apache Bench を使用して CPU 負荷の高いエンドポイントに対して負荷を生成
    # -n: リクエスト数 (同時接続数 * 期間で負荷を維持)
    # -c: 同時接続レベル
    # -t: 時間制限 (期間 > 0 の場合)

    if [ "$DURATION" -eq 0 ]; then
        # 連続モード - 無期限に実行
        ab -n 999999999 -c $CONCURRENCY $ALB_URL || true
    else
        # 時間指定モード - 指定された期間実行
        ab -t $DURATION -c $CONCURRENCY $ALB_URL || true
        echo "[$(date)] サイクル完了。次のサイクルまで 30 秒待機します..."
        sleep 30
    fi
done
SCRIPT

chmod +x /usr/local/bin/run-load-test.sh

# 負荷テスト用の systemd サービスを作成
cat > /etc/systemd/system/load-test.service <<'SERVICE'
[Unit]
Description=Continuous Load Testing Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/run-load-test.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=load-test

[Install]
WantedBy=multi-user.target
SERVICE

# systemd のリロード
systemctl daemon-reload

# 負荷テストサービスの有効化と開始
systemctl enable load-test
systemctl start load-test

echo "Load testing service enabled and started" | systemd-cat -t user-data
echo "Load testing instance user data script completed successfully" | systemd-cat -t user-data
