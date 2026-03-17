import React, { useState, useEffect } from 'react';
import QuantumLayout from '../components/QuantumLayout';
import { useAuth } from '../context/AuthContext';
import { accountService } from '../services/accountService';
import { transactionService } from '../services/transactionService';
import {
  Search,
  Filter,
  Download,
  ArrowUpRight,
  ArrowDownLeft,
  RefreshCw,
  Calendar
} from 'lucide-react';

export default function Transactions() {
  const { user, isCustomerActive } = useAuth();
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedFilter, setSelectedFilter] = useState('all');
  const [selectedAccount, setSelectedAccount] = useState('');
  const [transactions, setTransactions] = useState([]);
  const [accounts, setAccounts] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [dateRange, setDateRange] = useState('all');

  useEffect(() => {
    if (isCustomerActive && user?.id) {
      loadAccounts();
    }
  }, [isCustomerActive, user]);

  useEffect(() => {
    if (selectedAccount) {
      fetchTransactions();
    } else {
      setTransactions([]);
    }
  }, [selectedAccount]);

  const loadAccounts = async () => {
    try {
      setLoading(true);
      const data = await accountService.getAccountsByCustomerId(user.id);
      setAccounts(data);
      if (data.length > 0) {
        setSelectedAccount(data[0].accountNumber);
      }
    } catch (err) {
      console.error('Error loading accounts:', err);
      setError('Failed to load accounts');
    } finally {
      setLoading(false);
    }
  };

  const fetchTransactions = async () => {
    if (!selectedAccount) return;

    setLoading(true);
    setError(null);
    try {
      const data = await transactionService.getTransactionsByAccount(selectedAccount);
      setTransactions(data || []);
    } catch (err) {
      console.error('Error fetching transactions:', err);
      setError(err.response?.data?.message || 'Failed to load transactions');
      setTransactions([]);
    } finally {
      setLoading(false);
    }
  };

  const isWithinDateRange = (transactionDate) => {
    if (!transactionDate || dateRange === 'all') return true;

    const txnDate = new Date(transactionDate);
    const today = new Date();
    const diffTime = today - txnDate;
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    switch (dateRange) {
      case 'today':
        return diffDays === 0;
      case 'week':
        return diffDays <= 7;
      case 'month':
        return diffDays <= 30;
      case 'year':
        return diffDays <= 365;
      default:
        return true;
    }
  };

  const filteredTransactions = transactions.filter(transaction => {
    const matchesSearch =
      (transaction.description && transaction.description.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (transaction.fromAccountNumber && transaction.fromAccountNumber.includes(searchQuery)) ||
      (transaction.toAccountNumber && transaction.toAccountNumber.includes(searchQuery));

    const matchesFilter =
      selectedFilter === 'all' ||
      (selectedFilter === 'sent' && transaction.fromAccountNumber === selectedAccount) ||
      (selectedFilter === 'received' && transaction.toAccountNumber === selectedAccount);

    const matchesDate = isWithinDateRange(transaction.createdAt);

    return matchesSearch && matchesFilter && matchesDate;
  });

  const getTransactionIcon = (transaction) => {
    const isSent = transaction.fromAccountNumber === selectedAccount;
    return isSent ?
      <ArrowUpRight className="w-5 h-5 text-red-500" /> :
      <ArrowDownLeft className="w-5 h-5 text-green-500" />;
  };

  const getTransactionAmount = (transaction) => {
    const isSent = transaction.fromAccountNumber === selectedAccount;
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

  if (!isCustomerActive) {
    return (
      <QuantumLayout title="Transactions" subtitle="View transaction history">
        <div className="bg-yellow-50 border border-yellow-200 text-yellow-800 px-6 py-4 rounded-lg">
          <p className="font-medium">Profile Incomplete</p>
          <p className="text-sm mt-1">
            Please complete your customer profile before viewing transactions.
          </p>
        </div>
      </QuantumLayout>
    );
  }

  return (
    <QuantumLayout title="Transactions" subtitle="View and manage your transaction history">
      <div className="max-w-6xl mx-auto">
        {/* Account Selection */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 mb-2">Select Account</label>
          <select
            value={selectedAccount}
            onChange={(e) => setSelectedAccount(e.target.value)}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-600 focus:border-transparent"
          >
            <option value="">Choose an account</option>
            {accounts.map(acc => (
              <option key={acc.accountNumber} value={acc.accountNumber}>
                {acc.accountNumber} - {acc.accountType} (₹{parseFloat(acc.balance).toLocaleString('en-IN')})
              </option>
            ))}
          </select>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-6">
            {error}
          </div>
        )}

        {/* Filters and Search */}
        {selectedAccount && !loading && (
          <div className="bg-white rounded-lg p-6 mb-6 shadow-sm">
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              {/* Search */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Search</label>
                <div className="relative">
                  <Search className="absolute left-3 top-2.5 w-5 h-5 text-gray-400" />
                  <input
                    type="text"
                    placeholder="Description or account..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-600"
                  />
                </div>
              </div>

              {/* Transaction Type */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Type</label>
                <select
                  value={selectedFilter}
                  onChange={(e) => setSelectedFilter(e.target.value)}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-600"
                >
                  <option value="all">All Transactions</option>
                  <option value="sent">Sent</option>
                  <option value="received">Received</option>
                </select>
              </div>

              {/* Date Range */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Date Range</label>
                <select
                  value={dateRange}
                  onChange={(e) => setDateRange(e.target.value)}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-600"
                >
                  <option value="all">All Time</option>
                  <option value="today">Today</option>
                  <option value="week">Last 7 Days</option>
                  <option value="month">Last 30 Days</option>
                  <option value="year">Last Year</option>
                </select>
              </div>

              {/* Refresh */}
              <div className="flex items-end">
                <button
                  onClick={fetchTransactions}
                  className="w-full px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 flex items-center justify-center gap-2"
                >
                  <RefreshCw className="w-4 h-4" />
                  Refresh
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Transactions List */}
        {selectedAccount && (
          <div className="bg-white rounded-lg shadow-sm overflow-hidden">
            {loading ? (
              <div className="flex items-center justify-center p-12">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600"></div>
              </div>
            ) : filteredTransactions.length === 0 ? (
              <div className="p-12 text-center">
                <Calendar className="w-16 h-16 text-gray-300 mx-auto mb-4" />
                <h3 className="text-lg font-semibold text-gray-900 mb-2">No Transactions</h3>
                <p className="text-gray-500">No transactions found for this account in the selected period.</p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-gray-50 border-b border-gray-200">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Type</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Description</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">From Account</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">To Account</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Amount</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date & Time</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200">
                    {filteredTransactions.map((transaction, idx) => (
                      <tr key={transaction.transactionId || idx} className="hover:bg-gray-50">
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="flex items-center justify-center">
                            {getTransactionIcon(transaction)}
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <p className="text-sm font-medium text-gray-900">{transaction.description || 'Transfer'}</p>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <p className="text-sm text-gray-600 font-mono">{transaction.fromAccountNumber}</p>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <p className="text-sm text-gray-600 font-mono">{transaction.toAccountNumber}</p>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <p className={`text-sm font-semibold ${transaction.fromAccountNumber === selectedAccount ? 'text-red-600' : 'text-green-600'
                            }`}>
                            {getTransactionAmount(transaction)}
                          </p>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm text-gray-600">
                            <p>{formatDate(transaction.createdAt)}</p>
                            <p className="text-xs text-gray-400">{formatTime(transaction.createdAt)}</p>
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span className={`px-3 py-1 rounded-full text-xs font-medium ${transaction.status === 'SUCCESS' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'
                            }`}>
                            {transaction.status || 'PENDING'}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}

            {/* Summary */}
            {selectedAccount && filteredTransactions.length > 0 && (
              <div className="bg-gray-50 border-t border-gray-200 px-6 py-4">
                <div className="grid grid-cols-3 gap-4 text-sm">
                  <div>
                    <p className="text-gray-500">Total Transactions</p>
                    <p className="text-lg font-semibold text-gray-900">{filteredTransactions.length}</p>
                  </div>
                  <div>
                    <p className="text-gray-500">Sent</p>
                    <p className="text-lg font-semibold text-red-600">
                      ₹{filteredTransactions
                        .filter(t => t.fromAccountNumber === selectedAccount)
                        .reduce((sum, t) => sum + parseFloat(t.amount || 0), 0)
                        .toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                    </p>
                  </div>
                  <div>
                    <p className="text-gray-500">Received</p>
                    <p className="text-lg font-semibold text-green-600">
                      ₹{filteredTransactions
                        .filter(t => t.toAccountNumber === selectedAccount)
                        .reduce((sum, t) => sum + parseFloat(t.amount || 0), 0)
                        .toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                    </p>
                  </div>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </QuantumLayout>
  );
}
