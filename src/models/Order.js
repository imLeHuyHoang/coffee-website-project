// Order Model
import { generateId } from '../utils/formatters';
import { ORDER_STATUS } from '../utils/constants';

export class Order {
  constructor(data = {}) {
    this.orderId = data.orderId || generateId();
    this.userId = data.userId || null;
    this.customerInfo = data.customerInfo || {
      name: '',
      address: '',
      phone: '',
      email: '',
    };
    this.items = data.items || []; // Array of order items
    this.totalPrice = data.totalPrice || 0;
    this.totalQuantity = data.totalQuantity || 0;
    this.status = data.status || ORDER_STATUS.PENDING;
    this.createdAt = data.createdAt || Date.now();
    this.updatedAt = data.updatedAt || Date.now();
  }

  // Convert to API format
  toJSON() {
    return {
      orderId: this.orderId,
      userId: this.userId,
      customerInfo: this.customerInfo,
      items: this.items,
      totalPrice: this.totalPrice,
      totalQuantity: this.totalQuantity,
      status: this.status,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
    };
  }

  // Create from API response
  static fromAPI(data) {
    return new Order(data);
  }

  // Calculate total price from items
  calculateTotal() {
    this.totalPrice = this.items.reduce((sum, item) => {
      const itemTotal = item.variants.reduce((itemSum, variant) => {
        const priceNum = typeof variant.price === 'string'
          ? Number(variant.price.replace(' VND', '').replace(/\./g, ''))
          : variant.price;
        return itemSum + (priceNum * variant.quantity);
      }, 0);
      return sum + itemTotal;
    }, 0);
    return this.totalPrice;
  }

  // Calculate total quantity from items
  calculateQuantity() {
    this.totalQuantity = this.items.reduce((sum, item) => {
      const itemQty = item.variants.reduce(
        (itemSum, variant) => itemSum + variant.quantity,
        0
      );
      return sum + itemQty;
    }, 0);
    return this.totalQuantity;
  }

  // Validate order data
  isValid() {
    return (
      this.customerInfo.name &&
      this.customerInfo.address &&
      this.customerInfo.phone &&
      this.items.length > 0 &&
      this.totalQuantity > 0
    );
  }
}

export default Order;
