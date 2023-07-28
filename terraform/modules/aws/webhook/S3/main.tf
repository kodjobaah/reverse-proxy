resource "aws_s3_bucket" "webhook" {
  bucket = "afriex-webhook-documents-${var.env}"
  tags = {
    Name        = "afriex-webhook-documents-${var.env}"
    Environment = var.env
  }
}
