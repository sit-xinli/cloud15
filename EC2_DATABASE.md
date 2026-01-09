# EC2-Based Database Solution for AWS Academy

This guide explains how to use MySQL on EC2 instead of RDS, avoiding AWS Academy restrictions.

## Why Use Database on EC2?

### Advantages
- ✅ **No AWS Academy restrictions** - No DB subnet group issues
- ✅ **Lower cost** - ~$15/month vs ~$75 for RDS
- ✅ **Full control** - Direct access to MySQL server
- ✅ **Good for learning** - Hands-on database administration
- ✅ **Flexible** - Install any database software

### Disadvantages
- ❌ **Manual management** - You handle backups, updates
- ❌ **No automatic failover** - Single point of failure
- ❌ **More operational work** - Monitoring, security patches
- ❌ **Single-AZ only** - No built-in high availability

## Architecture

```
Internet Gateway
       ↓
Application Load Balancer (Public Subnet)
       ↓
Web Instances (Private Subnet)
       ↓
MySQL on EC2 (Private Subnet)
```

## Deployment

### Step 1: Configure Variables

Edit `terraform.tfvars`:
```hcl
# Use EC2 database instead of RDS
create_rds        = false
create_ec2_db     = true

# EC2 Database Configuration
db_ec2_instance_type = "t3.small"   # Or t3.micro for lower cost
db_ec2_volume_size   = 30           # GB for database storage

# Database credentials
db_name      = "webapp"
db_username  = "admin"
db_password  = "YourStrongPassword123!"  # Change this!
```

### Step 2: Deploy Infrastructure

```bash
terraform apply
```

This creates:
- VPC, subnets, networking
- Application Load Balancer
- Auto Scaling Group (web instances)
- **MySQL EC2 instance** (in private subnet)

### Step 3: Verify Database

Get the database endpoint:
```bash
terraform output ec2_db_endpoint
# Output: 10.0.1.123:3306
```

## What Gets Installed on DB Instance

The `db_user_data.sh` script automatically:

1. **Installs MySQL Server** (8.0)
2. **Configures security**:
   - Removes anonymous users
   - Removes test database
   - Sets up remote access
3. **Creates your database** and user
4. **Configures networking** (listens on all interfaces)
5. **Sets up automated backups** (daily at 2 AM)
6. **Optimizes performance** settings
7. **Enables binary logging** for point-in-time recovery

## Accessing the Database

### From Web Instances (Automatic)

Web instances automatically receive the DB endpoint via user_data:
```bash
DB_ENDPOINT=10.0.1.123:3306
DB_NAME=webapp
DB_USERNAME=admin
```

### From Your Computer (via Session Manager)

```bash
# 1. Get DB instance ID
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=myapp-prod-mysql-ec2" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text

# 2. Connect via SSM
aws ssm start-session --target <instance-id>

# 3. Check database status
sudo /usr/local/bin/db-status.sh

# 4. Connect to MySQL
mysql -u admin -p webapp
```

### Connection Strings

**MySQL CLI**:
```bash
mysql -h 10.0.1.123 -u admin -p webapp
```

**Python**:
```python
import mysql.connector
conn = mysql.connector.connect(
    host='10.0.1.123',
    user='admin',
    password='YourPassword',
    database='webapp'
)
```

**Node.js**:
```javascript
const mysql = require('mysql2');
const connection = mysql.createConnection({
  host: '10.0.1.123',
  user: 'admin',
  password: 'YourPassword',
  database: 'webapp'
});
```

**PHP**:
```php
$conn = new mysqli('10.0.1.123', 'admin', 'YourPassword', 'webapp');
```

**Java (JDBC)**:
```java
String url = "jdbc:mysql://10.0.1.123:3306/webapp";
Connection conn = DriverManager.getConnection(url, "admin", "YourPassword");
```

## Database Management

### Manual Backup

```bash
# Connect to DB instance via SSM
aws ssm start-session --target <db-instance-id>

# Run backup manually
sudo /usr/local/bin/mysql-backup.sh

# Backups are stored in:
ls -lh /var/lib/mysql/backups/
```

### Restore from Backup

```bash
# List available backups
ls -lh /var/lib/mysql/backups/

# Restore specific backup
mysql -u root webapp < /var/lib/mysql/backups/all-databases-20260109_020000.sql
```

### View Database Status

```bash
# System status
systemctl status mysqld

# Comprehensive status
sudo /usr/local/bin/db-status.sh

# Active connections
mysql -u root -e "SHOW PROCESSLIST;"

# Database sizes
mysql -u root -e "
  SELECT table_schema AS 'Database',
         ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
  FROM information_schema.tables
  GROUP BY table_schema;
"
```

### Performance Tuning

The database is pre-configured with:
- 256MB InnoDB buffer pool (adjust based on instance size)
- 200 max connections
- UTF-8MB4 character set
- Binary logging enabled
- Slow query logging (queries > 2 seconds)

To adjust:
```bash
sudo nano /etc/my.cnf.d/custom.cnf
sudo systemctl restart mysqld
```

