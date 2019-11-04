variable "bucketName"{
	description = "Enter Bucket Name like dev.bhfatnani.me"
}


resource "aws_s3_bucket" "bucket" {
  bucket = var.bucketName
  acl = "private"
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  
  force_destroy = true

  lifecycle_rule {
    enabled = "true"

    transition {
      days = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days = 60
      storage_class = "GLACIER"
    }
  }
}
