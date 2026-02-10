# ==============================================================================
# Lambda Module - Coffee Shop Functions
# ==============================================================================
# Doc goc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function
#
# Module nay tao:
#   1. 5 Lambda functions (get-products, create-order, get-orders, register, login)
#   2. CloudWatch Log Groups cho moi function
#   3. Archive (.zip) cho moi function tu source code
#
# Kien thuc nen:
#   - Lambda = serverless compute - chi chay khi co request, khong can quan ly server
#   - Moi function co Runtime (Node.js 20.x), Handler (entry point), Role (quyen)
#   - Handler format: "index.handler" = file index.mjs, export function handler
#   - Lambda Proxy Integration: API Gateway gui TOAN BO request (headers, body, query)
#     vao event object, Lambda tra ve response voi statusCode + headers + body
#
# Pricing: https://aws.amazon.com/lambda/pricing/
#   - 1 trieu request/thang MIEN PHI
#   - 400,000 GB-seconds/thang MIEN PHI
#   - Sau do: $0.20 per 1M requests
# ==============================================================================

# ==============================================================================
# DATA SOURCES - Dong goi source code thanh .zip
# ==============================================================================
# Doc: https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file
#
# Moi Lambda function can 1 file .zip chua source code.
# `archive_file` data source tu dong zip thu muc -> file .zip
# `source_code_hash` dam bao Terraform chi upload lai khi code thay doi
# ==============================================================================

data "archive_file" "get_products" {
  type        = "zip"
  source_dir  = "${var.lambda_source_dir}/get-products"
  output_path = "${path.module}/builds/get-products.zip"
}

data "archive_file" "create_order" {
  type        = "zip"
  source_dir  = "${var.lambda_source_dir}/create-order"
  output_path = "${path.module}/builds/create-order.zip"
}

data "archive_file" "get_orders" {
  type        = "zip"
  source_dir  = "${var.lambda_source_dir}/get-orders"
  output_path = "${path.module}/builds/get-orders.zip"
}

data "archive_file" "register_user" {
  type        = "zip"
  source_dir  = "${var.lambda_source_dir}/register-user"
  output_path = "${path.module}/builds/register-user.zip"
}

data "archive_file" "login_user" {
  type        = "zip"
  source_dir  = "${var.lambda_source_dir}/login-user"
  output_path = "${path.module}/builds/login-user.zip"
}

# ==============================================================================
# CLOUDWATCH LOG GROUPS
# ==============================================================================
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group
#
# Tao LOG GROUP TRUOC Lambda function. Tai sao?
#   - Neu khong tao, Lambda tu tao log group voi retention = NEVER EXPIRE
#   - Logs se tich tu mai mai -> ton tien storage
#   - Tao truoc cho phep ta kiem soat retention_in_days (7 ngay cho dev)
#
# `retention_in_days`: Sau bao nhieu ngay thi xoa logs cu
#   Valid values: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653, 0
#   0 = never expire (mac dinh cua AWS)
#
# Ten log group PHAI theo format: /aws/lambda/{function-name}
# Day la convention cua AWS Lambda - function tu dong ghi log vao group nay
# ==============================================================================

