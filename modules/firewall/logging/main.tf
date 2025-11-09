resource "aws_networkfirewall_logging_configuration" "main" {
  firewall_arn = var.firewall_arn

  logging_configuration {
    log_destination_config {
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"

      log_destination = {
        logGroup = var.cloudwatch_log_group_name
      }
    }
    log_destination_config {
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"

      log_destination = {
        logGroup = var.cloudwatch_log_group_name
      }
    }
  }
}
