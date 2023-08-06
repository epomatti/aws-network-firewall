resource "aws_networkfirewall_firewall" "main" {
  name                = "firewall-${var.workload}"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.main.arn
  vpc_id              = var.vpc_id

  # For development purposes only
  delete_protection        = false
  subnet_change_protection = false

  subnet_mapping {
    subnet_id = var.subnet
  }
}

resource "aws_networkfirewall_firewall_policy" "main" {
  name = "default-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:pass"]
    stateless_fragment_default_actions = ["aws:drop"]
    # stateless_rule_group_reference {
    #   priority     = 1
    #   resource_arn = aws_networkfirewall_rule_group.example.arn
    # }
  }
}

# resource "aws_networkfirewall_rule_group" "example" {
#   capacity = 100
#   name     = "example"
#   type     = "STATEFUL"
#   rule_group {
#     rules_source {
#       rules_source_list {
#         generated_rules_type = "DENYLIST"
#         target_types         = ["HTTP_HOST"]
#         targets              = ["test.example.com"]
#       }
#     }
#   }

#   tags = {
#     Tag1 = "Value1"
#     Tag2 = "Value2"
#   }
# }
