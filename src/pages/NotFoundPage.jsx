// NotFoundPage - 404 Error page
import React from 'react';
import { useNavigate } from 'react-router-dom';
import './NotFoundPage.css';

const NotFoundPage = () => {
  const navigate = useNavigate();

  return (
    <div className="not-found-page">
      <div className="not-found-container">
        <h1 className="not-found-title">404</h1>
        <h2 className="not-found-subtitle">Không tìm thấy trang</h2>
        <p className="not-found-message">
          Xin lỗi, trang bạn đang tìm kiếm không tồn tại.
        </p>
        <div className="not-found-actions">
          <button onClick={() => navigate('/')} className="btn-home">
            Về trang chủ
          </button>
          <button onClick={() => navigate(-1)} className="btn-back">
            Quay lại
          </button>
        </div>
      </div>
    </div>
  );
};

export default NotFoundPage;
