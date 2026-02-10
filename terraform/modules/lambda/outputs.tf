# ==============================================================================
# Lambda Module Outputs
# ==============================================================================
# Cac output nay duoc API Gateway module su dung de:
#   1. Tao integration giua API method va Lambda function
#   2. Tao lambda permission cho phep API Gateway invoke function
# ==============================================================================

# --- Function ARNs ---
# Dung cho API Gateway integration (chi dinh function nao xu ly request nao)

output "get_products_arn" {
  description = "ARN cua get-products function"
  value       = aws_lambda_function.get_products.arn
}

output "create_order_arn" {
  description = "ARN cua create-order function"
  value       = aws_lambda_function.create_order.arn
}

output "get_orders_arn" {
  description = "ARN cua get-orders function"
  value       = aws_lambda_function.get_orders.arn
}

output "register_user_arn" {
  description = "ARN cua register-user function"
  value       = aws_lambda_function.register_user.arn
}

output "login_user_arn" {
  description = "ARN cua login-user function"
  value       = aws_lambda_function.login_user.arn
}

# --- Function Names ---
# Dung cho API Gateway lambda permission (resource-based policy)

output "get_products_name" {
  description = "Ten cua get-products function"
  value       = aws_lambda_function.get_products.function_name
}

output "create_order_name" {
  description = "Ten cua create-order function"
  value       = aws_lambda_function.create_order.function_name
}

output "get_orders_name" {
  description = "Ten cua get-orders function"
  value       = aws_lambda_function.get_orders.function_name
}

output "register_user_name" {
  description = "Ten cua register-user function"
  value       = aws_lambda_function.register_user.function_name
}

output "login_user_name" {
  description = "Ten cua login-user function"
  value       = aws_lambda_function.login_user.function_name
}

# --- Invoke ARNs ---
# Format dac biet cua ARN dung cho API Gateway integration URI
# Doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html

output "get_products_invoke_arn" {
  description = "Invoke ARN cua get-products (dung cho API Gateway integration)"
  value       = aws_lambda_function.get_products.invoke_arn
}

output "create_order_invoke_arn" {
  description = "Invoke ARN cua create-order"
  value       = aws_lambda_function.create_order.invoke_arn
}

output "get_orders_invoke_arn" {
  description = "Invoke ARN cua get-orders"
  value       = aws_lambda_function.get_orders.invoke_arn
}

output "register_user_invoke_arn" {
  description = "Invoke ARN cua register-user"
  value       = aws_lambda_function.register_user.invoke_arn
}

output "login_user_invoke_arn" {
  description = "Invoke ARN cua login-user"
  value       = aws_lambda_function.login_user.invoke_arn
}
