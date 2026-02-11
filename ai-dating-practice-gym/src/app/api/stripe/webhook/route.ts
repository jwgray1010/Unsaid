import { NextResponse } from "next/server";
import Stripe from "stripe";

import { getServerEnv } from "@/lib/env";
import { getStripeClient } from "@/lib/stripe";
import { createSupabaseAdminClient } from "@/lib/supabase/admin";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

function toIso(unixSeconds: number | null | undefined) {
  if (!unixSeconds) {
    return null;
  }
  return new Date(unixSeconds * 1000).toISOString();
}

function getSubscriptionPeriodEnd(subscription: Stripe.Subscription): number | null {
  const ends = subscription.items.data
    .map((item) => item.current_period_end)
    .filter((value): value is number => typeof value === "number");
  if (ends.length === 0) {
    return null;
  }
  return Math.max(...ends);
}

async function findUserIdByCustomer(customerId: string) {
  const supabase = createSupabaseAdminClient();
  const { data } = await supabase
    .from("subscriptions")
    .select("user_id")
    .eq("stripe_customer_id", customerId)
    .maybeSingle();
  return data?.user_id ?? null;
}

async function upsertSubscription(params: {
  userId: string;
  customerId: string | null;
  subscriptionId: string | null;
  status: string | null;
  currentPeriodEnd: number | null | undefined;
}) {
  const supabase = createSupabaseAdminClient();
  await supabase.from("subscriptions").upsert(
    {
      user_id: params.userId,
      stripe_customer_id: params.customerId,
      stripe_subscription_id: params.subscriptionId,
      status: params.status,
      current_period_end: toIso(params.currentPeriodEnd),
    },
    { onConflict: "user_id" },
  );
}

export async function POST(request: Request) {
  const stripe = getStripeClient();
  const payload = await request.text();
  const signature = request.headers.get("stripe-signature");
  if (!signature) {
    return NextResponse.json({ error: "Missing stripe-signature header." }, { status: 400 });
  }

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(payload, signature, getServerEnv("STRIPE_WEBHOOK_SECRET"));
  } catch (error) {
    console.error("stripe webhook verification error", error);
    return NextResponse.json({ error: "Invalid webhook signature." }, { status: 400 });
  }

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
        const userId = session.metadata?.userId;
        const customerId = typeof session.customer === "string" ? session.customer : null;
        const subscriptionId = typeof session.subscription === "string" ? session.subscription : null;

        if (!userId) {
          break;
        }

        let status: string | null = null;
        let currentPeriodEnd: number | null = null;
        if (subscriptionId) {
          const subscription = await stripe.subscriptions.retrieve(subscriptionId);
          status = subscription.status;
          currentPeriodEnd = getSubscriptionPeriodEnd(subscription);
        }

        await upsertSubscription({
          userId,
          customerId,
          subscriptionId,
          status,
          currentPeriodEnd,
        });
        break;
      }

      case "customer.subscription.created":
      case "customer.subscription.updated":
      case "customer.subscription.deleted": {
        const subscription = event.data.object as Stripe.Subscription;
        const customerId = typeof subscription.customer === "string" ? subscription.customer : null;
        let userId = subscription.metadata?.userId ?? null;
        if (!userId && customerId) {
          userId = await findUserIdByCustomer(customerId);
        }

        if (!userId) {
          break;
        }

        await upsertSubscription({
          userId,
          customerId,
          subscriptionId: subscription.id,
          status: subscription.status,
          currentPeriodEnd: getSubscriptionPeriodEnd(subscription),
        });
        break;
      }

      default:
        break;
    }

    return NextResponse.json({ received: true });
  } catch (error) {
    console.error("stripe webhook handler error", error);
    return NextResponse.json({ error: "Webhook handler failed." }, { status: 500 });
  }
}
