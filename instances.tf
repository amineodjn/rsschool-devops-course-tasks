# Use Ubuntu 22.04 AMI for eu-central-1 region
locals {
  ubuntu_ami_id = "ami-0669b163befffbdfc" # Ubuntu 22.04 LTS in eu-central-1
}

# Bastion Host
resource "aws_instance" "bastion" {
  ami                    = local.ubuntu_ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.bastion.id]

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  user_data = base64encode(templatefile("${path.module}/templates/bastion-setup.sh", {
    cluster_name = var.cluster_name
  }))

  tags = {
    Name = "${var.cluster_name}-bastion"
  }
}

# Kubernetes Master Node
resource "aws_instance" "k8s_master" {
  ami                    = local.ubuntu_ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.k8s_nodes.id]

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  user_data = base64encode(templatefile("${path.module}/templates/k3s-master-setup.sh", {
    cluster_name = var.cluster_name
  }))

  tags = {
    Name = "${var.cluster_name}-master"
    Role = "master"
  }
}

# Kubernetes Worker Node
resource "aws_instance" "k8s_worker" {
  ami                    = local.ubuntu_ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.k8s_nodes.id]

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  user_data = base64encode(templatefile("${path.module}/templates/k3s-worker-setup.sh", {
    cluster_name = var.cluster_name
    master_ip    = aws_instance.k8s_master.private_ip
  }))

  tags = {
    Name = "${var.cluster_name}-worker"
    Role = "worker"
  }

  depends_on = [aws_instance.k8s_master]
}

# Outputs
output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "master_private_ip" {
  description = "Private IP of the master node"
  value       = aws_instance.k8s_master.private_ip
}

output "worker_private_ip" {
  description = "Private IP of the worker node"
  value       = aws_instance.k8s_worker.private_ip
}

output "ssh_bastion_command" {
  description = "SSH command to connect to bastion host"
  value       = "ssh -i k3s-key.pem ubuntu@${aws_instance.bastion.public_ip}"
}

output "ssh_master_command" {
  description = "SSH command to connect to master node via bastion"
  value       = "ssh -i k3s-key.pem -J ubuntu@${aws_instance.bastion.public_ip} ubuntu@${aws_instance.k8s_master.private_ip}"
} 