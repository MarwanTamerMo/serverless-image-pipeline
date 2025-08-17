variable region {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "eu-central-1"
}

variable "s3_bucket" {
  description = "The name of the S3 bucket to store the state file in"
  type        = string
  default     = "terraforms3marobucket"
  
}

variable "dynamodb_table" {
  description = "The name of the DynamoDB table for state locking"
  type        = string
  default     = "terraform-locks"
}