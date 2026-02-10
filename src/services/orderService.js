// Order Service - Handle order-related API calls
import API_CONFIG from '../config/api.config';
import { Order } from '../models/Order';

class OrderService {
  /**
   * Create new order
   * @param {Order} order
   * @returns {Promise<Order>}
   */
  async createOrder(order) {
    try {
      const response = await fetch(`${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.ORDERS}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(order.toJSON()),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.message || `HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      return Order.fromAPI(data.order || data);
    } catch (error) {
      console.error('Error creating order:', error);
      throw error;
    }
  }

  /**
   * Get orders by user ID
   * @param {string} userId
   * @param {string} token - Auth token
   * @returns {Promise<Order[]>}
   */
  async getOrdersByUserId(userId, token) {
    try {
      const response = await fetch(
        `${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.ORDERS}?userId=${userId}`,
        {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
        }
      );

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      return (data.orders || []).map((item) => Order.fromAPI(item));
    } catch (error) {
      console.error('Error fetching orders:', error);
      throw error;
    }
  }

  /**
   * Get order by ID
   * @param {string} orderId
   * @param {string} token - Auth token
   * @returns {Promise<Order>}
   */
  async getOrderById(orderId, token) {
    try {
      const response = await fetch(
        `${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.ORDER_BY_ID(orderId)}`,
        {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
        }
      );

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      return Order.fromAPI(data.order);
    } catch (error) {
      console.error('Error fetching order:', error);
      throw error;
    }
  }

  /**
   * Get all orders (Admin only)
   * @param {string} token - Auth token
   * @returns {Promise<Order[]>}
   */
  async getAllOrders(token) {
    try {
      const response = await fetch(`${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.ORDERS}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      return (data.orders || []).map((item) => Order.fromAPI(item));
    } catch (error) {
      console.error('Error fetching all orders:', error);
      throw error;
    }
  }

  /**
   * Update order status (Admin only)
   * @param {string} orderId
   * @param {string} status
   * @param {string} token - Auth token
   * @returns {Promise<Order>}
   */
  async updateOrderStatus(orderId, status, token) {
    try {
      const response = await fetch(
        `${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.ORDER_BY_ID(orderId)}`,
        {
          method: 'PUT',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({ status }),
        }
      );

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      return Order.fromAPI(data.order);
    } catch (error) {
      console.error('Error updating order status:', error);
      throw error;
    }
  }
}

export default new OrderService();
