import QuantumLayout from "../components/QuantumLayout"

export default function Support() {
  return (
    <QuantumLayout title="Support" subtitle="Get help from our 24/7 banking specialists.">
      <div>
        <h1 className="text-2xl font-semibold text-slate-900">Support</h1>
        <p className="text-sm text-slate-500">Get help from our 24/7 banking specialists.</p>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-slate-900">Chat with us</h2>
          <p className="mt-2 text-sm text-slate-500">Average response time: 2 minutes.</p>
          <button className="mt-4 rounded-xl bg-slate-900 px-4 py-2 text-sm font-semibold text-white">
            Start chat
          </button>
        </div>
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-slate-900">Call support</h2>
          <p className="mt-2 text-sm text-slate-500">Domestic: +1 (800) 555-0199</p>
          <p className="text-sm text-slate-500">International: +1 (212) 555-0132</p>
          <button className="mt-4 rounded-xl border border-slate-200 px-4 py-2 text-sm font-semibold text-slate-600">
            Request callback
          </button>
        </div>
      </div>

      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-slate-900">Help center</h2>
        <div className="mt-4 grid gap-3 sm:grid-cols-2">
          {[
            "Dispute a transaction",
            "Freeze a card",
            "Set travel notice",
            "Update personal details",
          ].map((item) => (
            <div key={item} className="rounded-xl border border-slate-100 px-4 py-3 text-sm text-slate-600">
              {item}
            </div>
          ))}
        </div>
      </div>
    </QuantumLayout>
  )
}
