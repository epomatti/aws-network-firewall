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
  az2 = "${var.region}b"
}

module "network" {
  source   = "./modules/network"
  region   = var.region
  workload = var.workload
  az1      = local.az1
  az2      = local.az2
}

module "nat-gateway" {
  source   = "./modules/nat-gateway"
  workload = var.workload
  subnet   = module.network.public_subnets[0]
}

module "lb" {
  source   = "./modules/lb"
  workload = var.workload
  vpc_id   = module.network.vpc_id
  subnets  = module.network.public_subnets
  azs      = [local.az1, local.az2]
}
