const API_CONFIG = {
  BASE_URL: import.meta.env.VITE_API_BASE_URL,
  ENDPOINTS: {
    // Orders
    ORDERS: '/orders',
    ORDER_BY_ID: (id) => `/orders/${id}`,
    
    // Auth
    LOGIN: '/auth/login',
    REGISTER: '/auth/register',
    PROFILE: '/auth/profile',
  },
  TIMEOUT: 30000, // 30 seconds
};

export default API_CONFIG;
