# ECR (Container Registry)
module "ecr_frontend" {
  source               = "../modules/09-ecr" 
  repository_name      = "mak_frontend_ecr"
  image_tag_mutability = "MUTABLE"
}

module "ecr_userservice" {
  source               = "../modules/09-ecr"
  repository_name      = "mak_userservice_ecr"
  image_tag_mutability = "MUTABLE"
}


module "ecr_contacts" {
  source               = "../modules/09-ecr"
  repository_name      = "mak_contacts_ecr"
  image_tag_mutability = "MUTABLE"
}


module "ecr_balancereader" {
  source               = "../modules/09-ecr"
  repository_name      = "mak_balancereader_ecr"
  image_tag_mutability = "MUTABLE"
}


module "ecr_ledgerwriter" {
  source               = "../modules/09-ecr"
  repository_name      = "mak_ledgerwriter_ecr"
  image_tag_mutability = "MUTABLE"
}


module "ecr_transactionhistory" {
  source               = "../modules/09-ecr"
  repository_name      = "mak_transactionhistory_ecr"
  image_tag_mutability = "MUTABLE"
}


# finops cronjob 부분이 들어있는 이미지 들어가는 부분
module "finops_analyzer_ecr" {
  source = "../modules/09-ecr"

  repository_name      = "finops-analyzer"
  image_tag_mutability = "IMMUTABLE"
}


# telegram과 같은 메신저로 알람을 보내는 파이프라인을 위한 코드가 들어가는 부분
module "tg_gateway_ecr" {
  source               = "../modules/09-ecr"
  repository_name      = "tg-gateway"
  image_tag_mutability = "IMMUTABLE"
}



