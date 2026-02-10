// OrderHistoryPage - View user's order history
import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import useOrders from '../hooks/useOrders';
import { formatDateTime, formatNumberToPrice } from '../utils/formatters';
import { ORDER_STATUS_LABELS } from '../utils/constants';
import LoadingSpinner from '../components/common/LoadingSpinner';
import './OrderHistoryPage.css';

const OrderHistoryPage = () => {
  const navigate = useNavigate();
  const { isLoggedIn } = useAuth();
  const { orders, loading, error } = useOrders();

  // Redirect if not logged in
  if (!isLoggedIn()) {
    navigate('/login');
    return null;
  }

  const getStatusClass = (status) => {
    const statusClasses = {
      pending: 'status-pending',
      processing: 'status-processing',
      shipped: 'status-shipped',
      delivered: 'status-delivered',
      cancelled: 'status-cancelled',
    };
    return statusClasses[status] || '';
  };

  return (
    <div className="order-history-page">
      <h1>Lịch sử đơn hàng</h1>

      {loading && <LoadingSpinner message="Đang tải đơn hàng..." />}
      {error && <div className="error-box">Lỗi: {error}</div>}

      {!loading && !error && orders.length === 0 && (
        <div className="no-orders">
          <p>Bạn chưa có đơn hàng nào.</p>
          <button onClick={() => navigate('/products')} className="btn-shop-now">
            Mua sắm ngay
          </button>
        </div>
      )}

      {!loading && !error && orders.length > 0 && (
        <div className="orders-list">
          {orders.map((order) => (
            <div key={order.orderId} className="order-card">
              <div className="order-header">
                <div>
                  <h3>Đơn hàng #{order.orderId.slice(0, 8)}</h3>
                  <p className="order-date">{formatDateTime(order.createdAt)}</p>
                </div>
                <span className={`order-status ${getStatusClass(order.status)}`}>
                  {ORDER_STATUS_LABELS[order.status]}
                </span>
              </div>

              <div className="order-items">
                {order.items.map((item, idx) => (
                  <div key={idx} className="order-item">
                    <strong>{item.nameProduct}</strong>
                    <div className="order-item-variants">
                      {item.variants
                        .filter((v) => v.quantity > 0)
                        .map((variant, vIdx) => (
                          <span key={vIdx}>
                            {variant.size}: {variant.quantity} x {variant.price}
                          </span>
                        ))}
                    </div>
                  </div>
                ))}
              </div>

              <div className="order-footer">
                <div className="order-customer">
                  <p>
                    <strong>Người nhận:</strong> {order.customerInfo.name}
                  </p>
                  <p>
                    <strong>Địa chỉ:</strong> {order.customerInfo.address}
                  </p>
                  <p>
                    <strong>SĐT:</strong> {order.customerInfo.phone}
                  </p>
                </div>
                <div className="order-total">
                  <p>Tổng số lượng: <strong>{order.totalQuantity}</strong></p>
                  <p className="total-price">
                    Tổng tiền: <strong>{formatNumberToPrice(order.totalPrice)}</strong>
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default OrderHistoryPage;
