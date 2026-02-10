import React from "react";
import "./App.css";
import { AuthProvider } from "./context/AuthContext";
import { CartProvider } from "./context/CartContext";
import Routing from "./Routing";

function App() {
  return (
    <AuthProvider>
      <CartProvider>
        <div className="App">
          <Routing />
        </div>
      </CartProvider>
    </AuthProvider>
  );
}

export default App;
