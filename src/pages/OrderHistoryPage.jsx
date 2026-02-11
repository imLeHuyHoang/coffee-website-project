// OrderHistoryPage - View user's order history
import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import useOrders from '../hooks/useOrders';
import { formatDateTime, formatNumberToPrice } from '../utils/formatters';
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

  return (
    <div className="order-history-page">
      <div className="page-header">
        <h1>Lịch sử đơn hàng</h1>
        <p className="page-subtitle">Xem lại các đơn hàng bạn đã đặt</p>
      </div>

      {loading && <LoadingSpinner message="Đang tải đơn hàng..." />}
      {error && <div className="error-box">Lỗi: {error}</div>}

      {!loading && !error && orders.length === 0 && (
        <div className="no-orders">
          <div className="no-orders-icon">📦</div>
          <h2>Chưa có đơn hàng nào</h2>
          <p>Bạn chưa đặt đơn hàng nào. Hãy khám phá các sản phẩm của chúng tôi!</p>
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
                <div className="order-info">
                  <h3 className="order-number">
                    <span className="order-icon">🧾</span>
                    Đơn hàng #{order.orderId.slice(0, 8).toUpperCase()}
                  </h3>
                  <p className="order-date">
                    <span className="date-icon">📅</span>
                    {formatDateTime(order.createdAt)}
                  </p>
                </div>
              </div>

              <div className="order-body">
                <div className="order-section">
                  <h4 className="section-title">Sản phẩm đã đặt</h4>
                  <div className="order-items">
                    {order.items
                      .filter((item) => item.variants.some((v) => v.quantity > 0))
                      .map((item, idx) => (
                        <div key={idx} className="order-item">
                          <div className="item-header">
                            <h5 className="item-name">{item.nameProduct}</h5>
                          </div>
                          <div className="item-variants">
                            {item.variants
                              .filter((v) => v.quantity > 0)
                              .map((variant, vIdx) => (
                                <div key={vIdx} className="variant-row">
                                  <span className="variant-size">{variant.size}</span>
                                  <span className="variant-quantity">x{variant.quantity}</span>
                                  <span className="variant-price">{variant.price}</span>
                                </div>
                              ))}
                          </div>
                        </div>
                      ))}
                  </div>
                </div>

                <div className="order-section">
                  <h4 className="section-title">Thông tin giao hàng</h4>
                  <div className="customer-info">
                    <div className="info-row">
                      <span className="info-icon">👤</span>
                      <span className="info-label">Người nhận:</span>
                      <span className="info-value">{order.customerInfo.name}</span>
                    </div>
                    <div className="info-row">
                      <span className="info-icon">📍</span>
                      <span className="info-label">Địa chỉ:</span>
                      <span className="info-value">{order.customerInfo.address}</span>
                    </div>
                    <div className="info-row">
                      <span className="info-icon">📞</span>
                      <span className="info-label">Số điện thoại:</span>
                      <span className="info-value">{order.customerInfo.phone}</span>
                    </div>
                  </div>
                </div>
              </div>

              <div className="order-footer">
                <div className="order-summary">
                  <div className="summary-row">
                    <span>Tổng số lượng:</span>
                    <strong>{order.totalQuantity} sản phẩm</strong>
                  </div>
                  <div className="summary-row total">
                    <span>Tổng tiền:</span>
                    <strong className="total-amount">{formatNumberToPrice(order.totalPrice)}</strong>
                  </div>
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
