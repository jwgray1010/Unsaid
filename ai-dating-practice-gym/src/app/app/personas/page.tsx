import Link from "next/link";
import { redirect } from "next/navigation";

import { getUsageAccess } from "@/lib/access";
import { requireProfile, requireUser } from "@/lib/auth";

type PersonaRow = {
  id: string;
  name: string;
  description: string;
  difficulty: number;
};

export default async function PersonasPage() {
  const { supabase, user } = await requireUser();
  await requireProfile(user.id);

  const usage = await getUsageAccess(supabase, user.id);
  if (!usage.canStartSession) {
    redirect("/app/billing");
  }

  const { data: personas } = await supabase
    .from("personas")
    .select("id,name,description,difficulty")
    .eq("is_active", true)
    .order("difficulty", { ascending: true });

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-semibold text-zinc-900">Choose your date persona</h1>
      <p className="text-sm text-zinc-600">Pick a scenario partner to practice pacing, curiosity, and warmth.</p>

      <div className="grid gap-4 md:grid-cols-3">
        {(personas as PersonaRow[] | null)?.map((persona) => (
          <article key={persona.id} className="rounded-2xl border border-zinc-200 bg-white p-5 shadow-sm">
            <h2 className="text-lg font-semibold text-zinc-900">{persona.name}</h2>
            <p className="mt-2 text-sm text-zinc-600">{persona.description}</p>
            <p className="mt-3 text-xs uppercase tracking-wide text-zinc-500">Difficulty: {persona.difficulty}/5</p>
            <Link
              href={`/app/settings?persona=${persona.id}`}
              className="mt-4 inline-flex rounded-xl bg-zinc-900 px-4 py-2 text-sm font-semibold text-white hover:bg-zinc-700"
            >
              Choose
            </Link>
          </article>
        )) ?? null}
      </div>
    </div>
  );
}
