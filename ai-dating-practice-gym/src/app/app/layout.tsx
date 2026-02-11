import Link from "next/link";
import { redirect } from "next/navigation";

import { requireUser } from "@/lib/auth";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export default async function AppLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const { user } = await requireUser();

  async function logout() {
    "use server";
    const supabase = await createSupabaseServerClient();
    await supabase.auth.signOut();
    redirect("/login");
  }

  return (
    <div className="space-y-6">
      <div className="rounded-2xl border border-zinc-200 bg-white p-4 shadow-sm">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p className="text-xs uppercase tracking-wide text-zinc-500">Signed in</p>
            <p className="text-sm font-medium text-zinc-800">{user.email}</p>
          </div>
          <div className="flex flex-wrap gap-2 text-sm">
            <Link href="/app" className="rounded-lg px-3 py-1.5 text-zinc-700 hover:bg-zinc-100">
              Dashboard
            </Link>
            <Link href="/app/personas" className="rounded-lg px-3 py-1.5 text-zinc-700 hover:bg-zinc-100">
              Practice
            </Link>
            <Link href="/app/billing" className="rounded-lg px-3 py-1.5 text-zinc-700 hover:bg-zinc-100">
              Billing
            </Link>
            <form action={logout}>
              <button
                type="submit"
                className="rounded-lg border border-zinc-300 px-3 py-1.5 text-zinc-700 hover:bg-zinc-100"
              >
                Log out
              </button>
            </form>
          </div>
        </div>
      </div>

      <div>{children}</div>
    </div>
  );
}
