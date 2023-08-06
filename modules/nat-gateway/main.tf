resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.subnet

  tags = {
    Name = "nat-gw-${var.workload}"
  }
}
