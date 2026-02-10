// ProductsPage - Display all products
import React from 'react';
import useProducts from '../hooks/useProducts';
import ProductList from '../components/product/ProductList';
import LoadingSpinner from '../components/common/LoadingSpinner';
import { DEFAULT_PRODUCTS } from '../data/defaultProducts';
import './ProductsPage.css';

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
