import Link from "next/link";
import { redirect } from "next/navigation";

import { requireProfile, requireUser } from "@/lib/auth";
import { type CoachingReport } from "@/lib/types";

type PageProps = {
  params: Promise<{
    id: string;
  }>;
};

export default async function CoachPage({ params }: PageProps) {
  const { id } = await params;
  const { supabase, user } = await requireUser();
  await requireProfile(user.id);

  const [{ data: session }, { data: reportRow }] = await Promise.all([
    supabase
      .from("sessions")
      .select("id,status,persona_id,setting_id,overall_score,summary")
      .eq("id", id)
      .eq("user_id", user.id)
      .maybeSingle(),
    supabase.from("coaching_reports").select("payload").eq("session_id", id).maybeSingle(),
  ]);

  if (!session) {
    redirect("/app");
  }

  const report = reportRow?.payload as CoachingReport | undefined;

  if (!report) {
    return (
      <div className="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
        <h1 className="text-2xl font-semibold text-zinc-900">Coaching report not ready yet</h1>
        <p className="mt-2 text-sm text-zinc-600">End the session first to generate feedback and rewrites.</p>
        <Link
          href={`/app/session/${id}`}
          className="mt-4 inline-flex rounded-xl bg-zinc-900 px-4 py-2 text-sm font-semibold text-white hover:bg-zinc-700"
        >
          Back to session
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <section className="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
        <p className="text-xs uppercase tracking-wide text-zinc-500">Overall score</p>
        <h1 className="mt-1 text-4xl font-semibold text-zinc-900">{report.overall_score}</h1>
        <p className="mt-3 text-sm text-zinc-700">{report.summary}</p>
      </section>

      <section className="grid gap-4 md:grid-cols-2">
        <article className="rounded-2xl border border-zinc-200 bg-white p-5 shadow-sm">
          <h2 className="text-lg font-semibold text-zinc-900">Strengths</h2>
          <div className="mt-3 space-y-3">
            {report.strengths.map((item) => (
              <div key={item.title}>
                <h3 className="text-sm font-semibold text-zinc-800">{item.title}</h3>
                <p className="text-sm text-zinc-600">{item.detail}</p>
              </div>
            ))}
          </div>
        </article>

        <article className="rounded-2xl border border-zinc-200 bg-white p-5 shadow-sm">
          <h2 className="text-lg font-semibold text-zinc-900">Improvements</h2>
          <div className="mt-3 space-y-3">
            {report.improvements.map((item) => (
              <div key={item.title}>
                <h3 className="text-sm font-semibold text-zinc-800">{item.title}</h3>
                <p className="text-sm text-zinc-600">{item.detail}</p>
                <ul className="mt-1 list-disc pl-4 text-xs text-zinc-600">
                  {item.action_steps.map((step) => (
                    <li key={step}>{step}</li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </article>
      </section>

      <section className="rounded-2xl border border-zinc-200 bg-white p-5 shadow-sm">
        <h2 className="text-lg font-semibold text-zinc-900">Timeline highlights</h2>
        <div className="mt-4 space-y-4">
          {report.timeline.map((moment, index) => (
            <article key={`${moment.title}-${index}`} className="rounded-xl border border-zinc-200 p-4">
              <h3 className="text-sm font-semibold text-zinc-800">{moment.title}</h3>
              <p className="mt-1 text-sm text-zinc-600">{moment.context}</p>
              <p className="mt-2 text-sm text-zinc-700">
                <span className="font-medium">Coach note:</span> {moment.coach_note}
              </p>
              <div className="mt-2">
                <p className="text-xs uppercase tracking-wide text-zinc-500">Try instead</p>
                <ul className="mt-1 list-disc pl-4 text-sm text-zinc-700">
                  {moment.rewrite_options.map((option) => (
                    <li key={option}>{option}</li>
                  ))}
                </ul>
              </div>
            </article>
          ))}
        </div>
      </section>

      <section className="flex flex-wrap gap-3">
        <Link
          href={`/app/settings?persona=${session.persona_id}`}
          className="rounded-xl bg-zinc-900 px-4 py-2.5 text-sm font-semibold text-white hover:bg-zinc-700"
        >
          Try Again (same persona)
        </Link>
        <Link
          href="/app/personas"
          className="rounded-xl border border-zinc-300 px-4 py-2.5 text-sm font-semibold text-zinc-700 hover:bg-zinc-100"
        >
          New Scenario
        </Link>
      </section>
    </div>
  );
}
