// Review Service - Handle review-related API calls
import API_CONFIG from '../config/api.config';
import { Review } from '../models/Review';

class ReviewService {
  /**
   * Create new review
   * @param {Review} review
   * @param {string} token - Auth token
   * @returns {Promise<Review>}
   */
  async createReview(review, token) {
    try {
      const response = await fetch(`${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.REVIEWS}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(review.toJSON()),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.message || `HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      return Review.fromAPI(data.review);
    } catch (error) {
      console.error('Error creating review:', error);
      throw error;
    }
  }

  /**
   * Get reviews by product ID
   * @param {string} productId
   * @returns {Promise<Review[]>}
   */
  async getReviewsByProductId(productId) {
    try {
      const response = await fetch(
        `${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.REVIEWS_BY_PRODUCT(productId)}`,
        {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
          },
        }
      );

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      return (data.reviews || []).map((item) => Review.fromAPI(item));
    } catch (error) {
      console.error('Error fetching reviews:', error);
      throw error;
    }
  }

  /**
   * Calculate average rating for a product
   * @param {Review[]} reviews
   * @returns {number}
   */
  calculateAverageRating(reviews) {
    if (!reviews || reviews.length === 0) return 0;
    const sum = reviews.reduce((acc, review) => acc + review.rating, 0);
    return (sum / reviews.length).toFixed(1);
  }

  /**
   * Get rating distribution
   * @param {Review[]} reviews
   * @returns {Object} - { 5: count, 4: count, 3: count, 2: count, 1: count }
   */
  getRatingDistribution(reviews) {
    const distribution = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
    
    reviews.forEach((review) => {
      if (review.rating >= 1 && review.rating <= 5) {
        distribution[review.rating]++;
      }
    });

    return distribution;
  }
}

export default new ReviewService();
