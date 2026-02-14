import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import {
  Wallet,
  TrendingUp,
  Send,
  Download,
  Plus,
  Eye,
  EyeOff,
  ArrowUpRight,
  ArrowDownLeft,
  Calendar,
  Bell,
  DollarSign,
  CheckCircle,
  AlertCircle,
  MapPin,
  CreditCard,
  FileText,
  Sparkles,
  TrendingDown,
  RefreshCw
} from 'lucide-react';
import QuantumLayout from '../components/QuantumLayout';
import CreateAccountModal from '../components/CreateAccountModal';
import { useAuth } from '../context/AuthContext';
import { useAccounts } from '../hooks/useData';

export default function QuantumBankingDashboard() {
  const [showBalance, setShowBalance] = useState(true);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const { user } = useAuth();
  const { accounts, loading: accountsLoading, refetch } = useAccounts();

  // User data from auth context
  const userData = {
    name: user?.name || user?.username || 'User',
    customerId: user?.customerId || 'N/A',
    email: user?.email || '',
    phone: user?.phone || '',
    memberSince: user?.createdAt ? new Date(user.createdAt).getFullYear() : '2024',
    kycStatus: user?.kycStatus || 'pending'
  };

  // Transform backend accounts to frontend format
  const accountsData = accounts.map((acc, index) => {
    const colors = [
      'from-blue-500 to-cyan-600',
      'from-purple-500 to-pink-600',
      'from-emerald-500 to-teal-600',
      'from-orange-500 to-red-600'
    ];

    return {
      id: acc.id || index + 1,
      type: acc.accountName || acc.accountType || 'Account',
      accountNumber: acc.accountNumber ? `****-****-${acc.accountNumber.slice(-4)}` : 'XXXX-XXXX-XXXX',
      balance: acc.balance || 0,
      currency: 'USD',
      accountType: acc.accountType?.toLowerCase() || 'checking',
      status: acc.status?.toLowerCase() || 'active',
      color: colors[index % colors.length]
    };
  });

  const recentTransactions = [
    {
      id: 'TXN001',
      type: 'credit',
      description: 'Salary Deposit - ABC Corporation',
      amount: 8500.00,
      date: '2026-02-13',
      time: '09:30 AM',
      status: 'completed',
      category: 'Income',
      referenceNumber: 'REF2026021301'
    },
    {
      id: 'TXN002',
      type: 'debit',
      description: 'Rent Payment',
      amount: -2500.00,
      date: '2026-02-12',
      time: '02:15 PM',
      status: 'completed',
      category: 'Housing',
      referenceNumber: 'REF2026021202'
    },
    {
      id: 'TXN003',
      type: 'debit',
      description: 'Amazon Purchase',
      amount: -156.43,
      date: '2026-02-11',
      time: '11:20 AM',
      status: 'completed',
      category: 'Shopping',
      referenceNumber: 'REF2026021103'
    },
    {
      id: 'TXN004',
      type: 'debit',
      description: 'Electric Bill Payment',
      amount: -89.50,
      date: '2026-02-10',
      time: '04:45 PM',
      status: 'completed',
      category: 'Utilities',
      referenceNumber: 'REF2026021004'
    },
    {
      id: 'TXN005',
      type: 'credit',
      description: 'Investment Return',
      amount: 450.00,
      date: '2026-02-09',
      time: '10:00 AM',
      status: 'completed',
      category: 'Investment',
      referenceNumber: 'REF2026020905'
    }
  ];

  const quickStats = {
    totalBalance: accountsData.reduce((sum, acc) => sum + acc.balance, 0),
    monthlyIncome: 8950.00,
    monthlyExpenses: 5234.67,
    rewardPoints: 28640,
    savingsGoal: 75,
    creditScore: 780
  };

  const notifications = [
    {
      id: 1,
      type: 'warning',
      message: 'Unusual login attempt blocked',
      time: '2 hours ago',
      read: false
    },
    {
      id: 2,
      type: 'success',
      message: 'Salary credited successfully',
      time: '1 day ago',
      read: false
    },
    {
      id: 3,
      type: 'info',
      message: 'Update your KYC documents',
      time: '3 days ago',
      read: true
    }
  ];

  const quickActions = [
    { to: '/transfers', icon: Send, label: 'Transfer', gradient: 'from-blue-500 to-blue-600' },
    { to: '/bills', icon: FileText, label: 'Pay Bills', gradient: 'from-purple-500 to-purple-600' },
    { to: '/cards', icon: CreditCard, label: 'Cards', gradient: 'from-pink-500 to-pink-600' },
    { to: '/accounts', icon: Download, label: 'Deposit', gradient: 'from-emerald-500 to-emerald-600' },
    { to: '/support', icon: MapPin, label: 'ATM Locator', gradient: 'from-orange-500 to-orange-600' },
    { to: '/statements', icon: Plus, label: 'More', gradient: 'from-cyan-500 to-cyan-600' }
  ];

  return (
    <QuantumLayout title="Dashboard" subtitle={`Welcome back, ${userData.name}`}>
      {/* Hero Balance Card - Enhanced */}
      <div className="relative mb-8 overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-blue-600 via-blue-700 to-purple-800 rounded-3xl"></div>
        <div className="absolute inset-0 opacity-10">
          <div className="absolute top-0 right-0 w-96 h-96 bg-white rounded-full blur-3xl -mr-48 -mt-48"></div>
          <div className="absolute bottom-0 left-0 w-96 h-96 bg-purple-300 rounded-full blur-3xl -ml-48 -mb-48"></div>
        </div>

        <div className="relative p-8">
          <div className="flex items-start justify-between mb-8">
            <div>
              <div className="flex items-center gap-2 mb-2">
                <Sparkles size={20} className="text-yellow-300" />
                <span className="text-blue-100 text-sm font-semibold">Total Portfolio Value</span>
              </div>
              <div className="flex items-center gap-4">
                <h1 className="text-5xl font-bold text-white tracking-tight">
                  {showBalance ? `$${quickStats.totalBalance.toLocaleString('en-US', { minimumFractionDigits: 2 })}` : '••••••••'}
                </h1>
                <button
                  onClick={() => setShowBalance(!showBalance)}
                  className="p-2 hover:bg-white/10 rounded-xl transition-all duration-200"
                >
                  {showBalance ? <Eye size={24} className="text-white" /> : <EyeOff size={24} className="text-white" />}
                </button>
              </div>
              <div className="flex items-center gap-2 mt-3">
                <div className="flex items-center gap-1 px-3 py-1 bg-green-500/20 rounded-full">
                  <TrendingUp size={14} className="text-green-300" />
                  <span className="text-green-300 text-sm font-semibold">+5.2%</span>
                </div>
                <span className="text-blue-200 text-sm">vs last month</span>
              </div>
            </div>

            <button className="p-3 hover:bg-white/10 rounded-xl transition-all">
              <RefreshCw size={20} className="text-white" />
            </button>
          </div>

          <div className="grid grid-cols-3 gap-4">
            <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-5 border border-white/20">
              <div className="flex items-center gap-2 mb-2">
                <div className="w-8 h-8 bg-green-500/20 rounded-lg flex items-center justify-center">
                  <ArrowDownLeft size={16} className="text-green-300" />
                </div>
                <span className="text-blue-100 text-sm font-medium">Income</span>
              </div>
              <p className="text-2xl font-bold text-white mb-1">${quickStats.monthlyIncome.toLocaleString()}</p>
              <p className="text-xs text-blue-200">This month</p>
            </div>

            <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-5 border border-white/20">
              <div className="flex items-center gap-2 mb-2">
                <div className="w-8 h-8 bg-red-500/20 rounded-lg flex items-center justify-center">
                  <ArrowUpRight size={16} className="text-red-300" />
                </div>
                <span className="text-blue-100 text-sm font-medium">Expenses</span>
              </div>
              <p className="text-2xl font-bold text-white mb-1">${quickStats.monthlyExpenses.toLocaleString()}</p>
              <p className="text-xs text-blue-200">This month</p>
            </div>

            <div className="bg-white/10 backdrop-blur-sm rounded-2xl p-5 border border-white/20">
              <div className="flex items-center gap-2 mb-2">
                <div className="w-8 h-8 bg-purple-500/20 rounded-lg flex items-center justify-center">
                  <DollarSign size={16} className="text-purple-300" />
                </div>
                <span className="text-blue-100 text-sm font-medium">Savings</span>
              </div>
              <p className="text-2xl font-bold text-white mb-1">${(quickStats.monthlyIncome - quickStats.monthlyExpenses).toLocaleString()}</p>
              <div className="flex items-center gap-2 mt-2">
                <div className="flex-1 h-1.5 bg-white/20 rounded-full overflow-hidden">
                  <div className="h-full bg-gradient-to-r from-green-400 to-emerald-400 rounded-full" style={{ width: `${quickStats.savingsGoal}%` }}></div>
                </div>
                <span className="text-xs text-blue-200">{quickStats.savingsGoal}%</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Quick Actions - Enhanced */}
      <div className="mb-8">
        <h3 className="text-lg font-bold text-slate-800 mb-4 flex items-center gap-2">
          <div className="w-1 h-6 bg-gradient-to-b from-blue-600 to-purple-600 rounded-full"></div>
          Quick Actions
        </h3>
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
          {quickActions.map((action) => (
            <Link
              key={action.to}
              to={action.to}
              className="group relative overflow-hidden bg-white rounded-2xl p-6 border border-slate-200 hover:border-blue-300 hover:shadow-xl transition-all duration-300"
            >
              <div className="relative z-10">
                <div className={`w-14 h-14 bg-gradient-to-br ${action.gradient} rounded-2xl flex items-center justify-center mb-4 group-hover:scale-110 transition-transform duration-300 shadow-lg`}>
                  <action.icon size={24} className="text-white" />
                </div>
                <span className="text-sm font-semibold text-slate-700 group-hover:text-slate-900">{action.label}</span>
              </div>
              <div className={`absolute inset-0 bg-gradient-to-br ${action.gradient} opacity-0 group-hover:opacity-5 transition-opacity duration-300`}></div>
            </Link>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
        {/* Accounts Section - Enhanced */}
        <div className="lg:col-span-2">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-bold text-slate-800 flex items-center gap-2">
              <div className="w-1 h-6 bg-gradient-to-b from-blue-600 to-purple-600 rounded-full"></div>
              My Accounts
            </h3>
            <div className="flex items-center gap-3">
              <button
                onClick={() => setShowCreateModal(true)}
                className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-lg hover:from-blue-700 hover:to-indigo-700 transition-all shadow-md hover:shadow-lg"
              >
                <Plus size={16} />
                <span className="text-sm font-semibold">New Account</span>
              </button>
              <button
                onClick={refetch}
                className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
                title="Refresh accounts"
              >
                <RefreshCw size={16} className="text-slate-600" />
              </button>
              <Link to="/accounts" className="text-sm text-blue-600 font-semibold hover:text-blue-700 flex items-center gap-1 group">
                View All
                <ArrowUpRight size={16} className="group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
              </Link>
            </div>
          </div>

          <div className="grid gap-4">
            {accountsData.map((account) => (
              <div key={account.id} className="group relative overflow-hidden bg-white rounded-2xl border border-slate-200 hover:border-blue-300 hover:shadow-xl transition-all duration-300">
                <div className="absolute inset-0 bg-gradient-to-br opacity-0 group-hover:opacity-100 transition-opacity duration-300" style={{ background: `linear-gradient(135deg, ${account.color.includes('blue') ? '#3b82f6' : account.color.includes('purple') ? '#a855f7' : '#10b981'}15, transparent)` }}></div>

                <div className="relative p-6">
                  <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center gap-4">
                      <div className={`w-14 h-14 bg-gradient-to-br ${account.color} rounded-2xl flex items-center justify-center shadow-lg`}>
                        <Wallet size={24} className="text-white" />
                      </div>
                      <div>
                        <h4 className="font-bold text-slate-800 text-lg">{account.type}</h4>
                        <p className="text-sm text-slate-500 font-mono">{account.accountNumber}</p>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-xs text-slate-500 mb-1">Available Balance</p>
                      <p className="text-2xl font-bold text-slate-800">
                        {showBalance ? `$${account.balance.toLocaleString('en-US', { minimumFractionDigits: 2 })}` : '••••••'}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center justify-between pt-4 border-t border-slate-100">
                    {account.interestRate && (
                      <div className="flex items-center gap-2">
                        <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                        <span className="text-sm text-slate-600">Interest Rate:</span>
                        <span className="text-sm font-bold text-green-600">{account.interestRate}% p.a.</span>
                      </div>
                    )}
                    {account.maturityDate && (
                      <div className="flex items-center gap-2 text-sm">
                        <Calendar size={14} className="text-slate-400" />
                        <span className="text-slate-600">Matures: {new Date(account.maturityDate).toLocaleDateString()}</span>
                      </div>
                    )}
                    <Link to="/accounts" className="text-sm text-blue-600 font-semibold hover:text-blue-700 opacity-0 group-hover:opacity-100 transition-opacity">
                      View Details →
                    </Link>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Insights Card - New */}
        <div className="space-y-6">
          {/* Credit Score */}
          <div className="bg-gradient-to-br from-slate-900 to-slate-800 rounded-2xl p-6 text-white relative overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 bg-blue-500/20 rounded-full blur-3xl"></div>
            <div className="relative">
              <div className="flex items-center justify-between mb-4">
                <span className="text-slate-300 text-sm font-medium">Credit Score</span>
                <div className="w-8 h-8 bg-white/10 rounded-lg flex items-center justify-center">
                  <TrendingUp size={16} className="text-green-400" />
                </div>
              </div>
              <div className="mb-4">
                <h3 className="text-5xl font-bold mb-2">{quickStats.creditScore}</h3>
                <div className="flex items-center gap-2">
                  <div className="px-3 py-1 bg-green-500/20 rounded-full">
                    <span className="text-green-300 text-xs font-semibold">Excellent</span>
                  </div>
                  <span className="text-slate-400 text-xs">+12 this month</span>
                </div>
              </div>
              <div className="w-full h-2 bg-white/10 rounded-full overflow-hidden">
                <div className="h-full bg-gradient-to-r from-green-400 to-emerald-400 rounded-full" style={{ width: '78%' }}></div>
              </div>
            </div>
          </div>

          {/* Rewards */}
          <div className="bg-gradient-to-br from-purple-500 to-pink-600 rounded-2xl p-6 text-white relative overflow-hidden">
            <div className="absolute top-0 right-0 w-32 h-32 bg-white/10 rounded-full blur-3xl"></div>
            <div className="relative">
              <div className="flex items-center justify-between mb-4">
                <span className="text-purple-100 text-sm font-medium">Reward Points</span>
                <Sparkles size={20} className="text-yellow-300" />
              </div>
              <h3 className="text-4xl font-bold mb-2">{quickStats.rewardPoints.toLocaleString()}</h3>
              <p className="text-purple-100 text-sm mb-4">Available to redeem</p>
              <button className="w-full py-3 bg-white/20 hover:bg-white/30 rounded-xl font-semibold transition-colors backdrop-blur-sm">
                Redeem Now
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Recent Transactions - Enhanced */}
      <div className="mb-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-bold text-slate-800 flex items-center gap-2">
            <div className="w-1 h-6 bg-gradient-to-b from-blue-600 to-purple-600 rounded-full"></div>
            Recent Transactions
          </h3>
          <Link to="/transactions" className="text-sm text-blue-600 font-semibold hover:text-blue-700 flex items-center gap-1 group">
            View All
            <ArrowUpRight size={16} className="group-hover:translate-x-0.5 group-hover:-translate-y-0.5 transition-transform" />
          </Link>
        </div>

        <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden hover:shadow-xl transition-shadow duration-300">
          {recentTransactions.slice(0, 5).map((transaction, index) => (
            <div key={transaction.id} className={`flex items-center justify-between p-5 hover:bg-slate-50 transition-colors cursor-pointer group ${index !== 0 ? 'border-t border-slate-100' : ''}`}>
              <div className="flex items-center gap-4">
                <div className={`w-12 h-12 rounded-2xl flex items-center justify-center shadow-sm ${transaction.type === 'credit'
                  ? 'bg-gradient-to-br from-green-400 to-emerald-500'
                  : 'bg-gradient-to-br from-red-400 to-pink-500'
                  }`}>
                  {transaction.type === 'credit' ? (
                    <ArrowDownLeft size={20} className="text-white" />
                  ) : (
                    <ArrowUpRight size={20} className="text-white" />
                  )}
                </div>
                <div>
                  <p className="font-semibold text-slate-800 mb-1 group-hover:text-blue-600 transition-colors">{transaction.description}</p>
                  <div className="flex items-center gap-2">
                    <p className="text-xs text-slate-500">{transaction.date} • {transaction.time}</p>
                    <span className="px-2 py-0.5 bg-slate-100 rounded text-xs font-medium text-slate-600">
                      {transaction.category}
                    </span>
                  </div>
                </div>
              </div>
              <div className="text-right">
                <p className={`text-xl font-bold mb-1 ${transaction.type === 'credit' ? 'text-green-600' : 'text-slate-800'}`}>
                  {transaction.type === 'credit' ? '+' : ''}${Math.abs(transaction.amount).toLocaleString('en-US', { minimumFractionDigits: 2 })}
                </p>
                <div className="flex items-center gap-1 justify-end">
                  <CheckCircle size={12} className="text-green-500" />
                  <span className="text-xs text-slate-500 capitalize">{transaction.status}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Alerts and Notifications - Enhanced */}
      {notifications.filter(n => !n.read).length > 0 && (
        <div className="bg-white rounded-2xl border border-slate-200 p-6 hover:shadow-xl transition-shadow duration-300">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-bold text-slate-800 flex items-center gap-2">
              <div className="w-1 h-6 bg-gradient-to-b from-orange-500 to-red-600 rounded-full"></div>
              Important Alerts
            </h3>
            <span className="px-3 py-1 bg-red-100 text-red-600 rounded-full text-xs font-semibold">
              {notifications.filter(n => !n.read).length} New
            </span>
          </div>
          <div className="space-y-3">
            {notifications.filter(n => !n.read).map((notification) => (
              <div key={notification.id} className={`group flex items-start gap-4 p-4 rounded-xl border-2 transition-all duration-300 cursor-pointer hover:scale-[1.02] ${notification.type === 'warning' ? 'bg-orange-50/50 border-orange-200 hover:bg-orange-50 hover:border-orange-300' :
                notification.type === 'success' ? 'bg-green-50/50 border-green-200 hover:bg-green-50 hover:border-green-300' :
                  'bg-blue-50/50 border-blue-200 hover:bg-blue-50 hover:border-blue-300'
                }`}>
                <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${notification.type === 'warning' ? 'bg-orange-100' :
                  notification.type === 'success' ? 'bg-green-100' :
                    'bg-blue-100'
                  }`}>
                  {notification.type === 'warning' && <AlertCircle size={20} className="text-orange-600" />}
                  {notification.type === 'success' && <CheckCircle size={20} className="text-green-600" />}
                  {notification.type === 'info' && <Bell size={20} className="text-blue-600" />}
                </div>
                <div className="flex-1">
                  <p className="font-semibold text-slate-800 mb-1">{notification.message}</p>
                  <p className="text-xs text-slate-500">{notification.time}</p>
                </div>
                <button className="px-4 py-2 bg-white border border-slate-200 rounded-lg text-sm font-semibold hover:bg-slate-50 transition-colors opacity-0 group-hover:opacity-100">
                  View
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Create Account Modal */}
      <CreateAccountModal
        isOpen={showCreateModal}
        onClose={() => setShowCreateModal(false)}
        onSuccess={refetch}
      />
    </QuantumLayout>
  );
}