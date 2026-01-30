terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_s3_bucket" "test_bucket" {
  bucket = "tf-test-yeram-20260130"  # 전세계 유일한 이름
}
