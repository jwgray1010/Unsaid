type ProfileSummaryInput = {
  display_name: string | null;
  dating_goal: string;
  tendencies: string[];
  comfort_level: number;
};

export function buildProfileSummary(profile: ProfileSummaryInput): string {
  const tendencies = profile.tendencies.length > 0 ? profile.tendencies.join(", ") : "none specified";
  return [
    `Name: ${profile.display_name ?? "Not provided"}`,
    `Dating goal: ${profile.dating_goal}`,
    `Common tendencies: ${tendencies}`,
    `Comfort level (1-5): ${profile.comfort_level}`,
  ].join(" | ");
}
