import Link from "next/link";

import { requireProfile, requireUser } from "@/lib/auth";

export default async function LiveVrPage() {
  const { user } = await requireUser();
  await requireProfile(user.id);

  return (
    <div className="space-y-5">
      <section className="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
        <h1 className="text-2xl font-semibold text-zinc-900">VR Practice Mode (experimental)</h1>
        <p className="mt-2 text-sm text-zinc-600">
          WebXR-ready scene for immersive practice. Works best in headset browsers that support immersive VR.
        </p>
        <ul className="mt-3 list-disc space-y-1 pl-5 text-sm text-zinc-700">
          <li>Use a headset browser with WebXR support.</li>
          <li>Click the headset icon inside the scene to enter VR.</li>
          <li>Use controllers to look around and rehearse conversational grounding.</li>
        </ul>
        <div className="mt-4 flex flex-wrap gap-3">
          <Link
            href="/app/live"
            className="rounded-xl border border-zinc-300 px-4 py-2 text-sm font-semibold text-zinc-700 hover:bg-zinc-100"
          >
            Back to Web Live Mode
          </Link>
          <a
            href="/vr-demo.html"
            target="_blank"
            rel="noopener noreferrer"
            className="rounded-xl bg-zinc-900 px-4 py-2 text-sm font-semibold text-white hover:bg-zinc-700"
          >
            Open VR scene in new tab
          </a>
        </div>
      </section>

      <section className="rounded-2xl border border-zinc-200 bg-white p-2 shadow-sm">
        <iframe
          title="AI Dating Practice VR Scene"
          src="/vr-demo.html"
          className="h-[620px] w-full rounded-xl border-0"
          allow="xr-spatial-tracking; fullscreen"
        />
      </section>
    </div>
  );
}
