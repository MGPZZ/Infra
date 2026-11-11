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
    kube-proxy = { resolve_conflicts_on_create = "OVERWRITE" }
    # t3.small 기준 pod 생성 기준이 최대 11개로 고정되어있는데 cpu와 memory 값이 남아도 11개가 고정되어있어서 생성 못하는 부분 발견
    # 밑의 vpc-cni 부분은 해당 부분에 대한 설정을 완화하는 블럭
    vpc-cni = {       # pod의 네트워크 설정 변경
      # node가 뜨기 전 미리 설정    
      before_compute              = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values = jsonencode({
        env = {
          # pod 개수 제한 해제
          ENABLE_PREFIX_DELEGATION = "true"
        }
      })
    }
    eks-node-monitoring-agent = {
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    aws-ebs-csi-driver = {
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values = jsonencode({
        controller = {
          nodeSelector = {
            role = "management"
          }
        }
        node = {
          nodeSelector = var.ebs_csi_node_selector
        }
      })
    }
  }

  eks_managed_node_group_defaults = var.node_group_defaults

  eks_managed_node_groups = var.node_groups

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
