# Lambda 실행 역할
resource "aws_iam_role" "lambda_exec" {
  name = "coreon-pdf-processor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project     = "coreon"
    Environment = "stage"
    ManagedBy   = "terraform"
  }
}

# CloudWatch Logs 권한
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# S3 및 Bedrock 권한 정책
# S3, Bedrock 및 Marketplace 권한 정책
resource "aws_iam_role_policy" "lambda_s3_bedrock" {
  name = "coreon-pdf-processor-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ReadWrite"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${data.aws_s3_bucket.existing_bucket.arn}/board/*",
          "${data.aws_s3_bucket.existing_bucket.arn}/summary/*"
        ]
      },
      {
        Sid    = "BedrockInvoke"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          # 1. 로그에서 거부된 기초 모델 경로 (리전/계정번호 없음)
          "arn:aws:bedrock:::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0",
          # 2. 이미지 속 공식 인퍼런스 프로파일 경로 (us-east-1 기반)
          "arn:aws:bedrock:us-east-1:390403881443:inference-profile/global.anthropic.claude-haiku-4-5-20251001-v1:0",
          # 3. 서울 리전에서 호출을 인식하기 위한 경로
          "arn:aws:bedrock:ap-northeast-2:390403881443:inference-profile/global.anthropic.claude-haiku-4-5-20251001-v1:0",
          # 4. 안전한 작동을 위한 와일드카드 추가 (권장) 해당 권한 추가 결과 인식성공
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-haiku-4-5*",
          "arn:aws:bedrock:*:390403881443:inference-profile/global.*"

        ]
      },
      # 💡 아래 Marketplace 권한이 추가되어야 에러가 해결됩니다.
      {
        Sid    = "MarketplaceAccess"
        Effect = "Allow"
        Action = [
          "aws-marketplace:ViewSubscriptions",
          "aws-marketplace:Subscribe"
        ]
        Resource = "*"
      }
    ]
  })
}