###############################################
# Outputs
###############################################

output "function_arn" {
  description = "ARN of the NAT route failover Lambda function"
  value       = aws_lambda_function.nat_route_failover.arn
}

output "function_name" {
  description = "Name of the NAT route failover Lambda function"
  value       = aws_lambda_function.nat_route_failover.function_name
}
