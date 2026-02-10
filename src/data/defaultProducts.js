// ==============================================================================
// Default Products - Fallback data khi backend chua san sang
// ==============================================================================
// Du lieu nay duoc su dung khi:
//   1. API Gateway / Lambda chua deploy (dang develop local)
//   2. DynamoDB chua co data (chua seed products)
//   3. Network error
//
// Khi backend san sang, useProducts hook se tu dong fetch tu API
// va thay the DEFAULT_PRODUCTS voi du lieu thuc te.
// ==============================================================================

import anh1 from '../assets/anh1.webp';
import anh2 from '../assets/anh2.webp';
import anh3 from '../assets/anh3.webp';
import anh4 from '../assets/anh4.webp';

export const DEFAULT_PRODUCTS = [
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

export default DEFAULT_PRODUCTS;
