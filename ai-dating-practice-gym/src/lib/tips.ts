import { type DatingGoal } from "@/lib/types";

type PersonaLite = {
  name: string;
  difficulty: number;
};

const goalTips: Record<DatingGoal, string[]> = {
  find_long_term_partner: [
    "Lead with values and lifestyle fit rather than trying to impress.",
    "Ask one future-oriented question to test compatibility naturally.",
    "Share one authentic preference early instead of mirroring everything.",
  ],
  build_confidence: [
    "Keep your messages concise and calm to avoid overthinking spirals.",
    "Use one open-ended question per turn to keep momentum.",
    "Remember: warm curiosity beats perfect wording.",
  ],
  practice_better_conversations: [
    "Use a 50/50 rhythm: ask, then share a related personal detail.",
    "Reflect one thing they said before moving to a new topic.",
    "Avoid interview mode by reacting emotionally at least once every few turns.",
  ],
  explore_compatibility: [
    "Surface daily-life habits (schedule, social energy, routines) early.",
    "Notice how they respond to boundaries and differing opinions.",
    "Ask clarifying follow-ups instead of filling silence quickly.",
  ],
};

export function buildPreDateTips(input: {
  datingGoal: DatingGoal;
  persona: PersonaLite;
}): string[] {
  const base = goalTips[input.datingGoal] ?? goalTips.build_confidence;
  const personaTip =
    input.persona.difficulty >= 4
      ? `This persona is higher difficulty. Slow down and validate before pushing deeper topics with ${input.persona.name}.`
      : `Keep things light and personable with ${input.persona.name}; build rapport before heavier topics.`;

  return [personaTip, ...base.slice(0, 2)];
}
