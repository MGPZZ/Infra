############################################
# 4. EKS (Control Plane, Worker Node 생성 및 설정)
############################################
module "side_project_eks" {
  source = "../../../modules/08-eks"

  cluster_name    = "side-project-eks"
  cluster_version = "1.36"
  vpc_id          = module.side_project_vpc.vpc_id
  subnet_ids = [
    module.side_project_private_subnet_cluster_a.subnet_id,
    module.side_project_private_subnet_cluster_c.subnet_id
  ]

  node_security_group_tags = {
    "karpenter.sh/discovery" = "side-project-eks"
  }

  admin_users = var.eks_admin_users

  # 공통 노드 설정. AMI 선택과 초기화·자원 보호 기준은 EKS 기본값을 사용합니다.
  node_group_defaults = {
    ami_type               = "AL2023_x86_64_STANDARD"
    vpc_security_group_ids = [module.security_groups.eks_node_sg_id]
  }

  ebs_csi_node_selector = {
    "ebs-csi-enabled" = "true"
  }

  # 노드 그룹 생성
  node_groups = {
    # 매니지 노드 생성
    eks-management-node = {
      # EBS CSI Controller가 실행되는 노드에만 EBS 관리 권한을 부여합니다.
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
      instance_types = ["t3.small"]
      min_size       = 2
      max_size       = 5
      desired_size   = 2
      labels = {
        role                      = "management"
        "karpenter.sh/controller" = "true"
      }
    }
    # 모니터링 노드 생성
    eks-monitoring-node = {
      instance_types = ["t3.small"]
      min_size       = 2
      max_size       = 5
      desired_size   = 2
      labels = {
        role              = "monitoring"
        "ebs-csi-enabled" = "true"
      }
    }
    # 데이터베이스 노드 생성
    eks-db-node = {
      instance_types = ["t3.small"]
      min_size       = 3
      max_size       = 5
      desired_size   = 3
      labels = {
        role              = "db"
        "ebs-csi-enabled" = "true"
      }
      taints = {
        dedicated = {
          key    = "dedicated"
          value  = "db"
          effect = "NO_SCHEDULE"
        }
      }
    }
    # 워커 노드 생성
    eks-worker-node = {
      instance_types = ["t3.small"]
      min_size       = 2
      max_size       = 5
      desired_size   = 2
      labels = {
        role = "worker"
      }
    }
  }

}

# eks 접속용 인증 토큰 가져오기
data "aws_eks_cluster_auth" "cluster" {
  name = module.side_project_eks.cluster_name
}

provider "kubernetes" {
  host                   = module.side_project_eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.side_project_eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--region", "ap-northeast-2", "--cluster-name", module.side_project_eks.cluster_name]
    env = {
      AWS_PROFILE = var.aws_profile
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = module.side_project_eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.side_project_eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--region", "ap-northeast-2", "--cluster-name", module.side_project_eks.cluster_name]
      env = {
        AWS_PROFILE = var.aws_profile
      }
    }
  }
}
