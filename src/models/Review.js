// Review Model
import { generateId } from '../utils/formatters';

export class Review {
  constructor(data = {}) {
    this.reviewId = data.reviewId || generateId();
    this.productId = data.productId || '';
    this.userId = data.userId || '';
    this.userName = data.userName || 'Anonymous';
    this.rating = data.rating || 0; // 1-5 stars
    this.comment = data.comment || '';
    this.images = data.images || []; // Array of image URLs
    this.createdAt = data.createdAt || Date.now();
    this.updatedAt = data.updatedAt || Date.now();
  }

  // Convert to API format
  toJSON() {
    return {
      reviewId: this.reviewId,
      productId: this.productId,
      userId: this.userId,
      userName: this.userName,
      rating: this.rating,
      comment: this.comment,
      images: this.images,
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
    };
  }

  // Create from API response
  static fromAPI(data) {
    return new Review(data);
  }

  // Validate review data
  isValid() {
    return (
      this.productId &&
      this.rating >= 1 &&
      this.rating <= 5 &&
      this.comment &&
      this.comment.length >= 10
    );
  }

  // Get star display
  getStarDisplay() {
    return '⭐'.repeat(this.rating);
  }
}

export default Review;
