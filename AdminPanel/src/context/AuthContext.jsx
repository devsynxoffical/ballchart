import React, { createContext, useContext, useState, useEffect } from 'react';
import api from '../services/api';

const AuthContext = createContext();

export const useAuth = () => useContext(AuthContext);

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const token = localStorage.getItem('adminToken');
        if (token) {
            // You might want to validate the token here or fetch user details
            // For now, we'll assume if token exists, we are logged in, 
            // but ideally we should hit /api/auth/me
            // Let's keep it simple for now and rely on login setting the user
            const userData = localStorage.getItem('adminUser');
            if (userData) setUser(JSON.parse(userData));
        }
        setLoading(false);
    }, []);

    const login = async (email, password) => {
        try {
            const response = await api.post('/auth/admin/login', { email, password });
            const { token, ...userData } = response.data;

            localStorage.setItem('adminToken', token);
            localStorage.setItem('adminUser', JSON.stringify(userData));
            setUser(userData);
            return { success: true };
        } catch (error) {
            console.error("Login failed", error);
            return {
                success: false,
                message: error.response?.data?.message || 'Login failed'
            };
        }
    };

    const logout = () => {
        localStorage.removeItem('adminToken');
        localStorage.removeItem('adminUser');
        setUser(null);
    };

    return (
        <AuthContext.Provider value={{ user, login, logout, loading }}>
            {!loading && children}
        </AuthContext.Provider>
    );
};
