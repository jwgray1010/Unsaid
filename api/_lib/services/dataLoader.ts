// api/_lib/services/dataLoader.ts
import * as fs from 'fs';
import * as path from 'path';
import { z } from 'zod';
import { logger } from '../logger';
import type {
  AttachmentLearningConfig,
  DataCache
} from '../types/dataTypes';

class DataLoaderService {
  private cache: DataCache = {};
  private dataPath: string;
  private initialized: boolean = false;

  constructor() {
    // The data folder is at the root of the unsaid-backend project
    // From api/_lib/services/, the data folder is at ../../../data/
    const possiblePaths = [
      path.resolve(__dirname, '../../../data'),     // api/_lib/services/ -> data/
      path.resolve(__dirname, '../../../../data'),  // Alternative nesting
      path.resolve(process.cwd(), 'data'),          // From project root
      path.resolve('/vercel/path0', 'data'),        // Vercel serverless path
      path.resolve(process.env.LAMBDA_TASK_ROOT || process.cwd(), 'data')
    ];
    
    // Find the first path that exists
    this.dataPath = possiblePaths.find(p => {
      try {
        return fs.existsSync(p);
      } catch {
        return false;
      }
    }) || possiblePaths[0];
    
    logger.info(`DataLoader initialized with path: ${this.dataPath}`);
    logger.info(`Available paths checked: ${possiblePaths.join(', ')}`);
    logger.info(`Data path exists: ${fs.existsSync(this.dataPath)}`);
    
    // List files in the data directory for debugging
    try {
      if (fs.existsSync(this.dataPath)) {
        const files = fs.readdirSync(this.dataPath);
        logger.info(`Files in data directory: ${files.join(', ')}`);
      }
    } catch (err) {
      logger.warn(`Could not list files in data directory: ${err}`);
    }

    // Pre-initialize synchronously to avoid async issues
    this.initializeSync();
  }

  private readJsonSafe<T>(filename: string, fallback: T): T {
    try {
      const filepath = path.join(this.dataPath, filename);
      logger.info(`Attempting to read: ${filepath}`);
      
      if (fs.existsSync(filepath)) {
        const content = fs.readFileSync(filepath, 'utf-8');
        const parsed = JSON.parse(content);
        logger.info(`Successfully loaded ${filename} (${content.length} chars)`);
        return parsed;
      } else {
        logger.warn(`File not found: ${filepath}`);
        // List directory contents for debugging
        try {
          const dirContents = fs.readdirSync(this.dataPath);
          logger.info(`Data directory contents: ${dirContents.join(', ')}`);
        } catch (dirError) {
          logger.error(`Cannot read data directory ${this.dataPath}:`, dirError);
        }
        return fallback;
      }
    } catch (error) {
      logger.error(`Error loading ${filename} from ${this.dataPath}:`, error);
      return fallback;
    }
  }

