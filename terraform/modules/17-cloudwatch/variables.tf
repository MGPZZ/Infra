###############################################
# Variables
###############################################

variable "alarm_name" {
  description = "Name of the CloudWatch alarm"
  type        = string
}

variable "instance_id" {
  description = "EC2 instance ID monitored by the alarm"
  type        = string
  default     = null
}

variable "namespace" {
  description = "CloudWatch namespace monitored by the alarm"
  type        = string
  default     = "AWS/EC2"
}

variable "dimensions" {
  description = "CloudWatch metric dimensions; defaults to InstanceId when omitted"
  type        = map(string)
  default     = null
}

variable "metric_name" {
  description = "AWS/EC2 metric name monitored by the alarm"
  type        = string
  default     = "StatusCheckFailed"
  nullable    = false
}

variable "statistic" {
  description = "Statistic used to evaluate the metric"
  type        = string
  default     = "Maximum"
}

variable "period_seconds" {
  description = "CloudWatch metric period in seconds"
  type        = number
  default     = 60
}

variable "evaluation_periods" {
  description = "Consecutive periods that must breach before the alarm activates"
  type        = number
  default     = 1
  nullable    = false
}

variable "datapoints_to_alarm" {
  description = "Number of breaching data points required to activate the alarm"
  type        = number
  default     = null
}

variable "threshold" {
  description = "Threshold used for the alarm comparison"
  type        = number
  default     = 0
}

variable "comparison_operator" {
  description = "Operator used to compare the metric against the threshold"
  type        = string
  default     = "GreaterThanThreshold"
}

variable "treat_missing_data" {
  description = "How CloudWatch handles missing metric data"
  type        = string
  default     = "missing"
}

variable "alarm_actions" {
  description = "Actions invoked when the alarm enters ALARM state"
  type        = list(string)
}

variable "ok_actions" {
  description = "Actions invoked when the alarm returns to OK state"
  type        = list(string)
  default     = []
  nullable    = false
}

variable "lambda_function_name" {
  description = "Lambda function name to permit CloudWatch invocation; null when no Lambda action is used"
  type        = string
  default     = null
}
