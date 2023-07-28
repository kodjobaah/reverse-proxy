###############################################################
### Store Terraform State in S3 bucket and DynamoDB Locking ###
###                 !!! WARNING !!!                         ###
### FOR NEW ENVIRONMENT YOU HAVE TO APPLY FOLLOWING STEPS:  ###
### 1. UPDATE FOLLOWING PARAMETERS ACCORDINLGY:             ###
###        aws_s3_bucket.terraform_state.bucket             ###
###        aws_dynamodb_table.terraform_lock.name           ###
###        backend.s3.bucket                                ###
###        backend.s3.region                                ###
###        backend.s3.dynamodb_table                        ###
### 2. APPLY aws_s3_bucket and aws_dynamodb_table resources ###
### 3. APPLY backend resource                               ###
###############################################################
### S3 Bucket for Shared Terraform State
provider "aws" {
  profile = "afriex"
  region  = "eu-west-2"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "afriex-terraform-webhook-codepipeline-state"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

### S3 block public access
resource "aws_s3_bucket_public_access_block" "terraform_state_block" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}
### DynamoDB for Locking ###
resource "aws_dynamodb_table" "terraform_lock" {
  name           = "webhook-terraform-lock-codepipeline"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

### Bucket and DynamoDB outputs
output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "The ARN of the S3 bucket"
}
output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_lock.name
  description = "The name of the DynamoDB table"
}
