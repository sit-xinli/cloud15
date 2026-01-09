#!/bin/bash
set -e

# Update system packages
dnf update -y

# Install Apache HTTP Server
dnf install -y httpd

# Install MySQL client for database connectivity testing
dnf install -y mariadb105

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Create a simple HTML page with health check endpoint
cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>AWS Multi-Tier Application</title>
    <style>
        body {
            font-family: Arial, sans-serif;
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
        <h1>Welcome to AWS Multi-Tier Application</h1>
        <div class="info">
            <p><strong>Status:</strong> Running</p>
            <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
            <p><strong>Availability Zone:</strong> <span id="az">Loading...</span></p>
        </div>
        <p>This application is deployed on a highly available, multi-AZ AWS infrastructure.</p>
        <ul>
            <li>Application Load Balancer for traffic distribution</li>
            <li>Auto Scaling for dynamic capacity management</li>
            <li>Multi-AZ RDS MySQL for database redundancy</li>
            <li>VPC with public and private subnets</li>
        </ul>
    </div>
    <div class="footer">
        <p>Deployed with Terraform</p>
    </div>

    <script>
        // Fetch instance metadata
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => document.getElementById('instance-id').textContent = data)
            .catch(() => document.getElementById('instance-id').textContent = 'N/A');

        fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone')
            .then(response => response.text())
            .then(data => document.getElementById('az').textContent = data)
            .catch(() => document.getElementById('az').textContent = 'N/A');
    </script>
</body>
</html>
EOF

# Create health check endpoint
cat > /var/www/html/health.html <<'EOF'
OK
EOF

# Set proper permissions
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Install MySQL on web server (AWS Academy workaround)
if [ "${install_mysql}" = "true" ]; then
    echo "Installing MySQL on web server..." | systemd-cat -t mysql-install

    # Install MySQL server
    dnf install -y mysql-server

    # Start and enable MySQL
    systemctl start mysqld
    systemctl enable mysqld

    # Wait for MySQL to start
    sleep 5

    # Create database and user
    mysql -u root <<-EOSQL
        CREATE DATABASE IF NOT EXISTS ${db_name};
        CREATE USER IF NOT EXISTS '${db_username}'@'localhost' IDENTIFIED BY '${db_password}';
        GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_username}'@'localhost';
        FLUSH PRIVILEGES;
EOSQL

    # Store local database connection info
    cat >> /etc/environment <<EOF
DB_ENDPOINT=localhost:3306
DB_NAME=${db_name}
DB_USERNAME=${db_username}
DB_HOST=localhost
EOF

    echo "MySQL installed successfully on web server" | systemd-cat -t mysql-install
else
    # Store database connection information in environment variables
    cat >> /etc/environment <<EOF
DB_ENDPOINT=${db_endpoint}
DB_NAME=${db_name}
DB_USERNAME=${db_username}
EOF
fi

# Install CloudWatch agent (optional)
# dnf install -y amazon-cloudwatch-agent

echo "User data script completed successfully" | systemd-cat -t user-data
