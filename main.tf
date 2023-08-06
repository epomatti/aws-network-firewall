terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  az1 = "${var.region}a"
}

module "network" {
  source   = "./modules/network"
  region   = var.region
  workload = var.workload
  az       = local.az1
}

module "nat-gateway" {
  source   = "./modules/nat-gateway"
  workload = var.workload
  subnet   = module.network.subnet_public_id
}
