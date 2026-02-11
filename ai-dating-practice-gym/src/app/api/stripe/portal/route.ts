import { NextResponse } from "next/server";

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

    const { data: subscription } = await supabase
      .from("subscriptions")
      .select("stripe_customer_id")
      .eq("user_id", user.id)
      .maybeSingle();

    if (!subscription?.stripe_customer_id) {
      return NextResponse.json({ error: "No billing account found for this user." }, { status: 400 });
    }

    const stripe = getStripeClient();
    const portalSession = await stripe.billingPortal.sessions.create({
      customer: subscription.stripe_customer_id,
      return_url: `${getPublicEnv("NEXT_PUBLIC_APP_URL")}/app/billing`,
    });

    return NextResponse.json({ url: portalSession.url });
  } catch (error) {
    console.error("stripe portal error", error);
    return NextResponse.json({ error: "Internal server error." }, { status: 500 });
  }
}