  public initializeSync(): void {
    if (this.initialized) {
      return;
    }

    try {
      logger.info('Initializing data cache synchronously...');

      // Load all JSON data files - using exact fallbacks from original JS (suggestions.js pattern)
      
      // Critical config files that should fail fast (use null)
      this.cache.attachmentLearning = this.readJsonSafe<AttachmentLearningConfig>(
        'attachment_learning.json',
        null as any // Match original JS behavior - fail fast, don't use elaborate fallbacks
      );

      this.cache.attachmentLearningEnhanced = this.readJsonSafe<AttachmentLearningConfig>(
        'attachment_learning_enhanced.json',
        null as any
      );

      // Standard data files with version + array pattern (from original suggestions.js)
      this.cache.therapyAdvice = this.readJsonSafe<any>(
        'therapy_advice.json',
        { version: '0', items: [] }
      );

      this.cache.contextClassifier = this.readJsonSafe<any>(
        'context_classifier.json',
        { version: '0', contexts: [] }
      );

      this.cache.toneTriggerWords = this.readJsonSafe<any>(
        'tone_triggerwords.json',
        { version: '0', triggers: [] }
      );

      this.cache.intensityModifiers = this.readJsonSafe<any>(
        'intensity_modifiers.json',
        { version: '0', modifiers: [] }
      );

      this.cache.sarcasmIndicators = this.readJsonSafe<any>(
        'sarcasm_indicators.json',
        { version: '0', sarcasm_indicators: [] }
      );

      this.cache.negationIndicators = this.readJsonSafe<any>(
        'negation_indicators.json',
        { version: '0', negation_indicators: [] }
      );

      this.cache.phraseEdges = this.readJsonSafe<any>(
        'phrase_edges.json',
        { version: '0', edges: [] }
      );

      this.cache.evaluationTones = this.readJsonSafe<any>(
        'evaluation_tones.json',
        { version: '0', tones: [] }
      );

      this.cache.tonePatterns = this.readJsonSafe<any>(
        'tone_patterns.json',
        { version: '0', patterns: [] }
      );

      this.cache.learningSignals = this.readJsonSafe<any>(
        'learning_signals.json',
        { version: '0', signals: [] }
      );

      this.cache.negationPatterns = this.readJsonSafe<any>(
        'negation_patterns.json',
        { version: '0', patterns: [] }
      );

      this.cache.profanityLexicons = this.readJsonSafe<any>(
        'profanity_lexicons.json',
        { version: '0', words: [] }
      );

      this.cache.weightModifiers = this.readJsonSafe<any>(
        'weight_modifiers.json',
        { version: '0', modifiers: [] }
      );

      this.cache.attachmentOverrides = this.readJsonSafe<any>(
        'attachment_overrides.json',
        { version: '0', overrides: [] }
      );

      this.cache.onboardingPlaybook = this.readJsonSafe<any>(
        'onboarding_playbook.json',
        { version: '0', steps: [] }
      );

      // Special structure files (from original suggestions.js)
      this.cache.severityCollaboration = this.readJsonSafe<any>(
        'severity_collaboration.json',
        { alert: { base: 0.55 }, caution: { base: 0.4 }, clear: { base: 0.35 } }
      );

      this.cache.semanticThesaurus = this.readJsonSafe<any>(
        'semantic_thesaurus.json',
        { version: '0' }
      );

      // Missing files found in tone-analysis-endpoint.js
      this.cache.severityCollab = this.readJsonSafe<any>(
        'severity_collaboration.json',
        { alert: { base: 0.55 }, caution: { base: 0.40 }, clear: { base: 0.35 } }
      );

      this.cache.weightProfiles = this.readJsonSafe<any>(
        'weightMultiplierProfiles.json',
        { version: '1.0', profiles: {} }
      );

      this.cache.userPreferences = this.readJsonSafe<any>(
        'user_preference.json',
        { categories: {} }
      );

      this.cache.guardrailConfig = this.readJsonSafe<any>(
        'guardrail_config.json',
        { blockedPatterns: [] }
      );

      // Complex tone bucket mapping (from original suggestions.js toneBucketMap fallback)
      this.cache.toneBucketMapping = this.readJsonSafe<any>(
        'tone_bucket_mapping.json',
        {
          version: '1.0',
          default: {
            neutral:   { clear: 0.70, caution: 0.25, alert: 0.05 },
            positive:  { clear: 0.80, caution: 0.18, alert: 0.02 },
            supportive:{ clear: 0.85, caution: 0.13, alert: 0.02 },
            angry:     { clear: 0.05, caution: 0.30, alert: 0.65 },
            frustrated:{ clear: 0.10, caution: 0.55, alert: 0.35 },
            anxious:   { clear: 0.15, caution: 0.60, alert: 0.25 },
            sad:       { clear: 0.25, caution: 0.60, alert: 0.15 }
          },
          contextOverrides: {
            conflict: {
              angry:      { clear: 0.02, caution: 0.18, alert: 0.80 },
              frustrated: { clear: 0.05, caution: 0.50, alert: 0.45 },
              anxious:    { clear: 0.10, caution: 0.55, alert: 0.35 }
            },
            repair: {
              angry:      { clear: 0.10, caution: 0.50, alert: 0.40 },
              frustrated: { clear: 0.15, caution: 0.60, alert: 0.25 }
            }
          },
          intensityShifts: {
            thresholds: { low: 0.15, med: 0.35, high: 0.60 },
            low:  { alert: -0.10, caution: +0.08, clear: +0.02 },
            med:  { alert:  0.00, caution:  0.00, clear:  0.00 },
            high: { alert: +0.12, caution: -0.08, clear: -0.04 }
          }
        }
      );

      this.initialized = true;
      logger.info('Data cache initialized successfully (sync)');
    } catch (error) {
      logger.error('Failed to initialize data cache synchronously:', error);
      // Don't throw error in sync initialization - just log and continue with empty cache
      this.initialized = true; // Mark as initialized even on failure to prevent re-init attempts
    }
  }

