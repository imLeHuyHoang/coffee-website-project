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
  "Shop now before it's too late :)",
  "Free shipping on orders above 500.000 VND",
  "New collection coming soon!",
  "Get a free coffee on your birthday!",
];

export const VALIDATION_RULES = {
  PHONE_PATTERN: /^[0-9]{10,11}$/,
  EMAIL_PATTERN: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
  PASSWORD_MIN_LENGTH: 8,
};
