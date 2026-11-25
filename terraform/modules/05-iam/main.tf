# 지정한 ServiceAccount가 역할을 사용할 수 있도록 IRSA 신뢰 관계 설정
data "aws_iam_policy_document" "irsa" {
  count = var.create_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_arn, "/^(.*provider/)/", "")}:sub"
      values   = [for sa in var.namespace_service_accounts : "system:serviceaccount:${sa}"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider_arn, "/^(.*provider/)/", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# infra에서 전달한 항목으로 권한 정책의 JSON 구조 생성
data "aws_iam_policy_document" "permissions" {
  version                 = "2012-10-17"
  source_policy_documents = var.policy_json == null ? [] : [var.policy_json]

  dynamic "statement" {
    for_each = var.policy_statements
    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources

      dynamic "condition" {
        for_each = statement.value.condition
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

# 새로운 IRSA 역할 생성
resource "aws_iam_role" "this" {
  count = var.create_role ? 1 : 0

  name                  = var.role_name
  assume_role_policy    = data.aws_iam_policy_document.irsa[0].json
  force_detach_policies = var.force_detach_policies
}

# infra에서 전달받은 권한 내용으로 관리형 정책 생성
resource "aws_iam_policy" "this" {
  count = var.create_role ? 1 : 0

  name        = var.policy_name
  description = var.policy_description
  policy      = data.aws_iam_policy_document.permissions.json
}

# 생성한 역할에 관리형 정책 연결
resource "aws_iam_role_policy_attachment" "this" {
  count = var.create_role ? 1 : 0

  role       = aws_iam_role.this[0].name
  policy_arn = aws_iam_policy.this[0].arn
}

# 기존 역할을 사용할 때는 전달받은 인라인 정책만 연결
resource "aws_iam_role_policy" "inline" {
  count = var.create_role ? 0 : 1

  name   = var.policy_name
  role   = var.role_name
  policy = data.aws_iam_policy_document.permissions.json
}
