#!/bin/bash
set -e

# システムパッケージの更新
dnf update -y

# Apache HTTP Server と PHP のインストール
dnf install -y httpd php

# データベース接続テスト用の MySQL クライアントのインストール
dnf install -y mariadb105

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
    <title>AWS マルチティアアプリケーション</title>
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
        .footer {
            margin-top: 30px;
            text-align: center;
            color: #666;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>AWS マルチティアアプリケーションへようこそ</h1>
        <div class="info">
            <p><strong>ステータス:</strong> 稼働中</p>
            <p><strong>インスタンス ID:</strong> $INSTANCE_ID</p>
            <p><strong>アベイラビリティゾーン:</strong> $AVAILABILITY_ZONE</p>
        </div>
        <p>このアプリケーションは、高可用性マルチ AZ AWS インフラストラクチャ上にデプロイされています。</p>
        <ul>
            <li>トラフィック分散のための Application Load Balancer</li>
            <li>動的な容量管理のための Auto Scaling</li>
            <li>データベースの冗長性のための Multi-AZ RDS MySQL</li>
            <li>パブリックサブネットとプライベートサブネットを持つ VPC</li>
        </ul>

        <h2>利用可能なエンドポイント</h2>
        <ul>
            <li><strong>/</strong> - このページ (軽量)</li>
            <li><strong>/health.html</strong> - ヘルスチェックエンドポイント</li>
            <li><strong>/work.php</strong> - CPU 負荷の高いワークロードエンドポイント (負荷テスト用)</li>
        </ul>
    </div>
    <div class="footer">
        <p>Terraform でデプロイ済み</p>
    </div>
</body>
</html>
EOF

# ヘルスチェックエンドポイントの作成
cat > /var/www/html/health.html <<'EOF'
OK
EOF

# 負荷テスト用の CPU 負荷の高いワークロードエンドポイントを作成
cat > /var/www/html/work.php <<'EOF'
<?php
// 実際のアプリケーション処理をシミュレートする CPU 負荷の高いワークロード
// これにより、リクエストごとに CPU 使用率が増加します

header('Content-Type: text/html; charset=utf-8');

// 設定
\$iterations = 5000000;  // CPU 作業の反復回数

// 1. 素数計算 (CPU 負荷が高い)
function isPrime(\$n) {
    if (\$n <= 1) return false;
    if (\$n <= 3) return true;
    if (\$n % 2 == 0 || \$n % 3 == 0) return false;
    for (\$i = 5; \$i * \$i <= \$n; \$i += 6) {
        if (\$n % \$i == 0 || \$n % (\$i + 2) == 0) return false;
    }
    return true;
}

// 2. 素数の算出
\$primes = [];
for (\$i = 2; \$i < 1000; \$i++) {
    if (isPrime(\$i)) {
        \$primes[] = \$i;
    }
}

// 3. 文字列ハッシュ操作
\$hash_count = 0;
for (\$i = 0; \$i < \$iterations; \$i++) {
    md5("load-test-" . \$i);
    \$hash_count++;
}

// 4. 配列のソート操作
\$random_array = [];
for (\$i = 0; \$i < 1000; \$i++) {
    \$random_array[] = rand(1, 10000);
}
sort(\$random_array);

// 5. 数学計算
\$sum = 0;
for (\$i = 1; \$i <= \$iterations; \$i++) {
    \$sum += sqrt(\$i) * log(\$i + 1);
}

// インスタンスメタデータの取得
\$instance_id = file_get_contents('http://169.254.169.254/latest/meta-data/instance-id');
\$az = file_get_contents('http://169.254.169.254/latest/meta-data/placement/availability-zone');

// レスポンスを返す
echo "<!DOCTYPE html>
<html lang='ja'>
<head>
    <meta charset='UTF-8'>
    <title>ワークロード処理完了</title>
    <style>
        body { font-family: \"Hiragino Kaku Gothic ProN\", \"Hiragino Sans\", Meiryo, sans-serif; padding: 20px; background: #f4f4f4; }
        .result { background: white; padding: 20px; border-radius: 5px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        .success { color: #28a745; }
    </style>
</head>
<body>
    <div class='result'>
        <h2 class='success'>✓ ワークロード処理完了</h2>
        <p><strong>インスタンス ID:</strong> " . htmlspecialchars(\$instance_id) . "</p>
        <p><strong>アベイラビリティゾーン:</strong> " . htmlspecialchars(\$az) . "</p>
        <p><strong>発見された素数:</strong> " . count(\$primes) . "</p>
        <p><strong>生成されたハッシュ:</strong> " . \$hash_count . "</p>
        <p><strong>計算結果:</strong> " . number_format(\$sum, 2) . "</p>
        <p><strong>時刻:</strong> " . date('Y-m-d H:i:s') . "</p>
    </div>
</body>
</html>";
?>
EOF

# 適切な権限の設定
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# データベース接続情報を環境変数に保存
cat >> /etc/environment <<EOF
DB_ENDPOINT=${db_endpoint}
DB_PRIMARY=${db_primary}
DB_SECONDARY=${db_secondary}
DB_NAME=${db_name}
DB_USERNAME=${db_username}
EOF

# DB 情報で index.html を更新
sed -i '/<p><strong>アベイラビリティゾーン:<\/strong>/a \            <p><strong>DB プライマリ:</strong> ${db_primary}</p>\n            <p><strong>DB セカンダリ:</strong> ${db_secondary}</p>' /var/www/html/index.html

# CloudWatch エージェントのインストール (オプション)
# dnf install -y amazon-cloudwatch-agent

echo "User data script completed successfully" | systemd-cat -t user-data
