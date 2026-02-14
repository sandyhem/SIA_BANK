import { useState } from 'react';
import { X, AlertCircle, CheckCircle } from 'lucide-react';

export default function Toast({ message, type = 'success', onClose }) {
    return (
        <div className="fixed bottom-4 right-4 z-50 animate-slide-in">
            <div className={`flex items-center gap-3 px-6 py-4 rounded-xl shadow-lg border ${type === 'success'
                    ? 'bg-green-50 border-green-200'
                    : type === 'error'
                        ? 'bg-red-50 border-red-200'
                        : 'bg-blue-50 border-blue-200'
                }`}>
                {type === 'success' && <CheckCircle size={20} className="text-green-600" />}
                {type === 'error' && <AlertCircle size={20} className="text-red-600" />}
                <p className={`font-medium ${type === 'success'
                        ? 'text-green-800'
                        : type === 'error'
                            ? 'text-red-800'
                            : 'text-blue-800'
                    }`}>{message}</p>
                <button
                    onClick={onClose}
                    className="ml-4 p-1 hover:bg-white/50 rounded transition-colors"
                >
                    <X size={16} />
                </button>
            </div>
        </div>
    );
}
