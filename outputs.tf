output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "bastion_private_key_pem" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}

output "private_vm_private_ips" {
  value = [aws_instance.k8s_master.private_ip, aws_instance.k8s_worker.private_ip]
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