## Security Considerations

### Network Security
✅ **Database in private subnet** - No direct internet access
✅ **Security group** - Only accepts connections from web instances
✅ **No public IP** - Only accessible within VPC

### Database Security
✅ **Strong passwords** - Required for production
✅ **No anonymous users** - Disabled by default
✅ **No remote root** - Root only from localhost
✅ **Encrypted EBS volume** - Data at rest encryption

### Additional Hardening (Optional)

```bash
# Enable SSL/TLS connections
sudo mysql_ssl_rsa_setup
sudo systemctl restart mysqld

# Create SSL-only user
mysql -u root -e "
  CREATE USER 'secure_user'@'%' IDENTIFIED BY 'password' REQUIRE SSL;
  GRANT ALL PRIVILEGES ON webapp.* TO 'secure_user'@'%';
"
```

## Monitoring

### CloudWatch Metrics (Automatic)
- CPU utilization
- Disk I/O
- Network traffic
- Disk space

### Custom Monitoring (Optional)

Install MySQL Exporter for Prometheus:
```bash
# Download and install
wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.15.0/mysqld_exporter-0.15.0.linux-amd64.tar.gz
tar -xzf mysqld_exporter-*.tar.gz
sudo mv mysqld_exporter*/mysqld_exporter /usr/local/bin/

# Create monitoring user
mysql -u root -e "
  CREATE USER 'exporter'@'localhost' IDENTIFIED BY 'exporterpass';
  GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';
"

# Run exporter
mysqld_exporter &
```

## High Availability Options

The current setup is single-instance. For better availability:

### Option 1: Manual Snapshots
```bash
# Create AMI from DB instance
aws ec2 create-image \
  --instance-id <db-instance-id> \
  --name "mysql-backup-$(date +%Y%m%d)" \
  --description "MySQL database backup"
```

### Option 2: MySQL Replication (Advanced)
- Set up primary-replica replication
- Deploy replica in second AZ
- Requires manual configuration

### Option 3: Scheduled Backups
Already configured:
- Daily automatic backups at 2 AM
- 7-day retention
- Binary logs for point-in-time recovery

## Troubleshooting

### Database Won't Start

```bash
# Check logs
sudo tail -f /var/log/mysql/error.log

# Check disk space
df -h /var/lib/mysql

# Verify MySQL process
ps aux | grep mysql
```

### Can't Connect from Web Instance

```bash
# Check security group allows port 3306
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw rds_security_group_id)

# Verify database is listening
mysql -u root -e "SHOW VARIABLES LIKE 'bind_address';"
# Should show: 0.0.0.0

# Test connection from web instance
mysql -h <db-private-ip> -u admin -p -e "SELECT 1;"
```

### Slow Performance

```bash
# Check slow query log
sudo tail -f /var/log/mysql/slow-query.log

# View current queries
mysql -u root -e "SHOW FULL PROCESSLIST;"

# Check buffer pool usage
mysql -u root -e "
  SHOW STATUS LIKE 'Innodb_buffer_pool_pages%';
"
```

### Out of Disk Space

```bash
# Check disk usage
df -h /var/lib/mysql

# Clean old backups
sudo find /var/lib/mysql/backups -name "*.sql" -mtime +7 -delete

# Clean binary logs
mysql -u root -e "PURGE BINARY LOGS BEFORE DATE_SUB(NOW(), INTERVAL 3 DAY);"
```

## Migrating to RDS Later

If you later gain RDS permissions:

1. **Export data**:
```bash
mysqldump --all-databases --single-transaction > full_backup.sql
```

2. **Create RDS instance** via Terraform

3. **Import data**:
```bash
mysql -h <rds-endpoint> -u admin -p < full_backup.sql
```

4. **Update Terraform**:
```hcl
create_ec2_db = false
create_rds    = true
```

5. **Apply changes** and terminate EC2 DB

## Cost Comparison

| Solution | Monthly Cost (AWS Academy Credits) |
|----------|-----------------------------------|
| EC2 t3.micro DB | ~$10 |
| EC2 t3.small DB | ~$15 |
| EC2 t3.medium DB | ~$30 |
| RDS Single-AZ db.t3.small | ~$75 |
| RDS Multi-AZ db.t3.small | ~$150 |

## Best Practices

1. **Regular Backups** - Automatic daily backups are configured
2. **Monitor Disk Space** - Set up CloudWatch alarms
3. **Update MySQL** - Run `sudo dnf update mysql-server` regularly
4. **Use Strong Passwords** - Never use default passwords
5. **Limit Connections** - Only from application tier
6. **Test Recovery** - Periodically test backup restoration
7. **Monitor Performance** - Use slow query log and CloudWatch

## Summary

**Recommended for AWS Academy**: Use EC2-based MySQL
- ✅ No restrictions
- ✅ Lower cost
- ✅ Full control
- ✅ Good learning experience

**Set in terraform.tfvars**:
```hcl
create_rds    = false
create_ec2_db = true
```

Your database will be automatically deployed and configured!
