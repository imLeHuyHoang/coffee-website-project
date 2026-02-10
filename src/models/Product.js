// Product Model
import { generateId } from '../utils/formatters';

export class Product {
  constructor(data = {}) {
    this.productId = data.productId || generateId();
    this.nameProduct = data.nameProduct || '';
    this.price = data.price || []; // Array of price strings
    this.sizes = data.sizes || data.Size || []; // Array of size strings
    this.note = data.note || data.Note || '';
    this.imageUrl = data.imageUrl || data.Image || '';
    this.createdAt = data.createdAt || Date.now();
    this.updatedAt = data.updatedAt || Date.now();
  }

  // Convert to API format
  toJSON() {
    return {
      productId: this.productId,
      nameProduct: this.nameProduct,
      price: this.price,
      sizes: this.sizes,
      note: this.note,
      imageUrl: this.imageUrl,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
    };
  }

  // Create from API response
  static fromAPI(data) {
    return new Product(data);
  }

  // Validate product data
  isValid() {
    return (
      this.nameProduct &&
      this.price.length > 0 &&
      this.sizes.length > 0 &&
      this.note
    );
  }
}

export default Product;
