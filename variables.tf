# Project
variable "aws_region" {
  type = string
}

variable "workload" {
  type = string
}

# Firewall
variable "ip_to_drop" {
  type = string
}

# Servers
variable "server_ami" {
  type = string
}

variable "server_instance_type" {
  type = string
}
