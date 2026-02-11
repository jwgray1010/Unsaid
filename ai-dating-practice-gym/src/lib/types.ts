import { z } from "zod";

export const datingGoals = [
  "find_long_term_partner",
  "build_confidence",
  "practice_better_conversations",
  "explore_compatibility",
] as const;

export type DatingGoal = (typeof datingGoals)[number];

export const tendencyOptions = [
  "overthinking",
  "people_pleasing",
  "avoidance",
  "oversharing",
  "anxious_texting",
  "low_self_disclosure",
  "interrupting",
  "fear_of_rejection",
] as const;

export type Tendency = (typeof tendencyOptions)[number];

export const CoachingReportSchema = z.object({
  overall_score: z.number().min(0).max(100),
  summary: z.string().min(1),
  strengths: z
    .array(
      z.object({
        title: z.string().min(1),
        detail: z.string().min(1),
      }),
    )
    .min(1)
    .max(5),
  improvements: z
    .array(
      z.object({
        title: z.string().min(1),
        detail: z.string().min(1),
        action_steps: z.array(z.string().min(1)).min(2).max(5),
      }),
    )
    .min(1)
    .max(5),
  timeline: z
    .array(
      z.object({
        title: z.string().min(1),
        context: z.string().min(1),
        user_message_id: z.string().min(1),
        assistant_message_id: z.string().min(1),
        coach_note: z.string().min(1),
        rewrite_options: z.array(z.string().min(1)).min(2).max(3),
      }),
    )
    .min(3)
    .max(10),
  score_breakdown: z.object({
    balance: z.number().min(0).max(100),
    pacing: z.number().min(0).max(100),
    clarity: z.number().min(0).max(100),
    warmth: z.number().min(0).max(100),
    curiosity: z.number().min(0).max(100),
    self_disclosure: z.number().min(0).max(100),
  }),
});

export type CoachingReport = z.infer<typeof CoachingReportSchema>;

export type ChatMessage = {
  id: string;
  role: "user" | "assistant" | "system";
  content: string;
  created_at: string;
};
