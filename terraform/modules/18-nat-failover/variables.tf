variable "nat_targets" {
  description = "AZ별 프라이빗 라우팅 테이블과 기본 NAT 네트워크 인터페이스"
  type = map(object({
    route_table_id       = string
    network_interface_id = string
  }))
}

variable "probe_targets" {
  description = "일반 검사 대상 목록과 복구 검사 대상 하나의 공인 IPv4 및 TCP 포트"
  type = object({
    service = list(object({
      ip   = string
      port = number
    }))
    recovery = object({
      ip   = string
      port = number
    })
  })
}
