# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name               = "${var.project_name}-lambda-pub-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    effect = "Allow"
  }
}

# inline policy to allow publish to SNS and read S3
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-pub-policy"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect   = "Allow",
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "*"
      },
      { Effect   = "Allow",
        Action   = ["s3:GetObject"],
        Resource = "arn:aws:s3:::${var.raw_bucket_name}/*"
      },
      { Effect   = "Allow",
        Action   = ["sns:Publish"],
        Resource = var.sns_topic_arn
      }
    ]
  })
}

# package the python lambda (archive_file expects local files)
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_code"
  output_path = "${path.module}/lambda_code/publisher.zip"
}

resource "aws_lambda_function" "publisher" {
  function_name = "${var.project_name}-s3-publisher"
  role          = aws_iam_role.lambda_role.arn
  handler       = "publisher.handler"
  runtime       = "python3.9"
  filename      = data.archive_file.lambda_zip.output_path
  timeout       = 10
  memory_size   = 128
  environment { variables = { SNS_TOPIC_ARN = var.sns_topic_arn } }
}

# S3 notification to Lambda (raw-images bucket)
resource "aws_s3_bucket_notification" "raw_to_lambda" {
  bucket = var.raw_bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.publisher.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "raw-images/" # only react to objects in raw-images/
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.publisher.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.raw_bucket_name}"
}
