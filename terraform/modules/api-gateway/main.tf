# ==============================================================================
# API Gateway Module - REST API with CORS
# ==============================================================================
# Doc goc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api
#
# Module nay tao:
#   1. REST API (CoffeeShopAPI)
#   2. Resources: /products, /orders, /auth, /auth/register, /auth/login
#   3. Methods: GET/POST cho moi resource + OPTIONS cho CORS
#   4. Lambda Proxy Integrations: ket noi moi method voi Lambda function
#   5. CORS Configuration: cho phep frontend (S3) goi API
#   6. Deployment + Stage (prod)
#   7. Lambda Permissions: cho phep API Gateway invoke Lambda
#
# Kien thuc nen:
#   API Gateway la "cua truoc" (front door) cua backend.
#   Browser gui HTTP request -> API Gateway -> route den dung Lambda function
#
#   REST API vs HTTP API:
#   - REST API: day du tinh nang, co API keys, usage plans, request validation
#   - HTTP API: don gian hon, re hon, nhung it tinh nang
#   Ta dung REST API theo AWS_SETUP.md
#
# CORS (Cross-Origin Resource Sharing):
#   Browser co "Same-Origin Policy" - chi cho phep request den CUNG domain.
#   Frontend (S3: http://bucket.s3-website.amazonaws.com)
#   Backend (API GW: https://abc123.execute-api.amazonaws.com)
#   -> KHAC domain -> Browser bi BLOCK!
#
#   CORS cho phep server noi voi browser: "frontend nay duoc phep goi toi"
#   Can:
#     1. OPTIONS method (preflight request) tra ve CORS headers
#     2. Cac response headers: Access-Control-Allow-Origin, Methods, Headers
#
#   Doc them: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
# ==============================================================================

