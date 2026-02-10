// User Model
import { generateId } from '../utils/formatters';
import { USER_ROLES } from '../utils/constants';

export class User {
  constructor(data = {}) {
    this.userId = data.userId || generateId();
    this.email = data.email || '';
    this.name = data.name || '';
    this.phone = data.phone || '';
    this.address = data.address || '';
    this.role = data.role || USER_ROLES.CUSTOMER;
    this.createdAt = data.createdAt || Date.now();
    this.updatedAt = data.updatedAt || Date.now();
  }

  // Convert to API format (without sensitive data)
  toJSON() {
    return {
      userId: this.userId,
      email: this.email,
      name: this.name,
      phone: this.phone,
      address: this.address,
      role: this.role,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
    };
  }

  // Create from API response
  static fromAPI(data) {
    return new User(data);
  }

  // Check if user is admin
  isAdmin() {
    return this.role === USER_ROLES.ADMIN;
  }

  // Validate user data
  isValid() {
    return this.email && this.name && this.phone;
  }

  // Get display name
  getDisplayName() {
    return this.name || this.email;
  }
}

export default User;
