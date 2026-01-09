# AWS Multi-Tier Architecture Documentation

## Architecture Overview

This document describes a highly available, multi-tier AWS infrastructure designed for production web applications. The architecture implements best practices for availability, security, and scalability.

## Architecture Diagram

![AWS Architecture](architecture.png)

## Architecture Components

### 1. Network Infrastructure

#### VPC (Virtual Private Cloud)
- **CIDR Block**: 10.0.0.0/16
- **DNS Resolution**: Enabled
- **DNS Hostnames**: Enabled
- **Purpose**: Isolated network environment for all resources

#### Availability Zones
The infrastructure spans **two Availability Zones** within a single AWS region:
- **Availability Zone A**: Primary zone
- **Availability Zone B**: Secondary zone for redundancy

#### Subnets

| Subnet Name | Type | CIDR | Availability Zone | Purpose |
|-------------|------|------|-------------------|---------|
| Public Subnet 1 | Public | 10.0.0.0/24 | AZ-A | NAT Gateway, ALB |
| Private Subnet 1 | Private | 10.0.1.0/24 | AZ-A | Web instances, RDS Primary |
| Public Subnet 2 | Public | 10.0.2.0/24 | AZ-B | ALB |
| Private Subnet 2 | Private | 10.0.3.0/24 | AZ-B | Web instances, RDS Secondary |

**Public Subnets**:
- Have routes to Internet Gateway
- Used for resources that need direct internet access
- Host NAT Gateway and Application Load Balancer

**Private Subnets**:
- Route internet-bound traffic through NAT Gateway
- Isolated from direct internet access
- Host application instances and databases

#### Internet Gateway
- Attached to VPC
- Enables internet connectivity for public subnets
- Used by resources in public subnets for inbound/outbound traffic

#### NAT Gateway
- **Location**: Public Subnet 1 (AZ-A)
- **Purpose**: Provides outbound internet access for private subnets
- **Elastic IP**: Required for static public IP address
- **Note**: Single NAT Gateway design for cost optimization. For production, consider Multi-AZ NAT Gateways.

#### Route Tables

**Public Route Table**:
- Associated with Public Subnets (10.0.0.0/24, 10.0.2.0/24)
- Routes:
  - `10.0.0.0/16` → Local (VPC)
  - `0.0.0.0/0` → Internet Gateway

**Private Route Table**:
- Associated with Private Subnets (10.0.1.0/24, 10.0.3.0/24)
- Routes:
  - `10.0.0.0/16` → Local (VPC)
  - `0.0.0.0/0` → NAT Gateway (in AZ-A)

### 2. Application Load Balancer (ALB)

- **Type**: Application Load Balancer (Layer 7)
- **Scheme**: Internet-facing
- **Subnets**: Deployed across both public subnets (AZ-A and AZ-B)
- **Security**: Configured with security group allowing HTTP/HTTPS traffic
- **Target**: Auto Scaling Group instances in private subnets
- **Health Checks**: Monitors instance health and routes traffic only to healthy instances

**Key Features**:
- Cross-zone load balancing
- Connection draining
- Sticky sessions (if needed)
- SSL/TLS termination
- Path-based or host-based routing

### 3. Auto Scaling Group

- **Deployment**: Spans both Availability Zones (AZ-A and AZ-B)
- **Subnets**: Private Subnet 1 and Private Subnet 2
- **Target**: Registered with Application Load Balancer
- **Scaling**: Dynamic scaling based on metrics (CPU, network, custom metrics)

**Configuration**:
- **Minimum Size**: Configurable (e.g., 2 instances)
- **Desired Capacity**: Configurable (e.g., 2 instances)
- **Maximum Size**: Configurable (e.g., 6 instances)
- **Health Check Type**: ELB health checks
- **Health Check Grace Period**: 300 seconds (typical)

**Auto Scaling Policies**:
- Scale up when average CPU > 70%
- Scale down when average CPU < 30%
- Target tracking or step scaling policies

### 4. Web Application Instances

- **Location**: Private Subnets (AZ-A and AZ-B)
- **Launch Template**: Defines instance configuration
- **Security Group**: Web Instance Security Group
- **Instance Type**: Configurable (e.g., t3.micro, t3.small)
- **AMI**: Application-specific AMI (Amazon Linux 2, Ubuntu, etc.)

**Security Group Rules** (Web Instance):
- **Inbound**:
  - HTTP (80) from ALB Security Group
  - HTTPS (443) from ALB Security Group
  - SSH (22) from Bastion/VPN (optional)
- **Outbound**:
  - All traffic to 0.0.0.0/0 (for updates, external API calls)

### 5. RDS Database (Multi-AZ)

- **Engine**: Configurable (MySQL, PostgreSQL, etc.)
- **Deployment**: Multi-AZ for high availability
- **Primary Instance**: Private Subnet 1 (AZ-A)
- **Standby Instance**: Private Subnet 2 (AZ-B)
- **Subnet Group**: RDS subnet group spanning both private subnets

**Multi-AZ Features**:
- Automatic failover to standby instance
- Synchronous replication
- No manual intervention required
- Single DNS endpoint (automatic failover)