# ==============================================================================
# 1. REST API
# ==============================================================================
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api
#
# `endpoint_configuration`: Loai endpoint
#   - REGIONAL: API duoc deploy tai region cu the (tot cho cung region voi user)
#   - EDGE: API duoc deploy tren CloudFront edge locations (tot cho global users)
#   - PRIVATE: Chi truy cap duoc tu VPC
#
# Ta dung REGIONAL vi user chu yeu o Vietnam -> region ap-southeast-1
# ==============================================================================
resource "aws_api_gateway_rest_api" "coffee_api" {
  name        = var.api_name
  description = "Coffee Shop REST API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

# ==============================================================================
# 2. API RESOURCES (URL paths)
# ==============================================================================
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource
#
# Resource = mot phan cua URL path.
# Moi resource co `parent_id` -> tao cay thu muc URL.
#
# Vi du cay URL:
#   / (root)
#   ├── /products     (parent = root)
#   ├── /orders       (parent = root)
#   └── /auth         (parent = root)
#       ├── /register (parent = auth)
#       └── /login    (parent = auth)
#
# `rest_api_id`: API nao
# `parent_id`:   Resource cha (root_resource_id cho top-level)
# `path_part`:   Phan URL (khong co /)
# ==============================================================================

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

# ==============================================================================
# 4. LAMBDA INTEGRATIONS - Ket noi Method voi Lambda Function
# ==============================================================================
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration
#
# `type = "AWS_PROXY"` (Lambda Proxy Integration):
#   API Gateway chuyen TOAN BO HTTP request (headers, body, querystring,
#   path params, context) vao Lambda event object.
#   Lambda tra ve response object voi { statusCode, headers, body }.
#   API Gateway chuyen response nay thang ve client.
#
# QUAN TRONG - `integration_http_method`:
#   LUON la "POST" cho Lambda integration!
#   Day la method ma API Gateway dung de GOI Lambda (qua AWS API).
#   KHONG lien quan toi HTTP method cua client request (GET, POST, etc.)
#   Nhieu nguoi nham lan va set "GET" cho GET endpoint -> LOI!
#
# `uri`: Lambda function invoke ARN
#   Format: arn:aws:apigateway:{region}:lambda:path/2015-03-31/functions/{function-arn}/invocations
#   invoke_arn tu Lambda resource da co dung format nay
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

# ==============================================================================
# 5. CORS - OPTIONS Methods (Preflight Requests)
# ==============================================================================
# Doc: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#preflighted_requests
#
# Khi browser gui request cross-origin voi Content-Type: application/json,
# no gui OPTIONS request TRUOC (preflight) de hoi server:
#   "Toi co duoc phep gui POST voi JSON body khong?"
#
# Server (API Gateway) phai tra loi voi CORS headers:
#   Access-Control-Allow-Origin:  Domain nao duoc phep (* = tat ca)
#   Access-Control-Allow-Methods: HTTP methods nao duoc phep
#   Access-Control-Allow-Headers: Headers nao duoc phep gui kem
#
# Cho OPTIONS method, ta dung MOCK integration (khong can Lambda):
#   API Gateway tu tra response ma khong goi backend nao
#
# Pattern cho moi resource can CORS:
#   1. aws_api_gateway_method        (OPTIONS)
#   2. aws_api_gateway_integration   (MOCK)
#   3. aws_api_gateway_method_response (200 voi CORS headers)
#   4. aws_api_gateway_integration_response (gia tri cua CORS headers)
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

# ==============================================================================
# 6. LAMBDA PERMISSIONS
# ==============================================================================
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission
#
# Lambda function co "Resource-based Policy" - xac dinh AI duoc phep invoke function.
# Mac dinh, khong ai duoc phep invoke (ke ca API Gateway).
#
# `aws_lambda_permission` them statement vao Resource-based Policy cua Lambda:
#   "Cho phep API Gateway (principal) invoke Lambda function nay"
#
# `source_arn`: Chi cho phep invoke tu DUNG API nay
# Format: arn:aws:execute-api:{region}:{account}:{api-id}/*/{method}/{resource}
# Ta dung wildcard (*) de cover tat ca stages va methods
#
# QUAN TRONG: Neu thieu permission nay, API Gateway se tra loi 500 Internal Server Error
# va noi "Lambda function not authorized"
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

# ==============================================================================
# 7. API DEPLOYMENT + STAGE
# ==============================================================================
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment
# Doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage
#
# Deployment = "anh chup" (snapshot) cua API configuration tai mot thoi diem.
# Stage = ten cua deployment (vd: "prod", "dev", "staging")
#
# URL cuoi cung: https://{api-id}.execute-api.{region}.amazonaws.com/{stage}
# Vi du: https://abc123.execute-api.ap-southeast-1.amazonaws.com/prod
#
# `triggers`: Terraform chi tao deployment MOI khi co thay doi.
# `redeployment` hash force Terraform tao deployment moi khi BAT KY resource nao thay doi.
# Neu khong co nay, Terraform co the KHONG deploy lai khi ban thay doi method/integration.
#
# QUAN TRONG: Su dung `lifecycle { create_before_destroy = true }`
# De tranh downtime khi tao deployment moi (tao moi truoc, xoa cu sau)
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
      # Methods
      aws_api_gateway_method.get_products.id,
      aws_api_gateway_method.create_order.id,
      aws_api_gateway_method.get_orders.id,
      aws_api_gateway_method.register_user.id,
      aws_api_gateway_method.login_user.id,
      # Integrations
      aws_api_gateway_integration.get_products.id,
      aws_api_gateway_integration.create_order.id,
      aws_api_gateway_integration.get_orders.id,
      aws_api_gateway_integration.register_user.id,
      aws_api_gateway_integration.login_user.id,
      # CORS
      aws_api_gateway_method.products_options.id,
      aws_api_gateway_method.orders_options.id,
      aws_api_gateway_method.auth_register_options.id,
      aws_api_gateway_method.auth_login_options.id,
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
