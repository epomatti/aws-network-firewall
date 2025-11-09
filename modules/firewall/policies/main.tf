resource "aws_networkfirewall_firewall_policy" "main" {
  name = "policy-${var.workload}"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:drop"]

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.httpbin_deny.arn
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.ip_drop.arn
    }
  }
}

resource "aws_networkfirewall_rule_group" "httpbin_deny" {
  capacity = 100
  name     = "httpbin-deny"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "DENYLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = ["httpbin.org"]
      }
    }
  }
}

resource "aws_networkfirewall_rule_group" "ip_drop" {
  capacity = 100
  name     = "drop-by-ip"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      stateful_rule {
        action = "DROP"
        header {
          destination      = "0.0.0.0/0"
          destination_port = "ANY"
          direction        = "ANY"
          protocol         = "TCP"
          source           = var.ip_to_drop
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["1"]
        }
      }
    }
  }
}
