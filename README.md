# AWS Multi-Tier Infrastructure with Terraform

This Terraform project deploys a highly available, production-ready AWS infrastructure for web applications.

## Architecture

![AWS Architecture](architecture.png)

For detailed architecture documentation, see [architecture.md](architecture.md).

For Claude Code guidance, see [CLAUDE.md](CLAUDE.md).

## ⚠️ AWS Academy Users

This project is compatible with AWS Academy's restricted IAM permissions. Key modifications:
- Uses existing `EC2InstanceProfile` instead of creating IAM roles
- RDS enhanced monitoring and Performance Insights are disabled
- **RDS must be created manually** via AWS Console (see [RDS_WORKAROUND.md](RDS_WORKAROUND.md))
- See [AWS_ACADEMY.md](AWS_ACADEMY.md) for complete compatibility notes and troubleshooting

**Quick Start**: See [QUICKSTART_AWS_ACADEMY.md](QUICKSTART_AWS_ACADEMY.md) for step-by-step deployment guide.

**Database Options**:
- ✅ **MySQL on Web Servers** (Recommended): Fully automated, works in AWS Academy - See [MYSQL_ON_WEB.md](MYSQL_ON_WEB.md)
- ⚠️ **RDS**: Requires manual setup via console - See [RDS_WORKAROUND.md](RDS_WORKAROUND.md)
- ⚠️ **Dedicated EC2 DB**: AWS Academy blocks EC2 instance creation - See [EC2_DATABASE.md](EC2_DATABASE.md)

All core features (VPC, ALB, Auto Scaling, Database) work within AWS Academy constraints!

### Key Components

- **VPC** (10.0.0.0/16) spanning 2 Availability Zones
- **Public Subnets** for Application Load Balancer and NAT Gateway
- **Private Subnets** for web application instances and RDS database
- **Application Load Balancer** (ALB) for traffic distribution
- **Auto Scaling Group** with 2-6 instances (t3.small)
- **Multi-AZ RDS MySQL 8.0** database (db.t3.small)
- **NAT Gateway** for private subnet internet access
- **Security Groups** with least-privilege access controls

## Prerequisites

1. **Terraform** >= 1.5.0
   ```bash
   terraform --version
   ```

2. **AWS CLI** configured with appropriate credentials
   ```bash
   aws configure
   # Or use environment variables:
   # export AWS_ACCESS_KEY_ID="your-access-key"
   # export AWS_SECRET_ACCESS_KEY="your-secret-key"
   # export AWS_DEFAULT_REGION="us-east-1"
   ```

3. **AWS Account** with permissions to create:
   - VPC, Subnets, Internet Gateway, NAT Gateway
   - EC2 instances, Auto Scaling Groups, Launch Templates
   - Application Load Balancer
   - RDS instances
   - IAM roles and policies
   - Security Groups

## Quick Start

### 1. Clone and Configure

```bash
# Navigate to project directory
cd cloud15

# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
# IMPORTANT: Set a strong db_password!
nano terraform.tfvars
```

### 2. Initialize Terraform

```bash
# Download providers and modules
terraform init
```

### 3. Review the Plan

```bash
# Preview what will be created
terraform plan
```

### 4. Deploy Infrastructure

```bash
# Deploy (will prompt for confirmation)
terraform apply

# Or deploy without confirmation
terraform apply -auto-approve
```

### 5. Access Your Application

After deployment completes (10-15 minutes), Terraform will output the ALB DNS name:

```bash
# Get the ALB DNS name
terraform output alb_dns_name
```

Visit `http://<alb-dns-name>` in your browser to see your application.

## Backend Setup (Recommended for Production)

For team collaboration and state locking, set up an S3 backend:

### 1. Create S3 Bucket and DynamoDB Table

```bash
# Create S3 bucket for state storage
aws s3api create-bucket \
  --bucket your-terraform-state-bucket \
  --region us-east-1

# Enable versioning on the bucket
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name your-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 2. Enable Backend Configuration

Edit `backend.tf` and uncomment the backend configuration block, updating with your bucket and table names.

### 3. Migrate State

```bash
terraform init -migrate-state
```

## Configuration

### Required Variables

These must be set in `terraform.tfvars`:

- `db_password` - Strong password for RDS database (minimum 8 characters)

### Optional Variables

You can customize these in `terraform.tfvars` (defaults shown):

```hcl
project_name               = "myapp"
environment                = "prod"
aws_region                 = "us-east-1"
vpc_cidr                   = "10.0.0.0/16"
web_instance_type          = "t3.small"
asg_min_size               = 2
asg_max_size               = 6
asg_desired_capacity       = 2
asg_target_cpu_utilization = 70
db_instance_class          = "db.t3.small"
db_name                    = "webapp"
db_username                = "admin"
```

See `variables.tf` for the complete list of configurable variables.

## Outputs

After deployment, Terraform provides these outputs:

| Output | Description |
|--------|-------------|
| `alb_dns_name` | Load balancer DNS name (use this to access your app) |
| `rds_endpoint` | Database connection endpoint |
| `vpc_id` | VPC identifier |
| `nat_gateway_ip` | NAT Gateway public IP (for whitelisting) |

View all outputs:

```bash
terraform output
```

## Management

### Scaling

To adjust the number of instances:

```bash
# Edit terraform.tfvars
asg_min_size         = 3
asg_desired_capacity = 4
asg_max_size         = 10

