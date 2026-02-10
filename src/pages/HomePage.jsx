// HomePage - Refactored version
import React, { useRef, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useCart } from '../context/CartContext';
import useProducts from '../hooks/useProducts';
import Navbar from '../components/common/Navbar';
import ProductList from '../components/product/ProductList';
import LoadingSpinner from '../components/common/LoadingSpinner';
import './HomePage.css';

// Import default product images
import anh1 from '../assets/anh1.webp';
import anh2 from '../assets/anh2.webp';
import anh3 from '../assets/anh3.webp';
import anh4 from '../assets/anh4.webp';

// Default products fallback (khi backend chưa sẵn sàng)
const DEFAULT_PRODUCTS = [
  {
    productId: '1',
    nameProduct: 'Default Route',
    price: ['300.000 VND', '450.000 VND'],
    Image: anh1,
    imageUrl: anh1,
    Size: ['8OZ', '12OZ'],
    sizes: ['8OZ', '12OZ'],
    Note: '100% Natural notes of Berries, Chocolate, & Caramel! Scoring 85+.',
    note: '100% Natural notes of Berries, Chocolate, & Caramel! Scoring 85+.',
  },
  {
    productId: '2',
    nameProduct: 'On-call',
    price: ['300.000 VND', '450.000 VND'],
    Image: anh2,
    imageUrl: anh2,
    Size: ['8OZ', '12OZ'],
    sizes: ['8OZ', '12OZ'],
    Note: '100% Natural notes Cocoa, Cherry, and Maple Syrup! Scoring 85+.',
    note: '100% Natural notes Cocoa, Cherry, and Maple Syrup! Scoring 85+.',
  },
  {
    productId: '3',
    nameProduct: '200 OK',
    price: ['300.000 VND', '450.000 VND'],
    Image: anh3,
    imageUrl: anh3,
    Size: ['8OZ', '12OZ'],
    sizes: ['8OZ', '12OZ'],
    Note: 'Caramlized Honey, Chocolate, brown sugar - an excellent morning cup.',
    note: 'Caramlized Honey, Chocolate, brown sugar - an excellent morning cup.',
  },
  {
    productId: '4',
    nameProduct: 'Sudo',
    price: ['300.000 VND', '450.000 VND'],
    Image: anh4,
    imageUrl: anh4,
    Size: ['8OZ', '12OZ'],
    sizes: ['8OZ', '12OZ'],
    Note: 'Bright notes of peach, honey, with a juicy acidity.',
    note: 'Bright notes of peach, honey, with a juicy acidity.',
  },
];

const HomePage = () => {
  const navigate = useNavigate();
  const productListRef = useRef(null);
  const { products: fetchedProducts, loading, error } = useProducts();
  const { initializeCart } = useCart();

  // Use fetched products or fallback to default
  const products = fetchedProducts.length > 0 ? fetchedProducts : DEFAULT_PRODUCTS;

  // Initialize cart when products load
  useEffect(() => {
    if (products.length > 0) {
      initializeCart(products);
    }
  }, [products]);

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
            Thưởng thức cà phê chất lượng cao từ những hạt được chọn lọc kỹ càng
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

        {loading && <LoadingSpinner message="Đang tải sản phẩm..." />}
        {error && <div className="error-box">Lỗi: {error}</div>}
        {!loading && !error && <ProductList products={products} />}
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
