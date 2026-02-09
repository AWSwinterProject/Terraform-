# 1. ECR 프라이빗 리포지토리 생성
resource "aws_ecr_repository" "coreon_repo" {
  for_each = toset(["auth", "board", "member", "notice", "faq", "nginx", "front", "redis"])
  name     = "coreon-${each.key}"
}

# 2. 수명 주기 정책 설정
resource "aws_ecr_lifecycle_policy" "coreon_policy" {
  for_each   = aws_ecr_repository.coreon_repo
  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "최신 10개의 이미지만 유지하고 나머지는 삭제"
        selection = {
          tagStatus     = "any"           # 태그 유무와 상관없이 적용
          countType     = "imageCountMoreThan"
          countNumber   = 10              # 보관할 최대 이미지 개수
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
