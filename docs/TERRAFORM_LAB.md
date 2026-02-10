# TERRAFORM LAB - Part 1: S3 Frontend + API Gateway + Lambda

> **Phong cach tai lieu**: Expert documenting their exploration journey  
> **Ngon ngu**: Vietnamese (giai thich), English (code + terms ky thuat)  
> **Nguyen tac**: Moi khai niem deu co link toi trang doc GOC noi toi da tim thay no

---

## Muc luc

- [Gioi thieu: Tai sao Terraform?](#gioi-thieu-tai-sao-terraform)
- [Kien thuc nen truoc khi bat dau](#kien-thuc-nen-truoc-khi-bat-dau)
- [Cau truc project](#cau-truc-project)
- [Module 1: IAM - Role va Policy](#module-1-iam---role-va-policy)
- [Module 2: S3 Frontend - Static Website Hosting](#module-2-s3-frontend---static-website-hosting)
- [Module 3: Lambda Layer - Shared Dependencies](#module-3-lambda-layer---shared-dependencies)
- [Module 4: Lambda Functions](#module-4-lambda-functions)
- [Module 5: API Gateway - REST API voi CORS](#module-5-api-gateway---rest-api-voi-cors)
- [Root Module - Orchestrator](#root-module---orchestrator)
- [Huong dan thuc hanh: Deploy tu A-Z](#huong-dan-thuc-hanh-deploy-tu-a-z)
- [Kiem tra va Debug](#kiem-tra-va-debug)
- [Tong ket Part 1](#tong-ket-part-1)

---

## Gioi thieu: Tai sao Terraform?

### Van de voi setup thu cong (AWS Console)

Trong file `AWS_SETUP.md`, ta da setup moi thu bang tay qua AWS Console:
- Tao DynamoDB tables -> click, click, click
- Tao IAM Role -> click, click, paste JSON
- Tao Lambda functions -> click, paste code, deploy
- Tao API Gateway -> click, tao resource, tao method, enable CORS...

**Van de:**
1. **Khong lap lai duoc** (reproducibility): Lam sai 1 buoc -> phai lam lai tu dau
2. **Khong theo doi duoc thay doi** (tracking): Ai thay doi gi? Khi nao? Tai sao?
3. **Khong dễ xoa sach** (cleanup): Quen xoa 1 resource -> bi tinh tien
4. **Khong scale duoc**: 10 environments (dev, staging, prod) = lam tay 10 lan?

### Terraform giai quyet nhu the nao?

> **Nguon**: https://developer.hashicorp.com/terraform/intro

Terraform la **Infrastructure as Code (IaC)** tool:
- Viet code mo ta infrastructure -> chay 1 lenh -> AWS tu dong tao moi thu
- Muon xoa? `terraform destroy` -> het
- Muon thay doi? Sua code -> `terraform apply` -> chi thay doi phan can thiet
- Commit code vao Git -> theo doi duoc moi thay doi

### Terraform hoat dong nhu the nao?

```
                    terraform plan
                         |
                         v
  .tf files  ------>  Terraform  ------->  AWS API
  (mong muon)        (so sanh)           (thuc te)
                         |
                    terraform apply
                    (thuc thi thay doi)
```

> **Doc them**: https://developer.hashicorp.com/terraform/intro/core-workflow

**3 buoc co ban:**
1. **Write**: Viet file `.tf` mo ta resources can tao
2. **Plan**: `terraform plan` - Terraform cho ban xem no SE LAM GI (preview)
3. **Apply**: `terraform apply` - Terraform thuc su goi AWS API de tao/sua/xoa resources

**State file** (`terraform.tfstate`):
- Terraform luu trang thai hien tai cua infrastructure vao file nay
- Moi lan `apply`, Terraform so sanh state file voi code -> biet can thay doi gi
- **QUAN TRONG**: KHONG commit file nay vao Git (chua secrets, thay doi lien tuc)
- Doc: https://developer.hashicorp.com/terraform/language/state

---

## Kien thuc nen truoc khi bat dau

### HCL - HashiCorp Configuration Language

> **Nguon**: https://developer.hashicorp.com/terraform/language/syntax/configuration

Terraform dung ngon ngu rieng goi la HCL. Cu phap co ban:

```hcl
# Resource block: tao 1 AWS resource
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-unique-bucket-name"
  tags = {
    Name = "My Bucket"
  }
}
```

Giai thich:
- `resource` = keyword (tao resource tren cloud)
- `"aws_s3_bucket"` = resource TYPE (AWS S3 Bucket)
- `"my_bucket"` = resource NAME (ten dung trong Terraform, KHONG phai ten tren AWS)
- `{ ... }` = configuration block

Cac kieu block khac:
- `variable` = bien dau vao
- `output` = gia tri dau ra
- `data` = doc thong tin tu cloud (khong tao gi)
- `module` = goi module khac
- `provider` = cau hinh cloud provider (AWS, GCP, Azure)
- `locals` = bien noi bo

### Modules - To chuc code

> **Nguon**: https://developer.hashicorp.com/terraform/language/modules

Module = "package" cua Terraform. Giong nhu function trong code:
- Co inputs (variables) va outputs
- Co the tai su dung (reusable)
- Giup to chuc code ro rang

```
terraform/
├── main.tf          # Goi cac modules
├── modules/
│   ├── iam/         # Module rieng cho IAM
│   ├── s3-frontend/ # Module rieng cho S3
│   ├── lambda/      # Module rieng cho Lambda
│   └── api-gateway/ # Module rieng cho API Gateway
```

### References giua Resources

> **Nguon**: https://developer.hashicorp.com/terraform/language/expressions/references

Resource A co the tham chieu gia tri cua resource B:

```hcl
# IAM Role tao truoc
resource "aws_iam_role" "lambda_exec" {
  name = "my-role"
}

# Lambda function dung role ARN cua IAM Role
resource "aws_lambda_function" "my_func" {
  role = aws_iam_role.lambda_exec.arn  # <-- reference!
}
```

Terraform doc reference -> biet phai tao IAM Role TRUOC Lambda function.
Day goi la **implicit dependency** (phu thuoc ngam dinh).

---

## Cau truc project

```
terraform/
├── main.tf                    # Root orchestrator - goi tat ca modules
├── variables.tf               # Bien dau vao (region, bucket name, jwt secret)
├── outputs.tf                 # Gia tri dau ra (API URL, website URL)
├── providers.tf               # AWS provider config
├── terraform.tfvars.example   # File mau cau hinh (copy thanh .tfvars)
├── .gitignore                 # Ignore state files, .tfvars, .zip
│
├── lambda-src/                # Source code cua Lambda functions
│   ├── get-products/
│   │   └── index.mjs
│   ├── create-order/
│   │   └── index.mjs
│   ├── get-orders/
│   │   └── index.mjs
│   ├── register-user/
│   │   └── index.mjs
│   ├── login-user/
│   │   └── index.mjs
│   └── layer/
│       └── nodejs/
│           └── package.json   # bcryptjs + jsonwebtoken
│
└── modules/
    ├── iam/                   # IAM Role + Policy cho Lambda
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── s3-frontend/           # S3 Static Website Hosting
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── lambda-layer/          # Lambda Layer (shared npm packages)
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── lambda/                # 5 Lambda functions
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── api-gateway/           # REST API + CORS + Deployment
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## Module 1: IAM - Role va Policy

> **File**: `terraform/modules/iam/main.tf`

### Ly thuyet: IAM la gi?

> **Nguon**: https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html

IAM (Identity and Access Management) quan ly **ai duoc phep lam gi** tren AWS.

3 khai niem chinh:
| Khai niem | Giai thich | Vi du |
|-----------|-----------|-------|
| **Role** | "Danh tinh" co quyen cu the | CoffeeLambdaRole |
| **Trust Policy** | "Ai duoc dung role nay?" | Lambda service |
| **Permission Policy** | "Role nay duoc lam gi?" | Doc/ghi DynamoDB |

### Terraform resources su dung

| Resource | Doc goc | Chuc nang |
|----------|---------|-----------|
| `aws_iam_role` | [Link](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | Tao IAM Role |
| `aws_iam_policy` | [Link](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | Tao Permission Policy |
| `aws_iam_role_policy_attachment` | [Link](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | Gan policy vao role |

### Trong code ta lam gi?

```hcl
# 1. Tao Role voi Trust Policy cho Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "CoffeeLambdaRole"
  assume_role_policy = jsonencode({
    Statement = [{
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# 2. Tao Policy cho DynamoDB + CloudWatch + S3 + SES
resource "aws_iam_policy" "lambda_policy" { ... }

# 3. Attach policy vao role
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
```

### jsonencode() function

> **Nguon**: https://developer.hashicorp.com/terraform/language/functions/jsonencode

`jsonencode()` chuyen HCL map/list thanh JSON string. Rat tien loi vi:
- Viet JSON trong HCL kho doc (phai escape quotes)
- jsonencode() cho phep viet bang HCL syntax roi tu dong convert

### Bai hoc rut ra

1. **Principle of Least Privilege**: Chi cap DUNG quyen can thiet
   - DynamoDB: chi cac actions can dung (PutItem, GetItem, Query, Scan, UpdateItem, DeleteItem)
   - Resource: chi cac tables bat dau bang "Coffee*" (khong phai TAT CA tables)
2. **Trust Policy vs Permission Policy**: 2 thu khac nhau!
   - Trust = AI duoc dung role
   - Permission = role DUOC LAM GI

---

## Module 2: S3 Frontend - Static Website Hosting

> **File**: `terraform/modules/s3-frontend/main.tf`

### Ly thuyet: S3 Static Website Hosting

> **Nguon**: https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html

S3 (Simple Storage Service) la dich vu luu tru objects (files) tren AWS.
Tinh nang "Static Website Hosting" bien S3 bucket thanh web server:

```
Browser -> http://bucket.s3-website-region.amazonaws.com -> S3 tra ve file
```

### QUAN TRONG: Terraform Provider v4 Breaking Changes

> **Nguon**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/version-4-upgrade

Tu AWS Provider v4+, nhieu config truoc day dat TRONG `aws_s3_bucket` (inline blocks) da bi **deprecated**. Phai dung **resource rieng**:

| Truoc (deprecated) | Sau (hien tai) |
|---------------------|----------------|
| `aws_s3_bucket { website { } }` | `aws_s3_bucket_website_configuration` |
| `aws_s3_bucket { policy = "..." }` | `aws_s3_bucket_policy` |
| `aws_s3_bucket { server_side_encryption_configuration { } }` | `aws_s3_bucket_server_side_encryption_configuration` |

Toi da tim thay dieu nay khi doc trang:
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket

### Terraform resources su dung

| Resource | Doc goc | Chuc nang |
|----------|---------|-----------|
| `aws_s3_bucket` | [Link](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | Tao S3 bucket |
| `aws_s3_bucket_website_configuration` | [Link](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration) | Bat Static Website Hosting |
| `aws_s3_bucket_public_access_block` | [Link](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | Tat Block Public Access |
| `aws_s3_bucket_policy` | [Link](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | Them Bucket Policy cho public read |

### SPA Routing trick

```hcl
error_document {
  key = "index.html"    # <-- Bi quyet!
}
```

**Tai sao `error_document = index.html`?**

React la SPA (Single Page Application). Chi co 1 file HTML (`index.html`).
Khi user truy cap `/products/123`:
1. S3 tim file `products/123` -> KHONG CO -> 404
2. S3 tra ve `error_document` = `index.html`
3. React Router chay trong browser -> render component cho `/products/123`

### depends_on - Explicit dependency

> **Nguon**: https://developer.hashicorp.com/terraform/language/meta-arguments/depends_on

```hcl
resource "aws_s3_bucket_policy" "frontend" {
  # ...
  depends_on = [aws_s3_bucket_public_access_block.frontend]
}
```

Binh thuong Terraform tu biet dependency tu references (implicit).
Nhung doi khi Terraform KHONG BIET, vi du:
- Phai tat Block Public Access TRUOC khi apply Bucket Policy
- Noi dung policy khong reference den public_access_block
- Terraform nghi 2 resources doc lap -> tao SONG SONG -> LOI!

`depends_on` = noi ro voi Terraform: "Tao cai nay TRUOC khi toi!"

### Bai hoc rut ra

1. **force_destroy**: Development dung `true`, production dung `false`
2. **S3 bucket names phai globally unique**: Khong chi unique trong account cua ban, ma tren TOAN BO AWS!
3. **Luon doc migration guide khi dung provider version moi**: Nhieu inline blocks bi deprecated

---

## Module 3: Lambda Layer - Shared Dependencies

> **File**: `terraform/modules/lambda-layer/main.tf`

### Ly thuyet: Lambda Layer la gi?

> **Nguon**: https://docs.aws.amazon.com/lambda/latest/dg/chapter-layers.html

Lambda Layer = goi shared code/dependencies dung chung giua nhieu functions.

**Van de**: Functions `register-user` va `login-user` can `bcryptjs` + `jsonwebtoken`.
**Giai phap 1**: Package moi function voi `node_modules` (nang, ~10MB x 2)
**Giai phap 2**: Tao 1 Layer chua dependencies, attach vao 2 functions (chi 1 ban)

Lambda Layer duoc mount o `/opt/nodejs/` trong runtime:
```
/opt/nodejs/
  └── node_modules/
      ├── bcryptjs/
      └── jsonwebtoken/
```

Node.js tu dong tim modules o `/opt/nodejs/node_modules/`

### Cau truc ZIP bat buoc

> **Nguon**: https://docs.aws.amazon.com/lambda/latest/dg/packaging-layers.html

```
layer.zip/
  └── nodejs/          # PHAI co thu muc nay
      ├── package.json
      └── node_modules/
          ├── bcryptjs/
          └── jsonwebtoken/
```

- Thu muc **phai ten la `nodejs`** (khong phai `node_modules` hay ten khac)
- Day la convention cua AWS Lambda cho Node.js runtime

### Data Source vs Resource

> **Nguon**: https://developer.hashicorp.com/terraform/language/data-sources

```hcl
# DATA SOURCE - doc thong tin, KHONG tao gi tren AWS
data "archive_file" "layer" {
  type        = "zip"
  source_dir  = var.layer_source_dir
  output_path = "${path.module}/builds/layer.zip"
}

# RESOURCE - tao resource tren AWS
resource "aws_lambda_layer_version" "dependencies" {
  filename         = data.archive_file.layer.output_path
  source_code_hash = data.archive_file.layer.output_base64sha256
}
```

- `data` = doc thong tin roi dung (vi du: zip file, doc AWS account ID)
- `resource` = tao/sua/xoa resource tren cloud

### source_code_hash - Detect Changes

```hcl
source_code_hash = data.archive_file.layer.output_base64sha256
```

Terraform so sanh hash cu vs moi:
- **Hash giong nhau**: Terraform SKIP upload (tiet kiem thoi gian + bandwidth)
- **Hash khac nhau**: Terraform tao LAYER VERSION MOI va upload code moi

**Luu y**: Moi lan update layer -> NEW version (v1, v2, v3...). Lambda functions van dung version cu cho den khi ta update `layers` attribute cua function.

---

## Module 4: Lambda Functions

> **File**: `terraform/modules/lambda/main.tf`

### Ly thuyet: Lambda function hoat dong nhu the nao?

> **Nguon**: https://docs.aws.amazon.com/lambda/latest/dg/welcome.html

```
Client -> API Gateway -> Lambda function -> DynamoDB -> Response
```

1. Client gui HTTP request (POST /orders)
2. API Gateway nhan request, chuyen TOAN BO vao Lambda event object
3. Lambda function chay code xu ly request
4. Lambda tra ve response { statusCode, headers, body }
5. API Gateway chuyen response ve client

### Handler format

```
handler = "index.handler"
```

Nghia la: file `index.mjs` (hoac `index.js`), export function ten `handler`

```javascript
// index.mjs
export const handler = async (event) => {
  // event = toan bo HTTP request tu API Gateway
  return {
    statusCode: 200,
    body: JSON.stringify({ message: "Hello" })
  };
};
```

### Environment Variables - Khong hardcode!

> **Nguon**: https://docs.aws.amazon.com/lambda/latest/dg/configuration-envvars.html

```hcl
environment {
  variables = {
    ORDERS_TABLE = "CoffeeOrders"  # Lambda doc: process.env.ORDERS_TABLE
    JWT_SECRET   = var.jwt_secret   # Sensitive! Terraform se an gia tri
  }
}
```

**Tai sao khong hardcode ten table trong code?**
- Dev dung `CoffeeOrders-dev`, prod dung `CoffeeOrders-prod`
- Doi table? Chi sua Terraform, khong can sua code
- Secrets (JWT_SECRET) KHONG BAO GIO nam trong source code

### CloudWatch Log Groups - Tao truoc Lambda

```hcl
resource "aws_cloudwatch_log_group" "get_products" {
  name              = "/aws/lambda/coffee-get-products"  # Format bat buoc!
  retention_in_days = 7
}

resource "aws_lambda_function" "get_products" {
  # ...
  depends_on = [aws_cloudwatch_log_group.get_products]
}
```

**Tai sao tao Log Group truoc?**
- Lambda tu dong tao log group NEU chua co
- Nhung: Lambda tao voi retention = **NEVER EXPIRE** (ton tien!)
- Tao truoc -> ta kiem soat `retention_in_days` (7 ngay cho dev, 30 cho prod)

### sensitive = true

> **Nguon**: https://developer.hashicorp.com/terraform/language/values/variables#suppressing-values-in-cli-output

```hcl
variable "jwt_secret" {
  type      = string
  sensitive = true  # An gia tri trong terminal output
}
```

Khi `terraform plan` hoac `apply`:
```
# Thay vi hien:  jwt_secret = "my-super-secret-key"
# Terraform hien: jwt_secret = (sensitive value)
```

### AWS_REGION_ - Reserved name workaround

```hcl
environment {
  variables = {
    AWS_REGION_ = var.aws_region  # Co dau _ o cuoi!
  }
}
```

`AWS_REGION` la **reserved environment variable** cua Lambda.
AWS tu dong set no = region noi Lambda chay.
Nen ta KHONG DUOC dung ten `AWS_REGION` -> dung `AWS_REGION_` thay the.

Thuc te, trong code Lambda ta khong can set region vi DynamoDBClient tu dong dung region cua Lambda. Variable nay chi la backup/reference.

---

## Module 5: API Gateway - REST API voi CORS

> **File**: `terraform/modules/api-gateway/main.tf`

### Ly thuyet: API Gateway

> **Nguon**: https://docs.aws.amazon.com/apigateway/latest/developerguide/welcome.html

API Gateway la "cua truoc" cua backend:

```
                    API Gateway
                        |
   GET /products  -->  Lambda: get-products
   POST /orders   -->  Lambda: create-order
   GET /orders    -->  Lambda: get-orders
   POST /auth/register --> Lambda: register-user
   POST /auth/login    --> Lambda: login-user
```

### REST API vs HTTP API

| | REST API | HTTP API |
|--|---------|----------|
| **Gia** | $3.50/trieu requests | $1.00/trieu requests |
| **Features** | Day du (API keys, caching, WAF) | Basic |
| **CORS** | Phai config thu cong | Tu dong |
| **Terraform** | Nhieu resources | It resources |

Ta dung REST API (theo AWS_SETUP.md). Phuc tap hon nhung hoc duoc nhieu hon!

### Cau truc API Gateway trong Terraform

> **Nguon**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api

Moi endpoint can **5 Terraform resources**:

```
1. aws_api_gateway_resource      -> URL path (/products)
2. aws_api_gateway_method        -> HTTP method (GET)
3. aws_api_gateway_integration   -> Ket noi voi Lambda
4. aws_lambda_permission         -> Cho phep API GW invoke Lambda
5. + CORS (4 resources cho OPTIONS method)
```

Tong cong cho 5 endpoints = **~40 Terraform resources** chi rieng API Gateway module!

### Lambda Proxy Integration

> **Nguon**: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html

```hcl
resource "aws_api_gateway_integration" "get_products" {
  type                    = "AWS_PROXY"         # Lambda Proxy!
  integration_http_method = "POST"              # LUON la POST!
  uri                     = var.invoke_arn       # Lambda function ARN
}
```

**BAY LOI PHO BIEN: `integration_http_method`**

Nhieu nguoi dat `integration_http_method = "GET"` cho GET endpoint. **SAI!**

- `http_method` (tren method) = HTTP method ma CLIENT gui (GET, POST)
- `integration_http_method` = method ma API Gateway dung de GOI Lambda qua AWS API
- AWS API **chi chap nhan POST** de invoke Lambda
- **Luon dat "POST"** bat ke client method la gi!

### CORS - Cross-Origin Resource Sharing

> **Nguon**: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS

**Van de:**
```
Frontend: http://bucket.s3-website-ap-southeast-1.amazonaws.com  (origin A)
Backend:  https://abc123.execute-api.ap-southeast-1.amazonaws.com (origin B)
```

Browser co **Same-Origin Policy**: chi cho request den CUNG origin.
Frontend va Backend **KHAC origin** -> Browser BLOCK request!

**Giai phap: CORS headers**

Browser gui **preflight request** (OPTIONS) truoc:
```
OPTIONS /products HTTP/1.1
Origin: http://bucket.s3-website.amazonaws.com
Access-Control-Request-Method: GET
```

Server phai tra loi:
```
HTTP/1.1 200 OK
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
```

Browser thay CORS headers -> cho phep GUI request thuc (GET /products).

### CORS Pattern trong Terraform (4 resources moi endpoint)

```hcl
# 1. OPTIONS method
resource "aws_api_gateway_method" "products_options" {
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# 2. MOCK integration (khong goi Lambda, tu tra response)
resource "aws_api_gateway_integration" "products_options" {
  type = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# 3. Method Response (khai bao response SE co headers nao)
resource "aws_api_gateway_method_response" "products_options" {
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# 4. Integration Response (gia tri THUC TE cua headers)
resource "aws_api_gateway_integration_response" "products_options" {
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
  }
}
```

**Luu y quan trong**: Gia tri headers duoc BAO BQUI QUOTE DON `'...'`:
```
"'*'"              # Dung! (co quote don ben trong)
"*"                # SAI! API Gateway se bao loi
```

Day la quirk cua API Gateway REST API. Values phai la static string bao boi single quotes.

### Deployment + Stage

> **Nguon**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment

```hcl
resource "aws_api_gateway_deployment" "coffee_api" {
  triggers = {
    redeployment = sha1(jsonencode([...list of resource IDs...]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  stage_name = "prod"
}
```

**Tai sao can `triggers`?**
- Terraform chi tao deployment khi CO THAY DOI
- Nhung Terraform khong tu biet khi methods/integrations thay doi
- `triggers.redeployment` = hash cua tat ca resource IDs
- Resource thay doi -> hash thay doi -> Terraform tao deployment moi

**Tai sao can `create_before_destroy`?**
- Mac dinh: xoa cu -> tao moi = DOWNTIME
- Voi flag nay: tao moi -> xoa cu = ZERO DOWNTIME

### Lambda Permission

> **Nguon**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission

```hcl
resource "aws_lambda_permission" "get_products" {
  action        = "lambda:InvokeFunction"
  function_name = var.get_products_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.coffee_api.execution_arn}/*/*"
}
```

**Day la resource QUAN TRONG nhat** ma nhieu nguoi QUEN!

Ngay ca khi integration da duoc cau hinh, API Gateway van KHONG THE invoke Lambda neu khong co **resource-based policy** tren Lambda function.

Thieu permission nay -> API tra ve **500 Internal Server Error**:
```json
{"message": "Internal server error"}
```

CloudWatch Logs cua API Gateway se ghi:
```
Execution failed due to configuration error: Invalid permissions on Lambda function
```

---

## Root Module - Orchestrator

> **File**: `terraform/main.tf`

### Module calls va dependency chain

```hcl
module "iam" {
  source = "./modules/iam"
  # ... config
}

module "lambda" {
  source          = "./modules/lambda"
  lambda_role_arn = module.iam.role_arn  # <-- Implicit dependency!
  layer_arns      = [module.lambda_layer.layer_arn]
}

module "api_gateway" {
  source                   = "./modules/api-gateway"
  get_products_invoke_arn  = module.lambda.get_products_invoke_arn  # <-- Dependency!
}
```

Terraform tu doc dependency chain:
```
IAM -> Lambda Layer -> Lambda -> API Gateway
           |                        |
           +---- depends on --------+
```

### Local Values

> **Nguon**: https://developer.hashicorp.com/terraform/language/values/locals

```hcl
locals {
  common_tags = {
    Project     = "CoffeeShop"
    ManagedBy   = "Terraform"
    Environment = var.stage_name
  }
}
```

`locals` khac `variable`:
- `variable` = nguoi dung truyen vao (tu ben ngoai)
- `locals` = tinh toan ben trong (khong the override)

Dung locals cho gia tri DUNG DI DUNG LAI nhieu noi (tags, naming conventions).

---

## Huong dan thuc hanh: Deploy tu A-Z

### Prerequisites

1. **Terraform >= 1.6.0**
   ```powershell
   # Download: https://developer.hashicorp.com/terraform/install
   terraform version
   ```

2. **AWS CLI configured**
   ```powershell
   aws configure
   # AWS Access Key ID: [tu IAM user]
   # AWS Secret Access Key: [tu IAM user]
   # Default region: ap-southeast-1
   ```

3. **Node.js + npm** (cho Lambda Layer)
   ```powershell
   node --version   # >= 18.x
   npm --version
   ```

### Buoc 1: Cau hinh

```powershell
cd terraform

# Copy file mau
cp terraform.tfvars.example terraform.tfvars

# Sua terraform.tfvars:
# - frontend_bucket_name = "coffee-shop-frontend-<ten-cua-ban>"
# - jwt_secret = "<tao random: openssl rand -hex 32>"
```

### Buoc 2: Install Lambda Layer dependencies

```powershell
cd lambda-src/layer/nodejs
npm install
cd ../../..
```

Sau khi install, folder structure se la:
```
lambda-src/layer/
  └── nodejs/
      ├── package.json
      ├── package-lock.json
      └── node_modules/    # <-- Moi tao
          ├── bcryptjs/
          └── jsonwebtoken/
```

### Buoc 3: Terraform Init

```powershell
terraform init
```

Output:
```
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 5.0"...
- Installing hashicorp/aws v5.x.x...
Terraform has been successfully initialized!
```

`terraform init`:
- Download AWS provider plugin
- Download archive provider plugin
- Tao thu muc `.terraform/` (giong `node_modules/`)

### Buoc 4: Terraform Plan

```powershell
terraform plan
```

Output se hien thi TAT CA resources se duoc tao:
```
Plan: 30 to add, 0 to change, 0 to destroy.
```

Doc ky output de kiem tra:
- Co dung resources khong?
- Co sai ten khong?
- Co thieu gi khong?

### Buoc 5: Terraform Apply

```powershell
terraform apply
```

Terraform hoi xac nhan:
```
Do you want to perform these actions?
  Enter a value: yes
```

Doi 2-5 phut de AWS tao tat ca resources.

Output cuoi cung:
```
Apply complete! Resources: 30 added, 0 changed, 0 destroyed.

Outputs:
  api_url = "https://xxxxxx.execute-api.ap-southeast-1.amazonaws.com/prod"
  website_url = "http://coffee-shop-frontend-xxx.s3-website-ap-southeast-1.amazonaws.com"
```

### Buoc 6: Deploy Frontend

```powershell
cd ..  # Ve root project

# Cap nhat .env voi API URL tu terraform output
# VITE_API_BASE_URL=https://xxxxxx.execute-api.ap-southeast-1.amazonaws.com/prod

# Build frontend
npm run build

# Upload len S3
aws s3 sync dist/ s3://coffee-shop-frontend-<ten-cua-ban>
```

### Buoc 7: Test

1. Mo browser -> truy cap website URL
2. Test GET products: `curl <api_url>/products`
3. Test register: `curl -X POST <api_url>/auth/register -H "Content-Type: application/json" -d '{"email":"test@test.com","password":"password123","name":"Test"}'`

---

## Kiem tra va Debug

### Terraform Commands huu ich

| Command | Chuc nang |
|---------|-----------|
| `terraform plan` | Xem truoc thay doi |
| `terraform apply` | Thuc thi thay doi |
| `terraform destroy` | XOA TAT CA resources |
| `terraform output` | Hien thi outputs |
| `terraform output -raw api_url` | Lay 1 output (cho scripts) |
| `terraform state list` | Liet ke tat ca resources dang quan ly |
| `terraform state show module.lambda.aws_lambda_function.get_products` | Xem chi tiet 1 resource |
| `terraform fmt` | Format code .tf cho dep |
| `terraform validate` | Kiem tra cu phap |

### Loi thuong gap

**1. S3 bucket name da ton tai**
```
Error: error creating S3 Bucket: BucketAlreadyExists
```
-> Doi `frontend_bucket_name` trong terraform.tfvars

**2. Lambda source code chua co**
```
Error: error creating Lambda Function: InvalidParameterValueException
```
-> Kiem tra file `lambda-src/*/index.mjs` co ton tai khong

**3. Lambda Layer chua install dependencies**
```
Error: archive_file.layer: error creating archive
```
-> Chay `cd lambda-src/layer/nodejs && npm install`

**4. CORS error trong browser**
```
Access to fetch at 'https://xxx' from origin 'http://xxx' has been blocked by CORS policy
```
-> Kiem tra OPTIONS method va CORS headers trong API Gateway module
-> Kiem tra Lambda response co `Access-Control-Allow-Origin: *` header

**5. 500 Internal Server Error tu API Gateway**
```
{"message": "Internal server error"}
```
-> Kiem tra CloudWatch Logs cua Lambda function
-> Thuong la loi trong code Lambda hoac thieu Lambda Permission

---

## Tong ket Part 1

### Resources da tao

| Module | Resources | So luong |
|--------|-----------|---------|
| IAM | Role, Policy, Attachment | 3 |
| S3 Frontend | Bucket, Website Config, Public Access, Policy | 4 |
| Lambda Layer | Archive, Layer Version | 1+1 data |
| Lambda | 5 Functions, 5 Log Groups, 5 Archives | 10+5 data |
| API Gateway | REST API, 5 Resources, 10 Methods (5 real + 5 OPTIONS), 10 Integrations, 5 Method Responses, 5 Integration Responses, 5 Lambda Permissions, 1 Deployment, 1 Stage | ~35 |
| **Tong** | | **~55** |

### Terraform concepts da hoc

1. **Providers**: AWS, Archive
2. **Resources**: Tao resources tren cloud
3. **Data Sources**: Doc thong tin (archive_file)
4. **Variables**: Input voi validation, sensitive
5. **Outputs**: Hien thi gia tri quan trong
6. **Modules**: To chuc code thanh packages
7. **Dependencies**: Implicit (references) va Explicit (depends_on)
8. **Locals**: Bien noi bo
9. **Functions**: jsonencode(), sha1()
10. **Lifecycle**: create_before_destroy

### Next: Part 2

Part 2 se cover:
- **DynamoDB Module**: 4 tables voi GSIs
- **S3 Images Module**: Bucket cho product images voi compression
- **Terraform concepts moi**: for_each, dynamic blocks, conditional expressions

---

> **Document**: TERRAFORM_LAB.md - Part 1  
> **Author**: Generated for Coffee Shop IaC learning project  
> **References**: Tat ca links trong document deu tro den documentation GOC cua  
> HashiCorp Terraform Registry hoac AWS Documentation

---
---

# TERRAFORM LAB - Part 2: DynamoDB + S3 Images

> **Tiep noi Part 1** - da co S3 Frontend, API Gateway, Lambda  
> **Part 2 them**: DynamoDB tables (4 bang), S3 Images bucket  
> **Concepts moi**: `for_each`, `dynamic` blocks, `count`, `optional()`, `try()`, `lookup()`, `for` expressions

---

## Muc luc Part 2

- [Gioi thieu Part 2](#gioi-thieu-part-2)
- [Terraform Concepts moi](#terraform-concepts-moi)
- [Module 6: DynamoDB - 4 Tables voi GSIs](#module-6-dynamodb---4-tables-voi-gsis)
- [Module 7: S3 Images - Private Image Storage](#module-7-s3-images---private-image-storage)
- [Root Module Updates](#root-module-updates)
- [Huong dan thuc hanh Part 2](#huong-dan-thuc-hanh-part-2)
- [Tong ket Part 2](#tong-ket-part-2)

---

## Gioi thieu Part 2

### Dang o dau?

Sau Part 1, ta da co:
```
[S3 Frontend] -> [API Gateway] -> [Lambda Functions] -> ???
```

Lambda functions da duoc tao va cau hinh voi DynamoDB table names qua environment variables. Nhung **chua co DynamoDB tables thuc te**! Lambda se bi loi `ResourceNotFoundException` khi co goi API.

### Part 2 them gi?

```
[S3 Frontend] -> [API Gateway] -> [Lambda Functions] -> [DynamoDB Tables] ✅
                                                     -> [S3 Images]       ✅
```

1. **DynamoDB Module**: 4 tables voi GSIs, su dung `for_each` + `dynamic`
2. **S3 Images Module**: Private bucket cho product images voi CORS, versioning, lifecycle, encryption

### Tai sao hoc for_each + dynamic?

Trong Part 1, moi Lambda function la 1 resource block rieng. 5 functions = 5 blocks (copy-paste).

Nhung 4 DynamoDB tables co cau truc TUONG TU nhau (table name, keys, GSIs). Copy-paste 4 lan = **code smell!**

`for_each` cho phep tao 4 tables tu 1 resource block duy nhat. Day la buoc tien QUAN TRONG tu "viet Terraform" sang "viet Terraform nhu expert".

---

## Terraform Concepts moi

### for_each - Tao nhieu resources tu 1 block

> **Nguon**: https://developer.hashicorp.com/terraform/language/meta-arguments/for_each

```hcl
# THAY VI:
resource "aws_dynamodb_table" "products" { name = "CoffeeProducts" ... }
resource "aws_dynamodb_table" "orders"   { name = "CoffeeOrders"   ... }
resource "aws_dynamodb_table" "users"    { name = "CoffeeUsers"    ... }
resource "aws_dynamodb_table" "reviews"  { name = "CoffeeReviews"  ... }

# DUNG for_each:
resource "aws_dynamodb_table" "tables" {
  for_each = var.tables    # Map voi 4 entries
  name     = each.value.name
  hash_key = each.value.hash_key
}
```

`for_each` nhan map hoac set -> tao 1 resource cho MOI phan tu:
- `each.key` = key cua map entry (vd: "products", "orders")
- `each.value` = value cua map entry (vd: { name = "CoffeeProducts", ... })

Resource address se la:
```
aws_dynamodb_table.tables["products"]
aws_dynamodb_table.tables["orders"]
aws_dynamodb_table.tables["users"]
aws_dynamodb_table.tables["reviews"]
```

**So sanh for_each vs count:**

| | `for_each` | `count` |
|---|-----------|---------|
| **Input** | Map hoac Set | Number |
| **Address** | `resource["key"]` | `resource[0]`, `resource[1]` |
| **Xoa 1 item** | Chi xoa item do | Xoa va tao lai tat ca items sau no! |
| **Khi nao dung** | Nhieu resources tuong tu | Bat/tat resource (count = 0 hoac 1) |

**Uu diem cua for_each**: Xoa `reviews` khong anh huong `products`, `orders`, `users`.
Voi `count`, xoa item [1] -> items [2], [3] deu bi tao lai!

### dynamic blocks - Tao nhieu nested blocks

> **Nguon**: https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks

Mot so resources can NHIEU nested blocks tuong tu nhau (vd: attribute, GSI):

```hcl
# THAY VI (hardcode):
attribute { name = "productId"; type = "S" }
attribute { name = "createdAt"; type = "N" }
attribute { name = "userId";    type = "S" }

# DUNG dynamic:
dynamic "attribute" {
  for_each = each.value.attributes   # List cac attributes
  content {
    name = attribute.value.name
    type = attribute.value.type
  }
}
```

`dynamic` giong `for_each` nhung dung cho **nested blocks** (blocks ben trong resource).

### try() - Truy cap an toan

> **Nguon**: https://developer.hashicorp.com/terraform/language/functions/try

```hcl
range_key = try(each.value.range_key, null)
```

`try(expr1, expr2)`: Thu tinh expr1, neu LOI (attribute khong ton tai) -> tra ve expr2.
Giong `?.` (optional chaining) trong JavaScript:
```javascript
const rangeKey = each.value?.range_key ?? null;
```

### lookup() - Tim gia tri trong map

> **Nguon**: https://developer.hashicorp.com/terraform/language/functions/lookup

```hcl
projection_type = lookup(gsi.value, "projection_type", "ALL")
```

`lookup(map, key, default)`: Tim `key` trong `map`, neu khong co -> tra ve `default`.
Giong `map.get(key) || default` trong JavaScript.

### optional() - Optional object attributes

> **Nguon**: https://developer.hashicorp.com/terraform/language/expressions/type-constraints#optional-object-type-attributes

```hcl
type = map(object({
  name      = string              # Bat buoc
  range_key = optional(string)    # Optional, default = null
  projection_type = optional(string, "ALL")  # Optional, default = "ALL"
}))
```

`optional(type)`: Attribute co the co hoac khong. Neu khong -> null.
`optional(type, default)`: Neu khong co -> dung default value.

### count - Bat/tat resource

> **Nguon**: https://developer.hashicorp.com/terraform/language/meta-arguments/count

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "images" {
  count  = var.enable_lifecycle ? 1 : 0   # 1 = tao, 0 = khong tao
  bucket = aws_s3_bucket.images.id
}
```

`count = 0` la cach Terraform lam **conditional resource** (if-else):
- `var.enable_lifecycle = true`  -> `count = 1` -> tao resource
- `var.enable_lifecycle = false` -> `count = 0` -> KHONG tao

### for expression - Transform collections

> **Nguon**: https://developer.hashicorp.com/terraform/language/expressions/for

```hcl
# Tao map tu for_each resources
output "table_names" {
  value = {
    for key, table in aws_dynamodb_table.tables : key => table.name
  }
}
# Ket qua: { products = "CoffeeProducts", orders = "CoffeeOrders", ... }
```

`for` expression giong `Array.map()` trong JavaScript:
- `{ for k, v in map : k => v.attr }` -> tao MAP moi
- `[ for v in list : v.attr ]` -> tao LIST moi

---

## Module 6: DynamoDB - 4 Tables voi GSIs

> **File**: `terraform/modules/dynamodb/main.tf`

### DynamoDB la gi?

> **Nguon**: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/Introduction.html

DynamoDB la fully-managed NoSQL database cua AWS:
- **Serverless**: Khong can tao/quan ly server
- **Auto-scaling**: Tu dong tang/giam capacity
- **Single-digit millisecond**: Cuc nhanh cho read/write
- **Pricing**: Pay-per-request hoac provisioned capacity

### Key Schema (PK + SK)

> **Nguon**: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.CoreComponents.html

| Khai niem | Ten Terraform | Chuc nang |
|-----------|--------------|-----------|
| Partition Key (PK) | `hash_key` | Khoa chinh, BAT BUOC. DynamoDB hash gia tri de phan phoi data |
| Sort Key (SK) | `range_key` | Khoa phu, OPTIONAL. Ket hop PK tao composite key |

**Vi du voi CoffeeOrders:**
```
PK (orderId)    SK (createdAt)    userId      items
order-001       1706000000        user-123    [...]
order-001       1706100000        user-123    [...]  <- Cung orderId, khac createdAt
order-002       1706200000        user-456    [...]
```

- PK + SK = unique (khong co 2 item cung orderId VA cung createdAt)
- Query: `orderId = "order-001"` -> tra ve 2 items, sort theo createdAt

### Global Secondary Index (GSI)

> **Nguon**: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GSI.html

**Van de**: CoffeeOrders co PK = orderId. Nhung ta can tim orders theo userId!

```
// Khong co GSI:
GET orders WHERE userId = "user-123"  -> PHAI SCAN TOAN BO TABLE (cham, dat)

// Co GSI userId-index:
GET orders WHERE userId = "user-123"  -> Query index truc tiep (nhanh, re)
```

GSI = "bang phu" voi schema rieng. DynamoDB TU DONG dong bo data.

### Cac tables trong du an

| Table | PK | SK | GSI | Muc dich |
|-------|----|----|-----|----------|
| CoffeeProducts | productId (S) | - | - | Danh sach san pham |
| CoffeeOrders | orderId (S) | createdAt (N) | userId-index (PK: userId, SK: createdAt) | Don hang |
| CoffeeUsers | userId (S) | - | email-index (PK: email) | Tai khoan user |
| CoffeeReviews | reviewId (S) | productId (S) | productId-index (PK: productId) | Danh gia san pham |

### Attribute types

> **Nguon**: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.NamingRulesDataTypes.html

| Type code | Ten | Vi du |
|-----------|-----|-------|
| S | String | "user-123", "test@email.com" |
| N | Number | 1706000000, 59000 |
| B | Binary | Images, compressed data |

**QUAN TRONG**: Chi khai bao attributes dung lam KEY (PK, SK, GSI keys).
DynamoDB la **schemaless** - cac attributes khac (name, items, status) tu dong xuat hien khi PutItem.

### Billing Mode

> **Nguon**: https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.ReadWriteCapacityMode.html

| Mode | Gia | Khi nao dung |
|------|-----|-------------|
| PAY_PER_REQUEST (On-demand) | ~$1.25/trieu writes, ~$0.25/trieu reads | Dev, unpredictable traffic |
| PROVISIONED | Dat truoc capacity, re hon 5-7x | Stable traffic, production |

Dev luon dung `PAY_PER_REQUEST` vi:
- Khong traffic = khong mat tien
- Khong can doan truoc capacity
- Tu dong scale

### Code analysis - for_each + dynamic

```hcl
resource "aws_dynamodb_table" "tables" {
  for_each = var.tables              # Loop qua 4 tables

  name     = each.value.name         # VD: "CoffeeProducts"
  hash_key = each.value.hash_key     # VD: "productId"
  range_key = try(each.value.range_key, null)  # VD: "createdAt" hoac null

  # Dynamic attribute blocks
  dynamic "attribute" {
    for_each = each.value.attributes  # Loop qua list attributes
    content {
      name = attribute.value.name    # VD: "productId"
      type = attribute.value.type    # VD: "S"
    }
  }

  # Dynamic GSI blocks
  dynamic "global_secondary_index" {
    for_each = try(each.value.global_secondary_indexes, [])
    content {
      name      = global_secondary_index.value.name
      hash_key  = global_secondary_index.value.hash_key
      range_key = lookup(global_secondary_index.value, "range_key", null)
    }
  }
}
```

**Voi CoffeeProducts (don gian nhat):**
- for_each tao 1 table: `aws_dynamodb_table.tables["products"]`
- 1 attribute block: `{ name = "productId", type = "S" }`
- 0 GSI blocks (list rong)

**Voi CoffeeOrders (phuc tap nhat):**
- for_each tao 1 table: `aws_dynamodb_table.tables["orders"]`
- 3 attribute blocks: orderId(S), createdAt(N), userId(S)
- 1 GSI: userId-index (hash_key = userId, range_key = createdAt)

### Variable type: map(object(...))

> **Nguon**: https://developer.hashicorp.com/terraform/language/expressions/type-constraints

```hcl
variable "tables" {
  type = map(object({
    name      = string
    hash_key  = string
    range_key = optional(string)
    attributes = list(object({
      name = string
      type = string
    }))
    global_secondary_indexes = optional(list(object({
      name            = string
      hash_key        = string
      range_key       = optional(string)
      projection_type = optional(string, "ALL")
    })), [])
  }))
}
```

Day la **complex type constraint**:
- `map(...)` = map cua objects
- `object({...})` = object voi schema cu the
- `optional(string)` = co the co hoac khong
- `optional(list(...), [])` = default la list rong
- `list(object({...}))` = list cua objects

Giong TypeScript:
```typescript
type Tables = Record<string, {
  name: string;
  hash_key: string;
  range_key?: string;
  attributes: Array<{ name: string; type: string }>;
  global_secondary_indexes?: Array<{
    name: string;
    hash_key: string;
    range_key?: string;
    projection_type?: string;  // default "ALL"
  }>;
}>;
```

### Bai hoc rut ra

1. **for_each > count** cho nhieu resources tuong tu
2. **dynamic** cho nhieu nested blocks tuong tu
3. **Chi khai bao key attributes** - DynamoDB la schemaless
4. **PAY_PER_REQUEST** cho dev - khong traffic = khong tien
5. **Point-in-Time Recovery** cho production - phong mat data

---

## Module 7: S3 Images - Private Image Storage

> **File**: `terraform/modules/s3-images/main.tf`

### So sanh S3 Frontend vs S3 Images

| | S3 Frontend | S3 Images |
|---|-----------|-----------|
| **Access** | PUBLIC (website) | PRIVATE (chi Lambda) |
| **Block Public Access** | Tat het (false) | Bat het (true) |
| **Bucket Policy** | PublicReadGetObject | Khong can (dung IAM) |
| **CORS** | Khong can | Can (browser upload) |
| **Versioning** | Khong can | Nen bat (phong xoa nham) |
| **Lifecycle** | Khong can | Nen co (tiet kiem chi phi) |
| **Encryption** | Optional | Nen co (bao mat data) |
| **Website Hosting** | Co | Khong |

### Resources su dung

| Resource | Doc goc | Chuc nang |
|----------|---------|-----------|
| `aws_s3_bucket` | [Link](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | Tao bucket |
| `aws_s3_bucket_public_access_block` | [Link](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | Block public access (ALL true) |
| `aws_s3_bucket_versioning` | [Link](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | Bat versioning |
| `aws_s3_bucket_cors_configuration` | [Link](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration) | CORS cho browser upload |
| `aws_s3_bucket_lifecycle_configuration` | [Link](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | Tu dong chuyen storage class |
| `aws_s3_bucket_server_side_encryption_configuration` | [Link](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | Ma hoa data at rest |

### CORS cho Image Upload

> **Nguon**: https://docs.aws.amazon.com/AmazonS3/latest/userguide/cors.html

Khi frontend muon upload anh truc tiep len S3 (khong qua Lambda):
1. Frontend goi Lambda de lay **presigned URL**
2. Lambda tao presigned URL (co hieu luc 15 phut)
3. Frontend dung presigned URL de upload truc tiep len S3
4. S3 kiem tra CORS -> cho phep vi frontend domain nam trong `allowed_origins`

```hcl
cors_rule {
  allowed_headers = ["*"]
  allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
  allowed_origins = ["*"]     # Dev: tat ca. Prod: chi frontend domain
  max_age_seconds = 3600      # Cache CORS response 1 gio
}
```

### S3 Storage Classes & Lifecycle

> **Nguon**: https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-class-intro.html

```
Ngay 0-90: Standard ($0.025/GB/thang)
     |
     | lifecycle transition (tu dong)
     v
Ngay 90+:  Standard-IA ($0.0125/GB/thang) -> tiet kiem 50%!
```

**Standard-IA** (Infrequent Access): Re hon 50% nhung ton them $0.01/1000 requests.
Tot cho anh san pham cu (it ai xem lai sau 3 thang).

### Versioning - Phong mat data

> **Nguon**: https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html

```
PUT product-1.jpg (v1: anh goc)
PUT product-1.jpg (v2: anh moi) -> v1 van ton tai (noncurrent)
DELETE product-1.jpg            -> chi tao "delete marker", v1 + v2 van con
```

Versioning + lifecycle = best practice:
- Versioning giu tat ca versions
- Lifecycle tu dong xoa noncurrent versions sau 30 ngay
- Khong lo mat data, khong lo ton storage mai mai

### Server-Side Encryption

> **Nguon**: https://aws.amazon.com/blogs/aws/amazon-s3-encrypts-new-objects-by-default/

Tu thang 1/2023, AWS TU DONG ma hoa tat ca S3 objects bang SSE-S3 (AES-256).
Nhung ta van khai bao trong Terraform de:
1. **Lam ro y dinh** (explicit better than implicit)
2. **Terraform biet rang da duoc cau hinh** (khong bi drift)
3. **Bat `bucket_key_enabled`** = giam phi KMS 99% (neu dung KMS sau nay)

### count = 0/1 pattern (Conditional resource)

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "images" {
  count  = var.enable_lifecycle ? 1 : 0    # If-else!
  bucket = aws_s3_bucket.images.id
  # ...
}
```

`count = 0` = **khong tao resource nay**. Day la cach Terraform lam conditional:

| Pattern | Khi nao dung |
|---------|-------------|
| `count = condition ? 1 : 0` | Bat/tat 1 resource |
| `for_each = map` | Tao nhieu resources tuong tu |
| `for_each = condition ? { "key" = value } : {}` | Bat/tat + truy cap each.value |

Luu y khi dung count, resource address se la `resource[0]` (co index).

### Bai hoc rut ra

1. **Private bucket**: Block ALL public access, dung IAM cho Lambda
2. **CORS**: Can khi browser truy cap truc tiep S3 (upload anh)
3. **Versioning + Lifecycle**: Ket hop de bao ve data MA tiet kiem chi phi
4. **Encryption**: Luon bat, AES256 la free
5. **count = 0/1**: Pattern de bat/tat features tuy moi truong (dev vs prod)
6. **filter {}**: Tu AWS provider v5+, lifecycle rules BAT BUOC co filter block

---

## Root Module Updates

### Thay doi trong main.tf

**Truoc (Part 1):**
```
Module 1: IAM
Module 2: S3 Frontend
Module 3: Lambda Layer
Module 4: Lambda Functions        <- hardcode table names tu variables
Module 5: API Gateway
```

**Sau (Part 2):**
```
Module 1: IAM
Module 2: S3 Frontend
Module 3: S3 Images               <- MOI
Module 4: DynamoDB                 <- MOI
Module 5: Lambda Layer
Module 6: Lambda Functions         <- lay table names TU dynamodb module
Module 7: API Gateway
```

### Ket noi DynamoDB -> Lambda

```hcl
# TRUOC (Part 1): hardcode tu variables
products_table_name = var.products_table_name  # "CoffeeProducts"

# SAU (Part 2): lay tu module output
products_table_name = module.dynamodb.products_table_name
```

**Tai sao thay doi?**
- Part 1: DynamoDB chua co, dung variable de "hua truoc" ten table
- Part 2: DynamoDB da co, lay ten THUC TE tu module output
- Dam bao DONG BO: Lambda dung dung ten table ma Terraform tao
- Neu doi ten table -> chi doi 1 cho (DynamoDB module) -> tu dong cap nhat Lambda

### Dependency chain moi

Terraform doc references va biet:
```
IAM ─────────────────────────> Lambda
S3 Frontend (doc lap)          Lambda
S3 Images (doc lap)            Lambda
DynamoDB ──── table names ──> Lambda ──── ARNs ──> API Gateway
Lambda Layer ── layer_arn ──> Lambda
```

---

## Huong dan thuc hanh Part 2

### Neu chua deploy Part 1

Lam theo huong dan Part 1 truoc (terraform init, plan, apply).
Part 2 chi THEM modules, khong thay doi gi cua Part 1.

### Neu da deploy Part 1

```powershell
cd terraform

# 1. Re-init de nap modules moi
terraform init -upgrade

# 2. Xem preview
terraform plan
```

Output se hien:
```
Plan: 10 to add, 1 to change, 0 to destroy.
```

- **10 to add**: 4 DynamoDB tables + 6 S3 Images resources
- **1 to change**: Lambda module cap nhat table names tu variables -> module output
- **0 to destroy**: Khong xoa gi cua Part 1!

```powershell
# 3. Apply
terraform apply
```

### Kiem tra DynamoDB tables

```powershell
# List cac tables
aws dynamodb list-tables --region ap-southeast-1

# Xem chi tiet 1 table
aws dynamodb describe-table --table-name CoffeeProducts --region ap-southeast-1
```

### Kiem tra S3 Images bucket

```powershell
# List buckets
aws s3 ls

# Kiem CORS
aws s3api get-bucket-cors --bucket coffee-shop-images-yourname

# Kiem encryption
aws s3api get-bucket-encryption --bucket coffee-shop-images-yourname
```

### Them sample data vao DynamoDB

```powershell
# Them 1 san pham vao CoffeeProducts
aws dynamodb put-item `
  --table-name CoffeeProducts `
  --item '{
    "productId": {"S": "prod-001"},
    "name": {"S": "Espresso"},
    "price": {"N": "45000"},
    "description": {"S": "Classic espresso shot"},
    "category": {"S": "coffee"},
    "imageUrl": {"S": ""},
    "available": {"BOOL": true}
  }' `
  --region ap-southeast-1

# Test API
curl https://YOUR-API-URL/prod/products
```

---

## Tong ket Part 2

### Resources da them

| Module | Resources | So luong |
|--------|-----------|---------|
| DynamoDB | 4 Tables (CoffeeProducts, CoffeeOrders, CoffeeUsers, CoffeeReviews) | 4 |
| S3 Images | Bucket, Public Access Block, Versioning, CORS, Encryption, Lifecycle (conditional) | 5-6 |
| **Tong Part 2** | | **~10** |
| **Tong tich luy (Part 1+2)** | | **~65** |

### Terraform concepts da hoc (Part 2)

| Concept | Doc goc | Muc dich |
|---------|---------|----------|
| `for_each` | [Link](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each) | Tao nhieu resources tu 1 block |
| `dynamic` | [Link](https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks) | Tao nhieu nested blocks |
| `count` | [Link](https://developer.hashicorp.com/terraform/language/meta-arguments/count) | Bat/tat resource (conditional) |
| `try()` | [Link](https://developer.hashicorp.com/terraform/language/functions/try) | Truy cap attribute an toan |
| `lookup()` | [Link](https://developer.hashicorp.com/terraform/language/functions/lookup) | Tim gia tri trong map voi default |
| `optional()` | [Link](https://developer.hashicorp.com/terraform/language/expressions/type-constraints#optional-object-type-attributes) | Optional object attributes |
| `for` expression | [Link](https://developer.hashicorp.com/terraform/language/expressions/for) | Transform collections |
| `map(object(...))` | [Link](https://developer.hashicorp.com/terraform/language/expressions/type-constraints) | Complex variable types |

### Tong ket toan bo concepts (Part 1 + Part 2)

| Part | Concepts |
|------|----------|
| Part 1 | Providers, Resources, Data Sources, Variables (basic), Outputs, Modules, Dependencies (implicit + explicit), Locals, jsonencode(), lifecycle |
| Part 2 | for_each, dynamic, count, try(), lookup(), optional(), for expressions, map(object()), validation, conditional resources |

### Next: Part 3

Part 3 se cover:
- **Code Integration**: Ket noi frontend voi backend, cap nhat .env tu terraform output
- **Environment Management**: Dev/staging/prod voi terraform workspaces hoac tfvars
- **GitHub Actions CI/CD**: Tu dong build + deploy frontend len S3, tu dong terraform apply

---

> **Document**: TERRAFORM_LAB.md - Part 2  
> **References**: Tat ca links trong document deu tro den documentation GOC cua  
> HashiCorp Terraform Registry hoac AWS Documentation

---
---

# TERRAFORM LAB - Part 3: CI/CD + Code Integration

> **Tiep noi Part 2** - da co DynamoDB, S3 Images  
> **Part 3 them**: Environment management, sync-env scripts, GitHub Actions CI/CD  
> **Concepts moi**: `tfvars` per-environment, GitHub Actions, cache strategies, artifacts

---

## Muc luc Part 3

- [Gioi thieu Part 3](#gioi-thieu-part-3)
- [Environment Management - tfvars files](#environment-management---tfvars-files)
- [Sync-env Script - Terraform -> Frontend](#sync-env-script---terraform---frontend)
- [GitHub Actions CI/CD](#github-actions-cicd)
- [Tong ket Part 3](#tong-ket-part-3)

---

## Gioi thieu Part 3

### Van de: Gap giua Terraform va Frontend

Sau Part 1+2, ta co Terraform tao toan bo infra (API Gateway, Lambda, DynamoDB, S3).
Nhung frontend van dung HARDCODED API URL trong `.env`:

```
VITE_API_BASE_URL=https://yxg0kbjrz6.execute-api.ap-southeast-1.amazonaws.com/prod
```

**Van de**:
- Moi lan `terraform destroy` + `terraform apply` -> API Gateway URL doi!
- Developer phai COPY-PASTE URL tu terminal vao .env bang tay
- Khong co cach phan biet dev/prod environment
- Deploy frontend = cac buoc thu cong (build, aws s3 sync)

### Part 3 giai quyet

```
[Terraform] --outputs--> [sync-env.ps1] --writes--> [.env] --reads--> [Frontend Build]
                                                                             |
[GitHub Push] --triggers--> [GitHub Actions] --deploys--> [S3 Frontend]
                                            --applies--> [Terraform Infra]
```

1. **Environment tfvars**: Dev vs Prod configuration tach biet
2. **Sync-env script**: Tu dong doc terraform outputs -> ghi .env
3. **GitHub Actions**: Tu dong deploy khi push code

---

## Environment Management - tfvars files

> **Doc**: https://developer.hashicorp.com/terraform/language/values/variables#variable-definitions-tfvars-files

### Tai sao can nhieu environments?

| | Dev | Production |
|---|-----|-----------|
| **Muc dich** | Develop + test | Users that su dung |
| **Data** | Fake data, co the xoa bat cu luc nao | Real data, KHONG DUOC mat |
| **Resources** | Tiet kiem toi da | Toi uu hieu nang + bao mat |
| **force_destroy** | true (xoa bucket nhanh) | false (bao ve data) |
| **Versioning** | Off (khong can) | On (phong mat anh) |
| **Lifecycle** | Off | On (tiet kiem chi phi) |
| **PITR** | Off (tiet kiem) | On (phuc hoi data trong 35 ngay) |
| **Logs** | 7 ngay | 30 ngay |
| **CORS** | `["*"]` | `["https://yourdomain.com"]` |

### Cau truc thu muc

```
terraform/
  environments/
    dev.tfvars      <- Dev configuration
    prod.tfvars     <- Production configuration
  terraform.tfvars.example  <- Template huong dan
```

### Cach su dung

```powershell
# Dev environment
terraform plan  -var-file="environments/dev.tfvars" -var="jwt_secret=dev-secret"
terraform apply -var-file="environments/dev.tfvars" -var="jwt_secret=dev-secret"

# Production environment
terraform plan  -var-file="environments/prod.tfvars" -var="jwt_secret=$env:JWT_SECRET"
terraform apply -var-file="environments/prod.tfvars" -var="jwt_secret=$env:JWT_SECRET"
```

### So sanh: tfvars vs workspaces

| | -var-file (tfvars) | Terraform Workspaces |
|---|---|---|
| **State** | 1 state file (hoac tu chia) | Moi workspace co state rieng |
| **Do phuc tap** | Don gian | Phuc tap hon |
| **Resource isolation** | Cung account, ten khac | Cung account, ten khac |
| **Khi nao dung** | Moi truong don gian | Nhieu moi truong phuc tap |

Ta chon **tfvars** vi don gian, phu hop du an hoc tap.

### Bai hoc rut ra

1. **KHONG BAO GIO** dat secrets (jwt_secret) trong tfvars files
2. Dung environment variables hoac `-var` flag cho secrets
3. tfvars files NEn commit vao git (khong chua secrets) -> team dung chung
4. terraform.tfvars (khong co extension) tu dong load -> KHONG commit (chua secrets)

---

## Sync-env Script - Terraform -> Frontend

### Van de

Frontend can `VITE_API_BASE_URL` de goi API. Gia tri nay la output cua Terraform:

```
terraform output -raw api_url
# -> https://abc123.execute-api.ap-southeast-1.amazonaws.com/prod
```

Developer phai copy-paste bang tay -> de quen, de sai.

### Giai phap: sync-env script

```
terraform/scripts/
  sync-env.ps1    <- Windows (PowerShell)
  sync-env.sh     <- Linux/Mac (Bash)
```

### Cach su dung

```powershell
cd terraform

# Sau khi terraform apply thanh cong:
.\scripts\sync-env.ps1

# Output:
# ======================================
#   Coffee Shop - Sync Terraform -> .env
# ======================================
#
# [1/3] Doc terraform outputs...
# [2/3] Tao file .env...
#   -> Ghi thanh cong: ../.env
# [3/3] Thong tin deploy:
#   API URL:          https://abc123.execute-api.../prod
#   Website URL:      http://coffee-shop-frontend....
#   Frontend Bucket:  coffee-shop-frontend-yourname
```

### Workflow day du

```powershell
# 1. Deploy infra
cd terraform
terraform apply -var-file="environments/dev.tfvars" -var="jwt_secret=my-secret"

# 2. Sync env tu terraform -> frontend .env
.\scripts\sync-env.ps1

# 3. Build frontend
cd ..
npm run build

# 4. Deploy frontend len S3
aws s3 sync dist/ s3://$(cd terraform; terraform output -raw frontend_bucket_name)

# 5. Mo website
start (cd terraform; terraform output -raw website_url)
```

### Root .env.example

File `.env.example` o root project huong dan developer:

```dotenv
# API Gateway URL
# Lay tu: cd terraform && terraform output -raw api_url
VITE_API_BASE_URL=https://YOUR-API-ID.execute-api.ap-southeast-1.amazonaws.com/prod
```

Developer moi chi can:
```powershell
cp .env.example .env
# Sua URL
```

Hoac tu dong hoa voi sync-env script.

---

## GitHub Actions CI/CD

> **Doc**: https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions

### Truoc khi co CI/CD

```
Developer -> Sua code -> git push
          -> SSH vao EC2 -> git pull -> docker-compose up  (CU - EC2)
          -> npm run build -> aws s3 sync -> terraform apply (MOI - nhieu buoc thu cong)
```

### Sau khi co CI/CD

```
Developer -> Sua code -> git push -> GitHub Actions TU DONG:
  terraform/ thay doi -> deploy-infrastructure.yml -> terraform plan + apply
  src/ thay doi       -> deploy-frontend.yml       -> npm build + s3 sync
```

### Workflow 1: deploy-infrastructure.yml

```yaml
name: Deploy Infrastructure
on:
  push:
    branches: [main]
    paths: ['terraform/**']     # Chi chay khi terraform/ thay doi
  pull_request:
    branches: [main]
    paths: ['terraform/**']
```

**Flow**:

```
Push to main                    Pull Request
     |                               |
     v                               v
[Terraform Plan]               [Terraform Plan]
     |                               |
     v                          (dung lai - review)
[Terraform Apply]
```

**Diem quan trong**:
- `paths`: Chi chay khi terraform/ thay doi (khong chay khi sua frontend)
- `concurrency`: Chi 1 terraform chay cung luc (tranh conflict state)
- `artifacts`: Plan duoc upload tu plan job -> download o apply job
- Secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `JWT_SECRET`

### Workflow 2: deploy-frontend.yml

```yaml
name: Deploy Frontend
on:
  push:
    branches: [main]
    paths: ['src/**', 'package.json', 'index.html']
```

**Flow**:

```
Push to main -> [Install] -> [Test] -> [Build] -> [S3 Sync] -> Done!
```

**Diem quan trong**:
- `vars.VITE_API_BASE_URL`: API URL set trong GitHub Variables (khong phai Secrets)
- `vars.FRONTEND_BUCKET_NAME`: Bucket name
- S3 sync voi cache strategy:
  - Static assets (JS, CSS, images): cache 1 nam (Vite add hash vao filename)
  - `index.html`: khong cache (de cap nhat nhanh)
- `concurrency` voi `cancel-in-progress: true`: Huy build cu neu co push moi

### Cau hinh GitHub Secrets & Variables

> **Doc**: https://docs.github.com/en/actions/security-for-github-actions/security-guides/using-secrets-in-github-actions

**Secrets** (gia tri BI AN, khong hien thi trong logs):

| Secret | Mo ta | Vi du |
|--------|-------|-------|
| `AWS_ACCESS_KEY_ID` | IAM Access Key | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | IAM Secret Key | `wJal...` |
| `JWT_SECRET` | JWT signing secret | `random-64-char-string` |

**Variables** (gia tri CONG KHAI, hien thi trong logs):

| Variable | Mo ta | Vi du |
|----------|-------|-------|
| `FRONTEND_BUCKET_NAME` | S3 bucket name | `coffee-shop-frontend-yourname` |
| `VITE_API_BASE_URL` | API Gateway URL | `https://abc.execute-api.../prod` |

**Cach cau hinh**: GitHub repo -> Settings -> Secrets and variables -> Actions

### Legacy workflows da xoa

| File cu | Chuc nang cu | Ly do xoa |
|---------|-------------|-----------|
| `production_deploy.yml` | SSH vao EC2, docker-compose | Khong con dung EC2 |
| `staging_deploy.yml` | SSH vao EC2, npm test | Da chuyen sang serverless |

---

## Tong ket Part 3

### Files da tao/sua

| File | Hanh dong | Muc dich |
|------|-----------|----------|
| `terraform/environments/dev.tfvars` | Tao moi | Dev environment config |
| `terraform/environments/prod.tfvars` | Tao moi | Production environment config |
| `terraform/scripts/sync-env.ps1` | Tao moi | Sync TF outputs -> .env (Windows) |
| `terraform/scripts/sync-env.sh` | Tao moi | Sync TF outputs -> .env (Linux/Mac) |
| `.github/workflows/deploy-infrastructure.yml` | Tao moi | CI/CD cho Terraform |
| `.github/workflows/deploy-frontend.yml` | Tao moi | CI/CD cho frontend |
| `.env.example` | Tao moi | Template cho .env |

### Concepts da hoc (Part 3)

| Concept | Muc dich |
|---------|----------|
| `-var-file` | Load variables tu file cu the |
| `terraform output -raw` | Doc 1 output value (dung trong scripts) |
| GitHub Actions `paths` | Chi trigger workflow khi dung files thay doi |
| GitHub Actions `concurrency` | Tranh chay 2 workflows cung luc |
| GitHub Actions `artifacts` | Truyen data giua jobs |
| GitHub Secrets vs Variables | An secrets, cong khai variables |
| S3 cache strategy | Cache static assets, khong cache index.html |

---
---

# TERRAFORM LAB - Part 4: Code Review & Cleanup

> **Part cuoi** - Review toan bo project, don dep code legacy  
> **Muc tieu**: Project sach, co cau truc, san sang de deploy that

---

## Muc luc Part 4

- [Legacy Cleanup](#legacy-cleanup)
- [Code Duplication Cleanup](#code-duplication-cleanup)
- [Gitignore Audit](#gitignore-audit)
- [Terraform Audit Summary](#terraform-audit-summary)
- [Final Project Structure](#final-project-structure)
- [Tong ket toan du an](#tong-ket-toan-du-an)

---

## Legacy Cleanup

### Files da xoa

Du an ban dau deploy tren EC2 voi Docker. Da chuyen sang serverless (Lambda + S3).
Cac files legacy khong con can thiet:

| File | Ly do xoa |
|------|-----------|
| `docker-compose.yml` | Khong con dung Docker (serverless) |
| `Dockerfile` | Khong con dung Docker |
| `src/index.mjs` | Lambda handler CU nam trong frontend src (da co ban moi trong terraform/lambda-src/) |
| `src/Component/` (capital C) | Thu muc component CU, da thay bang `src/components/` (lowercase) |
| `.github/workflows/production_deploy.yml` | CI/CD cu deploy len EC2 |
| `.github/workflows/staging_deploy.yml` | CI/CD cu deploy len EC2 |

### Tai sao xoa?

**Principle: Remove dead code**

Code khong dung lam:
1. **Nhieu nguoi** (confuse developer moi: "dung file nao?")
2. **Tang do phuc tap** khi search/grep
3. **Sai lang** khi ai do sua nham file cu
4. **Tao cam giac** project lon hon thuc te

---

## Code Duplication Cleanup

### Van de: DEFAULT_PRODUCTS

DEFAULT_PRODUCTS (fallback data khi API chua san sang) bi **copy-paste** tai 3 noi:

1. `src/pages/HomePage.jsx` - ~45 dong
2. `src/pages/ProductsPage.jsx` - ~45 dong
3. `src/pages/CartPage.jsx` - ~30 dong

Tong: ~120 dong trung lap.

### Giai phap: Extract to shared module

```
src/data/defaultProducts.js     <- 1 file duy nhat
```

```javascript
// src/data/defaultProducts.js
import anh1 from '../assets/anh1.webp';
// ...
export const DEFAULT_PRODUCTS = [ ... ];
```

```javascript
// src/pages/HomePage.jsx (TRUOC)
import anh1 from '../assets/anh1.webp';
const DEFAULT_PRODUCTS = [ ... ];  // 45 dong copy-paste

// src/pages/HomePage.jsx (SAU)
import { DEFAULT_PRODUCTS } from '../data/defaultProducts';  // 1 dong
```

**DRY principle** (Don't Repeat Yourself):
- Sua 1 noi -> ap dung cho 3 pages
- Them san pham moi -> chi sua 1 file
- Giam 120 dong trung lap xuong 1 import line moi page

---

## Gitignore Audit

### Root .gitignore - Da cap nhat

```gitignore
# Dependencies
node_modules/

# Build output
dist/

# Environment variables (CHUA SECRETS!)
.env
.env.local
.env.*.local

# Internal docs
docs-internal/

# Editor/IDE
.vscode/*
!.vscode/extensions.json
!.vscode/settings.json
.idea/

# Terraform (backup - chi tiet trong terraform/.gitignore)
terraform/*.tfstate
terraform/*.tfstate.*
terraform/.terraform/
terraform/*.zip
```

### terraform/.gitignore - Da co tu Part 1

```gitignore
**/.terraform/*
*.tfstate
*.tfstate.*
*.tfvars          # Quan trong: khong commit .tfvars (co the chua secrets)
*.tfvars.json
*.zip
.env
```

### Luu y quan trong

| File | Commit? | Ly do |
|------|---------|-------|
| `terraform.tfvars.example` | **Co** | Template huong dan |
| `terraform.tfvars` | **KHONG** | Chua secrets (jwt_secret) |
| `environments/dev.tfvars` | **Co** | Khong chua secrets |
| `environments/prod.tfvars` | **Co** | Khong chua secrets |
| `.env.example` | **Co** | Template huong dan |
| `.env` | **KHONG** | Chua API URL (co the chua secrets) |

---

## Terraform Audit Summary

### Format check

```powershell
terraform fmt -recursive -diff
# -> Khong co thay doi (da format dung tu dau)
```

### Validation

```powershell
terraform validate
# -> Success! The configuration is valid.
```

### Module dependency chain

```
IAM ─────────────────────────> Lambda
S3 Frontend (doc lap)           |
S3 Images (doc lap)             |
DynamoDB ──── table names ──> Lambda ──── ARNs ──> API Gateway
Lambda Layer ── layer_arn ──> Lambda
```

### Checklist toan du an

| Han muc | Status | Ghi chu |
|---------|--------|---------|
| terraform fmt | PASS | Khong co loi format |
| terraform validate | PASS | Configuration valid |
| Secrets khong commit | PASS | jwt_secret dung sensitive = true |
| Tags nhat quan | PASS | Tat ca modules nhan common_tags |
| force_destroy configurable | PASS | true cho dev, false cho prod |
| IAM least privilege | PASS | Chi DynamoDB Coffee*, S3 images bucket |
| S3 images private | PASS | block_public_access all true |
| S3 frontend public | PASS | bucket policy public read |
| DynamoDB PAY_PER_REQUEST | PASS | Dev friendly, no idle cost |
| CORS configurable | PASS | ["*"] cho dev, specific domain cho prod |
| CloudWatch logs configurable | PASS | retention_in_days 7 (dev) / 30 (prod) |
| Lambda env vars | PASS | Dung module outputs, khong hardcode |

---

## Final Project Structure

```
coffee-shop-project/
│
├── .env                          # Generated by sync-env (KHONG commit)
├── .env.example                  # Template huong dan
├── .gitignore                    # Updated, comprehensive
├── package.json                  # React + Vite frontend
├── vite.config.js                # Vite config
├── index.html                    # SPA entry point
│
├── .github/workflows/
│   ├── deploy-frontend.yml       # CI/CD: Build + S3 sync
│   └── deploy-infrastructure.yml # CI/CD: Terraform plan + apply
│
├── src/                          # React Frontend
│   ├── config/api.config.js      # API endpoints
│   ├── context/                  # React Context (Auth, Cart)
│   ├── hooks/                    # Custom hooks (useProducts, useOrders, useReviews)
│   ├── services/                 # API service classes
│   ├── models/                   # Data models (Order, Product, Review, User)
│   ├── utils/                    # Utilities (formatters, validation, constants)
│   ├── data/defaultProducts.js   # Shared fallback data (extracted from pages)
│   ├── pages/                    # Page components
│   ├── components/               # Reusable components (auth/, common/, product/)
│   └── assets/                   # Images, fonts
│
├── docs/
│   ├── AWS_SETUP.md              # AWS resource specifications
│   └── TERRAFORM_LAB.md          # This document (Parts 1-4)
│
└── terraform/                    # Infrastructure as Code
    ├── providers.tf              # AWS + Archive providers
    ├── main.tf                   # Root orchestrator (7 modules)
    ├── variables.tf              # Root variables
    ├── outputs.tf                # Root outputs
    ├── terraform.tfvars.example  # Variable template
    │
    ├── environments/
    │   ├── dev.tfvars            # Dev config (tiet kiem, convenience)
    │   └── prod.tfvars           # Prod config (bao mat, bao ve data)
    │
    ├── scripts/
    │   ├── sync-env.ps1          # Terraform outputs -> .env (Windows)
    │   └── sync-env.sh           # Terraform outputs -> .env (Linux/Mac)
    │
    ├── modules/
    │   ├── iam/                  # IAM Role + Policy cho Lambda
    │   ├── s3-frontend/          # S3 static website hosting (public)
    │   ├── s3-images/            # S3 private image storage
    │   ├── dynamodb/             # 4 DynamoDB tables voi GSIs
    │   ├── lambda-layer/         # Shared npm packages
    │   ├── lambda/               # 5 Lambda functions
    │   └── api-gateway/          # REST API voi CORS
    │
    └── lambda-src/               # Lambda source code
        ├── get-products/index.mjs
        ├── create-order/index.mjs
        ├── get-orders/index.mjs
        ├── register-user/index.mjs
        ├── login-user/index.mjs
        └── layer/nodejs/package.json
```

---

## Tong ket toan du an

### Terraform resources summary

| Module | Resources | Terraform Concepts |
|--------|-----------|-------------------|
| IAM | Role, Policy, Attachment | jsonencode(), variable |
| S3 Frontend | Bucket, Website Config, Public Access Block, Bucket Policy | depends_on, lifecycle |
| S3 Images | Bucket, Public Access Block, Versioning, CORS, Lifecycle, Encryption | count (conditional), merge() |
| DynamoDB | 4 Tables voi GSIs | for_each, dynamic, try(), lookup(), optional() |
| Lambda Layer | Layer Version | data source (archive_file) |
| Lambda | 5 Functions, 5 Log Groups | sensitive, depends_on |
| API Gateway | REST API, 5 Resources, 10 Methods, 5 Integrations, CORS, Deploy, Stage | sha1(), MOCK integration |
| **Tong** | **~65 resources** | |

### Tat ca Terraform concepts da hoc

| Part | Concepts |
|------|----------|
| Part 1 | Providers, Resources, Data Sources, Variables, Outputs, Modules, Dependencies (implicit + explicit), Locals, jsonencode(), lifecycle, create_before_destroy |
| Part 2 | for_each, dynamic, count, try(), lookup(), optional(), for expressions, map(object()), validation, conditional resources |
| Part 3 | -var-file, terraform output -raw, environment separation, scripts automation |
| Part 4 | terraform fmt, terraform validate, code review checklist, DRY principle |

### Hanh trinh hoc tap

```
Manual (Console)     -> Hieu resource la gi, cach chung lien ket
     |
Documentation        -> Ghi lai cac buoc, hieu flow
     |
Terraform Part 1     -> IaC co ban: providers, resources, modules
     |
Terraform Part 2     -> IaC nang cao: for_each, dynamic, conditional
     |
Terraform Part 3     -> DevOps: CI/CD, environment management
     |
Terraform Part 4     -> Best practices: code review, cleanup, DRY
     |
Production-ready! 🎉
```

### References

| Resource | URL |
|----------|-----|
| Terraform Language | https://developer.hashicorp.com/terraform/language |
| AWS Provider | https://registry.terraform.io/providers/hashicorp/aws/latest/docs |
| GitHub Actions | https://docs.github.com/en/actions |
| DynamoDB Guide | https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/ |
| S3 Developer Guide | https://docs.aws.amazon.com/AmazonS3/latest/userguide/ |
| Lambda Guide | https://docs.aws.amazon.com/lambda/latest/dg/ |
| API Gateway Guide | https://docs.aws.amazon.com/apigateway/latest/developerguide/ |

---

> **Document**: TERRAFORM_LAB.md - Parts 1-4 (Complete)  
> **Author**: Generated for Coffee Shop IaC learning project  
> **Status**: Du an HOAN THANH - san sang deploy  
> **References**: Tat ca links tro den documentation GOC cua  
> HashiCorp Terraform Registry, AWS Documentation, GitHub Documentation
