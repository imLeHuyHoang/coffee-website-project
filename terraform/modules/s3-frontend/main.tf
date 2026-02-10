# ==============================================================================
# S3 Frontend Module - Static Website Hosting
# ==============================================================================
# Doc goc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
#
# Module nay tao:
#   1. S3 Bucket: chua cac file frontend (HTML, CSS, JS, images)
#   2. Website Configuration: cho phep S3 phuc vu nhu mot web server
#   3. Public Access: mo quyen public read de user truy cap duoc
#   4. Bucket Policy: chi cho phep doc (GetObject), khong cho ghi/xoa
#
# Kien thuc nen:
#   - S3 Bucket la noi luu tru objects (files) tren AWS
#   - Static Website Hosting bien S3 bucket thanh web server (HTTP only)
#   - Browser truy cap URL -> S3 tra ve file tuong ung (index.html, style.css, etc.)
#   - SPA (Single Page App) can error_document = index.html de React Router xu ly routing
#
# QUAN TRONG - Terraform AWS Provider 4.x breaking changes:
#   Tu provider v4+, cac config truoc day dat TRONG aws_s3_bucket (inline)
#   da bi deprecated. Phai dung RESOURCE RIENG cho moi config:
#   - aws_s3_bucket_website_configuration  (thay cho website {} block)
#   - aws_s3_bucket_public_access_block    (thay cho block_public_access)
#   - aws_s3_bucket_policy                 (thay cho policy attribute)
#   Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-4-upgrade
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. S3 Bucket
# ------------------------------------------------------------------------------
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
#
# `bucket` (optional nhung nen dat): Ten bucket, phai GLOBALLY UNIQUE tren toan AWS
# Neu khong dat -> AWS tu sinh ten random (kho nho, kho quan ly)
#
# `force_destroy` = true: Cho phep Terraform xoa bucket NGAY CA KHI con objects ben trong
# Mac dinh = false -> Terraform se bao loi khi xoa bucket co objects
# Trong dev/learning: true la tien loi. Trong production: can than!
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "frontend" {
  bucket = var.bucket_name

  # force_destroy = true -> terraform destroy se xoa bucket + tat ca objects
  # Neu false, phai xoa het objects truoc khi destroy bucket
  force_destroy = var.force_destroy

  tags = merge(var.tags, {
    Component = "Frontend"
  })
}

# ------------------------------------------------------------------------------
# 2. S3 Static Website Hosting Configuration
# ------------------------------------------------------------------------------
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration
#
# Bat "Static website hosting" feature cua S3.
# Khi bat, S3 se phuc vu files qua HTTP endpoint:
#   http://{bucket-name}.s3-website-{region}.amazonaws.com
#
# `index_document`: File tra ve khi user truy cap root URL (/)
# `error_document`: File tra ve khi khong tim thay file (404)
#
# TAI SAO error_document = index.html?
# React la SPA (Single Page Application) - chi co 1 file HTML.
# Khi user truy cap /products, /cart -> S3 tim file "products" -> khong co -> 404
# Nhung neu error_document = index.html -> S3 tra ve index.html
# -> React Router chay va render dung component cho /products, /cart
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# ------------------------------------------------------------------------------
# 3. Tat chuc nang Block Public Access
# ------------------------------------------------------------------------------
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block
#
# Mac dinh, AWS BLOCK tat ca public access vao S3 bucket (bao mat).
# De host static website, ta CAN public access (ai cung co the doc website).
# Nen ta phai TAT (= false) cac setting nay.
#
# 4 settings:
#   block_public_acls       = Chặn thêm ACL công khai (Access Control List)
#   ignore_public_acls      = Bỏ qua ACL công khai đã có
#   block_public_policy     = Chặn thêm bucket policy công khai
#   restrict_public_buckets = Giới hạn truy cập từ bucket policy công khai
#
# Tat ca = false -> cho phep public access qua bucket policy
# Chi nen lam voi bucket THUC SU can public (website hosting)
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ------------------------------------------------------------------------------
# 4. Bucket Policy - Cho phep public read
# ------------------------------------------------------------------------------
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy
# Doc IAM Policy: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements.html
#
# Bucket Policy = IAM Policy nhung gan truc tiep vao S3 bucket.
# Policy nay cho phep BAT KY AI (Principal = "*") doc bat ky file nao trong bucket.
#
# `depends_on`: Dam bao public_access_block duoc tao/cap nhat TRUOC khi apply bucket policy.
# Neu khong co depends_on, Terraform co the tao policy truoc khi tat block
# -> AWS se REJECT policy vi block_public_policy van dang = true
# -> Terraform bao loi "AccessDenied"
#
# Day la mot vi du dien hinh cua "implicit vs explicit dependency" trong Terraform:
# Doc: https://developer.hashicorp.com/terraform/language/meta-arguments/depends_on
# ------------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })

  # QUAN TRONG: Phai doi public_access_block tat xong moi apply policy
  depends_on = [aws_s3_bucket_public_access_block.frontend]
}
