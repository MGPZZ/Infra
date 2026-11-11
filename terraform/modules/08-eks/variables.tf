variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for EKS"
  type        = list(string)
}

variable "node_security_group_tags" {
  description = "Tags to apply to the EKS shared node security group"
  type        = map(string)
  default     = {}
}

variable "node_group_defaults" {
  description = "Common managed node settings defined by the environment. EKS manages AMI selection and bootstrap defaults."
  type = object({
    ami_type               = string
    vpc_security_group_ids = list(string)
    iam_role_additional_policies = map(string)
  })
}

variable "node_groups" {
  type = map(object({
    instance_types               = list(string)
    min_size                     = number
    max_size                     = number
    desired_size                 = number
    labels                       = map(string)
    taints = optional(map(object({
      key    = string
      value  = optional(string)
      effect = string
    })), {})
  }))

  validation {
    condition = alltrue([
      for group in values(var.node_groups) :
      length(group.instance_types) > 0 &&
      group.min_size >= 0 &&
      group.min_size <= group.desired_size &&
      group.desired_size <= group.max_size
    ])
    error_message = "Each node group must have an instance type and satisfy 0 <= min_size <= desired_size <= max_size."
  }
}

variable "admin_users" {
  description = "List of IAM user ARNs to grant cluster admin access"
  type        = list(string)
  default     = []
}
