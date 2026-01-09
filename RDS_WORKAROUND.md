# RDS Deployment Workaround for AWS Academy

AWS Academy restricts creating RDS DB subnet groups programmatically. This guide provides solutions.

## Option 1: Try Automated Deployment First (Recommended)

The configuration has been modified to deploy RDS without explicitly specifying a DB subnet group.

### Step 1: Attempt Deployment
```bash
terraform apply
```

### Step 2: If It Works
✅ Great! Your RDS instance is created in the specified availability zone with your VPC security groups.

### Step 3: If It Fails with Subnet Error
⚠️ Proceed to Option 2 below.

## Option 2: Deploy Without RDS

If automated RDS deployment fails, deploy the infrastructure without RDS and add it manually later.

### Step 1: Disable RDS in Terraform

Edit `terraform.tfvars`:
```hcl
create_rds = false  # Change from true
```

### Step 2: Deploy Infrastructure
```bash
terraform apply
```

This will create everything except RDS:
- ✅ VPC and Subnets
- ✅ Application Load Balancer
- ✅ Auto Scaling Group
- ✅ Security Groups
- ❌ RDS (skipped)

### Step 3: Create RDS Manually via AWS Console

1. **Go to RDS Console**: https://console.aws.amazon.com/rds/

2. **Create Database**:
   - Click "Create database"
   - Choose "Standard create"
   - Engine: MySQL 8.0.35
   - Templates: Free tier or Dev/Test

3. **Settings**:
   - DB instance identifier: `myapp-prod-mysql`
   - Master username: `admin`
   - Master password: [Use the same password from terraform.tfvars]

4. **Instance Configuration**:
   - DB instance class: db.t3.small (or db.t3.micro for free tier)

5. **Storage**:
   - Storage type: gp3
   - Allocated storage: 20 GB
   - ✅ Enable storage autoscaling
   - Maximum storage threshold: 100 GB

6. **Connectivity** (IMPORTANT):
   - Virtual private cloud (VPC): Select `myapp-prod-vpc`
   - Subnet group: It will create automatically or use default
   - Public access: **No**
   - VPC security group: Choose existing → Select `myapp-prod-rds-sg`
   - Availability Zone: us-east-1a (or any in your region)

7. **Additional Configuration**:
   - Initial database name: `webapp`
   - ✅ Enable automated backups
   - Backup retention period: 7 days
   - ❌ Disable Enhanced Monitoring (AWS Academy restriction)
   - ❌ Disable Performance Insights

8. **Create Database**

### Step 4: Get RDS Endpoint

After database is available (5-10 minutes):

```bash
aws rds describe-db-instances \
  --db-instance-identifier myapp-prod-mysql \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text
```

Or get it from the console.

### Step 5: Update Application

The Auto Scaling Group instances need the RDS endpoint. Since user_data already runs, you have options:

**Option A: Recreate instances** (simplest):
```bash
# Terminate current instances (ASG will create new ones)
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name myapp-prod-web-asg \
  --desired-capacity 0

# Wait 30 seconds

aws autoscaling set-desired-capacity \
  --auto-scaling-group-name myapp-prod-web-asg \
  --desired-capacity 2
```

**Option B: SSH and update manually**:
1. Connect via Session Manager
2. Update `/etc/environment` with correct DB_ENDPOINT

## Option 3: Use Default VPC (Not Recommended)

If you must use RDS with the default VPC subnet group:

⚠️ **WARNING**: This breaks the multi-tier architecture and security isolation.

1. Don't create custom VPC - use AWS Academy default VPC
2. Deploy ALB, ASG, and RDS in default VPC
3. Manage security via security groups only

This is **not recommended** as it defeats the purpose of network isolation.

## Option 4: External Database

Use an external database service:

- **Amazon Aurora Serverless** (if available in AWS Academy)
- **RDS Proxy** (if available)
- **Self-hosted MySQL** on EC2 instance in private subnet
- **Amazon DynamoDB** instead of MySQL

## Troubleshooting

### Error: DB subnet group cannot be created

**Symptom**:
```
Error: creating RDS DB Subnet Group: AccessDenied
```

**Solution**: Use Option 2 (deploy without RDS, create manually)

### Error: Parameter DBSubnetGroupName must be provided

**Symptom**:
```
Error: DBSubnetGroupName is required
```

**Solution**:
1. Set `create_rds = false` in terraform.tfvars
2. Follow Option 2 to create via console

### Error: Cannot create database in VPC without DB subnet group

**Symptom**: RDS creation fails saying subnet group is required

**Solution**: Follow Option 2 to create via console (AWS Console may have different permissions)

### RDS Created But Instances Can't Connect

**Check Security Groups**:
```bash
# Verify RDS security group allows MySQL from web instances
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw rds_security_group_id)
```

Should show ingress rule for port 3306 from web security group.

**Check Subnets**:
```bash
# Verify RDS is in private subnet
aws rds describe-db-instances \
  --db-instance-identifier myapp-prod-mysql \
  --query 'DBInstances[0].DBSubnetGroup.Subnets[*].SubnetIdentifier'
```

Should show your private subnet IDs.

## Verification After Manual RDS Creation

```bash
# Test from web instance (via Session Manager)
# 1. Get instance ID
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=myapp-prod-web-instance" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text

# 2. Connect to instance
aws ssm start-session --target <instance-id>

# 3. Test MySQL connection
mysql -h <rds-endpoint> -u admin -p
```

## Cost Implications

| Deployment Option | Monthly Cost (Credits) |
|-------------------|------------------------|
| Full (with RDS Multi-AZ) | ~$150 |
| Single-AZ RDS (manual) | ~$75 |
| Without RDS | ~$95 |
| Minimal (t3.micro instances, no RDS) | ~$45 |

Remember AWS Academy uses credits, not real money.

## Summary

**Best Approach for AWS Academy**:
1. Try automated deployment (`create_rds = true`)
2. If fails, set `create_rds = false`
3. Deploy infrastructure without RDS
4. Create RDS manually via AWS Console
5. Update instances with RDS endpoint

This gives you the full multi-tier architecture while working within AWS Academy limitations.
