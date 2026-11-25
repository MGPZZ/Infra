############################################
# 2. ROUTING LAYER (라우팅 테이블)
############################################

# [1] Public Route Table
# 인터넷 게이트웨이(IGW)를 향하는 기본 라우팅(0.0.0.0/0)을 설정합니다.
# 라우팅 테이블에 연결된 서브넷은 외부 인터넷과 직접 통신이 가능합니다.
resource "aws_route_table" "side_project_public_rt" {
  vpc_id = module.side_project_vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = module.igw.igw_id
  }

  tags = {
    Name = "side-project-public-rt"
  }
}

# Public Subnet 연결
# A와 C 두 개의 퍼블릭 서브넷을 위에서 만든 라우팅 테이블에 연결합니다.
resource "aws_route_table_association" "public_a_rt" {
  subnet_id      = module.side_project_public_subnet_a.subnet_id
  route_table_id = aws_route_table.side_project_public_rt.id
}

resource "aws_route_table_association" "public_c_rt" {
  subnet_id      = module.side_project_public_subnet_c.subnet_id
  route_table_id = aws_route_table.side_project_public_rt.id
}


# [2] NAT 인스턴스
# 퍼블릭 서브넷 A에 위치하는 NAT instance
module "side_project_nat_instance_a" {
  source             = "../../../modules/06-nat-instance"
  name               = "side-project-nat-instance-a"
  subnet_id          = module.side_project_public_subnet_a.subnet_id
  security_group_ids = [module.security_groups.nat_sg_id]
}

# 퍼블릭 서브넷 C에 위치하는 NAT instance
module "side_project_nat_instance_c" {
  source             = "../../../modules/06-nat-instance"
  name               = "side-project-nat-instance-c"
  subnet_id          = module.side_project_public_subnet_c.subnet_id
  security_group_ids = [module.security_groups.nat_sg_id]
}


# [3] Private Route Table A & C
# AZ별로 프라이빗 서브넷이 각각 자신의 NAT 인스턴스를 바라보도록 라우팅 테이블을 2개 생성합니다.
resource "aws_route_table" "side_project_private_rt_a" {
  vpc_id = module.side_project_vpc.vpc_id

  tags = {
    Name = "side-project-private-rt-a"
  }
}

resource "aws_route_table" "side_project_private_rt_c" {
  vpc_id = module.side_project_vpc.vpc_id

  tags = {
    Name = "side-project-private-rt-c"
  }
}

module "nat_failover" {
  source      = "../../../modules/18-nat-failover"
  nat_targets = local.nat_controller_targets

  probe_targets = {
    # blackbox exporter와 nat_controller가 nat를 통해 외부 접속이 가능한지 테스트하는 ip와 port번호
    service = [
      { ip = "1.1.1.1", port = 53 },
      { ip = "8.8.8.8", port = 53 },
    ]
    recovery = {
      # failover 후 failback으로 넘어가기 복구된 nat를 통해 외부 접속이 가능한지 테스트하는 ip와 port번호
      ip   = "8.8.4.4"
      port = 53
    }
  }
}

# [4] Private Subnet 연결
# AZ A의 서브넷들은 RT A에, AZ C의 서브넷들은 RT C에 연결합니다.
resource "aws_route_table_association" "cluster_rt_A" {
  depends_on = [module.nat_failover.default_route_ids]

  subnet_id      = module.side_project_private_subnet_cluster_a.subnet_id
  route_table_id = aws_route_table.side_project_private_rt_a.id
}

resource "aws_route_table_association" "cluster_rt_C" {
  depends_on = [module.nat_failover.default_route_ids]

  subnet_id      = module.side_project_private_subnet_cluster_c.subnet_id
  route_table_id = aws_route_table.side_project_private_rt_c.id
}


