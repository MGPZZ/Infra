###############################################
# NAT Instance Health Monitoring
###############################################

data "aws_region" "current" {}

locals {
  nat_route_failover_targets = {
    nat_a = {
      route_failover_alarm_name = "side-project-nat-a-status-check"
      instance_id               = module.side_project_nat_instance_a.nat_instance_id
    }
    nat_c = {
      route_failover_alarm_name = "side-project-nat-c-status-check"
      instance_id               = module.side_project_nat_instance_c.nat_instance_id
    }
  }
}

# Nat instance에 문제가 발생하였을 때 살아있는 Nat instance로 라우팅 설정을 바꿔서 failover하는 블럭
module "nat_route_failover_alarm" {
  for_each = local.nat_route_failover_targets

  source = "../../../modules/17-cloudwatch"

  alarm_name  = each.value.route_failover_alarm_name
  namespace   = "MGPZZ/NAT"
  metric_name = "EgressHealthy"
  dimensions = {
    NatName = each.key
  }
  statistic            = "Minimum"
  period_seconds       = 60
  evaluation_periods   = 3
  datapoints_to_alarm  = 2
  threshold            = 1
  comparison_operator  = "LessThanThreshold"
  treat_missing_data   = "missing"
  alarm_actions        = [module.nat_route_failover_lambda.function_arn] # 문제 발생 시 이 주소로 lambda를 호출
  ok_actions           = [module.nat_route_failover_lambda.function_arn] # 문제 해결 시 이 주소로 lambda를 호출 
  lambda_function_name = module.nat_route_failover_lambda.function_name  # default값은 null이고 지금처럼 값을 넣어주면 Cloudwatch가 lambda를 호출해도 되는 권한 부여
}
# ============================
# Nat 조치 사항에 해당하는 블럭
# ============================

# Nat instance가 시스템적으로 문제가 발생했을 때 복구
# 2분동안 os등 시스템에 문제가 있을 때 복구
module "nat_system_recovery_alarm" {
  for_each = local.nat_route_failover_targets

  source = "../../../modules/17-cloudwatch"

  alarm_name         = "${each.value.route_failover_alarm_name}-system-recovery"
  instance_id        = each.value.instance_id
  metric_name        = "StatusCheckFailed_System"
  evaluation_periods = 2
  alarm_actions      = ["arn:aws:automate:${data.aws_region.current.name}:ec2:recover"]
}
