variable "region" {
  type    = string
  default = "us-east-2"
}

variable "workload" {
  type    = string
  default = "corpx"
}

variable "ip_to_drop" {
  type    = string
  default = "1.2.3.4/32"
}
