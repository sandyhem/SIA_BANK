import { useState, useEffect } from 'react';
import QuantumLayout from '../components/QuantumLayout';
import { useAuth } from '../context/AuthContext';
import { accountService } from '../services/accountService';
import { transactionService } from '../services/transactionService';
import { ArrowRight, CheckCircle, AlertCircle } from 'lucide-react';

export default function Transfers() {
    const { user, isCustomerActive } = useAuth();
    const [accounts, setAccounts] = useState([]);
    const [formData, setFormData] = useState({
        fromAccount: '',
        toAccount: '',
        amount: '',
        description: ''
    });
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState('');

    useEffect(() => {
        if (isCustomerActive && user?.id) {
            loadAccounts();
        }
    }, [isCustomerActive, user]);

    const loadAccounts = async () => {
        try {
            // Backend expects userId for this endpoint (legacy naming)
            const data = await accountService.getAccountsByCustomerId(user.id);
            setAccounts(data);
            if (data.length > 0) {
                setFormData(prev => ({ ...prev, fromAccount: data[0].accountNumber }));
            }
        } catch (err) {
            console.error('Error loading accounts:', err);
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setSuccess('');
        setLoading(true);

        try {
            // Validate sufficient balance
            const fromAcc = accounts.find(acc => acc.accountNumber === formData.fromAccount);
            if (fromAcc && parseFloat(fromAcc.balance) < parseFloat(formData.amount)) {
                setError('Insufficient balance in source account');
                setLoading(false);
                return;
            }

            await transactionService.transfer(
                formData.fromAccount,
                formData.toAccount,
                parseFloat(formData.amount),
                formData.description || 'Fund Transfer'
            );

            setSuccess('Transfer completed successfully!');
            setFormData({ ...formData, toAccount: '', amount: '', description: '' });
            await loadAccounts(); // Refresh balances
        } catch (err) {
            setError(err.response?.data?.message || err.response?.data || 'Transfer failed');
        } finally {
            setLoading(false);
        }
    };

    const selectedAccount = accounts.find(acc => acc.accountNumber === formData.fromAccount);

    return (
        <QuantumLayout title="Transfers" subtitle="Transfer money between accounts">
            <div className="max-w-3xl mx-auto">
                {/* Account Balance Card */}
                {selectedAccount && (
                    <div className="bg-gradient-to-br from-purple-600 to-indigo-600 rounded-2xl p-6 mb-6 text-white shadow-lg">
                        <div className="flex justify-between items-center">
                            <div>
                                <p className="text-purple-100 text-sm mb-1">Available Balance</p>
                                <p className="text-3xl font-bold">₹{parseFloat(selectedAccount.balance).toLocaleString('en-IN')}</p>
                                <p className="text-purple-200 text-sm mt-1">{selectedAccount.accountNumber}</p>
                            </div>
                            <div className="bg-white/20 rounded-full p-3">
                                <ArrowRight className="w-8 h-8" />
                            </div>
                        </div>
                    </div>
                )}

                {/* Transfer Form */}
                <form onSubmit={handleSubmit} className="bg-white rounded-2xl p-6 shadow-lg">
                    {error && (
                        <div className="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg flex items-center gap-2">
                            <AlertCircle className="w-5 h-5 flex-shrink-0" />
                            <span>{error}</span>
                        </div>
                    )}

                    {success && (
                        <div className="mb-4 bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg flex items-center gap-2">
                            <CheckCircle className="w-5 h-5 flex-shrink-0" />
                            <span>{success}</span>
                        </div>
                    )}

                    <div className="space-y-5">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">From Account</label>
                            <select
                                value={formData.fromAccount}
                                onChange={(e) => setFormData({ ...formData, fromAccount: e.target.value })}
                                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-600 focus:border-transparent transition-all"
                                required
                            >
                                {accounts.map(acc => (
                                    <option key={acc.id} value={acc.accountNumber}>
                                        {acc.accountNumber} - {acc.accountType} - ₹{parseFloat(acc.balance).toLocaleString('en-IN')}
                                    </option>
                                ))}
                            </select>
                            {accounts.length === 0 && (
                                <p className="text-sm text-gray-500 mt-1">No accounts available</p>
                            )}
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">To Account Number</label>
                            <input
                                type="text"
                                value={formData.toAccount}
                                onChange={(e) => setFormData({ ...formData, toAccount: e.target.value })}
                                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-600 focus:border-transparent transition-all"
                                placeholder="Enter recipient account number"
                                required
                            />
                            <p className="text-sm text-gray-500 mt-1">Enter the 10-digit account number</p>
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">Amount</label>
                            <div className="relative">
                                <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 font-medium">₹</span>
                                <input
                                    type="number"
                                    step="0.01"
                                    min="0.01"
                                    value={formData.amount}
                                    onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
                                    className="w-full pl-8 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-600 focus:border-transparent transition-all"
                                    placeholder="0.00"
                                    required
                                />
                            </div>
                            {selectedAccount && formData.amount && (
                                <p className={`text-sm mt-1 ${parseFloat(formData.amount) > parseFloat(selectedAccount.balance) ? 'text-red-600' : 'text-gray-500'}`}>
                                    {parseFloat(formData.amount) > parseFloat(selectedAccount.balance)
                                        ? '⚠️ Amount exceeds available balance'
                                        : `Remaining balance: ₹${(parseFloat(selectedAccount.balance) - parseFloat(formData.amount)).toLocaleString('en-IN')}`
                                    }
                                </p>
                            )}
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">Description (Optional)</label>
                            <input
                                type="text"
                                value={formData.description}
                                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                                className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-600 focus:border-transparent transition-all"
                                placeholder="e.g., Payment for services, Gift, etc."
                                maxLength={100}
                            />
                        </div>

                        <div className="pt-4">
                            <button
                                type="submit"
                                disabled={loading || accounts.length === 0}
                                className="w-full px-6 py-4 bg-gradient-to-r from-purple-600 to-indigo-600 text-white rounded-lg hover:from-purple-700 hover:to-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed font-medium text-lg shadow-lg hover:shadow-xl transition-all transform hover:-translate-y-0.5"
                            >
                                {loading ? (
                                    <span className="flex items-center justify-center gap-2">
                                        <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                                        Processing Transfer...
                                    </span>
                                ) : (
                                    <span className="flex items-center justify-center gap-2">
                                        <ArrowRight className="w-5 h-5" />
                                        Transfer Money
                                    </span>
                                )}
                            </button>
                        </div>
                    </div>
                </form>

                {/* Quick Tips */}
                <div className="mt-6 bg-blue-50 border border-blue-200 rounded-lg p-4">
                    <h3 className="font-semibold text-blue-900 mb-2">💡 Quick Tips</h3>
                    <ul className="text-sm text-blue-800 space-y-1">
                        <li>• Transfers are processed instantly</li>
                        <li>• Ensure the recipient account number is correct before submitting</li>
                        <li>• You can track all transfers in the Transactions page</li>
                        <li>• Minimum transfer amount is ₹0.01</li>
                    </ul>
                </div>
            </div>
        </QuantumLayout>
    );
}
