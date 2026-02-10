# ==============================================================================
# S3 Images Module - Product Image Storage
# ==============================================================================
# Doc goc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
#
# Module nay tao:
#   1. S3 Bucket:  Luu tru anh san pham (product images)
#   2. CORS Config: Cho phep frontend upload anh truc tiep (presigned URL)
#   3. Lifecycle:  Tu dong chuyen anh cu sang storage class re hon
#   4. Versioning: Giu lich su cac phien ban cua anh
#
# KHAC BIET voi S3 Frontend module:
#   - Frontend bucket: PUBLIC (ai cung doc duoc website)
#   - Images bucket:   PRIVATE (chi Lambda/presigned URL moi truy cap duoc)
#   - Frontend khong can CORS (browser truy cap truc tiep)
#   - Images CAN CORS (browser upload anh tu frontend domain)
#
# Kien thuc nen:
#   - S3 Object Lifecycle: Tu dong chuyen objects sang storage class re hon theo thoi gian
#     Standard -> Standard-IA (Infrequent Access) -> Glacier
#     Doc: https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html
#   - S3 Versioning: Giu tat ca phien ban cua object (phong truong hop xoa nham)
#     Doc: https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html
#   - S3 CORS: Cho phep browser tai domain A upload file len S3
#     Doc: https://docs.aws.amazon.com/AmazonS3/latest/userguide/cors.html
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. S3 Bucket
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "images" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  tags = merge(var.tags, {
    Component = "Images"
  })
}

# ------------------------------------------------------------------------------
# 2. Block Public Access - GIU NGUYEN (PRIVATE bucket)
# ------------------------------------------------------------------------------
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
#
# KHAC voi Frontend bucket (tat het block):
# Images bucket KHONG can public access!
# Chi Lambda co quyen doc/ghi (qua IAM policy da tao o module IAM)
# Va frontend co the dung presigned URLs de upload (khong can public)
#
# Tat ca = true -> KHONG AI co the mo public access
# Day la BEST PRACTICE bao mat cho bucket chua data
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "images" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# 3. Versioning
# ------------------------------------------------------------------------------
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning
#
# Bat versioning de:
#   - Giu lich su thay doi anh (khong mat data khi upload de)
#   - Phuc hoi anh bi xoa nham (xoa chi tao "delete marker", file van con)
#   - Ket hop voi lifecycle policy de tu dong don dep old versions
#
# Luu y: Versioning chi co the BAT hoac SUSPEND, KHONG THE TAT hoan toan
# sau khi da bat. Suspend = ngung tao version moi, nhung versions cu van ton tai.
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_versioning" "images" {
  bucket = aws_s3_bucket.images.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# ------------------------------------------------------------------------------
# 4. CORS Configuration
# ------------------------------------------------------------------------------
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration
#
# Khi user upload anh tu frontend (browser):
#   Browser tai domain http://frontend.s3-website.amazonaws.com
#   Upload anh len   https://images-bucket.s3.amazonaws.com
#   -> Khac domain -> CORS can thiet!
#
# CORS rules:
#   allowed_origins: Domain nao duoc phep (["*"] = tat ca, production nen gioi han)
#   allowed_methods: HTTP methods (GET de xem, PUT de upload, DELETE de xoa)
#   allowed_headers: Headers browser duoc phep gui
#   max_age_seconds: Browser cache CORS response bao lau (3600 = 1 gio)
#
# `dynamic` block o day cho phep BAT/TAT CORS tuy vao variable
# Neu cors_allowed_origins rong -> khong tao CORS rule nao
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# 5. Lifecycle Rules - Tu dong toi uu chi phi storage
# ------------------------------------------------------------------------------
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration
#
# S3 co nhieu Storage Classes voi gia khac nhau:
#   Standard:     $0.025/GB/thang  (truy cap thuong xuyen)
#   Standard-IA:  $0.0125/GB/thang (truy cap khong thuong xuyen)
#   Glacier:      $0.004/GB/thang  (luu tru dai han, truy cap cham)
#
# Lifecycle Rules TU DONG chuyen objects giua cac classes:
#   - Anh upload > 90 ngay -> chuyen sang Standard-IA (re 50%)
#   - Old versions > 30 ngay -> xoa (don dep phien ban cu)
#
# `noncurrent_version_expiration`: Chi ap dung cho versions CU (khong phai current)
# Khi versioning bat, moi lan upload de -> version cu tro thanh "noncurrent"
# Rule nay xoa noncurrent versions sau 30 ngay -> tiet kiem storage
#
# CONDITIONAL: Chi tao lifecycle rules khi enable_lifecycle = true
# Doc count: https://developer.hashicorp.com/terraform/language/meta-arguments/count
#
# `count` la mot cach KHAC de tao/khong tao resource (ngoai for_each):
#   count = 1 -> tao resource
#   count = 0 -> KHONG tao resource (nhu if-else)
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# 6. Server-Side Encryption
# ------------------------------------------------------------------------------
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration
#
# Ma hoa tat ca objects khi luu tru. AWS tu dong giai ma khi doc.
# AES256 (SSE-S3): AWS quan ly key, MIEN PHI. Khong can config them gi.
# aws:kms: Dung AWS KMS key, linh hoat hon nhung ton them phi (~$1/key/thang)
#
# Tu thang 1/2023, AWS tu dong ma hoa TAT CA S3 objects bang SSE-S3.
# Nhung Terraform KHONG biet dieu nay -> viet ra de lam ro y dinh (explicit).
# Doc: https://aws.amazon.com/blogs/aws/amazon-s3-encrypts-new-objects-by-default/
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "images" {
  bucket = aws_s3_bucket.images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}
