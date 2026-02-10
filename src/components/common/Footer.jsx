// Footer Component
import React from 'react';
import './Footer.css';

const Footer = () => {
  return (
    <footer className="footer">
      <div className="footer-container">
        <div className="footer-section">
          <h3>☕ Coffee Shop</h3>
          <p>Cà phê chất lượng cao từ những hạt cà phê được chọn lọc kỹ càng.</p>
        </div>

        <div className="footer-section">
          <h4>Liên kết</h4>
          <ul>
            <li><a href="/">Trang chủ</a></li>
            <li><a href="/products">Sản phẩm</a></li>
            <li><a href="/about">Về chúng tôi</a></li>
            <li><a href="/contact">Liên hệ</a></li>
          </ul>
        </div>

        <div className="footer-section">
          <h4>Liên hệ</h4>
          <p>Email: lehuyhoang1352002@gmail.com</p>
          <p>Hotline: 0123-456-789</p>
          <p>Địa chỉ: Hà Nội, Việt Nam</p>
        </div>

        <div className="footer-section">
          <h4>Theo dõi chúng tôi</h4>
          <div className="social-links">
            <a href="#" aria-label="Facebook">📘 Facebook</a>
            <a href="#" aria-label="Instagram">📷 Instagram</a>
            <a href="https://github.com/imLeHuyHoang" target="_blank" rel="noopener noreferrer">
              💻 GitHub
            </a>
          </div>
        </div>
      </div>

      <div className="footer-bottom">
        <p>&copy; 2026 Coffee Shop. Created by imLeHuyHoang. All rights reserved.</p>
      </div>
    </footer>
  );
};

export default Footer;
