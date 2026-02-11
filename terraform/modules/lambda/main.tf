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

data "archive_file" "update_user" {
  type        = "zip"
  source_dir  = "${var.lambda_source_dir}/update-user"
  output_path = "${path.module}/builds/update-user.zip"
}


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

resource "aws_cloudwatch_log_group" "update_user" {
  name              = "/aws/lambda/${var.function_prefix}-update-user"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

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

# --- 6. UPDATE User ---
# Function nay CAN Lambda Layer (jsonwebtoken)
resource "aws_lambda_function" "update_user" {
  function_name    = "${var.function_prefix}-update-user"
  handler          = "index.handler"
  runtime          = var.runtime
  role             = var.lambda_role_arn
  filename         = data.archive_file.update_user.output_path
  source_code_hash = data.archive_file.update_user.output_base64sha256
  timeout          = var.timeout
  memory_size      = var.memory_size

  # Attach Lambda Layer cho jsonwebtoken
  layers = var.layer_arns

  environment {
    variables = {
      USERS_TABLE = var.users_table_name
      JWT_SECRET  = var.jwt_secret
      AWS_REGION_ = var.aws_region
    }
  }

  depends_on = [aws_cloudwatch_log_group.update_user]
  tags       = var.tags
}
