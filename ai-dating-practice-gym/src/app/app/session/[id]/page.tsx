import Link from "next/link";
import { redirect } from "next/navigation";

import { ChatSession } from "@/components/chat-session";
import { requireProfile, requireUser } from "@/lib/auth";
import { type ChatMessage } from "@/lib/types";

type PageProps = {
  params: Promise<{
    id: string;
  }>;
};

export default async function SessionPage({ params }: PageProps) {
  const { id } = await params;
  const { supabase, user } = await requireUser();
  await requireProfile(user.id);

  const [{ data: session }, { data: messages }] = await Promise.all([
    supabase
      .from("sessions")
      .select(
        `
        id,
        status,
        started_at,
        persona:personas (id,name),
        setting:settings (id,name)
      `,
      )
      .eq("id", id)
      .eq("user_id", user.id)
      .maybeSingle(),
    supabase
      .from("messages")
      .select("id,role,content,created_at")
      .eq("session_id", id)
      .order("created_at", { ascending: true }),
  ]);

  if (!session) {
    redirect("/app");
  }

  const persona = Array.isArray(session.persona) ? session.persona[0] : session.persona;
  const setting = Array.isArray(session.setting) ? session.setting[0] : session.setting;

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-zinc-200 bg-white p-4 shadow-sm">
        <div>
          <h1 className="text-xl font-semibold text-zinc-900">
            {persona?.name} · {setting?.name}
          </h1>
          <p className="text-sm text-zinc-600">Status: {session.status}</p>
        </div>
        {session.status === "coached" ? (
          <Link
            href={`/app/session/${session.id}/coach`}
            className="rounded-xl border border-zinc-300 px-4 py-2 text-sm font-semibold text-zinc-700 hover:bg-zinc-100"
          >
            View coaching report
          </Link>
        ) : null}
      </div>

      <ChatSession
        sessionId={session.id}
        initialMessages={(messages ?? []) as ChatMessage[]}
        initialStatus={session.status as "active" | "ended" | "coached"}
      />
    </div>
  );
}
