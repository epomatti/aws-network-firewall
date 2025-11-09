output "vpc_id" {
  value = aws_vpc.main.id
}

output "firewall_arn" {
  value = aws_networkfirewall_firewall.main.arn
}
