// Auth Context - Manage authentication state
import React, { createContext, useState, useEffect, useContext } from 'react';
import authService from '../services/authService';
import { User } from '../models/User';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Load user from localStorage on mount
  useEffect(() => {
    const savedToken = authService.getToken();
    const savedUser = authService.getUser();
    
    if (savedToken && savedUser) {
      setToken(savedToken);
      setUser(savedUser);
    }
    
    setLoading(false);
  }, []);

  // Register new user
  const register = async (userData) => {
    try {
      setLoading(true);
      setError(null);
      
      const { user: newUser, token: newToken } = await authService.register(userData);
      
      authService.saveToken(newToken);
      authService.saveUser(newUser);
      
      setUser(newUser);
      setToken(newToken);
      
      return { success: true, user: newUser };
    } catch (err) {
      setError(err.message);
      return { success: false, error: err.message };
    } finally {
      setLoading(false);
    }
  };

  // Login user
  const login = async (email, password) => {
    try {
      setLoading(true);
      setError(null);
      
      const { user: loggedUser, token: newToken } = await authService.login(email, password);
      
      authService.saveToken(newToken);
      authService.saveUser(loggedUser);
      
      setUser(loggedUser);
      setToken(newToken);
      
      return { success: true, user: loggedUser };
    } catch (err) {
      setError(err.message);
      return { success: false, error: err.message };
    } finally {
      setLoading(false);
    }
  };

  // Logout user
  const logout = () => {
    authService.logout();
    setUser(null);
    setToken(null);
    setError(null);
  };

  // Update user profile
  const updateProfile = async (updates) => {
    try {
      setLoading(true);
      setError(null);
      
      const updatedUser = await authService.updateProfile(updates, token);
      
      authService.saveUser(updatedUser);
      setUser(updatedUser);
      
      return { success: true, user: updatedUser };
    } catch (err) {
      setError(err.message);
      return { success: false, error: err.message };
    } finally {
      setLoading(false);
    }
  };

  // Check if user is logged in
  const isLoggedIn = () => {
    return !!user && !!token;
  };

  // Check if user is admin
  const isAdmin = () => {
    return user && user.isAdmin();
  };

  const value = {
    user,
    token,
    loading,
    error,
    register,
    login,
    logout,
    updateProfile,
    isLoggedIn,
    isAdmin,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

// Custom hook to use auth context
export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};

export default AuthContext;
