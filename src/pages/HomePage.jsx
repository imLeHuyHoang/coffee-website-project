// HomePage - Refactored version
import React, { useRef, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useCart } from '../context/CartContext';
import Navbar from '../components/common/Navbar';
import ProductList from '../components/product/ProductList';
import { DEFAULT_PRODUCTS } from '../data/defaultProducts';
import './HomePage.css';

const HomePage = () => {
  const navigate = useNavigate();
  const productListRef = useRef(null);
  const { initializeCart } = useCart();

  // Use default products
  const products = DEFAULT_PRODUCTS;

  // Initialize cart when products load
  useEffect(() => {
    if (products.length > 0) {
      initializeCart(products);
    }
  }, [products, initializeCart]);

  const handleShopCoffeeClick = () => {
    if (productListRef.current) {
      productListRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  };

  const handleOrderNowClick = () => {
    navigate('/cart');
  };

  return (
    <>
      <Navbar />

      {/* Banner Section */}
      <section className="banner-section">
        <div className="banner">
          <h1 className="banner-title">COFFEE, RIGHT NOW</h1>
          <p className="banner-subtitle">
            Thưởng thức cà phê chất lượng cao được chọn lọc kỹ càng
          </p>
          <button className="btn-banner" onClick={handleShopCoffeeClick}>
            KHÁM PHÁ NGAY
          </button>
        </div>
      </section>

      {/* Products Section */}
      <section ref={productListRef} className="products-section">
        <div className="section-header">
          <h2>Sản phẩm của chúng tôi</h2>
          <p>Chọn từ những sản phẩm cà phê tuyệt vời nhất</p>
        </div>

        <ProductList products={products} />
      </section>

      {/* Call to Action Section */}
      <section className="cta-section">
        <div className="cta-content">
          <h2>Sẵn sàng đặt hàng?</h2>
          <p>Thêm sản phẩm vào giỏ hàng và hoàn tất đơn hàng của bạn</p>
          <button className="btn-cta" onClick={handleOrderNowClick}>
            ĐẶT HÀNG NGAY
          </button>
        </div>
      </section>
    </>
  );
};

export default HomePage;
