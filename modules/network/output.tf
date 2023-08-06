output "vpc_id" {
  value = aws_vpc.main.id
}

output "firewall_subnet" {
  value = aws_subnet.fw1.id
}

output "public_subnets" {
  value = [aws_subnet.public1.id]
}

# output "subnet_private_id" {
#   value = aws_subnet.private.id
# }

output "firewall_ouptut" {
  value = aws_networkfirewall_firewall.main.firewall_status
}
