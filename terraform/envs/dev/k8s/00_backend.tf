terraform {
  backend "s3" {
    key          = "k8s/terraform.tfstate"
    region       = "ap-northeast-2"
    use_lockfile = true
    encrypt      = true
  }
}

