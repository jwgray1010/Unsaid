import { redirect } from "next/navigation";

import { AuthForm } from "@/components/auth-form";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export default async function LoginPage() {
  const supabase = await createSupabaseServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (user) {
    redirect("/app");
  }

  return (
    <div className="mx-auto flex max-w-md flex-col gap-4">
      <div>
        <h1 className="text-2xl font-semibold text-zinc-900">Welcome back</h1>
        <p className="mt-1 text-sm text-zinc-600">Create an account or log in to continue your practice sessions.</p>
      </div>
      <AuthForm />
    </div>
  );
}