**Security Groups**:
- **RDS Primary Security Group** (AZ-A)
- **RDS Secondary Security Group** (AZ-B)
- **Rules**:
  - Inbound: Database port (e.g., 3306 for MySQL, 5432 for PostgreSQL) from Web Instance Security Group
  - Outbound: Not required (database doesn't initiate outbound connections)

**Database Configuration**:
- **Instance Class**: Configurable (db.t3.micro, db.t3.small, etc.)
- **Storage**: GP3 or io1 for production workloads
- **Backup**: Automated backups enabled
- **Backup Retention**: 7-30 days
- **Encryption**: Enabled at rest
- **Enhanced Monitoring**: Enabled

### 6. Security Groups

#### Web Instance Security Group
- **Purpose**: Controls traffic to web application instances
- **Inbound Rules**:
  - Port 80 (HTTP) from ALB Security Group
  - Port 443 (HTTPS) from ALB Security Group
- **Outbound Rules**:
  - All traffic to 0.0.0.0/0 (internet access via NAT Gateway)
  - Database port to RDS Security Groups

#### ALB Security Group
- **Purpose**: Controls traffic to Application Load Balancer
- **Inbound Rules**:
  - Port 80 (HTTP) from 0.0.0.0/0
  - Port 443 (HTTPS) from 0.0.0.0/0
- **Outbound Rules**:
  - Port 80 to Web Instance Security Group
  - Port 443 to Web Instance Security Group

#### RDS Security Groups
- **Purpose**: Controls traffic to database instances
- **Inbound Rules**:
  - Database port (e.g., 3306, 5432) from Web Instance Security Group
- **Outbound Rules**:
  - None required

## Traffic Flow

### Inbound Traffic (User Request)
1. User request arrives at **Internet Gateway**
2. Traffic routes to **Application Load Balancer** in public subnets
3. ALB performs health checks and selects healthy target
4. Request forwarded to **Web Instance** in private subnet (AZ-A or AZ-B)
5. Web instance processes request
6. If database access needed, web instance connects to **RDS endpoint**
7. Response returns through same path

### Outbound Traffic (Instance Updates, API Calls)
1. Web instance in private subnet initiates outbound request
2. Traffic routes to **NAT Gateway** in Public Subnet 1
3. NAT Gateway forwards traffic through **Internet Gateway**
4. Response returns through NAT Gateway to web instance

### Database Replication (Multi-AZ)
1. Write operations sent to **RDS Primary** (AZ-A)
2. Data synchronously replicated to **RDS Standby** (AZ-B)
3. Standby remains ready for automatic failover
4. Single DNS endpoint automatically points to active instance

## High Availability Design

### Availability Zone Redundancy
- All tiers deployed across two AZs
- Failure of single AZ does not impact application availability
- Auto Scaling maintains desired capacity across healthy AZs

### Database Failover
- Multi-AZ RDS provides automatic failover
- Typical failover time: 60-120 seconds
- No data loss due to synchronous replication
- Application reconnects automatically using same endpoint

### Load Balancer Health Checks
- Continuous monitoring of instance health
- Unhealthy instances removed from rotation
- Auto Scaling launches replacement instances
- Zero downtime for instance failures

## Security Considerations

### Network Isolation
- **Public/Private Subnet Separation**: Application and database tiers isolated in private subnets
- **No Direct Internet Access**: Private resources access internet only through NAT Gateway
- **Security Group Segmentation**: Each tier has dedicated security groups with minimal required access

### Encryption
- **In Transit**: Use HTTPS/TLS for ALB and application communication
- **At Rest**: Enable RDS encryption
- **Secrets**: Use AWS Secrets Manager or Parameter Store for credentials

### Access Control
- **IAM Roles**: Use instance profiles for AWS service access
- **No Hardcoded Credentials**: Use IAM roles and secrets management
- **Least Privilege**: Security groups allow only required ports/protocols

## Scalability

### Horizontal Scaling
- Auto Scaling Group automatically adds/removes instances
- Load Balancer distributes traffic across all healthy instances
- Stateless application design recommended for seamless scaling

### Database Scaling
- **Vertical Scaling**: Upgrade RDS instance class for more CPU/memory
- **Read Replicas**: Add read replicas for read-heavy workloads
- **Connection Pooling**: Use RDS Proxy for connection management at scale

## Cost Optimization Considerations

### Current Design
- Single NAT Gateway (instead of one per AZ)
- Auto Scaling matches capacity to demand

### Recommendations
- Use Reserved Instances or Savings Plans for predictable baseline
- Enable RDS storage autoscaling
- Consider Aurora Serverless for variable workloads
- Use CloudWatch metrics to right-size instances

## Disaster Recovery

### Backup Strategy
- **RDS Automated Backups**: Daily snapshots with point-in-time recovery
- **Snapshot Retention**: 7-30 days
- **Cross-Region Replication**: Consider for disaster recovery

### Recovery Objectives
- **RTO (Recovery Time Objective)**: ~2-5 minutes (automatic Multi-AZ failover)
- **RPO (Recovery Point Objective)**: ~0 seconds (synchronous replication)

## Monitoring and Logging

### CloudWatch Metrics
- ALB metrics: Request count, latency, healthy host count
- Auto Scaling metrics: CPU utilization, network traffic
- RDS metrics: CPU, IOPS, connections, replication lag

### Logging
- **VPC Flow Logs**: Network traffic analysis
- **ALB Access Logs**: Request-level logging
- **RDS Logs**: Error logs, slow query logs
- **CloudTrail**: API activity logging

## Future Enhancements

1. **Add WAF (Web Application Firewall)** to ALB for application-layer protection
2. **Deploy NAT Gateway in AZ-B** for higher availability
3. **Add Bastion Host** or **AWS Systems Manager Session Manager** for secure instance access
4. **Implement CloudFront CDN** for static content delivery
5. **Add ElastiCache** for application caching layer
6. **Configure RDS Read Replicas** for read scaling
7. **Implement AWS Backup** for centralized backup management
8. **Add Route53 Health Checks** for DNS failover
