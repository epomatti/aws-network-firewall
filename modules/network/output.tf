output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_firewall_id" {
  value = aws_subnet.firewall.id
}

output "public_subnets" {
  value = [aws_subnet.public1.id, aws_subnet.public2.id]
}

output "subnet_private_id" {
  value = aws_subnet.private.id
}
