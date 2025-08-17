variable "aws_region" {
  description = "AWS region to deploy in"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDRs"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

# Messaging / S3
variable "raw_bucket_name" {
  description = "S3 bucket name for raw uploads"
  type        = string
}
variable "thumb_bucket_name" {
  description = "S3 bucket name for thumbnails"
  type        = string
}

variable "sns_topic_name" {
  description = "Optional SNS topic name (if you want to override default)"
  type        = string
}

variable "sqs_queue_name" {
  description = "Optional SQS queue name (if you want to override default)"
  type        = string
}

# Lambda settings
variable "lambda_memory" {
  type    = number
  default = 128
}
variable "lambda_timeout" {
  type    = number
  default = 10
}
variable "lambda_runtime" {
  type    = string
  default = "python3.9"
}

# ECR / EKS
variable "ecr_repo_name" {
  description = "ECR repository name for the consumer app"
  type        = string
  default     = "sprints-consumer"
}

variable "eks_node_instance_type" {
  description = "EKS node EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "eks_node_count" {
  description = "EKS node group desired count"
  type        = number
  default     = 1
}

# Consumer runtime
variable "consumer_image_tag" {
  type    = string
  default = "latest"
}
variable "consumer_replicas" {
  type    = number
  default = 1
}

