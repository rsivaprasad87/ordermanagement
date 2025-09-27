# ----------------------------
# S3 bucket for EB app versions
# ----------------------------
resource "aws_s3_bucket" "eb_bucket" {
  bucket        = "${var.project_name}-eb-${random_id.bucket_id.hex}"
  force_destroy = true
}

# Upload application bundle
resource "aws_s3_object" "app_version" {
  bucket = aws_s3_bucket.eb_bucket.id
  key    = var.app_file
  source = "./${var.app_file}"
  etag   = filemd5("./${var.app_file}")
}

# ----------------------------
# IAM roles for Elastic Beanstalk
# ----------------------------
resource "aws_iam_role" "eb_ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = { Service = "ec2.amazonaws.com" }
        Effect    = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_role_attach" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}


resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = "${var.project_name}-instance-profile"
  role = aws_iam_role.eb_ec2_role.name
}

resource "aws_iam_role_policy_attachment" "sqs_access" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "ses_access" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
}

resource "aws_iam_role" "eb_service_role" {
  name = "${var.project_name}-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "elasticbeanstalk.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "elasticbeanstalk_managed_updates_policy" {
  role       = aws_iam_role.eb_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy"
}


resource "aws_iam_role_policy_attachment" "eb_health_policy" {
  role       = aws_iam_role.eb_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

# ----------------------------
# Elastic Beanstalk App & Version
# ----------------------------
resource "aws_elastic_beanstalk_application" "app" {
  name        = var.project_name
  description = "Spring Boot app deployed with Terraform"
}

resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = "v1"
  application = aws_elastic_beanstalk_application.app.name
  bucket      = aws_s3_bucket.eb_bucket.bucket
  key         = aws_s3_object.app_version.key
}

# ----------------------------
# Elastic Beanstalk Environment
# ----------------------------
resource "aws_elastic_beanstalk_environment" "env" {
  name                = "${var.project_name}-env"
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.9.5 running Corretto 17"
  version_label       = aws_elastic_beanstalk_application_version.app_version.name
  tier                = "WebServer"

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.eb_service_role.arn
  }

  setting {
    namespace = "aws:ec2:instances"
    name      = "InstanceTypes"
    value     = "t2.micro"
  }

  # Inject environment variables for app
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_REGION"
    value     = var.aws_region
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_URL"
    value     = "jdbc:mysql://${aws_db_instance.mysql.endpoint}/${var.db_name}"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_USERNAME"
    value     = var.db_username
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_PASSOWRD"
    value     = var.db_password
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "S3_BUCKET_NAME"
    value     = aws_s3_bucket.customer_docs.id
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "QUEUE_URL"
    value     = aws_sqs_queue.file_events.url
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SES_SENDER_EMAIL"
    value     = aws_ses_email_identity.from_email.email
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PORT"
    value     = "8080" # This tells your application to listen on 8080
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "ListenerEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "ListenerProtocol"
    value     = "HTTP"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "InstancePort"
    value     = "8080" # The port the load balancer forwards to on the instance
  }
}
