# Tham Chieu Cau Hinh Bien Moi Truong (ENV Configuration Reference)

> Tai lieu nay mo ta CHI TIET tung bien cau hinh trong du an.  
> Nguoi dung chi can sua file cau hinh, code se tu dong doc dung noi.

---

## Tong quan

Du an su dung **2 lop cau hinh**:

```
┌─────────────────────────────────────────┐
│  Terraform (.tfvars)                    │
│  → Cau hinh AWS infrastructure          │
│  → File: terraform/environments/*.tfvars│
├─────────────────────────────────────────┤
│  Frontend (.env)                        │
│  → Cau hinh React app                  │
│  → File: .env (root du an)             │
│  → TU DONG tao boi sync-env script     │
└─────────────────────────────────────────┘
```

**Luong du lieu:**
```
dev.tfvars → terraform apply → AWS Resources → terraform output
                                                     ↓
                                              sync-env.ps1
                                                     ↓
                                            .env (VITE_API_BASE_URL)
                                                     ↓
                                          npm run build → dist/
```

---

## 1. Terraform Variables (.tfvars)

### 1.1 NAMING - Bien dat ten tai nguyen

#### `project_name`
| Thuoc tinh | Gia tri |
|------------|---------|
| **Kieu** | string |
| **Mac dinh** | `"Coffee"` |
| **Bat buoc** | Khong (co gia tri default) |
| **Validation** | Regex `^[A-Za-z][A-Za-z0-9]{1,19}$` |
| **Gioi han** | 2-20 ky tu, bat dau bang chu cai, chi chu + so |

**Anh huong:**
```
project_name = "Coffee"     project_name = "TeaShop"
──────────────────────      ──────────────────────
CoffeeLambdaRole            TeaShopLambdaRole
CoffeeLambdaPolicy          TeaShopLambdaPolicy
coffee-get-products         teashop-get-products
coffee-create-order         teashop-create-order
coffee-get-orders           teashop-get-orders
coffee-register-user        teashop-register-user
coffee-login-user           teashop-login-user
CoffeeNodeModules           TeaShopNodeModules
CoffeeShopAPI               TeaShopShopAPI
CoffeeProducts              TeaShopProducts
CoffeeOrders                TeaShopOrders
CoffeeUsers                 TeaShopUsers
CoffeeReviews               TeaShopReviews
```

> ⚠️ **CANH BAO**: Doi `project_name` SAU KHI deploy se khien Terraform XOA + TAO LAI tat ca tai nguyen. Data trong DynamoDB se MAT.

---

#### `frontend_bucket_name`
| Thuoc tinh | Gia tri |
|------------|---------|
| **Kieu** | string |
| **Bat buoc** | Co |
| **Quy tac** | GLOBALLY UNIQUE tren toan bo AWS, 3-63 ky tu |
| **Ky tu hop le** | a-z (lowercase), 0-9, dau gach ngang (-) |

**Vi du:**
```hcl
frontend_bucket_name = "coffee-shop-frontend-dev-yourname"
# ↪ Tao S3 bucket hosting website tinh
# ↪ URL: http://coffee-shop-frontend-dev-yourname.s3-website-{region}.amazonaws.com
```

> **Meo**: Them ten ca nhan hoac ma so vao cuoi de dam bao unique: `coffee-shop-dev-nguyenvana`

---

#### `images_bucket_name`
| Thuoc tinh | Gia tri |
|------------|---------|
| **Kieu** | string |
| **Bat buoc** | Co |
| **Quy tac** | GLOBALLY UNIQUE, tuong tu `frontend_bucket_name` |

**Vi du:**
```hcl
images_bucket_name = "coffee-shop-images-dev-yourname"
# ↪ Luu tru hinh anh san pham
```

---

### 1.2 AWS CONFIG - Cau hinh AWS

#### `aws_region`
| Thuoc tinh | Gia tri |
|------------|---------|
| **Kieu** | string |
| **Mac dinh** | `"ap-southeast-1"` (Singapore) |

**Cac region pho bien:**
| Region | Vi tri | Code |
|--------|--------|------|
| Singapore | Dong Nam A | `ap-southeast-1` |
| Tokyo | Nhat Ban | `ap-northeast-1` |
| US East | Virginia, My | `us-east-1` |
| EU West | Ireland | `eu-west-1` |

> Chon region gan vi tri dia ly cua nguoi dung de giam latency.

---

#### `stage_name`
| Thuoc tinh | Gia tri |
|------------|---------|
| **Kieu** | string |
| **Mac dinh** | `"dev"` |
| **Gia tri thuong dung** | `"dev"`, `"staging"`, `"prod"` |

