###############################################
# NAT Route Failover and Egress Check Lambdas
###############################################

module "nat_route_failover_lambda" {
  source = "../../../modules/18-lambda"

  name = "side-project-nat-route-failover"

  nat_routes = {
    "side-project-nat-a-status-check" = {
      route_table_id               = aws_route_table.side_project_private_rt_a.id
      primary_instance_id          = module.side_project_nat_instance_a.nat_instance_id
      primary_network_interface_id = module.side_project_nat_instance_a.primary_network_interface_id
      standby_network_interface_id = module.side_project_nat_instance_c.primary_network_interface_id
    }

    "side-project-nat-c-status-check" = {
      route_table_id               = aws_route_table.side_project_private_rt_c.id
      primary_instance_id          = module.side_project_nat_instance_c.nat_instance_id
      primary_network_interface_id = module.side_project_nat_instance_c.primary_network_interface_id
      standby_network_interface_id = module.side_project_nat_instance_a.primary_network_interface_id
    }
  }

  egress_check = {
    name      = "side-project-nat-egress-check"
    vpc_id    = module.side_project_vpc.vpc_id
    probe_ips = ["1.1.1.1", "8.8.8.8"]
    targets = {
      nat_a = {
        subnet_id = module.side_project_private_subnet_cluster_c.subnet_id
      }
      nat_c = {
        subnet_id = module.side_project_private_subnet_cluster_a.subnet_id
      }
    }
  }
}
