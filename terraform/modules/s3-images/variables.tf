# ==============================================================================
# S3 Images Module Variables
# ==============================================================================

variable "bucket_name" {
  description = "Ten S3 bucket cho product images (phai globally unique)"
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "S3 bucket name phai tu 3 den 63 ky tu."
  }
}

variable "force_destroy" {
  description = "Cho phep xoa bucket ngay ca khi con objects (true cho dev)"
  type        = bool
  default     = true
}

variable "enable_versioning" {
  description = "Bat S3 versioning (giu lich su thay doi anh, nen bat cho production)"
  type        = bool
  default     = false
}

variable "enable_lifecycle" {
  description = "Bat lifecycle rules (tu dong chuyen storage class, don dep old versions)"
  type        = bool
  default     = false
}

variable "cors_allowed_origins" {
  description = <<-EOT
    Danh sach domains duoc phep upload anh (CORS).
    Dev: ["*"] (cho phep tat ca)
    Prod: ["https://yourdomain.com"] (chi cho domain cu the)
  EOT
  type        = list(string)
  default     = ["*"]
}

variable "tags" {
  description = "Tags chung"
  type        = map(string)
  default     = {}
}
