# ==============================================================================
# API Gateway Module Variables
# ==============================================================================

variable "api_name" {
  description = "Ten API Gateway"
  type        = string
  default     = "CoffeeShopAPI"
}

variable "stage_name" {
  description = "Ten stage (prod, dev, staging)"
  type        = string
  default     = "prod"
}

# --- Lambda Function Invoke ARNs ---
# Dung cho API Gateway integration URI
# Invoke ARN co format dac biet: arn:aws:apigateway:{region}:lambda:path/...

variable "get_products_invoke_arn" {
  description = "Invoke ARN cua get-products Lambda function"
  type        = string
}

variable "create_order_invoke_arn" {
  description = "Invoke ARN cua create-order Lambda function"
  type        = string
}

variable "get_orders_invoke_arn" {
  description = "Invoke ARN cua get-orders Lambda function"
  type        = string
}

variable "register_user_invoke_arn" {
  description = "Invoke ARN cua register-user Lambda function"
  type        = string
}

variable "login_user_invoke_arn" {
  description = "Invoke ARN cua login-user Lambda function"
  type        = string
}

# --- Lambda Function Names ---
# Dung cho Lambda Permission (resource-based policy)

variable "get_products_function_name" {
  description = "Ten cua get-products Lambda function"
  type        = string
}

variable "create_order_function_name" {
  description = "Ten cua create-order Lambda function"
  type        = string
}

variable "get_orders_function_name" {
  description = "Ten cua get-orders Lambda function"
  type        = string
}

variable "register_user_function_name" {
  description = "Ten cua register-user Lambda function"
  type        = string
}

variable "login_user_function_name" {
  description = "Ten cua login-user Lambda function"
  type        = string
}

variable "tags" {
  description = "Tags chung"
  type        = map(string)
  default     = {}
}