  public async initialize(): Promise<void> {
    if (this.initialized) {
      return;
    }

    try {
      logger.info('Initializing data cache...');

      // Load all JSON data files - using exact fallbacks from original JS (suggestions.js pattern)
      
      // Critical config files that should fail fast (use null)
      this.cache.attachmentLearning = this.readJsonSafe<AttachmentLearningConfig>(
        'attachment_learning.json',
        null as any // Match original JS behavior - fail fast, don't use elaborate fallbacks
      );

      this.cache.attachmentLearningEnhanced = this.readJsonSafe<AttachmentLearningConfig>(
        'attachment_learning_enhanced.json',
        null as any
      );

      // Standard data files with version + array pattern (from original suggestions.js)
      this.cache.therapyAdvice = this.readJsonSafe<any>(
        'therapy_advice.json',
        { version: '0', items: [] }
      );

      this.cache.contextClassifier = this.readJsonSafe<any>(
        'context_classifier.json',
        { version: '0', contexts: [] }
      );

      this.cache.toneTriggerWords = this.readJsonSafe<any>(
        'tone_triggerwords.json',
        { version: '0', triggers: [] }
      );

      this.cache.intensityModifiers = this.readJsonSafe<any>(
        'intensity_modifiers.json',
        { version: '0', modifiers: [] }
      );

      this.cache.sarcasmIndicators = this.readJsonSafe<any>(
        'sarcasm_indicators.json',
        { version: '0', sarcasm_indicators: [] }
      );

      this.cache.negationIndicators = this.readJsonSafe<any>(
        'negation_indicators.json',
        { version: '0', negation_indicators: [] }
      );

      this.cache.phraseEdges = this.readJsonSafe<any>(
        'phrase_edges.json',
        { version: '0', edges: [] }
      );

      this.cache.evaluationTones = this.readJsonSafe<any>(
        'evaluation_tones.json',
        { version: '0', tones: [] }
      );

      this.cache.tonePatterns = this.readJsonSafe<any>(
        'tone_patterns.json',
        { version: '0', patterns: [] }
      );

      this.cache.learningSignals = this.readJsonSafe<any>(
        'learning_signals.json',
        { version: '0', signals: [] }
      );

      this.cache.negationPatterns = this.readJsonSafe<any>(
        'negation_patterns.json',
        { version: '0', patterns: [] }
      );

      this.cache.profanityLexicons = this.readJsonSafe<any>(
        'profanity_lexicons.json',
        { version: '0', words: [] }
      );

      this.cache.weightModifiers = this.readJsonSafe<any>(
        'weight_modifiers.json',
        { version: '0', modifiers: [] }
      );

      this.cache.attachmentOverrides = this.readJsonSafe<any>(
        'attachment_overrides.json',
        { version: '0', overrides: [] }
      );

      this.cache.onboardingPlaybook = this.readJsonSafe<any>(
        'onboarding_playbook.json',
        { version: '0', steps: [] }
      );

      // Special structure files (from original suggestions.js)
      this.cache.severityCollaboration = this.readJsonSafe<any>(
        'severity_collaboration.json',
        { alert: { base: 0.55 }, caution: { base: 0.4 }, clear: { base: 0.35 } }
      );

      this.cache.semanticThesaurus = this.readJsonSafe<any>(
        'semantic_thesaurus.json',
        { version: '0' }
      );

      // Missing files found in tone-analysis-endpoint.js
      this.cache.severityCollab = this.readJsonSafe<any>(
        'severity_collaboration.json',
        { alert: { base: 0.55 }, caution: { base: 0.40 }, clear: { base: 0.35 } }
      );

      this.cache.weightProfiles = this.readJsonSafe<any>(
        'weightMultiplierProfiles.json',
        { version: '1.0', profiles: {} }
      );

      this.cache.userPreferences = this.readJsonSafe<any>(
        'user_preference.json',
        { categories: {} }
      );

      this.cache.guardrailConfig = this.readJsonSafe<any>(
        'guardrail_config.json',
        { blockedPatterns: [] }
      );

      // Complex tone bucket mapping (from original suggestions.js toneBucketMap fallback)
      this.cache.toneBucketMapping = this.readJsonSafe<any>(
        'tone_bucket_mapping.json',
        {
          version: '1.0',
          default: {
            neutral:   { clear: 0.70, caution: 0.25, alert: 0.05 },
            positive:  { clear: 0.80, caution: 0.18, alert: 0.02 },
            supportive:{ clear: 0.85, caution: 0.13, alert: 0.02 },
            angry:     { clear: 0.05, caution: 0.30, alert: 0.65 },
            frustrated:{ clear: 0.10, caution: 0.55, alert: 0.35 },
            anxious:   { clear: 0.15, caution: 0.60, alert: 0.25 },
            sad:       { clear: 0.25, caution: 0.60, alert: 0.15 }
          },
          contextOverrides: {
            conflict: {
              angry:      { clear: 0.02, caution: 0.18, alert: 0.80 },
              frustrated: { clear: 0.05, caution: 0.50, alert: 0.45 },
              anxious:    { clear: 0.10, caution: 0.55, alert: 0.35 }
            },
            repair: {
              angry:      { clear: 0.10, caution: 0.50, alert: 0.40 },
              frustrated: { clear: 0.15, caution: 0.60, alert: 0.25 }
            }
          },
          intensityShifts: {
            thresholds: { low: 0.15, med: 0.35, high: 0.60 },
            low:  { alert: -0.10, caution: +0.08, clear: +0.02 },
            med:  { alert:  0.00, caution:  0.00, clear:  0.00 },
            high: { alert: +0.12, caution: -0.08, clear: -0.04 }
          }
        }
      );

      this.initialized = true;
      logger.info('Data cache initialized successfully');
    } catch (error) {
      logger.error('Failed to initialize data cache:', error);
      throw new Error(`DataLoader initialization failed: ${error}`);
    }
  }

