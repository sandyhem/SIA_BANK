import QuantumLayout from "../components/QuantumLayout"
import { Link } from "react-router-dom"

export default function NotFound() {
  return (
    <QuantumLayout title="Page not found" subtitle="We couldn’t locate this page.">
      <div className="flex min-h-[60vh] flex-col items-center justify-center rounded-2xl border border-dashed border-slate-200 bg-white px-6 py-12 text-center">
        <p className="text-sm font-semibold uppercase tracking-widest text-slate-400">404</p>
        <h1 className="mt-2 text-2xl font-semibold text-slate-900">Page not found</h1>
        <p className="mt-3 text-sm text-slate-500">
          The page you’re looking for doesn’t exist. Head back to your dashboard.
        </p>
        <Link
          to="/"
          className="mt-6 rounded-xl bg-slate-900 px-4 py-2 text-sm font-semibold text-white"
        >
          Back to dashboard
        </Link>
      </div>
    </QuantumLayout>
  )
}
