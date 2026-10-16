output "vpc_id" {
  description = "VPC ID used to reject stale ALBs from a previous environment"
  value       = module.side_project_vpc.vpc_id
}
