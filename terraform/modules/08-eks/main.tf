module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id                         = var.vpc_id
  subnet_ids                     = var.subnet_ids
  cluster_endpoint_public_access = true
  node_security_group_tags       = var.node_security_group_tags

  authentication_mode                      = "API_AND_CONFIG_MAP"
  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true

  cluster_addons = {
    # coredns는 서비스를 이름으로 찾을 수 있게해줌
    coredns = {
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values = jsonencode({
        # pod 개수를 2개로하여 management 노드가 있는 두 AZ에 하나씩 배치
        replicaCount = 2
        autoScaling = {
          enabled = false
        }
        affinity = {
          nodeAffinity = {
            # 조건에 맞지 않는 노드에는 스케쥴링 되지 않음
            requiredDuringSchedulingIgnoredDuringExecution = {
              nodeSelectorTerms = [ 
                {
                  # 스케쥴링 되는 노드 조건 management 노드
                  matchExpressions = [
                    {
                      key      = "role"
                      operator = "In"
                      values   = ["management"]
                    }
                  ]
                }
              ]
            }
          }
        }
        podAnnotations = {
          "karpenter.sh/do-not-disrupt" = "true"
        }
        # management 노드가 있는 두 AZ에 하나씩 배치하며, 한 AZ만 있으면 두 번째 Pod는 대기
        topologySpreadConstraints = [
          {
            maxSkew           = 1
            minDomains        = 2
            topologyKey       = "topology.kubernetes.io/zone" # 가용영역 분산
            whenUnsatisfiable = "DoNotSchedule"
            labelSelector = {
              matchLabels = {
                "k8s-app" = "kube-dns"
              }
            }
          },
          {
            maxSkew           = 1
            topologyKey       = "kubernetes.io/hostname" # 노드 1개에 다 안올라가게 분산
            whenUnsatisfiable = "DoNotSchedule"
            labelSelector = {
              matchLabels = {
                "k8s-app" = "kube-dns"
              }
            }
          }
        ]
      })
    }
    kube-proxy         = { resolve_conflicts_on_create = "OVERWRITE" }
    vpc-cni            = { resolve_conflicts_on_create = "OVERWRITE" }
    aws-ebs-csi-driver = { resolve_conflicts_on_create = "OVERWRITE" }
  }

  eks_managed_node_group_defaults = {
    iam_role_additional_policies = {
      AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    }
  }

  eks_managed_node_groups = {
    eks-management-node = {
      name                   = "eks-management-node"
      instance_types         = var.instance_types
      ami_type               = var.ami_type
      min_size               = 2
      max_size               = 3
      desired_size           = 2
      vpc_security_group_ids = var.node_security_group_ids
      # manage node는 라벨을 management로 붙임
      # karpenter가 붙을 수 있게 태그 추가 작성
      labels = {
        role                      = "management"
        "karpenter.sh/controller" = "true"
      }
    }

    eks-worker-node = {
      name                   = "eks-worker-node"
      instance_types         = var.instance_types
      ami_type               = var.ami_type
      min_size               = var.min_size
      max_size               = var.max_size
      desired_size           = var.desired_size
      vpc_security_group_ids = var.node_security_group_ids
      # worker node는 라벨을 worker로 붙임
      labels = {
        role = "worker"
      }
    }

    eks-db-node = {
      name                   = "eks-db-node"
      instance_types         = ["t3.small"]
      ami_type               = var.ami_type
      min_size               = 1
      max_size               = 2
      desired_size           = 1
      vpc_security_group_ids = var.node_security_group_ids

      labels = {
        role = "db"
      }

      taints = {
        dedicated = {
          key    = "dedicated"
          value  = "db"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  access_entries = {
    for arn in var.admin_users : arn => {
      kubernetes_groups = []
      principal_arn     = arn

      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}
