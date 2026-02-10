# ==============================================================================
# DynamoDB Module Outputs
# ==============================================================================
# Doc for expression: https://developer.hashicorp.com/terraform/language/expressions/for
#
# Khi dung for_each, resource address la:
#   aws_dynamodb_table.tables["products"]
#   aws_dynamodb_table.tables["orders"]
#   aws_dynamodb_table.tables["users"]
#   etc.
#
# `for` expression tao map/list tu collection khac.
# Cung cap cach truy cap gon gang tu root module.
# ==============================================================================

# --- Table Names ---
# Map: { products = "CoffeeProducts", orders = "CoffeeOrders", ... }
output "table_names" {
  description = "Map ten logic -> ten table thuc te tren AWS"
  value = {
    for key, table in aws_dynamodb_table.tables : key => table.name
  }
}

# --- Table ARNs ---
# Map: { products = "arn:aws:...", orders = "arn:aws:...", ... }
output "table_arns" {
  description = "Map ten logic -> ARN cua table"
  value = {
    for key, table in aws_dynamodb_table.tables : key => table.arn
  }
}

# --- Individual table names (tien loi cho truyen vao Lambda module) ---
output "products_table_name" {
  description = "Ten CoffeeProducts table"
  value       = aws_dynamodb_table.tables["products"].name
}

output "orders_table_name" {
  description = "Ten CoffeeOrders table"
  value       = aws_dynamodb_table.tables["orders"].name
}

output "users_table_name" {
  description = "Ten CoffeeUsers table"
  value       = aws_dynamodb_table.tables["users"].name
}

output "reviews_table_name" {
  description = "Ten CoffeeReviews table"
  value       = aws_dynamodb_table.tables["reviews"].name
}
