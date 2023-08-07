### Locals
locals {
  cidr_block_vpc = "10.0.0.0/16"

  cidr_block_subnet_fw1   = "10.0.10.0/24"
  cidr_block_subnet_pub1  = "10.0.40.0/24"
  cidr_block_subnet_priv1 = "10.0.90.0/24"
}

### VPC ###
resource "aws_vpc" "main" {
  cidr_block           = local.cidr_block_vpc
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-${var.workload}"
  }
}

# Remove all routes just to clean it up
resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.main.default_route_table_id
  route                  = []
}

### CloudWatch Logs ###
resource "aws_cloudwatch_log_group" "alert" {
  name = "firewall/alert"
}

resource "aws_cloudwatch_log_group" "flow" {
  name = "firewall/flow"
}

### Network Firewall ###

resource "aws_networkfirewall_logging_configuration" "main" {
  firewall_arn = aws_networkfirewall_firewall.main.arn
  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.alert.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.flow.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }
  }
}

resource "aws_networkfirewall_firewall" "main" {
  name                = "firewall-${var.workload}"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.main.arn
  vpc_id              = aws_vpc.main.id

  # For development purposes only
  delete_protection        = false
  subnet_change_protection = false

  subnet_mapping {
    subnet_id = aws_subnet.fw1.id
  }
}

resource "aws_networkfirewall_firewall_policy" "main" {
  name = "policy-${var.workload}"

  firewall_policy {
    stateless_default_actions          = ["aws:pass"]
    stateless_fragment_default_actions = ["aws:drop"]

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.httpbin_deny.arn
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.ip_drop.arn
    }
  }
}

resource "aws_networkfirewall_rule_group" "httpbin_deny" {
  capacity = 100
  name     = "httpbin-deny"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "DENYLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = ["httpbin.org"]
      }
    }
  }
}

resource "aws_networkfirewall_rule_group" "ip_drop" {
  capacity = 100
  name     = "drop-by-ip"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      stateful_rule {
        action = "DROP"
        header {
          destination      = "0.0.0.0/0"
          destination_port = "ANY"
          direction        = "ANY"
          protocol         = "TCP"
          source           = var.ip_to_drop
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["1"]
        }
      }
    }
  }
}

### Routes ###
locals {
  fw_vpce = tolist(aws_networkfirewall_firewall.main.firewall_status[0].sync_states)[0].attachment[0].endpoint_id
}

### Internet Gateway ###
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ig-${var.workload}"
  }
}

resource "aws_route_table" "igw" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block      = local.cidr_block_subnet_pub1
    vpc_endpoint_id = local.fw_vpce
  }

  tags = {
    Name = "rt-${var.workload}-igw"
  }
}


### Firewall Subnet ###
resource "aws_route_table" "firewall" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "rt-${var.workload}-firewall"
  }
}

resource "aws_subnet" "fw1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.cidr_block_subnet_fw1
  availability_zone = var.az1

  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-${var.workload}-fw1"
  }
}

### Public Subnet ###
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block      = "0.0.0.0/0"
    vpc_endpoint_id = local.fw_vpce
  }

  tags = {
    Name = "rt-${var.workload}-public"
  }
}

resource "aws_subnet" "public1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.cidr_block_subnet_pub1
  availability_zone = var.az1

  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-${var.workload}-pub1"
  }
}

# resource "aws_subnet" "public2" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = "10.0.11.0/24"
#   availability_zone = var.az2

#   map_public_ip_on_launch = true

#   tags = {
#     Name = "subnet-${var.workload}-pub2"
#   }
# }

### Private Subnet ###

# resource "aws_route_table" "private" {
#   vpc_id = aws_vpc.main.id
#   tags = {
#     Name = "rt-${var.workload}-priv"
#   }
# }

# resource "aws_subnet" "private" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = "10.0.100.0/24"
#   availability_zone = var.az1

#   tags = {
#     Name = "subnet-${var.workload}-priv"
#   }
# }

resource "aws_route_table_association" "gateway" {
  gateway_id     = aws_internet_gateway.main.id
  route_table_id = aws_route_table.igw.id
}

resource "aws_route_table_association" "firewall" {
  subnet_id      = aws_subnet.fw1.id
  route_table_id = aws_route_table.firewall.id
}


resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

# resource "aws_route_table_association" "public2" {
#   subnet_id      = aws_subnet.public2.id
#   route_table_id = aws_route_table.public.id
# }

# resource "aws_route_table_association" "private" {
#   subnet_id      = aws_subnet.private.id
#   route_table_id = aws_route_table.private.id
# }
