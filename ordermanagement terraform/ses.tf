# SES (Simple Email Service)
# ----------------------------
# Verify an email identity (sender address)
resource "aws_ses_email_identity" "from_email" {
  email = var.ses_from_email
}