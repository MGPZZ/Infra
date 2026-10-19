# ECR (Container Registry) - 표준화된 마이크로서비스 저장소
module "ecr_frontend" {
  source               = "../modules/09-ecr"
  repository_name      = "frontend"
  image_tag_mutability = "MUTABLE"
}

module "ecr_userservice" {
  source               = "../modules/09-ecr"
  repository_name      = "userservice"
  image_tag_mutability = "MUTABLE"
}

module "ecr_contacts" {
  source               = "../modules/09-ecr"
  repository_name      = "contacts"
  image_tag_mutability = "MUTABLE"
}

module "ecr_balancereader" {
  source               = "../modules/09-ecr"
  repository_name      = "balancereader"
  image_tag_mutability = "MUTABLE"
}

module "ecr_ledgerwriter" {
  source               = "../modules/09-ecr"
  repository_name      = "ledgerwriter"
  image_tag_mutability = "MUTABLE"
}

module "ecr_transactionhistory" {
  source               = "../modules/09-ecr"
  repository_name      = "transactionhistory"
  image_tag_mutability = "MUTABLE"
}

# KRR(Kubernetes Resource Recommender) 기반 리소스 분석 배치/실시간 이미지
module "krr_analyzer_ecr" {
  source               = "../modules/09-ecr"
  repository_name      = "krr-analyzer"
  image_tag_mutability = "MUTABLE"
}

# 텔레그램/슬랙/디스코드 등 범용 메신저 알림 발송 게이트웨이 이미지
module "notification_gateway_ecr" {
  source               = "../modules/09-ecr"
  repository_name      = "notification-gateway"
  image_tag_mutability = "MUTABLE"
}





