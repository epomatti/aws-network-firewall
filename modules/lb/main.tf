### IAM Role ###
resource "aws_iam_role" "main" {
  name = "FirewallRole-${var.workload}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm-managed-instance-core" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

### EC2 ###
resource "aws_iam_instance_profile" "main" {
  name = "profile-${var.workload}"
  role = aws_iam_role.main.id
}

### Security Group ###
resource "aws_security_group" "server" {
  name   = "ec2-${var.workload}-server"
  vpc_id = var.vpc_id

  tags = {
    Name = "sg-ssm-${var.workload}-server"
  }
}

resource "aws_security_group_rule" "ingress_server" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = []
  security_group_id = aws_security_group.server.id
}

resource "aws_security_group_rule" "egress_server" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = []
  security_group_id = aws_security_group.server.id
}

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

### ALB ###
resource "aws_security_group" "allow_http_lb" {
  name        = "Allow HTTP"
  description = "Allow HTTP inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lb-sc"
  }
}

resource "aws_lb_target_group" "main" {
  name     = "tg-${var.workload}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled = true
    path    = "/"
  }
}

resource "aws_autoscaling_group" "default" {
  name = "asg-${var.workload}"

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
  
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = var.subnets
  target_group_arns   = [aws_lb_target_group.main.arn]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "main" {
  name               = "lb-${var.workload}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_http_lb.id]
  subnets            = var.subnets
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
