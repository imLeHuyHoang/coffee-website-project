# Coffee Shop - Huong Dan Cau Hinh & Su Dung

> **Muc dich**: Huong dan nguoi dung cach cau hinh va deploy du an Coffee Shop  
> **Doi tuong**: Developer moi clone repo ve  
> **Nguyen tac**: Chi sua file cau hinh (.env, .tfvars), KHONG sua code

---

## Muc luc

- [Yeu cau](#yeu-cau)
- [Cau truc du an](#cau-truc-du-an)
- [Buoc 1: Cau hinh Terraform](#buoc-1-cau-hinh-terraform)
- [Buoc 2: Deploy Infrastructure](#buoc-2-deploy-infrastructure)
- [Buoc 3: Cau hinh Frontend](#buoc-3-cau-hinh-frontend)
- [Buoc 4: Build va Deploy Frontend](#buoc-4-build-va-deploy-frontend)
- [Buoc 5: Truy cap va Su dung](#buoc-5-truy-cap-va-su-dung)
- [Cac lenh thuong dung](#cac-lenh-thuong-dung)
- [Xoa toan bo tai nguyen](#xoa-toan-bo-tai-nguyen)
- [Xu ly loi thuong gap](#xu-ly-loi-thuong-gap)

---

## Yeu cau

### Cong cu can cai dat

| Cong cu | Version | Kiem tra | Tai ve |
|---------|---------|---------|--------|
| Node.js | >= 18.x | `node --version` | https://nodejs.org |
| npm | >= 9.x | `npm --version` | (di kem Node.js) |
| Terraform | >= 1.6.0 | `terraform --version` | https://developer.hashicorp.com/terraform/install |
| AWS CLI | >= 2.x | `aws --version` | https://aws.amazon.com/cli/ |

### Tai khoan AWS

- Tai khoan AWS voi quyyen IAM (tao role, policy, S3, DynamoDB, Lambda, API Gateway)
- AWS Access Key ID va Secret Access Key
- Cau hinh AWS CLI:

```powershell
aws configure
# AWS Access Key ID:     YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region name:   ap-southeast-1
# Default output format: json
```

---

## Cau truc du an

```
coffee-shop/
├── .env                          # Frontend config (TU DONG tao boi sync-env)
├── .env.example                  # Template huong dan
├── src/                          # React frontend source code
├── terraform/
│   ├── environments/
│   │   ├── dev.tfvars            # << SUA FILE NAY cho dev
│   │   └── prod.tfvars           # << SUA FILE NAY cho production
│   ├── terraform.tfvars.example  # Template tham khao
│   ├── scripts/
│   │   ├── sync-env.ps1          # Tu dong tao .env (Windows)
│   │   └── sync-env.sh           # Tu dong tao .env (Linux/Mac)
│   └── ...                       # Modules, lambda-src (KHONG can sua)
└── docs/                         # Tai lieu
```

**Nguoi dung chi can sua**:
1. `terraform/environments/dev.tfvars` (hoac `prod.tfvars`)
2. Chay lenh deploy

**KHONG can sua** bat ky file code nao.

---

## Buoc 1: Cau hinh Terraform

### Mo file `terraform/environments/dev.tfvars`

File nay chia thanh 2 nhom chinh:

### Nhom 1: NAMING - Dat ten tai nguyen AWS

```hcl
# --- NAMING: Dat ten tai nguyen AWS ---
project_name         = "Coffee"                              # (1)
frontend_bucket_name = "coffee-shop-frontend-dev-hoangcon"   # (2)
images_bucket_name   = "coffee-shop-images-dev-hoangcon"     # (3)
```

| # | Bien | Y nghia | Quy tac |
|---|------|---------|---------|
| (1) | `project_name` | Prefix cho TAT CA tai nguyen | Chi chu cai + so, bat dau bang chu, toi da 20 ky tu |
| (2) | `frontend_bucket_name` | Ten S3 bucket website | GLOBALLY UNIQUE, 3-63 ky tu, chi lowercase + so + dau gach |
| (3) | `images_bucket_name` | Ten S3 bucket anh | GLOBALLY UNIQUE, tuong tu bucket name |

**project_name** tu dong sinh ra ten cho tat ca tai nguyen khac:

| Tai nguyen | Template | Vi du (project_name = "Coffee") | Vi du (project_name = "MyShop") |
|------------|----------|----------------------------------|----------------------------------|
| IAM Role | `{name}LambdaRole` | CoffeeLambdaRole | MyShopLambdaRole |
| IAM Policy | `{name}LambdaPolicy` | CoffeeLambdaPolicy | MyShopLambdaPolicy |
| Lambda functions | `{name}-get-products` | coffee-get-products | myshop-get-products |
| Lambda Layer | `{name}NodeModules` | CoffeeNodeModules | MyShopNodeModules |
| API Gateway | `{name}ShopAPI` | CoffeeShopAPI | MyShopShopAPI |
| DynamoDB tables | `{name}Products` | CoffeeProducts | MyShopProducts |

> **Luu y**: Neu doi `project_name` SAU KHI da deploy, Terraform se XOA tai nguyen cu va tao moi.
> DynamoDB data se bi MAT. Chi doi truoc khi deploy lan dau.

### Nhom 2: CONFIGURATION - Cau hinh tai nguyen

```hcl
# --- AWS CONFIG ---
aws_region = "ap-southeast-1"    # Region deploy (Singapore)
stage_name = "dev"               # API stage: dev, prod, staging

# --- RESOURCE BEHAVIOR ---
force_destroy      = true        # true = xoa bucket nhanh, false = bao ve data
log_retention_days = 7           # So ngay giu CloudWatch logs
lambda_timeout     = 30          # Lambda timeout (giay)
lambda_memory_size = 128         # Lambda memory (MB)

# --- DYNAMODB ---
dynamodb_billing_mode         = "PAY_PER_REQUEST"  # On-demand pricing
enable_point_in_time_recovery = false               # Backup protection

# --- S3 IMAGES ---
enable_versioning    = false     # Giu lich su phien ban anh
enable_lifecycle     = false     # Tu dong don dep anh cu
cors_allowed_origins = ["*"]     # Domain duoc phep upload anh
```

### So sanh Dev vs Production

| Bien | Dev | Production | Ly do |
|------|-----|-----------|-------|
| `stage_name` | `"dev"` | `"prod"` | Phan biet environment |
| `force_destroy` | `true` | `false` | Bao ve data production |
| `log_retention_days` | `7` | `30` | Debug lau hon cho prod |
| `enable_point_in_time_recovery` | `false` | `true` | Backup data production |
| `enable_versioning` | `false` | `true` | Bao ve anh san pham |
| `enable_lifecycle` | `false` | `true` | Tiet kiem chi phi storage |
| `cors_allowed_origins` | `["*"]` | `["https://domain.com"]` | Gioi han truy cap |

### JWT Secret

**KHONG** dat jwt_secret trong file tfvars! Dung 1 trong 2 cach:

```powershell
# Cach 1: Truyen truc tiep qua command line
terraform apply -var-file="environments/dev.tfvars" -var="jwt_secret=my-super-secret-key-2024"

# Cach 2: Dat bien moi truong (khong hien thi trong history)
$env:TF_VAR_jwt_secret = "my-super-secret-key-2024"
terraform apply -var-file="environments/dev.tfvars"
```

> JWT secret phai it nhat **16 ky tu**. Dung chuoi ngau nhien, vi du:
> `openssl rand -base64 32` hoac bat ky password generator nao.

---

## Buoc 2: Deploy Infrastructure

### Lan dau tien

```powershell
# 1. Vao thu muc terraform
cd terraform

# 2. Cai dat npm packages cho Lambda Layer
cd lambda-src/layer/nodejs
npm install
cd ../../..

# 3. Khoi tao Terraform (tai providers)
terraform init

# 4. Xem truoc thay doi
terraform plan -var-file="environments/dev.tfvars" -var="jwt_secret=my-super-secret-key-2024"

# 5. Tao tai nguyen tren AWS
terraform apply -var-file="environments/dev.tfvars" -var="jwt_secret=my-super-secret-key-2024"
# Nhap "yes" khi duoc hoi

# 6. Tu dong tao file .env cho frontend
.\scripts\sync-env.ps1
```

### Cac lan sau

Neu chi sua terraform config (VD: doi log_retention_days):

```powershell
cd terraform
terraform apply -var-file="environments/dev.tfvars" -var="jwt_secret=my-super-secret-key-2024"
```

---

## Buoc 3: Cau hinh Frontend

### Tu dong (khuyen nghi)

```powershell
cd terraform
.\scripts\sync-env.ps1
```

Script se tu dong:
1. Doc terraform outputs (API URL, bucket names)
2. Tao file `.env` o root du an
3. Hien thi thong tin deploy

### Thu cong

Copy `.env.example` thanh `.env` va sua:

```dotenv
VITE_API_BASE_URL=https://YOUR-API-ID.execute-api.ap-southeast-1.amazonaws.com/dev
```

Lay API URL tu:
```powershell
cd terraform
terraform output -raw api_url
```

---

## Buoc 4: Build va Deploy Frontend

```powershell
# 1. Quay ve root du an
cd ..   # (neu dang o terraform/)

# 2. Cai dat dependencies (lan dau)
npm install

# 3. Build
npm run build

# 4. Deploy len S3
aws s3 sync dist/ s3://coffee-shop-frontend-dev-hoangcon --delete
```

> **Luu y**: Thay `coffee-shop-frontend-dev-hoangcon` bang gia tri `frontend_bucket_name` cua ban.
> Hoac dung: `aws s3 sync dist/ s3://$(cd terraform; terraform output -raw frontend_bucket_name) --delete`

---

## Buoc 5: Truy cap va Su dung

### Lay URL website

```powershell
cd terraform
terraform output -raw website_url
```

### Chuc nang chinh

1. **Trang chu**: Xem danh sach san pham (fallback data khi DynamoDB rong)
2. **Dang ky**: Tao tai khoan moi (POST /auth/register)
3. **Dang nhap**: Dang nhap bang email + password (POST /auth/login)
4. **Dat hang**: Them san pham vao gio, dien thong tin, dat hang (POST /orders)
5. **Xem don hang**: Xem lich su don hang (GET /orders?userId=...)

### Test API truc tiep

```powershell
# Lay API URL
$api = "$(cd terraform; terraform output -raw api_url)"

# Test lay san pham
Invoke-RestMethod -Uri "$api/products" -Method GET

# Test dang ky
$body = @{email="user@test.com"; password="MyPassword123!"; name="Nguyen Van A"} | ConvertTo-Json
Invoke-RestMethod -Uri "$api/auth/register" -Method POST -Body $body -ContentType "application/json"

# Test dang nhap
$body = @{email="user@test.com"; password="MyPassword123!"} | ConvertTo-Json
Invoke-RestMethod -Uri "$api/auth/login" -Method POST -Body $body -ContentType "application/json"
```

---

## Cac lenh thuong dung

| Muc dich | Lenh |
|----------|------|
| Xem trang thai infra | `cd terraform && terraform show` |
| Xem API URL | `cd terraform && terraform output -raw api_url` |
| Xem website URL | `cd terraform && terraform output -raw website_url` |
| Xem tat ca outputs | `cd terraform && terraform output` |
| Chay frontend local | `npm run dev` |
| Build frontend | `npm run build` |
| Deploy frontend | `aws s3 sync dist/ s3://BUCKET_NAME --delete` |
| Xem tai nguyen da tao | `cd terraform && terraform state list` |

---

## Xoa toan bo tai nguyen

```powershell
cd terraform
terraform destroy -var-file="environments/dev.tfvars" -var="jwt_secret=my-super-secret-key-2024"
# Nhap "yes" khi duoc hoi
```

> **Tat ca** AWS resources (S3, DynamoDB, Lambda, API Gateway, IAM) se bi xoa.
> Data trong DynamoDB va S3 se bi MAT VINH VIEN.

---

## Xu ly loi thuong gap

### Loi: "S3 bucket already exists"
Ten bucket da duoc su dung boi nguoi khac tren AWS. Doi `frontend_bucket_name` hoac `images_bucket_name` trong tfvars.

### Loi: "JWT secret must be at least 16 characters"
JWT secret qua ngan. Dung chuoi dai hon 16 ky tu.

### Loi: "terraform init required"
Chua chay `terraform init`. Chay lenh nay truoc khi plan/apply.

### Loi: Frontend hien thi nhung API khong hoat dong
- Kiem tra `.env` co dung API URL khong
- Build lai frontend: `npm run build`
- Deploy lai: `aws s3 sync dist/ s3://BUCKET_NAME --delete`

### Loi: "AccessDenied" khi deploy len S3
- Kiem tra AWS CLI da cau hinh dung credentials chua: `aws sts get-caller-identity`
- Kiem tra IAM user co quyen S3 khong

### Loi: Frontend fallback data (khong co san pham tu API)
- Day la binh thuong khi DynamoDB table CoffeeProducts trong
- Frontend tu dong dung DEFAULT_PRODUCTS lam fallback
- Them san pham vao DynamoDB bang AWS Console hoac API

---

## Quick Start (Tom tat)

```powershell
# === LAN DAU ===
# 1. Sua terraform/environments/dev.tfvars (doi bucket names)
# 2. Deploy infrastructure
cd terraform
cd lambda-src/layer/nodejs && npm install && cd ../../..
terraform init
terraform apply -var-file="environments/dev.tfvars" -var="jwt_secret=my-super-secret-key-2024"
.\scripts\sync-env.ps1

# 3. Build va deploy frontend
cd ..
npm install
npm run build
aws s3 sync dist/ s3://YOUR-FRONTEND-BUCKET --delete

# 4. Mo website
cd terraform && terraform output -raw website_url

# === CAP NHAT FRONTEND ===
npm run build
aws s3 sync dist/ s3://YOUR-FRONTEND-BUCKET --delete

# === XOA TAT CA ===
cd terraform
terraform destroy -var-file="environments/dev.tfvars" -var="jwt_secret=my-super-secret-key-2024"
```
