import { BillingActions } from "@/components/billing-actions";
import { getUsageAccess } from "@/lib/access";
import { requireProfile, requireUser } from "@/lib/auth";

type PageProps = {
  searchParams: Promise<{
    success?: string;
    canceled?: string;
  }>;
};

export default async function BillingPage({ searchParams }: PageProps) {
  const params = await searchParams;
  const { supabase, user } = await requireUser();
  await requireProfile(user.id);

  const usage = await getUsageAccess(supabase, user.id);

  return (
    <div className="mx-auto max-w-2xl space-y-5">
      <h1 className="text-2xl font-semibold text-zinc-900">Billing</h1>

      {params.success ? (
        <p className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-2 text-sm text-emerald-700">
          Checkout completed. Your subscription is updating now.
        </p>
      ) : null}
      {params.canceled ? (
        <p className="rounded-xl border border-zinc-200 bg-zinc-50 px-4 py-2 text-sm text-zinc-700">
          Checkout canceled. You can upgrade anytime.
        </p>
      ) : null}

      <section className="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
        <p className="text-xs uppercase tracking-wide text-zinc-500">Current plan</p>
        <p className="mt-1 text-xl font-semibold text-zinc-900">
          {usage.isPrototypeMode ? "Prototype" : usage.isSubscribed ? "Pro" : "Free"}
        </p>
        <p className="mt-2 text-sm text-zinc-600">
          Free tier includes 1 total session. Pro gives unlimited sessions with fair-use rate limits.
        </p>
        {usage.isPrototypeMode ? (
          <p className="mt-3 rounded-xl border border-emerald-200 bg-emerald-50 px-3 py-2 text-xs text-emerald-700">
            Billing enforcement is currently disabled for prototype testing. Stripe checkout and portal remain available
            for end-to-end billing tests.
          </p>
        ) : null}
        <div className="mt-4">
          <BillingActions subscribed={usage.isSubscribed} />
        </div>
      </section>

      <section className="rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
        <h2 className="text-lg font-semibold text-zinc-900">Plan details</h2>
        <ul className="mt-3 list-disc space-y-1 pl-5 text-sm text-zinc-700">
          <li>AI persona simulations in a realistic coffee-date setting</li>
          <li>Post-date coaching with rewrite options and score breakdown</li>
          <li>Safety guardrails and self-harm support handling</li>
        </ul>
      </section>
    </div>
  );
}
