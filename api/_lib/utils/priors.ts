// api/_lib/utils/priors.ts
// Local prior blending utilities for attachment style estimation
import type { AttachmentScores } from '../schemas/communicatorProfile';

export interface NormalizedScores extends AttachmentScores {}

export function normalizeScores(s: Partial<AttachmentScores>): NormalizedScores {
  const anxious = Math.max(0, s.anxious || 0);
  const avoidant = Math.max(0, s.avoidant || 0);
  const disorganized = Math.max(0, s.disorganized || 0);
  const secure = Math.max(0, s.secure || 0);
  const sum = anxious + avoidant + disorganized + secure || 1e-9;
  return {
    anxious: anxious / sum,
    avoidant: avoidant / sum,
    disorganized: disorganized / sum,
    secure: secure / sum,
  };
}

export function defaultPriorWeight(daysObserved: number, learningDays: number) {
  const floor = 0.2;
  const w = 1 - Math.min(1, daysObserved / Math.max(1, learningDays));
  return Math.max(floor, w);
}
