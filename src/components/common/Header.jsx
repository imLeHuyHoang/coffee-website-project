// Header Component
import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { useCart } from '../../context/CartContext';
import './Header.css';

const Header = () => {
  const { user, isLoggedIn, logout } = useAuth();
  const { getTotalQuantity } = useCart();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  return (
    <header className="header">
      <div className="header-container">
        <Link to="/" className="header-logo">
          <h1>☕ Coffee Shop</h1>
        </Link>

        <nav className="header-nav">
          <Link to="/" className="nav-link">Trang chủ</Link>
          <Link to="/products" className="nav-link">Sản phẩm</Link>
          
          {isLoggedIn() && (
            <>
              <Link to="/orders" className="nav-link">Đơn hàng</Link>
              <Link to="/profile" className="nav-link">Tài khoản</Link>
            </>
          )}

          <Link to="/cart" className="nav-link cart-link">
            🛒 Giỏ hàng
            {getTotalQuantity() > 0 && (
              <span className="cart-badge">{getTotalQuantity()}</span>
            )}
          </Link>

          {!isLoggedIn() ? (
            <>
              <Link to="/login" className="nav-link btn-login">Đăng nhập</Link>
              <Link to="/register" className="nav-link btn-register">Đăng ký</Link>
            </>
          ) : (
            <>
              <span className="user-greeting">Xin chào, {user?.name}!</span>
              <button onClick={handleLogout} className="btn-logout">
                Đăng xuất
              </button>
            </>
          )}
        </nav>
      </div>
    </header>
  );
};

export default Header;
