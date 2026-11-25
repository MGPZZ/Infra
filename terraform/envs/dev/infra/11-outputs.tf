output "vpc_id" {
  description = "VPC ID used to reject stale ALBs from a previous environment"
  value       = module.side_project_vpc.vpc_id
}

# k8s 배포 설정에서 ServiceAccount에 연결할 역할
output "nat_controller_role_arn" {
  value = module.nat_controller_irsa.iam_role_arn
}

# ConfigMap의 config.json으로 전달할 Controller 설정
output "nat_controller_config" {
  value = {
    region                 = data.aws_region.nat_controller.name
    vpc_id                 = module.side_project_vpc.vpc_id
    alert_name             = "NATEgressFailure"
    targets                = local.nat_controller_targets
    probe_targets          = module.nat_failover.probe_targets.service
    recovery_probe_targets = module.nat_failover.probe_targets.recovery
  }
}
