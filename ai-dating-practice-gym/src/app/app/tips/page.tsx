import Link from "next/link";
import { redirect } from "next/navigation";

import { requireProfile, requireUser } from "@/lib/auth";
import { buildPreDateTips } from "@/lib/tips";
import { type DatingGoal } from "@/lib/types";

type PageProps = {
  searchParams: Promise<{ session?: string }>;
};

export default async function TipsPage({ searchParams }: PageProps) {
  const params = await searchParams;
  const sessionId = params.session;
  if (!sessionId) {
    redirect("/app/personas");
  }

  const { supabase, user } = await requireUser();
  const profile = await requireProfile(user.id);

  const { data: session } = await supabase
    .from("sessions")
    .select(
      `
      id,
      user_id,
      persona:personas (id,name,difficulty),
      setting:settings (id,name)
    `,
    )
    .eq("id", sessionId)
    .eq("user_id", user.id)
    .single();

  if (!session) {
    redirect("/app/personas");
  }

  const persona = Array.isArray(session.persona) ? session.persona[0] : session.persona;
  const setting = Array.isArray(session.setting) ? session.setting[0] : session.setting;

  const tips = buildPreDateTips({
    datingGoal: profile.dating_goal as DatingGoal,
    persona: {
      name: persona.name,
      difficulty: persona.difficulty,
    },
  });

  return (
    <div className="mx-auto max-w-2xl space-y-5">
      <div className="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
        <h1 className="text-2xl font-semibold text-zinc-900">Pre-date tips</h1>
        <p className="mt-2 text-sm text-zinc-600">
          Scenario: {persona.name} in {setting.name}
        </p>
        <ul className="mt-4 list-disc space-y-2 pl-5 text-sm text-zinc-700">
          {tips.map((tip) => (
            <li key={tip}>{tip}</li>
          ))}
        </ul>
        <div className="mt-6 flex flex-wrap gap-3">
          <Link
            href={`/app/session/${session.id}`}
            className="rounded-xl bg-zinc-900 px-4 py-2.5 text-sm font-semibold text-white hover:bg-zinc-700"
          >
            Start Chat
          </Link>
          <Link
            href="/app/personas"
            className="rounded-xl border border-zinc-300 px-4 py-2.5 text-sm font-semibold text-zinc-700 hover:bg-zinc-100"
          >
            Back to personas
          </Link>
        </div>
      </div>
    </div>
  );
}
