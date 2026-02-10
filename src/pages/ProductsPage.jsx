// ProductsPage - Display all products
import React from 'react';
import useProducts from '../hooks/useProducts';
import ProductList from '../components/product/ProductList';
import LoadingSpinner from '../components/common/LoadingSpinner';
import './ProductsPage.css';

// Import default product images for fallback
import anh1 from '../assets/anh1.webp';
import anh2 from '../assets/anh2.webp';
import anh3 from '../assets/anh3.webp';
import anh4 from '../assets/anh4.webp';

const DEFAULT_PRODUCTS = [
  {
    productId: '1',
    nameProduct: 'Default Route',
    price: ['300.000 VND', '450.000 VND'],
    imageUrl: anh1,
    Image: anh1,
    sizes: ['8OZ', '12OZ'],
    Size: ['8OZ', '12OZ'],
    note: '100% Natural notes of Berries, Chocolate, & Caramel! Scoring 85+.',
    Note: '100% Natural notes of Berries, Chocolate, & Caramel! Scoring 85+.',
  },
  {
    productId: '2',
    nameProduct: 'On-call',
    price: ['300.000 VND', '450.000 VND'],
    imageUrl: anh2,
    Image: anh2,
    sizes: ['8OZ', '12OZ'],
    Size: ['8OZ', '12OZ'],
    note: '100% Natural notes Cocoa, Cherry, and Maple Syrup! Scoring 85+.',
    Note: '100% Natural notes Cocoa, Cherry, and Maple Syrup! Scoring 85+.',
  },
  {
    productId: '3',
    nameProduct: '200 OK',
    price: ['300.000 VND', '450.000 VND'],
    imageUrl: anh3,
    Image: anh3,
    sizes: ['8OZ', '12OZ'],
    Size: ['8OZ', '12OZ'],
    note: 'Caramlized Honey, Chocolate, brown sugar - an excellent morning cup.',
    Note: 'Caramlized Honey, Chocolate, brown sugar - an excellent morning cup.',
  },
  {
    productId: '4',
    nameProduct: 'Sudo',
    price: ['300.000 VND', '450.000 VND'],
    imageUrl: anh4,
    Image: anh4,
    sizes: ['8OZ', '12OZ'],
    Size: ['8OZ', '12OZ'],
    note: 'Bright notes of peach, honey, with a juicy acidity.',
    Note: 'Bright notes of peach, honey, with a juicy acidity.',
  },
];

const ProductsPage = () => {
  const { products: fetchedProducts, loading, error } = useProducts();

  const products = fetchedProducts.length > 0 ? fetchedProducts : DEFAULT_PRODUCTS;

  return (
    <div className="products-page">
      <div className="products-page-header">
        <h1>Tất cả sản phẩm</h1>
        <p>Khám phá bộ sưu tập cà phê chất lượng cao của chúng tôi</p>
      </div>

      {loading && <LoadingSpinner message="Đang tải sản phẩm..." />}
      {error && <div className="error-box">Lỗi: {error}</div>}
      {!loading && !error && <ProductList products={products} />}
    </div>
  );
};

export default ProductsPage;
