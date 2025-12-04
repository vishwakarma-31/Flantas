# High Availability + Auto Scaling

## HA Architecture & Traffic Flow 

I upgraded the single-instance design to a highly available architecture using an internet-facing Application Load Balancer (ALB) and an Auto Scaling Group (ASG). The ALB is deployed in two public subnets and listens on HTTP port 80. It forwards traffic to a target group containing EC2 instances running Nginx in two private subnets across different Availability Zones. The EC2 instances are launched and managed by an ASG using a launch template that installs Nginx and deploys my static resume page via user data. Outbound traffic from private instances goes through the existing NAT Gateway created in the VPC, while inbound traffic reaches only the ALB, which then routes it to healthy backend instances.

## Components

- **ALB**: Internet-facing, in public subnets, listening on port 80.
- **Target Group**: HTTP target group with health checks on `/`.
- **ASG**: Spans both private subnets, desired capacity 2 for HA.
- **EC2 Instances**: Ubuntu + Nginx servers, created from a launch template.
- **Security Groups**: ALB allows HTTP from the internet; app instances only allow HTTP from ALB SG.

## Traffic Flow

User Browser → ALB DNS (public) → ALB in public subnets → Target Group → EC2 instances in private subnets (Nginx) → Resume HTML response.

## Files

- `main.tf` – Terraform code for ALB, Target Group, Launch Template, and ASG.
- `user_data.sh` – Bootstraps EC2 instances (Nginx install + static resume).
- `images/` – Screenshots of ALB, Target Group, ASG, and EC2 instances.


## Screenshots

![Auto Scaling](./assests/Auto%20Scaling.png)
![Load Balancer](./assests/Load%20Balancer.png)
![Target Group](./assests/Target%20Group.png)
![Website](./assests/Website.png)
