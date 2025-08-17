variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "eks_node_instance_type" {
  type    = string
  default = "t3.small"
}

variable "eks_node_count" {
  type    = number
  default = 1
}

variable "ecr_repo_name" {
  description = "ECR repository name for the consumer app"
  type        = string
  default     = "sprints-consumer"
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS queue for the consumer"
  type        = string
}

variable "raw_bucket_name" {
  type = string
}

variable "thumb_bucket_name" {
  type = string
}

# K8s location of the consumer pod
variable "consumer_namespace" {
  type        = string
  default     = "default"
  description = "Kubernetes namespace for the consumer workload"
}

variable "consumer_service_account" {
  type        = string
  default     = "consumer-sa"
  description = "Kubernetes service account used by the consumer pod"
}

# Names for created IAM entities
variable "consumer_policy_name" {
  type        = string
  default     = "consumer-sqs-s3-policy"
  description = "IAM policy name for consumer permissions"
}

variable "consumer_role_name" {
  type        = string
  default     = "consumer-irsa-role"
  description = "IAM role name assumed via IRSA"
}
