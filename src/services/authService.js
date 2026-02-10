// Auth Service - Handle authentication-related API calls
import API_CONFIG from '../config/api.config';
import { User } from '../models/User';

class AuthService {
  /**
   * Register new user
   * @param {Object} userData - { email, password, name, phone }
   * @returns {Promise<{user: User, token: string}>}
   */
  async register(userData) {
    try {
      const response = await fetch(`${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.REGISTER}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(userData),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.message || 'Đăng ký thất bại');
      }

      const data = await response.json();
      return {
        user: User.fromAPI(data.user),
        token: data.token,
      };
    } catch (error) {
      console.error('Error registering user:', error);
      throw error;
    }
  }

  /**
   * Login user
   * @param {string} email
   * @param {string} password
   * @returns {Promise<{user: User, token: string}>}
   */
  async login(email, password) {
    try {
      const response = await fetch(`${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.LOGIN}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.message || 'Đăng nhập thất bại');
      }

      const data = await response.json();
      return {
        user: User.fromAPI(data.user),
        token: data.token,
      };
    } catch (error) {
      console.error('Error logging in:', error);
      throw error;
    }
  }

  /**
   * Get user profile
   * @param {string} token - Auth token
   * @returns {Promise<User>}
   */
  async getProfile(token) {
    try {
      const response = await fetch(`${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.PROFILE}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      return User.fromAPI(data.user);
    } catch (error) {
      console.error('Error fetching profile:', error);
      throw error;
    }
  }

  /**
   * Update user profile
   * @param {Object} updates
   * @param {string} token - Auth token
   * @returns {Promise<User>}
   */
  async updateProfile(updates, token) {
    try {
      const response = await fetch(`${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.PROFILE}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(updates),
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      return User.fromAPI(data.user);
    } catch (error) {
      console.error('Error updating profile:', error);
      throw error;
    }
  }

  /**
   * Save token to localStorage
   * @param {string} token
   */
  saveToken(token) {
    localStorage.setItem('authToken', token);
  }

  /**
   * Get token from localStorage
   * @returns {string|null}
   */
  getToken() {
    return localStorage.getItem('authToken');
  }

  /**
   * Remove token from localStorage
   */
  removeToken() {
    localStorage.removeItem('authToken');
  }

  /**
   * Save user to localStorage
   * @param {User} user
   */
  saveUser(user) {
    localStorage.setItem('user', JSON.stringify(user.toJSON()));
  }

  /**
   * Get user from localStorage
   * @returns {User|null}
   */
  getUser() {
    const userData = localStorage.getItem('user');
    return userData ? User.fromAPI(JSON.parse(userData)) : null;
  }

  /**
   * Remove user from localStorage
   */
  removeUser() {
    localStorage.removeItem('user');
  }

  /**
   * Logout user (clear local storage)
   */
  logout() {
    this.removeToken();
    this.removeUser();
  }

  /**
   * Check if user is logged in
   * @returns {boolean}
   */
  isLoggedIn() {
    return !!this.getToken();
  }
}

export default new AuthService();
