# Terraform AWS Infrastructure with Kubernetes Cluster

This repository contains Terraform configurations to deploy and manage AWS infrastructure, including a Kubernetes cluster using k3s, integrated with GitHub Actions for CI/CD.

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [AWS IAM Setup](#aws-iam-setup)
- [GitHub Repository Secrets](#github-repository-secrets)
- [Terraform Configuration Files](#terraform-configuration-files)
- [CI/CD Workflow](#ci/cd-workflow)
- [Kubernetes Cluster Deployment](#kubernetes-cluster-deployment)
- [Cluster Verification](#cluster-verification)
- [Local Access Setup](#local-access-setup)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)

## Project Overview

This project uses Terraform to define and provision AWS resources including:

- S3 bucket for Terraform state management
- DynamoDB table for state locking
- VPC with public and private subnets
- Bastion host for secure cluster access
- Kubernetes cluster using k3s (1 master + 1 worker node)
- IAM roles and policies for GitHub Actions

The infrastructure as code (IaC) is managed through a GitHub Actions CI/CD pipeline, ensuring automated checks, planning, and application of changes.

## Architecture

```
Internet
    │
    ▼
┌─────────────┐
│ Bastion     │ (Public Subnet)
│ Host        │ - SSH Access
└─────────────┘
    │
    ▼
┌─────────────┐    ┌─────────────┐
│ Master      │    │ Worker      │ (Private Subnet)
│ Node        │    │ Node        │ - k3s Server
│ (k3s)       │    │ (k3s)       │ - k3s Agent
└─────────────┘    └─────────────┘
```

## Prerequisites

Before you begin, ensure you have the following:

- An AWS Account with appropriate permissions
- AWS CLI configured with appropriate permissions
- Terraform CLI installed (version >= 1.0)
- A GitHub repository to host this code
- kubectl installed locally (for local cluster access)

## AWS IAM Setup

This setup requires an IAM role and an OpenID Connect (OIDC) provider in AWS to allow GitHub Actions to assume a role and deploy resources securely.

1. **IAM Role (`GithubActionsRole`)**: This role grants GitHub Actions the necessary permissions to manage AWS resources. It includes policies for:

   - EC2, Route53, S3, IAM, VPC, SQS, and EventBridge
   - DynamoDB state locking
   - EC2 and networking resources for Kubernetes cluster

2. **IAM OIDC Provider**: Configured to trust `https://token.actions.githubusercontent.com`.

These resources are defined in `iam.tf` and are provisioned as part of the Terraform apply process.

## GitHub Repository Secrets

For the GitHub Actions workflow to authenticate with AWS, you need to add your AWS Account ID as a repository secret.

1. Go to your GitHub repository settings.
2. Navigate to `Secrets and variables` -> `Actions`.
3. Click on `New repository secret`.
4. Name the secret `AWS_ACCOUNT_ID` and paste your 12-digit AWS account ID as the value.

## Terraform Configuration Files

The Terraform configuration is organized into several files:

- `main.tf`: Defines the required Terraform version.
- `variables.tf`: Contains variable definitions for the cluster configuration.
- `providers.tf`: Configures the AWS and TLS providers.
- `backend.tf`: Configures the S3 backend for Terraform state management and DynamoDB for state locking.
- `data.tf`: Defines data sources, including current AWS caller identity and region.
- `iam.tf`: Contains the AWS IAM role and OIDC provider resources for GitHub Actions.
- `networking.tf`: Defines VPC, subnets, security groups, and routing.
- `key_pair.tf`: Generates SSH key pair for instance access.
- `instances.tf`: Defines EC2 instances for bastion, master, and worker nodes.
- `s3_dynamodb_resources.tf`: S3 bucket and DynamoDB table for Terraform state.

## CI/CD Workflow

The CI/CD pipeline is defined in `.github/workflows/terraform.yml` and consists of the following jobs:

- **`terraform-check`**: Runs `terraform fmt -check -recursive` to ensure code formatting compliance.
- **`terraform-plan`**: Initializes Terraform and generates an execution plan. This job requires the `terraform-check` to pass.
- **`terraform-apply`**: Applies the Terraform changes. This job runs only on `push` events to the `main` branch, after `terraform-plan` has succeeded, and requires manual approval if configured.

## Kubernetes Cluster Deployment

### Cluster Components

1. **Bastion Host**:

   - Located in public subnet
   - Provides SSH access to private instances
   - Has kubectl installed for cluster management
   - Acts as jump host for cluster access

2. **Master Node**:

   - Located in private subnet
   - Runs k3s server
   - Manages cluster control plane
   - Hosts Kubernetes API server

3. **Worker Node**:
   - Located in private subnet
   - Runs k3s agent
   - Executes workloads
   - Joins the cluster using master node token

### Deployment Process

1. **Infrastructure Provisioning**: Terraform creates all AWS resources
2. **Instance Bootstrapping**: User data scripts configure each instance
3. **Cluster Formation**: Master node starts k3s server, worker joins using token
4. **Configuration**: Bastion host copies kubeconfig from master

## Cluster Verification

### From Bastion Host

1. **SSH to bastion host**:

   ```bash
   ssh -i k3s-key.pem ubuntu@<bastion-public-ip>
   ```

2. **Copy kubeconfig from master**:

   ```bash
   ./copy-kubeconfig.sh
   ```

3. **Verify cluster nodes**:

   ```bash
   kubectl get nodes
   ```

   Expected output: 2 nodes (master and worker)

4. **Check all resources**:

   ```bash
   kubectl get all --all-namespaces
   ```

5. **Deploy test workload**:

   ```bash
   kubectl apply -f https://k8s.io/examples/pods/simple-pod.yaml
   ```

6. **Verify workload**:
   ```bash
   kubectl get pods
   kubectl get all --all-namespaces
   ```

## Local Access Setup

To access the cluster from your local machine:

1. **Get the private key**:

   ```bash
   terraform output -raw private_key > k3s-key.pem
   chmod 600 k3s-key.pem
   ```

2. **Get bastion IP**:

   ```bash
   terraform output bastion_public_ip
   ```

3. **Create SSH config** (optional):

   ```bash
   # Add to ~/.ssh/config
   Host k3s-bastion
     HostName <bastion-public-ip>
     User ubuntu
     IdentityFile ~/.ssh/k3s-key.pem
     StrictHostKeyChecking no
   ```

4. **Copy kubeconfig from bastion**:

   ```bash
   scp -i k3s-key.pem ubuntu@<bastion-public-ip>:/home/ubuntu/.kube/config ~/.kube/config-k3s
   ```

5. **Update kubeconfig for local access**:

   ```bash
   # Replace bastion IP with your local machine's public IP or use port forwarding
   sed -i "s/<bastion-public-ip>/localhost/g" ~/.kube/config-k3s
   ```

6. **Use the kubeconfig**:
   ```bash
   export KUBECONFIG=~/.kube/config-k3s
   kubectl get nodes
   ```

## Usage

### Initial Setup (Manual, One-time)

1. **Clone the repository**:

   ```bash
   git clone <your-repository-url>
   cd <your-repository-name>
   git checkout task_3
   ```

2. **Initialize Terraform**: This will download the necessary providers and set up the S3 backend.

   ```bash
   terraform init
   ```

3. **Apply Infrastructure**: Deploy all resources including the Kubernetes cluster.

   ```bash
   terraform apply
   ```

4. **Wait for cluster setup**: The instances will take 5-10 minutes to fully configure.

### Development Workflow (via GitHub Actions)

1. **Make changes**: Modify your Terraform `.tf` files as needed.
2. **Commit and Push**: Push your changes to a branch. A pull request will trigger the `terraform-check` and `terraform-plan` jobs.
3. **Create a Pull Request**: Opening a pull request will run the `terraform-check` and `terraform-plan` jobs, showing you the proposed infrastructure changes before merging.
4. **Merge to `main`**: Pushing or merging changes to the `main` branch will trigger the `terraform-apply` job, which will automatically apply your infrastructure changes to AWS.

### Cluster Management

1. **Access cluster via bastion**:

   ```bash
   ssh -i k3s-key.pem ubuntu@<bastion-public-ip>
   ./check-cluster.sh
   ```

2. **Deploy applications**:

   ```bash
   kubectl apply -f <your-manifest.yaml>
   ```

3. **Monitor cluster**:
   ```bash
   kubectl get nodes
   kubectl get pods --all-namespaces
   kubectl top nodes
   kubectl top pods
   ```

## Troubleshooting

### Common Issues

1. **Instances not starting**:

   - Check security groups and network configuration
   - Verify key pair exists and is properly configured
   - Check instance logs in AWS console

2. **Worker node not joining cluster**:

   - Verify master node is running: `systemctl status k3s`
   - Check node token is accessible: `cat /home/ubuntu/node-token`
   - Ensure network connectivity between nodes

3. **kubectl not working**:

   - Verify kubeconfig is copied correctly
   - Check file permissions: `chmod 600 ~/.kube/config`
   - Ensure API server is accessible

4. **Pods not scheduling**:
   - Check node resources: `kubectl describe nodes`
   - Verify taints and tolerations
   - Check pod events: `kubectl describe pod <pod-name>`

### Useful Commands

```bash
# Check k3s status on master
systemctl status k3s

# Check k3s agent status on worker
systemctl status k3s-agent

# View k3s logs
journalctl -u k3s -f

# Check cluster info
kubectl cluster-info

# Get detailed node information
kubectl describe nodes

# Check pod events
kubectl get events --sort-by='.lastTimestamp'
```

### Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

**Warning**: This will delete all resources including the Kubernetes cluster and all data.

## Security Considerations

1. **SSH Access**: The bastion host is configured to accept SSH from anywhere (0.0.0.0/0). In production, restrict this to specific IP ranges.
2. **Key Management**: SSH private keys are stored in Terraform state. Consider using AWS Systems Manager Parameter Store for production.
3. **Network Security**: Worker nodes are in private subnets and only accessible via bastion host.
4. **IAM Permissions**: The GitHub Actions role has broad permissions. Consider implementing least privilege access.

## Cost Optimization

1. **Instance Types**: Using t3.micro instances (free tier eligible) for development.
2. **Storage**: Using gp3 volumes for better performance/cost ratio.
3. **Monitoring**: Consider using AWS CloudWatch for monitoring and alerting.
4. **Auto-scaling**: For production, consider implementing auto-scaling groups.

## Next Steps

1. **Production Hardening**:

   - Implement proper secrets management
   - Add monitoring and logging
   - Configure backup strategies
   - Implement auto-scaling

2. **Application Deployment**:

   - Deploy your applications to the cluster
   - Set up CI/CD pipelines for applications
   - Configure ingress controllers
   - Implement service mesh if needed

3. **Security Enhancements**:
   - Implement network policies
   - Add pod security policies
   - Configure RBAC
   - Enable audit logging
