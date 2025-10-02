# Create an S3 bucket for the Lambda function code
resource "aws_s3_bucket" "lambda_code_bucket" {
  bucket        = "lambda-code-documents-${random_id.bucket_id.hex}"
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-s3-lambda-bucket"
    Environment = "Development"
  }
}

resource "aws_s3_bucket_public_access_block" "lambda_bucket_block_public_access" {
  bucket = aws_s3_bucket.lambda_code_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Upload the Lambda function code to S3
resource "aws_s3_object" "lambda_code" {
  bucket = aws_s3_bucket.lambda_code_bucket.id
  key    = "s3tosqsuploadlambda.zip"
  source = "./s3tosqsuploadlambda.zip"          # Replace with the actual path to your ZIP file
  etag   = filemd5("./s3tosqsuploadlambda.zip") # Replace with the actual path to your ZIP file
}

# Create an IAM role for the Lambda function
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_s3_sqs_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach AWSLambdaBasicExecutionRole policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::616640453658:policy/service-role/AWSLambdaBasicExecutionRole-1871db16-86a8-4a1a-a0c2-b7632122f0f3"
}

# Attach AmazonSQSFullAccess policy to the Lambda role
resource "aws_iam_role_policy_attachment" "sqs_full_access" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

# Create the Lambda function
resource "aws_lambda_function" "my_lambda_function" {
  function_name    = "S3TriggeredLambda"
  s3_bucket        = aws_s3_bucket.lambda_code_bucket.id
  s3_key           = aws_s3_object.lambda_code.key
  source_code_hash = aws_s3_object.lambda_code.etag
  handler          = "lambda_function.lambda_handler" # Replace with your Lambda handler (e.g. my_function.handler # Assuming your function is in my_function.py and the handler is named 'handler'  for Python)
  runtime          = "python3.12"                     # Replace with your desired runtime (e.g., 'python3.9')
  role             = aws_iam_role.lambda_exec_role.arn
  timeout          = 30
  memory_size      = 128
  environment {
    variables = {
      SQS_QUEUE_URL = aws_sqs_queue.file_events.id # The ID attribute of aws_sqs_queue is the Queue URL
    }
  }
}


# Grant S3 permission to invoke the Lambda function
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.customer_docs.arn
}

# Configure the S3 bucket notification to trigger the Lambda function
resource "aws_s3_bucket_notification" "s3_trigger_notification" {
  bucket = aws_s3_bucket.customer_docs.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.my_lambda_function.arn
    events              = ["s3:ObjectCreated:Put"]
  }
}