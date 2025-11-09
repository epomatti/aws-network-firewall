terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

module "cloudwatch" {
  source = "./modules/cloudwatch"
}

module "firewall_policies" {
  source     = "./modules/firewall/policies"
  workload   = var.workload
  ip_to_drop = var.ip_to_drop
}

module "network" {
  source              = "./modules/network"
  workload            = var.workload
  aws_region          = var.aws_region
  firewall_policy_arn = module.firewall_policies.firewall_policy_arn
}

module "firewall_logging" {
  source                    = "./modules/firewall/logging"
  firewall_arn              = module.network.firewall_arn
  cloudwatch_log_group_name = module.cloudwatch.firewll_cloudwatch_log_group_name
}

# module "server" {
#   source   = "./modules/server"
#   workload = var.workload
#   vpc_id   = module.network.vpc_id
#   subnet   = module.network.public_subnets[0]
#   az       = local.az1
# }


# module "nat-gateway" {
#   source   = "./modules/nat-gateway"
#   workload = var.workload
#   subnet   = module.network.public_subnets[0]
# }

# module "lb" {
#   source   = "./modules/lb"
#   workload = var.workload
#   vpc_id   = module.network.vpc_id
#   subnets  = module.network.public_subnets
#   azs      = [local.az1, local.az2]
# }
