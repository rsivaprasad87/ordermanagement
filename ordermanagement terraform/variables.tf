variable "aws_region" {
  default = "ap-south-1"
}

variable "project_name" {
  default = "ordermanagement"
}

variable "db_instance_identifier" {
  description = "Identifier for the RDS instance"
  type        = string
  default     = "ordermanagement-rds"
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "customerdb"
}

variable "db_username" {
  description = "RDS DB username"
  default     = "admin"
}


variable "db_password" {
  description = "RDS DB password"
  default     = "******"
  sensitive   = true
}

variable "ses_from_email" {
  description = "Verified SES email address"
  default     = "abc@gmail.com"
}


variable "app_file" {
  description = "Name of Spring Boot app jar file"
  default     = "ordermanagement-1.0.0.zip"
}