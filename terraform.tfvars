# Project Configuration
# Copy this file to terraform.tfvars and update with your values

# Project and Environment
project_name = "Lab6"
environment  = "education"

# AWS Region
aws_region = "us-east-1"

# VPC and Network Configuration
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.0.0.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.1.0/24", "10.0.3.0/24"]

# EC2 Configuration
web_instance_type         = "t3.small"
ec2_instance_profile_name = "Work-Role" # AWS Academy: Use existing profile

# Auto Scaling Configuration
# For FAST load testing: scales quickly from 1 to 5 instances
asg_min_size                  = 2
asg_max_size                  = 5
asg_desired_capacity          = 2
asg_health_check_grace_period = 180
asg_target_cpu_utilization    = 50  # Lower threshold = faster scaling

# Database Configuration
# MySQL on dedicated EC2 instances (always created)
db_name             = "webapp"
db_username         = "admin"
db_password         = "CHANGE_ME_TO_STRONG_PASSWORD" # IMPORTANT: Use a strong password!
db_ec2_instance_type = "t3.small"
db_ec2_volume_size  = 30

# Load Testing - creates instance and starts load testing automatically
run_load_test          = false
test_instance_type     = "t3.small"  # More powerful for aggressive load generation
load_test_concurrency  = 200         # 200 concurrent connections (very aggressive)
load_test_duration     = 0           # Continuous load (no breaks)

# Backend Configuration (Optional - for documentation)
# Update these values in backend.tf when ready to use remote state
# backend_s3_bucket       = "my-terraform-state-bucket"
# backend_dynamodb_table  = "my-terraform-locks"
