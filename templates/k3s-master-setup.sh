#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y curl wget

# Install k3s server
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--flannel-iface=eth0" sh -

# Wait for k3s to be ready
echo "Waiting for k3s to be ready..."
sleep 30

# Get the node token for worker nodes
NODE_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)

# Create a file with the token for worker nodes
echo $NODE_TOKEN > /home/ubuntu/node-token
chown ubuntu:ubuntu /home/ubuntu/node-token

# Copy kubeconfig to a location accessible by bastion
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/k3s.yaml
chown ubuntu:ubuntu /home/ubuntu/k3s.yaml

# Create a script to check cluster status
cat > /home/ubuntu/check-master.sh << 'EOF'
#!/bin/bash
echo "=== K3s Status ==="
systemctl status k3s

echo -e "\n=== Cluster Nodes ==="
kubectl get nodes

echo -e "\n=== All Resources ==="
kubectl get all --all-namespaces
EOF

chmod +x /home/ubuntu/check-master.sh
chown ubuntu:ubuntu /home/ubuntu/check-master.sh

echo "K3s master setup completed!" 