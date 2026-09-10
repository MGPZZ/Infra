variable "aws_profile" {
  description = "AWS CLI 프로필 이름"
  type        = string
  default     = "default"
}

variable "azs" {
  description = "사용할 가용 영역 목록"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "eks_admin_users" {
  description = "EKS 클러스터 관리자 권한을 부여할 IAM 사용자 ARN 목록"
  type        = list(string)
  default = []
}
