import { NextResponse } from "next/server";

import { hasActiveSubscription } from "@/lib/access";
import { getPublicEnv } from "@/lib/env";
import { getStripeClient } from "@/lib/stripe";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function POST() {
  try {
    const supabase = await createSupabaseServerClient();
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { data: existingSubscription } = await supabase
      .from("subscriptions")
      .select("status,current_period_end,stripe_customer_id")
      .eq("user_id", user.id)
      .maybeSingle();

    if (hasActiveSubscription(existingSubscription)) {
      return NextResponse.json({ error: "You already have an active subscription." }, { status: 400 });
    }

    const stripe = getStripeClient();
    const appUrl = getPublicEnv("NEXT_PUBLIC_APP_URL");
    const priceId = getPublicEnv("NEXT_PUBLIC_STRIPE_PRICE_ID");

    const checkoutSession = await stripe.checkout.sessions.create({
      mode: "subscription",
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: `${appUrl}/app/billing?success=1`,
      cancel_url: `${appUrl}/app/billing?canceled=1`,
      customer: existingSubscription?.stripe_customer_id ?? undefined,
      customer_email: existingSubscription?.stripe_customer_id ? undefined : user.email ?? undefined,
      metadata: {
        userId: user.id,
      },
      subscription_data: {
        metadata: {
          userId: user.id,
        },
      },
      allow_promotion_codes: true,
    });

    if (!checkoutSession.url) {
      return NextResponse.json({ error: "Unable to create checkout session." }, { status: 500 });
    }

    return NextResponse.json({ url: checkoutSession.url });
  } catch (error) {
    console.error("stripe checkout error", error);
    return NextResponse.json({ error: "Internal server error." }, { status: 500 });
  }
}
