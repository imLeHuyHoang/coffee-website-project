# ==============================================================================
# Root Module - Coffee Shop Infrastructure Orchestrator
# ==============================================================================
# Doc: https://developer.hashicorp.com/terraform/language/modules/syntax
#
# Day la file CHINH cua Terraform project.
# No goi cac sub-modules va truyen bien giua chung.
#
# Thu tu tao resources (dependency chain):
#   1. IAM Role + Policy       (Lambda can role de chay)
#   2. S3 Frontend Bucket      (doc lap, khong phu thuoc)
#   3. S3 Images Bucket         (doc lap, khong phu thuoc)
#   4. DynamoDB Tables          (doc lap, nhung Lambda can biet ten table)
#   5. Lambda Layer             (install npm packages truoc)
#   6. Lambda Functions         (can role_arn + layer_arn + table names)
#   7. API Gateway              (can Lambda function ARNs)
#
# Terraform TU DONG xac dinh dependency tu references.
# Vi du: module.lambda.lambda_role_arn = module.iam.role_arn
# -> Terraform biet phai tao IAM truoc Lambda
#
# CACH SU DUNG:
#   1. Copy terraform.tfvars.example -> terraform.tfvars
#   2. Dien gia tri (aws_region, bucket_name, jwt_secret)
#   3. cd terraform/lambda-src/layer/nodejs && npm install
#   4. cd terraform && terraform init
#   5. terraform plan
#   6. terraform apply
# ==============================================================================

# ==============================================================================
# Module 1: IAM - Role va Policy cho Lambda
# ==============================================================================
module "iam" {
  source = "./modules/iam"

  role_name             = "${var.project_name}LambdaRole"
  policy_name           = "${var.project_name}LambdaPolicy"
  aws_region            = var.aws_region
  images_bucket_name    = var.images_bucket_name
  dynamodb_table_prefix = var.project_name

  tags = local.common_tags
}

# ==============================================================================
# Module 2: S3 Frontend - Static Website Hosting
# ==============================================================================
module "s3_frontend" {
  source = "./modules/s3-frontend"

  bucket_name   = var.frontend_bucket_name
  force_destroy = var.force_destroy

  tags = local.common_tags
}

# ==============================================================================
# Module 3: S3 Images - Product Image Storage (Part 2)
# ==============================================================================
module "s3_images" {
  source = "./modules/s3-images"

  bucket_name          = var.images_bucket_name
  force_destroy        = var.force_destroy
  enable_versioning    = var.enable_versioning
  enable_lifecycle     = var.enable_lifecycle
  cors_allowed_origins = var.cors_allowed_origins

  tags = local.common_tags
}

# ==============================================================================
# Module 4: DynamoDB Tables (Part 2)
# ==============================================================================
# Dung for_each voi map de tao 4 tables tu 1 module call.
# Table names lay tu default values trong module.
# Override tables variable neu can doi ten hoac them/bot tables.
# ==============================================================================
module "dynamodb" {
  source = "./modules/dynamodb"

  table_name_prefix             = var.project_name
  billing_mode                  = var.dynamodb_billing_mode
  enable_point_in_time_recovery = var.enable_point_in_time_recovery

  tags = local.common_tags
}

# ==============================================================================
# Module 5: Lambda Layer - Shared Dependencies (bcryptjs + jsonwebtoken)
# ==============================================================================
# LUU Y: Truoc khi chay terraform apply, phai install npm packages:
#   cd lambda-src/layer/nodejs && npm install && cd ../../..
# ==============================================================================
module "lambda_layer" {
  source = "./modules/lambda-layer"

  layer_name       = "${var.project_name}NodeModules"
  layer_source_dir = "${path.module}/lambda-src/layer"
  runtime          = "nodejs20.x"
}

# ==============================================================================
# Module 6: Lambda Functions
# ==============================================================================
module "lambda" {
  source = "./modules/lambda"

  function_prefix    = lower(var.project_name)
  runtime            = "nodejs20.x"
  lambda_role_arn    = module.iam.role_arn
  lambda_source_dir  = "${path.module}/lambda-src"
  layer_arns         = [module.lambda_layer.layer_arn]
  timeout            = var.lambda_timeout
  memory_size        = var.lambda_memory_size
  log_retention_days = var.log_retention_days
  aws_region         = var.aws_region

  # DynamoDB table names - LAY TU MODULE OUTPUT (Part 2)
  # Truoc day hardcode tu variables, gio lay tu dynamodb module
  # Dam bao ten table DONG BO giua Lambda env vars va DynamoDB thuc te
  products_table_name = module.dynamodb.products_table_name
  orders_table_name   = module.dynamodb.orders_table_name
  users_table_name    = module.dynamodb.users_table_name

  jwt_secret = var.jwt_secret

  tags = local.common_tags
}

# ==============================================================================
# Module 7: API Gateway - REST API voi CORS
# ==============================================================================
module "api_gateway" {
  source = "./modules/api-gateway"

  api_name   = "${var.project_name}ShopAPI"
  stage_name = var.stage_name

  # Lambda invoke ARNs (dung cho integration URI)
  get_products_invoke_arn  = module.lambda.get_products_invoke_arn
  create_order_invoke_arn  = module.lambda.create_order_invoke_arn
  get_orders_invoke_arn    = module.lambda.get_orders_invoke_arn
  register_user_invoke_arn = module.lambda.register_user_invoke_arn
  login_user_invoke_arn    = module.lambda.login_user_invoke_arn

  # Lambda function names (dung cho Lambda permission)
  get_products_function_name  = module.lambda.get_products_name
  create_order_function_name  = module.lambda.create_order_name
  get_orders_function_name    = module.lambda.get_orders_name
  register_user_function_name = module.lambda.register_user_name
  login_user_function_name    = module.lambda.login_user_name

  tags = local.common_tags
}

# ==============================================================================
# Local Values
# ==============================================================================
# Doc: https://developer.hashicorp.com/terraform/language/values/locals
#
# Locals la bien NOI BO cua module, khong the override tu ben ngoai.
# Dung de tinh toan gia tri chung, tranh lap lai.
# ==============================================================================
locals {
  common_tags = {
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Environment = var.stage_name
  }
}
