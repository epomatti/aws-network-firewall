### Locals ###
locals {
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]

  cidr_block_prefix = "10.0"
  cidr_block        = "${local.cidr_block_prefix}.0.0/16"

  cidr_firewall_subnets = [
    "${local.cidr_block_prefix}.3.0/28",
    "${local.cidr_block_prefix}.3.16/28",
    "${local.cidr_block_prefix}.3.32/28",
  ]

  cidr_protected_subnets = [
    "${local.cidr_block_prefix}.0.0/24",
    "${local.cidr_block_prefix}.1.0/24",
    "${local.cidr_block_prefix}.2.0/24",
  ]

  cidr_private_subnets = [
    "${local.cidr_block_prefix}.10.0/24",
    "${local.cidr_block_prefix}.11.0/24",
    "${local.cidr_block_prefix}.12.0/24",
  ]
}

### VPC ###
resource "aws_vpc" "main" {
  cidr_block           = local.cidr_block
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-${var.workload}"
  }
}

### Internet Gateway ###
resource "aws_internet_gateway" "main" {
  tags = {
    Name = "ig-${var.workload}"
  }
}

resource "aws_internet_gateway_attachment" "main" {
  internet_gateway_id = aws_internet_gateway.main.id
  vpc_id              = aws_vpc.main.id
}

### Firewall Subnets ###
resource "aws_subnet" "fw1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.cidr_firewall_subnets[0]
  availability_zone       = local.availability_zones[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet-${var.workload}-fw1"
  }
}

resource "aws_subnet" "fw2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.cidr_firewall_subnets[1]
  availability_zone       = local.availability_zones[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet-${var.workload}-fw2"
  }
}

resource "aws_subnet" "fw3" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.cidr_firewall_subnets[2]
  availability_zone       = local.availability_zones[2]
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet-${var.workload}-fw3"
  }
}

resource "aws_route_table" "firewall" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rt-${var.workload}-firewall"
  }
}

resource "aws_route" "firewall" {
  route_table_id         = aws_route_table.firewall.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "fw1" {
  subnet_id      = aws_subnet.fw1.id
  route_table_id = aws_route_table.firewall.id
}

resource "aws_route_table_association" "fw2" {
  subnet_id      = aws_subnet.fw2.id
  route_table_id = aws_route_table.firewall.id
}

resource "aws_route_table_association" "fw3" {
  subnet_id      = aws_subnet.fw3.id
  route_table_id = aws_route_table.firewall.id
}

### Network Firewall ###
resource "aws_networkfirewall_firewall" "main" {
  name                = "${var.workload}-firewall"
  firewall_policy_arn = var.firewall_policy_arn
  vpc_id              = aws_vpc.main.id

  # For development purposes only
  delete_protection        = false
  subnet_change_protection = false

  subnet_mapping {
    subnet_id = aws_subnet.fw1.id
  }

  subnet_mapping {
    subnet_id = aws_subnet.fw2.id
  }

  subnet_mapping {
    subnet_id = aws_subnet.fw3.id
  }
}

locals {
  firewall_subnets = tolist(aws_networkfirewall_firewall.main.firewall_status[0].sync_states)
  fw_vpce1         = local.firewall_subnets[0].attachment[0].endpoint_id
  fw_vpce2         = local.firewall_subnets[1].attachment[0].endpoint_id
  fw_vpce3         = local.firewall_subnets[2].attachment[0].endpoint_id
}

### Protected Subnets ###
resource "aws_subnet" "prot1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.cidr_protected_subnets[0]
  availability_zone       = local.availability_zones[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet-${var.workload}-prot1"
  }
}

resource "aws_subnet" "prot2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.cidr_protected_subnets[1]
  availability_zone       = local.availability_zones[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet-${var.workload}-prot2"
  }
}

resource "aws_subnet" "prot3" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.cidr_protected_subnets[2]
  availability_zone       = local.availability_zones[2]
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet-${var.workload}-prot3"
  }
}

resource "aws_route_table" "prot1" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rt-${var.workload}-prot1"
  }
}

