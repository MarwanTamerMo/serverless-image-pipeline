resource "aws_s3_bucket" "tfstate" {
    bucket = var.s3_bucket

    tags = {
    Name = "Terraform remote state ${var.s3_bucket}"
  }
  
}

resource "aws_s3_bucket_versioning" "s3_versioning" {
    
    bucket = aws_s3_bucket.tfstate.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_dynamodb_table" "tfstate_locks" {
    name         = var.dynamodb_table
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }

    tags = {
        Name = "Terraform state locks ${var.dynamodb_table}"
    }
}

