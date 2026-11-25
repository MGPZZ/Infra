# 생성한 IRSA 역할과 관리형 정책 ARN 반환
output "iam_role_arn" {
  value = try(aws_iam_role.this[0].arn, null)
}

output "policy_arn" {
  value = try(aws_iam_policy.this[0].arn, null)
}
