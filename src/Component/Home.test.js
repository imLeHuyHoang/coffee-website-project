// src/Component/Home.test.js
import { getTotalPrice, getTotalQuantity } from "./Home";

describe("getTotalPrice function", () => {
  it("should calculate the total price for a single item with multiple quantities", () => {
    global.cart = [
      {
        quantities: [2, 1],
      },
    ];

    global.arrCoffee = [
      {
        price: ["300.000 VND", "450.000 VND"],
      },
    ];

    const totalPrice = getTotalPrice();

    const expected = 1050000;
    expect(totalPrice).toBe(expected);
  });

  it("should calculate the total price for a single item with different quantities", () => {
    global.cart = [
      {
        quantities: [1, 3],
      },
    ];

    global.arrCoffee = [
      {
        price: ["300.000 VND", "450.000 VND"],
      },
    ];

    const totalPrice = getTotalPrice();

    const expected = 300000 * 1 + 450000 * 3;
    expect(totalPrice).toBe(expected);
  });

  it("should return 0 when all quantities are 0", () => {
    global.cart = [
      {
        quantities: [0, 0],
      },
    ];

    global.arrCoffee = [
      {
        price: ["300.000 VND", "450.000 VND"],
      },
    ];

    const totalPrice = getTotalPrice();

    const expected = 0;
    expect(totalPrice).toBe(expected);
  });

  it("should calculate the total price for multiple items with different quantities", () => {
    global.cart = [
      {
        quantities: [1, 1],
      },
      {
        quantities: [1, 3],
      },
    ];

    global.arrCoffee = [
      { price: ["300.000 VND", "450.000 VND"] }, // arrCoffee[0]
      { price: ["300.000 VND", "450.000 VND"] }, // arrCoffee[1]
    ];

    const totalPrice = getTotalPrice();

    const expected = 2 * 300000 + 450000 * 4;
    expect(totalPrice).toBe(expected);
  });

  it("should calculate the total price for multiple items including items with zero quantities", () => {
    global.cart = [
      {
        quantities: [1, 1],
      },
      {
        quantities: [1, 3],
      },
      {
        quantities: [0, 0],
      },
    ];

    global.arrCoffee = [
      { price: ["300.000 VND", "450.000 VND"] },
      { price: ["300.000 VND", "450.000 VND"] },
      { price: ["300.000 VND", "450.000 VND"] },
    ];

    const totalPrice = getTotalPrice();

    const expected = 2 * 300000 + 450000 * 4 + 0 * 300000 + 0 * 450000;
    expect(totalPrice).toBe(expected);
  });
});

describe("getTotalQuantity function", () => {
  it("should return 0 when the cart is empty", () => {
    global.cart = [];
    const result = getTotalQuantity();
    expect(result).toBe(0);
  });

  it("should calculate the total quantity for a single item", () => {
    global.cart = [
      {
        quantities: [2, 1], // total quantity = 3
      },
    ];
    const result = getTotalQuantity();
    expect(result).toBe(3);
  });

  it("should calculate the total quantity for multiple items", () => {
    global.cart = [
      {
        quantities: [1, 1], // 2
      },
      {
        quantities: [2, 3], // 5
      },
    ];
    const result = getTotalQuantity();
    expect(result).toBe(7); // 2 + 5 = 7
  });

  it("should return 0 when all quantities are 0", () => {
    global.cart = [
      {
        quantities: [0, 0],
      },
      {
        quantities: [0, 0],
      },
    ];
    const result = getTotalQuantity();
    expect(result).toBe(0);
  });

  it("should calculate the total quantity for multiple items including items with zero quantities", () => {
    global.cart = [
      {
        quantities: [1, 1], // 2
      },
      {
        quantities: [2, 3], // 5
      },
      {
        quantities: [0, 0], // 0
      },
    ];
    const result = getTotalQuantity();
    expect(result).toBe(7); // 2 + 5 = 7
  });
});
