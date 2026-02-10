// ProductList Component
import React from 'react';
import ProductCard from './ProductCard';
import './ProductList.css';

const ProductList = ({ products }) => {
  if (!products || products.length === 0) {
    return (
      <div className="product-list-empty">
        <p>Không có sản phẩm nào.</p>
      </div>
    );
  }

  return (
    <div className="product-list">
      {products.map((product, index) => (
        <ProductCard
          key={product.productId || index}
          product={product}
          productIndex={index}
        />
      ))}
    </div>
  );
};

export default ProductList;
