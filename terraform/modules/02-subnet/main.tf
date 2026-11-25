resource "aws_subnet" "this" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.cidr_block
  availability_zone       = var.az
  map_public_ip_on_launch = var.map_public_ip

  tags = {
    Name                     = var.name
    "kubernetes.io/role/elb" = var.cluster_role_subnet
    "karpenter.sh/discovery" = var.karpenter_subnet
  }
}

# Pod prefix는 .32~.239에 예약합니다. .4~.31과 .240~.254는 개별 IP 자동 할당에 사용합니다.
resource "aws_ec2_subnet_cidr_reservation" "pod_prefix" {
  for_each = var.enable_cidr_reservations ? var.pod_prefix_ranges : {}

  subnet_id        = aws_subnet.this.id
  cidr_block       = cidrsubnet(var.cidr_block, each.value.newbits, each.value.netnum)
  reservation_type = var.reservation_type
}
