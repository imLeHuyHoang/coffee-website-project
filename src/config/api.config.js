// API Configuration
const API_CONFIG = {
  BASE_URL: 'https://wn7pg9kwgi.execute-api.ap-southeast-1.amazonaws.com/prod',
  ENDPOINTS: {
    // Orders
    ORDERS: '/orders',
    ORDER_BY_ID: (id) => `/orders/${id}`,
    
    // Products
    PRODUCTS: '/products',
    PRODUCT_BY_ID: (id) => `/products/${id}`,
    
    // Reviews
    REVIEWS: '/reviews',
    REVIEWS_BY_PRODUCT: (productId) => `/reviews?productId=${productId}`,
    
    // Auth
    LOGIN: '/auth/login',
    REGISTER: '/auth/register',
    PROFILE: '/auth/profile',
  },
  TIMEOUT: 30000, // 30 seconds
};

export default API_CONFIG;
