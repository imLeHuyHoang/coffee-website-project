// Navbar Advertisement Component
import React, { useState, useEffect } from 'react';
import { ADVERTISEMENT_MESSAGES } from '../../utils/constants';
import './Navbar.css';

const Navbar = () => {
  const [currentIndex, setCurrentIndex] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentIndex((prevIndex) => (prevIndex + 1) % ADVERTISEMENT_MESSAGES.length);
    }, 5000);
    return () => clearInterval(interval);
  }, []);

  const handlePrevClick = () => {
    setCurrentIndex((prevIndex) =>
      prevIndex === 0 ? ADVERTISEMENT_MESSAGES.length - 1 : prevIndex - 1
    );
  };

  const handleNextClick = () => {
    setCurrentIndex((prevIndex) => (prevIndex + 1) % ADVERTISEMENT_MESSAGES.length);
  };

  return (
    <div className="navbar-advertising">
      <button className="navbar-button" onClick={handlePrevClick} aria-label="Previous">
        ◀
      </button>
      <div className="navbar-message">{ADVERTISEMENT_MESSAGES[currentIndex]}</div>
      <button className="navbar-button" onClick={handleNextClick} aria-label="Next">
        ▶
      </button>
    </div>
  );
};

export default Navbar;
