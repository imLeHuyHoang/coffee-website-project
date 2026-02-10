# ==============================================================================
# Root Outputs
# ==============================================================================
# Doc: https://developer.hashicorp.com/terraform/language/values/outputs
#
# Outputs hien thi gia tri quan trong sau khi terraform apply.
# Cac gia tri nay cung co the duoc doc boi:
#   - Cac Terraform configurations khac (remote state)
#   - CI/CD scripts (terraform output -raw api_url)
#   - Nguoi dung (copy URL de cau hinh frontend)
# ==============================================================================

# --- API Gateway ---
output "api_url" {
  description = "URL cua API Gateway (dung cho VITE_API_BASE_URL)"
  value       = module.api_gateway.invoke_url
}

output "api_id" {
  description = "ID cua API Gateway"
  value       = module.api_gateway.api_id
}

# --- S3 Frontend ---
output "website_url" {
  description = "URL website frontend (S3 static hosting)"
  value       = module.s3_frontend.website_url
}

output "frontend_bucket_name" {
  description = "Ten S3 bucket frontend (dung cho aws s3 sync)"
  value       = module.s3_frontend.bucket_name
}

# --- IAM ---
output "lambda_role_arn" {
  description = "ARN cua Lambda execution role"
  value       = module.iam.role_arn
}

# --- Lambda Layer ---
output "lambda_layer_arn" {
  description = "ARN cua Lambda Layer (bao gom version)"
  value       = module.lambda_layer.layer_arn
}

# --- DynamoDB (Part 2) ---
output "dynamodb_table_names" {
  description = "Map cac DynamoDB table names"
  value       = module.dynamodb.table_names
}

output "dynamodb_table_arns" {
  description = "Map cac DynamoDB table ARNs"
  value       = module.dynamodb.table_arns
}

# --- S3 Images (Part 2) ---
output "images_bucket_name" {
  description = "Ten S3 bucket chua product images"
  value       = module.s3_images.bucket_name
}

output "images_bucket_arn" {
  description = "ARN cua S3 images bucket"
  value       = module.s3_images.bucket_arn
}

# --- Huong dan su dung ---
output "next_steps" {
  description = "Cac buoc tiep theo sau khi deploy"
  value       = <<-EOT

    ========================================
    DEPLOY THANH CONG!
    ========================================
    
    1. Cap nhat frontend .env:
       VITE_API_BASE_URL=${module.api_gateway.invoke_url}
    
    2. Build va deploy frontend:
       npm run build
       aws s3 sync dist/ s3://${module.s3_frontend.bucket_name}
    
    3. Truy cap website:
       ${module.s3_frontend.website_url}
    
    4. Test API:
       curl ${module.api_gateway.invoke_url}/products
    
    ========================================
  EOT
}
