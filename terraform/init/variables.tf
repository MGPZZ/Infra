variable "aws_profile" {
  type        = string
  description = "AWS CLI Profile Name"
  default     = "admin-seonggyu"
}

variable "backend_bucket_name" {
  type        = string
  description = "Terraform tfstate 상태 저장용 S3 버킷 이름"
  default     = "mgpzz-tflock"
}

variable "dynamodb_table_name" {
  type        = string
  description = "Terraform State Lock용 DynamoDB 테이블 이름"
  default     = "mak-tf-lock"
}

variable "thanos_bucket_name" {
  type        = string
  description = "Thanos 메트릭 장기 보관용 S3 버킷 이름"
  default     = "mgpzz-thanos-metrics"
}

variable "cnpg_bucket_name" {
  type        = string
  description = "CNPG 데이터베이스 백업 보존용 S3 버킷 이름"
  default     = "mgpzz-cnpg-backup"
}

variable "enable_acm" {
  type        = bool
  description = "ACM 인증서 및 Route53 레코드 생성 활성화 여부"
  default     = false
}