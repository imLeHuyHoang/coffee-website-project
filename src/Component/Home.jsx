// src/Component/Home.jsx
import React, { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import Confetti from "react-confetti";
import { z } from "zod";

import anh1 from "../assets/anh1.webp";
import anh2 from "../assets/anh2.webp";
import anh3 from "../assets/anh3.webp";
import anh4 from "../assets/anh4.webp";

import "./Home.css";

// ======================
// Mảng coffee để app sử dụng
// ======================
export const arrCoffee = [
  {
    nameProduct: "Default Route",
    price: ["300.000 VND", "450.000 VND"],
    Image: anh1,
    Size: ["8OZ", "12OZ"],
    Note: "100% Natural notes of Berries, Chocolate, & Caramel! Scoring 85+.",
  },
  {
    nameProduct: "On-call",
    price: ["300.000 VND", "450.000 VND"],
    Image: anh2,
    Size: ["8OZ", "12OZ"],
    Note: "100% Natural notes Cocoa, Cherry, and Maple Syrup! Scoring 85+.",
  },
  {
    nameProduct: "200 OK",
    price: ["300.000 VND", "450.000 VND"],
    Image: anh3,
    Size: ["8OZ", "12OZ"],
    Note: "Caramlized Honey, Chocolate, brown sugar - an excellent morning cup.",
  },
  {
    nameProduct: "Sudo",
    price: ["300.000 VND", "450.000 VND"],
    Image: anh4,
    Size: ["8OZ", "12OZ"],
    Note: "Bright notes of peach, honey, with a juicy acidity.",
  },
];

/**
 * Hàm tính tổng tiền.
 * - Nếu được gọi bên trong app: ta truyền (cart, arrCoffee).
 * - Nếu được test cũ gọi mà KHÔNG truyền gì => fallback sang global.cart, global.arrCoffee.
 */
export function getTotalPrice(cart, coffeeList) {
  // Fallback cho TEST cũ
  const localCart = cart || global.cart;
  const localCoffeeList = coffeeList || global.arrCoffee;

  if (!Array.isArray(localCart) || !Array.isArray(localCoffeeList)) {
    return 0;
  }

  let total = 0;
  localCart.forEach((cartItem, indexProduct) => {
    if (!localCoffeeList[indexProduct]) return;
    cartItem.quantities.forEach((qty, sizeIdx) => {
      const priceString = localCoffeeList[indexProduct].price[sizeIdx];
      // "300.000 VND" => "300000"
      const priceNumber = Number(
        priceString.replace(" VND", "").replace(/\./g, "")
      );
      total += priceNumber * qty;
    });
  });
  return total;
}

/**
 * Hàm tính tổng số lượng.
 * - Nếu được gọi bên trong app: ta truyền (cart).
 * - Nếu được test cũ gọi không truyền => fallback sang global.cart.
 */
export function getTotalQuantity(cart) {
  // Fallback cho TEST cũ
  const localCart = cart || global.cart;

  if (!Array.isArray(localCart)) {
    return 0;
  }

  let totalQty = 0;
  localCart.forEach((cartItem) => {
    if (cartItem.quantities && Array.isArray(cartItem.quantities)) {
      cartItem.quantities.forEach((qty) => {
        totalQty += qty;
      });
    }
  });
  return totalQty;
}

// Schema dùng Zod để validate form
const orderSchema = z.object({
  name: z.string().min(1, "Vui lòng nhập tên người nhận."),
  address: z.string().min(1, "Vui lòng nhập địa chỉ."),
  phone: z
    .string()
    .min(1, "Vui lòng nhập số điện thoại.")
    .regex(/^[0-9]{10,11}$/, "Số điện thoại không hợp lệ."),
});

const arrAdvertising = [
  "Shop now before it's too late :)",
  "Free shipping on orders above 500.000 VND",
  "New collection coming soon!",
  "Get a free coffee on your birthday!",
];

// Card hiển thị từng sản phẩm
function ProductCard({ coffee }) {
  const [isOpen, setIsOpen] = useState(false);
  const toggleDetails = () => setIsOpen(!isOpen);

  return (
    <div className="ProductList_card" onClick={toggleDetails}>
      <div className="ProductContent">
        <img
          className="ProductList_card-image"
          src={coffee.Image}
          alt="product"
        />
        <h2>{coffee.nameProduct}</h2>
        <p className="Price">
          {coffee.price[0]} / {coffee.price[1]}
        </p>
      </div>
      {isOpen && (
        <div
          className="ProductDetails open"
          onClick={(e) => e.stopPropagation()}
        >
          <p>
            <strong>Size:</strong> {coffee.Size.join(" / ")}
          </p>
          <p>
            <strong>Note:</strong> {coffee.Note}
          </p>
        </div>
      )}
    </div>
  );
}

// Component chính Home
function Home() {
  const navigate = useNavigate();
  const productListRef = useRef(null);

  // State
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isOrderFormOpen, setIsOrderFormOpen] = useState(false);
  const [isConfirmModalOpen, setIsConfirmModalOpen] = useState(false);

  const [orderSuccess, setOrderSuccess] = useState(false);
  const [showConfetti, setShowConfetti] = useState(false);

  // Giỏ hàng: mỗi sản phẩm có mảng quantities cho từng size
  const [cart, setCart] = useState(
    arrCoffee.map(() => ({ quantities: [0, 0] }))
  );

  // Thông tin người nhận
  const [customerInfo, setCustomerInfo] = useState({
    name: "",
    address: "",
    phone: "",
  });

  const [formErrors, setFormErrors] = useState([]);

  // Hiệu ứng carousel quảng cáo
  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentIndex((prevIndex) => (prevIndex + 1) % arrAdvertising.length);
    }, 5000);
    return () => clearInterval(interval);
  }, []);

  // Hiệu ứng Confetti khi orderSuccess
  useEffect(() => {
    if (orderSuccess) {
      setShowConfetti(true);
      const timer = setTimeout(() => {
        setShowConfetti(false);
        navigate("/");
      }, 3000);
      return () => clearTimeout(timer);
    }
  }, [orderSuccess, navigate]);

  // Tính tổng tiền & số lượng
  // (gọi hàm, nhưng LẦN NÀY ta truyền cart và arrCoffee để chạy bình thường)
  const totalPrice = getTotalPrice(cart, arrCoffee);
  const totalQty = getTotalQuantity(cart);

  // Xử lý nút prev/next
  const handlePrevClick = () => {
    setCurrentIndex((prevIndex) =>
      prevIndex === 0 ? arrAdvertising.length - 1 : prevIndex - 1
    );
  };
  const handleNextClick = () => {
    setCurrentIndex((prevIndex) => (prevIndex + 1) % arrAdvertising.length);
  };

  // Scroll tới danh sách sp
  const handleShopCoffeeClick = () => {
    if (productListRef.current) {
      productListRef.current.scrollIntoView({ behavior: "smooth" });
    }
  };

  // Mở form đặt hàng
  const handleOrderNowClick = () => {
    setIsOrderFormOpen(true);
    setOrderSuccess(false);
  };

  // Tăng/giảm số lượng
  const handleIncrement = (productIndex, sizeIndex) => {
    const newCart = [...cart];
    newCart[productIndex].quantities[sizeIndex]++;
    setCart(newCart);
  };
  const handleDecrement = (productIndex, sizeIndex) => {
    const newCart = [...cart];
    if (newCart[productIndex].quantities[sizeIndex] > 0) {
      newCart[productIndex].quantities[sizeIndex]--;
    }
    setCart(newCart);
  };

  // Thay đổi thông tin khách hàng
  const handleCustomerInfoChange = (e) => {
    const { name, value } = e.target;
    setCustomerInfo((prev) => ({ ...prev, [name]: value }));
  };

  // Trước khi gọi API => kiểm tra form + số lượng
  const handleConfirmOrder = () => {
    const result = orderSchema.safeParse(customerInfo);

    if (!result.success) {
      const zodErrors = result.error.errors.map((err) => err.message);
      setFormErrors(zodErrors);
      return;
    } else if (totalQty === 0) {
      setFormErrors(["Bạn chưa chọn sản phẩm nào."]);
      return;
    }

    setFormErrors([]);
    setIsConfirmModalOpen(true);
  };

  // Gửi đơn hàng tới API Gateway
  const submitOrderToAPI = async () => {
    const orderPayload = {
      customerInfo,
      items: cart.map((cartItem, index) => {
        const coffee = arrCoffee[index];
        return {
          nameProduct: coffee.nameProduct,
          variants: coffee.Size.map((sz, sizeIdx) => ({
            size: sz,
            quantity: cartItem.quantities[sizeIdx],
            price: coffee.price[sizeIdx],
          })),
        };
      }),
      totalPrice,
    };

    try {
      const response = await fetch(
        "https://wn7pg9kwgi.execute-api.ap-southeast-1.amazonaws.com/prod/orders",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(orderPayload),
        }
      );

      const data = await response.json();
      console.log("Response from API: ", data);

      // Lưu thành công => hiển thị confetti
      setOrderSuccess(true);

      // Reset cart & form
      setCart(arrCoffee.map(() => ({ quantities: [0, 0] })));
      setCustomerInfo({ name: "", address: "", phone: "" });
    } catch (error) {
      console.error("Error saving order:", error);
      alert("Có lỗi xảy ra khi gửi đơn hàng. Vui lòng thử lại sau.");
    }
  };

  // Người dùng đồng ý => gửi API
  const handleFinalConfirm = () => {
    setIsConfirmModalOpen(false);
    setIsOrderFormOpen(false);
    submitOrderToAPI();
  };

  // Người dùng huỷ => đóng modal
  const handleCancelConfirm = () => {
    setIsConfirmModalOpen(false);
  };

  return (
    <>
      {showConfetti && <Confetti />}

      {/* Section 1: Navbar quảng cáo */}
      <section>
        <div className="Navbar">
          <button className="Navbar_button" onClick={handlePrevClick}>
            <i className="fas fa-chevron-left"> </i>
          </button>
          <div className="Navbar_advertising">
            {arrAdvertising[currentIndex]}
          </div>
          <button className="Navbar_button" onClick={handleNextClick}>
            <i className="fas fa-chevron-right"> </i>
          </button>
        </div>
      </section>

      {/* Section 2: Banner */}
      <section>
        <div className="Banner">
          <h1 className="Banner_title">COFFEE, RIGHT NOW</h1>
          <button onClick={handleShopCoffeeClick}>SHOP COFFEE</button>
        </div>
      </section>

      {/* Section 3: Danh sách sp */}
      <section ref={productListRef}>
        <div className="ProductList">
          {arrCoffee.map((coffee) => (
            <ProductCard key={coffee.nameProduct} coffee={coffee} />
          ))}
        </div>
      </section>

      {/* Section 4: Nút Order */}
      <section>
        <div className="Order">
          <button onClick={handleOrderNowClick}>Order Now</button>
        </div>
      </section>

      {/* Thông báo đặt hàng thành công */}
      {orderSuccess && (
        <div className="OrderSuccessModal">
          <p>Đơn hàng của bạn đã được đặt thành công!</p>
        </div>
      )}

      {/* Form đặt hàng */}
      {isOrderFormOpen && (
        <div className="OrderFormOverlay">
          <div className="OrderForm">
            <h2>Đặt hàng</h2>

            {/* Hiển thị lỗi (nếu có) */}
            {formErrors.length > 0 && (
              <div style={{ color: "red", marginBottom: "10px" }}>
                {formErrors.map((err, idx) => (
                  <div key={idx}>{err}</div>
                ))}
              </div>
            )}

            <div className="OrderFormContainer">
              {/* Cột trái */}
              <div className="OrderFormLeft">
                {arrCoffee.map((coffee, productIndex) => (
                  <div key={coffee.nameProduct} className="OrderFormProduct">
                    <img src={coffee.Image} alt={coffee.nameProduct} />
                    <div className="OrderFormProductDetails">
                      <h3>{coffee.nameProduct}</h3>
                      {coffee.Size.map((size, sizeIndex) => (
                        <div key={sizeIndex} className="OrderFormSizeRow">
                          <span>
                            {size} - {coffee.price[sizeIndex]}
                          </span>
                          <div className="QuantityButtons">
                            <button
                              onClick={() =>
                                handleDecrement(productIndex, sizeIndex)
                              }
                            >
                              -
                            </button>
                            <span>
                              {cart[productIndex].quantities[sizeIndex]}
                            </span>
                            <button
                              onClick={() =>
                                handleIncrement(productIndex, sizeIndex)
                              }
                            >
                              +
                            </button>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>

              {/* Cột phải */}
              <div className="OrderFormRight">
                <h3>Tổng quan</h3>
                <p>
                  Tổng số lượng: <strong>{totalQty}</strong>
                </p>
                <p>
                  Tổng tiền: <strong>{totalPrice.toLocaleString()} VND</strong>
                </p>

                <h3>Thông tin người nhận</h3>
                <div className="CustomerInfo">
                  <label>
                    Tên người nhận:
                    <input
                      type="text"
                      name="name"
                      value={customerInfo.name}
                      onChange={handleCustomerInfoChange}
                    />
                  </label>
                  <label>
                    Địa chỉ:
                    <input
                      type="text"
                      name="address"
                      value={customerInfo.address}
                      onChange={handleCustomerInfoChange}
                    />
                  </label>
                  <label>
                    Số điện thoại:
                    <input
                      type="text"
                      name="phone"
                      value={customerInfo.phone}
                      onChange={handleCustomerInfoChange}
                    />
                  </label>
                </div>

                <div className="OrderFormButtons">
                  <button onClick={handleConfirmOrder}>
                    Xác nhận đặt hàng
                  </button>
                  <button onClick={() => setIsOrderFormOpen(false)}>
                    Đóng
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Modal confirm */}
      {isConfirmModalOpen && (
        <div className="ConfirmModalOverlay">
          <div className="ConfirmModal">
            <p>Bạn có chắc chắn với đơn hàng này không?</p>
            <div className="ConfirmModalButtons">
              <button onClick={handleFinalConfirm}>Đồng ý</button>
              <button onClick={handleCancelConfirm}>Hủy</button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

export default Home;
