# ==============================================================================
# Root Variables - Coffee Shop Infrastructure
# ==============================================================================
# Doc: https://developer.hashicorp.com/terraform/language/values/variables
#
# Variables cho phep truyen gia tri tu ben ngoai vao Terraform configuration.
# Co 3 cach truyen gia tri:
#   1. File terraform.tfvars hoac -var-file (tu dong/chi dinh)
#   2. Command line: terraform apply -var="project_name=Coffee"
#   3. Environment variable: TF_VAR_project_name=Coffee
#
# GUIDE: Chi can thay doi gia tri trong file .tfvars, KHONG can sua code.
#   - Muc "NAMING": Dat ten tai nguyen AWS (bucket, lambda, API, ...)
#   - Muc "AWS CONFIG": Cau hinh region, stage
#   - Muc "SECURITY": Secrets, authentication
#   - Muc "RESOURCE BEHAVIOR": Toggle features on/off
# ==============================================================================

# ==============================================================================
# NAMING - Dat ten cac tai nguyen AWS
# ==============================================================================
# Thay doi cac bien nay de dat ten tai nguyen theo y muon.
# `project_name` la PREFIX chung, cac ten khac duoc tu dong sinh ra.
# ==============================================================================

variable "project_name" {
  description = "Ten du an, dung lam prefix cho tat ca tai nguyen (IAM, Lambda, API, DynamoDB)"
  type        = string
  default     = "Coffee"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9]{1,19}$", var.project_name))
    error_message = "project_name chi chua chu cai va so, bat dau bang chu cai, toi da 20 ky tu."
  }
}

variable "frontend_bucket_name" {
  description = "Ten S3 bucket cho frontend (phai globally unique tren toan AWS)"
  type        = string

  validation {
    condition     = length(var.frontend_bucket_name) >= 3 && length(var.frontend_bucket_name) <= 63
    error_message = "S3 bucket name phai tu 3 den 63 ky tu."
  }
}

variable "images_bucket_name" {
  description = "Ten S3 bucket chua anh san pham (phai globally unique)"
  type        = string
  default     = "coffee-shop-images"
}

# ==============================================================================
# AWS CONFIGURATION - Region, stage
# ==============================================================================

variable "aws_region" {
  description = "AWS Region de deploy infrastructure"
  type        = string
  default     = "ap-southeast-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "Region phai theo format: ap-southeast-1, us-east-1, etc."
  }
}

variable "stage_name" {
  description = "API Gateway stage name (prod, dev, staging)"
  type        = string
  default     = "prod"
}

# ==============================================================================
# SECURITY - Secrets, authentication
# ==============================================================================

variable "jwt_secret" {
  description = "Secret key cho JWT token signing (KHONG commit vao git!)"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.jwt_secret) >= 16
    error_message = "JWT secret phai it nhat 16 ky tu de dam bao bao mat."
  }
}

# ==============================================================================
# RESOURCE BEHAVIOR - Toggle features, performance tuning
# ==============================================================================

variable "force_destroy" {
  description = "Cho phep xoa S3 bucket ngay ca khi con objects (true cho dev)"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "So ngay giu CloudWatch Logs (7=dev, 30=prod)"
  type        = number
  default     = 7
}

variable "lambda_timeout" {
  description = "Lambda timeout tinh bang giay (mac dinh 30s cho API operations)"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda memory tinh bang MB (128-10240)"
  type        = number
  default     = 128
}

# --- DynamoDB ---

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode: PAY_PER_REQUEST (dev) hoac PROVISIONED (prod)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "enable_point_in_time_recovery" {
  description = "Bat Point-in-Time Recovery cho DynamoDB tables (nen bat cho production)"
  type        = bool
  default     = false
}

# --- S3 Images ---

variable "enable_versioning" {
  description = "Bat S3 versioning cho images bucket"
  type        = bool
  default     = false
}

variable "enable_lifecycle" {
  description = "Bat lifecycle rules cho images bucket (chuyen storage class, don dep old versions)"
  type        = bool
  default     = false
}

variable "cors_allowed_origins" {
  description = "Danh sach domains duoc phep upload anh via CORS. Dev: [\"*\"], Prod: [\"https://yourdomain.com\"]"
  type        = list(string)
  default     = ["*"]
}