# Apply changes
terraform apply
```

Auto Scaling will also automatically scale based on:
- CPU utilization (target: 70%)
- ALB request count (target: 1000 requests per target)

### Updating Configuration

```bash
# Make changes to .tf files or terraform.tfvars
# Preview changes
terraform plan

# Apply changes
terraform apply
```

### Viewing Resources

```bash
# List all resources
terraform state list

# Show specific resource
terraform show aws_lb.main

# Get current state
terraform show
```

## Monitoring

### CloudWatch Metrics

Monitor your infrastructure in AWS CloudWatch:

- **ALB**: Request count, target response time, healthy host count
- **Auto Scaling**: CPU utilization, network traffic, instance count
- **RDS**: CPU, connections, IOPS, replication lag

### Logs

CloudWatch Logs are enabled for:
- RDS: Error logs, general logs, slow query logs

### Health Checks

The ALB performs health checks on instances:
- Path: `/`
- Interval: 30 seconds
- Healthy threshold: 2 consecutive successes
- Unhealthy threshold: 2 consecutive failures

## Security

### Network Security

- Web instances and databases are in **private subnets** with no direct internet access
- NAT Gateway provides controlled outbound internet access
- Security groups implement least-privilege access
- Multi-layer security: ALB → Web → Database

### Encryption

- RDS storage encrypted at rest
- HTTPS support ready (add ACM certificate to `alb.tf`)

### Secrets Management

**IMPORTANT**: Never commit `terraform.tfvars` to version control!

For production, consider using:
- AWS Secrets Manager for database credentials
- AWS Systems Manager Parameter Store for configuration

### Access

- EC2 instances use IAM roles (no access keys needed)
- AWS Systems Manager Session Manager enabled for secure instance access (no SSH keys required)

## Cost Optimization

### Current Configuration Costs (Approximate)

Monthly costs in us-east-1 (as of 2025):

- NAT Gateway: ~$32/month + data transfer
- Application Load Balancer: ~$16/month + LCU charges
- EC2 (2x t3.small): ~$30/month
- RDS Multi-AZ (db.t3.small): ~$55/month
- EBS Storage (gp3): ~$2/month
- **Total**: ~$135-150/month (excluding data transfer)

### Cost Savings Tips

1. Use Reserved Instances or Savings Plans for 30-75% discount on predictable workloads
2. Consider single-AZ RDS for dev/test environments (not recommended for production)
3. Use Auto Scaling to match capacity to demand
4. Enable RDS storage autoscaling to avoid over-provisioning
5. Review CloudWatch metrics to right-size instances

## Troubleshooting

### Instances Not Healthy

```bash
# Check Auto Scaling Group health
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names $(terraform output -raw web_asg_name)

# Check target health
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw alb_arn | sed 's/:loadbalancer/:targetgroup/')
```

### Cannot Connect to Database

1. Check security group rules
2. Verify instances are in correct subnets
3. Check RDS endpoint: `terraform output rds_endpoint`
4. Verify credentials in user data script

### Terraform Errors

```bash
# Refresh state
terraform refresh

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive
```

## Cleanup

To destroy all resources:

```bash
# Preview what will be destroyed
terraform plan -destroy

# Destroy infrastructure
terraform destroy

# Or without confirmation
terraform destroy -auto-approve
```

**Note**: By default, a final RDS snapshot will be created before deletion. Set `db_skip_final_snapshot = true` in `terraform.tfvars` to skip this.

## Project Structure

```
.
├── README.md                   # This file
├── CLAUDE.md                   # Claude Code guidance
├── architecture.md             # Detailed architecture documentation
├── architecture.png            # Architecture diagram
├── versions.tf                 # Terraform version constraints
├── provider.tf                 # AWS provider configuration
├── backend.tf                  # Remote state configuration
├── variables.tf                # Input variable definitions
├── outputs.tf                  # Output value definitions
├── terraform.tfvars.example    # Example variable values
├── .gitignore                  # Git ignore rules
├── vpc.tf                      # VPC and route tables
├── subnets.tf                  # Subnet definitions
├── nat.tf                      # NAT Gateway
├── security_groups.tf          # Security group rules
├── alb.tf                      # Application Load Balancer
├── launch_template.tf          # EC2 launch template
├── user_data.sh                # Instance initialization script
├── asg.tf                      # Auto Scaling Group
└── rds.tf                      # RDS MySQL database
```

## Contributing

For guidance on working with this codebase, see [CLAUDE.md](CLAUDE.md).

## License

This project is provided as-is for educational and demonstration purposes.

## Support

For issues or questions:
1. Review [architecture.md](architecture.md) for detailed documentation
2. Check [CLAUDE.md](CLAUDE.md) for development guidance
3. Review AWS documentation for specific services
4. Check Terraform documentation: https://www.terraform.io/docs
