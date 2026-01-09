#!/bin/bash
set -e

# EC2-based MySQL Database Setup
# This script installs and configures MySQL on Amazon Linux 2023

echo "Starting MySQL installation on EC2..." | systemd-cat -t db-setup

# Update system
dnf update -y

# Install MySQL Server
dnf install -y mysql-server

# Start and enable MySQL
systemctl start mysqld
systemctl enable mysqld

# Wait for MySQL to be ready
sleep 10

# Secure MySQL installation and create database
mysql -u root <<-EOSQL
    -- Remove anonymous users
    DELETE FROM mysql.user WHERE User='';

    -- Remove remote root login
    DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

    -- Remove test database
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

    -- Create application database
    CREATE DATABASE IF NOT EXISTS ${db_name};

    -- Create application user with remote access
    CREATE USER IF NOT EXISTS '${db_username}'@'%' IDENTIFIED BY '${db_password}';
    GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_username}'@'%';

    -- Create read-only user for monitoring
    CREATE USER IF NOT EXISTS 'readonly'@'%' IDENTIFIED BY 'readonly123';
    GRANT SELECT ON ${db_name}.* TO 'readonly'@'%';

    -- Flush privileges
    FLUSH PRIVILEGES;
EOSQL

# Configure MySQL to listen on all interfaces (not just localhost)
cat > /etc/my.cnf.d/custom.cnf <<EOF
[mysqld]
# Network settings
bind-address = 0.0.0.0
port = 3306

# Performance settings
max_connections = 200
innodb_buffer_pool_size = 256M

# Character set
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# Binary logging for backups
log_bin = /var/lib/mysql/mysql-bin
expire_logs_days = 7

# Error logging
log_error = /var/log/mysql/error.log

# Slow query log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow-query.log
long_query_time = 2
EOF

# Create log directory
mkdir -p /var/log/mysql
chown -R mysql:mysql /var/log/mysql

# Restart MySQL to apply configuration
systemctl restart mysqld

# Create backup script
cat > /usr/local/bin/mysql-backup.sh <<'BACKUP_SCRIPT'
#!/bin/bash
BACKUP_DIR="/var/lib/mysql/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Backup all databases
mysqldump --all-databases --single-transaction --routines --triggers \
  > $BACKUP_DIR/all-databases-$DATE.sql

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete

echo "Backup completed: all-databases-$DATE.sql"
BACKUP_SCRIPT

chmod +x /usr/local/bin/mysql-backup.sh

# Schedule daily backups at 2 AM
echo "0 2 * * * root /usr/local/bin/mysql-backup.sh" > /etc/cron.d/mysql-backup

# Create database info file
cat > /root/database-info.txt <<EOF
==============================================
MySQL Database Information
==============================================
Database Name: ${db_name}
Username: ${db_username}
Password: ${db_password}
Port: 3306
Private IP: $(hostname -I | awk '{print $1}')

Connection String Examples:
- MySQL CLI: mysql -h $(hostname -I | awk '{print $1}') -u ${db_username} -p${db_password} ${db_name}
- JDBC: jdbc:mysql://$(hostname -I | awk '{print $1}'):3306/${db_name}
- Python: mysql://$(hostname -I | awk '{print $1}'):3306/${db_name}

Backup Location: /var/lib/mysql/backups/
Backup Schedule: Daily at 2 AM
==============================================
EOF

# Test database connection
mysql -u ${db_username} -p${db_password} -e "SELECT 'Database setup successful!' as Status; SHOW DATABASES;" ${db_name}

# Create status check script
cat > /usr/local/bin/db-status.sh <<'STATUS_SCRIPT'
#!/bin/bash
echo "===== MySQL Status ====="
systemctl status mysqld --no-pager
echo ""
echo "===== Active Connections ====="
mysql -u root -e "SHOW PROCESSLIST;"
echo ""
echo "===== Database Size ====="
mysql -u root -e "SELECT table_schema AS 'Database',
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
    FROM information_schema.tables
    GROUP BY table_schema;"
STATUS_SCRIPT

chmod +x /usr/local/bin/db-status.sh

echo "MySQL database setup completed successfully!" | systemd-cat -t db-setup
echo "Database info saved to /root/database-info.txt" | systemd-cat -t db-setup
