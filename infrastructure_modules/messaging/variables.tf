variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
}
variable "raw_bucket_name" {
  description = "Name of the raw images S3 bucket"
  type        = string
  default     = "raw-images-bucket"
}
variable "thumb_bucket_name" {
  description = "Name of the thumbnails S3 bucket (optional)"
  type        = string
}
