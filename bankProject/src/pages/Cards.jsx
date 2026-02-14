import QuantumLayout from "../components/QuantumLayout"
import { cards } from "../data/bankingMock"

export default function Cards() {
  return (
    <QuantumLayout title="Cards" subtitle="Control limits, freeze cards, and monitor spending.">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold text-slate-900">Cards</h1>
          <p className="text-sm text-slate-500">Control limits, freeze cards, and monitor spending.</p>
        </div>
        <button className="rounded-xl bg-slate-900 px-4 py-2 text-sm font-semibold text-white">
          Add new card
        </button>
      </div>

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {cards.map((card) => (
          <div key={card.id} className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
            <div className="flex items-start justify-between">
              <div>
                <p className="text-sm text-slate-500">{card.name}</p>
                <p className="text-lg font-semibold text-slate-900">{card.number}</p>
              </div>
              <span className={`rounded-full px-3 py-1 text-xs font-semibold ${card.status === "Active" ? "bg-emerald-50 text-emerald-600" : "bg-slate-100 text-slate-600"}`}>
                {card.status}
              </span>
            </div>
            <div className="mt-4">
              <div className="flex items-center justify-between text-xs text-slate-500">
                <span>Used</span>
                <span>${card.used.toLocaleString()}</span>
              </div>
              <div className="mt-2 h-2 w-full rounded-full bg-slate-100">
                <div className="h-2 rounded-full bg-slate-900" style={{ width: "55%" }} />
              </div>
              <p className="mt-3 text-xs text-slate-500">Limit ${card.limit.toLocaleString()}</p>
            </div>
            <div className="mt-4 flex gap-2">
              <button className="flex-1 rounded-xl border border-slate-200 px-3 py-2 text-sm font-medium text-slate-600">
                Manage
              </button>
              <button className="flex-1 rounded-xl bg-slate-900 px-3 py-2 text-sm font-semibold text-white">
                Freeze
              </button>
            </div>
          </div>
        ))}
      </div>
    </QuantumLayout>
  )
}
