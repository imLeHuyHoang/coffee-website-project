# Coffee Website Project

## Hướng dẫn cài đặt và khởi chạy

### Bước 1: Clone dự án

Mở terminal (hoặc cmd, PowerShell) và chạy lệnh sau:

```bash
git clone https://github.com/imLeHuyHoang/coffee-website-project.git
```

### Bước 2: Cài đặt npm

```bash
cd coffee-website-project
```

Sau đó, cài đặt các package cần thiết:

```bash
npm install
```

_Nếu dùng Yarn thì thay `npm install` bằng `yarn`._

### Bước 3: Khởi chạy ở môi trường Development

```bash
npm run dev
```

Sau khi chạy, Vite sẽ thông báo địa chỉ server (thường là [http://localhost:5173/](http://localhost:5173/)). Mở trình duyệt và truy cập địa chỉ này để xem website.

### Bước 4: Build và Deploy (Tùy chọn)

Nếu bạn đã code sẵn Docker Compose, hãy chạy lệnh sau để build và chạy container:

```bash
docker-compose up -d --build
```

## Góp ý và Hỗ trợ

- Mọi góp ý và hỗ trợ xin vui lòng gửi issue trên GitHub.

## Thông tin liên hệ

- Tác giả: imLeHuyHoang
- Email: [lehuyhoang1352002@gmail.com]
