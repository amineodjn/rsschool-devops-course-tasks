#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install additional tools
apt-get install -y jq curl wget

# Create directory for kubeconfig
mkdir -p /home/ubuntu/.kube

# Set proper permissions
chown -R ubuntu:ubuntu /home/ubuntu/.kube

# Create a script to copy kubeconfig from master
cat > /home/ubuntu/copy-kubeconfig.sh << 'EOF'
#!/bin/bash
# This script will be used to copy kubeconfig from master node
echo "Waiting for master node to be ready..."
sleep 30

# Copy kubeconfig from master node
scp -o StrictHostKeyChecking=no ubuntu@${cluster_name}-master:/etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
sed -i "s/127.0.0.1/${cluster_name}-master/g" /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config
chmod 600 /home/ubuntu/.kube/config

echo "Kubeconfig copied and configured successfully!"
EOF

chmod +x /home/ubuntu/copy-kubeconfig.sh
chown ubuntu:ubuntu /home/ubuntu/copy-kubeconfig.sh

# Create a script to check cluster status
cat > /home/ubuntu/check-cluster.sh << 'EOF'
#!/bin/bash
echo "=== Cluster Nodes ==="
kubectl get nodes

echo -e "\n=== All Resources ==="
kubectl get all --all-namespaces

echo -e "\n=== Cluster Info ==="
kubectl cluster-info
EOF

chmod +x /home/ubuntu/check-cluster.sh
chown ubuntu:ubuntu /home/ubuntu/check-cluster.sh

echo "Bastion host setup completed!" 