// Application Constants

export const ORDER_STATUS = {
  PENDING: 'pending',
  PROCESSING: 'processing',
  SHIPPED: 'shipped',
  DELIVERED: 'delivered',
  CANCELLED: 'cancelled',
};

export const ORDER_STATUS_LABELS = {
  pending: 'Chờ xử lý',
  processing: 'Đang xử lý',
  shipped: 'Đang giao',
  delivered: 'Đã giao',
  cancelled: 'Đã huỷ',
};

export const COFFEE_SIZES = {
  SMALL: '8OZ',
  LARGE: '12OZ',
};

export const USER_ROLES = {
  CUSTOMER: 'customer',
  ADMIN: 'admin',
};

export const ADVERTISEMENT_MESSAGES = [
  "Hãy mua nhanh khi còn có thể :)",
  "Miễn phí vận chuyển cho đơn hàng trên 500.000 VND",
  "Nhận một ly cà phê miễn phí vào ngày sinh nhật của bạn!",
];

export const VALIDATION_RULES = {
  PHONE_PATTERN: /^[0-9]{10,11}$/,
  EMAIL_PATTERN: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
  PASSWORD_MIN_LENGTH: 8,
};
