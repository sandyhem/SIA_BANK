import { useState, useEffect } from 'react';
import QuantumLayout from '../components/QuantumLayout';
import CreateAccountModal from '../components/CreateAccountModal';
import { useAuth } from '../context/AuthContext';
import { accountService } from '../services/accountService';
import { Plus, Banknote, Eye, EyeOff } from 'lucide-react';

export default function Accounts() {
    const { user, customer, isCustomerActive } = useAuth();
    const [accounts, setAccounts] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showCreateModal, setShowCreateModal] = useState(false);
    const [showBalances, setShowBalances] = useState(true);
    const [error, setError] = useState('');
    const [successMessage, setSuccessMessage] = useState('');

    useEffect(() => {
        if (isCustomerActive && user?.id) {
            loadAccounts();
        } else {
            setLoading(false);
        }
    }, [isCustomerActive, user]);

    const loadAccounts = async () => {
        try {
            setLoading(true);
            setError('');
            // Backend expects userId in /customer/{id} (legacy naming)
            const data = await accountService.getAccountsByCustomerId(user.id);
            setAccounts(data);
            console.log('Loaded accounts:', data);
        } catch (err) {
            console.error('Error loading accounts:', err);
            setError(err.response?.data?.message || 'Failed to load accounts');
        } finally {
            setLoading(false);
        }
    };

    const handleAccountCreated = (newAccount) => {
        console.log('Account created, reloading accounts...');
        setShowCreateModal(false);
        setSuccessMessage(`Account ${newAccount.accountNumber} created successfully!`);
        loadAccounts(); // Reload accounts list

        // Clear success message after 5 seconds
        setTimeout(() => {
            setSuccessMessage('');
        }, 5000);
    };

    if (!isCustomerActive) {
        return (
            <QuantumLayout title="Accounts" subtitle="Manage your bank accounts">
                <div className="bg-yellow-50 border border-yellow-200 text-yellow-800 px-6 py-4 rounded-lg">
                    <p className="font-medium">Profile Incomplete</p>
                    <p className="text-sm mt-1">
                        Please complete your customer profile and KYC verification before opening accounts.
                    </p>
                </div>
            </QuantumLayout>
        );
    }

    if (loading) {
        return (
            <QuantumLayout title="Accounts" subtitle="Loading your accounts...">
                <div className="flex items-center justify-center h-64">
                    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600"></div>
                </div>
            </QuantumLayout>
        );
    }

    return (
        <QuantumLayout title="Accounts" subtitle="Manage your bank accounts">
            <div className="flex items-center justify-between mb-6">
                <div>
                    <h2 className="text-2xl font-bold text-gray-900">Your Accounts</h2>
                    <p className="text-sm text-gray-500">Manage and monitor all your accounts</p>
                </div>
                <div className="flex gap-3">
                    <button
                        onClick={() => setShowBalances(!showBalances)}
                        className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 flex items-center gap-2"
                    >
                        {showBalances ? (
                            <>
                                <EyeOff className="w-5 h-5" />
                                Hide Balances
                            </>
                        ) : (
                            <>
                                <Eye className="w-5 h-5" />
                                Show Balances
                            </>
                        )}
                    </button>
                    <button
                        onClick={() => setShowCreateModal(true)}
                        className="px-6 py-2 bg-gradient-to-r from-purple-600 to-indigo-600 text-white rounded-lg hover:from-purple-700 hover:to-indigo-700 flex items-center gap-2"
                    >
                        <Plus className="w-5 h-5" />
                        Open New Account
                    </button>
                </div>
            </div>

            {error && (
                <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg mb-6">
                    {error}
                </div>
            )}

            {successMessage && (
                <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg mb-6 flex items-center gap-2">
                    <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                    </svg>
                    {successMessage}
                </div>
            )}

            {accounts.length === 0 ? (
                <div className="bg-gradient-to-br from-purple-50 to-indigo-50 rounded-2xl p-12 border border-purple-200 text-center">
                    <Banknote className="w-20 h-20 mx-auto text-purple-600 mb-4" />
                    <h3 className="text-2xl font-bold text-gray-900 mb-2">No Accounts Yet</h3>
                    <p className="text-gray-600 mb-6 max-w-md mx-auto">
                        Open your first bank account to start managing your finances.
                        Choose from Savings, Current, or Fixed Deposit accounts.
                    </p>
                    <button
                        onClick={() => setShowCreateModal(true)}
                        className="px-8 py-3 bg-gradient-to-r from-purple-600 to-indigo-600 text-white rounded-lg hover:from-purple-700 hover:to-indigo-700 font-medium"
                    >
                        Open Your First Account
                    </button>
                </div>
            ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {accounts.map((account) => (
                        <div
                            key={account.id}
                            className="bg-gradient-to-br from-white to-gray-50 rounded-2xl p-6 border border-gray-200 hover:shadow-lg transition"
                        >
                            <div className="flex items-center justify-between mb-4">
                                <div className="px-3 py-1 bg-purple-100 text-purple-700 rounded-full text-sm font-medium">
                                    {account.accountType}
                                </div>
                                <div className={`px-3 py-1 rounded-full text-sm font-medium ${account.accountStatus === 'ACTIVE'
                                    ? 'bg-green-100 text-green-700'
                                    : 'bg-red-100 text-red-700'
                                    }`}>
                                    {account.accountStatus}
                                </div>
                            </div>

                            <div className="mb-4">
                                <p className="text-sm text-gray-500 mb-1">Account Number</p>
                                <p className="text-lg font-mono font-semibold text-gray-900">
                                    {account.accountNumber}
                                </p>
                            </div>

                            <div className="mb-4">
                                <p className="text-sm text-gray-500 mb-1">Current Balance</p>
                                <p className="text-3xl font-bold text-gray-900">
                                    {showBalances
                                        ? `₹${parseFloat(account.balance).toLocaleString('en-IN', { minimumFractionDigits: 2 })}`
                                        : '••••••'}
                                </p>
                            </div>

                            <div className="grid grid-cols-2 gap-4 pt-4 border-t border-gray-200">
                                <div>
                                    <p className="text-xs text-gray-500">Branch Code</p>
                                    <p className="text-sm font-medium text-gray-900">{account.branchCode || 'N/A'}</p>
                                </div>
                                <div>
                                    <p className="text-xs text-gray-500">IFSC Code</p>
                                    <p className="text-sm font-medium text-gray-900">{account.ifscCode || 'N/A'}</p>
                                </div>
                            </div>

                            <button className="w-full mt-4 px-4 py-2 bg-purple-50 text-purple-700 rounded-lg hover:bg-purple-100 font-medium transition">
                                View Details
                            </button>
                        </div>
                    ))}
                </div>
            )}

            <CreateAccountModal
                isOpen={showCreateModal}
                onClose={() => setShowCreateModal(false)}
                onSuccess={handleAccountCreated}
            />
        </QuantumLayout>
    );
}