```hcl
stage_name = "dev"   # → API URL: .../dev/products
stage_name = "prod"  # → API URL: .../prod/products
```

---

### 1.3 SECURITY - Bao mat

#### `jwt_secret`
| Thuoc tinh | Gia tri |
|------------|---------|
| **Kieu** | string (sensitive) |
| **Bat buoc** | Co |
| **Gioi han** | Toi thieu 16 ky tu |
| **Cach truyen** | Command line hoac bien moi truong |

**KHONG BAO GIO** dat jwt_secret trong file .tfvars:

```powershell
# ✅ DUNG: Truyen qua command line
terraform apply -var-file="environments/dev.tfvars" -var="jwt_secret=my-secret-key-at-least-16-chars"

# ✅ DUNG: Truyen qua bien moi truong
$env:TF_VAR_jwt_secret = "my-secret-key-at-least-16-chars"
terraform apply -var-file="environments/dev.tfvars"

# ❌ SAI: Dat trong file (lo thong tin khi commit git)
# jwt_secret = "my-secret"  # KHONG LAM THE NAY
```

**Tao JWT secret ngau nhien:**
```powershell
# PowerShell
[Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }) -as [byte[]])

# Bash/Linux
openssl rand -base64 32
```

---

### 1.4 RESOURCE BEHAVIOR - Hanh vi tai nguyen

#### `force_destroy`
| Thuoc tinh | Gia tri |
|------------|---------|
| **Kieu** | bool |
| **Mac dinh** | `false` |
| **Khuyen nghi Dev** | `true` |
| **Khuyen nghi Prod** | `false` |

```hcl
force_destroy = true   # Cho phep xoa S3 bucket ngay ca khi con files
force_destroy = false  # Bao ve: terraform destroy se THAT BAI neu bucket con files
```

---

#### `log_retention_days`
| Thuoc tinh | Gia tri |
|------------|---------|
| **Kieu** | number |
| **Mac dinh** | `14` |
| **Gia tri hop le** | 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653 |

```hcl
log_retention_days = 7    # Dev: giu log 7 ngay
log_retention_days = 30   # Prod: giu log 30 ngay
```

---

#### `lambda_timeout`
| Thuoc tinh | Gia tri |
|------------|---------|
| **Kieu** | number (giay) |
| **Mac dinh** | `30` |
| **Gioi han** | 1 - 900 |

---

#### `lambda_memory_size`
| Thuoc tinh | Gia tri |
|------------|---------|
| **Kieu** | number (MB) |
| **Mac dinh** | `128` |
| **Gioi han** | 128 - 10240 (buoc 64MB) |

> Tang memory cung tang CPU tuong ung. 128MB du cho du an nho.

---

### 1.5 DYNAMODB - Cau hinh Database

#### `dynamodb_billing_mode`
| Thuoc tinh | Gia tri |
|------------|---------|
| **Kieu** | string |
| **Mac dinh** | `"PAY_PER_REQUEST"` |

| Mode | Mo ta | Phu hop |
|------|-------|---------|
| `PAY_PER_REQUEST` | Tra theo so luong request | Dev, traffic khong deu |
| `PROVISIONED` | Tra theo capacity dat truoc | Traffic on dinh, tiet kiem chi phi |

---

#### `enable_point_in_time_recovery`
| Thuoc tinh | Gia tri |
|------------|---------|
| **Kieu** | bool |
| **Mac dinh** | `false` |
| **Khuyen nghi Prod** | `true` |

Bat tinh nang backup lien tuc cua DynamoDB. Cho phep khoi phuc data ve bat ky thoi diem nao trong 35 ngay.

---

### 1.6 S3 IMAGES - Cau hinh Bucket anh

#### `enable_versioning`
| Thuoc tinh | Gia tri |
|------------|---------|
| **Kieu** | bool |
| **Mac dinh** | `false` |
| **Khuyen nghi Prod** | `true` |

Giu moi phien ban cua file khi upload de len. Cho phep khoi phuc file bi xoa hoac bi ghi de.

---

#### `enable_lifecycle`
| Thuoc tinh | Gia tri |
|------------|---------|
| **Kieu** | bool |
| **Mac dinh** | `false` |

Tu dong chuyen file cu sang storage re hon (Glacier) hoac xoa sau thoi gian.

---

#### `cors_allowed_origins`
| Thuoc tinh | Gia tri |
|------------|---------|
| **Kieu** | list(string) |
| **Mac dinh** | `["*"]` |

