variable "az" {
  description = "사용할 가용영역"
  type        = string
}
variable "cidr_block" {
  type = string

  validation {
    condition     = !var.enable_cidr_reservations || (can(cidrnetmask(var.cidr_block)) && can(regex("/24$", var.cidr_block)))
    error_message = "CIDR reservations require an IPv4 /24 subnet."
  }
}
variable "map_public_ip" {

}
variable "name" {

}

variable "vpc_id" {

}
variable "cluster_role_subnet" {
  default     = null
  description = "Discern subnet to use the aws lb controller "
}

variable "karpenter_subnet" {
  default     = null
  description = "Discern subnet to use the karpenter "
}

variable "enable_cidr_reservations" {
  type    = bool
  default = false
}

variable "reservation_type" {
  type    = string
  default = "prefix"
}

variable "pod_prefix_ranges" {
  type = map(object({
    newbits = number
    netnum  = number
  }))

  default = {
    "32_63"   = { newbits = 3, netnum = 1 }
    "64_127"  = { newbits = 2, netnum = 1 }
    "128_191" = { newbits = 2, netnum = 2 }
    "192_223" = { newbits = 3, netnum = 6 }
    "224_239" = { newbits = 4, netnum = 14 }
  }
}
