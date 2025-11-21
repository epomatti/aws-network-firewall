resource "aws_iam_instance_profile" "server" {
  name = "server-${var.workload}"
  role = var.server_iam_role_arn
}
