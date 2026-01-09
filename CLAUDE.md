# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Terraform project that deploys a highly available, multi-tier AWS infrastructure across two Availability Zones. The architecture implements a production-ready web application environment with load balancing, auto-scaling, and Multi-AZ RDS database.

**For detailed architecture documentation, see [architecture.md](architecture.md).**

**For AWS Academy compatibility notes, see [AWS_ACADEMY.md](AWS_ACADEMY.md).**

### AWS Academy Compatibility

This project has been modified to work with AWS Academy's restricted IAM permissions:
- Uses existing `EC2InstanceProfile` instead of creating IAM roles
- Disabled RDS enhanced monitoring, Performance Insights, and custom parameter groups
- All core networking, ALB, Auto Scaling, and basic RDS features remain functional

See [AWS_ACADEMY.md](AWS_ACADEMY.md) for detailed modifications and troubleshooting.

## Common Commands

### Terraform Operations

```bash
# Initialize Terraform (download providers and modules)
terraform init

# Format Terraform files
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes (dry-run)
terraform plan

# Plan with variable file
terraform plan -var-file="terraform.tfvars"

# Apply changes
terraform apply

# Apply without confirmation prompt
terraform apply -auto-approve

# Destroy infrastructure
terraform destroy

# Show current state
terraform show

# List resources in state
terraform state list

# Output values
terraform output
```

### Testing and Linting

```bash
# Run tflint (if installed)
tflint

# Run terraform fmt check
terraform fmt -check -recursive

# Validate all configurations
terraform validate
```

## Architecture Quick Reference

The infrastructure follows a **multi-tier, multi-AZ architecture** pattern with:
- **VPC** (10.0.0.0/16) spanning 2 Availability Zones
- **Public Subnets** (10.0.0.0/24, 10.0.2.0/24) for ALB and NAT Gateway
- **Private Subnets** (10.0.1.0/24, 10.0.3.0/24) for web instances and RDS
- **Application Load Balancer** distributing traffic to Auto Scaling Group
- **Multi-AZ RDS MySQL** for database high availability

**See [architecture.md](architecture.md) for complete architecture details, traffic flows, and design decisions.**

## Project Structure

The Terraform code is organized by resource type and logical components:

```
.
├── CLAUDE.md               # This file - development guidance
├── architecture.md         # Detailed architecture documentation
├── README.md               # User-facing project documentation
├── versions.tf             # Terraform and provider version constraints
├── provider.tf             # AWS provider configuration
├── backend.tf              # Remote state configuration (S3 + DynamoDB)
├── variables.tf            # Input variable definitions
├── outputs.tf              # Output value definitions
├── terraform.tfvars.example # Example variable values
├── vpc.tf                  # VPC, Internet Gateway, route tables
├── subnets.tf              # Subnet definitions across both AZs
├── nat.tf                  # NAT Gateway and Elastic IP
├── security_groups.tf      # Security group rules for all tiers
├── alb.tf                  # Application Load Balancer configuration
├── launch_template.tf      # EC2 launch template with IAM roles
├── user_data.sh            # Instance initialization script
├── asg.tf                  # Auto Scaling Group and scaling policies
└── rds.tf                  # RDS MySQL Multi-AZ database
```

## Development Guidelines

### Resource Naming Convention
All resources follow a consistent naming pattern:
- **Format**: `${var.project_name}-${var.environment}-{resource-type}-{identifier}`
- **Example**: `myapp-prod-vpc`, `myapp-prod-web-asg`, `myapp-prod-mysql`
- This naming convention is applied via variables to ensure consistency

### Tagging Strategy
All resources automatically receive these tags (configured in provider.tf):
- `Project`: Value from `var.project_name`
- `Environment`: Value from `var.environment`
- `ManagedBy`: "Terraform"
- Individual resources may have additional `Name` tags

### State Management
- **Backend**: S3 + DynamoDB (configured in backend.tf, initially commented out)
- **Local State**: Never commit `terraform.tfstate` or `terraform.tfvars` to version control
- **State Locking**: Enabled via DynamoDB to prevent concurrent modifications
- See backend.tf for setup instructions before enabling remote state

### Security Best Practices
- Database passwords must be set via `terraform.tfvars` (marked as sensitive)
- Consider using AWS Secrets Manager or SSM Parameter Store for production
- IAM roles are used for EC2 instances (no hardcoded credentials)
- All RDS storage is encrypted at rest
- Private subnets have no direct internet access (NAT Gateway for outbound only)

### Important Implementation Notes

#### CIDR Allocation
- VPC: 10.0.0.0/16
- Public Subnets: 10.0.0.0/24 (AZ-A), 10.0.2.0/24 (AZ-B)
- Private Subnets: 10.0.1.0/24 (AZ-A), 10.0.3.0/24 (AZ-B)

#### Cost Optimization
- **Single NAT Gateway** deployed in AZ-A only (not both AZs) to reduce costs (~$32/month savings)
- For production requiring higher availability, deploy NAT Gateway in both AZs by modifying nat.tf
- Auto Scaling policies help match capacity to demand

#### User Data Script
- Located in `user_data.sh` and referenced by launch_template.tf
- Uses templatefile() to inject variables (DB endpoint, credentials)
- Installs Apache HTTP server and creates basic health check page
- For production, customize this script for your application needs

## Documentation Maintenance

**IMPORTANT**: When making changes to the infrastructure, keep related documentation synchronized:

### When modifying Terraform code:

1. **Update architecture.md** if changes affect:
   - Network topology or IP addressing
   - Component relationships or data flows
   - Security group rules or access patterns
   - High availability or disaster recovery design
   - New components or services added

2. **Update this file (CLAUDE.md)** if changes affect:
   - Common commands or workflows
   - File structure or organization
   - Development conventions or patterns
   - Important implementation notes

3. **Update README.md** if changes affect:
   - Deployment steps or prerequisites
   - Variable configuration requirements
   - Cost estimates or resource sizing
   - User-facing functionality

### Example scenarios requiring documentation updates:

- **Adding a new component** (e.g., ElastiCache, CloudFront):
  - Update architecture.md with component details and integration points
  - Add relevant Terraform commands to CLAUDE.md if needed
  - Update README.md with new outputs and usage instructions

- **Changing network layout** (e.g., adding subnet, changing CIDR):
  - Update CIDR tables in architecture.md
  - Update CIDR references in CLAUDE.md
  - Update network diagram if available

- **Modifying security groups**:
  - Update security group rules section in architecture.md
  - Update security considerations if access patterns change

- **Adding new variables**:
  - Update README.md with variable descriptions
  - Update terraform.tfvars.example with new variables

**Before committing changes, verify all three documentation files (CLAUDE.md, architecture.md, README.md) are consistent with the implementation.**
