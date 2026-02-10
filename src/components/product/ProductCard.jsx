// ProductCard Component
import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { useCart } from '../../context/CartContext';
import './ProductCard.css';

const ProductCard = ({ product, productIndex }) => {
  const [isOpen, setIsOpen] = useState(false);
  const { addToCart, getProductQuantity } = useCart();

  const toggleDetails = () => setIsOpen(!isOpen);

  const handleQuickAdd = (sizeIndex, e) => {
    e.stopPropagation();
    e.preventDefault();
    addToCart(productIndex, sizeIndex);
  };

  const quantity = getProductQuantity(productIndex);

  return (
    <div className="product-card" onClick={toggleDetails}>
      <div className="product-card-image-container">
        <img
          className="product-card-image"
          src={product.imageUrl || product.Image}
          alt={product.nameProduct}
        />
        {quantity > 0 && (
          <div className="product-card-badge">{quantity}</div>
        )}
      </div>

      <div className="product-card-content">
        <h3 className="product-card-title">{product.nameProduct}</h3>
        <p className="product-card-price">
          {product.price[0]} / {product.price[1]}
        </p>

        {isOpen && (
          <div
            className="product-card-details"
            onClick={(e) => e.stopPropagation()}
          >
            <p className="product-card-note">
              <strong>Mô tả:</strong> {product.note || product.Note}
            </p>
            <p className="product-card-sizes">
              <strong>Kích thước:</strong> {(product.sizes || product.Size).join(' / ')}
            </p>

            <div className="product-card-actions">
              {product.sizes.map((size, sizeIndex) => (
                <button
                  key={sizeIndex}
                  onClick={(e) => handleQuickAdd(sizeIndex, e)}
                  className="btn-quick-add"
                >
                  + {size}
                </button>
              ))}
              <Link
                to={`/products/${product.productId}`}
                className="btn-view-detail"
                onClick={(e) => e.stopPropagation()}
              >
                Xem chi tiết
              </Link>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default ProductCard;
