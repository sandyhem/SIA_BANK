import React, { useState, useEffect } from 'react';
import QuantumLayout from '../components/QuantumLayout';
import { useAccounts } from '../hooks/useData';
import { transactionService } from '../services/transactionService';
import {
  Search,
  Filter,
  Download,
  Calendar,
  ArrowUpRight,
  ArrowDownLeft,
  ChevronDown,
  FileText,
  X,
  RefreshCw
} from 'lucide-react';

export default function Transactions() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedFilter, setSelectedFilter] = useState('all');
  const [selectedTransaction, setSelectedTransaction] = useState(null);
  const [dateRange, setDateRange] = useState('thisMonth');
  const [selectedAccount, setSelectedAccount] = useState('');
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const { accounts, loading: accountsLoading } = useAccounts();

  // Fetch transactions when account changes
  useEffect(() => {
    if (selectedAccount) {
      fetchTransactions();
    } else {
      setTransactions([]);
    }
  }, [selectedAccount]);

  const fetchTransactions = async () => {
    if (!selectedAccount) return;

    setLoading(true);
    setError(null);
    try {
      const data = await transactionService.getTransactions(selectedAccount);
      // Transform backend data to match frontend structure
      const transformedData = (data || []).map(txn => ({
        id: txn.transactionId || txn.id,
        type: txn.transactionType === 'CREDIT' ? 'credit' : 'debit',
        description: txn.description || 'No description',
        amount: txn.transactionType === 'DEBIT' ? -txn.amount : txn.amount,
        date: txn.transactionDate ? txn.transactionDate.split('T')[0] : new Date().toISOString().split('T')[0],
        time: txn.transactionDate ? txn.transactionDate.split('T')[1]?.substring(0, 8) : '00:00:00',
        category: txn.category || 'Other',
        status: txn.status?.toLowerCase() || 'completed',
        accountNumber: '****' + String(txn.accountNumber || selectedAccount).slice(-4),
        referenceNumber: txn.referenceNumber || `REF${Date.now()}`,
        balanceBefore: txn.balanceBefore || 0,
        balanceAfter: txn.balanceAfter || 0
      }));
      setTransactions(transformedData);
    } catch (err) {
      console.error('Error fetching transactions:', err);
      setError(err.message || 'Failed to fetch transactions');
      setTransactions([]);
    } finally {
      setLoading(false);
    }
  };

  const categories = [
    'All',
    'Income',
    'Housing',
    'Shopping',
    'Utilities',
    'Groceries',
    'Transportation',
    'Dining',
    'Entertainment',
    'Investment'
  ];

  const filteredTransactions = transactions.filter(transaction => {
    const matchesSearch = transaction.description.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesFilter = selectedFilter === 'all' ||
      selectedFilter === 'credit' && transaction.type === 'credit' ||
      selectedFilter === 'debit' && transaction.type === 'debit' ||
      transaction.category === selectedFilter;
    return matchesSearch && matchesFilter;
  });

  const totalCredits = transactions
    .filter(t => t.type === 'credit')
    .reduce((sum, t) => sum + t.amount, 0);

  const totalDebits = Math.abs(transactions
    .filter(t => t.type === 'debit')
    .reduce((sum, t) => sum + t.amount, 0));

  return (
    <QuantumLayout title="Transactions" subtitle="View and manage your transaction history">
      <div className="p-6">
        {/* Header */}
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-slate-800 mb-2">Transaction History</h1>
          <p className="text-slate-600">View and manage your transaction history</p>
        </div>

        {/* Account Selector */}
        <div className="bg-white rounded-xl border border-slate-200 p-6 mb-6">
          <label className="block text-sm font-semibold text-slate-700 mb-2">
            Select Account
          </label>
          <div className="flex items-center gap-4">
            <select
              value={selectedAccount}
              onChange={(e) => setSelectedAccount(e.target.value)}
              className="flex-1 px-4 py-3 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              disabled={accountsLoading}
            >
              <option value="">Choose an account to view transactions</option>
              {accounts.map((account) => (
                <option key={account.accountNumber} value={account.accountNumber}>
                  {account.accountName || account.accountType || 'Account'} - {account.accountNumber} (${account.balance.toLocaleString()})
                </option>
              ))}
            </select>
            <button
              onClick={fetchTransactions}
              disabled={!selectedAccount || loading}
              className="px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center gap-2 font-semibold disabled:bg-slate-300"
            >
              <RefreshCw size={18} className={loading ? 'animate-spin' : ''} />
              Refresh
            </button>
          </div>
          {accountsLoading && (
            <p className="mt-2 text-sm text-slate-500">Loading accounts...</p>
          )}
          {error && (
            <p className="mt-2 text-sm text-red-600">{error}</p>
          )}
          {!selectedAccount && accounts.length > 0 && (
            <p className="mt-2 text-sm text-amber-600">Please select an account to view transactions</p>
          )}
          {selectedAccount && !loading && transactions.length === 0 && (
            <p className="mt-2 text-sm text-slate-500">No transactions found for this account</p>
          )}
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
          <div className="bg-white rounded-xl p-6 border border-slate-200">
            <div className="flex items-center justify-between mb-3">
              <div className="w-12 h-12 bg-green-100 rounded-xl flex items-center justify-center">
                <ArrowDownLeft size={24} className="text-green-600" />
              </div>
            </div>
            <p className="text-sm text-slate-600 mb-1">Total Credits</p>
            <p className="text-3xl font-bold text-green-600">+${totalCredits.toLocaleString('en-US', { minimumFractionDigits: 2 })}</p>
            <p className="text-xs text-slate-500 mt-2">{transactions.filter(t => t.type === 'credit').length} transactions</p>
          </div>

          <div className="bg-white rounded-xl p-6 border border-slate-200">
            <div className="flex items-center justify-between mb-3">
              <div className="w-12 h-12 bg-red-100 rounded-xl flex items-center justify-center">
                <ArrowUpRight size={24} className="text-red-600" />
              </div>
            </div>
            <p className="text-sm text-slate-600 mb-1">Total Debits</p>
            <p className="text-3xl font-bold text-red-600">-${totalDebits.toLocaleString('en-US', { minimumFractionDigits: 2 })}</p>
            <p className="text-xs text-slate-500 mt-2">{transactions.filter(t => t.type === 'debit').length} transactions</p>
          </div>

          <div className="bg-white rounded-xl p-6 border border-slate-200">
            <div className="flex items-center justify-between mb-3">
              <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center">
                <FileText size={24} className="text-blue-600" />
              </div>
            </div>
            <p className="text-sm text-slate-600 mb-1">Net Change</p>
            <p className={`text-3xl font-bold ${(totalCredits - totalDebits) >= 0 ? 'text-green-600' : 'text-red-600'}`}>
              {(totalCredits - totalDebits) >= 0 ? '+' : ''} ${(totalCredits - totalDebits).toLocaleString('en-US', { minimumFractionDigits: 2 })}
            </p>
            <p className="text-xs text-slate-500 mt-2">This period</p>
          </div>
        </div>

        {/* Filters and Search */}
        <div className="bg-white rounded-xl border border-slate-200 p-6 mb-6">
          <div className="grid grid-cols-1 md:grid-cols-12 gap-4">
            {/* Search */}
            <div className="md:col-span-5">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
                <input
                  type="text"
                  placeholder="Search transactions..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-10 pr-4 py-2.5 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>
            </div>

            {/* Type Filter */}
            <div className="md:col-span-2">
              <select
                value={selectedFilter}
                onChange={(e) => setSelectedFilter(e.target.value)}
                className="w-full px-4 py-2.5 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="all">All Types</option>
                <option value="credit">Credits</option>
                <option value="debit">Debits</option>
              </select>
            </div>

            {/* Category Filter */}
            <div className="md:col-span-3">
              <select
                value={selectedFilter}
                onChange={(e) => setSelectedFilter(e.target.value)}
                className="w-full px-4 py-2.5 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                {categories.map((category) => (
                  <option key={category} value={category.toLowerCase()}>
                    {category}
                  </option>
                ))}
              </select>
            </div>

            {/* Export Button */}
            <div className="md:col-span-2">
              <button className="w-full px-4 py-2.5 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center justify-center gap-2 font-semibold">
                <Download size={18} />
                Export
              </button>
            </div>
          </div>

          {/* Active Filters */}
          {(searchQuery || selectedFilter !== 'all') && (
            <div className="flex items-center gap-2 mt-4 pt-4 border-t border-slate-200">
              <span className="text-sm text-slate-600">Active Filters:</span>
              {searchQuery && (
                <span className="px-3 py-1 bg-blue-100 text-blue-700 text-sm rounded-full flex items-center gap-2">
                  Search: "{searchQuery}"
                  <button onClick={() => setSearchQuery('')}>
                    <X size={14} />
                  </button>
                </span>
              )}
              {selectedFilter !== 'all' && (
                <span className="px-3 py-1 bg-blue-100 text-blue-700 text-sm rounded-full flex items-center gap-2">
                  Filter: {selectedFilter}
                  <button onClick={() => setSelectedFilter('all')}>
                    <X size={14} />
                  </button>
                </span>
              )}
            </div>
          )}
        </div>

        {/* Transactions List */}
        <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
          <div className="divide-y divide-slate-100">
            {filteredTransactions.length > 0 ? (
              filteredTransactions.map((transaction) => (
                <div
                  key={transaction.id}
                  onClick={() => setSelectedTransaction(transaction)}
                  className="p-6 hover:bg-slate-50 transition-colors cursor-pointer"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-4">
                      <div className={`w-14 h-14 rounded-xl flex items-center justify-center ${transaction.type === 'credit' ? 'bg-green-100' : 'bg-red-100'
                        }`}>
                        {transaction.type === 'credit' ? (
                          <ArrowDownLeft size={24} className="text-green-600" />
                        ) : (
                          <ArrowUpRight size={24} className="text-red-600" />
                        )}
                      </div>
                      <div>
                        <p className="font-semibold text-slate-800 mb-1">{transaction.description}</p>
                        <div className="flex items-center gap-3 text-sm text-slate-500">
                          <span>{new Date(transaction.date).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}</span>
                          <span>•</span>
                          <span>{transaction.time}</span>
                          <span>•</span>
                          <span className="px-2 py-0.5 bg-slate-100 rounded text-xs font-medium">
                            {transaction.category}
                          </span>
                        </div>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className={`text-2xl font-bold mb-1 ${transaction.type === 'credit' ? 'text-green-600' : 'text-slate-800'
                        }`}>
                        {transaction.type === 'credit' ? '+' : '-'}${Math.abs(transaction.amount).toLocaleString('en-US', { minimumFractionDigits: 2 })}
                      </p>
                      <p className="text-sm text-slate-500">{transaction.accountNumber}</p>
                    </div>
                  </div>
                </div>
              ))
            ) : (
              <div className="p-12 text-center">
                <div className="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Search size={32} className="text-slate-400" />
                </div>
                {loading ? (
                  <>
                    <h3 className="text-lg font-semibold text-slate-800 mb-2">Loading transactions...</h3>
                    <p className="text-slate-500">Please wait</p>
                  </>
                ) : !selectedAccount ? (
                  <>
                    <h3 className="text-lg font-semibold text-slate-800 mb-2">No account selected</h3>
                    <p className="text-slate-500">Please select an account to view transactions</p>
                  </>
                ) : transactions.length === 0 ? (
                  <>
                    <h3 className="text-lg font-semibold text-slate-800 mb-2">No transactions yet</h3>
                    <p className="text-slate-500">This account has no transaction history</p>
                  </>
                ) : (
                  <>
                    <h3 className="text-lg font-semibold text-slate-800 mb-2">No transactions found</h3>
                    <p className="text-slate-500">Try adjusting your filters or search query</p>
                  </>
                )}
              </div>
            )}
          </div>
        </div>

        {/* Transaction Detail Modal */}
        {
          selectedTransaction && (
            <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
              <div className="bg-white rounded-2xl max-w-2xl w-full">
                <div className="p-6 border-b border-slate-200">
                  <div className="flex items-center justify-between">
                    <h2 className="text-2xl font-bold text-slate-800">Transaction Details</h2>
                    <button
                      onClick={() => setSelectedTransaction(null)}
                      className="w-10 h-10 flex items-center justify-center hover:bg-slate-100 rounded-lg transition-colors text-2xl"
                    >
                      ×
                    </button>
                  </div>
                </div>
                <div className="p-6">
                  {/* Amount */}
                  <div className="text-center mb-6">
                    <p className={`text-5xl font-bold mb-2 ${selectedTransaction.type === 'credit' ? 'text-green-600' : 'text-slate-800'
                      }`}>
                      {selectedTransaction.type === 'credit' ? '+' : '-'}${Math.abs(selectedTransaction.amount).toLocaleString('en-US', { minimumFractionDigits: 2 })}
                    </p>
                    <span className={`px-4 py-2 rounded-full text-sm font-semibold ${selectedTransaction.type === 'credit' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                      }`}>
                      {selectedTransaction.type === 'credit' ? 'Credit' : 'Debit'}
                    </span>
                  </div>

                  {/* Details Grid */}
                  <div className="space-y-4">
                    <div className="grid grid-cols-2 gap-4 p-4 bg-slate-50 rounded-lg">
                      <div>
                        <p className="text-sm text-slate-500 mb-1">Description</p>
                        <p className="font-semibold text-slate-800">{selectedTransaction.description}</p>
                      </div>
                      <div>
                        <p className="text-sm text-slate-500 mb-1">Category</p>
                        <p className="font-semibold text-slate-800">{selectedTransaction.category}</p>
                      </div>
                      <div>
                        <p className="text-sm text-slate-500 mb-1">Date</p>
                        <p className="font-semibold text-slate-800">
                          {new Date(selectedTransaction.date).toLocaleDateString('en-US', {
                            month: 'long',
                            day: 'numeric',
                            year: 'numeric'
                          })}
                        </p>
                      </div>
                      <div>
                        <p className="text-sm text-slate-500 mb-1">Time</p>
                        <p className="font-semibold text-slate-800">{selectedTransaction.time}</p>
                      </div>
                      <div>
                        <p className="text-sm text-slate-500 mb-1">Reference Number</p>
                        <p className="font-semibold text-slate-800">{selectedTransaction.referenceNumber}</p>
                      </div>
                      <div>
                        <p className="text-sm text-slate-500 mb-1">Account</p>
                        <p className="font-semibold text-slate-800">{selectedTransaction.accountNumber}</p>
                      </div>
                      <div>
                        <p className="text-sm text-slate-500 mb-1">Balance Before</p>
                        <p className="font-semibold text-slate-800">
                          ${selectedTransaction.balanceBefore.toLocaleString('en-US', { minimumFractionDigits: 2 })}
                        </p>
                      </div>
                      <div>
                        <p className="text-sm text-slate-500 mb-1">Balance After</p>
                        <p className="font-semibold text-slate-800">
                          ${selectedTransaction.balanceAfter.toLocaleString('en-US', { minimumFractionDigits: 2 })}
                        </p>
                      </div>
                    </div>

                    {/* Actions */}
                    <div className="flex gap-3 pt-4">
                      <button className="flex-1 py-3 px-4 bg-slate-100 hover:bg-slate-200 rounded-lg font-semibold transition-colors flex items-center justify-center gap-2">
                        <Download size={18} />
                        Download Receipt
                      </button>
                      <button className="flex-1 py-3 px-4 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-semibold transition-colors">
                        Report Issue
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          )
        }
      </div >
    </QuantumLayout >
  );
}