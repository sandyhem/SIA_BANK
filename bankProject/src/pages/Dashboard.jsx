import { useState, useEffect } from 'react';
import QuantumLayout from "../components/QuantumLayout";
import CreateCustomerModal from '../components/CreateCustomerModal';
import { useAuth } from '../context/AuthContext';
import { accountService } from '../services/accountService';
import { transactionService } from '../services/transactionService';
import { UserCircle, BadgeCheck, XCircle } from 'lucide-react';

export default function Dashboard() {
  const { user, customer, hasCustomerProfile, isKycVerified, isCustomerActive } = useAuth();
  const [accounts, setAccounts] = useState([]);
  const [transactions, setTransactions] = useState([]);
  const [stats, setStats] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showCustomerModal, setShowCustomerModal] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (isCustomerActive) {
      loadDashboardData();
    } else {
      setLoading(false);
    }
  }, [isCustomerActive]);

  const loadDashboardData = async () => {
    try {
      setLoading(true);

      // Load accounts
      let accountsData = [];
      if (customer?.id) {
        accountsData = await accountService.getAccountsByCustomerId(customer.id);
        setAccounts(accountsData);

        // Load transactions for the first account
        if (accountsData.length > 0) {
          const txns = await transactionService.getTransactionsByAccount(accountsData[0].accountNumber);
          setTransactions(txns.slice(0, 5)); // Show last 5 transactions
        }

        // Calculate stats
        const totalBalance = accountsData.reduce((sum, acc) => sum + parseFloat(acc.balance || 0), 0);
        const savingsAccounts = accountsData.filter(acc => acc.accountType === 'SAVINGS');
        const currentAccounts = accountsData.filter(acc => acc.accountType === 'CURRENT');

        setStats([
          { id: 1, label: 'Total Balance', value: `₹${totalBalance.toLocaleString('en-IN')}`, trend: '+12.5%' },
          { id: 2, label: 'Total Accounts', value: accountsData.length, trend: `${accountsData.length} Active` },
          { id: 3, label: 'Savings Accounts', value: savingsAccounts.length, trend: 'Available' },
          { id: 4, label: 'Current Accounts', value: currentAccounts.length, trend: 'Available' }
        ]);
      }
    } catch (err) {
      console.error('Error loading dashboard data:', err);
      setError('Failed to load dashboard data');
    } finally {
      setLoading(false);
    }
  };

  const handleCustomerCreated = () => {
    window.location.reload(); // Reload to fetch new customer data
  };

  if (!hasCustomerProfile) {
    return (
      <QuantumLayout title="Welcome" subtitle="Complete your profile to get started">
        <div className="max-w-2xl mx-auto">
          <div className="bg-gradient-to-br from-purple-50 to-indigo-50 rounded-2xl p-8 border border-purple-200">
            <div className="text-center">
              <UserCircle className="w-20 h-20 mx-auto text-purple-600 mb-4" />
              <h2 className="text-2xl font-bold text-gray-900 mb-2">Create Your Customer Profile</h2>
              <p className="text-gray-600 mb-6">
                Before you can open bank accounts, you need to create your Customer Information File (CIF).
                This is a one-time process that helps us verify your identity and comply with regulations.
              </p>

              <div className="bg-white rounded-lg p-6 mb-6 text-left">
                <h3 className="font-semibold text-gray-900 mb-3">What you'll need:</h3>
                <ul className="space-y-2 text-sm text-gray-600">
                  <li className="flex items-start">
                    <span className="text-purple-600 mr-2">•</span>
                    <span>Personal information (Name, Phone, Date of Birth)</span>
                  </li>
                  <li className="flex items-start">
                    <span className="text-purple-600 mr-2">•</span>
                    <span>Complete address details</span>
                  </li>
                  <li className="flex items-start">
                    <span className="text-purple-600 mr-2">•</span>
                    <span>PAN and Aadhaar numbers (for KYC verification)</span>
                  </li>
                </ul>
              </div>

              <button
                onClick={() => setShowCustomerModal(true)}
                className="px-8 py-3 bg-gradient-to-r from-purple-600 to-indigo-600 text-white rounded-lg hover:from-purple-700 hover:to-indigo-700 font-medium transition shadow-lg"
              >
                Create Customer Profile
              </button>
            </div>
          </div>
        </div>

        <CreateCustomerModal
          isOpen={showCustomerModal}
          onClose={() => setShowCustomerModal(false)}
          onSuccess={handleCustomerCreated}
        />
      </QuantumLayout>
    );
  }

  if (!isKycVerified) {
    return (
      <QuantumLayout title="KYC Pending" subtitle="Your profile is under verification">
        <div className="max-w-2xl mx-auto">
          <div className="bg-gradient-to-br from-amber-50 to-orange-50 rounded-2xl p-8 border border-amber-200">
            <div className="text-center">
              <XCircle className="w-20 h-20 mx-auto text-amber-600 mb-4" />
              <h2 className="text-2xl font-bold text-gray-900 mb-2">KYC Verification Pending</h2>
              <p className="text-gray-600 mb-6">
                Your customer profile has been created successfully! Our team is currently reviewing your
                KYC documents. You'll be able to open accounts once the verification is complete.
              </p>

              <div className="bg-white rounded-lg p-6 text-left">
                <h3 className="font-semibold text-gray-900 mb-3">Your Profile Details:</h3>
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <p className="text-gray-500">CIF Number</p>
                    <p className="font-medium text-gray-900">{customer?.cifNumber}</p>
                  </div>
                  <div>
                    <p className="text-gray-500">Full Name</p>
                    <p className="font-medium text-gray-900">{customer?.fullName}</p>
                  </div>
                  <div>
                    <p className="text-gray-500">KYC Status</p>
                    <p className="font-medium text-amber-600">{customer?.kycStatus}</p>
                  </div>
                  <div>
                    <p className="text-gray-500">Customer Status</p>
                    <p className="font-medium text-gray-900">{customer?.customerStatus}</p>
                  </div>
                </div>
              </div>

              <p className="mt-6 text-sm text-gray-500">
                Verification usually takes 24-48 hours. You'll receive a notification once it's complete.
              </p>
            </div>
          </div>
        </div>
      </QuantumLayout>
    );
  }

  if (loading) {
    return (
      <QuantumLayout title="Overview" subtitle="Loading your dashboard...">
        <div className="flex items-center justify-center h-64">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600"></div>
        </div>
      </QuantumLayout>
    );
  }

  return (
    <QuantumLayout
      title="Overview"
      subtitle="A snapshot of your current financial position."
    >
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold text-slate-900">Account overview</h1>
          <p className="text-sm text-slate-500">
            Welcome back, {customer?.fullName}! CIF: {customer?.cifNumber}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
            <BadgeCheck className="w-4 h-4 mr-1" />
            KYC Verified
          </span>
        </div>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
          {error}
        </div>
      )}

      <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {stats.map((item) => (
          <div key={item.id} className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <p className="text-sm text-slate-500">{item.label}</p>
            <div className="mt-2 flex items-end justify-between">
              <span className="text-2xl font-semibold text-slate-900">{item.value}</span>
              <span className="rounded-full bg-emerald-50 px-2 py-1 text-xs font-semibold text-emerald-600">
                {item.trend}
              </span>
            </div>
          </div>
        ))}
      </section>

      {accounts.length === 0 ? (
        <div className="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-2xl p-8 border border-blue-200 text-center">
          <h3 className="text-xl font-semibold text-gray-900 mb-2">No Accounts Yet</h3>
          <p className="text-gray-600 mb-4">
            You're ready to open your first bank account! Visit the Accounts page to get started.
          </p>
          <a
            href="/accounts"
            className="inline-block px-6 py-2 bg-gradient-to-r from-purple-600 to-indigo-600 text-white rounded-lg hover:from-purple-700 hover:to-indigo-700 font-medium transition"
          >
            Open Account
          </a>
        </div>
      ) : (
        <section className="grid gap-6 lg:grid-cols-[1.2fr_1fr]">
          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-semibold text-slate-900">Recent transactions</h2>
              <span className="text-sm text-slate-400">Latest activity</span>
            </div>
            <div className="mt-4 divide-y divide-slate-100">
              {transactions.length === 0 ? (
                <p className="text-center text-gray-500 py-8">No transactions yet</p>
              ) : (
                transactions.map((txn) => (
                  <div key={txn.id} className="flex items-center justify-between py-3">
                    <div>
                      <p className="text-sm font-semibold text-slate-900">{txn.description || 'Transaction'}</p>
                      <p className="text-xs text-slate-500">
                        {new Date(txn.createdAt).toLocaleDateString()} · {txn.status}
                      </p>
                    </div>
                    <p className={`text-sm font-semibold ${txn.toAccountNumber === accounts[0]?.accountNumber
                      ? "text-emerald-600"
                      : "text-slate-800"
                      }`}>
                      {txn.toAccountNumber === accounts[0]?.accountNumber ? "+" : "-"}
                      ₹{parseFloat(txn.amount).toLocaleString('en-IN')}
                    </p>
                  </div>
                ))
              )}
            </div>
          </div>
          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h2 className="text-lg font-semibold text-slate-900">Your Accounts</h2>
                <p className="text-sm text-slate-500">{accounts.length} Active {accounts.length === 1 ? 'Account' : 'Accounts'}</p>
              </div>
              <a
                href="/accounts"
                className="text-sm text-purple-600 hover:text-purple-700 font-medium"
              >
                View All →
              </a>
            </div>
            <div className="space-y-4">
              {accounts.map((account) => (
                <div key={account.id} className="rounded-xl border-2 border-slate-100 p-4 hover:border-purple-200 hover:shadow-md transition-all">
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <p className="text-sm font-bold text-slate-900">{account.accountType} Account</p>
                        <span className={`text-xs px-2 py-0.5 rounded-full ${account.accountStatus === 'ACTIVE' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                          {account.accountStatus}
                        </span>
                      </div>
                      <p className="text-xs text-slate-500 font-mono">{account.accountNumber}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-lg font-bold text-slate-900">
                        ₹{parseFloat(account.balance).toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                      </p>
                      <p className="text-xs text-slate-500">Available Balance</p>
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-3 pt-3 border-t border-slate-100">
                    <div>
                      <p className="text-xs text-slate-500">Branch</p>
                      <p className="text-xs font-semibold text-slate-700">{account.branchCode || 'N/A'}</p>
                    </div>
                    <div>
                      <p className="text-xs text-slate-500">Opened On</p>
                      <p className="text-xs font-semibold text-slate-700">
                        {account.createdAt ? new Date(account.createdAt).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }) : 'N/A'}
                      </p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
            <div className="mt-4 pt-4 border-t border-slate-100">
              <a
                href="/accounts"
                className="block w-full text-center px-4 py-2 bg-purple-50 text-purple-700 rounded-lg hover:bg-purple-100 font-medium text-sm transition"
              >
                + Open New Account
              </a>
            </div>
          </div>
        </section>
      )}
    </QuantumLayout>
  );
}

