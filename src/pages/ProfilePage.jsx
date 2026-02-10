// ProfilePage - User profile management
import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import './ProfilePage.css';

const ProfilePage = () => {
  const navigate = useNavigate();
  const { user, isLoggedIn, updateProfile, logout } = useAuth();

  const [isEditing, setIsEditing] = useState(false);
  const [formData, setFormData] = useState({
    name: user?.name || '',
    phone: user?.phone || '',
    address: user?.address || '',
  });
  const [errors, setErrors] = useState([]);
  const [loading, setLoading] = useState(false);

  // Redirect if not logged in
  if (!isLoggedIn()) {
    navigate('/login');
    return null;
  }

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setErrors([]);

    setLoading(true);
    const response = await updateProfile(formData);
    setLoading(false);

    if (response.success) {
      setIsEditing(false);
      alert('Cập nhật thông tin thành công!');
    } else {
      setErrors([response.error]);
    }
  };

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  return (
    <div className="profile-page">
      <div className="profile-container">
        <h1>Thông tin tài khoản</h1>

        {errors.length > 0 && (
          <div className="profile-errors">
            {errors.map((error, idx) => (
              <div key={idx}>{error}</div>
            ))}
          </div>
        )}

        {!isEditing ? (
          <div className="profile-view">
            <div className="profile-field">
              <label>Email:</label>
              <span>{user?.email}</span>
            </div>
            <div className="profile-field">
              <label>Họ và tên:</label>
              <span>{user?.name}</span>
            </div>
            <div className="profile-field">
              <label>Số điện thoại:</label>
              <span>{user?.phone}</span>
            </div>
            <div className="profile-field">
              <label>Địa chỉ:</label>
              <span>{user?.address || 'Chưa cập nhật'}</span>
            </div>
            <div className="profile-field">
              <label>Vai trò:</label>
              <span className="user-role">{user?.role === 'admin' ? 'Quản trị viên' : 'Khách hàng'}</span>
            </div>

            <div className="profile-actions">
              <button onClick={() => setIsEditing(true)} className="btn-edit">
                Chỉnh sửa
              </button>
              <button onClick={handleLogout} className="btn-logout">
                Đăng xuất
              </button>
            </div>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="profile-form">
            <div className="form-group">
              <label>Email (không thể thay đổi):</label>
              <input type="email" value={user?.email} disabled />
            </div>

            <div className="form-group">
              <label htmlFor="name">Họ và tên:</label>
              <input
                type="text"
                id="name"
                name="name"
                value={formData.name}
                onChange={handleChange}
                required
              />
            </div>

            <div className="form-group">
              <label htmlFor="phone">Số điện thoại:</label>
              <input
                type="tel"
                id="phone"
                name="phone"
                value={formData.phone}
                onChange={handleChange}
                required
              />
            </div>

            <div className="form-group">
              <label htmlFor="address">Địa chỉ:</label>
              <input
                type="text"
                id="address"
                name="address"
                value={formData.address}
                onChange={handleChange}
              />
            </div>

            <div className="form-actions">
              <button type="submit" className="btn-save" disabled={loading}>
                {loading ? 'Đang lưu...' : 'Lưu thay đổi'}
              </button>
              <button
                type="button"
                onClick={() => setIsEditing(false)}
                className="btn-cancel"
              >
                Hủy
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
};

export default ProfilePage;
