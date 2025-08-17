output "raw_bucket" {
  value = module.messaging.raw_bucket_name
}
output "thumb_bucket" {
  value = module.messaging.thumb_bucket_name
}
output "sns_topic_arn" {
  value = module.messaging.sns_topic_arn
}
output "sqs_queue_url" {
  value = module.messaging.sqs_queue_url
}
output "ecr_repo" {
  value = module.eks.ecr_repo_url
}
output "eks_cluster_name" {
  value = module.eks.cluster_name
}