  public isInitialized(): boolean {
    return this.initialized;
  }

  // Getters for each data type - using null fallbacks to match original JS behavior
  public getAttachmentLearning(): AttachmentLearningConfig | null {
    return this.cache.attachmentLearning || null;
  }

  public getAttachmentLearningEnhanced(): AttachmentLearningConfig | null {
    return this.cache.attachmentLearningEnhanced || null;
  }

  public getTherapyAdvice(): any {
    return this.cache.therapyAdvice || { version: '0', items: [] };
  }

  public getContextClassifier(): any {
    return this.cache.contextClassifier || { version: '0', contexts: [] };
  }

  public getToneTriggerWords(): any {
    return this.cache.toneTriggerWords || { version: '0', triggers: [] };
  }

  public getIntensityModifiers(): any {
    return this.cache.intensityModifiers || { version: '0', modifiers: [] };
  }

  public getSarcasmIndicators(): any {
    return this.cache.sarcasmIndicators || { version: '0', sarcasm_indicators: [] };
  }

  public getNegationIndicators(): any {
    return this.cache.negationIndicators || { version: '0', negation_indicators: [] };
  }

  public getPhraseEdges(): any {
    return this.cache.phraseEdges || { version: '0', edges: [] };
  }

  public getEvaluationTones(): any {
    return this.cache.evaluationTones || { version: '0', tones: [] };
  }

  public getTonePatterns(): any {
    return this.cache.tonePatterns || { version: '0', patterns: [] };
  }

  public getLearningSignals(): any {
    return this.cache.learningSignals || { version: '0', signals: [] };
  }

  public getNegationPatterns(): any {
    return this.cache.negationPatterns || { version: '0', patterns: [] };
  }

  public getProfanityLexicons(): any {
    return this.cache.profanityLexicons || { version: '0', words: [] };
  }

  public getWeightModifiers(): any {
    return this.cache.weightModifiers || { version: '0', modifiers: [] };
  }

  public getAttachmentOverrides(): any {
    return this.cache.attachmentOverrides || { version: '0', overrides: [] };
  }

  public getOnboardingPlaybook(): any {
    return this.cache.onboardingPlaybook || { version: '0', steps: [] };
  }

