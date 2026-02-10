import { z } from 'zod';
import { VALIDATION_RULES } from './constants';

// Order validation schema
export const orderSchema = z.object({
  name: z.string().min(1, 'Vui lòng nhập tên người nhận.'),
  address: z.string().min(1, 'Vui lòng nhập địa chỉ.'),
  phone: z
    .string()
    .min(1, 'Vui lòng nhập số điện thoại.')
    .regex(VALIDATION_RULES.PHONE_PATTERN, 'Số điện thoại không hợp lệ.'),
});

// Register validation schema
export const registerSchema = z.object({
  name: z.string().min(2, 'Tên phải có ít nhất 2 ký tự.'),
  email: z
    .string()
    .min(1, 'Vui lòng nhập email.')
    .regex(VALIDATION_RULES.EMAIL_PATTERN, 'Email không hợp lệ.'),
  phone: z
    .string()
    .min(1, 'Vui lòng nhập số điện thoại.')
    .regex(VALIDATION_RULES.PHONE_PATTERN, 'Số điện thoại không hợp lệ.'),
  password: z
    .string()
    .min(VALIDATION_RULES.PASSWORD_MIN_LENGTH, `Mật khẩu phải có ít nhất ${VALIDATION_RULES.PASSWORD_MIN_LENGTH} ký tự.`),
  confirmPassword: z.string(),
}).refine((data) => data.password === data.confirmPassword, {
  message: 'Mật khẩu xác nhận không khớp.',
  path: ['confirmPassword'],
});

// Login validation schema
export const loginSchema = z.object({
  email: z
    .string()
    .min(1, 'Vui lòng nhập email.')
    .regex(VALIDATION_RULES.EMAIL_PATTERN, 'Email không hợp lệ.'),
  password: z
    .string()
    .min(1, 'Vui lòng nhập mật khẩu.'),
});

// Review validation schema
export const reviewSchema = z.object({
  rating: z
    .number()
    .min(1, 'Vui lòng chọn đánh giá.')
    .max(5, 'Đánh giá tối đa 5 sao.'),
  comment: z
    .string()
    .min(10, 'Nhận xét phải có ít nhất 10 ký tự.')
    .max(500, 'Nhận xét không được vượt quá 500 ký tự.'),
});

// Product validation schema (Admin)
export const productSchema = z.object({
  nameProduct: z.string().min(1, 'Vui lòng nhập tên sản phẩm.'),
  price: z.array(z.string()).min(1, 'Vui lòng nhập giá.'),
  sizes: z.array(z.string()).min(1, 'Vui lòng nhập kích thước.'),
  note: z.string().min(1, 'Vui lòng nhập mô tả.'),
  imageUrl: z.string().url('URL hình ảnh không hợp lệ.').optional(),
});
