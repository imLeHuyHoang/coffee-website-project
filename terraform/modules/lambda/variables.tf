# ==============================================================================
# Lambda Module Variables
# ==============================================================================

variable "function_prefix" {
  description = "Prefix cho ten cac Lambda functions (vd: 'coffee' -> 'coffee-get-products')"
  type        = string
  default     = "coffee"
}

variable "runtime" {
  description = "Lambda runtime (Node.js version)"
  type        = string
  default     = "nodejs20.x"
}

variable "lambda_role_arn" {
  description = "ARN cua IAM Role cho Lambda execution"
  type        = string
}

variable "lambda_source_dir" {
  description = "Duong dan root cua Lambda source code (chua cac thu muc get-products/, create-order/, etc.)"
  type        = string
}

variable "layer_arns" {
  description = "Danh sach Lambda Layer ARNs (dung cho auth functions can bcryptjs + jsonwebtoken)"
  type        = list(string)
  default     = []
}

variable "timeout" {
  description = "Lambda timeout tinh bang giay (mac dinh 30s cho API operations)"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Lambda memory tinh bang MB (128-10240)"
  type        = number
  default     = 128
}

variable "log_retention_days" {
  description = "So ngay giu CloudWatch Logs (7 cho dev, 30 cho prod)"
  type        = number
  default     = 7
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

# --- DynamoDB Table Names ---
# Truyen vao qua environment variables cua Lambda
# Giup Lambda biet doc/ghi vao table nao

variable "products_table_name" {
  description = "Ten DynamoDB table chua san pham"
  type        = string
  default     = "CoffeeProducts"
}

variable "orders_table_name" {
  description = "Ten DynamoDB table chua don hang"
  type        = string
  default     = "CoffeeOrders"
}

variable "users_table_name" {
  description = "Ten DynamoDB table chua users"
  type        = string
  default     = "CoffeeUsers"
}

variable "jwt_secret" {
  description = "Secret key cho JWT token (KHONG commit vao git!)"
  type        = string
  sensitive   = true # Terraform se AN gia tri nay trong output/logs
}

variable "tags" {
  description = "Tags chung"
  type        = map(string)
  default     = {}
}
