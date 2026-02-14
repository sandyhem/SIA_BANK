import React, { useState, useEffect } from 'react';
import QuantumLayout from '../components/QuantumLayout';
import Toast from '../components/Toast';
import { useAccounts } from '../hooks/useData';
import { transactionService } from '../services/transactionService';
import {
  Send,
  User,
  Building2,
  Globe,
  Plus,
  ArrowRight,
  Check,
  AlertCircle,
  Clock,
  RefreshCw
} from 'lucide-react';

export default function Transfers() {
  const [transferType, setTransferType] = useState('internal');
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState({
    fromAccount: '',
    toAccount: '',
    amount: '',
    description: ''
  });
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState(null);
  const { accounts, loading: accountsLoading, refetch } = useAccounts();

  // Mock recent transfers data
  const recentTransfers = [
    { id: 1, recipient: 'John Smith', date: 'Feb 12, 2026', amount: 250.00 },
    { id: 2, recipient: 'Sarah Johnson', date: 'Feb 10, 2026', amount: 150.00 },
    { id: 3, recipient: 'Mike Davis', date: 'Feb 8, 2026', amount: 500.00 }
  ];

  const showToast = (message, type = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 5000);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (step < 2) {
      setStep(step + 1);
      return;
    }

    // Step 2: Confirm and submit
    setLoading(true);
    try {
      await transactionService.transfer({
        fromAccount: formData.fromAccount,
        toAccount: formData.toAccount,
        amount: parseFloat(formData.amount),
        description: formData.description || 'Transfer'
      });

      showToast('Transfer completed successfully!', 'success');

      // Reset form
      setFormData({
        fromAccount: '',
        toAccount: '',
        amount: '',
        description: ''
      });
      setStep(1);

      // Refresh accounts to show updated balances
      setTimeout(() => refetch(), 1000);
    } catch (error) {
      showToast(error.response?.data?.message || 'Transfer failed. Please try again.', 'error');
    } finally {
      setLoading(false);
    }
  };

  return (
    <QuantumLayout title="Transfers" subtitle="Send money quickly and securely">
      <div className="p-6">
        {/* Header */}
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-slate-800 mb-2">Transfer Money</h1>
          <p className="text-slate-600">Send money quickly and securely</p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Main Transfer Form */}
          <div className="lg:col-span-2">
            {/* Transfer Type Selection */}
            <div className="bg-white rounded-xl border border-slate-200 p-6 mb-6">
              <h2 className="text-lg font-bold text-slate-800 mb-4">Transfer Type</h2>
              <div className="grid grid-cols-3 gap-4">
                <button
                  onClick={() => setTransferType('internal')}
                  className={`p-4 rounded-xl border-2 transition-all ${transferType === 'internal'
                    ? 'border-blue-600 bg-blue-50'
                    : 'border-slate-200 hover:border-slate-300'
                    }`}
                >
                  <div className={`w-12 h-12 rounded-lg flex items-center justify-center mb-3 mx-auto ${transferType === 'internal' ? 'bg-blue-100' : 'bg-slate-100'
                    }`}>
                    <User size={24} className={transferType === 'internal' ? 'text-blue-600' : 'text-slate-600'} />
                  </div>
                  <p className="font-semibold text-slate-800 text-center">Own Account</p>
                  <p className="text-xs text-slate-500 text-center mt-1">Between your accounts</p>
                </button>

                <button
                  onClick={() => setTransferType('domestic')}
                  className={`p-4 rounded-xl border-2 transition-all ${transferType === 'domestic'
                    ? 'border-blue-600 bg-blue-50'
                    : 'border-slate-200 hover:border-slate-300'
                    }`}
                >
                  <div className={`w-12 h-12 rounded-lg flex items-center justify-center mb-3 mx-auto ${transferType === 'domestic' ? 'bg-blue-100' : 'bg-slate-100'
                    }`}>
                    <Building2 size={24} className={transferType === 'domestic' ? 'text-blue-600' : 'text-slate-600'} />
                  </div>
                  <p className="font-semibold text-slate-800 text-center">Domestic</p>
                  <p className="text-xs text-slate-500 text-center mt-1">To other banks</p>
                </button>

                <button
                  onClick={() => setTransferType('international')}
                  className={`p-4 rounded-xl border-2 transition-all ${transferType === 'international'
                    ? 'border-blue-600 bg-blue-50'
                    : 'border-slate-200 hover:border-slate-300'
                    }`}
                >
                  <div className={`w-12 h-12 rounded-lg flex items-center justify-center mb-3 mx-auto ${transferType === 'international' ? 'bg-blue-100' : 'bg-slate-100'
                    }`}>
                    <Globe size={24} className={transferType === 'international' ? 'text-blue-600' : 'text-slate-600'} />
                  </div>
                  <p className="font-semibold text-slate-800 text-center">International</p>
                  <p className="text-xs text-slate-500 text-center mt-1">Worldwide transfer</p>
                </button>
              </div>
            </div>

            {/* Transfer Form */}
            <div className="bg-white rounded-xl border border-slate-200 p-6">
              {/* Progress Steps */}
              <div className="flex items-center justify-between mb-8">
                {[1, 2, 3].map((s) => (
                  <React.Fragment key={s}>
                    <div className="flex flex-col items-center">
                      <div className={`w-10 h-10 rounded-full flex items-center justify-center font-semibold ${step >= s ? 'bg-blue-600 text-white' : 'bg-slate-200 text-slate-500'
                        }`}>
                        {step > s ? <Check size={20} /> : s}
                      </div>
                      <p className="text-xs mt-2 font-medium text-slate-600">
                        {s === 1 ? 'Details' : s === 2 ? 'Review' : 'Confirm'}
                      </p>
                    </div>
                    {s < 3 && (
                      <div className={`flex-1 h-0.5 mx-4 ${step > s ? 'bg-blue-600' : 'bg-slate-200'}`} />
                    )}
                  </React.Fragment>
                ))}
              </div>

              <form onSubmit={handleSubmit}>
                {step === 1 && (
                  <div className="space-y-6">
                    <h3 className="text-xl font-bold text-slate-800">Transfer Details</h3>

                    {/* From Account */}
                    <div>
                      <label className="block text-sm font-semibold text-slate-700 mb-2">
                        From Account
                      </label>
                      <select
                        value={formData.fromAccount}
                        onChange={(e) => setFormData({ ...formData, fromAccount: e.target.value })}
                        className="w-full px-4 py-3 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                        required
                        disabled={accountsLoading}
                      >
                        <option value="">Select account</option>
                        {accounts.map((account) => (
                          <option key={account.accountNumber} value={account.accountNumber}>
                            {account.accountName || account.accountType || 'Account'} - {account.accountNumber} (${account.balance.toLocaleString()})
                          </option>
                        ))}
                      </select>
                      {accounts.length === 0 && !accountsLoading && (
                        <p className="mt-2 text-sm text-amber-600">No accounts found. Please create an account first.</p>
                      )}
                    </div>

                    {/* To Account/Beneficiary */}
                    {transferType === 'internal' ? (
                      <div>
                        <label className="block text-sm font-semibold text-slate-700 mb-2">
                          To Account
                        </label>
                        <select
                          value={formData.toAccount}
                          onChange={(e) => setFormData({ ...formData, toAccount: e.target.value })}
                          className="w-full px-4 py-3 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                          required
                          disabled={accountsLoading}
                        >
                          <option value="">Select account</option>
                          {accounts
                            .filter(acc => acc.accountNumber !== formData.fromAccount)
                            .map((account) => (
                              <option key={account.accountNumber} value={account.accountNumber}>
                                {account.accountName || account.accountType || 'Account'} - {account.accountNumber}
                              </option>
                            ))}
                        </select>
                      </div>
                    ) : (
                      <div>
                        <label className="block text-sm font-semibold text-slate-700 mb-2">
                          Recipient Account Number
                        </label>
                        <input
                          type="text"
                          value={formData.toAccount}
                          onChange={(e) => setFormData({ ...formData, toAccount: e.target.value })}
                          className="w-full px-4 py-3 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                          placeholder="Enter account number"
                          required
                        />
                      </div>
                    )}

                    {/* Amount */}
                    <div>
                      <label className="block text-sm font-semibold text-slate-700 mb-2">
                        Amount
                      </label>
                      <div className="relative">
                        <span className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500 font-semibold">
                          $
                        </span>
                        <input
                          type="number"
                          value={formData.amount}
                          onChange={(e) => setFormData({ ...formData, amount: e.target.value })}
                          className="w-full pl-8 pr-4 py-3 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                          placeholder="0.00"
                          step="0.01"
                          required
                        />
                      </div>
                    </div>

                    {/* Remarks */}
                    <div>
                      <label className="block text-sm font-semibold text-slate-700 mb-2">
                        Remarks (Optional)
                      </label>
                      <textarea
                        value={formData.remarks}
                        onChange={(e) => setFormData({ ...formData, remarks: e.target.value })}
                        className="w-full px-4 py-3 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                        rows="3"
                        placeholder="Add a note..."
                      />
                    </div>
                  </div>
                )}

                {step === 2 && (
                  <div className="space-y-6">
                    <h3 className="text-xl font-bold text-slate-800">Review Transfer</h3>

                    <div className="bg-slate-50 rounded-lg p-6 space-y-4">
                      <div className="flex justify-between">
                        <span className="text-slate-600">From</span>
                        <span className="font-semibold text-slate-800">
                          {accounts.find(a => a.accountNumber === formData.fromAccount)?.accountName ||
                            accounts.find(a => a.accountNumber === formData.fromAccount)?.accountNumber ||
                            'Account'}
                        </span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-slate-600">To</span>
                        <span className="font-semibold text-slate-800">
                          {transferType === 'internal'
                            ? (accounts.find(a => a.accountNumber === formData.toAccount)?.accountName ||
                              accounts.find(a => a.accountNumber === formData.toAccount)?.accountNumber ||
                              'Account')
                            : formData.toAccount}
                        </span>
                      </div>
                      <div className="flex justify-between border-t border-slate-200 pt-4">
                        <span className="text-slate-600">Amount</span>
                        <span className="text-2xl font-bold text-slate-800">${formData.amount}</span>
                      </div>
                      {formData.remarks && (
                        <div className="flex justify-between">
                          <span className="text-slate-600">Remarks</span>
                          <span className="font-semibold text-slate-800">{formData.remarks}</span>
                        </div>
                      )}
                    </div>

                    <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 flex items-start gap-3">
                      <AlertCircle size={20} className="text-blue-600 flex-shrink-0 mt-0.5" />
                      <div>
                        <p className="font-semibold text-blue-900 mb-1">Please verify</p>
                        <p className="text-sm text-blue-700">
                          Make sure all details are correct before proceeding. This action cannot be undone.
                        </p>
                      </div>
                    </div>
                  </div>
                )}

                {step === 3 && (
                  <div className="text-center py-8">
                    <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6">
                      <Check size={40} className="text-green-600" />
                    </div>
                    <h3 className="text-2xl font-bold text-slate-800 mb-2">Transfer Successful!</h3>
                    <p className="text-slate-600 mb-6">Your transfer has been processed successfully</p>

                    <div className="bg-slate-50 rounded-lg p-6 mb-6">
                      <p className="text-sm text-slate-600 mb-1">Amount Transferred</p>
                      <p className="text-3xl font-bold text-slate-800 mb-4">${formData.amount}</p>
                      <p className="text-xs text-slate-500">Reference: REF2026021408</p>
                    </div>
                  </div>
                )}

                {/* Actions */}
                <div className="flex gap-3 mt-6">
                  {step > 1 && step < 3 && (
                    <button
                      type="button"
                      onClick={() => setStep(step - 1)}
                      className="flex-1 py-3 px-6 border border-slate-200 rounded-lg font-semibold hover:bg-slate-50 transition-colors"
                    >
                      Back
                    </button>
                  )}
                  <button
                    type="submit"
                    className="flex-1 py-3 px-6 bg-blue-600 text-white rounded-lg font-semibold hover:bg-blue-700 transition-colors flex items-center justify-center gap-2"
                  >
                    {step === 3 ? 'Make Another Transfer' : step === 2 ? 'Confirm Transfer' : 'Continue'}
                    {step < 3 && <ArrowRight size={20} />}
                  </button>
                </div>
              </form>
            </div>
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            {/* Quick Transfer Accounts */}
            <div className="bg-white rounded-xl border border-slate-200 p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="font-bold text-slate-800">Quick Transfer</h3>
                <button className="text-sm text-blue-600 font-semibold hover:text-blue-700">
                  View All
                </button>
              </div>
              <div className="space-y-3">
                {accountsLoading ? (
                  <p className="text-sm text-slate-500">Loading accounts...</p>
                ) : accounts.length > 0 ? (
                  accounts.slice(0, 3).map((acc) => (
                    <div
                      key={acc.accountNumber}
                      className="flex items-center justify-between p-3 hover:bg-slate-50 rounded-lg cursor-pointer transition-colors"
                      onClick={() => {
                        if (transferType === 'internal' && formData.fromAccount && formData.fromAccount !== acc.accountNumber) {
                          setFormData({ ...formData, toAccount: acc.accountNumber });
                        }
                      }}
                    >
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 bg-slate-100 rounded-full flex items-center justify-center">
                          <User size={18} className="text-slate-600" />
                        </div>
                        <div>
                          <p className="font-semibold text-slate-800 text-sm">
                            {acc.accountName || acc.accountType || 'Account'}
                          </p>
                          <p className="text-xs text-slate-500">{acc.accountNumber}</p>
                        </div>
                      </div>
                      <span className="text-xs text-slate-500">${acc.balance.toLocaleString()}</span>
                    </div>
                  ))
                ) : (
                  <p className="text-sm text-slate-500">No accounts available</p>
                )}
              </div>
            </div>

            {/* Recent Transfers */}
            <div className="bg-white rounded-xl border border-slate-200 p-6">
              <h3 className="font-bold text-slate-800 mb-4">Recent Transfers</h3>
              <div className="space-y-3">
                {recentTransfers.map((transfer) => (
                  <div key={transfer.id} className="flex items-center justify-between">
                    <div>
                      <p className="font-semibold text-slate-800 text-sm">{transfer.recipient}</p>
                      <p className="text-xs text-slate-500">{transfer.date}</p>
                    </div>
                    <p className="font-bold text-slate-800">${transfer.amount.toLocaleString()}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}
    </QuantumLayout>
  );
}