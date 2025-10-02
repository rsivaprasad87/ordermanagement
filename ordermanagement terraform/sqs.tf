# ----------------------------
# SQS Queue for File Events
# ----------------------------
resource "aws_sqs_queue" "file_events" {
  name                       = "${var.project_name}-file-events"
  message_retention_seconds  = 86400
  visibility_timeout_seconds = 30
  delay_seconds              = 0
  receive_wait_time_seconds  = 0
  # fifo_queue                = false # Default for standard queues
  # content_based_deduplication = false # Not applicable for standard queues
  tags = {
    Name        = "${var.project_name}-sqs"
    Environment = "Development"
  }
}