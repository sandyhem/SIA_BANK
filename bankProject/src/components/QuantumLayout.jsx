import { useState } from "react"
import { Link, NavLink, useNavigate } from "react-router-dom"
import {
  Bell,
  Building2,
  ChevronDown,
  FileDown,
  HelpCircle,
  LayoutDashboard,
  Menu,
  Receipt,
  Search,
  Send,
  Settings,
  User,
  Wallet,
  X,
  LogOut,
} from "lucide-react"
import { useAuth } from "../context/AuthContext"

const menuItems = [
  { id: "dashboard", label: "Dashboard", icon: LayoutDashboard, to: "/" },
  { id: "accounts", label: "Accounts", icon: Wallet, to: "/accounts" },
  { id: "transactions", label: "Transactions", icon: Receipt, to: "/transactions" },
  { id: "transfers", label: "Transfers", icon: Send, to: "/transfers" },
  { id: "statements", label: "Statements", icon: FileDown, to: "/statements" },
  { id: "settings", label: "Settings", icon: Settings, to: "/settings" },
]

export default function QuantumLayout({ title, subtitle, children }) {
  const [sidebarOpen, setSidebarOpen] = useState(true)
  const [profileDropdown, setProfileDropdown] = useState(false)
  const { user, logout } = useAuth()
  const navigate = useNavigate()

  const handleLogout = () => {
    logout()
    navigate('/login')
  }

  const userData = {
    name: user?.name || user?.username || "User",
    customerId: user?.customerId || "N/A",
    email: user?.email || "",
    phone: user?.phone || "",
    memberSince: user?.createdAt ? new Date(user.createdAt).getFullYear() : "2024",
    kycStatus: user?.kycStatus || "pending",
  }

  return (
    <div className="min-h-screen bg-slate-50">
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;500;600;700&display=swap');

        * {
          font-family: 'IBM Plex Sans', -apple-system, BlinkMacSystemFont, sans-serif;
        }

        .gradient-primary {
          background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
        }

        .gradient-success {
          background: linear-gradient(135deg, #059669 0%, #10b981 100%);
        }

        .gradient-card {
          background: linear-gradient(135deg, #334155 0%, #475569 100%);
        }

        .card-shadow {
          box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
        }

        .card-shadow-hover {
          transition: all 0.3s ease;
        }

        .card-shadow-hover:hover {
          box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
          transform: translateY(-2px);
        }

        .animate-slide-in {
          animation: slideIn 0.3s ease-out;
        }

        @keyframes slideIn {
          from {
            opacity: 0;
            transform: translateX(-20px);
          }
          to {
            opacity: 1;
            transform: translateX(0);
          }
        }

        .animate-fade-in {
          animation: fadeIn 0.4s ease-out;
        }

        @keyframes fadeIn {
          from { opacity: 0; }
          to { opacity: 1; }
        }

        .scrollbar-hide::-webkit-scrollbar {
          display: none;
        }

        .scrollbar-hide {
          -ms-overflow-style: none;
          scrollbar-width: none;
        }
      `}</style>

      <aside className={`fixed left-0 top-0 h-full bg-white border-r border-slate-200 transition-all duration-300 z-40 ${sidebarOpen ? "w-64" : "w-20"
        }`}>
        <div className="h-16 border-b border-slate-200 flex items-center justify-between px-4">
          {sidebarOpen ? (
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 gradient-primary rounded-lg flex items-center justify-center">
                <Building2 className="text-white" size={24} />
              </div>
              <div>
                <h1 className="text-lg font-bold text-slate-800">Quantum Bank</h1>
                <p className="text-xs text-slate-500">Corporate Banking</p>
              </div>
            </div>
          ) : (
            <div className="w-10 h-10 gradient-primary rounded-lg flex items-center justify-center mx-auto">
              <Building2 className="text-white" size={24} />
            </div>
          )}
        </div>

        <nav className="p-3 space-y-1">
          {menuItems.map((item) => (
            <NavLink
              key={item.id}
              to={item.to}
              className={({ isActive }) =>
                `w-full flex items-center gap-3 px-3 py-3 rounded-lg transition-all ${isActive
                  ? "bg-blue-50 text-blue-700 font-semibold"
                  : "text-slate-600 hover:bg-slate-50 hover:text-slate-900"
                }`
              }
            >
              <item.icon size={20} />
              {sidebarOpen && <span>{item.label}</span>}
            </NavLink>
          ))}
        </nav>

        <button
          onClick={() => setSidebarOpen(!sidebarOpen)}
          className="absolute -right-3 top-20 w-6 h-6 bg-white border border-slate-200 rounded-full flex items-center justify-center shadow-sm hover:shadow-md transition-all"
        >
          {sidebarOpen ? <X size={14} /> : <Menu size={14} />}
        </button>

        {sidebarOpen && (
          <div className="absolute bottom-4 left-4 right-4">
            <div className="bg-blue-50 rounded-lg p-4 border border-blue-100">
              <div className="flex items-center gap-3 mb-2">
                <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
                  <HelpCircle size={16} className="text-blue-600" />
                </div>
                <div>
                  <h4 className="text-sm font-semibold text-slate-800">Need Help?</h4>
                  <p className="text-xs text-slate-600">24/7 Support</p>
                </div>
              </div>
              <Link
                to="/support"
                className="block w-full py-2 bg-blue-600 text-white text-sm font-semibold rounded-lg text-center hover:bg-blue-700 transition-colors"
              >
                Contact Us
              </Link>
            </div>
          </div>
        )}
      </aside>

      <div className={`transition-all duration-300 ${sidebarOpen ? "ml-64" : "ml-20"}`}>
        <header className="h-16 bg-white border-b border-slate-200 px-6 flex items-center justify-between sticky top-0 z-30">
          <div>
            <h2 className="text-xl font-bold text-slate-800">{title}</h2>
            {subtitle ? <p className="text-sm text-slate-500">{subtitle}</p> : null}
          </div>

          <div className="flex items-center gap-4">
            <div className="relative hidden md:block">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
              <input
                type="text"
                placeholder="Search transactions, accounts..."
                className="pl-10 pr-4 py-2 w-80 border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              />
            </div>

            <div className="relative">
              <button className="relative p-2 hover:bg-slate-100 rounded-lg transition-colors">
                <Bell size={20} className="text-slate-600" />
                <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
              </button>
            </div>

            <div className="relative">
              <button
                onClick={() => setProfileDropdown(!profileDropdown)}
                className="flex items-center gap-3 px-3 py-2 hover:bg-slate-100 rounded-lg transition-colors"
              >
                <div className="w-9 h-9 bg-blue-600 rounded-full flex items-center justify-center">
                  <User size={18} className="text-white" />
                </div>
                <div className="hidden md:block text-left">
                  <p className="text-sm font-semibold text-slate-800">{userData.name}</p>
                  <p className="text-xs text-slate-500">{userData.customerId}</p>
                </div>
                <ChevronDown size={16} className="text-slate-400" />
              </button>

              {profileDropdown && (
                <div className="absolute right-0 mt-2 w-64 bg-white rounded-lg shadow-lg border border-slate-200 py-2 animate-fade-in">
                  <div className="px-4 py-3 border-b border-slate-100">
                    <p className="font-semibold text-slate-800">{userData.name}</p>
                    <p className="text-sm text-slate-500">{userData.email}</p>
                  </div>
                  <Link to="/settings" className="w-full px-4 py-2 text-left hover:bg-slate-50 flex items-center gap-3">
                    <Settings size={16} />
                    <span className="text-sm">Settings</span>
                  </Link>
                  <Link to="/support" className="w-full px-4 py-2 text-left hover:bg-slate-50 flex items-center gap-3">
                    <HelpCircle size={16} />
                    <span className="text-sm">Support</span>
                  </Link>
                  <div className="border-t border-slate-100 mt-2 pt-2">
                    <button
                      onClick={handleLogout}
                      className="w-full px-4 py-2 text-left hover:bg-slate-50 flex items-center gap-3 text-red-600"
                    >
                      <LogOut size={16} />
                      <span className="text-sm font-semibold">Logout</span>
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </header>

        <main className="p-6 animate-fade-in">{children}</main>
      </div>
    </div>
  )
}
