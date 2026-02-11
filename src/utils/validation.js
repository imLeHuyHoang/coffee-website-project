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
