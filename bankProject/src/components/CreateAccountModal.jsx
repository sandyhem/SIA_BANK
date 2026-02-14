import { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { accountService } from '../services/accountService';
import { X } from 'lucide-react';

export default function CreateAccountModal({ isOpen, onClose, onSuccess }) {
    const { user, customer } = useAuth();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [formData, setFormData] = useState({
        accountType: 'SAVINGS',
        branchCode: 'MAIN001',
        initialDeposit: 1000
    });

    // Debug: Log user and customer data when modal opens
    useEffect(() => {
        if (isOpen) {
            console.log('Modal opened. User:', user, 'Customer:', customer);
        }
    }, [isOpen, user, customer]);

    const handleChange = (e) => {
        setFormData({
            ...formData,
            [e.target.name]: e.target.value
        });
        setError('');
    };

    const handleSubmit = async (e) => {
        e.preventDefault();

        // Prevent double submission
        if (loading) {
            console.log('Already creating account, please wait...');
            return;
        }

        setError('');

        // Validate user data
        if (!user || !user.id) {
            setError('User not found. Please login again.');
            return;
        }

        // Validate form data
        if (!formData.initialDeposit || parseFloat(formData.initialDeposit) <= 0) {
            setError('Please enter a valid initial deposit amount.');
            return;
        }

        const depositAmount = parseFloat(formData.initialDeposit);
        const selectedType = accountTypes.find(t => t.value === formData.accountType);

        if (depositAmount < selectedType?.minBalance) {
            setError(`Minimum deposit for ${selectedType.label} is ₹${selectedType.minBalance.toLocaleString('en-IN')}`);
            return;
        }

        setLoading(true);

        try {
            const accountData = {
                userId: user.id,
                accountType: formData.accountType,
                initialBalance: depositAmount,
                accountName: `${formData.accountType} Account`
            };

            console.log('Creating account with data:', accountData);

            const newAccount = await accountService.createAccount(accountData);
            console.log('Account created successfully:', newAccount);

            // Reset form
            setFormData({
                accountType: 'SAVINGS',
                branchCode: 'MAIN001',
                initialDeposit: 1000
            });

            // Call success callback with new account data
            if (onSuccess) {
                onSuccess(newAccount);
            }

            // Close modal
            if (onClose) {
                onClose();
            }
        } catch (error) {
            console.error('Account creation error:', error);
            const errorMessage = error?.response?.data?.message
                || error?.response?.data
                || error?.message
                || 'Failed to create account. Please try again.';
            setError(errorMessage);
        } finally {
            setLoading(false);
        }
    };

    if (!isOpen) return null;

    const accountTypes = [
        {
            value: 'SAVINGS',
            label: 'Savings Account',
            description: 'Earn interest on your deposits',
            minBalance: 1000
        },
        {
            value: 'CURRENT',
            label: 'Current Account',
            description: 'For business transactions',
            minBalance: 5000
        }
    ];

    const selectedAccountType = accountTypes.find(t => t.value === formData.accountType);

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
            <div className="bg-white rounded-2xl shadow-2xl max-w-lg w-full">
                <div className="bg-gradient-to-r from-purple-600 to-indigo-600 p-6 flex items-center justify-between rounded-t-2xl">
                    <h2 className="text-2xl font-bold text-white">Open New Account</h2>
                    <button onClick={onClose} className="text-white hover:bg-white/20 rounded-lg p-2">
                        <X className="w-6 h-6" />
                    </button>
                </div>

                <form onSubmit={handleSubmit} className="p-6">
                    {error && (
                        <div className="mb-4 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">{error}</div>
                    )}

                    <div className="mb-4">
                        <label className="block text-sm font-medium text-gray-700 mb-2">Account Type</label>
                        {accountTypes.map((type) => (
                            <label key={type.value} className={`block p-3 border-2 rounded-lg cursor-pointer mb-2 ${formData.accountType === type.value ? 'border-purple-600 bg-purple-50' : 'border-gray-200'}`}>
                                <input type="radio" name="accountType" value={type.value} checked={formData.accountType === type.value} onChange={handleChange} className="sr-only" />
                                <p className="font-semibold">{type.label}</p>
                                <p className="text-sm text-gray-600">{type.description}</p>
                            </label>
                        ))}
                    </div>

                    <div className="grid grid-cols-2 gap-4 mb-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Branch Code</label>
                            <select name="branchCode" value={formData.branchCode} onChange={handleChange} className="w-full px-4 py-2 border rounded-lg">
                                <option value="MAIN001">Main Branch</option>
                                <option value="EAST002">East Branch</option>
                            </select>
                        </div>
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">
                                Initial Deposit <span className="text-red-500">*</span>
                            </label>
                            <input
                                type="number"
                                name="initialDeposit"
                                min={selectedAccountType?.minBalance}
                                step="0.01"
                                value={formData.initialDeposit}
                                onChange={handleChange}
                                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-600 focus:border-transparent"
                                required
                                placeholder={`Min: ₹${selectedAccountType?.minBalance || 1000}`}
                            />
                            <p className="text-xs text-gray-500 mt-1">
                                Minimum: ₹{selectedAccountType?.minBalance?.toLocaleString('en-IN')}
                            </p>
                        </div>
                    </div>

                    <div className="flex gap-4">
                        <button type="button" onClick={onClose} className="flex-1 px-6 py-3 border border-gray-300 rounded-lg hover:bg-gray-50 font-medium">Cancel</button>
                        <button
                            type="submit"
                            disabled={loading}
                            className="flex-1 px-6 py-3 bg-gradient-to-r from-purple-600 to-indigo-600 text-white rounded-lg hover:from-purple-700 hover:to-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed font-medium"
                        >
                            {loading ? (
                                <span className="flex items-center justify-center gap-2">
                                    <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                                    Creating...
                                </span>
                            ) : (
                                'Open Account'
                            )}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}
