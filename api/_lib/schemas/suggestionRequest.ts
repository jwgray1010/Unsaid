// api/_lib/schemas/suggestionRequest.ts
import { z } from 'zod';

/**
 * Enhanced SuggestionRequest schema matching the JSON schema structure
 * Schema for generating secure suggestions and rewrites
 * Version: 1.0.0 - Last Updated: 2025-08-28
 */

// Tone override enum (matching JSON schema)
export const toneOverrideSchema = z.enum(['alert', 'caution', 'clear']).describe('Optional override for detected tone');

// Attachment style enum (matching JSON schema)
export const attachmentStyleSchema = z.enum(['anxious', 'avoidant', 'disorganized', 'secure']).describe('User attachment style');

// Features array for response customization
export const featuresSchema = z.array(z.string()).max(8).optional().describe('Feature flags to include in the response');

// Meta object for tracing and UX decisions
export const metaSchema = z.object({
  platform: z.string().optional().describe('Platform identifier (e.g., ios_keyboard)'),
  timestamp: z.string().datetime().optional().describe('Request timestamp'),
  user: z.string().optional().describe('User identifier'),
  locale: z.string().optional().describe('User locale (e.g., en-US)'),
  context: z.string().optional().describe('Additional context information'),
}).passthrough().describe('Optional metadata for tracing and UX decisions');

// Main SuggestionRequest schema (matching JSON schema structure)
export const suggestionRequestSchema = z.object({
  text: z.string()
    .min(1, 'A valid message text (1–2000 characters) is required')
    .max(2000, 'A valid message text (1–2000 characters) is required')
    .describe('The message to improve with secure rewrites and/or therapy advice'),
  toneOverride: toneOverrideSchema.optional().describe('Optional override for detected tone. Useful for testing or manual control'),
  attachmentStyle: attachmentStyleSchema.optional().describe('Optional user attachment-style override, if already known'),
  features: featuresSchema.describe('Feature flags to include in the response. Common values: rewrite, advice, quick_fixes, evidence'),
  meta: metaSchema.optional().describe('Optional metadata for tracing and UX decisions'),
});

export type SuggestionRequest = z.infer<typeof suggestionRequestSchema>;

// Enhanced suggestion item schema
export const suggestionItemSchema = z.object({
  text: z.string().describe('Suggested rewrite text'),
  type: z.enum(['rewrite', 'addition', 'tone_adjustment', 'empathy_boost', 'advice']).describe('Type of suggestion'),
  confidence: z.number().min(0).max(1).describe('Confidence level of the suggestion'),
  reason: z.string().describe('Explanation for why this suggestion is recommended'),
  attachmentFriendly: z.boolean().optional().describe('Whether this suggestion is optimized for the user\'s attachment style'),
  category: z.enum(['communication', 'emotional', 'relationship', 'conflict_resolution']).optional().describe('Category of the suggestion'),
});

export type SuggestionItem = z.infer<typeof suggestionItemSchema>;

// Analysis results schema
export const originalAnalysisSchema = z.object({
  tone: z.string().describe('Detected tone of the original message'),
  sentiment: z.number().min(-1).max(1).describe('Sentiment score (-1 to 1)'),
  clarity_score: z.number().min(0).max(1).describe('Clarity score (0 to 1)'),
  empathy_score: z.number().min(0).max(1).describe('Empathy score (0 to 1)'),
  attachment_indicators: z.array(z.string()).optional().describe('Detected attachment style indicators'),
  communication_patterns: z.array(z.string()).optional().describe('Identified communication patterns'),
});

export type OriginalAnalysis = z.infer<typeof originalAnalysisSchema>;

// Response metadata schema
export const responseMetadataSchema = z.object({
  suggestion_count: z.number().describe('Number of suggestions generated'),
  processing_time_ms: z.number().describe('Processing time in milliseconds'),
  model_version: z.string().describe('Version of the suggestion model used'),
  features_used: z.array(z.string()).optional().describe('Features that were actually used in generation'),
  attachment_style_applied: z.string().optional().describe('Attachment style that was applied'),
});

export type ResponseMetadata = z.infer<typeof responseMetadataSchema>;

// Complete SuggestionResponse schema
export const suggestionResponseSchema = z.object({
  text: z.string().describe('Original input text'),
  suggestions: z.array(suggestionItemSchema).describe('Array of generated suggestions'),
  original_analysis: originalAnalysisSchema.describe('Analysis of the original message'),
  metadata: responseMetadataSchema.describe('Response metadata'),
  success: z.boolean().default(true).describe('Whether the request was successful'),
  version: z.string().default('1.0.0').describe('API version used'),
});

export type SuggestionResponse = z.infer<typeof suggestionResponseSchema>;

// Validation schemas for different contexts
export const conflictSuggestionRequestSchema = suggestionRequestSchema.extend({
  meta: metaSchema.extend({
    context: z.literal('conflict').describe('Conflict resolution context'),
  }).optional(),
});

export const romanticSuggestionRequestSchema = suggestionRequestSchema.extend({
  meta: metaSchema.extend({
    context: z.literal('romantic').describe('Romantic relationship context'),
  }).optional(),
});

export const professionalSuggestionRequestSchema = suggestionRequestSchema.extend({
  meta: metaSchema.extend({
    context: z.literal('professional').describe('Professional communication context'),
  }).optional(),
});

// Export context-specific types
export type ConflictSuggestionRequest = z.infer<typeof conflictSuggestionRequestSchema>;
export type RomanticSuggestionRequest = z.infer<typeof romanticSuggestionRequestSchema>;
export type ProfessionalSuggestionRequest = z.infer<typeof professionalSuggestionRequestSchema>;
