output "raw_bucket_name" {
  value = aws_s3_bucket.raw.bucket
}

output "thumb_bucket_name" {
  value = aws_s3_bucket.thumbs.bucket
}

output "sns_topic_arn" {
  value = aws_sns_topic.topic.arn
}

output "sqs_queue_url" {
  value = aws_sqs_queue.queue.id
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.queue.arn
}
