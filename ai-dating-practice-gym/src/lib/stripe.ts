import Stripe from "stripe";

import { getServerEnv } from "@/lib/env";

let stripe: Stripe | null = null;

export function getStripeClient() {
  if (!stripe) {
    stripe = new Stripe(getServerEnv("STRIPE_SECRET_KEY"));
  }
  return stripe;
}
