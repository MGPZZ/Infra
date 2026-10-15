terraform {
  backend "s3" {
    bucket       = "tfstate-bucket-229a9274"
    key          = "init/terraform.tfstate"
    region       = "ap-northeast-2"
    use_lockfile = true
    encrypt      = true
  }
}
