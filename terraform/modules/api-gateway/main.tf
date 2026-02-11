resource "aws_api_gateway_rest_api" "coffee_api" {
  name        = var.api_name
  description = "Coffee Shop REST API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

resource "aws_api_gateway_resource" "products" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id
  parent_id   = aws_api_gateway_rest_api.coffee_api.root_resource_id
  path_part   = "products"
}

resource "aws_api_gateway_resource" "orders" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id
  parent_id   = aws_api_gateway_rest_api.coffee_api.root_resource_id
  path_part   = "orders"
}

resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id
  parent_id   = aws_api_gateway_rest_api.coffee_api.root_resource_id
  path_part   = "auth"
}

# /auth/register va /auth/login la CON cua /auth
resource "aws_api_gateway_resource" "auth_register" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "register"
}

resource "aws_api_gateway_resource" "auth_login" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "login"
}

resource "aws_api_gateway_resource" "auth_profile" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "profile"
}

# ==============================================================================
# 3. API METHODS - Actual HTTP methods (GET, POST)
# ==============================================================================
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method
#
# `http_method`: GET, POST, PUT, DELETE, OPTIONS, etc.
# `authorization`: NONE = public, AWS_IAM = IAM auth, COGNITO = Cognito user pool
#   Ta dung NONE vi authentication duoc xu ly boi JWT trong Lambda code
#   (khong phai API Gateway level authentication)
# ==============================================================================

# --- GET /products ---
resource "aws_api_gateway_method" "get_products" {
  rest_api_id   = aws_api_gateway_rest_api.coffee_api.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "GET"
  authorization = "NONE"
}

# --- POST /orders ---
resource "aws_api_gateway_method" "create_order" {
  rest_api_id   = aws_api_gateway_rest_api.coffee_api.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "POST"
  authorization = "NONE"
}

# --- GET /orders ---
resource "aws_api_gateway_method" "get_orders" {
  rest_api_id   = aws_api_gateway_rest_api.coffee_api.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "GET"
  authorization = "NONE"
}

# --- POST /auth/register ---
resource "aws_api_gateway_method" "register_user" {
  rest_api_id   = aws_api_gateway_rest_api.coffee_api.id
  resource_id   = aws_api_gateway_resource.auth_register.id
  http_method   = "POST"
  authorization = "NONE"
}

# --- POST /auth/login ---
resource "aws_api_gateway_method" "login_user" {
  rest_api_id   = aws_api_gateway_rest_api.coffee_api.id
  resource_id   = aws_api_gateway_resource.auth_login.id
  http_method   = "POST"
  authorization = "NONE"
}

# --- PUT /auth/profile ---
resource "aws_api_gateway_method" "update_user" {
  rest_api_id   = aws_api_gateway_rest_api.coffee_api.id
  resource_id   = aws_api_gateway_resource.auth_profile.id
  http_method   = "PUT"
  authorization = "NONE"
}

# ==============================================================================
# 4. LAMBDA INTEGRATIONS - Ket noi Method voi Lambda Function
# ==============================================================================
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration
# ==============================================================================

resource "aws_api_gateway_integration" "get_products" {
  rest_api_id             = aws_api_gateway_rest_api.coffee_api.id
  resource_id             = aws_api_gateway_resource.products.id
  http_method             = aws_api_gateway_method.get_products.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST" # LUON la POST cho Lambda!
  uri                     = var.get_products_invoke_arn
}

resource "aws_api_gateway_integration" "create_order" {
  rest_api_id             = aws_api_gateway_rest_api.coffee_api.id
  resource_id             = aws_api_gateway_resource.orders.id
  http_method             = aws_api_gateway_method.create_order.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.create_order_invoke_arn
}

resource "aws_api_gateway_integration" "get_orders" {
  rest_api_id             = aws_api_gateway_rest_api.coffee_api.id
  resource_id             = aws_api_gateway_resource.orders.id
  http_method             = aws_api_gateway_method.get_orders.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.get_orders_invoke_arn
}

resource "aws_api_gateway_integration" "register_user" {
  rest_api_id             = aws_api_gateway_rest_api.coffee_api.id
  resource_id             = aws_api_gateway_resource.auth_register.id
  http_method             = aws_api_gateway_method.register_user.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.register_user_invoke_arn
}

resource "aws_api_gateway_integration" "login_user" {
  rest_api_id             = aws_api_gateway_rest_api.coffee_api.id
  resource_id             = aws_api_gateway_resource.auth_login.id
  http_method             = aws_api_gateway_method.login_user.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.login_user_invoke_arn
}

resource "aws_api_gateway_integration" "update_user" {
  rest_api_id             = aws_api_gateway_rest_api.coffee_api.id
  resource_id             = aws_api_gateway_resource.auth_profile.id
  http_method             = aws_api_gateway_method.update_user.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.update_user_invoke_arn
}

# ==============================================================================
# 5. CORS - OPTIONS Methods (Preflight Requests)
# ==============================================================================


# ---------- CORS cho /products ----------

