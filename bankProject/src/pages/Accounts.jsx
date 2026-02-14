import React, { useState, useEffect } from 'react';
import QuantumLayout from '../components/QuantumLayout';
import {
  Wallet,
  Eye,
  EyeOff,
  Download,
  Calendar,
  TrendingUp,
  RefreshCw,
  Plus,
  ArrowUpRight,
  ArrowDownLeft,
  Filter,
  Search,
  ChevronRight,
  DollarSign,
  Clock,
  CheckCircle
} from 'lucide-react';

export default function Accounts() {
  const [showBalances, setShowBalances] = useState(true);
  const [selectedAccount, setSelectedAccount] = useState(null);
  const [loading, setLoading] = useState(false);

  const accounts = [
    {
      id: 'ACC001',
      type: 'Savings Account',
      accountNumber: '****7890',
      fullAccountNumber: '1234567890',
      balance: 45230.85,
      currency: 'USD',
      status: 'active',
      interestRate: 3.5,
      minimumBalance: 1000.00,
      availableBalance: 45230.85,
      holdAmount: 0.00,
      openedDate: '2020-01-15',
      branch: 'Main Street Branch',
      ifscCode: 'QBNK0001234',
      lastTransactionDate: '2026-02-13',
      monthlyAverage: 42500.00,
      interestEarned: 1245.50
    },
    {
      id: 'ACC002',
      type: 'Current Account',
      accountNumber: '****4521',
      fullAccountNumber: '9876544521',
      balance: 12458.92,
      currency: 'USD',
      status: 'active',
      interestRate: 0,
      availableBalance: 12458.92,
      holdAmount: 0.00,
      openedDate: '2020-01-15',
      branch: 'Main Street Branch',
      ifscCode: 'QBNK0001234',
      lastTransactionDate: '2026-02-14',
      overdraftLimit: 5000.00,
      monthlyTransactions: 156
    },
    {
      id: 'ACC003',
      type: 'Fixed Deposit',
      accountNumber: '****3214',
      fullAccountNumber: '5432103214',
      balance: 100000.00,
      currency: 'USD',
      status: 'active',
      interestRate: 6.5,
      openedDate: '2024-03-15',
      maturityDate: '2027-03-15',
      maturityAmount: 121025.00,
      tenure: 36,
      autoRenew: true,
      branch: 'Main Street Branch'
    }
  ];

  const recentTransactions = [
    {
      id: 'TXN001',
      accountId: 'ACC001',
      type: 'credit',
      description: 'Salary Deposit - ABC Corporation',
      amount: 8500.00,
      date: '2026-02-13',
      time: '09:30 AM',
      balance: 45230.85
    },
    {
      id: 'TXN002',
      accountId: 'ACC002',
      type: 'debit',
      description: 'Rent Payment',
      amount: -2500.00,
      date: '2026-02-12',
      time: '02:15 PM',
      balance: 12458.92
    },
    {
      id: 'TXN003',
      accountId: 'ACC001',
      type: 'debit',
      description: 'Amazon Purchase',
      amount: -156.43,
      date: '2026-02-11',
      time: '11:20 AM',
      balance: 44230.85
    }
  ];

  const handleRefresh = async () => {
    setLoading(true);
    // Simulate API call
    setTimeout(() => setLoading(false), 1000);
  };

  const totalBalance = accounts.reduce((sum, acc) => sum + acc.balance, 0);

  return (
    <QuantumLayout title="Accounts" subtitle="Manage all your bank accounts">
      <div className="p-6">
      {/* Header */}
      <div className="mb-6">
        <div className="flex items-center justify-between mb-2">
          <div>
            <h1 className="text-3xl font-bold text-slate-800">My Accounts</h1>
            <p className="text-slate-600 mt-1">Manage all your bank accounts</p>
          </div>
          <div className="flex items-center gap-3">
            <button
              onClick={handleRefresh}
              className="px-4 py-2 bg-white border border-slate-200 rounded-lg hover:bg-slate-50 transition-colors flex items-center gap-2"
              disabled={loading}
            >
              <RefreshCw size={18} className={loading ? 'animate-spin' : ''} />
              <span className="font-semibold">Refresh</span>
            </button>
            <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center gap-2 font-semibold">
              <Plus size={18} />
              Open New Account
            </button>
          </div>
        </div>
      </div>

      {/* Summary Card */}
      <div className="bg-gradient-to-br from-blue-600 to-blue-800 rounded-2xl p-8 text-white mb-6">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-blue-100 mb-2">Total Balance Across All Accounts</p>
            <div className="flex items-center gap-3">
              <h2 className="text-5xl font-bold">
                {showBalances ? `$${totalBalance.toLocaleString('en-US', { minimumFractionDigits: 2 })}` : '••••••••'}
              </h2>
              <button
                onClick={() => setShowBalances(!showBalances)}
                className="p-2 hover:bg-white/10 rounded-lg transition-colors"
              >
                {showBalances ? <Eye size={24} /> : <EyeOff size={24} />}
              </button>
            </div>
          </div>
          <div className="text-right">
            <div className="bg-white/10 backdrop-blur-sm rounded-xl p-4 border border-white/20">
              <p className="text-sm text-blue-100 mb-1">Active Accounts</p>
              <p className="text-3xl font-bold">{accounts.filter(a => a.status === 'active').length}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Accounts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6 mb-6">
        {accounts.map((account) => (
          <div
            key={account.id}
            className="bg-white rounded-xl border border-slate-200 overflow-hidden hover:shadow-lg transition-all cursor-pointer"
            onClick={() => setSelectedAccount(account)}
          >
            {/* Account Header */}
            <div className="bg-gradient-to-r from-slate-50 to-slate-100 p-6 border-b border-slate-200">
              <div className="flex items-start justify-between mb-4">
                <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center">
                  <Wallet size={24} className="text-blue-600" />
                </div>
                <span className="px-3 py-1 bg-green-100 text-green-700 text-xs font-semibold rounded-full">
                  Active
                </span>
              </div>
              <h3 className="text-lg font-bold text-slate-800 mb-1">{account.type}</h3>
              <p className="text-sm text-slate-500">{account.accountNumber}</p>
            </div>

            {/* Account Balance */}
            <div className="p-6">
              <div className="mb-4">
                <p className="text-sm text-slate-500 mb-1">Available Balance</p>
                <p className="text-3xl font-bold text-slate-800">
                  {showBalances 
                    ? `$${account.balance.toLocaleString('en-US', { minimumFractionDigits: 2 })}` 
                    : '••••••••'
                  }
                </p>
              </div>

              {/* Account Details */}
              <div className="space-y-3">
                {account.interestRate > 0 && (
                  <div className="flex items-center justify-between py-2 border-t border-slate-100">
                    <span className="text-sm text-slate-600">Interest Rate</span>
                    <span className="text-sm font-semibold text-green-600">{account.interestRate}% p.a.</span>
                  </div>
                )}
                {account.maturityDate && (
                  <div className="flex items-center justify-between py-2 border-t border-slate-100">
                    <span className="text-sm text-slate-600">Maturity Date</span>
                    <span className="text-sm font-semibold text-slate-800">
                      {new Date(account.maturityDate).toLocaleDateString()}
                    </span>
                  </div>
                )}
                {account.overdraftLimit && (
                  <div className="flex items-center justify-between py-2 border-t border-slate-100">
                    <span className="text-sm text-slate-600">Overdraft Limit</span>
                    <span className="text-sm font-semibold text-slate-800">
                      ${account.overdraftLimit.toLocaleString()}
                    </span>
                  </div>
                )}
              </div>

              {/* Actions */}
              <div className="flex gap-2 mt-4 pt-4 border-t border-slate-100">
                <button className="flex-1 py-2 px-3 bg-slate-100 hover:bg-slate-200 rounded-lg text-sm font-semibold transition-colors">
                  View Details
                </button>
                <button className="flex-1 py-2 px-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-semibold transition-colors">
                  Statement
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
        <div className="bg-white rounded-xl p-6 border border-slate-200">
          <div className="flex items-center justify-between mb-3">
            <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
              <TrendingUp size={20} className="text-green-600" />
            </div>
          </div>
          <p className="text-sm text-slate-600 mb-1">Total Credits (This Month)</p>
          <p className="text-2xl font-bold text-slate-800">$8,950.00</p>
        </div>

        <div className="bg-white rounded-xl p-6 border border-slate-200">
          <div className="flex items-center justify-between mb-3">
            <div className="w-10 h-10 bg-red-100 rounded-lg flex items-center justify-center">
              <ArrowUpRight size={20} className="text-red-600" />
            </div>
          </div>
          <p className="text-sm text-slate-600 mb-1">Total Debits (This Month)</p>
          <p className="text-2xl font-bold text-slate-800">$5,234.67</p>
        </div>

        <div className="bg-white rounded-xl p-6 border border-slate-200">
          <div className="flex items-center justify-between mb-3">
            <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
              <DollarSign size={20} className="text-blue-600" />
            </div>
          </div>
          <p className="text-sm text-slate-600 mb-1">Interest Earned (YTD)</p>
          <p className="text-2xl font-bold text-slate-800">$1,245.50</p>
        </div>

        <div className="bg-white rounded-xl p-6 border border-slate-200">
          <div className="flex items-center justify-between mb-3">
            <div className="w-10 h-10 bg-purple-100 rounded-lg flex items-center justify-center">
              <Clock size={20} className="text-purple-600" />
            </div>
          </div>
          <p className="text-sm text-slate-600 mb-1">Pending Transactions</p>
          <p className="text-2xl font-bold text-slate-800">0</p>
        </div>
      </div>

      {/* Recent Transactions */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        <div className="p-6 border-b border-slate-200">
          <div className="flex items-center justify-between">
            <h3 className="text-xl font-bold text-slate-800">Recent Transactions</h3>
            <button className="text-sm text-blue-600 font-semibold hover:text-blue-700">
              View All →
            </button>
          </div>
        </div>
        <div className="divide-y divide-slate-100">
          {recentTransactions.map((transaction) => (
            <div
              key={transaction.id}
              className="p-6 hover:bg-slate-50 transition-colors cursor-pointer"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4">
                  <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${
                    transaction.type === 'credit' ? 'bg-green-100' : 'bg-red-100'
                  }`}>
                    {transaction.type === 'credit' ? (
                      <ArrowDownLeft size={20} className="text-green-600" />
                    ) : (
                      <ArrowUpRight size={20} className="text-red-600" />
                    )}
                  </div>
                  <div>
                    <p className="font-semibold text-slate-800">{transaction.description}</p>
                    <p className="text-sm text-slate-500">
                      {transaction.date} • {transaction.time}
                    </p>
                  </div>
                </div>
                <div className="text-right">
                  <p className={`text-xl font-bold ${
                    transaction.type === 'credit' ? 'text-green-600' : 'text-slate-800'
                  }`}>
                    {transaction.type === 'credit' ? '+' : ''}${Math.abs(transaction.amount).toLocaleString('en-US', { minimumFractionDigits: 2 })}
                  </p>
                  <p className="text-sm text-slate-500">
                    Balance: ${transaction.balance.toLocaleString('en-US', { minimumFractionDigits: 2 })}
                  </p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Account Details Modal */}
      {selectedAccount && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-slate-200">
              <div className="flex items-center justify-between">
                <h2 className="text-2xl font-bold text-slate-800">Account Details</h2>
                <button
                  onClick={() => setSelectedAccount(null)}
                  className="w-10 h-10 flex items-center justify-center hover:bg-slate-100 rounded-lg transition-colors"
                >
                  ×
                </button>
              </div>
            </div>
            <div className="p-6">
              <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-slate-500 mb-1">Account Type</p>
                    <p className="font-semibold text-slate-800">{selectedAccount.type}</p>
                  </div>
                  <div>
                    <p className="text-sm text-slate-500 mb-1">Account Number</p>
                    <p className="font-semibold text-slate-800">{selectedAccount.fullAccountNumber}</p>
                  </div>
                  <div>
                    <p className="text-sm text-slate-500 mb-1">IFSC Code</p>
                    <p className="font-semibold text-slate-800">{selectedAccount.ifscCode}</p>
                  </div>
                  <div>
                    <p className="text-sm text-slate-500 mb-1">Branch</p>
                    <p className="font-semibold text-slate-800">{selectedAccount.branch}</p>
                  </div>
                  <div>
                    <p className="text-sm text-slate-500 mb-1">Opened Date</p>
                    <p className="font-semibold text-slate-800">
                      {new Date(selectedAccount.openedDate).toLocaleDateString()}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-slate-500 mb-1">Status</p>
                    <span className="px-3 py-1 bg-green-100 text-green-700 text-xs font-semibold rounded-full">
                      {selectedAccount.status}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
      </div>
    </QuantumLayout>
  );
}