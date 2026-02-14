import { accountApi } from './api';

export const accountService = {
    // Get all accounts for the authenticated user
    getAccounts: async () => {
        const response = await accountApi.get('/accounts');
        return response.data;
    },

    // Get accounts by customer ID
    getAccountsByCustomerId: async (customerId) => {
        const response = await accountApi.get(`/accounts/customer/${customerId}`);
        return response.data;
    },

    // Get account by account number
    getAccountByNumber: async (accountNumber) => {
        const response = await accountApi.get(`/accounts/${accountNumber}`);
        return response.data;
    },

    // Create new account
    createAccount: async (accountData) => {
        const response = await accountApi.post('/accounts', accountData);
        return response.data;
    },

    // Credit account
    creditAccount: async (accountNumber, amount, description) => {
        const response = await accountApi.put(`/accounts/${accountNumber}/credit`, {
            senderAccount: accountNumber,
            amount: amount,
            description: description || 'Credit'
        });
        return response.data;
    },

    // Debit account
    debitAccount: async (accountNumber, amount, description) => {
        const response = await accountApi.put(`/accounts/${accountNumber}/debit`, {
            senderAccount: accountNumber,
            amount: amount,
            description: description || 'Debit'
        });
        return response.data;
    },
};
