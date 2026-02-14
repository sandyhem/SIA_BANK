import { authApi } from './api';

export const authService = {
    // Register new user
    register: async (userData) => {
        const response = await authApi.post('/auth/register', {
            username: userData.username,
            email: userData.email,
            password: userData.password,
            firstName: userData.firstName,
            lastName: userData.lastName,
            phone: userData.phone || ''
        });
        if (response.data.token) {
            localStorage.setItem('authToken', response.data.token);
            const userProfile = {
                id: response.data.userId,
                username: response.data.username,
                email: response.data.email,
                firstName: response.data.firstName,
                lastName: response.data.lastName,
                phone: response.data.phone
            };
            localStorage.setItem('userProfile', JSON.stringify(userProfile));
        }
        return response.data;
    },

    // Login user
    login: async (credentials) => {
        const response = await authApi.post('/auth/login', {
            username: credentials.username,
            password: credentials.password
        });
        if (response.data.token) {
            localStorage.setItem('authToken', response.data.token);
            const userProfile = {
                id: response.data.userId,
                username: response.data.username,
                email: response.data.email || '',
                firstName: response.data.firstName || '',
                lastName: response.data.lastName || '',
                phone: response.data.phone || ''
            };
            localStorage.setItem('userProfile', JSON.stringify(userProfile));
        }
        return response.data;
    },

    // Logout user
    logout: () => {
        localStorage.removeItem('authToken');
        localStorage.removeItem('userProfile');
        localStorage.removeItem('customerProfile');
    },

    // Get current user profile
    getCurrentUser: () => {
        const userProfile = localStorage.getItem('userProfile');
        return userProfile ? JSON.parse(userProfile) : null;
    },

    // Check if user is authenticated
    isAuthenticated: () => {
        return !!localStorage.getItem('authToken');
    },

    // Get auth token
    getToken: () => {
        return localStorage.getItem('authToken');
    },
};
