# raw images bucket
resource "aws_s3_bucket" "raw" {
  bucket        = var.raw_bucket_name
  force_destroy = true
  tags          = { Name = "${var.project_name}-raw" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "raw" {
  bucket = aws_s3_bucket.raw.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# thumbnails bucket
resource "aws_s3_bucket" "thumbs" {
  bucket        = var.thumb_bucket_name
  force_destroy = true
  tags          = { Name = "${var.project_name}-thumbs" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "thumbs" {
  bucket = aws_s3_bucket.thumbs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# SNS topic
resource "aws_sns_topic" "topic" {
  name = "${var.project_name}-image-events"
}

# SQS queue
resource "aws_sqs_queue" "queue" {
  name          = "${var.project_name}-image-queue"
  delay_seconds = 0
}

# allow SNS -> SQS subscription
resource "aws_sns_topic_subscription" "sns_to_sqs" {
  topic_arn  = aws_sns_topic.topic.arn
  protocol   = "sqs"
  endpoint   = aws_sqs_queue.queue.arn
  depends_on = [aws_sqs_queue.queue, aws_sns_topic.topic]
}

# Give SQS permission for SNS to send messages
resource "aws_sqs_queue_policy" "allow_sns" {
  queue_url = aws_sqs_queue.queue.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "SQS:SendMessage"
        Resource  = aws_sqs_queue.queue.arn
        Condition = {
          ArnEquals = { "aws:SourceArn" = aws_sns_topic.topic.arn }
        }
      }
    ]
  })
}

# Allow S3 to publish events to the SNS topic
resource "aws_sns_topic_policy" "s3_event_policy" {
  arn    = aws_sns_topic.topic.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    effect  = "Allow"
    actions = ["SNS:Publish"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    resources = [aws_sns_topic.topic.arn]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.raw.arn]
    }
  }
}

# Configure the S3 bucket to send a notification on object creation
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.raw.id

  topic {
    topic_arn = aws_sns_topic.topic.arn
    events    = ["s3:ObjectCreated:*"]

    filter_prefix = "raw-images/"
    filter_suffix = ".jpg"
  }

  depends_on = [aws_sns_topic_policy.s3_event_policy]
}
