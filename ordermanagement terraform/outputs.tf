output "rds_endpoint" {
  value = aws_db_instance.mysql.endpoint
}

output "rds_dbname" {
  value = var.db_name
}

output "bucket_name" {
  description = "The name of the S3 bucket."
  value       = aws_s3_bucket.customer_docs.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket."
  value       = aws_s3_bucket.customer_docs.arn
}

output "sqs_queue_url" {
  description = "The URL of the created SQS queue."
  value       = aws_sqs_queue.file_events.url
}

output "ses_from_email" {
  value = aws_ses_email_identity.from_email.email
}