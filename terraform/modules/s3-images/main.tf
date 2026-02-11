
resource "aws_s3_bucket" "images" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = merge(var.tags, {
    Component = "Images"
  })
}


resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_versioning" "images" {
  bucket = aws_s3_bucket.images.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_cors_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag", "x-amz-meta-custom-header"]
    max_age_seconds = 3600
  }
}


resource "aws_s3_bucket_lifecycle_configuration" "images" {
  count  = var.enable_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.images.id

  # Rule 1: Chuyen anh cu sang Standard-IA sau 90 ngay
  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    # filter {} rong = ap dung cho TAT CA objects trong bucket
    # Bat buoc tu AWS provider v5+ (truoc day la optional)
    filter {}

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
  }

  # Rule 2: Xoa old versions sau 30 ngay (chi khi versioning bat)
  rule {
    id     = "cleanup-old-versions"
    status = var.enable_versioning ? "Enabled" : "Disabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  # Phai tao versioning truoc lifecycle (lifecycle tham chieu version status)
  depends_on = [aws_s3_bucket_versioning.images]
}


resource "aws_s3_bucket_server_side_encryption_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}
