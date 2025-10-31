
# Creates a monthly budget for the entire AWS account.
resource "aws_budgets_budget" "monthly" {
  name         = "${var.project_name}-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.budget_amount_usd
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Sends an alert when forecasted spending reaches 80% of the budget.
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}


# Creates a monitor that looks for cost anomalies related to our project's tag.
resource "aws_ce_anomaly_monitor" "service_monitor" {
  name         = "${var.project_name}-service-monitor"
  monitor_type = "CUSTOM"

  monitor_specification = jsonencode({
    Tags = {
      Key    = "Name"
      Values = [var.project_name]
    }
  })
}


# Subscribes an email address to receive immediate notifications about anomalies.
resource "aws_ce_anomaly_subscription" "email_subscription" {
  name             = "${var.project_name}-anomaly-subscription"
  monitor_arn_list = [aws_ce_anomaly_monitor.service_monitor.arn]
  frequency        = "DAILY"

  #alert on any anomaly with a cost impact greater than $0.
  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = ["15"]
    }
  }

  subscriber {
    type    = "EMAIL"
    address = var.alert_email
  }
}


