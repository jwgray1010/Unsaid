import Link from "next/link";

import { LiveMultimodalCoach } from "@/components/live-multimodal-coach";
import { requireProfile, requireUser } from "@/lib/auth";

export default async function LivePracticePage() {
  const { user } = await requireUser();
  await requireProfile(user.id);

  return (
    <div className="space-y-5">
      <section className="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
        <h1 className="text-2xl font-semibold text-zinc-900">Live Practice Lab</h1>
        <p className="mt-2 text-sm text-zinc-600">
          Experimental multimodal experience for real-time camera + microphone based coaching signals.
        </p>
        <div className="mt-4 flex flex-wrap gap-3">
          <Link
            href="/app/live/vr"
            className="rounded-xl border border-zinc-300 px-4 py-2 text-sm font-semibold text-zinc-700 hover:bg-zinc-100"
          >
            Open VR Mode
          </Link>
          <Link
            href="/app/personas"
            className="rounded-xl bg-zinc-900 px-4 py-2 text-sm font-semibold text-white hover:bg-zinc-700"
          >
            Back to chat simulations
          </Link>
        </div>
      </section>

      <LiveMultimodalCoach />
    </div>
  );
}
