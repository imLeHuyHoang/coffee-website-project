// CartPage - Shopping cart page
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useCart } from '../context/CartContext';
import { useAuth } from '../context/AuthContext';
import { orderSchema } from '../utils/validation';
import { formatNumberToPrice } from '../utils/formatters';
import orderService from '../services/orderService';
import { Order } from '../models/Order';
import { DEFAULT_PRODUCTS } from '../data/defaultProducts';
import Confetti from 'react-confetti';
import './CartPage.css';

const CartPage = () => {
  const navigate = useNavigate();
  const { user, isLoggedIn } = useAuth();
  const { cart, getTotalQuantity, getTotalPrice, addToCart, removeFromCart, clearCart } = useCart();

  const products = DEFAULT_PRODUCTS;

  const [customerInfo, setCustomerInfo] = useState({
    name: user?.name || '',
    address: user?.address || '',
    phone: user?.phone || '',
    email: user?.email || '',
  });
  const [errors, setErrors] = useState([]);
  const [showConfetti, setShowConfetti] = useState(false);
  const [orderSuccess, setOrderSuccess] = useState(false);
  const [loading, setLoading] = useState(false);

  const totalQuantity = getTotalQuantity();
  const totalPrice = getTotalPrice(products);

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setCustomerInfo((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmitOrder = async () => {
    setErrors([]);

    // Check if user is logged in
    if (!isLoggedIn()) {
      const confirmLogin = window.confirm(
        'Bạn cần đăng nhập để đặt hàng. Bạn có muốn chuyển đến trang đăng nhập không?'
      );
      if (confirmLogin) {
        navigate('/login');
      }
      return;
    }

    // Validate customer info
    const validationData = {
      name: customerInfo.name,
      address: customerInfo.address,
      phone: customerInfo.phone,
    };
    const result = orderSchema.safeParse(validationData);

    if (!result.success) {
      const zodErrors = result.error.errors.map((err) => err.message);
      setErrors(zodErrors);
      return;
    }

    if (totalQuantity === 0) {
      setErrors(['Giỏ hàng trống. Vui lòng thêm sản phẩm trước khi đặt hàng.']);
      return;
    }

    // Create order object
    const orderItems = cart
      .map((cartItem, productIndex) => {
        const product = products[productIndex];
        if (!product) return null;

        return {
          nameProduct: product.nameProduct,
          productId: product.productId,
          variants: product.sizes.map((size, sizeIndex) => ({
            size,
            quantity: cartItem.quantities[sizeIndex],
            price: product.price[sizeIndex],
          })),
        };
      })
      .filter((item) => item !== null);

    const order = new Order({
      userId: user?.userId || null,
      customerInfo,
      items: orderItems,
      totalPrice,
      totalQuantity,
    });

    order.calculateTotal();
    order.calculateQuantity();

    // Submit order
    try {
      setLoading(true);
      await orderService.createOrder(order);
      
      // Success
      setOrderSuccess(true);
      setShowConfetti(true);
      clearCart();

      setTimeout(() => {
        setShowConfetti(false);
        if (isLoggedIn()) {
          navigate('/orders');
        } else {
          navigate('/');
        }
      }, 3000);
    } catch (error) {
      setErrors([error.message || 'Có lỗi xảy ra khi đặt hàng. Vui lòng thử lại.']);
    } finally {
      setLoading(false);
    }
  };

  if (orderSuccess) {
    return (
      <>
        {showConfetti && <Confetti />}
        <div className="order-success-page">
          <div className="success-icon">✅</div>
          <h1>Đặt hàng thành công!</h1>
          <p>Cảm ơn bạn đã đặt hàng. Chúng tôi sẽ xử lý đơn hàng của bạn sớm nhất.</p>
        </div>
      </>
    );
  }

  return (
    <div className="cart-page">
      <h1 className="cart-title">Giỏ hàng của bạn</h1>

      {totalQuantity === 0 ? (
        <div className="cart-empty">
          <p>Giỏ hàng trống</p>
          <button onClick={() => navigate('/products')} className="btn-continue-shopping">
            Tiếp tục mua sắm
          </button>
        </div>
      ) : (
        <div className="cart-container">
          {/* Left: Cart items */}
          <div className="cart-items">
            <h2>Sản phẩm</h2>
            {cart.map((cartItem, productIndex) => {
              const product = products[productIndex];
              if (!product) return null;

              const hasItems = cartItem.quantities.some((qty) => qty > 0);
              if (!hasItems) return null;

              return (
                <div key={productIndex} className="cart-item">
                  <img src={product.imageUrl || product.Image} alt={product.nameProduct} />
                  <div className="cart-item-details">
                    <h3>{product.nameProduct}</h3>
                    {cartItem.quantities.map((qty, sizeIndex) => {
                      if (qty === 0) return null;
                      return (
                        <div key={sizeIndex} className="cart-item-variant">
                          <span>
                            {product.sizes[sizeIndex]} - {product.price[sizeIndex]}
                          </span>
                          <div className="quantity-controls">
                            <button onClick={() => removeFromCart(productIndex, sizeIndex)}>
                              -
                            </button>
                            <span>{qty}</span>
                            <button onClick={() => addToCart(productIndex, sizeIndex)}>
                              +
                            </button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              );
            })}
          </div>

          {/* Right: Order summary */}
          <div className="cart-summary">
            <h2>Tóm tắt đơn hàng</h2>
            <div className="summary-row">
              <span>Tổng số lượng:</span>
              <strong>{totalQuantity}</strong>
            </div>
            <div className="summary-row">
              <span>Tổng tiền:</span>
              <strong className="total-price">{formatNumberToPrice(totalPrice)}</strong>
            </div>

            <h3>Thông tin nhận hàng</h3>
            {errors.length > 0 && (
              <div className="form-errors">
                {errors.map((error, idx) => (
                  <div key={idx}>{error}</div>
                ))}
              </div>
            )}

            <div className="customer-form">
              <input
                type="text"
                name="name"
                placeholder="Họ và tên"
                value={customerInfo.name}
                onChange={handleInputChange}
              />
              <input
                type="text"
                name="address"
                placeholder="Địa chỉ giao hàng"
                value={customerInfo.address}
                onChange={handleInputChange}
              />
              <input
                type="tel"
                name="phone"
                placeholder="Số điện thoại"
                value={customerInfo.phone}
                onChange={handleInputChange}
              />
              <input
                type="email"
                name="email"
                placeholder="Email (không bắt buộc)"
                value={customerInfo.email}
                onChange={handleInputChange}
              />
            </div>

            <button
              onClick={handleSubmitOrder}
              className="btn-checkout"
              disabled={loading}
            >
              {loading ? 'Đang xử lý...' : 'Đặt hàng'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default CartPage;
