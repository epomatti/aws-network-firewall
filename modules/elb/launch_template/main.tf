### Launch Template ###
resource "aws_launch_template" "main" {
  name = "template-server-${var.workload}"

  image_id      = "ami-08fdd91d87f63bb09"
  instance_type = "t4g.nano"
  # vpc_security_group_ids = [aws_security_group.server.id]
  user_data = filebase64("${path.module}/userdata.sh")

  iam_instance_profile {
    arn = aws_iam_instance_profile.main.arn
  }

  metadata_options {
    http_endpoint          = "enabled"
    http_tokens            = "required"
    instance_metadata_tags = "enabled"
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.server.id]
  }
}
