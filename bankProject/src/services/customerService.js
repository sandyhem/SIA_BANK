import { authApi } from './api';

export const customerService = {
    // Create customer profile (CIF generation)
    createCustomer: async (userId, customerData) => {
        const response = await authApi.post(`/customers?userId=${userId}`, {
            fullName: customerData.fullName,
            phone: customerData.phone,
            address: customerData.address,
            city: customerData.city,
            state: customerData.state,
            postalCode: customerData.postalCode,
            country: customerData.country,
            dateOfBirth: customerData.dateOfBirth,
            panNumber: customerData.panNumber,
            aadhaarNumber: customerData.aadhaarNumber
        });

        // Store customer profile in localStorage
        if (response.data) {
            localStorage.setItem('customerProfile', JSON.stringify(response.data));
        }

        return response.data;
    },

    // Get customer by user ID
    getCustomerByUserId: async (userId) => {
        const response = await authApi.get(`/customers/user/${userId}`);

        // Store customer profile in localStorage
        if (response.data) {
            localStorage.setItem('customerProfile', JSON.stringify(response.data));
        }

        return response.data;
    },

    // Get customer by CIF number
    getCustomerByCif: async (cifNumber) => {
        const response = await authApi.get(`/customers/cif/${cifNumber}`);
        return response.data;
    },

    // Get all customers (admin)
    getAllCustomers: async () => {
        const response = await authApi.get('/customers');
        return response.data;
    },

    // Update KYC status (admin)
    updateKycStatus: async (cifNumber, kycStatus, adminUsername = 'admin') => {
        const response = await authApi.put(
            `/customers/cif/${cifNumber}/kyc?adminUsername=${adminUsername}`,
            {
                kycStatus: kycStatus
            }
        );

        // Update localStorage if this is current user's customer profile
        const storedCustomer = localStorage.getItem('customerProfile');
        if (storedCustomer) {
            const customer = JSON.parse(storedCustomer);
            if (customer.cifNumber === cifNumber) {
                customer.kycStatus = kycStatus;
                localStorage.setItem('customerProfile', JSON.stringify(customer));
            }
        }

        return response.data;
    },

    // Check if customer is active and can open accounts
    isCustomerActive: async (userId) => {
        const response = await authApi.get(`/customers/user/${userId}/active`);
        return response.data;
    },

    // Get current customer profile from localStorage
    getCurrentCustomer: () => {
        const customerProfile = localStorage.getItem('customerProfile');
        return customerProfile ? JSON.parse(customerProfile) : null;
    },

    // Clear customer profile from localStorage
    clearCustomerProfile: () => {
        localStorage.removeItem('customerProfile');
    }
};
