// api/_lib/schemas/communicatorProfile.ts
import { z } from 'zod';

/**
 * Enhanced CommunicatorProfile schema matching the JSON schema structure
 * Tracks attachment-style learning over the 7-day onboarding window and beyond
 * Version: 1.0.0 - Last Updated: 2025-08-28
 */

// Attachment style scores object
export const attachmentScoresSchema = z.object({
  anxious: z.number().min(0).describe('Anxious attachment score'),
  avoidant: z.number().min(0).describe('Avoidant attachment score'),
  disorganized: z.number().min(0).describe('Disorganized attachment score'),
  secure: z.number().min(0).describe('Secure attachment score'),
});

// Daily counters for increments and activity
export const dailyCountersSchema = z.object({
  dayKey: z.string().describe('Current learning day (YYYY-MM-DD)'),
  incrementsToday: z.number().min(0).describe('How many signals were incremented today (bounded by daily limit)'),
});

// Learning event history item
export const historyEventSchema = z.object({
  type: z.string().describe('Type of event (e.g., increment)'),
  style: z.string().describe('Attachment style affected (e.g., anxious)'),
  weight: z.number().describe('Weight of the signal'),
  signalId: z.string().describe('Unique identifier for the signal'),
  dayKey: z.string().describe('Day when the event occurred (YYYY-MM-DD)'),
  at: z.string().datetime().describe('ISO timestamp when the event occurred'),
});

// Main CommunicatorProfile schema (matching JSON schema structure)
export const communicatorProfileSchema = z.object({
  userId: z.string().min(1, 'Each profile must include a valid userId').describe('Unique identifier for the user'),
  createdAt: z.string().datetime().describe('ISO timestamp when the profile was created'),
  updatedAt: z.string().datetime().describe('ISO timestamp of the most recent update'),
  firstSeenDay: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Must be YYYY-MM-DD format').describe('The YYYY-MM-DD date of the user\'s first interaction'),
  daysObserved: z.number().min(0).describe('Number of distinct days messages have been observed for this user'),
  scores: attachmentScoresSchema.describe('Cumulative weighted scores per attachment style'),
  counters: dailyCountersSchema.describe('Daily counters for increments and activity'),
  history: z.array(historyEventSchema).optional().describe('Rolling history of learning events. Useful for debugging and audits'),
  localPrior: z.object({
    scores: attachmentScoresSchema.describe('Normalized prior scores (sum≈1)'),
    weight: z.number().min(0).max(1).describe('Effective weight at time of seeding (decayed at read)'),
    seededAt: z.string().datetime().describe('ISO timestamp when prior was seeded'),
    lastUpdatedAt: z.string().datetime().optional().describe('If user retakes quiz, update timestamp'),
    sourceVersion: z.string().optional().describe('Assessment version, e.g., modern_v1.0'),
  }).optional().describe('Local on-device assessment prior'),
});

export type CommunicatorProfile = z.infer<typeof communicatorProfileSchema>;
export type AttachmentScores = z.infer<typeof attachmentScoresSchema>;
export type DailyCounters = z.infer<typeof dailyCountersSchema>;
export type HistoryEvent = z.infer<typeof historyEventSchema>;

// Enhanced schemas for API operations
export const createProfileSchema = communicatorProfileSchema.omit({ 
  createdAt: true, 
  updatedAt: true,
  history: true 
}).extend({
  userId: z.string().min(1, 'Valid userId required for profile creation'),
});

export const updateProfileSchema = communicatorProfileSchema.partial().omit({ 
  userId: true, 
  createdAt: true 
}).extend({
  updatedAt: z.string().datetime().optional(),
});

// Attachment estimate result schema
export const attachmentEstimateSchema = z.object({
  primary: z.string().nullable().describe('Primary attachment style'),
  secondary: z.string().nullable().describe('Secondary attachment style'),
  windowComplete: z.boolean().describe('Whether the 7-day learning window is complete'),
  confidence: z.number().min(0).max(1).describe('Confidence level of the estimate'),
  scores: attachmentScoresSchema.describe('Current attachment scores'),
  daysObserved: z.number().min(0).describe('Number of days observed'),
  totalSignals: z.number().min(0).describe('Total number of signals processed'),
});

export type AttachmentEstimate = z.infer<typeof attachmentEstimateSchema>;

// Profile status schema
export const profileStatusSchema = z.object({
  userId: z.string(),
  isActive: z.boolean(),
  profileHealth: z.object({
    attachmentConfidence: z.number().min(0).max(1),
    windowComplete: z.boolean(),
    dataQuality: z.enum(['excellent', 'good', 'fair', 'poor']).optional(),
  }),
  metadata: z.object({
    version: z.string(),
    lastUpdated: z.string().datetime(),
    status: z.enum(['active', 'inactive', 'suspended']),
  }),
});

export type ProfileStatus = z.infer<typeof profileStatusSchema>;

// Export types for API requests
export type CreateProfileRequest = z.infer<typeof createProfileSchema>;
export type UpdateProfileRequest = z.infer<typeof updateProfileSchema>;
