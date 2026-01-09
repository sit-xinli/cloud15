# Quick Start Guide for AWS Academy

This guide helps you deploy the infrastructure in AWS Academy environment.

## Prerequisites ✅

- AWS Academy Lab session started
- AWS credentials configured (automatically in AWS Academy)
- Terraform installed (you have `/home/suny/.tfenv/bin/terraform`)

## Deployment Steps

### 1. Configure Variables

```bash
# Copy example to actual tfvars file
cp terraform.tfvars.example terraform.tfvars

# Edit the file
nano terraform.tfvars
```

**Required: Set a strong database password**
```hcl
# Database Configuration (MySQL on EC2 - fully automated!)
create_rds    = false
create_ec2_db = true   # MySQL on EC2 instance

db_password = "YourStrongPassword123!"  # Change this!
```

### 2. Initialize Terraform

```bash
/home/suny/.tfenv/bin/terraform init
```

### 3. Review What Will Be Created

```bash
/home/suny/.tfenv/bin/terraform plan
```

Expected output: **Plan: ~35-40 to add, 0 to change, 0 to destroy**

Note: RDS is disabled by default (`create_rds = false`). See [RDS_WORKAROUND.md](RDS_WORKAROUND.md) for manual RDS setup.

### 4. Deploy Infrastructure

```bash
/home/suny/.tfenv/bin/terraform apply
```

Type `yes` when prompted.

⏱️ **Deployment Time**: 10-15 minutes (RDS takes the longest)

### 5. Get Your Application URL

```bash
/home/suny/.tfenv/bin/terraform output alb_dns_name
```

Visit the URL in your browser: `http://<alb-dns-name>`

## What Gets Created

### Network Layer
- ✅ VPC (10.0.0.0/16)
- ✅ 2 Public Subnets (for ALB)
- ✅ 2 Private Subnets (for web instances and RDS)
- ✅ Internet Gateway
- ✅ NAT Gateway
- ✅ Route Tables

### Application Layer
- ✅ Application Load Balancer
- ✅ Target Group
- ✅ Auto Scaling Group (2-6 instances)
- ✅ Launch Template with Amazon Linux 2023
- ✅ Security Groups

### Database Layer
- ✅ **MySQL on EC2** (fully automated, recommended!)
- 📝 See [EC2_DATABASE.md](EC2_DATABASE.md) for details
- Alternative: Manual RDS via console - [RDS_WORKAROUND.md](RDS_WORKAROUND.md)

## Important Outputs

After deployment, get these values:

```bash
# Application URL
terraform output alb_dns_name

# Database endpoint (for application configuration)
terraform output rds_endpoint

# NAT Gateway IP (for whitelisting)
terraform output nat_gateway_ip

# All outputs
terraform output
```

## Verify Deployment

### Check Load Balancer
```bash
aws elbv2 describe-load-balancers --names myapp-prod-alb
```

### Check Auto Scaling Group
```bash
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names myapp-prod-web-asg
```

### Check RDS Instance
```bash
aws rds describe-db-instances --db-instance-identifier myapp-prod-mysql
```

### Access the Application
1. Get ALB DNS: `terraform output alb_dns_name`
2. Open in browser: `http://<alb-dns-name>`
3. You should see a welcome page

## Troubleshooting

### Issue: DB Subnet Group Creation Fails

**Error**: `AccessDenied: not authorized to perform: rds:CreateDBSubnetGroup`

**Solution**: Comment out DB subnet group resource in `rds.tf`:
```hcl
# Comment out this resource
# resource "aws_db_subnet_group" "main" { ... }

# In RDS instance, remove the line:
# db_subnet_group_name = aws_db_subnet_group.main.name
```

### Issue: Multi-AZ Not Allowed

**Error**: `AccessDenied` when creating Multi-AZ RDS

**Solution**: Set `multi_az = false` in `rds.tf`:
```hcl
multi_az = false  # Change from true
```

### Issue: Storage Encryption Fails

**Error**: `storage_encrypted is not supported`

**Solution**: In `rds.tf`:
```hcl
storage_encrypted = false  # Change from true
```

### Issue: Timeout During Apply

AWS Academy has session time limits. If deployment times out:

1. **Don't panic!** - Partially created resources are tracked
2. Run `terraform apply` again - it will continue
3. Check what's created: `terraform state list`

## Costs

AWS Academy uses credits, not real money. Approximate credit usage:

- **Per Hour**: ~$0.50 in credits
- **8-hour session**: ~$4 in credits
- **Monthly** (if left running): ~$150 in credits

Remember to destroy when done!

## Scaling

### Scale Up Instances
Edit `terraform.tfvars`:
```hcl
asg_desired_capacity = 4  # Increase from 2
asg_max_size = 8          # Increase from 6
```

Apply changes:
```bash
terraform apply
```

### Scale Database
Edit `terraform.tfvars`:
```hcl
db_instance_class = "db.t3.medium"  # Upgrade from db.t3.small
```

## Cleanup

**IMPORTANT**: Destroy resources before AWS Academy session ends!

```bash
# Destroy all infrastructure
/home/suny/.tfenv/bin/terraform destroy
```

Type `yes` when prompted.

⏱️ **Destroy Time**: 10-15 minutes

### If Destroy Fails

Sometimes RDS deletion protection or final snapshots cause issues:

```bash
# Skip final snapshot (edit terraform.tfvars)
db_skip_final_snapshot = true

# Retry destroy
terraform destroy
```

### Force Destroy Specific Resources

If stuck on a specific resource:

```bash
# Remove from state (last resort)
terraform state rm aws_db_instance.main

# Then manually delete in AWS Console
```

## Monitoring

### Check Auto Scaling Activity
```bash
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name myapp-prod-web-asg \
  --max-records 10
```

### Check Load Balancer Health
```bash
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw alb_arn | sed 's/loadbalancer/targetgroup/; s/app\///')
```

### View RDS Status
```bash
aws rds describe-db-instances \
  --db-instance-identifier myapp-prod-mysql \
  --query 'DBInstances[0].[DBInstanceStatus,MultiAZ,AllocatedStorage]'
```

## Testing Auto Scaling

### Simulate Load (SSH into instance via Session Manager)
```bash
# Get instance ID
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=myapp-prod-web-instance" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text

# Start Session Manager session
aws ssm start-session --target <instance-id>

# Simulate CPU load
yes > /dev/null &
```

Watch Auto Scaling add instances:
```bash
watch -n 10 'terraform output web_asg_name | xargs aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names | jq .AutoScalingGroups[0].Instances'
```

## Next Steps

1. **Customize Application**: Edit `user_data.sh` to deploy your app
2. **Add HTTPS**: Set up ACM certificate and enable HTTPS listener
3. **Configure Database**: Connect your application to RDS endpoint
4. **Set up Monitoring**: Enable CloudWatch dashboards
5. **Implement CI/CD**: Use GitHub Actions or GitLab CI

## Additional Resources

- [AWS Academy Documentation](https://awsacademy.instructure.com/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [AWS ALB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/)
- [Project Architecture](architecture.md)
- [AWS Academy Compatibility](AWS_ACADEMY.md)

## Support

If you encounter issues:
1. Check [AWS_ACADEMY.md](AWS_ACADEMY.md) for known restrictions
2. Review error messages carefully
3. Check AWS Academy Learner Lab session is active
4. Verify AWS credentials: `aws sts get-caller-identity`
