output "vpc_id" {
  value = aws_vpc.main.id
}

output "firewall_subnet" {
  value = aws_subnet.firewall.id
}

output "public_subnets" {
  value = [aws_subnet.public1.id]
}

output "subnet_private_id" {
  value = aws_subnet.private.id
}
