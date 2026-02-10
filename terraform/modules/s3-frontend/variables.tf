variable "bucket_name" {
  description = "Ten S3 bucket cho frontend (phai globally unique)"
  type        = string
}

variable "force_destroy" {
  description = "Cho phep xoa bucket ngay ca khi con objects (true cho dev, false cho prod)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags chung"
  type        = map(string)
  default     = {}
}
