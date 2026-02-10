// Custom Hook: useReviews
import { useState, useEffect } from 'react';
import reviewService from '../services/reviewService';

export const useReviews = (productId) => {
  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [averageRating, setAverageRating] = useState(0);
  const [ratingDistribution, setRatingDistribution] = useState({});

  const fetchReviews = async () => {
    if (!productId) {
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const data = await reviewService.getReviewsByProductId(productId);
      setReviews(data);
      
      // Calculate average rating and distribution
      const avgRating = reviewService.calculateAverageRating(data);
      const distribution = reviewService.getRatingDistribution(data);
      
      setAverageRating(avgRating);
      setRatingDistribution(distribution);
    } catch (err) {
      setError(err.message);
      console.error('Error fetching reviews:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchReviews();
  }, [productId]);

  const refetch = () => {
    fetchReviews();
  };

  return {
    reviews,
    loading,
    error,
    averageRating,
    ratingDistribution,
    refetch,
  };
};

export default useReviews;
