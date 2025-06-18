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
  value     = tls_private_key.bastion_key.private_key_pem
  sensitive = true
}

output "private_vm_private_ips" {
  value = aws_instance.private_vm[*].private_ip
} 