  public getSeverityCollaboration(): any {
    return this.cache.severityCollaboration || { alert: { base: 0.55 }, caution: { base: 0.4 }, clear: { base: 0.35 } };
  }

  public getSemanticThesaurus(): any {
    return this.cache.semanticThesaurus || { version: '0' };
  }

  public getUserPreferences(): any {
    return this.cache.userPreferences || { categories: {} };
  }

  public getGuardrailConfig(): any {
    return this.cache.guardrailConfig || { blockedPatterns: [] };
  }

  public getToneBucketMapping(): any {
    return this.cache.toneBucketMapping || {
      version: '1.0',
      default: {
        neutral: { clear: 0.70, caution: 0.25, alert: 0.05 }
      }
    };
  }

  // Utility methods for common access patterns
  public get(key: string): any {
    // Handle aliases for backward compatibility
    if (key === 'toneBucketMap') {
      return this.cache.toneBucketMapping || null;
    }
    
    return this.cache[key as keyof DataCache] || null;
  }

  // Refresh data cache
  public async refresh(): Promise<void> {
    this.initialized = false;
    this.cache = {};
    await this.initialize();
  }

  // Get all cached data (for debugging)
  public getAllData(): DataCache {
    return { ...this.cache };
  }

  // Get data file status (for health checks)
  public getDataStatus(): Record<string, boolean> {
    const files = [
      'attachment_learning.json',
      'attachment_learning_enhanced.json', 
      'therapy_advice.json',
      'context_classifier.json',
      'tone_triggerwords.json',
      'intensity_modifiers.json',
      'sarcasm_indicators.json',
      'negation_indicators.json',
      'phrase_edges.json',
      'evaluation_tones.json',
      'tone_patterns.json',
      'learning_signals.json',
      'negation_patterns.json',
      'profanity_lexicons.json',
      'weight_modifiers.json',
      'attachment_overrides.json',
      'onboarding_playbook.json',
      'severity_collaboration.json',
      'semantic_thesaurus.json',
      'user_preference.json',
      'guardrail_config.json',
      'tone_bucket_mapping.json'
    ];

    const status: Record<string, boolean> = {};
    files.forEach(file => {
      const filepath = path.join(this.dataPath, file);
      status[file] = fs.existsSync(filepath);
    });

    return status;
  }

  // Enhanced methods for suggestions system
  getAllAdviceItems(): AdviceItem[] {
    const db = this.get('therapyAdvice');
    return normalizeAdvice(db);
  }
}

// ============================
// Validation Schemas
// ============================
const AdviceItem = z.object({
  id: z.string(),
  tier: z.enum(['general','premium']).optional(),
  advice: z.string().min(1),
  rewriteCue: z.string().optional(),
  categories: z.array(z.string()).default([]),
  contexts: z.array(z.string()).default([]),
  triggerTone: z.enum(['clear','caution','alert']).optional(),
  attachmentStyles: z.array(z.enum(['secure','anxious','avoidant','disorganized'])).default([]),
  severityThreshold: z.record(z.enum(['clear','caution','alert']), z.number().min(0).max(1)).optional(),
  keywords: z.array(z.string()).default([]),
  embeddings: z.array(z.number()).optional(),
  matchKeywords: z.array(z.string()).optional(),
  boostSources: z.array(z.string()).optional(),
  negationSensitive: z.boolean().optional()
});

export type AdviceItem = z.infer<typeof AdviceItem>;

// ============================
// Normalization Functions
// ============================
export function normalizeAdvice(db: any): AdviceItem[] {
  const items = (db?.items ?? []).map((raw: any) => {
    const merged = {
      ...raw,
      keywords: [
        ...(raw.keywords ?? []), 
        ...(raw.matchKeywords ?? []), 
        ...(raw.boostSources ?? [])
      ]
    };
    try {
      return AdviceItem.parse(merged);
    } catch (error) {
      logger.warn(`Failed to validate advice item ${raw.id}:`, error);
      // Return a safe fallback
      return AdviceItem.parse({
        id: raw.id || 'unknown',
        advice: raw.advice || 'No advice available',
        keywords: []
      });
    }
  });
  
  logger.info(`Normalized ${items.length} advice items`);
  return items;
}

export const dataLoader = new DataLoaderService();