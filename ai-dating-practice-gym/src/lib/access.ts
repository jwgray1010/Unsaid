const ACTIVE_STATUSES = new Set(["active", "trialing", "past_due"]);
const billingEnforced = process.env.BILLING_ENFORCED === "true";

type SubscriptionRow = {
  status: string | null;
  current_period_end: string | null;
};

export function hasActiveSubscription(subscription: SubscriptionRow | null): boolean {
  if (!subscription?.status) {
    return false;
  }

  if (!ACTIVE_STATUSES.has(subscription.status)) {
    return false;
  }

  if (!subscription.current_period_end) {
    return true;
  }

  return new Date(subscription.current_period_end).getTime() > Date.now();
}

export async function getUsageAccess(
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  supabase: any,
  userId: string,
) {
  const [{ data: subscription }, sessionsResult] = await Promise.all([
    supabase.from("subscriptions").select("status,current_period_end").eq("user_id", userId).maybeSingle(),
    supabase.from("sessions").select("id", { count: "exact", head: true }).eq("user_id", userId),
  ]);

  const isSubscribed = hasActiveSubscription(subscription);
  const sessionCount = sessionsResult.count ?? 0;
  const hasFreeSessionRemaining = sessionCount < 1;
  const isPrototypeMode = !billingEnforced;

  return {
    billingEnforced,
    isPrototypeMode,
    isSubscribed,
    sessionCount,
    hasFreeSessionRemaining,
    canStartSession: isPrototypeMode || isSubscribed || hasFreeSessionRemaining,
  };
}
