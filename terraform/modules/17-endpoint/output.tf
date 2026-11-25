# 생성된 서비스별 Endpoint ID 전달
output "endpoint_ids" {
  description = "AWS 서비스 이름별 Endpoint ID"
  value = {
    for service, endpoint in aws_vpc_endpoint.this : service => endpoint.id
  }
}
