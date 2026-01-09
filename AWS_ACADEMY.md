# AWS Academy Compatibility Notes

This document describes the modifications made to support AWS Academy's restricted permissions.

## AWS Academy Restrictions

AWS Academy environments have limited IAM permissions. Specifically, you **cannot**:
- Create IAM roles
- Create IAM policies
- Create RDS parameter groups (in some cases)
- Create RDS subnet groups (in some cases)
- Enable RDS enhanced monitoring (requires IAM roles)

## Modifications Made for AWS Academy

### 1. EC2 IAM Instance Profile

**Original**: Creates custom IAM role with SSM and CloudWatch permissions
```hcl
resource "aws_iam_role" "web_instance" { ... }
resource "aws_iam_instance_profile" "web" { ... }
```

**Modified**: Uses existing `EC2InstanceProfile` provided by AWS Academy
```hcl
data "aws_iam_instance_profile" "lab_profile" {
  name = var.ec2_instance_profile_name  # Default: "EC2InstanceProfile"
}
```

**File**: `launch_template.tf`

### 2. RDS Parameter Group

**Original**: Creates custom parameter group with UTF-8 settings
```hcl
resource "aws_db_parameter_group" "main" {
  family = "mysql8.0"
  # custom parameters
}
```

**Modified**: Uses default MySQL 8.0 parameter group (removed resource)

**File**: `rds.tf`

### 3. RDS Enhanced Monitoring

**Original**: Creates IAM role for enhanced monitoring
```hcl
resource "aws_iam_role" "rds_monitoring" { ... }
monitoring_interval = 60
```

**Modified**: Disabled enhanced monitoring
```hcl
monitoring_interval = 0
```

**File**: `rds.tf`

### 4. RDS Performance Insights

**Original**: Enabled with 7-day retention
```hcl
performance_insights_enabled = true
```

**Modified**: Disabled (commented out)

**File**: `rds.tf`

### 5. RDS CloudWatch Logs

**Original**: Exports error, general, and slow query logs
```hcl
enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
```

**Modified**: Disabled (commented out)

**File**: `rds.tf`

## Potential Issues and Solutions

### Issue: DB Subnet Group Creation Fails

**Error**:
```
Error: creating RDS DB Subnet Group: AccessDenied
```

**Solution**:
AWS Academy may restrict DB subnet group creation. If this occurs:

1. Check if a default DB subnet group exists:
```bash
aws rds describe-db-subnet-groups
```

2. If a default exists, modify `rds.tf` to use it:
```hcl
# Comment out the resource
# resource "aws_db_subnet_group" "main" { ... }

# Use default or existing subnet group
resource "aws_db_instance" "main" {
  # Remove or comment out this line:
  # db_subnet_group_name = aws_db_subnet_group.main.name

  # Or use existing group:
  # db_subnet_group_name = "default"
}
```

### Issue: Cannot Create Multi-AZ RDS

**Error**:
```
Error: operation error RDS: CreateDBInstance, AccessDenied
```

**Solution**:
AWS Academy may restrict Multi-AZ deployments. Modify `rds.tf`:
```hcl
# Change from:
multi_az = true

# To:
multi_az = false
```

Note: This reduces high availability but works within Academy constraints.

### Issue: Storage Encryption Not Allowed

**Error**:
```
Error: storage_encrypted is not supported for db.t3.small
```

**Solution**:
Some AWS Academy environments restrict encryption. Modify `rds.tf`:
```hcl
# Change from:
storage_encrypted = true

# To:
storage_encrypted = false
```

## Features Still Available

Despite the restrictions, the following production-grade features still work:

✅ **Multi-AZ VPC Architecture** - 2 availability zones with public/private subnets
✅ **Application Load Balancer** - Internet-facing with health checks
✅ **Auto Scaling Group** - CPU-based scaling (2-6 instances)
✅ **Security Groups** - Proper network isolation and least-privilege access
✅ **NAT Gateway** - Outbound internet access for private subnets
✅ **RDS MySQL** - Database with automated backups (single-AZ in restricted mode)
✅ **EBS Encryption** - Encrypted volumes for EC2 instances
✅ **CloudWatch Metrics** - Basic monitoring for all resources

## Recommended Testing Workflow

1. **Start with Minimal Configuration**
   ```bash
   terraform plan
   ```

2. **If you encounter permission errors**, check which resource is failing

3. **Modify the failing resource**:
   - For IAM resources: Use existing AWS Academy resources
   - For RDS features: Disable or use defaults
   - For other services: Check AWS Academy documentation

4. **Apply incrementally**:
   ```bash
   # Apply only specific resources
   terraform apply -target=aws_vpc.main
   terraform apply -target=aws_subnet.public
   # etc.
   ```

## Comparison: Full vs AWS Academy Version

| Feature | Full Version | AWS Academy Version |
|---------|-------------|---------------------|
| Custom IAM Roles | ✅ Created | ❌ Uses LabInstanceProfile |
| RDS Parameter Group | ✅ Custom UTF-8 | ❌ Uses default |
| RDS Enhanced Monitoring | ✅ 60-second interval | ❌ Disabled |
| Performance Insights | ✅ 7-day retention | ❌ Disabled |
| CloudWatch Logs Export | ✅ Error/General/Slow | ❌ Disabled |
| Multi-AZ RDS | ✅ Enabled | ⚠️ May need to disable |
| VPC & Networking | ✅ Full features | ✅ Full features |
| ALB & Auto Scaling | ✅ Full features | ✅ Full features |
| Security Groups | ✅ Full features | ✅ Full features |

## Converting Back to Full Version

If you deploy this to a standard AWS account (non-Academy), you can restore full features:

1. Uncomment IAM role creation in `launch_template.tf`
2. Uncomment RDS parameter group in `rds.tf`
3. Re-enable enhanced monitoring, Performance Insights, and CloudWatch logs
4. Set `multi_az = true` if it was changed
5. Run `terraform plan` to see what will be added

## Additional Resources

- [AWS Academy Learner Lab](https://awsacademy.instructure.com/)
- [AWS Academy IAM Restrictions](https://docs.aws.amazon.com/academy/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Support

If you encounter other AWS Academy restrictions not covered here:
1. Check the error message for the specific permission denied
2. Look for the AWS resource type (e.g., `iam:CreateRole`, `rds:CreateDBParameterGroup`)
3. Determine if the resource can be:
   - Removed (not critical)
   - Replaced with existing AWS Academy resource
   - Simplified to use default settings

Document your findings and update this file for future reference.
