data "aws_vpc" "selected" {
  id = var.vpc_id
}

locals {
  vpc_cidr_blocks = [data.aws_vpc.selected.cidr_block]
}

resource "aws_security_group" "server" {
  name        = "ec2-ssm-${var.workload}-servers"
  description = "Controls access for EC2 via Session Manager"
  vpc_id      = var.vpc_id

  tags = {
    Name = "sg-ssm-${var.workload}-servers"
  }
}

resource "aws_security_group_rule" "ingress_http_vpc" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = local.vpc_cidr_blocks
  security_group_id = aws_security_group.server.id
}

resource "aws_security_group_rule" "ingress_https_vpc" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = local.vpc_cidr_blocks
  security_group_id = aws_security_group.server.id
}

resource "aws_security_group_rule" "egress_http_internet" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.server.id
}

resource "aws_security_group_rule" "egress_https_internet" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.server.id
}
