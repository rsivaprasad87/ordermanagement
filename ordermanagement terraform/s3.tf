# ----------------------------
# S3 Bucket for File Uploads
# ----------------------------
resource "aws_s3_bucket" "customer_docs" {
  bucket        = "${var.project_name}-documents-${random_id.bucket_id.hex}"
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-s3"
    Environment = "Development"
  }
}

resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.customer_docs.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
