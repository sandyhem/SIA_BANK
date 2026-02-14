import QuantumLayout from "../components/QuantumLayout"
import { userProfile } from "../data/bankingMock"

export default function Settings() {
  return (
    <QuantumLayout title="Settings" subtitle="Manage profile, security preferences, and alerts.">
      <div>
        <h1 className="text-2xl font-semibold text-slate-900">Settings</h1>
        <p className="text-sm text-slate-500">Manage profile, security preferences, and alerts.</p>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-slate-900">Profile</h2>
          <div className="mt-4 grid gap-4">
            <div>
              <label className="text-xs font-semibold text-slate-500">Full name</label>
              <input
                className="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm"
                defaultValue={userProfile.name}
              />
            </div>
            <div>
              <label className="text-xs font-semibold text-slate-500">Email</label>
              <input
                className="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm"
                defaultValue={userProfile.email}
              />
            </div>
            <div>
              <label className="text-xs font-semibold text-slate-500">Phone</label>
              <input
                className="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm"
                defaultValue={userProfile.phone}
              />
            </div>
          </div>
          <button className="mt-6 rounded-xl bg-slate-900 px-4 py-2 text-sm font-semibold text-white">
            Save changes
          </button>
        </div>

        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <h2 className="text-lg font-semibold text-slate-900">Security</h2>
          <div className="mt-4 space-y-4">
            <div className="flex items-center justify-between rounded-xl border border-slate-100 px-4 py-3">
              <div>
                <p className="text-sm font-semibold text-slate-900">Multi-factor authentication</p>
                <p className="text-xs text-slate-500">Enabled for all logins</p>
              </div>
              <button className="rounded-lg bg-emerald-50 px-3 py-2 text-xs font-semibold text-emerald-600">
                Enabled
              </button>
            </div>
            <div className="flex items-center justify-between rounded-xl border border-slate-100 px-4 py-3">
              <div>
                <p className="text-sm font-semibold text-slate-900">Login alerts</p>
                <p className="text-xs text-slate-500">Instant alerts for new devices</p>
              </div>
              <button className="rounded-lg border border-slate-200 px-3 py-2 text-xs font-semibold text-slate-600">
                Manage
              </button>
            </div>
            <div className="flex items-center justify-between rounded-xl border border-slate-100 px-4 py-3">
              <div>
                <p className="text-sm font-semibold text-slate-900">Spending limits</p>
                <p className="text-xs text-slate-500">Daily spend caps enforced</p>
              </div>
              <button className="rounded-lg border border-slate-200 px-3 py-2 text-xs font-semibold text-slate-600">
                Adjust
              </button>
            </div>
          </div>
        </div>
      </div>
    </QuantumLayout>
  )
}
