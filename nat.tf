# NAT Instance and related resources

data "aws_network_interface" "nat_primary" {
  id = aws_instance.nat.primary_network_interface_id
}

resource "aws_instance" "nat" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public[0].id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.bastion_key.key_name
  vpc_security_group_ids      = [aws_security_group.nat_sg.id]
  source_dest_check           = false

  user_data = <<-EOF
    #!/bin/bash
    echo 1 > /proc/sys/net/ipv4/ip_forward
    sysctl -w net.ipv4.ip_forward=1
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    # Make persistent
    echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
    yum install -y iptables-services
    service iptables save
    systemctl enable iptables
    systemctl start iptables
  EOF

  tags = {
    Name = "nat-instance"
  }
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = data.aws_network_interface.nat_primary.id
} 