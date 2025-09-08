// api/_lib/types/dataTypes.ts
// TypeScript interfaces for all JSON data structures

export interface AttachmentLearningConfig {
  version: string;
  notes: string;
  metadata: {
    researchBasis: string;
    lastUpdated: string;
    validationDataset: string;
    accuracy: string;
  };
  learningDays: number;
  styles: string[];
  scoring: {
    thresholds: {
      primary: number;
      secondary: number;
    };
    dailyLimit: number;
    decay: {
      factor: number;
      applyDaily: boolean;
    };
  };
  learningConfig: {
    styles: string[];
    minObservations: number;
    maxObservationsPerDay: number;
    contextualLearning: boolean;
    temporalAnalysis: boolean;
    adaptiveThresholds: boolean;
  };
  scoringAlgorithm: {
    method: string;
    components: Record<string, number>;
    thresholds: {
      primary: {
        base: number;
        adaptive_range: [number, number];
        confidence_required: number;
      };
      secondary: {
        base: number;
        adaptive_range: [number, number];
        confidence_required: number;
      };
    };
  };
  attachmentSignatures: Record<string, any>;
  contextualFactors: Record<string, any>;
  linguisticMarkers: Record<string, any>;
  temporalPatterns: Record<string, any>;
  adaptiveThresholds: Record<string, any>;
}

export interface TherapyAdvice {
  id: string;
  advice: string;
  triggerTone: string;
  contexts: string[];
  attachmentStyles: string[];
  severityThreshold: Record<string, number>;
  spacyLink?: string[];
  contextLink?: string[];
  boostSources?: string[];
  styleTuning?: Record<string, number>;
  category?: string;
  tags?: string[];
  efficacy?: number;
}

export interface TonePattern {
  id: string;
  tone: string;
  type: string;
  pattern: string;
  confidence: number;
  category: string;
  attachmentStyles: string[];
  styleWeight: Record<string, number>;
  spacyPattern?: any[];
  semanticVariants?: string[];
  contextualModifiers?: Record<string, number>;
  intensityMultiplier?: number;
}

export interface EvaluationTone {
  tone: string;
  description: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  color: string;
  emoji: string;
  attachmentRelevance: Record<string, number>;
  therapeuticPriority: number;
  interventionRequired: boolean;
  commonTriggers: string[];
  healingApproaches: string[];
}

export interface SemanticThesaurus {
  baseWord: string;
  synonyms: string[];
  emotionalVariants: Record<string, string[]>;
  intensityLevels: Record<string, string[]>;
  contextualAlternatives: Record<string, string[]>;
  attachmentStylePreferences: Record<string, string[]>;
}

export interface UserPreference {
  userId: string;
  communicationStyle: string;
  preferredToneRange: string[];
  avoidedTopics: string[];
  responseStyle: 'direct' | 'gentle' | 'balanced' | 'analytical';
  attachmentAwareness: boolean;
  personalityInsights: Record<string, any>;
  adaptationHistory: Record<string, any>;
}

export interface ContextClassifier {
  context: string;
  keywords: string[];
  patterns: string[];
  emotionalIndicators: string[];
  attachmentTriggers: Record<string, string[]>;
  appropriateResponses: string[];
  riskFactors: string[];
  therapeuticOpportunities: string[];
}

export interface IntensityModifier {
  modifier: string;
  type: 'amplifier' | 'diminisher' | 'neutral';
  baseMultiplier: number;
  contextualAdjustments: Record<string, number>;
  attachmentSpecific: Record<string, number>;
  linguisticVariants: string[];
}

export interface LearningSignal {
  signalType: string;
  indicators: string[];
  weight: number;
  attachmentRelevance: Record<string, number>;
  temporalDecay: number;
  contextualModifiers: Record<string, number>;
  validationCriteria: string[];
}

export interface GuardrailConfig {
  category: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  patterns: string[];
  blockedPhrases: string[];
  warningThresholds: Record<string, number>;
  allowedExceptions: string[];
  escalationProtocol: string[];
  therapeuticResponse: string[];
}

export interface OnboardingPlaybook {
  stage: string;
  objectives: string[];
  keyQuestions: string[];
  expectedOutcomes: string[];
  attachmentConsiderations: Record<string, string[]>;
  progressIndicators: string[];
  commonChallenges: string[];
  supportStrategies: string[];
}

export interface ToneBucketMapping {
  bucket: string;
  tones: string[];
  severity: number;
  therapeuticApproach: string;
  attachmentConsiderations: Record<string, string>;
  interventionTrigger: boolean;
  escalationPath: string[];
}

export interface NegationIndicator {
  indicator: string;
  type: 'explicit' | 'implicit' | 'contextual';
  strength: number;
  patterns: string[];
  exceptions: string[];
}

export interface NegationPattern {
  pattern: string;
  type: 'regex' | 'phrase' | 'keyword';
  negationType: 'complete' | 'partial' | 'conditional';
  confidence: number;
  contextualRules: string[];
}

export interface ProfanityLexicon {
  word: string;
  severity: 'mild' | 'moderate' | 'severe' | 'extreme';
  category: string;
  variants: string[];
  contextualModifiers: Record<string, number>;
}

export interface SarcasmIndicator {
  indicator: string;
  type: 'verbal' | 'contextual' | 'punctuation';
  confidence: number;
  patterns: string[];
  attachmentRelevance: Record<string, number>;
}

export interface WeightModifier {
  modifier: string;
  category: string;
  baseWeight: number;
  contextualAdjustments: Record<string, number>;
  attachmentSpecific: Record<string, number>;
}

export interface AttachmentOverride {
  attachmentStyle: string;
  scenario: string;
  originalResponse: string;
  overrideResponse: string;
  conditions: string[];
  priority: number;
}

export interface PhraseEdge {
  fromPhrase: string;
  toPhrase: string;
  relationshipType: string;
  weight: number;
  context: string[];
  attachmentRelevance: Record<string, number>;
}

export interface ToneTriggerWord {
  word: string;
  targetTone: string;
  weight: number;
  variants: string[];
  contextualModifiers: Record<string, number>;
}

export interface SeverityCollaboration {
  level: string;
  description: string;
  interventions: string[];
  escalationThreshold: number;
  therapeuticApproach: string[];
}

// Data loading utilities
export interface DataCache {
  attachmentLearning?: AttachmentLearningConfig;
  attachmentLearningEnhanced?: AttachmentLearningConfig;
  therapyAdvice?: TherapyAdvice[];
  tonePatterns?: TonePattern[];
  evaluationTones?: EvaluationTone[];
  semanticThesaurus?: SemanticThesaurus[];
  userPreferences?: UserPreference[];
  contextClassifier?: ContextClassifier[];
  intensityModifiers?: IntensityModifier[];
  learningSignals?: LearningSignal[];
  guardrailConfig?: GuardrailConfig[];
  onboardingPlaybook?: OnboardingPlaybook[];
  toneBucketMapping?: ToneBucketMapping[];
  negationIndicators?: NegationIndicator[];
  negationPatterns?: NegationPattern[];
  profanityLexicons?: ProfanityLexicon[];
  sarcasmIndicators?: SarcasmIndicator[];
  weightModifiers?: WeightModifier[];
  attachmentOverrides?: AttachmentOverride[];
  phraseEdges?: PhraseEdge[];
  toneTriggerWords?: ToneTriggerWord[];
  severityCollaboration?: SeverityCollaboration[];
  severityCollab?: any; // From tone-analysis-endpoint.js
  weightProfiles?: any; // From tone-analysis-endpoint.js
}
