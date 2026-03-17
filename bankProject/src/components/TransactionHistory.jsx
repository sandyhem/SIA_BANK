import React, { useState, useEffect } from 'react';
import { transactionService } from '../services/transactionService';
import { ArrowUpRight, ArrowDownLeft } from 'lucide-react';

export default function TransactionHistory({ accountNumber, limit = 10 }) {
    const [transactions, setTransactions] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    useEffect(() => {
        if (accountNumber) {
            fetchTransactions();
        }
    }, [accountNumber]);

    const fetchTransactions = async () => {
        setLoading(true);
        setError(null);
        try {
            const data = await transactionService.getTransactionsByAccount(accountNumber);
            // Get only the most recent transactions
            const recentTxns = (data || []).slice(0, limit);
            setTransactions(recentTxns);
        } catch (err) {
            console.error('Error fetching transactions:', err);
            setError('Failed to load transaction history');
            setTransactions([]);
        } finally {
            setLoading(false);
        }
    };

    const getTransactionIcon = (transaction) => {
        const isSent = transaction.fromAccountNumber === accountNumber;
        return isSent ?
            <ArrowUpRight className="w-4 h-4 text-red-500" /> :
            <ArrowDownLeft className="w-4 h-4 text-green-500" />;
    };

    const getTransactionAmount = (transaction) => {
        const isSent = transaction.fromAccountNumber === accountNumber;
        const sign = isSent ? '-' : '+';
        return sign + parseFloat(transaction.amount).toLocaleString('en-IN', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
    };

    const formatDate = (dateString) => {
        if (!dateString) return 'N/A';
        return new Date(dateString).toLocaleDateString('en-IN', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    };

    const formatTime = (dateString) => {
        if (!dateString) return '';
        return new Date(dateString).toLocaleTimeString('en-IN', {
            hour: '2-digit',
            minute: '2-digit'
        });
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center p-8">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-600"></div>
            </div>
        );
    }

    if (error) {
        return (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
                {error}
            </div>
        );
    }

    if (transactions.length === 0) {
        return (
            <div className="text-center py-8">
                <p className="text-gray-500">No transactions yet</p>
            </div>
        );
    }

    return (
        <div className="space-y-2">
            {transactions.map((transaction, idx) => (
                <div
                    key={transaction.transactionId || idx}
                    className="flex items-center justify-between p-3 hover:bg-gray-50 rounded-lg transition"
                >
                    <div className="flex items-center gap-3 flex-1 min-w-0">
                        <div className="flex-shrink-0">
                            {getTransactionIcon(transaction)}
                        </div>
                        <div className="flex-1 min-w-0">
                            <p className="text-sm font-medium text-gray-900 truncate">
                                {transaction.description || 'Transfer'}
                            </p>
                            <p className="text-xs text-gray-500">
                                {formatDate(transaction.createdAt)} at {formatTime(transaction.createdAt)}
                            </p>
                        </div>
                    </div>
                    <div className="text-right flex-shrink-0 ml-4">
                        <p className={`text-sm font-semibold ${transaction.fromAccountNumber === accountNumber ? 'text-red-600' : 'text-green-600'
                            }`}>
                            {getTransactionAmount(transaction)}
                        </p>
                        <p className="text-xs text-gray-500">
                            {transaction.status === 'SUCCESS' ? 'Completed' : transaction.status || 'Pending'}
                        </p>
                    </div>
                </div>
            ))}
        </div>
    );
}
