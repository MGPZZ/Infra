# NAT Controller가 사용할 AWS 계정·리전 정보
data "aws_caller_identity" "nat_controller" {}
data "aws_region" "nat_controller" {}
data "aws_partition" "nat_controller" {}

# AZ별 기본 NAT와 다른 AZ의 전환 대상을 함께 전달
locals {
  nat_controller_targets = {
    (var.azs[0]) = {
      instance_id          = module.side_project_nat_instance_a.nat_instance_id
      network_interface_id = module.side_project_nat_instance_a.primary_network_interface_id
      route_table_id       = aws_route_table.side_project_private_rt_a.id
      failover_az          = var.azs[1]
    }
    (var.azs[1]) = {
      instance_id          = module.side_project_nat_instance_c.nat_instance_id
      network_interface_id = module.side_project_nat_instance_c.primary_network_interface_id
      route_table_id       = aws_route_table.side_project_private_rt_c.id
      failover_az          = var.azs[0]
    }
  }
}

# 조치용 ServiceAccount만 사용할 수 있는 IAM 역할과 권한 생성
module "nat_controller_irsa" {
  source = "../../../modules/05-iam"

  role_name                  = "side-project-nat-controller-role"
  policy_name                = "side-project-nat-controller-policy"
  policy_description         = "Read NAT state and manage approved NAT instances and private route tables"
  oidc_provider_arn          = module.side_project_eks.oidc_provider_arn
  namespace_service_accounts = ["manage:nat-controller"]

  policy_statements = [
    {
      sid       = "ReadNATState"
      actions   = ["ec2:DescribeInstances", "ec2:DescribeInstanceStatus", "ec2:DescribeRouteTables"]
      resources = ["*"]
      condition = [{
        test     = "StringEquals"
        variable = "aws:RequestedRegion"
        values   = [data.aws_region.nat_controller.name]
      }]
    },
    {
      sid     = "RebootNATInstances"
      actions = ["ec2:RebootInstances"]
      resources = [
        for target in local.nat_controller_targets :
        "arn:${data.aws_partition.nat_controller.partition}:ec2:${data.aws_region.nat_controller.name}:${data.aws_caller_identity.nat_controller.account_id}:instance/${target.instance_id}"
      ]
    },
    {
      sid     = "SwitchNATRoutes"
      actions = ["ec2:ReplaceRoute"]
      resources = [
        aws_route_table.side_project_private_rt_a.arn,
        aws_route_table.side_project_private_rt_c.arn
      ]
    }
  ]
}
