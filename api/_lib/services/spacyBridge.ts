// api/_lib/services/spacyBridge.ts
import { logger } from '../logger';
import { spacyClient } from './spacyClient';

export interface CompactDoc {
  tokens?: Array<{ text: string; lemma: string; pos: string; i: number }>;
  sents?: Array<{ start: number; end: number }>;
  deps?: Array<{ head?: number; dep?: string; rel?: string; i?: number }>;
  sarcasm?: { present: boolean; score?: number };
  context?: { label: string; score: number };
  phraseEdges?: { hits: string[] } | string[];
}

// Main processing function - simplified for serverless
export async function processWithSpacy(text: string, mode?: string): Promise<CompactDoc> {
  try {
    logger.info(`Processing text with spaCy client: ${text.substring(0, 50)}...`);

    // Use the TypeScript spaCy client
    const result = spacyClient.process(text);

    // Convert to compact format expected by toneAnalysis
    const compact: CompactDoc = {
      tokens: result.features.featureCount > 0 ? [{
        text: text.split(/\s+/)[0] || '',
        lemma: text.split(/\s+/)[0]?.toLowerCase() || '',
        pos: 'NOUN',
        i: 0
      }] : undefined,
      sents: [{ start: 0, end: text.length }],
      deps: [],
      sarcasm: {
        present: result.sarcasm.present,
        score: result.sarcasm.score
      },
      context: {
        label: result.context.label,
        score: result.context.score
      },
      phraseEdges: result.phraseEdges.hits
    };

    logger.info(`spaCy processing completed successfully`);
    return compact;

  } catch (error) {
    logger.error('spaCy processing failed:', error);
    // Return minimal fallback result
    return {
      tokens: [],
      sents: [{ start: 0, end: text.length }],
      deps: [],
      sarcasm: { present: false, score: 0 },
      context: { label: 'general', score: 0.1 },
      phraseEdges: []
    };
  }
}

// Synchronous version for cases where async is not needed
export function processWithSpacySync(text: string, mode?: string): CompactDoc {
  try {
    logger.debug(`Processing text with spaCy client (sync): ${text.substring(0, 50)}...`);

    // Use the TypeScript spaCy client
    const result = spacyClient.process(text);

    // Convert to compact format expected by toneAnalysis
    const compact: CompactDoc = {
      tokens: result.features.featureCount > 0 ? [{
        text: text.split(/\s+/)[0] || '',
        lemma: text.split(/\s+/)[0]?.toLowerCase() || '',
        pos: 'NOUN',
        i: 0
      }] : undefined,
      sents: [{ start: 0, end: text.length }],
      deps: [],
      sarcasm: {
        present: result.sarcasm.present,
        score: result.sarcasm.score
      },
      context: {
        label: result.context.label,
        score: result.context.score
      },
      phraseEdges: result.phraseEdges.hits
    };

    return compact;

  } catch (error) {
    logger.error('spaCy processing failed (sync):', error);
    // Return minimal fallback result
    return {
      tokens: [],
      sents: [{ start: 0, end: text.length }],
      deps: [],
      sarcasm: { present: false, score: 0 },
      context: { label: 'general', score: 0.1 },
      phraseEdges: []
    };
  }
}

// Health check
export async function checkSpacyHealth(): Promise<boolean> {
  try {
    await spacyClient.healthCheck();
    return true;
  } catch (error) {
    logger.error('spaCy health check failed:', error);
    return false;
  }
}
