"use client";

import { useMemo, useState } from "react";
import { useRouter } from "next/navigation";

import { createSupabaseBrowserClient } from "@/lib/supabase/browser";
import { datingGoals, tendencyOptions, type DatingGoal, type Tendency } from "@/lib/types";

type ProfileFormProps = {
  userId: string;
  initialProfile: {
    display_name: string | null;
    dating_goal: string;
    tendencies: string[];
    comfort_level: number;
  } | null;
};

export function ProfileForm({ userId, initialProfile }: ProfileFormProps) {
  const router = useRouter();
  const supabase = useMemo(() => createSupabaseBrowserClient(), []);

  const [displayName, setDisplayName] = useState(initialProfile?.display_name ?? "");
  const [datingGoal, setDatingGoal] = useState<DatingGoal>(
    (initialProfile?.dating_goal as DatingGoal) ?? "build_confidence",
  );
  const [comfortLevel, setComfortLevel] = useState<number>(initialProfile?.comfort_level ?? 3);
  const [tendencies, setTendencies] = useState<Tendency[]>(
    (initialProfile?.tendencies as Tendency[] | undefined) ?? [],
  );
  const [loading, setLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");

  function toggleTendency(option: Tendency) {
    setTendencies((current) =>
      current.includes(option) ? current.filter((value) => value !== option) : [...current, option],
    );
  }

  async function onSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setLoading(true);
    setErrorMessage("");

    try {
      const { error } = await supabase.from("profiles").upsert(
        {
          user_id: userId,
          display_name: displayName || null,
          dating_goal: datingGoal,
          tendencies,
          comfort_level: comfortLevel,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "user_id" },
      );

      if (error) {
        setErrorMessage(error.message);
        return;
      }

      router.push("/app");
      router.refresh();
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={onSubmit} className="space-y-6 rounded-2xl border border-zinc-200 bg-white p-6 shadow-sm">
      <label className="block text-sm font-medium text-zinc-700">
        Display name (optional)
        <input
          type="text"
          value={displayName}
          onChange={(event) => setDisplayName(event.target.value)}
          placeholder="Alex"
          className="mt-1 w-full rounded-xl border border-zinc-300 px-3 py-2 text-sm outline-none ring-zinc-300 focus:ring-2"
        />
      </label>

      <label className="block text-sm font-medium text-zinc-700">
        Dating goal
        <select
          value={datingGoal}
          onChange={(event) => setDatingGoal(event.target.value as DatingGoal)}
          className="mt-1 w-full rounded-xl border border-zinc-300 px-3 py-2 text-sm outline-none ring-zinc-300 focus:ring-2"
        >
          {datingGoals.map((goal) => (
            <option key={goal} value={goal}>
              {goal.replaceAll("_", " ")}
            </option>
          ))}
        </select>
      </label>

      <fieldset>
        <legend className="text-sm font-medium text-zinc-700">Tendencies (choose any)</legend>
        <div className="mt-2 grid grid-cols-1 gap-2 sm:grid-cols-2">
          {tendencyOptions.map((option) => {
            const checked = tendencies.includes(option);
            return (
              <label
                key={option}
                className={`flex cursor-pointer items-center gap-2 rounded-xl border px-3 py-2 text-sm ${
                  checked ? "border-zinc-900 bg-zinc-50" : "border-zinc-300"
                }`}
              >
                <input
                  type="checkbox"
                  checked={checked}
                  onChange={() => toggleTendency(option)}
                  className="h-4 w-4 rounded border-zinc-300"
                />
                <span>{option.replaceAll("_", " ")}</span>
              </label>
            );
          })}
        </div>
      </fieldset>

      <label className="block text-sm font-medium text-zinc-700">
        Comfort level (1-5)
        <input
          type="range"
          min={1}
          max={5}
          value={comfortLevel}
          onChange={(event) => setComfortLevel(Number(event.target.value))}
          className="mt-2 w-full accent-zinc-900"
        />
        <span className="mt-1 block text-sm text-zinc-600">{comfortLevel}</span>
      </label>

      {errorMessage ? <p className="text-sm text-red-600">{errorMessage}</p> : null}

      <button
        type="submit"
        disabled={loading}
        className="rounded-xl bg-zinc-900 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-zinc-700 disabled:cursor-not-allowed disabled:bg-zinc-400"
      >
        {loading ? "Saving..." : "Save profile"}
      </button>
    </form>
  );
}
