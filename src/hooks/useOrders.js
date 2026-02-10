// Custom Hook: useOrders
import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import orderService from '../services/orderService';

export const useOrders = () => {
  const { user, token, isLoggedIn } = useAuth();
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchOrders = async () => {
    if (!isLoggedIn() || !user || !token) {
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const data = await orderService.getOrdersByUserId(user.userId, token);
      setOrders(data);
    } catch (err) {
      setError(err.message);
      console.error('Error fetching orders:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders();
  }, [user, token]);

  const refetch = () => {
    fetchOrders();
  };

  const getOrderById = async (orderId) => {
    try {
      return await orderService.getOrderById(orderId, token);
    } catch (err) {
      console.error('Error fetching order:', err);
      throw err;
    }
  };

  return { orders, loading, error, refetch, getOrderById };
};

export default useOrders;
