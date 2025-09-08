// api/_lib/schemas/toneRequest.ts
import { z } from 'zod';

/**
 * Enhanced ToneRequest schema matching the JSON schema structure
 * Schema for tone analysis requests with optional metadata
 * Version: 1.0.0 - Last Updated: 2025-08-28
 */

// Context enum (matching JSON schema exactly)
export const contextSchema = z.enum(['conflict', 'repair', 'jealousy', 'boundary', 'general']).describe('Optional hint about conversation context to improve classification');

// Tone override enum
export const toneOverrideSchema = z.enum(['alert', 'caution', 'clear']).describe('Optional override for detected tone');

// Attachment style enum
export const attachmentStyleSchema = z.enum(['anxious', 'avoidant', 'disorganized', 'secure']).describe('User attachment style');

// Meta object for request metadata (matching JSON schema structure)
export const metaSchema = z.object({
  platform: z.string().optional().describe('Platform identifier (e.g., ios_keyboard)'),
  timestamp: z.string().datetime().optional().describe('Request timestamp'),
  user: z.string().optional().describe('User identifier'),
  locale: z.string().optional().describe('User locale'),
  sessionId: z.string().optional().describe('Session identifier for tracking'),
  requestId: z.string().optional().describe('Unique request identifier'),
}).passthrough().describe('Optional metadata about the request (platform, timestamp, user info)');

// Main ToneRequest schema (matching JSON schema structure)
export const toneRequestSchema = z.object({
  text: z.string()
    .min(1, 'A valid message text (1–5000 characters) is required')
    .max(5000, 'A valid message text (1–5000 characters) is required')
    .describe('The user\'s message text to analyze for tone'),
  context: contextSchema.optional().default('general').describe('Optional hint about conversation context to improve classification'),
  meta: metaSchema.optional().describe('Optional metadata about the request (platform, timestamp, user info)'),
  // Extended fields for enhanced functionality
  toneOverride: toneOverrideSchema.optional().describe('Optional override for detected tone'),
  attachmentStyle: attachmentStyleSchema.optional().describe('Optional user attachment style for personalized analysis'),
  includeSuggestions: z.boolean().optional().default(true).describe('Whether to include improvement suggestions'),
  includeEmotions: z.boolean().optional().default(true).describe('Whether to include emotion analysis'),
  includeAttachmentInsights: z.boolean().optional().default(false).describe('Whether to include attachment-specific insights'),
  deepAnalysis: z.boolean().optional().default(false).describe('Whether to perform deep linguistic analysis'),
});

export type ToneRequest = z.infer<typeof toneRequestSchema>;

// Attachment estimate schema for responses
export const attachmentEstimateSchema = z.object({
  primary: z.string().nullable().describe('Primary attachment style'),
  secondary: z.string().nullable().describe('Secondary attachment style'),
  windowComplete: z.boolean().describe('Whether the 7-day learning window is complete'),
  confidence: z.number().min(0).max(1).describe('Confidence level of the estimate'),
});

export type AttachmentEstimate = z.infer<typeof attachmentEstimateSchema>;

// Emotion analysis schema
export const emotionAnalysisSchema = z.object({
  primary_emotion: z.string().describe('Primary detected emotion'),
  intensity: z.number().min(0).max(1).describe('Emotional intensity (0-1)'),
  emotions: z.record(z.number()).describe('Emotion scores by type'),
  emotional_stability: z.number().min(0).max(1).describe('Stability score of emotional state'),
});

export type EmotionAnalysis = z.infer<typeof emotionAnalysisSchema>;

// Enhanced tone response schema
export const toneResponseSchema = z.object({
  ok: z.boolean().describe('Whether the analysis was successful'),
  userId: z.string().describe('User identifier'),
  text: z.string().describe('Original input text'),
  attachmentEstimate: attachmentEstimateSchema.describe('Attachment style estimate'),
  tone: z.enum(['alert', 'caution', 'clear']).describe('Detected tone classification'),
  confidence: z.number().min(0).max(1).describe('Confidence level of tone detection'),
  scores: z.record(z.number()).describe('Tone scores by category'),
  context: z.string().describe('Context used for analysis'),
  evidence: z.array(z.string()).describe('Evidence supporting the tone classification'),
  rewritability: z.number().min(0).max(1).describe('How much the message could benefit from rewriting'),
  // Enhanced response fields
  emotions: emotionAnalysisSchema.optional().describe('Emotion analysis results'),
  suggestions: z.array(z.object({
    text: z.string(),
    reason: z.string(),
    confidence: z.number().min(0).max(1),
  })).optional().describe('Improvement suggestions'),
  attachmentInsights: z.array(z.string()).optional().describe('Attachment-specific insights'),
  communicationPatterns: z.array(z.string()).optional().describe('Detected communication patterns'),
  metadata: z.object({
    processing_time_ms: z.number(),
    model_version: z.string(),
    analysis_depth: z.enum(['basic', 'standard', 'deep']),
    features_used: z.array(z.string()),
  }).describe('Analysis metadata'),
  version: z.string().default('1.0.0').describe('API version'),
  timestamp: z.string().datetime().describe('Response timestamp'),
});

export type ToneResponse = z.infer<typeof toneResponseSchema>;

// Context-specific tone request schemas
export const conflictToneRequestSchema = toneRequestSchema.extend({
  context: z.literal('conflict'),
  includeAttachmentInsights: z.boolean().default(true),
});

export const repairToneRequestSchema = toneRequestSchema.extend({
  context: z.literal('repair'),
  includeSuggestions: z.boolean().default(true),
});

export const boundaryToneRequestSchema = toneRequestSchema.extend({
  context: z.literal('boundary'),
  deepAnalysis: z.boolean().default(true),
});

// Export context-specific types
export type ConflictToneRequest = z.infer<typeof conflictToneRequestSchema>;
export type RepairToneRequest = z.infer<typeof repairToneRequestSchema>;
export type BoundaryToneRequest = z.infer<typeof boundaryToneRequestSchema>;

// Validation helper functions
export function validateToneRequest(data: unknown): ToneRequest {
  return toneRequestSchema.parse(data);
}

export function validateToneRequestSafe(data: unknown): { success: true; data: ToneRequest } | { success: false; error: z.ZodError } {
  const result = toneRequestSchema.safeParse(data);
  if (result.success) {
    return { success: true, data: result.data };
  }
  return { success: false, error: result.error };
}
