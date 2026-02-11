import { ProfileForm } from "@/components/profile-form";
import { getProfile, requireUser } from "@/lib/auth";

export default async function ProfilePage() {
  const { user } = await requireUser();
  const profile = await getProfile(user.id);

  return (
    <div className="mx-auto max-w-2xl space-y-4">
      <div>
        <h1 className="text-2xl font-semibold text-zinc-900">Complete your profile</h1>
        <p className="mt-1 text-sm text-zinc-600">
          This helps tailor date simulations and coaching feedback.
        </p>
      </div>
      <ProfileForm
        userId={user.id}
        initialProfile={
          profile
            ? {
                display_name: profile.display_name,
                dating_goal: profile.dating_goal,
                tendencies: Array.isArray(profile.tendencies) ? profile.tendencies : [],
                comfort_level: profile.comfort_level,
              }
            : null
        }
      />
    </div>
  );
}
