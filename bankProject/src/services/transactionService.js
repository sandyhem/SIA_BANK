import { transactionApi } from './api';

export const transactionService = {
    // Get all transactions for an account
    getTransactionsByAccount: async (accountNumber) => {
        const response = await transactionApi.get(`/transactions/account/${accountNumber}`);
        return response.data;
    },

    // Transfer money between accounts
    transfer: async (fromAccountNumber, toAccountNumber, amount, description) => {
        const response = await transactionApi.post('/transactions/transfer', {
            fromAccountNumber: fromAccountNumber,
            toAccountNumber: toAccountNumber,
            amount: amount,
            description: description || 'Transfer'
        });
        return response.data;
    },
};
