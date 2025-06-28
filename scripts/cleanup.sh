#!/bin/bash
set -e

echo "🧹 Starting Infrastructure Cleanup"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Confirm cleanup
print_warning "This will destroy ALL infrastructure including:"
echo "• VPC and networking resources"
echo "• EC2 instances (bastion, master, worker)"
echo "• Security groups"
echo "• SSH key pair"
echo "• Kubernetes cluster and all data"
echo ""

read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    print_status "Cleanup cancelled"
    exit 0
fi

# Step 1: Destroy Terraform infrastructure
print_status "Step 1: Destroying Terraform infrastructure..."
terraform destroy -auto-approve

# Step 2: Clean up local files
print_status "Step 2: Cleaning up local files..."

# Remove SSH key if it exists
if [ -f "k3s-key.pem" ]; then
    rm k3s-key.pem
    print_status "Removed k3s-key.pem"
fi

# Remove local kubeconfig if it exists
if [ -f "~/.kube/config-k3s" ]; then
    rm ~/.kube/config-k3s
    print_status "Removed local kubeconfig"
fi

# Remove verification scripts
if [ -f "verify-local.sh" ]; then
    rm verify-local.sh
    print_status "Removed verify-local.sh"
fi

if [ -f "verify-cluster.sh" ]; then
    rm verify-cluster.sh
    print_status "Removed verify-cluster.sh"
fi

# Remove terraform plan file
if [ -f "tfplan" ]; then
    rm tfplan
    print_status "Removed tfplan"
fi

print_status "Cleanup completed successfully!"
echo ""
echo "✅ All infrastructure and local files have been cleaned up." 