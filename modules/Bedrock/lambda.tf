# 0. Lambda 소스코드를 자동으로 zip 패키징
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda_function.zip"
}

# 1. 기존에 존재하는 S3 버킷 참조
data "aws_s3_bucket" "existing_bucket" {
  bucket = "coreon"
}

# 2. Lambda 함수 정의 (기존 함수가 있다면 data로, 새로 만든다면 resource로)
resource "aws_lambda_function" "pdf_processor" {
  function_name = "coreon-pdf-summarizer"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  memory_size = 512
  timeout     = 60

  tags = {
    Project     = "coreon"
    Environment = "stage"
    ManagedBy   = "terraform"
  }

  environment {
    variables = {
      BEDROCK_MODEL_ID = "global.anthropic.claude-haiku-4-5-20251001-v1:0"
    }
  }
}

# 3. S3 서비스가 Lambda를 호출할 수 있도록 권한 추가
resource "aws_lambda_permission" "allow_s3_trigger" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pdf_processor.function_name
  principal     = "s3.amazonaws.com"
  
  # 특정 버킷에서 오는 요청만 허용 (보안 강화)
  source_arn    = data.aws_s3_bucket.existing_bucket.arn
}

# 4. 기존 버킷에 이벤트 알림 설정
resource "aws_s3_bucket_notification" "board_notification" {
  bucket = data.aws_s3_bucket.existing_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.pdf_processor.arn
    events              = ["s3:ObjectCreated:*"]
    
    # 요청하신 폴더 경로 및 확장자 필터
    filter_prefix       = "board/"
    filter_suffix       = ".pdf"
  }

  depends_on = [aws_lambda_permission.allow_s3_trigger]
}