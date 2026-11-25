# AWS Provider에 설정된 리전 조회
data "aws_region" "current" {}

# 서비스별 Interface Endpoint 생성
resource "aws_vpc_endpoint" "this" {
  for_each = var.services

  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  vpc_endpoint_type = "Interface"

  # 지정한 서브넷과 보안 그룹에 사설 연결 경로 구성
  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids

  # 기본 AWS API 주소를 Endpoint의 사설 IP로 연결
  private_dns_enabled = true

  tags = {
    Name = "${var.name}-${each.value}-endpoint"
  }
}
