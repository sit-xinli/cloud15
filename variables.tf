# Project Configuration
variable "project_name" {
  description = "Name of the project, used for resource naming and tagging"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

# AWS Region Configuration
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"]
}

# EC2 Configuration
variable "web_instance_type" {
  description = "Instance type for web servers"
  type        = string
  default     = "t3.small"
}

variable "ec2_instance_profile_name" {
  description = "Name of existing IAM instance profile for EC2 instances (AWS Academy: use EC2InstanceProfile)"
  type        = string
  default     = "EC2InstanceProfile"
}


# Auto Scaling Configuration
variable "asg_min_size" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 6
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in Auto Scaling Group"
  type        = number
  default     = 2
}

variable "asg_health_check_grace_period" {
  description = "Time (in seconds) after instance comes into service before checking health"
  type        = number
  default     = 300
}

variable "asg_target_cpu_utilization" {
  description = "Target CPU utilization percentage for auto scaling"
  type        = number
  default     = 70
}

# RDS Configuration
variable "create_rds" {
  description = "Whether to create RDS instance (AWS Academy: set to false and use EC2 DB instead)"
  type        = bool
  default     = false # AWS Academy: RDS requires manual creation
}

variable "create_ec2_db" {
  description = "Whether to create MySQL on EC2 instance (AWS Academy blocks this - use install_mysql_on_web instead)"
  type        = bool
  default     = false # AWS Academy blocks direct EC2 creation
}

variable "db_ec2_instance_type" {
  description = "Instance type for EC2-based database"
  type        = string
  default     = "t3.small"
}

variable "db_ec2_volume_size" {
  description = "EBS volume size in GB for EC2 database"
  type        = number
  default     = 30
}

variable "db_instance_class" {
  description = "Instance class for RDS database"
  type        = string
  default     = "db.t3.small"
}

variable "db_name" {
  description = "Name of the database to create"
  type        = string
  default     = "webapp"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master password for the database (must be at least 8 characters)"
  type        = string
  sensitive   = true
}

variable "db_allocated_storage" {
  description = "Initial allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for RDS autoscaling in GB"
  type        = number
  default     = 100
}

variable "db_backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}

variable "db_backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "db_maintenance_window" {
  description = "Preferred maintenance window (UTC)"
  type        = string
  default     = "Mon:04:00-Mon:05:00"
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot when destroying database (set to false for production)"
  type        = bool
  default     = false
}

# Backend Configuration (for documentation purposes)
variable "backend_s3_bucket" {
  description = "S3 bucket name for Terraform state (update in backend.tf)"
  type        = string
  default     = ""
}

variable "backend_dynamodb_table" {
  description = "DynamoDB table name for Terraform state locking (update in backend.tf)"
  type        = string
  default     = ""
}
