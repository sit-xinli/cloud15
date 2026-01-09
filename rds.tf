# AWS Academy Workaround: DB Subnet Group
# AWS Academy restricts creating DB subnet groups programmatically
# This must be created manually via AWS Console first
# See AWS_ACADEMY.md for step-by-step instructions

# Uncomment this block ONLY if you've manually created the subnet group
# data "aws_db_subnet_group" "main" {
#   name = "${var.project_name}-${var.environment}-db-subnet-group"
# }

# AWS Academy: Use default parameter group instead of creating custom one
# Custom parameter groups require permissions that AWS Academy may not provide

# RDS MySQL Instance (Multi-AZ)
# Set var.create_rds = false if DB subnet group creation fails
resource "aws_db_instance" "main" {
  count          = var.create_rds ? 1 : 0
  identifier     = "${var.project_name}-${var.environment}-mysql"
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = var.db_instance_class

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Storage configuration
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # High Availability
  # AWS Academy: Set to false if deployment fails
  multi_az = false # Changed from true for AWS Academy compatibility

  # Network configuration
  # AWS Academy: Comment out if you can't create DB subnet group
  # db_subnet_group_name   = data.aws_db_subnet_group.main.name

  # For AWS Academy: Use availability_zone to deploy in specific subnet
  # This will be single-AZ instead of Multi-AZ
  availability_zone = var.availability_zones[0]

  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Backup configuration
  backup_retention_period   = var.db_backup_retention_period
  backup_window             = var.db_backup_window
  maintenance_window        = var.db_maintenance_window
  skip_final_snapshot       = var.db_skip_final_snapshot
  final_snapshot_identifier = var.db_skip_final_snapshot ? null : "${var.project_name}-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # AWS Academy: Disabled enhanced monitoring (requires IAM role creation)
  # enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  monitoring_interval = 0
  # monitoring_role_arn             = aws_iam_role.rds_monitoring.arn

  # AWS Academy: Disabled Performance Insights (may require additional permissions)
  # performance_insights_enabled          = true
  # performance_insights_retention_period = 7

  # AWS Academy: Use default parameter group
  # parameter_group_name = aws_db_parameter_group.main.name

  # Deletion protection
  deletion_protection = false

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  # Copy tags to snapshots
  copy_tags_to_snapshot = true

  tags = {
    Name = "${var.project_name}-${var.environment}-mysql"
  }

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier
    ]
  }
}

# AWS Academy: IAM roles for RDS monitoring are disabled
# AWS Academy restricts IAM role creation
# If you need enhanced monitoring, you would need to use an existing IAM role
