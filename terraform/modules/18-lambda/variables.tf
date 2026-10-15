###############################################
# Variables
###############################################

variable "name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "nat_routes" {
  description = "NAT route failover configuration keyed by CloudWatch alarm name"
  type = map(object({
    route_table_id               = string
    primary_instance_id          = string
    primary_network_interface_id = string
    standby_network_interface_id = string
  }))
}

variable "egress_check" {
  description = "Configuration for VPC Lambda functions that publish NAT egress health metrics"
  type = object({
    name      = string
    vpc_id    = string
    probe_ips = list(string)
    targets = map(object({
      subnet_id = string
    }))
  })

  validation {
    condition     = length(var.egress_check.probe_ips) > 0
    error_message = "At least one public probe IP is required."
  }
}

variable "tags" {
  description = "Tags applied to Lambda resources"
  type        = map(string)
  default     = {}
}
