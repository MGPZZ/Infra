variable "aws_profile" { type = string }

variable "priority_classes" {
  description = "PriorityClass names and their scheduling priorities."
  type        = map(number)
}
