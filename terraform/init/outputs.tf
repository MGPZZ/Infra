# --------------------------------------
# 파일 위치 : terraform/init/outputs.tf
# --------------------------------------

# ---------
# S3 버킷
# ---------
output "s3_bucket_name" {
  value       = aws_s3_bucket.tfstate_bucket.id
  description = "tfstate 저장될 S3 버킷의 이름"
}

# ----------
# ACM 인증서
# ----------
output "acm_certificate_arn" {
  value       = aws_acm_certificate.this.arn
  description = "발급된 ACM 인증서 ARN"
}

# --------------------
# ECR Repository URLs
# --------------------

output "ecr_frontend" {
  description = "Frontend ECR Repository URL"
  value       = module.ecr_frontend.repository_url
}

output "ecr_userservice" {
  description = "UserService ECR Repository URL"
  value       = module.ecr_userservice.repository_url
}

output "ecr_contacts" {
  description = "Contacts ECR Repository URL"
  value       = module.ecr_contacts.repository_url
}

output "ecr_balancereader" {
  description = "BalanceReader ECR Repository URL"
  value       = module.ecr_balancereader.repository_url
}

output "ecr_ledgerwriter" {
  description = "LedgerWriter ECR Repository URL"
  value       = module.ecr_ledgerwriter.repository_url
}

output "ecr_transactionhistory" {
  description = "TransactionHistory ECR Repository URL"
  value       = module.ecr_transactionhistory.repository_url
}

output "krr_analyzer_ecr_repository_url" {
  description = "KRR Analyzer ECR Repository URL"
  value       = module.krr_analyzer_ecr.repository_url
}

output "notification_gateway_ecr_repository_url" {
  description = "Notification Gateway ECR Repository URL"
  value       = module.notification_gateway_ecr.repository_url
}

output "chronos_model_ecr_repository_url" {
  description = "Chronos Model ECR Repository URL"
  value       = module.chronos_model_ecr.repository_url
}

