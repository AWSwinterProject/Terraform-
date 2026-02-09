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
          "arn:aws:bedrock:*:*:foundation-model/*",
          "arn:aws:bedrock:*:390403881443:inference-profile/*"
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