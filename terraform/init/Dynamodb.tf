# ---------------------------------------------------------------
# 파일 위치 : /home/user1/practical-project/infra/terraform/init/Dynamodb.tf
# ---------------------------------------------------------------

# DynamoDB 테이블 생성 - 동시 수정 방지(Lock)용
resource "aws_dynamodb_table" "terraform_lock" {
  name         = var.dynamodb_table_name # 테이블명
  billing_mode = "PAY_PER_REQUEST"       # 비용 지불 방식 (요청 개수당 과금)
  hash_key     = "LockID"                # Partition key
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Name = "Terraform State Lock Table"
  }

  lifecycle {
    prevent_destroy = true
  }
}
