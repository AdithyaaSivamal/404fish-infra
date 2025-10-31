
variable "project_name" {
  description = "The name of the project, used for tagging resources."
  type        = string
}

variable "budget_amount_usd" {
  description = "The monthly budget amount in USD. An alert will be sent when forecasted spending exceeds a percentage of this."
  type        = number
  default     = 10
}

variable "alert_email" {
  description = "The email address to send budget and anomaly alerts to."
  type        = string
}

