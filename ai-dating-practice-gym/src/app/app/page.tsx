import Link from "next/link";

import { getUsageAccess } from "@/lib/access";
import { requireProfile, requireUser } from "@/lib/auth";

export default async function DashboardPage() {
  const { supabase, user } = await requireUser();
  const profile = await requireProfile(user.id);

  const [usage, { data: recentSessions }] = await Promise.all([
    getUsageAccess(supabase, user.id),
    supabase
      .from("sessions")
      .select("id,status,started_at,overall_score")
      .eq("user_id", user.id)
      .order("started_at", { ascending: false })
      .limit(5),
  ]);

  return (
    <div className="space-y-6">
      <section className="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
        <h1 className="text-2xl font-semibold text-zinc-900">
          {profile.display_name ? `Hi ${profile.display_name},` : "Welcome,"} let&apos;s practice.
        </h1>
        <p className="mt-2 text-sm text-zinc-600">
          Goal: <span className="font-medium">{profile.dating_goal.replaceAll("_", " ")}</span> · Comfort level:{" "}
          <span className="font-medium">{profile.comfort_level}/5</span>
        </p>
        <div className="mt-6 flex flex-wrap gap-3">
          <Link
            href={usage.canStartSession ? "/app/personas" : "/app/billing"}
            className={`rounded-xl px-4 py-2.5 text-sm font-semibold ${
              usage.canStartSession
                ? "bg-zinc-900 text-white hover:bg-zinc-700"
                : "bg-zinc-200 text-zinc-500"
            }`}
          >
            {usage.canStartSession ? "Start Practice" : "Upgrade to continue"}
          </Link>
          <Link
            href="/app/profile"
            className="rounded-xl border border-zinc-300 px-4 py-2.5 text-sm font-semibold text-zinc-700 hover:bg-zinc-100"
          >
            Edit profile
          </Link>
          <Link
            href="/app/live"
            className="rounded-xl border border-zinc-300 px-4 py-2.5 text-sm font-semibold text-zinc-700 hover:bg-zinc-100"
          >
            Open Live Lab
          </Link>
        </div>
        {usage.isPrototypeMode ? (
          <p className="mt-4 rounded-xl border border-emerald-200 bg-emerald-50 px-3 py-2 text-xs text-emerald-700">
            Prototype mode is active. Billing gate is disabled for testing.
          </p>
        ) : null}
      </section>

      <section className="grid gap-4 md:grid-cols-3">
        <div className="rounded-2xl border border-zinc-200 bg-white p-5 shadow-sm">
          <p className="text-xs uppercase tracking-wide text-zinc-500">Plan</p>
          <p className="mt-2 text-lg font-semibold text-zinc-900">
            {usage.isPrototypeMode ? "Prototype" : usage.isSubscribed ? "Pro" : "Free"}
          </p>
        </div>
        <div className="rounded-2xl border border-zinc-200 bg-white p-5 shadow-sm">
          <p className="text-xs uppercase tracking-wide text-zinc-500">Sessions used</p>
          <p className="mt-2 text-lg font-semibold text-zinc-900">{usage.sessionCount}</p>
        </div>
        <div className="rounded-2xl border border-zinc-200 bg-white p-5 shadow-sm">
          <p className="text-xs uppercase tracking-wide text-zinc-500">Free sessions remaining</p>
          <p className="mt-2 text-lg font-semibold text-zinc-900">
            {usage.isSubscribed ? "Unlimited" : usage.hasFreeSessionRemaining ? "1" : "0"}
          </p>
        </div>
      </section>

      <section className="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-zinc-900">Recent sessions</h2>
        <div className="mt-4 space-y-3">
          {(recentSessions ?? []).length === 0 ? (
            <p className="text-sm text-zinc-600">No sessions yet. Start your first practice round.</p>
          ) : (
            recentSessions?.map((session) => (
              <div
                key={session.id}
                className="flex flex-col gap-2 rounded-xl border border-zinc-200 px-4 py-3 sm:flex-row sm:items-center sm:justify-between"
              >
                <p className="text-sm text-zinc-700">
                  {new Date(session.started_at).toLocaleString()} · {session.status}
                </p>
                <div className="flex items-center gap-3">
                  <span className="text-sm text-zinc-600">
                    Score: {typeof session.overall_score === "number" ? session.overall_score : "N/A"}
                  </span>
                  <Link
                    href={
                      session.status === "coached" ? `/app/session/${session.id}/coach` : `/app/session/${session.id}`
                    }
                    className="text-sm font-medium text-zinc-900 underline"
                  >
                    Open
                  </Link>
                </div>
              </div>
            ))
          )}
        </div>
      </section>
    </div>
  );
}
