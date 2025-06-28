#!/bin/bash
set -e

echo "🚀 Starting Kubernetes Cluster Deployment and Verification"
echo "=========================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "main.tf" ]; then
    print_error "Please run this script from the root directory of the Terraform project"
    exit 1
fi

# Step 1: Initialize Terraform
print_status "Step 1: Initializing Terraform..."
terraform init

# Step 2: Plan the deployment
print_status "Step 2: Planning Terraform deployment..."
terraform plan -out=tfplan

# Step 3: Apply the deployment
print_status "Step 3: Applying Terraform configuration..."
terraform apply tfplan

# Step 4: Get outputs
print_status "Step 4: Getting deployment outputs..."
BASTION_IP=$(terraform output -raw bastion_public_ip)
MASTER_IP=$(terraform output -raw master_private_ip)
WORKER_IP=$(terraform output -raw worker_private_ip)

print_status "Bastion Host IP: $BASTION_IP"
print_status "Master Node IP: $MASTER_IP"
print_status "Worker Node IP: $WORKER_IP"

# Step 5: Save private key
print_status "Step 5: Saving SSH private key..."
terraform output -raw private_key > k3s-key.pem
chmod 600 k3s-key.pem
print_status "SSH key saved as k3s-key.pem"

# Step 6: Wait for instances to be ready
print_status "Step 6: Waiting for instances to be ready (5 minutes)..."
sleep 300

# Step 7: Verify cluster from bastion
print_status "Step 7: Verifying cluster from bastion host..."

# Create a temporary script to run on bastion
cat > verify-cluster.sh << EOF
#!/bin/bash
set -e

echo "Connecting to bastion host and verifying cluster..."

# Copy kubeconfig from master
echo "Copying kubeconfig from master node..."
scp -o StrictHostKeyChecking=no ubuntu@$MASTER_IP:/home/ubuntu/k3s.yaml /home/ubuntu/.kube/config
sed -i "s/127.0.0.1/$MASTER_IP/g" /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config
chmod 600 /home/ubuntu/.kube/config

# Wait a bit for cluster to be fully ready
sleep 30

# Check cluster nodes
echo "=== Cluster Nodes ==="
kubectl get nodes

# Check all resources
echo -e "\n=== All Resources ==="
kubectl get all --all-namespaces

# Deploy test workload
echo -e "\n=== Deploying Test Workload ==="
kubectl apply -f https://k8s.io/examples/pods/simple-pod.yaml

# Wait for pod to be ready
echo "Waiting for pod to be ready..."
sleep 30

# Check pods
echo -e "\n=== Pods ==="
kubectl get pods

# Check all resources again
echo -e "\n=== All Resources (After Test Deployment) ==="
kubectl get all --all-namespaces

echo "Cluster verification completed!"
EOF

# Copy verification script to bastion
scp -i k3s-key.pem -o StrictHostKeyChecking=no verify-cluster.sh ubuntu@$BASTION_IP:/home/ubuntu/
ssh -i k3s-key.pem -o StrictHostKeyChecking=no ubuntu@$BASTION_IP "chmod +x /home/ubuntu/verify-cluster.sh && /home/ubuntu/verify-cluster.sh"

# Step 8: Setup local access
print_status "Step 8: Setting up local access..."

# Copy kubeconfig from bastion
scp -i k3s-key.pem -o StrictHostKeyChecking=no ubuntu@$BASTION_IP:/home/ubuntu/.kube/config ~/.kube/config-k3s

# Create local verification script
cat > verify-local.sh << EOF
#!/bin/bash
echo "=== Local Cluster Verification ==="
export KUBECONFIG=~/.kube/config-k3s

echo "Cluster nodes:"
kubectl get nodes

echo -e "\nAll resources:"
kubectl get all --all-namespaces

echo -e "\nCluster info:"
kubectl cluster-info
EOF

chmod +x verify-local.sh

print_status "Local verification script created: verify-local.sh"
print_warning "To use local access, run: export KUBECONFIG=~/.kube/config-k3s"

# Step 9: Final status
print_status "Step 9: Deployment completed!"
echo ""
echo "📋 Summary:"
echo "==========="
echo "• Bastion Host: ubuntu@$BASTION_IP"
echo "• SSH Key: k3s-key.pem"
echo "• Local kubeconfig: ~/.kube/config-k3s"
echo "• Verification script: verify-local.sh"
echo ""
echo "🔗 Useful Commands:"
echo "=================="
echo "• SSH to bastion: ssh -i k3s-key.pem ubuntu@$BASTION_IP"
echo "• Local cluster access: export KUBECONFIG=~/.kube/config-k3s && kubectl get nodes"
echo "• Run local verification: ./verify-local.sh"
echo ""
echo "✅ Kubernetes cluster deployment and verification completed successfully!" 