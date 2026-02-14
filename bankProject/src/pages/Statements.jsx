import QuantumLayout from "../components/QuantumLayout"

const statements = [
  {
    id: "stmt-2026-02",
    period: "February 2026",
    account: "Everyday Checking • **** 4521",
    balance: "$12,458.92",
    status: "Ready",
  },
  {
    id: "stmt-2026-01",
    period: "January 2026",
    account: "High-Yield Savings • **** 7890",
    balance: "$45,230.85",
    status: "Ready",
  },
  {
    id: "stmt-2025-12",
    period: "December 2025",
    account: "Fixed Deposit • **** 3214",
    balance: "$100,000.00",
    status: "Ready",
  },
]

const deliveryPrefs = [
  { id: "email", label: "Email statement", icon: "📧" },
  { id: "pdf", label: "Download PDF", icon: "📄" },
  { id: "csv", label: "Export CSV", icon: "📊" },
]

export default function Statements() {
  return (
    <QuantumLayout
      title="Statements"
      subtitle="Download monthly statements, export data, and manage delivery preferences."
    >
      <div className="grid gap-6 lg:grid-cols-[1.3fr_0.7fr]">
        {/* Main Statement History */}
        <div className="rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-100 p-6">
            <div className="flex items-center justify-between">
              <div>
                <h1 className="text-2xl font-semibold text-slate-900">Statement history</h1>
                <p className="mt-1 text-sm text-slate-500">Your last 12 months of statements</p>
              </div>
              <button className="group rounded-xl bg-slate-900 px-5 py-2.5 text-sm font-semibold text-white transition-all hover:bg-slate-800 hover:shadow-lg active:scale-95">
                <span className="flex items-center gap-2">
                  <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                  </svg>
                  Download all
                </span>
              </button>
            </div>
          </div>

          <div className="p-6 space-y-3">
            {statements.map((statement, index) => (
              <div
                key={statement.id}
                className="group relative overflow-hidden rounded-xl border border-slate-200 bg-gradient-to-br from-slate-50 to-white p-5 transition-all hover:border-slate-300 hover:shadow-md"
              >
                {/* Decorative accent */}
                <div className="absolute right-0 top-0 h-full w-1 bg-gradient-to-b from-slate-900 to-slate-600 opacity-0 transition-opacity group-hover:opacity-100" />
                
                <div className="flex flex-wrap items-center justify-between gap-4">
                  <div className="flex items-center gap-4">
                    <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-slate-900 text-white font-bold shadow-sm">
                      {statement.period.slice(0, 3)}
                    </div>
                    <div>
                      <p className="text-base font-semibold text-slate-900">{statement.period}</p>
                      <p className="mt-0.5 text-xs text-slate-500">{statement.account}</p>
                    </div>
                  </div>
                  
                  <div className="flex items-center gap-6">
                    <div className="text-right">
                      <p className="text-xs font-medium text-slate-500">Closing balance</p>
                      <p className="mt-1 text-lg font-bold text-slate-900">{statement.balance}</p>
                    </div>
                    
                    <div className="flex gap-2">
                      <button className="rounded-lg border border-slate-200 bg-white px-4 py-2 text-xs font-semibold text-slate-700 transition-all hover:border-slate-300 hover:bg-slate-50 active:scale-95">
                        <span className="flex items-center gap-1.5">
                          <svg className="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                          </svg>
                          Preview
                        </span>
                      </button>
                      <button className="rounded-lg bg-slate-900 px-4 py-2 text-xs font-semibold text-white transition-all hover:bg-slate-800 hover:shadow-lg active:scale-95">
                        <span className="flex items-center gap-1.5">
                          <svg className="h-3.5 w-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                          </svg>
                          Download
                        </span>
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* Generate Statement Card */}
          <div className="rounded-2xl border border-slate-200 bg-white shadow-sm overflow-hidden">
            <div className="bg-gradient-to-br from-slate-900 to-slate-700 p-6 text-white">
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-white/20 backdrop-blur-sm">
                  <svg className="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                  </svg>
                </div>
                <div>
                  <h2 className="text-lg font-semibold">Generate statement</h2>
                  <p className="text-sm text-slate-200">Custom date ranges</p>
                </div>
              </div>
            </div>
            
            <div className="p-6">
              <div className="grid gap-4">
                <div>
                  <label className="block text-xs font-semibold uppercase tracking-wider text-slate-500">Account</label>
                  <select className="mt-2 w-full rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-700 transition-all hover:border-slate-300 focus:border-slate-900 focus:outline-none focus:ring-2 focus:ring-slate-900/10">
                    <option>Everyday Checking • **** 4521</option>
                    <option>High-Yield Savings • **** 7890</option>
                    <option>Fixed Deposit • **** 3214</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-semibold uppercase tracking-wider text-slate-500">Date range</label>
                  <select className="mt-2 w-full rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-700 transition-all hover:border-slate-300 focus:border-slate-900 focus:outline-none focus:ring-2 focus:ring-slate-900/10">
                    <option>Last 30 days</option>
                    <option>Last 90 days</option>
                    <option>Year to date</option>
                    <option>Custom range</option>
                  </select>
                </div>
              </div>
              <button className="mt-6 w-full rounded-xl bg-slate-900 px-4 py-3 text-sm font-semibold text-white transition-all hover:bg-slate-800 hover:shadow-lg active:scale-95">
                <span className="flex items-center justify-center gap-2">
                  <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                  </svg>
                  Generate statement
                </span>
              </button>
            </div>
          </div>

          {/* Delivery Preferences Card */}
          <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-slate-100">
                <svg className="h-5 w-5 text-slate-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
              </div>
              <div>
                <h2 className="text-lg font-semibold text-slate-900">Delivery preferences</h2>
                <p className="text-sm text-slate-500">Manage notifications</p>
              </div>
            </div>
            
            <div className="mt-5 space-y-2">
              {deliveryPrefs.map((pref) => (
                <label 
                  key={pref.id} 
                  className="group flex cursor-pointer items-center justify-between rounded-xl border border-slate-200 bg-white px-4 py-3.5 transition-all hover:border-slate-300 hover:bg-slate-50"
                >
                  <span className="flex items-center gap-3 text-sm font-medium text-slate-700">
                    <span className="text-lg">{pref.icon}</span>
                    {pref.label}
                  </span>
                  <input 
                    type="checkbox" 
                    defaultChecked={pref.id === "email"} 
                    className="h-4 w-4 rounded border-slate-300 text-slate-900 transition-all focus:ring-2 focus:ring-slate-900/20"
                  />
                </label>
              ))}
            </div>
            
            <button className="mt-5 w-full rounded-xl border-2 border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 transition-all hover:border-slate-900 hover:bg-slate-900 hover:text-white active:scale-95">
              Save preferences
            </button>
          </div>
        </div>
      </div>
    </QuantumLayout>
  )
}