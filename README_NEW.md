# ☕ Coffee Shop - Modern E-commerce Website

## 📋 Mô tả dự án

Dự án Coffee Shop là một trang web thương mại điện tử hiện đại để bán cà phê trực tuyến. Dự án được xây dựng với kiến trúc Serverless trên AWS, sử dụng React cho Frontend và API Gateway + Lambda + DynamoDB cho Backend.

## 🏗️ Kiến trúc

### Frontend
- **React 19** với Vite
- **React Router v6** cho routing
- **Context API** cho state management
- **Zod** cho validation

### Backend (AWS Serverless)
- **API Gateway** - REST API endpoints
- **Lambda Functions** - Business logic
- **DynamoDB** - NoSQL database
- **S3** - Static hosting & image storage
- **CloudFront** - CDN
- **Cognito** (Optional) - User authentication
- **SES** (Optional) - Email notifications

### Cấu trúc MVC
```
src/
├── config/              # API configuration
├── models/              # Data models (Product, Order, User, Review)
├── services/            # API service layer
├── context/             # React Context (Auth, Cart)
├── hooks/               # Custom React hooks
├── components/          # Reusable components
│   ├── common/         # Header, Footer, Navbar, etc.
│   ├── product/        # ProductCard, ProductList
│   ├── auth/           # Login, Register
│   └── ...
├── pages/               # Page components
│   ├── HomePage.jsx
│   ├── ProductsPage.jsx
│   ├── CartPage.jsx
│   ├── OrderHistoryPage.jsx
│   └── ProfilePage.jsx
└── utils/               # Utility functions
```

## ✨ Tính năng

### Đã triển khai
1. ✅ **Trang chủ**: Banner, danh sách sản phẩm
2. ✅ **Sản phẩm**: Xem danh sách, chi tiết sản phẩm
3. ✅ **Giỏ hàng**: Thêm/xóa sản phẩm, quản lý số lượng
4. ✅ **Đặt hàng**: Form đặt hàng, validation
5. ✅ **Đăng nhập/Đăng ký**: Authentication system
6. ✅ **Lịch sử đơn hàng**: Xem đơn hàng đã đặt
7. ✅ **Tài khoản**: Quản lý thông tin cá nhân
8. ✅ **Responsive**: Tối ưu cho mobile

### Đang phát triển
- 🚧 **Đánh giá sản phẩm**: Rating & reviews
- 🚧 **Admin Dashboard**: Quản lý sản phẩm, đơn hàng
- 🚧 **Upload ảnh**: S3 integration
- 🚧 **Email notifications**: SES integration
- 🚧 **Real-time notifications**: WebSocket

## 🚀 Hướng dẫn cài đặt

### Prerequisites
- Node.js >= 18
- npm hoặc yarn
- Git

### Bước 1: Clone repository
```bash
git clone https://github.com/imLeHuyHoang/coffee-website-project.git
cd coffee-website-project
```

### Bước 2: Cài đặt dependencies
```bash
npm install
```

### Bước 3: Cấu hình API (Optional)
Nếu bạn đã setup backend trên AWS, cập nhật file `src/config/api.config.js`:
```javascript
const API_CONFIG = {
  BASE_URL: 'https://your-api-gateway-url.amazonaws.com/prod',
  // ...
};
```

### Bước 4: Chạy development server
```bash
npm run dev
```

Truy cập: http://localhost:5173

### Bước 5: Build cho production
```bash
npm run build
```

## 🧪 Testing

```bash
npm test
```

## 📦 Deploy

### Deploy Frontend lên S3 + CloudFront
```bash
npm run build
aws s3 sync dist/ s3://your-bucket-name
aws cloudfront create-invalidation --distribution-id YOUR_DIST_ID --paths "/*"
```

### Deploy với Docker
```bash
docker-compose up -d --build
```

## 🔧 Cấu hình môi trường

Tạo file `.env` (nếu cần):
```env
VITE_API_BASE_URL=https://your-api-gateway-url.amazonaws.com/prod
VITE_AWS_REGION=ap-southeast-1
```

## 📚 Documentation

- [AWS Setup Guide](./docs/AWS_SETUP.md) - Hướng dẫn setup infrastructure trên AWS
- [Terraform Guide](./docs/TERRAFORM.md) - Infrastructure as Code với Terraform
- [API Documentation](./docs/API.md) - API endpoints documentation

## 🛠️ Tech Stack

**Frontend:**
- React 19
- Vite
- React Router v6
- Zod (validation)
- React Confetti

**Backend:**
- AWS API Gateway
- AWS Lambda (Node.js)
- AWS DynamoDB
- AWS S3
- AWS CloudFront
- AWS Cognito
- AWS SES

**DevOps:**
- Docker
- Terraform
- GitHub Actions (CI/CD)

## 📝 Scripts

```bash
npm run dev          # Chạy development server
npm run build        # Build production
npm run preview      # Preview production build
npm run lint         # Run ESLint
npm test             # Run tests
```

## 🤝 Contributing

Contributions, issues và feature requests đều được chào đón!

1. Fork dự án
2. Tạo branch mới (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Tạo Pull Request

## 👤 Author

**Lê Huy Hoàng (imLeHuyHoang)**
- GitHub: [@imLeHuyHoang](https://github.com/imLeHuyHoang)
- Email: lehuyhoang1352002@gmail.com

## 📄 License

This project is open source.

## 🙏 Acknowledgments

- React team
- AWS Serverless team
- Vite team
- All contributors

## 📈 Roadmap

### Phase 1: ✅ Refactoring & Basic Features (Completed)
- [x] Refactor code theo MVC
- [x] Implement Authentication
- [x] Order History
- [x] Cart Management

### Phase 2: 🚧 Advanced Features (In Progress)
- [ ] Product Reviews & Ratings
- [ ] Admin Dashboard
- [ ] Image Upload to S3
- [ ] Email Notifications (SES)

### Phase 3: 📝 Infrastructure as Code (Planned)
- [ ] Complete Terraform modules
- [ ] CI/CD with GitHub Actions
- [ ] Monitoring & Logging
- [ ] Performance optimization

### Phase 4: 🎯 Future Enhancements
- [ ] Payment integration (Stripe/VNPay)
- [ ] Real-time chat support
- [ ] Loyalty program
- [ ] Mobile app (React Native)

---

Made with ☕ and ❤️ by imLeHuyHoang
