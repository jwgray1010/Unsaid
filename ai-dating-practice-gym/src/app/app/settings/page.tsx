import { redirect } from "next/navigation";

import { getUsageAccess } from "@/lib/access";
import { requireProfile, requireUser } from "@/lib/auth";

type PageProps = {
  searchParams: Promise<{
    persona?: string;
  }>;
};

export default async function SettingsPage({ searchParams }: PageProps) {
  const params = await searchParams;
  const personaId = params.persona;
  if (!personaId) {
    redirect("/app/personas");
  }

  const { supabase, user } = await requireUser();
  await requireProfile(user.id);

  const usage = await getUsageAccess(supabase, user.id);
  if (!usage.canStartSession) {
    redirect("/app/billing");
  }

  const [{ data: persona }, { data: settings }] = await Promise.all([
    supabase
      .from("personas")
      .select("id,name,description,difficulty")
      .eq("id", personaId)
      .eq("is_active", true)
      .maybeSingle(),
    supabase.from("settings").select("id,name,context_prompt_template").eq("is_active", true),
  ]);

  if (!persona) {
    redirect("/app/personas");
  }

  async function startSession(formData: FormData) {
    "use server";

    const selectedPersonaId = String(formData.get("persona_id") ?? "");
    const selectedSettingId = String(formData.get("setting_id") ?? "");
    if (!selectedPersonaId || !selectedSettingId) {
      return;
    }

    const { supabase: actionSupabase, user: actionUser } = await requireUser();
    await requireProfile(actionUser.id);
    const actionUsage = await getUsageAccess(actionSupabase, actionUser.id);
    if (!actionUsage.canStartSession) {
      redirect("/app/billing");
    }

    const { data: session, error } = await actionSupabase
      .from("sessions")
      .insert({
        user_id: actionUser.id,
        persona_id: selectedPersonaId,
        setting_id: selectedSettingId,
        status: "active",
      })
      .select("id")
      .single();

    if (error || !session) {
      throw new Error(error?.message ?? "Unable to create session.");
    }

    redirect(`/app/tips?session=${session.id}`);
  }

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-semibold text-zinc-900">Choose your setting</h1>
        <p className="mt-1 text-sm text-zinc-600">
          Persona: <span className="font-medium">{persona.name}</span> · Difficulty {persona.difficulty}/5
        </p>
      </div>

      <div className="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-zinc-900">{persona.name}</h2>
        <p className="mt-2 text-sm text-zinc-600">{persona.description}</p>
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        {settings?.map((setting) => (
          <form
            key={setting.id}
            action={startSession}
            className="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm"
          >
            <input type="hidden" name="persona_id" value={persona.id} />
            <input type="hidden" name="setting_id" value={setting.id} />
            <h3 className="text-lg font-semibold text-zinc-900">{setting.name}</h3>
            <p className="mt-2 text-sm text-zinc-600">
              A grounded first-date environment focused on emotional pacing and conversational flow.
            </p>
            <button
              type="submit"
              className="mt-4 rounded-xl bg-zinc-900 px-4 py-2 text-sm font-semibold text-white hover:bg-zinc-700"
            >
              Continue
            </button>
          </form>
        ))}
      </div>
    </div>
  );
}
