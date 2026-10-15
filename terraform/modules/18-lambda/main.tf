###############################################
# NAT Route Failover Lambda
###############################################

# lambda에서 사용할 py 파일 zip으로 압축 ===============
data "archive_file" "nat_route_failover" {
  type        = "zip"
  source_file = "${path.module}/nat_route_failover.py"
  output_path = "${path.root}/.terraform/${var.name}.zip"
}

data "archive_file" "nat_egress_check" {
  type        = "zip"
  source_file = "${path.module}/nat_egress_check.py"
  output_path = "${path.root}/.terraform/${var.egress_check.name}.zip"
}
# ====================================================

# lambda가 실행될 때 사용할 iam role 생성
resource "aws_iam_role" "nat_route_failover" {
  name = "${var.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# lambda가 cloudwatch에 로그 기록을 남길 수 있는 실행 권한 부여
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.nat_route_failover.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# lambda가 라우팅을 변경할 수 있게 권한 부여
resource "aws_iam_role_policy" "replace_route" {
  name = "${var.name}-replace-route"
  role = aws_iam_role.nat_route_failover.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ec2:ReplaceRoute", "ec2:RebootInstances"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "nat_route_failover" {
  function_name = var.name
  role          = aws_iam_role.nat_route_failover.arn
  handler       = "nat_route_failover.lambda_handler"
  runtime       = "python3.12"
  timeout       = 15

  filename = data.archive_file.nat_route_failover.output_path
  # python 파일 내용에 해쉬값을 붙여서 변경되었을 때만 lambda를 재배포하게 하는 설정
  source_code_hash = data.archive_file.nat_route_failover.output_base64sha256

  # lambda에서 환경변수로 읽을 값들
  # -> lambda.tf에서 nat_routes 블럭 안에 있는 값들을 json 형태로 변환해서 전달
  environment {
    variables = {
      NAT_ROUTES = jsonencode(var.nat_routes)
    }
  }

  tags = var.tags
}


resource "aws_iam_role" "nat_egress_check" {
  name = "${var.egress_check.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "nat_egress_check_basic_execution" {
  role       = aws_iam_role.nat_egress_check.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "nat_egress_check_vpc_access" {
  role       = aws_iam_role.nat_egress_check.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "nat_egress_check_put_metric" {
  name = "${var.egress_check.name}-put-metric"
  role = aws_iam_role.nat_egress_check.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["cloudwatch:PutMetricData"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "MGPZZ/NAT"
          }
        }
      }
    ]
  })
}

resource "aws_security_group" "nat_egress_check" {
  name        = "${var.egress_check.name}-sg"
  description = "Outbound access for NAT egress checks"
  vpc_id      = var.egress_check.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_lambda_function" "nat_egress_check" {
  for_each = var.egress_check.targets

  function_name = "${var.egress_check.name}-${each.key}"
  role          = aws_iam_role.nat_egress_check.arn
  handler       = "nat_egress_check.lambda_handler"
  runtime       = "python3.12"
  timeout       = 15
  memory_size   = 128

  filename         = data.archive_file.nat_egress_check.output_path
  source_code_hash = data.archive_file.nat_egress_check.output_base64sha256

  vpc_config {
    subnet_ids         = [each.value.subnet_id]
    security_group_ids = [aws_security_group.nat_egress_check.id]
  }

  environment {
    variables = {
      NAT_NAME  = each.key
      PROBE_IPS = join(",", var.egress_check.probe_ips)
    }
  }

  tags = var.tags
}

resource "aws_cloudwatch_event_rule" "nat_egress_check_every_minute" {
  name                = "${var.egress_check.name}-every-minute"
  description         = "Runs NAT egress checks every minute"
  schedule_expression = "rate(1 minute)"
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "nat_egress_check" {
  for_each = var.egress_check.targets

  rule = aws_cloudwatch_event_rule.nat_egress_check_every_minute.name
  arn  = aws_lambda_function.nat_egress_check[each.key].arn
}

resource "aws_lambda_permission" "nat_egress_check_eventbridge" {
  for_each = var.egress_check.targets

  statement_id  = "AllowEventBridge-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nat_egress_check[each.key].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.nat_egress_check_every_minute.arn
}
