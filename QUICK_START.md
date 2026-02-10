# 🚀 QUICK START GUIDE

## Chạy dự án Coffee Shop trong 5 phút!

---

## ✅ Prerequisites

Đảm bảo bạn đã cài đặt:
- **Node.js** >= 18 ([Download](https://nodejs.org/))
- **npm** hoặc **yarn**
- **Git**

---

## 📦 Bước 1: Setup Project

```bash
# Clone repository (nếu chưa có)
git clone https://github.com/imLeHuyHoang/coffee-website-project.git
cd coffee-website-project

# Cài đặt dependencies
npm install

# Hoặc nếu dùng yarn
yarn install
```

---

## 🔧 Bước 2: Configuration (Optional)

### Option A: Chạy với Default Data (Không cần AWS)

Không cần làm gì! App sẽ tự động sử dụng data mặc định.

### Option B: Connect với AWS Backend

1. Đã setup AWS infrastructure theo [AWS_SETUP.md](./docs/AWS_SETUP.md)
2. Update file `src/config/api.config.js`:

```javascript
const API_CONFIG = {
  BASE_URL: 'https://YOUR-API-GATEWAY-URL/prod',
  // Ví dụ: https://abc123.execute-api.ap-southeast-1.amazonaws.com/prod
  // ...
};
```

---

## 🎮 Bước 3: Chạy Development Server

```bash
npm run dev
```

Hoặc:

```bash
yarn dev
```

Server sẽ start tại: **http://localhost:5173**

---

## 🌐 Bước 4: Mở Browser

1. Mở browser
2. Truy cập: `http://localhost:5173`
3. Khám phá app! 🎉

---

## ✨ Tính năng có thể test

### Không cần đăng nhập:
- ✅ Xem trang chủ
- ✅ Xem danh sách sản phẩm
- ✅ Thêm sản phẩm vào giỏ hàng
- ✅ Đặt hàng (guest checkout)

### Cần đăng nhập:
- ✅ Đăng ký tài khoản mới
- ✅ Đăng nhập
- ✅ Xem lịch sử đơn hàng
- ✅ Quản lý thông tin cá nhân

---

## 🧪 Testing Flow

### 1. Test Guest User (Không đăng nhập)

```
1. Vào trang chủ (/)
2. Click "KHÁM PHÁ NGAY" để scroll tới sản phẩm
3. Click vào 1 sản phẩm để xem chi tiết
4. Click nút "+ 8OZ" hoặc "+ 12OZ" để thêm vào giỏ
5. Click "Giỏ hàng" ở header (sẽ thấy badge số lượng)
6. Điền thông tin người nhận
7. Click "Đặt hàng"
8. Thấy confetti animation & thông báo thành công ✅
```

### 2. Test Registered User (Có đăng nhập)

```
1. Click "Đăng ký" ở header
2. Điền form đăng ký:
   - Họ và tên
   - Email
   - Số điện thoại
   - Mật khẩu
   - Xác nhận mật khẩu
3. Click "Đăng ký"
4. Sau khi đăng ký thành công, sẽ tự động login
5. Header hiển thị: "Xin chào, [Tên]!"
6. Test shopping flow như guest
7. Click "Đơn hàng" để xem lịch sử
8. Click "Tài khoản" để quản lý profile
9. Test "Đăng xuất"
```

### 3. Test Login

```
1. Click "Đăng xuất" (nếu đang login)
2. Click "Đăng nhập"
3. Nhập email & password đã đăng ký
4. Click "Đăng nhập"
5. Kiểm tra đã login thành công ✅
```

---

## 🐛 Common Issues & Solutions

### Issue 1: Port 5173 đã được sử dụng

```bash
# Ngừng process đang dùng port
# Windows:
netstat -ano | findstr :5173
taskkill /PID <PID> /F

# Mac/Linux:
lsof -ti:5173 | xargs kill -9

# Hoặc đổi port
npm run dev -- --port 3000
```

### Issue 2: Dependencies install failed

```bash
# Xóa node_modules và reinstall
rm -rf node_modules package-lock.json
npm install

# Hoặc clear cache
npm cache clean --force
npm install
```

### Issue 3: API calls thất bại

- **Nguyên nhân**: Chưa setup AWS hoặc sai API URL
- **Giải pháp**: App sẽ tự động fallback sang default data
- **Kiểm tra**: Mở DevTools → Console → Xem error logs

### Issue 4: Login/Register không hoạt động

- **Nguyên nhân**: Backend chưa sẵn sàng
- **Giải pháp**: Authentication sẽ fail gracefully
- **Note**: Để test đầy đủ auth, cần setup Lambda functions

---

## 📂 Project Structure Quick Reference

```
src/
├── config/          ← API configuration
├── models/          ← Data models
├── services/        ← API services
├── context/         ← Auth & Cart context
├── hooks/           ← Custom hooks
├── components/      ← UI components
├── pages/           ← Page components
└── utils/           ← Utilities
```

---

## 🎨 Screenshots

### Trang chủ
- Banner với call-to-action
- Carousel quảng cáo
- Grid sản phẩm

### Giỏ hàng
- Danh sách sản phẩm đã chọn
- Điều chỉnh số lượng
- Form thông tin người nhận
- Tổng tiền

### Lịch sử đơn hàng
- Danh sách orders
- Trạng thái đơn hàng
- Chi tiết từng đơn

---

## 📚 Next Steps

### Sau khi test local thành công:

1. **Setup AWS Backend**
   - Follow [AWS_SETUP.md](./docs/AWS_SETUP.md)
   - Create DynamoDB tables
   - Deploy Lambda functions
   - Create API Gateway

2. **Update Configuration**
   - Update `src/config/api.config.js`
   - Test with real backend

3. **Build & Deploy**
   ```bash
   npm run build
   # Deploy dist/ folder to S3
   ```

---

## 🔗 Useful Links

- **GitHub Repo**: https://github.com/imLeHuyHoang/coffee-website-project
- **AWS Setup Guide**: [docs/AWS_SETUP.md](./docs/AWS_SETUP.md)
- **Refactoring Summary**: [docs/REFACTORING_SUMMARY.md](./docs/REFACTORING_SUMMARY.md)

---

## 💡 Tips

### Development
- Use React DevTools để debug components
- Check Console logs để debug API calls
- Check Application tab (DevTools) để xem localStorage

### Testing
- Test trên nhiều browsers (Chrome, Firefox, Safari)
- Test responsive trên mobile (Toggle device toolbar)
- Test với data khác nhau (empty cart, many items)

### Performance
- Mở Network tab để monitor API calls
- Check loading times
- Verify caching works

---

## 🆘 Need Help?

1. Check [REFACTORING_SUMMARY.md](./docs/REFACTORING_SUMMARY.md)
2. Check [AWS_SETUP.md](./docs/AWS_SETUP.md)
3. Open GitHub issue
4. Contact: lehuyhoang1352002@gmail.com

---

## ✅ Checklist

- [ ] Node.js installed
- [ ] Project cloned
- [ ] Dependencies installed
- [ ] Dev server running
- [ ] Browser opened at localhost:5173
- [ ] Tested guest checkout
- [ ] Tested registration
- [ ] Tested login
- [ ] Tested order history
- [ ] Ready for AWS setup!

---

**Happy Coding! ☕**

---

Made with ❤️ by imLeHuyHoang
