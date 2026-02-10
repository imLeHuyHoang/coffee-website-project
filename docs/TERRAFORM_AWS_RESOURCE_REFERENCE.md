# Terraform AWS Provider Resource Reference

> Researched from Terraform Registry (AWS Provider v6.31.0)

---

## Table of Contents

1. [S3 Resources](#1-s3-resources)
2. [API Gateway Resources](#2-api-gateway-resources)
3. [Lambda Resources](#3-lambda-resources)
4. [IAM Resources](#4-iam-resources)
5. [DynamoDB Resources](#5-dynamodb-resources)
6. [CORS Configuration Notes](#6-cors-configuration-for-api-gateway)

---

## 1. S3 Resources

### 1.1 `aws_s3_bucket`

**URL:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket

**Required Arguments:** None (bucket name is auto-generated if omitted)

**Key Optional Arguments:**
| Argument | Description |
|---|---|
| `bucket` | Name of the bucket. If omitted, Terraform assigns a random unique name |
| `bucket_prefix` | Creates a unique bucket name beginning with the specified prefix |
| `force_destroy` | (Default: `false`) Whether all objects should be deleted when destroying the bucket |
| `object_lock_enabled` | Whether S3 Object Lock is enabled |
| `tags` | Map of tags |

**Key Attributes:**
- `arn` - ARN of the bucket
- `bucket_domain_name` - Bucket domain name
- `hosted_zone_id` - Route 53 Hosted Zone ID
- `region` - AWS region the bucket resides in

**Example:**
```hcl
resource "aws_s3_bucket" "example" {
  bucket = "my-coffee-web-bucket"
  tags = {
    Name        = "Coffee Web"
    Environment = "dev"
  }
}
```

**Gotchas:**
- Many sub-resource configurations (`website`, `cors_rule`, `versioning`, `logging`, `server_side_encryption_configuration`) are **DEPRECATED** as inline blocks. Use separate resources instead (e.g., `aws_s3_bucket_website_configuration`, `aws_s3_bucket_cors_configuration`).
- `force_destroy = false` (default) means `terraform destroy` will fail if the bucket contains objects.

---

### 1.2 `aws_s3_bucket_website_configuration`

**URL:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration

**Required Arguments:**
| Argument | Description |
|---|---|
| `bucket` | Name of the bucket (Forces new resource) |
| `index_document` | Required if `redirect_all_requests_to` is not specified |

**Key Optional Arguments:**
| Argument | Description |
|---|---|
| `error_document` | Error document configuration (conflicts with `redirect_all_requests_to`) |
| `redirect_all_requests_to` | Redirect all requests (conflicts with `index_document`, `error_document`, `routing_rule`) |
| `routing_rule` | List of routing rules for redirects |
| `routing_rules` | JSON array of routing rules (use when rules contain empty strings) |

**Key Attributes:**
- `website_domain` - Domain of the website endpoint (for Route 53 aliases)
- `website_endpoint` - Website endpoint URL

**Example:**
```hcl
resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  routing_rule {
    condition {
      key_prefix_equals = "docs/"
    }
    redirect {
      replace_key_prefix_with = "documents/"
    }
  }
}
```

**Gotchas:**
- Cannot be used with S3 directory buckets.
- `index_document.suffix` must not be empty and must not include a slash character.
- `routing_rule` and `routing_rules` conflict with each other — use `routing_rules` (JSON) when rules contain empty string values.

---

### 1.3 `aws_s3_bucket_policy`

**URL:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy

**Required Arguments:**
| Argument | Description |
|---|---|
| `bucket` | Name of the bucket |
| `policy` | Text of the policy (JSON string) |

**Key Attributes:** None additional.

**Example:**
```hcl
resource "aws_s3_bucket_policy" "allow_public_read" {
  bucket = aws_s3_bucket.example.id
  policy = data.aws_iam_policy_document.allow_public_read.json
}

data "aws_iam_policy_document" "allow_public_read" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.example.arn}/*"]
  }
}
```

**Gotchas:**
- Only **one** `aws_s3_bucket_policy` per S3 bucket. Multiple resources targeting the same bucket will silently overwrite each other (uses `PutBucketPolicy` which replaces the entire policy).
- Bucket policies are **limited to 20 KB**.
- Use `aws_iam_policy_document` data source for cleaner policy definition.

---

### 1.4 `aws_s3_bucket_public_access_block`

**URL:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block

**Required Arguments:**
| Argument | Description |
|---|---|
| `bucket` | S3 bucket to apply configuration to |

**Key Optional Arguments:**
| Argument | Default | Description |
|---|---|---|
| `block_public_acls` | `false` | Block public ACLs |
| `block_public_policy` | `false` | Block public bucket policies |
| `ignore_public_acls` | `false` | Ignore public ACLs |
| `restrict_public_buckets` | `false` | Restrict public bucket policies |
| `skip_destroy` | `false` | If `true`, resource is removed from state on destroy but not deleted in AWS |

**Example:**
```hcl
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

**Gotchas:**
- Cannot be used with S3 directory buckets.
- For **static website hosting**, you typically need to set all four to `false` (or selectively allow public access).
- `skip_destroy = true` creates a dangling resource that persists in AWS after `terraform destroy`.
- All four settings default to `false` — always set them explicitly.

---

## 2. API Gateway Resources

### 2.1 `aws_api_gateway_rest_api`

**URL:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api

**Required Arguments:**
| Argument | Description |
|---|---|
| `name` | Name of the REST API |

**Key Optional Arguments:**
| Argument | Description |
|---|---|
| `description` | Description of the REST API |
| `endpoint_configuration` | Nested block with `types` (list: `EDGE`, `REGIONAL`, `PRIVATE`) |
| `body` | OpenAPI specification (JSON/YAML). When used, don't manage resources/methods separately |
| `api_key_source` | Source of API key (`HEADER` or `AUTHORIZER`) |
| `binary_media_types` | List of binary media types supported by the REST API |

**Key Attributes:**
- `execution_arn` - Execution ARN for Lambda permissions
- `root_resource_id` - Resource ID of the REST API's root
- `id` - ID of the REST API

**Example:**
```hcl
resource "aws_api_gateway_rest_api" "api" {
  name        = "coffee-web-api"
  description = "Coffee Web API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}
```

**Gotchas:**
- When using `body` (OpenAPI spec), do NOT separately manage `aws_api_gateway_resource`, `aws_api_gateway_method`, or `aws_api_gateway_integration` — they will conflict.
- `root_resource_id` is needed as `parent_id` for top-level `aws_api_gateway_resource` children.

---

### 2.2 `aws_api_gateway_resource`

**URL:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_resource

**Required Arguments:**
| Argument | Description |
|---|---|
| `rest_api_id` | ID of the associated REST API |
| `parent_id` | ID of the parent API resource |
| `path_part` | Last path segment of this API resource |

**Key Attributes:**
- `id` - Resource's identifier
- `path` - Complete path including all parent paths

**Example:**
```hcl
resource "aws_api_gateway_resource" "products" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "products"
}

# Nested resource: /products/{id}
resource "aws_api_gateway_resource" "product" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.products.id
  path_part   = "{id}"
}
```

**Gotchas:**
- Use `{proxy+}` as `path_part` for greedy path matching.
- `parent_id` for top-level resources should be `aws_api_gateway_rest_api.*.root_resource_id`.

---

### 2.3 `aws_api_gateway_method`

**URL:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method

**Required Arguments:**
| Argument | Description |
|---|---|
| `rest_api_id` | ID of the associated REST API |
| `resource_id` | API resource ID |
| `http_method` | HTTP method (`GET`, `POST`, `PUT`, `DELETE`, `HEAD`, `OPTIONS`, `ANY`) |
| `authorization` | Authorization type (`NONE`, `CUSTOM`, `AWS_IAM`, `COGNITO_USER_POOLS`) |

**Key Optional Arguments:**
| Argument | Description |
|---|---|
| `authorizer_id` | Authorizer ID (required when authorization is `CUSTOM` or `COGNITO_USER_POOLS`) |
| `authorization_scopes` | Scopes for `COGNITO_USER_POOLS` authorization |
| `api_key_required` | Whether an API key is required |
| `request_parameters` | Map of request parameters (path/query/header) with required flag |
| `request_models` | Map of API models for request content types |
| `request_validator_id` | ID of request validator |

**Example:**
```hcl
resource "aws_api_gateway_method" "get_products" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "GET"
  authorization = "NONE"
}

# OPTIONS method for CORS
resource "aws_api_gateway_method" "options_products" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}
```

**Gotchas:**
- You need a separate `OPTIONS` method on each resource for CORS preflight support.
- `request_parameters` format: `{"method.request.header.X-Some-Header" = true}` — `true` = required, `false` = optional.

---

### 2.4 `aws_api_gateway_integration`

**URL:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration

**Required Arguments:**
| Argument | Description |
|---|---|
| `rest_api_id` | ID of the associated REST API |
| `resource_id` | API resource ID |
| `http_method` | HTTP method when calling the associated resource |
| `type` | Integration type: `HTTP`, `MOCK`, `AWS`, `AWS_PROXY`, `HTTP_PROXY` |

**Key Optional Arguments:**
| Argument | Description |
|---|---|
| `integration_http_method` | Required for `AWS`, `AWS_PROXY`, `HTTP`, `HTTP_PROXY`. For Lambda: always `POST` |
| `uri` | Required for `AWS`, `AWS_PROXY`, `HTTP`, `HTTP_PROXY`. For Lambda: use `invoke_arn` |
| `credentials` | IAM role ARN for the integration |
| `request_templates` | Map of request templates |
| `request_parameters` | Map of request parameters to pass to backend |
| `passthrough_behavior` | `WHEN_NO_MATCH`, `WHEN_NO_TEMPLATES`, `NEVER` |
| `content_handling` | `CONVERT_TO_BINARY` or `CONVERT_TO_TEXT` |
| `timeout_milliseconds` | Default 29000, max 300000 (buffered) or 900000 (stream) |
| `connection_type` | `INTERNET` (default) or `VPC_LINK` |

**Example (Lambda Proxy):**
```hcl
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.products.id
  http_method             = aws_api_gateway_method.get_products.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# CORS OPTIONS mock integration
resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.options_products.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}
```

**Gotchas:**
- Lambda functions can **only be invoked via `POST`** — always set `integration_http_method = "POST"` for Lambda.
- `AWS_PROXY` (Lambda proxy) passes the entire request to Lambda and expects a specific response format.
- For `MOCK` integrations (commonly used for CORS), you need `request_templates` returning a status code.
- `timeout_milliseconds` minimum is 50ms. You need a Service Quota increase to go above 29000ms for buffered mode.

---

### 2.5 `aws_api_gateway_deployment`

**URL:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment

**Required Arguments:**
| Argument | Description |
|---|---|
| `rest_api_id` | REST API identifier |

**Key Optional Arguments:**
| Argument | Description |
|---|---|
| `description` | Description of the deployment |
| `triggers` | Map of arbitrary keys/values — changes trigger redeployment |
| `variables` | Map to set on the related stage |

**Example:**
```hcl
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.products.id,
      aws_api_gateway_method.get_products.id,
      aws_api_gateway_integration.lambda_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

**Gotchas:**
- **ALWAYS** use `lifecycle { create_before_destroy = true }` — without it, API Gateway returns `BadRequestException: Active stages pointing to this deployment must be moved or deleted`.
- Use `triggers` to ensure redeployment when upstream resources change. `depends_on` only handles ordering, not change detection.
- The `triggers` map should reference IDs of all resources/methods/integrations you want tracked.
- `variables` cannot be imported — use `aws_api_gateway_stage` instead.

---

### 2.6 `aws_api_gateway_stage`

**URL:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage

**Required Arguments:**
| Argument | Description |
|---|---|
| `rest_api_id` | ID of the associated REST API |
| `stage_name` | Name of the stage |
| `deployment_id` | ID of the deployment the stage points to |

**Key Optional Arguments:**
| Argument | Description |
|---|---|
| `access_log_settings` | Access logs config: `destination_arn` + `format` |
| `cache_cluster_enabled` | Enable cache cluster |
| `cache_cluster_size` | Cache size: `0.5`, `1.6`, `6.1`, `13.5`, `28.4`, `58.2`, `118`, `237` |
| `description` | Description of the stage |
| `variables` | Map of stage variables |
| `tags` | Map of tags |
| `xray_tracing_enabled` | Enable X-Ray tracing (default `false`) |

**Key Attributes:**
- `invoke_url` - URL to invoke the API (e.g., `https://z4675bid1j.execute-api.eu-west-2.amazonaws.com/prod`)
- `execution_arn` - Execution ARN for `lambda_permission` `source_arn`
- `arn` - ARN of the stage

**Example:**
```hcl
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "prod"

  variables = {
    environment = "production"
  }

  tags = {
    Environment = "prod"
  }
}
```

**Gotchas:**
- `invoke_url` is the callable endpoint for your API.
- For CloudWatch logging, the log group name must follow: `API-Gateway-Execution-Logs_{rest-api-id}/{stage-name}`.
- Use `depends_on` with `aws_cloudwatch_log_group` when enabling access logging.

---

## 3. Lambda Resources

### 3.1 `aws_lambda_function`

**URL:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function

**Required Arguments:**
| Argument | Description |
|---|---|
| `function_name` | Unique name for the function |
| `role` | ARN of the IAM role for the function |

**Key Optional Arguments:**
| Argument | Description |
|---|---|
| `handler` | Function entrypoint (required for Zip deployment, e.g., `index.handler`) |
| `runtime` | Runtime identifier (required for Zip, e.g., `nodejs20.x`, `python3.12`) |
| `filename` | Path to local deployment package (conflicts with `s3_bucket`/`image_uri`) |
| `s3_bucket` / `s3_key` / `s3_object_version` | S3 deployment package |
| `image_uri` | ECR image URI for container deployment |
| `source_code_hash` | Trigger updates when code changes: `filebase64sha256("file.zip")` |
| `layers` | List of layer ARNs (max 5) |
| `memory_size` | Memory in MB (128-10240, default 128) |
| `timeout` | Timeout in seconds (1-900, default 3) |
| `environment` | Environment variables block with `variables` map |
| `vpc_config` | VPC configuration: `subnet_ids` + `security_group_ids` |
| `architectures` | `["x86_64"]` (default) or `["arm64"]` |
| `tags` | Map of tags |

**Key Attributes:**
- `arn` - ARN of the function
- `invoke_arn` - ARN for API Gateway integration URI
- `qualified_arn` - Qualified ARN (with version)
- `version` - Latest published version

**Example:**
```hcl
resource "aws_lambda_function" "api_handler" {
  filename         = "lambda.zip"
  function_name    = "coffee-web-api-handler"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  source_code_hash = filebase64sha256("lambda.zip")
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.products.name
      NODE_ENV   = "production"
    }
  }

  layers = [aws_lambda_layer_version.common.arn]
}
```

**Gotchas:**
- `invoke_arn` is what you pass to `aws_api_gateway_integration.uri` — NOT `arn`.
- VPC-attached functions need a **45-minute delete timeout** due to ENI cleanup.
- `KMSAccessDeniedException` may occur if the IAM role is recreated — the function retains a reference to the old role.
- One of `filename`, `s3_bucket`+`s3_key`, or `image_uri` is required.
- Always set `source_code_hash` to detect code changes.

---

### 3.2 `aws_lambda_layer_version`

**URL:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_layer_version

**Required Arguments:**
| Argument | Description |
|---|---|
| `layer_name` | Unique name for the Lambda Layer |

**Key Optional Arguments:**
| Argument | Description |
|---|---|
| `filename` | Path to local deployment package |
| `s3_bucket` / `s3_key` / `s3_object_version` | S3 deployment package |
| `compatible_runtimes` | List of compatible runtimes (up to 15) |
| `compatible_architectures` | `["x86_64"]`, `["arm64"]`, or both |
| `description` | Description of the layer |
| `license_info` | License information |
| `source_code_hash` | Hash to trigger replacement |
| `skip_destroy` | (Default `false`) If `true`, old versions are retained |

**Key Attributes:**
- `arn` - ARN of the layer **with version** (use this in `aws_lambda_function.layers`)
- `layer_arn` - ARN without version
- `version` - Layer version number

**Example:**
```hcl
resource "aws_lambda_layer_version" "common" {
  filename         = "layer.zip"
  layer_name       = "coffee-web-common"
  source_code_hash = filebase64sha256("layer.zip")
  description      = "Common utilities for Coffee Web Lambda functions"

  compatible_runtimes      = ["nodejs20.x"]
  compatible_architectures = ["x86_64"]
}
```

**Gotchas:**
- Layer package structure depends on runtime (e.g., `nodejs/node_modules/` for Node.js).
- Changing any attribute (without `skip_destroy = true`) deletes the old version and creates a new one.
- `skip_destroy = true` creates dangling versions that are NOT managed by Terraform.
- For large packages, upload via S3 for better reliability.

---

### 3.3 `aws_lambda_permission`

**URL:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission

**Required Arguments:**
| Argument | Description |
|---|---|
| `action` | Lambda action (e.g., `lambda:InvokeFunction`) |
| `function_name` | Name or ARN of the Lambda function |
| `principal` | AWS service or account (e.g., `apigateway.amazonaws.com`) |

**Key Optional Arguments:**
| Argument | Description |
|---|---|
| `statement_id` | Unique identifier for the permission statement |
| `source_arn` | ARN of the source granting permission |
| `source_account` | AWS account ID of the source owner |
| `qualifier` | Function version or alias name |
| `principal_org_id` | AWS Organizations ID for org-wide permission |

**Example (API Gateway):**
```hcl
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
```

**Gotchas:**
- The `source_arn` pattern `execution_arn/*/*` allows invocation from **any stage, any method, any path**. Be more specific in production: `${execution_arn}/prod/GET/products`.
- `statement_id` is auto-generated if not provided, but explicit IDs make management clearer.
- Use `lifecycle { replace_triggered_by = [aws_lambda_function.example] }` to auto-update permissions when the function changes.

---

## 4. IAM Resources

### 4.1 `aws_iam_role`

**URL:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role

**Required Arguments:**
| Argument | Description |
|---|---|
| `assume_role_policy` | Trust policy (who can assume this role). Similar to but different from standard IAM policies |

**Key Optional Arguments:**
| Argument | Description |
|---|---|
| `name` | Name of the role (auto-generated if omitted) |
| `name_prefix` | Prefix for auto-generated name |
| `description` | Description of the role |
| `path` | Path (default `/`) |
| `permissions_boundary` | ARN of policy to set as permissions boundary |
| `force_detach_policies` | Whether to force detach policies before destroying |
| `max_session_duration` | Max session duration in seconds (3600-43200, default 3600) |
| `tags` | Map of tags |

**Key Attributes:**
- `arn` - ARN of the role
- `name` - Name of the role
- `id` - Name of the role

**Example:**
```hcl
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "coffee-web-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Project = "coffee-web"
  }
}
```

**Gotchas:**
- `inline_policy` and `managed_policy_arns` arguments are **DEPRECATED** — use `aws_iam_role_policy` and `aws_iam_role_policy_attachment` instead.
- Use `jsonencode()` or `aws_iam_policy_document` data source for the `assume_role_policy` — avoid raw JSON strings.
- `assume_role_policy` is a **trust policy** (who can assume), not a permissions policy (what they can do).

---

### 4.2 `aws_iam_policy`

**URL:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy

**Required Arguments:**
| Argument | Description |
|---|---|
| `policy` | Policy document (JSON string) |

**Key Optional Arguments:**
| Argument | Description |
|---|---|
| `name` | Name of the policy (auto-generated if omitted) |
| `name_prefix` | Prefix for auto-generated name |
| `description` | Description (Forces new resource) |
| `path` | Path (default `/`) |
| `tags` | Map of tags |

**Key Attributes:**
- `arn` - ARN of the policy (also the `id`)
- `policy_id` - Policy's ID
- `attachment_count` - Number of attached entities

**Example:**
```hcl
resource "aws_iam_policy" "lambda_dynamodb" {
  name        = "coffee-web-lambda-dynamodb"
  description = "Allow Lambda to access DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
        ]
        Resource = [
          aws_dynamodb_table.products.arn,
          "${aws_dynamodb_table.products.arn}/index/*",
        ]
      },
    ]
  })
}

# Attach to role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb.arn
}
```

**Gotchas:**
- Use `jsonencode()` or `aws_iam_policy_document` data source rather than raw JSON strings.
- `description` forces a new resource — changing it destroys and recreates the policy.
- Always attach via `aws_iam_role_policy_attachment`, NOT the deprecated `managed_policy_arns` on the role.

---

## 5. DynamoDB Resources

### 5.1 `aws_dynamodb_table`

**URL:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table

**Required Arguments:**
| Argument | Description |
|---|---|
| `name` | Name of the table |
| `hash_key` | Partition key attribute name |
| `attribute` | Attribute definitions (only for keys used in table/indexes) |

**Key Optional Arguments:**
| Argument | Description |
|---|---|
| `billing_mode` | `PROVISIONED` (default) or `PAY_PER_REQUEST` |
| `range_key` | Sort key attribute name |
| `read_capacity` | Required if `billing_mode` is `PROVISIONED` |
| `write_capacity` | Required if `billing_mode` is `PROVISIONED` |
| `global_secondary_index` | GSI definitions |
| `local_secondary_index` | LSI definitions |
| `ttl` | TTL configuration: `attribute_name` + `enabled` |
| `stream_enabled` | Enable DynamoDB Streams |
| `stream_view_type` | `KEYS_ONLY`, `NEW_IMAGE`, `OLD_IMAGE`, `NEW_AND_OLD_IMAGES` |
| `tags` | Map of tags |

**Key Attributes:**
- `arn` - ARN of the table
- `stream_arn` - ARN of the Table Stream (if enabled)

**Example:**
```hcl
resource "aws_dynamodb_table" "products" {
  name         = "coffee-web-products"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK"
  range_key    = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "GSI1PK"
    type = "S"
  }

  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "SK"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled        = true
  }

  tags = {
    Project     = "coffee-web"
    Environment = "dev"
  }
}
```

**Gotchas:**
- **Only define `attribute` blocks for attributes used as hash/range keys** (table or indexes). Defining unused attributes causes infinite planning loops.
- `PAY_PER_REQUEST` does not require `read_capacity`/`write_capacity`.
- LSIs can only be created at table creation time and cannot be modified later.
- GSI names must be unique within the table.

---

## 6. CORS Configuration for API Gateway

CORS with API Gateway REST API (not HTTP API) requires manual configuration of the `OPTIONS` method. Here's the complete pattern:

### Full CORS Pattern

```hcl
# 1. OPTIONS method
resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.products.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# 2. OPTIONS integration (MOCK)
resource "aws_api_gateway_integration" "options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# 3. OPTIONS method response
resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.options.http_method
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

# 4. OPTIONS integration response
resource "aws_api_gateway_integration_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.products.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT,DELETE'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}
```

**Notes:**
- With `AWS_PROXY` (Lambda proxy), the Lambda function itself must also return CORS headers in its response.
- The `OPTIONS` mock integration handles the preflight request only.
- For production, replace `'*'` with your actual domain.
- Each API resource path needs its own `OPTIONS` method/integration/response setup.
- Consider using `aws_api_gateway_gateway_response` for CORS headers on 4XX/5XX error responses.

---

## Quick Reference: Complete API Gateway + Lambda Pattern

```hcl
# REST API
resource "aws_api_gateway_rest_api" "api" { ... }

# Resource path
resource "aws_api_gateway_resource" "resource" { ... }

# Method (GET, POST, etc.)
resource "aws_api_gateway_method" "method" { ... }

# Lambda integration
resource "aws_api_gateway_integration" "integration" {
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.fn.invoke_arn
}

# Deployment (with triggers + create_before_destroy)
resource "aws_api_gateway_deployment" "deploy" { ... }

# Stage
resource "aws_api_gateway_stage" "stage" { ... }

# Lambda permission
resource "aws_lambda_permission" "apigw" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fn.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
```

**Resource dependency chain:** REST API → Resource → Method → Integration → Deployment → Stage
