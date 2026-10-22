# ECR (Container Registry) - 표준화된 마이크로서비스 저장소
module "ecr_frontend" {
  source               = "../modules/09-ecr"
  repository_name      = "frontend_ecr"
  image_tag_mutability = "MUTABLE"
}

module "ecr_userservice" {
  source               = "../modules/09-ecr"
  repository_name      = "userservice_ecr"
  image_tag_mutability = "MUTABLE"
}

module "ecr_contacts" {
  source               = "../modules/09-ecr"
  repository_name      = "contacts_ecr"
  image_tag_mutability = "MUTABLE"
}

module "ecr_balancereader" {
  source               = "../modules/09-ecr"
  repository_name      = "balancereader_ecr"
  image_tag_mutability = "MUTABLE"
}

module "ecr_ledgerwriter" {
  source               = "../modules/09-ecr"
  repository_name      = "ledgerwriter_ecr"
  image_tag_mutability = "MUTABLE"
}

module "ecr_transactionhistory" {
  source               = "../modules/09-ecr"
  repository_name      = "transactionhistory_ecr"
  image_tag_mutability = "MUTABLE"
}

# KRR(Kubernetes Resource Recommender) 기반 리소스 분석 배치/실시간 이미지
module "krr_analyzer_ecr" {
  source               = "../modules/09-ecr"
  repository_name      = "krr-analyzer"
  image_tag_mutability = "MUTABLE"
}

# 텔레그램/슬랙/디스코드 등 범용 메신저 알림 발송 게이트웨이 이미지
module "tg_gateway_ecr" {
  source               = "../modules/09-ecr"
  repository_name      = "tg-gateway"
  image_tag_mutability = "IMMUTABLE"
}

module "sample_fastapi_ecr" {
  source               = "../modules/09-ecr"
  repository_name      = "sample-fastapi"
  image_tag_mutability = "IMMUTABLE"
}

module "loadgen_ecr" {
  source               = "../modules/09-ecr"
  repository_name      = "loadgen_ecr"
  image_tag_mutability = "IMMUTABLE"
}



