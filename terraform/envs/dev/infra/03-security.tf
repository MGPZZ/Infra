############################################
# 3. SECURITY GROUP & IAM
############################################

module "security_groups" {
  source = "../../../modules/04-security-group"

  name   = "side-project"
  vpc_id = module.side_project_vpc.vpc_id

  # 프라이빗 서브넷들의 대역폭
  eks_private_subnet_cidrs = [
    "10.0.10.0/24",
    "10.0.30.0/24"
  ]
}

# EC2·STS Endpoint에 연결할 보안 그룹
resource "aws_security_group" "nat_controller_endpoint" {
  name        = "side-project-nat-controller-endpoint"
  description = "Allow HTTPS from EKS nodes to EC2 and STS endpoints"
  vpc_id      = module.side_project_vpc.vpc_id

  # EKS 노드의 HTTPS 요청만 허용하며 응답은 자동 허용
  ingress {
    description     = "HTTPS from EKS nodes"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [module.security_groups.eks_node_sg_id]
  }

  tags = {
    Name = "side-project-nat-controller-endpoint"
  }
}
