# Endpoint 이름 접두사
variable "name" {
  description = "Endpoint 이름 접두사"
  type        = string
}

# Endpoint를 생성할 VPC
variable "vpc_id" {
  description = "Endpoint를 생성할 VPC ID"
  type        = string
}

# AZ별 Endpoint 배치 서브넷
variable "subnet_ids" {
  description = "AZ마다 하나씩 지정하는 서브넷 ID 목록"
  type        = list(string)
}

# Endpoint 접근을 제어할 보안 그룹
variable "security_group_ids" {
  description = "Endpoint에 연결할 보안 그룹 ID 목록"
  type        = list(string)
}

# Endpoint를 생성할 AWS 서비스
variable "services" {
  description = "연결할 AWS 서비스 이름 집합"
  type        = set(string)
}