resource "aws_cloudwatch_log_group" "get_products" {
  name              = "/aws/lambda/${var.function_prefix}-get-products"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "create_order" {
  name              = "/aws/lambda/${var.function_prefix}-create-order"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "get_orders" {
  name              = "/aws/lambda/${var.function_prefix}-get-orders"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "register_user" {
  name              = "/aws/lambda/${var.function_prefix}-register-user"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "login_user" {
  name              = "/aws/lambda/${var.function_prefix}-login-user"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# ==============================================================================
# LAMBDA FUNCTIONS
# ==============================================================================
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function
#
# Cac tham so quan trong:
#   `function_name`: Ten function (hien thi trong AWS Console)
#   `handler`:       Entry point - format "filename.exportedFunction"
#                    Vi du: "index.handler" = import { handler } from "./index.mjs"
#   `runtime`:       Ngon ngu + version (nodejs20.x, python3.12, etc.)
#   `role`:          IAM Role ARN - xac dinh Lambda co quyen lam gi
#   `filename`:      Duong dan toi file .zip chua source code
#   `source_code_hash`: Base64 SHA256 hash cua zip file
#                    Terraform so sanh hash cu vs moi -> chi deploy khi code thay doi
#   `timeout`:       Thoi gian toi da function duoc chay (seconds, mac dinh = 3)
#                    API operations nen set 30s de tranh timeout
#   `memory_size`:   RAM (MB, mac dinh = 128). Nhieu RAM > chay nhanh hon (va dat hon)
#
# `environment`: Truyen bien moi vao function (giong .env file)
#   Lambda doc qua process.env.VARIABLE_NAME
#   KHONG bao gio hardcode secrets trong code - dung environment variables!
#
# `layers`: Danh sach Layer ARNs de attach
#   Chi register-user va login-user can layer (cho bcryptjs + jsonwebtoken)
#
# `depends_on`: Dam bao log group duoc tao TRUOC function
#   Neu khong, Lambda co the tao log group rieng truoc khi Terraform tao
#   -> Terraform bao loi "ResourceAlreadyExistsException"
# ==============================================================================

# --- 1. GET Products ---
resource "aws_lambda_function" "get_products" {
  function_name    = "${var.function_prefix}-get-products"
  handler          = "index.handler"
  runtime          = var.runtime
  role             = var.lambda_role_arn
  filename         = data.archive_file.get_products.output_path
  source_code_hash = data.archive_file.get_products.output_base64sha256
  timeout          = var.timeout
  memory_size      = var.memory_size

  environment {
    variables = {
      PRODUCTS_TABLE = var.products_table_name
      AWS_REGION_    = var.aws_region # AWS_REGION la reserved, dung AWS_REGION_
    }
  }

  depends_on = [aws_cloudwatch_log_group.get_products]
  tags       = var.tags
}

# --- 2. CREATE Order ---
resource "aws_lambda_function" "create_order" {
  function_name    = "${var.function_prefix}-create-order"
  handler          = "index.handler"
  runtime          = var.runtime
  role             = var.lambda_role_arn
  filename         = data.archive_file.create_order.output_path
  source_code_hash = data.archive_file.create_order.output_base64sha256
  timeout          = var.timeout
  memory_size      = var.memory_size

  environment {
    variables = {
      ORDERS_TABLE = var.orders_table_name
      AWS_REGION_  = var.aws_region
    }
  }

  depends_on = [aws_cloudwatch_log_group.create_order]
  tags       = var.tags
}

# --- 3. GET Orders ---
resource "aws_lambda_function" "get_orders" {
  function_name    = "${var.function_prefix}-get-orders"
  handler          = "index.handler"
  runtime          = var.runtime
  role             = var.lambda_role_arn
  filename         = data.archive_file.get_orders.output_path
  source_code_hash = data.archive_file.get_orders.output_base64sha256
  timeout          = var.timeout
  memory_size      = var.memory_size

  environment {
    variables = {
      ORDERS_TABLE = var.orders_table_name
      AWS_REGION_  = var.aws_region
    }
  }

  depends_on = [aws_cloudwatch_log_group.get_orders]
  tags       = var.tags
}

# --- 4. REGISTER User ---
# Function nay CAN Lambda Layer (bcryptjs + jsonwebtoken)
resource "aws_lambda_function" "register_user" {
  function_name    = "${var.function_prefix}-register-user"
  handler          = "index.handler"
  runtime          = var.runtime
  role             = var.lambda_role_arn
  filename         = data.archive_file.register_user.output_path
  source_code_hash = data.archive_file.register_user.output_base64sha256
  timeout          = var.timeout
  memory_size      = var.memory_size

  # Attach Lambda Layer cho bcryptjs + jsonwebtoken
  layers = var.layer_arns

  environment {
    variables = {
      USERS_TABLE = var.users_table_name
      JWT_SECRET  = var.jwt_secret
      AWS_REGION_ = var.aws_region
    }
  }

  depends_on = [aws_cloudwatch_log_group.register_user]
  tags       = var.tags
}

# --- 5. LOGIN User ---
# Function nay CAN Lambda Layer (bcryptjs + jsonwebtoken)
resource "aws_lambda_function" "login_user" {
  function_name    = "${var.function_prefix}-login-user"
  handler          = "index.handler"
  runtime          = var.runtime
  role             = var.lambda_role_arn
  filename         = data.archive_file.login_user.output_path
  source_code_hash = data.archive_file.login_user.output_base64sha256
  timeout          = var.timeout
  memory_size      = var.memory_size

  # Attach Lambda Layer cho bcryptjs + jsonwebtoken
  layers = var.layer_arns

  environment {
    variables = {
      USERS_TABLE = var.users_table_name
      JWT_SECRET  = var.jwt_secret
      AWS_REGION_ = var.aws_region
    }
  }

  depends_on = [aws_cloudwatch_log_group.login_user]
  tags       = var.tags
}
