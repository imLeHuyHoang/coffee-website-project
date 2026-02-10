// Cart Context - Manage shopping cart state
import React, { createContext, useState, useEffect, useContext } from 'react';
import { parsePriceToNumber } from '../utils/formatters';

const CartContext = createContext(null);

export const CartProvider = ({ children }) => {
  // Initialize cart from localStorage or empty array
  const [cart, setCart] = useState(() => {
    const savedCart = localStorage.getItem('cart');
    return savedCart ? JSON.parse(savedCart) : [];
  });

  // Save cart to localStorage whenever it changes
  useEffect(() => {
    localStorage.setItem('cart', JSON.stringify(cart));
  }, [cart]);

  /**
   * Initialize cart for products
   * @param {Array} products - Array of product objects
   */
  const initializeCart = (products) => {
    if (cart.length === 0 && products.length > 0) {
      const initialCart = products.map(() => ({ quantities: [0, 0] }));
      setCart(initialCart);
    }
  };

  /**
   * Add item to cart (increment quantity)
   * @param {number} productIndex
   * @param {number} sizeIndex
   */
  const addToCart = (productIndex, sizeIndex) => {
    const newCart = [...cart];
    if (!newCart[productIndex]) {
      newCart[productIndex] = { quantities: [0, 0] };
    }
    newCart[productIndex].quantities[sizeIndex]++;
    setCart(newCart);
  };

  /**
   * Remove item from cart (decrement quantity)
   * @param {number} productIndex
   * @param {number} sizeIndex
   */
  const removeFromCart = (productIndex, sizeIndex) => {
    const newCart = [...cart];
    if (newCart[productIndex] && newCart[productIndex].quantities[sizeIndex] > 0) {
      newCart[productIndex].quantities[sizeIndex]--;
    }
    setCart(newCart);
  };

  /**
   * Update quantity directly
   * @param {number} productIndex
   * @param {number} sizeIndex
   * @param {number} quantity
   */
  const updateQuantity = (productIndex, sizeIndex, quantity) => {
    const newCart = [...cart];
    if (!newCart[productIndex]) {
      newCart[productIndex] = { quantities: [0, 0] };
    }
    newCart[productIndex].quantities[sizeIndex] = Math.max(0, quantity);
    setCart(newCart);
  };

  /**
   * Clear entire cart
   */
  const clearCart = () => {
    setCart([]);
    localStorage.removeItem('cart');
  };

  /**
   * Get total quantity in cart
   * @returns {number}
   */
  const getTotalQuantity = () => {
    return cart.reduce((total, item) => {
      if (item.quantities && Array.isArray(item.quantities)) {
        return total + item.quantities.reduce((sum, qty) => sum + qty, 0);
      }
      return total;
    }, 0);
  };

  /**
   * Get total price in cart
   * @param {Array} products - Array of product objects with price info
   * @returns {number}
   */
  const getTotalPrice = (products) => {
    if (!products || products.length === 0) return 0;

    return cart.reduce((total, cartItem, productIndex) => {
      const product = products[productIndex];
      if (!product || !cartItem.quantities) return total;

      const itemTotal = cartItem.quantities.reduce((sum, qty, sizeIndex) => {
        const price = product.price[sizeIndex];
        const priceNumber = parsePriceToNumber(price);
        return sum + priceNumber * qty;
      }, 0);

      return total + itemTotal;
    }, 0);
  };

  /**
   * Check if cart is empty
   * @returns {boolean}
   */
  const isCartEmpty = () => {
    return getTotalQuantity() === 0;
  };

  /**
   * Get cart item count for specific product
   * @param {number} productIndex
   * @returns {number}
   */
  const getProductQuantity = (productIndex) => {
    if (!cart[productIndex] || !cart[productIndex].quantities) return 0;
    return cart[productIndex].quantities.reduce((sum, qty) => sum + qty, 0);
  };

  const value = {
    cart,
    initializeCart,
    addToCart,
    removeFromCart,
    updateQuantity,
    clearCart,
    getTotalQuantity,
    getTotalPrice,
    isCartEmpty,
    getProductQuantity,
  };

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
};

// Custom hook to use cart context
export const useCart = () => {
  const context = useContext(CartContext);
  if (!context) {
    throw new Error('useCart must be used within CartProvider');
  }
  return context;
};

export default CartContext;
