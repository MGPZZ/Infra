# 새 IRSA 역할 생성 여부; false이면 기존 역할에 인라인 정책 연결
variable "create_role" {
  type    = bool
  default = true
}

# 생성하거나 재사용할 IAM 역할 이름
variable "role_name" {
  type = string
}

# 연결할 IAM 정책 이름과 권한 내용
variable "policy_name" {
  type = string
}

# 공식 정책처럼 완성된 JSON이 있으면 그대로 전달
variable "policy_json" {
  type    = string
  default = null
  validation {
    condition     = var.policy_json == null || can(jsondecode(var.policy_json))
    error_message = "policy_json에는 유효한 JSON 정책을 전달해야 합니다."
  }
}

# 직접 정의하는 권한은 Statement별 값으로 전달
variable "policy_statements" {
  type = list(object({
    effect    = optional(string, "Allow")
    actions   = list(string)
    resources = list(string)
    sid       = optional(string)
    condition = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
  }))
  default = []

  validation {
    condition = ((var.policy_json != null) != (length(var.policy_statements) > 0)) && alltrue([
      for statement in var.policy_statements :
      contains(["Allow", "Deny"], statement.effect) &&
      length(statement.actions) > 0 && length(statement.resources) > 0 &&
      alltrue([for condition in statement.condition : length(condition.values) > 0])
    ])
    error_message = "policy_json 또는 policy_statements 중 하나만 지정하고, Statement의 권한 항목과 조건 값은 비워 두지 마세요."
  }
}

variable "policy_description" {
  type    = string
  default = null
}

# 새 IRSA 역할을 사용할 EKS OIDC Provider
variable "oidc_provider_arn" {
  type    = string
  default = null
  validation {
    condition     = !var.create_role || can(regex("^arn:[^:]+:iam::[0-9]{12}:oidc-provider/.+$", var.oidc_provider_arn))
    error_message = "IRSA 역할 생성에는 유효한 OIDC Provider ARN이 필요합니다."
  }
}

# IRSA 역할 사용을 허용할 namespace:ServiceAccount 목록
variable "namespace_service_accounts" {
  type    = list(string)
  default = []
  validation {
    condition = !var.create_role || (
      length(var.namespace_service_accounts) > 0 &&
      alltrue([for sa in var.namespace_service_accounts : can(regex("^[^:*?]+:[^:*?]+$", sa))])
    )
    error_message = "IRSA 역할 생성에는 와일드카드 없는 namespace:ServiceAccount 목록이 필요합니다."
  }
}

# 기존 역할별 삭제 시 정책 분리 동작 유지
variable "force_detach_policies" {
  type    = bool
  default = false
}
