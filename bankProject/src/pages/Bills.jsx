import React, { useState } from 'react';
import QuantumLayout from '../components/QuantumLayout';
import { Zap, Droplet, Flame, Smartphone, Wifi, Shield, Search, Calendar, CheckCircle } from 'lucide-react';

export default function Bills() {
  const [selectedCategory, setSelectedCategory] = useState(null);
  const [billAmount, setBillAmount] = useState('');

  const categories = [
    { id: 'electricity', name: 'Electricity', icon: Zap, color: 'yellow' },
    { id: 'water', name: 'Water', icon: Droplet, color: 'blue' },
    { id: 'gas', name: 'Gas', icon: Flame, color: 'orange' },
    { id: 'mobile', name: 'Mobile', icon: Smartphone, color: 'purple' },
    { id: 'internet', name: 'Internet', icon: Wifi, color: 'cyan' },
    { id: 'insurance', name: 'Insurance', icon: Shield, color: 'green' }
  ];

  const savedBillers = [
    { id: 1, name: 'ABC Electricity', category: 'electricity', accountNumber: '1234567890', lastPaid: '2026-01-15', amount: 156.50 },
    { id: 2, name: 'XYZ Water Board', category: 'water', accountNumber: '9876543210', lastPaid: '2026-01-20', amount: 45.00 },
    { id: 3, name: 'Mobile Network', category: 'mobile', accountNumber: '5551234567', lastPaid: '2026-02-01', amount: 49.99 }
  ];

  const recentPayments = [
    { id: 1, biller: 'ABC Electricity', amount: 156.50, date: '2026-02-10', status: 'completed' },
    { id: 2, biller: 'XYZ Water Board', amount: 45.00, date: '2026-02-08', status: 'completed' },
    { id: 3, biller: 'Mobile Network', amount: 49.99, date: '2026-02-05', status: 'completed' }
  ];

  const colorVariants = {
    yellow: 'bg-yellow-100 text-yellow-600',
    blue: 'bg-blue-100 text-blue-600',
    orange: 'bg-orange-100 text-orange-600',
    purple: 'bg-purple-100 text-purple-600',
    cyan: 'bg-cyan-100 text-cyan-600',
    green: 'bg-green-100 text-green-600'
  };

  return (
    <QuantumLayout title="Bill Payments" subtitle="Pay your bills easily and securely">
      <div className="p-6">
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-slate-800 mb-2">Bill Payments</h1>
          <p className="text-slate-600">Pay your bills easily and securely</p>
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
          {/* Bill Categories */}
          <div className="bg-white rounded-xl border border-slate-200 p-6">
            <h3 className="text-lg font-bold text-slate-800 mb-4">Select Category</h3>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
              {categories.map((category) => {
                const Icon = category.icon;
                return (
                  <button
                    key={category.id}
                    onClick={() => setSelectedCategory(category.id)}
                    className={`p-6 rounded-xl border-2 transition-all ${
                      selectedCategory === category.id
                        ? 'border-blue-600 bg-blue-50'
                        : 'border-slate-200 hover:border-slate-300'
                    }`}
                  >
                    <div className={`w-14 h-14 rounded-xl flex items-center justify-center mb-3 mx-auto ${colorVariants[category.color]}`}>
                      <Icon size={28} />
                    </div>
                    <p className="font-semibold text-slate-800 text-center">{category.name}</p>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Bill Payment Form */}
          {selectedCategory && (
            <div className="bg-white rounded-xl border border-slate-200 p-6">
              <h3 className="text-lg font-bold text-slate-800 mb-4">Pay Bill</h3>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-semibold text-slate-700 mb-2">
                    Biller
                  </label>
                  <select className="w-full px-4 py-3 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500">
                    <option>Select biller</option>
                    <option>ABC Electricity Board</option>
                    <option>XYZ Electricity Company</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-semibold text-slate-700 mb-2">
                    Consumer Number
                  </label>
                  <input
                    type="text"
                    className="w-full px-4 py-3 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    placeholder="Enter consumer number"
                  />
                </div>
                <button className="w-full py-3 bg-blue-600 text-white rounded-lg font-semibold hover:bg-blue-700 transition-colors">
                  Fetch Bill
                </button>
              </div>
            </div>
          )}

          {/* Saved Billers */}
          <div className="bg-white rounded-xl border border-slate-200 p-6">
            <h3 className="text-lg font-bold text-slate-800 mb-4">Saved Billers</h3>
            <div className="space-y-3">
              {savedBillers.map((biller) => (
                <div key={biller.id} className="flex items-center justify-between p-4 border border-slate-200 rounded-lg hover:border-blue-300 transition-colors">
                  <div>
                    <p className="font-semibold text-slate-800">{biller.name}</p>
                    <p className="text-sm text-slate-500">Account: {biller.accountNumber}</p>
                  </div>
                  <button className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm font-semibold hover:bg-blue-700 transition-colors">
                    Pay Now
                  </button>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          <div className="bg-white rounded-xl border border-slate-200 p-6">
            <h3 className="font-bold text-slate-800 mb-4">Recent Payments</h3>
            <div className="space-y-3">
              {recentPayments.map((payment) => (
                <div key={payment.id}>
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-semibold text-slate-800 text-sm">{payment.biller}</p>
                      <p className="text-xs text-slate-500">{payment.date}</p>
                    </div>
                    <div className="text-right">
                      <p className="font-bold text-slate-800">${payment.amount}</p>
                      <span className="flex items-center gap-1 text-xs text-green-600">
                        <CheckCircle size={12} />
                        Paid
                      </span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
        </div>
      </div>
    </QuantumLayout>
  );
}