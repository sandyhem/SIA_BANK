import { useState, useEffect } from 'react';
import { accountService } from '../services/accountService';
import { transactionService } from '../services/transactionService';

export const useAccounts = () => {
    const [accounts, setAccounts] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const fetchAccounts = async () => {
        try {
            setLoading(true);
            const data = await accountService.getAccounts();
            setAccounts(data);
            setError(null);
        } catch (err) {
            setError(err.response?.data?.message || 'Failed to fetch accounts');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchAccounts();
    }, []);

    return { accounts, loading, error, refetch: fetchAccounts };
};

export const useTransactions = (accountNumber) => {
    const [transactions, setTransactions] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    const fetchTransactions = async () => {
        if (!accountNumber) return;

        try {
            setLoading(true);
            const data = await transactionService.getTransactions(accountNumber);
            setTransactions(data);
            setError(null);
        } catch (err) {
            setError(err.response?.data?.message || 'Failed to fetch transactions');
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchTransactions();
    }, [accountNumber]);

    return { transactions, loading, error, refetch: fetchTransactions };
};