```hcl
# Dev: cho phep tat ca
cors_allowed_origins = ["*"]

# Prod: chi cho phep domain chinh
cors_allowed_origins = ["https://myshop.com", "https://www.myshop.com"]
```

---

## 2. Frontend Variables (.env)

### Cach tao file .env

**Tu dong (khuyen nghi):**
```powershell
cd terraform
.\scripts\sync-env.ps1    # Windows
./scripts/sync-env.sh     # Linux/Mac
```

**Thu cong:**
```dotenv
VITE_API_BASE_URL=https://YOUR-API-ID.execute-api.ap-southeast-1.amazonaws.com/dev
```

### `VITE_API_BASE_URL`
| Thuoc tinh | Gia tri |
|------------|---------|
| **Kieu** | string (URL) |
| **Bat buoc** | Co |
| **Lay tu** | `terraform output -raw api_url` |

Day la URL duy nhat ma frontend can de ket noi voi backend API Gateway.

**Cach code doc bien nay:**
```
.env (VITE_API_BASE_URL)
    ↓
src/config/api.config.js (import.meta.env.VITE_API_BASE_URL)
    ↓
src/services/*.js (API_CONFIG.BASE_URL)
    ↓
React components (hooks & context)
```

> **Luu y**: Moi khi doi .env, phai `npm run build` lai va deploy len S3.

---

## 3. Bieu do luong cau hinh

```
terraform/environments/dev.tfvars
│
├── project_name ──────→ IAM Role/Policy names
│                  ──→ Lambda function names
│                  ──→ Lambda Layer name
│                  ──→ API Gateway name
│                  ──→ DynamoDB table names (prefix)
│
├── frontend_bucket_name ──→ S3 Frontend bucket
├── images_bucket_name ────→ S3 Images bucket
├── aws_region ────────────→ All AWS resources location
├── stage_name ────────────→ API Gateway stage
├── jwt_secret ────────────→ Lambda env vars (auth)
│
│   [sync-env.ps1 tu dong tao]
│         ↓
│   .env
│   └── VITE_API_BASE_URL ──→ src/config/api.config.js
│                          ──→ src/services/productService.js
│                          ──→ src/services/authService.js
│                          ──→ src/services/orderService.js
│                          ──→ src/services/reviewService.js
```

---

## 4. Checklist Truoc Khi Deploy

- [ ] Da sua `frontend_bucket_name` thanh ten UNIQUE cua ban
- [ ] Da sua `images_bucket_name` thanh ten UNIQUE cua ban
- [ ] Da chon `aws_region` phu hop
- [ ] Da chuan bi `jwt_secret` (>= 16 ky tu)
- [ ] Da cau hinh AWS CLI (`aws configure`)
- [ ] Da cai `terraform` va `node` dung version

---

## 5. Vi du Cau hinh Day Du

### Dev environment
```hcl
# terraform/environments/dev.tfvars

# === NAMING: Dat ten tai nguyen ===
project_name         = "Coffee"
frontend_bucket_name = "coffee-shop-frontend-dev-nguyenvana"
images_bucket_name   = "coffee-shop-images-dev-nguyenvana"

# === AWS CONFIG ===
aws_region = "ap-southeast-1"
stage_name = "dev"

# === RESOURCE BEHAVIOR ===
force_destroy      = true
log_retention_days = 7
lambda_timeout     = 30
lambda_memory_size = 128

# === DYNAMODB ===
dynamodb_billing_mode         = "PAY_PER_REQUEST"
enable_point_in_time_recovery = false

# === S3 IMAGES ===
enable_versioning    = false
enable_lifecycle     = false
cors_allowed_origins = ["*"]
```

### Production environment
```hcl
# terraform/environments/prod.tfvars

# === NAMING: Dat ten tai nguyen ===
project_name         = "Coffee"
frontend_bucket_name = "coffee-shop-frontend-prod-nguyenvana"
images_bucket_name   = "coffee-shop-images-prod-nguyenvana"

# === AWS CONFIG ===
aws_region = "ap-southeast-1"
stage_name = "prod"

# === RESOURCE BEHAVIOR ===
force_destroy      = false
log_retention_days = 30
lambda_timeout     = 30
lambda_memory_size = 256

# === DYNAMODB ===
dynamodb_billing_mode         = "PAY_PER_REQUEST"
enable_point_in_time_recovery = true

# === S3 IMAGES ===
enable_versioning    = true
enable_lifecycle     = true
cors_allowed_origins = ["https://your-domain.com"]
```
