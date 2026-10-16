resource "aws_ecr_repository" "this" {
  name = var.repository_name
  image_tag_mutability = var.image_tag_mutability

  # 이미지가 남아있으면 삭제 차단 (실수 방지)
  force_delete = false

  # 이미지 유무와 관계없이 terraform destroy 차단
  lifecycle {
    prevent_destroy = true
  }

  # 이미지 푸시 시 취약점 자동 스캔
  image_scanning_configuration {
    scan_on_push = true
  }
}

# ECR 수명 주기 정책 (Lifecycle Policy)
# 1) 태그 없는(untagged) 임시 이미지는 1일 후 자동 삭제
# 2) 개발/CI 빌드 이미지(dev-, sha-, ci-, test-, pr-)는 최신 10개만 유지
# 3) 정식 릴리스 버전(v*)은 어떤 만료 규칙에도 걸리지 않아 영구 보존
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Delete untagged dangling images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only last 10 development/CI images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev-", "sha-", "ci-", "test-", "pr-"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}