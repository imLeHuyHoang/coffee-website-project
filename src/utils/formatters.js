// Utility functions for formatting

/**
 * Format price string to number
 * @param {string} priceString - "300.000 VND"
 * @returns {number} - 300000
 */
export const parsePriceToNumber = (priceString) => {
  if (!priceString) return 0;
  return Number(priceString.replace(' VND', '').replace(/\./g, ''));
};

/**
 * Format number to price string
 * @param {number} price - 300000
 * @returns {string} - "300.000 VND"
 */
export const formatNumberToPrice = (price) => {
  if (!price) return '0 VND';
  return `${price.toLocaleString('vi-VN')} VND`;
};

/**
 * Format date to Vietnamese format
 * @param {Date|string|number} date
 * @returns {string} - "10/02/2026"
 */
export const formatDate = (date) => {
  const d = new Date(date);
  const day = String(d.getDate()).padStart(2, '0');
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const year = d.getFullYear();
  return `${day}/${month}/${year}`;
};

/**
 * Format date to Vietnamese datetime format
 * @param {Date|string|number} date
 * @returns {string} - "10/02/2026 14:30"
 */
export const formatDateTime = (date) => {
  const d = new Date(date);
  const day = String(d.getDate()).padStart(2, '0');
  const month = String(d.getMonth() + 1).padStart(2, '0');
  const year = d.getFullYear();
  const hours = String(d.getHours()).padStart(2, '0');
  const minutes = String(d.getMinutes()).padStart(2, '0');
  return `${day}/${month}/${year} ${hours}:${minutes}`;
};

/**
 * Truncate text to specified length
 * @param {string} text
 * @param {number} maxLength
 * @returns {string}
 */
export const truncateText = (text, maxLength = 100) => {
  if (!text || text.length <= maxLength) return text;
  return `${text.substring(0, maxLength)}...`;
};

/**
 * Generate unique ID
 * @returns {string}
 */
export const generateId = () => {
  return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
};
