# Generate SSH key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# AWS Key Pair
resource "aws_key_pair" "main" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.ssh_key.public_key_openssh

  tags = {
    Name = "${var.cluster_name}-key-pair"
  }
}

# Output the private key (for local access)
output "private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}

output "public_key" {
  value = tls_private_key.ssh_key.public_key_openssh
} 