module "vpc" {
  source             = "./infrastructure_modules/vpc"
  project_name       = var.project_name
  vpc_cidr_block     = var.vpc_cidr_block
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  availability_zones = var.availability_zones
}

module "messaging" {
  source            = "./infrastructure_modules/messaging"
  project_name      = var.project_name
  raw_bucket_name   = var.raw_bucket_name
  thumb_bucket_name = var.thumb_bucket_name
}

module "lambda_pub" {
  source          = "./infrastructure_modules/lambda_publisher"
  project_name    = var.project_name
  sns_topic_arn   = module.messaging.sns_topic_arn
  raw_bucket_name = module.messaging.raw_bucket_name
}

module "eks" {
  source = "./infrastructure_modules/eks_consumer"

  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  # node settings
  eks_node_count         = var.eks_node_count
  eks_node_instance_type = var.eks_node_instance_type
  ecr_repo_name          = var.ecr_repo_name # or "${var.project_name}-consumer"

  # messaging inputs — pass the ARN (not the queue URL) if module requires it
  sqs_queue_arn = module.messaging.sqs_queue_arn

  # buckets
  raw_bucket_name   = module.messaging.raw_bucket_name
  thumb_bucket_name = module.messaging.thumb_bucket_name
}