resource "aws_api_gateway_method" "products_options" {
  rest_api_id   = aws_api_gateway_rest_api.coffee_api.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "products_options" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.products_options.http_method
  type        = "MOCK"

  # MOCK integration can request_templates de tra ve statusCode 200
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "products_options" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.products_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "products_options" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.products_options.http_method
  status_code = aws_api_gateway_method_response.products_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# ---------- CORS cho /orders ----------

resource "aws_api_gateway_method" "orders_options" {
  rest_api_id   = aws_api_gateway_rest_api.coffee_api.id
  resource_id   = aws_api_gateway_resource.orders.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "orders_options" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.orders_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "orders_options" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.orders_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "orders_options" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id
  resource_id = aws_api_gateway_resource.orders.id
  http_method = aws_api_gateway_method.orders_options.http_method
  status_code = aws_api_gateway_method_response.orders_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# ---------- CORS cho /auth/register ----------

resource "aws_api_gateway_method" "auth_register_options" {
  rest_api_id   = aws_api_gateway_rest_api.coffee_api.id
  resource_id   = aws_api_gateway_resource.auth_register.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_register_options" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id
  resource_id = aws_api_gateway_resource.auth_register.id
  http_method = aws_api_gateway_method.auth_register_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "auth_register_options" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id
  resource_id = aws_api_gateway_resource.auth_register.id
  http_method = aws_api_gateway_method.auth_register_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "auth_register_options" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id
  resource_id = aws_api_gateway_resource.auth_register.id
  http_method = aws_api_gateway_method.auth_register_options.http_method
  status_code = aws_api_gateway_method_response.auth_register_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# ---------- CORS cho /auth/login ----------

resource "aws_api_gateway_method" "auth_login_options" {
  rest_api_id   = aws_api_gateway_rest_api.coffee_api.id
  resource_id   = aws_api_gateway_resource.auth_login.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_login_options" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id
  resource_id = aws_api_gateway_resource.auth_login.id
  http_method = aws_api_gateway_method.auth_login_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "auth_login_options" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id
  resource_id = aws_api_gateway_resource.auth_login.id
  http_method = aws_api_gateway_method.auth_login_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "auth_login_options" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id
  resource_id = aws_api_gateway_resource.auth_login.id
  http_method = aws_api_gateway_method.auth_login_options.http_method
  status_code = aws_api_gateway_method_response.auth_login_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# ---------- CORS cho /auth/profile ----------

resource "aws_api_gateway_method" "auth_profile_options" {
  rest_api_id   = aws_api_gateway_rest_api.coffee_api.id
  resource_id   = aws_api_gateway_resource.auth_profile.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_profile_options" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id
  resource_id = aws_api_gateway_resource.auth_profile.id
  http_method = aws_api_gateway_method.auth_profile_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "auth_profile_options" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id
  resource_id = aws_api_gateway_resource.auth_profile.id
  http_method = aws_api_gateway_method.auth_profile_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "auth_profile_options" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id
  resource_id = aws_api_gateway_resource.auth_profile.id
  http_method = aws_api_gateway_method.auth_profile_options.http_method
  status_code = aws_api_gateway_method_response.auth_profile_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'PUT,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# ==============================================================================
# 6. LAMBDA PERMISSIONS
# ==============================================================================
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission
# ==============================================================================

resource "aws_lambda_permission" "get_products" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.get_products_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.coffee_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "create_order" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.create_order_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.coffee_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "get_orders" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.get_orders_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.coffee_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "register_user" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.register_user_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.coffee_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "login_user" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.login_user_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.coffee_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "update_user" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.update_user_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.coffee_api.execution_arn}/*/*"
}

# ==============================================================================
# 7. API DEPLOYMENT + STAGE
# ==============================================================================
resource "aws_api_gateway_deployment" "coffee_api" {
  rest_api_id = aws_api_gateway_rest_api.coffee_api.id

  # Force redeployment khi bat ky resource nao thay doi
  triggers = {
    redeployment = sha1(jsonencode([
      # Resources
      aws_api_gateway_resource.products.id,
      aws_api_gateway_resource.orders.id,
      aws_api_gateway_resource.auth.id,
      aws_api_gateway_resource.auth_register.id,
      aws_api_gateway_resource.auth_login.id,
      aws_api_gateway_resource.auth_profile.id,
      # Methods
      aws_api_gateway_method.get_products.id,
      aws_api_gateway_method.create_order.id,
      aws_api_gateway_method.get_orders.id,
      aws_api_gateway_method.register_user.id,
      aws_api_gateway_method.login_user.id,
      aws_api_gateway_method.update_user.id,
      # Integrations
      aws_api_gateway_integration.get_products.id,
      aws_api_gateway_integration.create_order.id,
      aws_api_gateway_integration.get_orders.id,
      aws_api_gateway_integration.register_user.id,
      aws_api_gateway_integration.login_user.id,
      aws_api_gateway_integration.update_user.id,
      # CORS
      aws_api_gateway_method.products_options.id,
      aws_api_gateway_method.orders_options.id,
      aws_api_gateway_method.auth_register_options.id,
      aws_api_gateway_method.auth_login_options.id,
      aws_api_gateway_method.auth_profile_options.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.coffee_api.id
  deployment_id = aws_api_gateway_deployment.coffee_api.id
  stage_name    = var.stage_name

  tags = var.tags
}
