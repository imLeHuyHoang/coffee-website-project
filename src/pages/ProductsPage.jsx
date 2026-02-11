// ProductsPage - Display all products
import React from 'react';
import ProductList from '../components/product/ProductList';
import { DEFAULT_PRODUCTS } from '../data/defaultProducts';
import './ProductsPage.css';

const ProductsPage = () => {
  const products = DEFAULT_PRODUCTS;

  return (
    <div className="products-page">
      <div className="products-page-header">
        <h1>Tất cả sản phẩm</h1>
        <p>Khám phá bộ sưu tập cà phê chất lượng cao của chúng tôi</p>
      </div>

      <ProductList products={products} />
    </div>
  );
};

export default ProductsPage;
