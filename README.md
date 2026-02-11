# ☕ Coffee Shop - Serverless Web Application

> Ứng dụng web bán cà phê trực tuyến được xây dựng với kiến trúc serverless trên AWS

![Project Banner](./docs/images/banner.png)

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)]()
[![React](https://img.shields.io/badge/React-19.0-blue?logo=react)]()
[![AWS](https://img.shields.io/badge/AWS-Serverless-orange?logo=amazon-aws)]()
[![Terraform](https://img.shields.io/badge/Terraform-IaC-purple?logo=terraform)]()

## 📖 Tổng quan

Coffee Shop là một ứng dụng web thương mại điện tử hiện đại cho phép người dùng duyệt, đặt hàng và quản lý các sản phẩm cà phê trực tuyến. Dự án được xây dựng với kiến trúc **Serverless** hoàn toàn trên AWS, tận dụng các dịch vụ managed để giảm thiểu chi phí vận hành và tăng khả năng mở rộng.

### ✨ Tính năng chính

- 🛍️ **Quản lý giỏ hàng**: Thêm/xóa sản phẩm, chọn size, tính tổng tiền tự động
- 👤 **Xác thực người dùng**: Đăng ký, đăng nhập với JWT authentication
- 📦 **Quản lý đơn hàng**: Xem lịch sử đơn hàng, theo dõi trạng thái
- 💳 **Thanh toán**: Thu thập thông tin giao hàng và xử lý đơn hàng
- 📱 **Responsive Design**: Giao diện thân thiện trên mọi thiết bị
- 🔒 **Bảo mật**: CORS, HTTPS, JWT tokens, IAM policies

## 🏗️ Kiến trúc hệ thống

![Architecture Diagram](./docs/images/architecture.png)

### Tech Stack

#### Frontend
- **ReactJS 19.0** - UI Framework
- **React Router** - Client-side routing
- **Vite** - Build tool & dev server
- **CSS3** - Styling

#### Backend (AWS Serverless)
- **Amazon S3** - Static website hosting
- **CloudFront** - CDN (optional)
- **API Gateway** - RESTful API endpoints
- **AWS Lambda** - Serverless compute (Node.js 20.x)
- **DynamoDB** - NoSQL database
- **IAM** - Access management

#### Infrastructure as Code
- **Terraform** - Infrastructure provisioning và quản lý tài nguyên AWS

#### Công cụ phát triển
- **ESLint** - Code linting
- **Git** - Version control
- **AWS CLI** - AWS management

## 📁 Cấu trúc dự án

```
coffee-shop/
├── src/                          # Frontend source code
│   ├── components/               # React components
│   │   ├── auth/                # Authentication components
│   │   ├── common/              # Shared components
│   │   └── product/             # Product components
│   ├── context/                 # React Context (State management)
│   ├── hooks/                   # Custom React hooks
│   ├── pages/                   # Page components
│   ├── services/                # API services
│   ├── utils/                   # Utility functions
│   └── models/                  # Data models
│
├── terraform/                    # Infrastructure as Code
│   ├── modules/                 # Terraform modules
│   │   ├── api-gateway/        # API Gateway configuration
│   │   ├── dynamodb/           # DynamoDB tables
│   │   ├── iam/                # IAM roles & policies
│   │   ├── lambda/             # Lambda functions
│   │   ├── lambda-layer/       # Lambda layers
│   │   └── s3-frontend/        # S3 hosting
│   ├── lambda-src/             # Lambda function source code
│   │   ├── create-order/
│   │   ├── get-orders/
│   │   ├── login-user/
│   │   ├── register-user/
│   │   └── update-user/
│   ├── environments/           # Environment configs
│   └── main.tf                 # Main Terraform configuration
│
├── docs/                        # Documentation
├── dist/                        # Build output
└── public/                      # Static assets
```

## 🚀 Cài đặt và Triển khai

### Yêu cầu

- Node.js 18+ và npm/yarn
- AWS Account với credentials configured
- Terraform 1.0+
- AWS CLI v2

### 1. Clone dự án

```bash
git clone https://github.com/imLeHuyHoang/coffee-website-project.git
cd coffee-website-project
```

### 2. Cài đặt dependencies

```bash
npm install
```

### 3. Cấu hình môi trường

Tạo file `.env` trong thư mục root:

```env
VITE_API_BASE_URL=https://your-api-gateway-url.execute-api.region.amazonaws.com/prod
```

### 4. Chạy development server

```bash
npm run dev
```

Truy cập http://localhost:5173 để xem ứng dụng.

### 5. Build production

```bash
npm run build
```

## ☁️ Triển khai lên AWS

### Bước 1: Cấu hình AWS credentials

```bash
aws configure
```

### Bước 2: Cài đặt Lambda Layer dependencies

```bash
cd terraform/lambda-src/layer/nodejs
npm install
cd ../../../..
```

### Bước 3: Cấu hình Terraform variables

Tạo file `terraform/terraform.tfvars`:

```hcl
project_name         = "Coffee"
frontend_bucket_name = "coffee-shop-frontend-yourname"
images_bucket_name   = "coffee-shop-images-yourname"
aws_region          = "ap-southeast-1"
stage_name          = "prod"
jwt_secret          = "your-super-secret-key"
```

### Bước 4: Deploy infrastructure với Terraform

```bash
cd terraform
terraform init
terraform plan -var-file="environments/prod.tfvars" -var="jwt_secret=your-secret"
terraform apply -var-file="environments/prod.tfvars" -var="jwt_secret=your-secret"
```

### Bước 5: Deploy frontend lên S3

```bash
cd ..
npm run build
aws s3 sync dist/ s3://your-frontend-bucket-name --delete
```

### Bước 6: Cập nhật API URL

Sau khi Terraform deploy xong, cập nhật file `.env` với API Gateway URL từ output:

```bash
cd terraform
terraform output api_url
```

Rebuild và redeploy frontend với URL mới.

## 🌐 API Endpoints

| Method | Endpoint | Mô tả | Auth |
|--------|----------|-------|------|
| GET | `/products` | Lấy danh sách sản phẩm | No |
| POST | `/orders` | Tạo đơn hàng mới | No |
| GET | `/orders` | Lấy lịch sử đơn hàng | Yes |
| POST | `/auth/register` | Đăng ký tài khoản | No |
| POST | `/auth/login` | Đăng nhập | No |
| PUT | `/auth/profile` | Cập nhật thông tin | Yes |

## 📊 DynamoDB Tables

- **CoffeeProducts** - Lưu trữ thông tin sản phẩm
- **CoffeeOrders** - Lưu trữ đơn hàng
- **CoffeeUsers** - Lưu trữ thông tin người dùng
- **CoffeeReviews** - Lưu trữ đánh giá sản phẩm

## 🔧 Scripts npm

```bash
npm run dev          # Chạy development server
npm run build        # Build production
npm run preview      # Preview production build
npm run lint         # Chạy ESLint
```

## 🧪 Testing

```bash
npm test             # Chạy tests (nếu có)
```

## 📝 Environment Variables

### Frontend (.env)

```env
VITE_API_BASE_URL=              # API Gateway URL
```

### Backend (Lambda)

- `JWT_SECRET` - Secret key cho JWT signing
- `USERS_TABLE` - DynamoDB Users table name
- `ORDERS_TABLE` - DynamoDB Orders table name
- `PRODUCTS_TABLE` - DynamoDB Products table name
- `AWS_REGION_` - AWS Region

## 🤝 Đóng góp

Mọi đóng góp đều được chào đón! Vui lòng:

1. Fork dự án
2. Tạo branch mới (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Mở Pull Request

## 📜 License

Dự án này được phân phối dưới giấy phép MIT. Xem file `LICENSE` để biết thêm chi tiết.

## 👤 Tác giả

**imLeHuyHoang**

- Email: lehuyhoang1352002@gmail.com
- GitHub: [@imLeHuyHoang](https://github.com/imLeHuyHoang)

## 🙏 Cảm ơn

- AWS Documentation
- Terraform Registry
- React Community
- Tất cả contributors

## 📞 Liên hệ & Hỗ trợ

Nếu bạn có bất kỳ câu hỏi hoặc cần hỗ trợ, vui lòng:
- Tạo issue trên GitHub
- Email: lehuyhoang1352002@gmail.com

---

⭐ Nếu bạn thấy dự án hữu ích, hãy cho một star nhé!

