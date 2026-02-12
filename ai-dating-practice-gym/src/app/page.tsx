import Link from "next/link";

export default function Home() {
  return (
    <div className="space-y-8">
      <section className="rounded-3xl border border-zinc-200 bg-white p-8 shadow-sm">
        <p className="mb-3 inline-flex rounded-full bg-zinc-100 px-3 py-1 text-xs font-medium text-zinc-600">
          Practice real-world dating conversations
        </p>
        <h1 className="max-w-3xl text-4xl font-semibold tracking-tight text-zinc-900 sm:text-5xl">
          Build confidence with AI date simulations and actionable coaching.
        </h1>
        <p className="mt-4 max-w-2xl text-base text-zinc-600 sm:text-lg">
          Train conversation pacing, warmth, and curiosity in realistic scenarios. End each session with a score,
          timeline highlights, and rewrite suggestions you can use right away.
        </p>
        <div className="mt-6 flex flex-wrap items-center gap-3">
          <Link
            href="/login"
            className="rounded-xl bg-indigo-600 px-5 py-2.5 text-sm font-semibold text-white shadow-sm ring-1 ring-indigo-500/40 transition hover:bg-indigo-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500"
          >
            Start Practice Free
          </Link>
          <Link
            href="/app/billing"
            className="rounded-xl border border-zinc-300 px-5 py-2.5 text-sm font-semibold text-zinc-700 transition hover:bg-zinc-100"
          >
            View Pricing
          </Link>
        </div>
      </section>

      <section className="grid gap-4 md:grid-cols-3">
        {[
          {
            title: "1. Pick a persona",
            body: "Choose from warm, playful, or lightly avoidant dating personalities.",
          },
          {
            title: "2. Run a simulation",
            body: "Chat in a guided Coffee Date setting with boundaries and safety controls.",
          },
          {
            title: "3. Get coached",
            body: "Receive strengths, improvements, and line-by-line rewrites for key moments.",
          },
        ].map((item) => (
          <article key={item.title} className="rounded-2xl border border-zinc-200 bg-white p-5 shadow-sm">
            <h2 className="text-base font-semibold text-zinc-900">{item.title}</h2>
            <p className="mt-2 text-sm text-zinc-600">{item.body}</p>
          </article>
        ))}
      </section>
    </div>
  );
}
