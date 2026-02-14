import { createContext, useContext, useState, useEffect } from 'react';
import { authService } from '../services/authService';
import { customerService } from '../services/customerService';

const AuthContext = createContext(null);

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (!context) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [customer, setCustomer] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        // Check if user is already logged in
        const currentUser = authService.getCurrentUser();
        const currentCustomer = customerService.getCurrentCustomer();

        if (currentUser) {
            setUser(currentUser);
            setCustomer(currentCustomer);

            // Try to fetch latest customer data if user exists
            if (currentUser.id) {
                fetchCustomerProfile(currentUser.id).catch(() => {
                    // If fetch fails, keep existing customer data from localStorage
                });
            }
        }
        setLoading(false);
    }, []);

    const fetchCustomerProfile = async (userId) => {
        try {
            const customerData = await customerService.getCustomerByUserId(userId);
            setCustomer(customerData);
            return customerData;
        } catch (error) {
            // Customer profile might not exist yet
            setCustomer(null);
            return null;
        }
    };

    const login = async (credentials) => {
        const userData = await authService.login(credentials);
        setUser({
            id: userData.userId,
            username: userData.username,
            email: userData.email || '',
            firstName: userData.firstName || '',
            lastName: userData.lastName || '',
            phone: userData.phone || ''
        });

        // Fetch customer profile if exists
        if (userData.userId) {
            await fetchCustomerProfile(userData.userId);
        }

        return userData;
    };

    const register = async (userData) => {
        const newUser = await authService.register(userData);
        setUser({
            id: newUser.userId,
            username: newUser.username,
            email: newUser.email || '',
            firstName: newUser.firstName || '',
            lastName: newUser.lastName || '',
            phone: newUser.phone || ''
        });
        return newUser;
    };

    const logout = () => {
        authService.logout();
        customerService.clearCustomerProfile();
        setUser(null);
        setCustomer(null);
    };

    const createCustomerProfile = async (customerData) => {
        if (!user) {
            throw new Error('User must be logged in to create customer profile');
        }
        const customerProfile = await customerService.createCustomer(user.id, customerData);
        setCustomer(customerProfile);
        return customerProfile;
    };

    const refreshCustomerProfile = async () => {
        if (user?.id) {
            return await fetchCustomerProfile(user.id);
        }
        return null;
    };

    const value = {
        user,
        customer,
        loading,
        login,
        register,
        logout,
        createCustomerProfile,
        refreshCustomerProfile,
        isAuthenticated: !!user,
        hasCustomerProfile: !!customer,
        isKycVerified: customer?.kycStatus === 'VERIFIED',
        isCustomerActive: customer?.customerStatus === 'ACTIVE' && customer?.kycStatus === 'VERIFIED',
    };

    return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
