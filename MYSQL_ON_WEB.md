# MySQL on Web Servers - AWS Academy Solution

## The Problem

AWS Academy has very strict restrictions:
- ❌ Cannot create RDS DB subnet groups
- ❌ Cannot create standalone EC2 instances
- ❌ Limited EC2 RunInstances permissions

## The Solution

**Install MySQL directly on the web server instances!**

While not ideal for production, this works perfectly for learning and development in AWS Academy:

✅ **No AWS restrictions** - Part of web server setup
✅ **Fully automated** - Installed via user_data.sh
✅ **Works immediately** - No manual steps
✅ **Zero extra cost** - Uses existing web instances
✅ **Good for learning** - Understand application+database integration

## Architecture

```
Internet → Load Balancer → Web Instance (Apache + MySQL)
```

Each web instance runs:
- Apache HTTP Server (port 80)
- MySQL Server (localhost only)
- Your application

## How It Works

### Automatic Installation

When `install_mysql_on_web = true` (default), each web instance:

1. Installs MySQL 8.0 server
2. Creates your database (`webapp`)
3. Creates your user (`admin`)
4. Configures local-only access
5. Sets environment variables

### Configuration

In `terraform.tfvars`:
```hcl
# Enable MySQL on web servers (recommended for AWS Academy)
install_mysql_on_web = true
create_ec2_db        = false
create_rds           = false

# Database credentials
db_name     = "webapp"
db_username = "admin"
db_password = "YourStrongPassword123!"
```

## Database Access

### From Your Application (Same Instance)

Connect to localhost:
```bash
DB_HOST=localhost
DB_PORT=3306
DB_NAME=webapp
DB_USERNAME=admin
```

### Connection Examples

**MySQL CLI** (on the instance):
```bash
mysql -u admin -p webapp
```

**Python**:
```python
import mysql.connector
db = mysql.connector.connect(
    host='localhost',
    user='admin',
    password='YourPassword',
    database='webapp'
)
```

**Node.js**:
```javascript
const mysql = require('mysql2');
const connection = mysql.createConnection({
  host: 'localhost',
  user: 'admin',
  password: 'YourPassword',
  database: 'webapp'
});
```

**PHP**:
```php
$conn = new mysqli('localhost', 'admin', 'YourPassword', 'webapp');
```

## Pros and Cons

### Advantages ✅
- Works in AWS Academy (no restrictions)
- Fully automated setup
- Zero extra cost
- Fast local database access
- Good for development/learning
- Simple architecture

### Disadvantages ❌
- **Data not shared** between instances (each has own DB)
- **No automatic backups** (manual only)
- **Limited scalability** (database scales with web tier)
- **Mixed concerns** (web + database on same instance)
- **Not production-ready** for multi-instance setups

## Use Cases

### ✅ **GOOD FOR:**
- Learning AWS and database concepts
- Development and testing
- Single-instance applications
- Prototypes and demos
- AWS Academy projects
- Session storage (with sticky sessions)

### ❌ **NOT GOOD FOR:**
- Production applications requiring HA
- Data that must be shared across instances
- High-traffic applications
- Applications requiring database isolation
- Anything requiring Multi-AZ failover

## Making It Work with Auto Scaling

Since each instance has its own database, you need to handle data consistency:

### Option 1: Sticky Sessions (Recommended)

Configure ALB with sticky sessions so users always hit the same instance:

Add to `alb.tf`:
```hcl
resource "aws_lb_target_group" "web" {
  # ... existing config ...

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400  # 24 hours
    enabled         = true
  }
}
```

### Option 2: Shared Database (Advanced)

Use Amazon EFS to share database files between instances (complex).

### Option 3: Single Instance

Set ASG to min=1, max=1, desired=1 for single instance.

## Backup Strategy

### Manual Backup

SSH into instance and backup:
```bash
# Create backup
mysqldump -u admin -p webapp > /tmp/backup_$(date +%Y%m%d).sql

# Copy to local machine
aws s3 cp /tmp/backup_*.sql s3://your-bucket/backups/
```

### Scheduled Backups

Add to `user_data.sh`:
```bash
# Create backup script
cat > /usr/local/bin/mysql-backup.sh <<'BACKUP'
#!/bin/bash
mysqldump -u admin -p${db_password} webapp > /tmp/backup_$(date +%Y%m%d).sql
BACKUP

chmod +x /usr/local/bin/mysql-backup.sh

# Schedule daily at 2 AM
echo "0 2 * * * root /usr/local/bin/mysql-backup.sh" > /etc/cron.d/mysql-backup
```

## Monitoring

Check MySQL status:
```bash
# Connect to instance via Session Manager
aws ssm start-session --target <instance-id>

# Check MySQL
systemctl status mysqld
mysql -u admin -p -e "SHOW DATABASES;"
mysql -u admin -p -e "SHOW PROCESSLIST;"
```

## Troubleshooting

### MySQL Not Running

```bash
# Check status
systemctl status mysqld

# Check logs
sudo tail -f /var/log/mysqld.log

# Restart
sudo systemctl restart mysqld
```

### Can't Connect to Database

```bash
# Verify user exists
mysql -u root -e "SELECT User, Host FROM mysql.user;"

# Test connection
mysql -u admin -p webapp -e "SELECT 1;"
```

### Application Can't Connect

Check environment variables:
```bash
cat /etc/environment | grep DB_
```

## Upgrading to Dedicated Database Later

When you move to a real AWS account or need a proper database:

1. **Export data from web instance**:
```bash
mysqldump -u admin -p webapp > export.sql
```

2. **Create RDS or dedicated EC2 database**

3. **Import data**:
```bash
mysql -h <new-db-endpoint> -u admin -p webapp < export.sql
```

4. **Update Terraform**:
```hcl
install_mysql_on_web = false
create_rds = true  # or create_ec2_db = true
```

5. **Redeploy web instances** to connect to new database

## Alternative: SQLite

For even simpler setup, use SQLite (file-based database):

```bash
# Install SQLite
dnf install -y sqlite

# No server needed, just use files
sqlite3 /var/www/data/app.db
```

Pros:
- Even simpler than MySQL
- No server process
- File-based

Cons:
- Limited concurrent access
- No network access
- Not suitable for web applications

## Recommendations

### For AWS Academy:
✅ **Use this solution** - MySQL on web servers with sticky sessions

### For Production:
❌ **Don't use this** - Use RDS Multi-AZ or dedicated database tier

### For Learning:
✅ **Perfect** - Understand database integration and management

## Summary

**Current Setup:**
```hcl
install_mysql_on_web = true   # MySQL on each web instance
create_ec2_db        = false  # Can't create in AWS Academy
create_rds           = false  # Requires manual setup
```

**What You Get:**
- Working MySQL database on each web instance
- Fully automated installation
- No AWS Academy restrictions
- Perfect for learning and development

**Limitation:**
- Each instance has its own separate database
- Not suitable for production multi-instance setups

**Solution:**
- Use ALB sticky sessions for consistent user experience
- Or run single instance (ASG min/max = 1)
- Or accept eventual consistency for non-critical data

This is the **most practical solution for AWS Academy** given the restrictions!
