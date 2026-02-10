# ==============================================================================
# Lambda Layer Module - Shared Dependencies
# ==============================================================================
# Doc goc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version
#
# Module nay tao:
#   1. Lambda Layer chua bcryptjs + jsonwebtoken (dung cho auth functions)
#
# Kien thuc nen:
#   - Lambda Layer = goi shared code/dependencies dung chung giua nhieu functions
#   - Thay vi moi function phai package kem node_modules (nang, trung lap),
#     ta tao 1 Layer chua dependencies va attach vao cac functions can
#   - Layer duoc mount tai /opt/nodejs/ trong Lambda runtime
#   - Khi Lambda chay, Node.js tu dong tim modules trong /opt/nodejs/node_modules/
#   - Moi Layer co VERSION (1, 2, 3...) - moi lan update tao version moi
#
# Cau truc ZIP cua Layer (BAT BUOC theo dung format):
#   nodejs/
#     package.json
#     node_modules/
#       bcryptjs/
#       jsonwebtoken/
#  
# Doc them: https://docs.aws.amazon.com/lambda/latest/dg/chapter-layers.html
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Dong goi layer thanh file .zip
# ------------------------------------------------------------------------------
# Doc: https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file
#
# `data "archive_file"` KHONG phai resource - no la DATA SOURCE
# Data source doc thong tin tu he thong, khong tao gi tren AWS
# archive_file dong goi thu muc thanh .zip file -> dung de upload len Lambda
#
# `source_dir`: Thu muc nguon (chua nodejs/package.json + node_modules)
# `output_path`: Noi luu file .zip
# `type`: Dinh dang nen (zip, tar.gz, etc.)
#
# LUU Y: Ban phai chay `npm install` TRUOC trong thu muc layer-src/nodejs/
# Terraform khong tu dong install npm packages!
# Xem README hoac TERRAFORM_LAB.md de biet cach setup.
# ------------------------------------------------------------------------------
data "archive_file" "layer" {
  type        = "zip"
  source_dir  = var.layer_source_dir
  output_path = "${path.module}/builds/layer.zip"
}

# ------------------------------------------------------------------------------
# 2. Lambda Layer Version
# ------------------------------------------------------------------------------
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version
#
# `layer_name`: Ten cua Layer (hien thi trong AWS Console)
# `filename`: Duong dan toi file .zip local
# `source_code_hash`: Hash cua file zip - Terraform dung de PHAT HIEN THAY DOI
#   Neu hash khong doi -> Terraform SKIP upload (tiet kiem thoi gian)
#   Neu hash thay doi -> Terraform tao version moi
#
# `compatible_runtimes`: Danh sach runtimes ho tro
#   Layer chi co the attach vao functions dung runtime tuong thich
#
# `compatible_architectures`: CPU architecture (x86_64 hoac arm64)
#   Lambda chay tren x86_64 mac dinh
# ------------------------------------------------------------------------------
resource "aws_lambda_layer_version" "dependencies" {
  layer_name          = var.layer_name
  filename            = data.archive_file.layer.output_path
  source_code_hash    = data.archive_file.layer.output_base64sha256
  compatible_runtimes = [var.runtime]

  description = "Shared npm packages: bcryptjs, jsonwebtoken"
}
