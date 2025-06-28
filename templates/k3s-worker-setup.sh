#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y curl wget

# Wait for master to be ready and get the token
echo "Waiting for master node to be ready..."
sleep 60

# Get the node token from master
NODE_TOKEN=$(ssh -o StrictHostKeyChecking=no ubuntu@${master_ip} "cat /home/ubuntu/node-token")

# Install k3s agent
curl -sfL https://get.k3s.io | K3S_URL=https://${master_ip}:6443 K3S_TOKEN=$NODE_TOKEN INSTALL_K3S_EXEC="--flannel-iface=eth0" sh -

# Create a script to check worker status
cat > /home/ubuntu/check-worker.sh << 'EOF'
#!/bin/bash
echo "=== K3s Agent Status ==="
systemctl status k3s-agent

echo -e "\n=== Node Info ==="
kubectl get nodes
EOF

chmod +x /home/ubuntu/check-worker.sh
chown ubuntu:ubuntu /home/ubuntu/check-worker.sh

echo "K3s worker setup completed!" 