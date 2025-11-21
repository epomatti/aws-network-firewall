resource "aws_instance" "server" {
  ami           = var.ami
  instance_type = var.instance_type

  associate_public_ip_address = false
  subnet_id                   = var.subnet
  vpc_security_group_ids      = [aws_security_group.server.id]

  availability_zone    = var.az
  iam_instance_profile = var.insta
  user_data            = file("${path.module}/user_data/ubuntu.sh")

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring    = false
  ebs_optimized = false

  root_block_device {
    encrypted = true
  }

  lifecycle {
    ignore_changes = [
      ami,
      associate_public_ip_address
    ]
  }

  tags = {
    Name = "server-${var.workload}"
  }
}
