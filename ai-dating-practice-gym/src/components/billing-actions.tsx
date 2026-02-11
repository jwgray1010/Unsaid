"use client";

import { useState } from "react";

type BillingActionsProps = {
  subscribed: boolean;
};

async function postForUrl(endpoint: string) {
  const response = await fetch(endpoint, {
    method: "POST",
  });

  const payload = (await response.json()) as { url?: string; error?: string };
  if (!response.ok || !payload.url) {
    throw new Error(payload.error ?? "Unable to start billing flow.");
  }

  window.location.href = payload.url;
}

export function BillingActions({ subscribed }: BillingActionsProps) {
  const [loadingCheckout, setLoadingCheckout] = useState(false);
  const [loadingPortal, setLoadingPortal] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");

  return (
    <div className="space-y-3">
      {subscribed ? (
        <button
          type="button"
          disabled={loadingPortal}
          onClick={async () => {
            setErrorMessage("");
            setLoadingPortal(true);
            try {
              await postForUrl("/api/stripe/portal");
            } catch (error) {
              setErrorMessage(error instanceof Error ? error.message : "Unable to open portal.");
            } finally {
              setLoadingPortal(false);
            }
          }}
          className="rounded-xl border border-zinc-300 px-4 py-2 text-sm font-semibold text-zinc-700 transition hover:bg-zinc-100 disabled:cursor-not-allowed disabled:text-zinc-400"
        >
          {loadingPortal ? "Opening..." : "Manage subscription"}
        </button>
      ) : (
        <button
          type="button"
          disabled={loadingCheckout}
          onClick={async () => {
            setErrorMessage("");
            setLoadingCheckout(true);
            try {
              await postForUrl("/api/stripe/checkout");
            } catch (error) {
              setErrorMessage(error instanceof Error ? error.message : "Unable to start checkout.");
            } finally {
              setLoadingCheckout(false);
            }
          }}
          className="rounded-xl bg-zinc-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-zinc-700 disabled:cursor-not-allowed disabled:bg-zinc-400"
        >
          {loadingCheckout ? "Redirecting..." : "Upgrade to Pro"}
        </button>
      )}

      {errorMessage ? <p className="text-sm text-red-600">{errorMessage}</p> : null}
    </div>
  );
}