resource "aws_route_table" "prot2" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rt-${var.workload}-prot2"
  }
}

resource "aws_route_table" "prot3" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rt-${var.workload}-prot3"
  }
}

resource "aws_route" "protected_fw1" {
  route_table_id         = aws_route_table.prot1.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = local.fw_vpce1
}

resource "aws_route" "protected_fw2" {
  route_table_id         = aws_route_table.prot2.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = local.fw_vpce2
}

resource "aws_route" "protected_fw3" {
  route_table_id         = aws_route_table.prot3.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = local.fw_vpce3
}

resource "aws_route_table_association" "prot1" {
  subnet_id      = aws_subnet.prot1.id
  route_table_id = aws_route_table.prot1.id
}

resource "aws_route_table_association" "prot2" {
  subnet_id      = aws_subnet.prot2.id
  route_table_id = aws_route_table.prot2.id
}

resource "aws_route_table_association" "prot3" {
  subnet_id      = aws_subnet.prot3.id
  route_table_id = aws_route_table.prot3.id
}

### NAT Gateways ###
resource "aws_eip" "nat1" {
  domain = "vpc"
}
resource "aws_eip" "nat2" {
  domain = "vpc"
}
resource "aws_eip" "nat3" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat1" {
  allocation_id = aws_eip.nat1.id
  subnet_id     = aws_subnet.prot1.id

  tags = {
    Name = "nat-${var.workload}-1"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "nat2" {
  allocation_id = aws_eip.nat2.id
  subnet_id     = aws_subnet.prot2.id

  tags = {
    Name = "nat-${var.workload}-2"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "nat3" {
  allocation_id = aws_eip.nat3.id
  subnet_id     = aws_subnet.prot3.id

  tags = {
    Name = "nat-${var.workload}-3"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway_eip_association" "nat1" {
  allocation_id  = aws_eip.nat1.id
  nat_gateway_id = aws_nat_gateway.nat1.id
}

resource "aws_nat_gateway_eip_association" "nat2" {
  allocation_id  = aws_eip.nat2.id
  nat_gateway_id = aws_nat_gateway.nat2.id
}

resource "aws_nat_gateway_eip_association" "nat3" {
  allocation_id  = aws_eip.nat3.id
  nat_gateway_id = aws_nat_gateway.nat3.id
}

### Private Subnets ###
resource "aws_subnet" "priv1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.cidr_private_subnets[0]
  availability_zone       = local.availability_zones[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet-${var.workload}-priv1"
  }
}

resource "aws_subnet" "priv2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.cidr_private_subnets[1]
  availability_zone       = local.availability_zones[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet-${var.workload}-priv2"
  }
}

resource "aws_subnet" "priv3" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.cidr_private_subnets[2]
  availability_zone       = local.availability_zones[2]
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet-${var.workload}-priv3"
  }
}

resource "aws_route_table" "priv1" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rt-${var.workload}-priv1"
  }
}

resource "aws_route_table" "priv2" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rt-${var.workload}-priv2"
  }
}

resource "aws_route_table" "priv3" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "rt-${var.workload}-priv3"
  }
}

resource "aws_route" "private_nat_1" {
  route_table_id         = aws_route_table.priv1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat1.id
}

resource "aws_route" "private_nat_2" {
  route_table_id         = aws_route_table.priv2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat2.id
}

resource "aws_route" "private_nat_3" {
  route_table_id         = aws_route_table.priv3.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat3.id
}

resource "aws_route_table_association" "priv_nat_1" {
  subnet_id      = aws_subnet.priv1.id
  route_table_id = aws_route_table.priv1.id
}

resource "aws_route_table_association" "priv_nat_2" {
  subnet_id      = aws_subnet.priv2.id
  route_table_id = aws_route_table.priv2.id
}

resource "aws_route_table_association" "priv_nat_3" {
  subnet_id      = aws_subnet.priv3.id
  route_table_id = aws_route_table.priv3.id
}

### Clear all entries ###
resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.main.default_route_table_id
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id
}
