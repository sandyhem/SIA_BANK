import axios from 'axios';

// API Base URLs from environment variables
const AUTH_API_URL = import.meta.env.VITE_AUTH_API_URL || 'http://localhost:8083/auth/api';
const ACCOUNT_API_URL = import.meta.env.VITE_ACCOUNT_API_URL || 'http://localhost:8081/api';
const TRANSACTION_API_URL = import.meta.env.VITE_TRANSACTION_API_URL || 'http://localhost:8082/api';

// Create axios instances for each service
const authApi = axios.create({
    baseURL: AUTH_API_URL,
    headers: {
        'Content-Type': 'application/json',
    },
});

const accountApi = axios.create({
    baseURL: ACCOUNT_API_URL,
    headers: {
        'Content-Type': 'application/json',
    },
});

const transactionApi = axios.create({
    baseURL: TRANSACTION_API_URL,
    headers: {
        'Content-Type': 'application/json',
    },
});

// Request interceptor to add auth token
const addAuthInterceptor = (apiInstance) => {
    apiInstance.interceptors.request.use(
        (config) => {
            const token = localStorage.getItem('authToken');
            if (token) {
                config.headers.Authorization = `Bearer ${token}`;
            }
            return config;
        },
        (error) => Promise.reject(error)
    );
};

// Add interceptors to all APIs
addAuthInterceptor(accountApi);
addAuthInterceptor(transactionApi);

// Response interceptor for error handling
const addErrorInterceptor = (apiInstance) => {
    apiInstance.interceptors.response.use(
        (response) => response,
        (error) => {
            if (error.response?.status === 401) {
                // Unauthorized - clear token and redirect to login
                localStorage.removeItem('authToken');
                localStorage.removeItem('userProfile');
                window.location.href = '/login';
            }
            return Promise.reject(error);
        }
    );
};

addErrorInterceptor(authApi);
addErrorInterceptor(accountApi);
addErrorInterceptor(transactionApi);

export { authApi, accountApi, transactionApi };
