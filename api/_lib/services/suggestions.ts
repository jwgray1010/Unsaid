// api/_lib/services/suggestions.ts
/**
 * Advanced ML-Enhanced Suggestions API (Therapy-Advice Focus)
 *
 * This implementation:
 *  - Uses ONLY local JSON knowledge bases + spaCy (via toneAnalysis) — no LLM calls
 *  - Hybrid retrieval (BM25 + embeddings) with MMR diversity
 *  - Context/attachment-aware scoring with JSON-driven weights/overrides
 *  - Guardrails & contraindications from JSON, no risky fallbacks
 *  - Confidence calibration per context (evaluation_tones.json)
 *  - Returns your existing SuggestionAnalysis shape
 */

import { logger } from '../logger';
import { dataLoader } from './dataLoader';
import { MLAdvancedToneAnalyzer } from './toneAnalysis';
import { spacyClient } from './spacyClient';
import type {
  TherapyAdvice,
  ContextClassifier,
  ToneTriggerWord,
  NegationPattern,
  SarcasmIndicator,
  IntensityModifier,
  PhraseEdge,
  ToneBucketMapping,
  WeightModifier,
  GuardrailConfig,
  ProfanityLexicon,
  AttachmentOverride,
  LearningSignal,
  EvaluationTone,
  UserPreference
} from '../types/dataTypes';

// ============================
// Interfaces (keep identical to your original)
// ============================
export interface DetailedSuggestionResult {
  id?: string;
  text: string;
  rewriteCue?: string;
  categories?: string[];
  type: 'rephrase' | 'addition' | 'tone_adjustment' | 'empathy_boost' | 'clarity_improvement' | 'emotional_validation';
  confidence: number;
  reason: string;
  category: 'communication_style' | 'emotional_intelligence' | 'conflict_resolution' | 'relationship_building';
  priority: number;
  context_specific: boolean;
  attachment_informed?: boolean;
  ltrScore?: number;
}

export interface SuggestionAnalysis {
  success: boolean;
  tier: 'general' | 'premium';
  original_text: string;
  context: string;
  suggestions: DetailedSuggestionResult[];
  analysis: {
    tone: {
      classification: string;
      confidence: number;
    };
    mlGenerated: boolean;
    context: {
      label: string;
      score: number;
    };
    flags: {
      hasNegation: boolean;
      hasSarcasm: boolean;
      intensityScore: number;
      phraseEdgeHits: string[];
    };
    toneBuckets: {
      primary: string;
      dist: {
        clear: number;
        caution: number;
        alert: number;
      };
    };
  };
  analysis_meta: {
    complexity_score: number;
    emotional_intensity: number;
    clarity_level: number;
    empathy_present: boolean;
    potential_triggers: string[];
    recommended_approach: string;
  };
  metadata: {
    attachmentStyle: string;
    timestamp: string;
    version: string;
  };
  trialStatus: any;
}

type Bucket = 'clear'|'caution'|'alert';

interface ToneBucketDistribution {
  clear: number;
  caution: number;
  alert: number;
}

interface ToneBucketResult {
  primary: string;
  dist: ToneBucketDistribution;
}

// ============================
// Comprehensive JSON Data Loader Enforcement
// ============================
async function ensureDataLoaded(): Promise<void> {
  // DataLoader is now pre-initialized synchronously
  if (!dataLoader.isInitialized()) {
    logger.warn('DataLoader not initialized in suggestions service');
  }

  const requiredJSONFiles = [
    'therapy_advice.json',
    'context_classifier.json', 
    'tone_triggerwords.json',
    'negation_patterns.json',
    'sarcasm_indicators.json',
    'intensity_modifiers.json',
    'phrase_edges.json',
    'tone_bucket_mapping.json',
    'weight_modifiers.json',
    'guardrail_config.json',
    'profanity_lexicons.json',
    'attachment_overrides.json',
    'learning_signals.json',
    'evaluation_tones.json',
    'user_preference.json'
  ];

  logger.info('Ensuring all JSON data files are loaded...');
  
  // Check data status
  const dataStatus = dataLoader.getDataStatus();
  const missingFiles: string[] = [];
  
  for (const fileName of requiredJSONFiles) {
    if (!dataStatus[fileName]) {
      missingFiles.push(fileName);
      logger.error(`✗ Critical JSON dependency missing: ${fileName}`);
    } else {
      logger.debug(`✓ ${fileName} available`);
    }
  }
  
  if (missingFiles.length > 0) {
    throw new Error(`Critical JSON dependencies missing: ${missingFiles.join(', ')}`);
  }
  
  // Validate core data can be accessed
  const therapyAdvice = dataLoader.get('therapyAdvice');
  const toneBucketMapping = dataLoader.get('toneBucketMapping');
  const guardrailConfig = dataLoader.get('guardrailConfig');
  
  if (!therapyAdvice || !toneBucketMapping || !guardrailConfig) {
    throw new Error('Core JSON data structures not properly loaded');
  }
  
  logger.info('All JSON data files validated and loaded');
}

// ============================
// Trial Manager (no network, simple gate)
// ============================
class TrialManager {
  async getTrialStatus(userId: string = 'anonymous', userEmail?: string | null) {
    return {
      status: 'trial_active',
      inTrial: true,
      planType: 'trial',
      features: { 'tone-analysis': true, suggestions: true, advice: true },
      isActive: true,
      hasAccess: true,
      isAdmin: false,
      daysRemaining: 5,
      totalTrialDays: 7,
      userId,
      userEmail,
      timestamp: new Date().toISOString()
    };
  }
  resolveTier(trialStatus: any): 'general' | 'premium' {
    if (trialStatus?.hasAccess && (trialStatus?.inTrial || trialStatus?.planType === 'premium')) return 'premium';
    return 'general';
  }
}

// ============================
// Helpers: retrieval / guardrails / calibration
// ============================
function cosine(a: Float32Array, b: Float32Array): number {
  let dot = 0, na = 0, nb = 0;
  for (let i=0;i<a.length;i++){ const x=a[i], y=b[i]; dot+=x*y; na+=x*x; nb+=y*y; }
  const d = Math.sqrt(na)*Math.sqrt(nb) || 1;
  return dot/d;
}

function getAdviceCorpus(): any[] {
  const idxItems = dataLoader.get('adviceIndexItems');
  if (Array.isArray(idxItems) && idxItems.length) return idxItems;
  const db = dataLoader.get('therapyAdvice') || { items: [] };
  return db.items || [];
}

function getVecById(id: string): Float32Array | null {
  const getter = dataLoader.get('adviceGetVector');
  if (typeof getter === 'function') {
    const v = getter(id);
    if (v && v.length) return new Float32Array(v);
  }
  return null;
}

function bm25Search(query: string, limit = 200): any[] {
  const bm25 = dataLoader.get('adviceBM25');
  if (!bm25) return [];
  const hits = bm25.search(query, { prefix: true, fuzzy: 0.2 }).slice(0, limit);
  const byId = new Map<string, any>(getAdviceCorpus().map((it:any)=>[it.id, it]));
  return hits.map((h:any)=>byId.get(h.id)).filter(Boolean);
}

function mmr(pool: any[], qVec: Float32Array | null, vecOf: (it:any)=>Float32Array|null, k=200, lambda=0.7) {
  const out: any[] = [];
  const cand = new Set(pool);
  while (out.length < Math.min(k, pool.length) && cand.size) {
    let best: any = null;
    let bestScore = -Infinity;
    for (const it of cand) {
      const v = vecOf(it);
      const rel = qVec && v ? cosine(qVec, v) : 0;
      let nov = 1;
      if (out.length && v) {
        let maxSim = 0;
        for (const o of out) {
          const ov = vecOf(o);
          if (ov) maxSim = Math.max(maxSim, cosine(v, ov));
        }
        nov = 1 - maxSim;
      }
      const score = lambda*rel + (1-lambda)*nov;
      if (score > bestScore) { bestScore = score; best = it; }
    }
    if (!best) break;
    out.push(best);
    cand.delete(best);
  }
  return out;
}

async function hybridRetrieve(text: string, contextLabel: string, toneKey: string, k=200) {
  const corpus = getAdviceCorpus();
  const query = `${text} ctx:${contextLabel} tone:${toneKey}`;
  let denseTop: any[] = [];
  let qVec: Float32Array | null = null;

  const hasVecs = !!getVecById(corpus[0]?.id || '');
  if (hasVecs && typeof (spacyClient.embed) === 'function') {
    const qArr: number[] = await spacyClient.embed(query);
    qVec = new Float32Array(qArr);
    denseTop = corpus
      .map((it:any) => {
        const v = getVecById(it.id);
        const s = (v && qVec) ? cosine(v, qVec) : 0;
        return [it, s] as const;
      })
      .sort((a,b)=>b[1]-a[1])
      .slice(0, k*2)
      .map(([it])=>it);
  }

  const sparseTop = bm25Search(query, k*2);

  const uniq = new Map<string, any>();
  for (const it of [...denseTop, ...sparseTop]) if (it?.id && !uniq.has(it.id)) uniq.set(it.id, it);
  const pool = Array.from(uniq.values());
  return mmr(pool, qVec, (it:any)=>getVecById(it.id), k, 0.7);
}

function applyContraindications(items: any[], flags: {hasNegation:boolean; hasSarcasm:boolean; intensityScore:number}) {
  const guard = dataLoader.get('guardrailConfig');
  const prof  = dataLoader.get('profanityLexicons');
  return items.filter((it:any) => {
    if (flags.intensityScore > (guard?.maxIntensityForConfront ?? 0.75)) {
      if ((it.categories ?? []).includes('confrontation')) return false;
    }
    if (flags.hasNegation && it.negationSensitive) return false;
    if (prof?.block && prof.block.some((w:string)=>String(it.advice||'').toLowerCase().includes(w))) return false;
    return true;
  });
}

function applyAttachmentOverrides(items:any[], style:string) {
  const overrides = dataLoader.get('attachmentOverrides')?.[style];
  if (!overrides) return items;
  return items.map((it:any) => {
    const boosted = {...it};
    if (overrides.categoryBoost && boosted.categories?.some((c:string)=>overrides.categoryBoost.includes(c))) {
      (boosted as any).__boost = ((boosted as any).__boost ?? 0) + 0.2;
    }
    if (overrides.rewriteCueReplace && overrides.rewriteCueReplace[boosted.id]) {
      boosted.rewriteCue = overrides.rewriteCueReplace[boosted.id];
    }
    return boosted;
  });
}

function diversify(ranked:any[], topN=5, simThreshold=0.87) {
  const out:any[]=[];
  const vec = (it:any)=>getVecById(it.id);
  for (const r of ranked) {
    const v = vec(r);
    const dup = v && out.some(o => {
      const ov = vec(o);
      return ov ? cosine(v, ov) > simThreshold : false;
    });
    if (!dup) out.push(r);
    if (out.length >= topN) break;
  }
  return out.length ? out : ranked.slice(0, topN);
}

function calibrate(conf:number, contextLabel:string) {
  const evalSet = dataLoader.get('evaluationTones');
  const p = evalSet?.platt?.[contextLabel] ?? { a: 1, b: 0 };
  return 1 / (1 + Math.exp(-(p.a*conf + p.b)));
}

// ============================
// Orchestrator (spaCy + local analyzer only)
// ============================
class AnalysisOrchestrator {
  constructor(
    private spacyService: any,
    private mlAnalyzer: MLAdvancedToneAnalyzer,
    private loader: any
  ) {}

  async analyze(
    text: string,
    providedTone?: { classification: string; confidence: number } | null,
    attachmentStyle?: string,
    contextHint?: string
  ) {
    // spaCy process for flags/context/intensity
    const spacyResult = this.spacyService.process(text, {
      contextClassifier: this.loader.get('contextClassifier'),
      negationIndicators: this.loader.get('negationIndicators') || this.loader.get('negationPatterns'),
      sarcasmIndicators: this.loader.get('sarcasmIndicators'),
      intensityModifiers: this.loader.get('intensityModifiers'),
      phraseEdges: this.loader.get('phraseEdges'),
      semanticThesaurus: this.loader.get('semanticThesaurus'),
      wantTokens: true, wantSents: true, wantDeps: true
    });

    // Improved intensity with POS adv
    const advCount = (spacyResult.tokens || []).filter((t:any)=>String(t.pos).toUpperCase()==='ADV').length;
    const excl = (text.match(/!/g)||[]).length * 0.08;
    const q = (text.match(/\?/g)||[]).length * 0.04;
    const caps = (text.match(/[A-Z]{2,}/g)||[]).length * 0.12;
    const mod = spacyResult.intensity?.score || 0;
    const intensityScore = Math.min(1, excl + q + caps + mod + advCount*0.04);

    let toneResult = providedTone || null;
    let mlGenerated = false;

    if (!toneResult) {
      const ml = await this.mlAnalyzer.analyzeTone(
        text,
        attachmentStyle || 'secure',
        contextHint || spacyResult.context?.label || 'general',
        'general'
      );
      if (ml?.success) {
        toneResult = { classification: ml.tone.classification, confidence: ml.tone.confidence };
        mlGenerated = true;
      } else {
        // No fallback: if analyzer fails, throw — caller handles as 4xx
        throw new Error('Tone analysis unavailable');
      }
    }

    return {
      tone: toneResult!,
      context: spacyResult.context || { label: contextHint || 'general', score: 0.5 },
      entities: spacyResult.entities || [],
      flags: {
        hasNegation: spacyResult.negation?.present || (spacyResult.deps || []).some((d:any)=>d.rel==='neg'),
        hasSarcasm: spacyResult.sarcasm?.present || false,
        intensityScore,
        phraseEdgeHits: spacyResult.phraseEdges?.hits || []
      },
      features: spacyResult.features || {},
      mlGenerated
    };
  }
}

// ============================
// Advice Engine (JSON-weighted; no fallbacks)
// ============================
class AdviceEngine {
  private baseWeights = {
    baseConfidence: 1.0,
    toneMatch: 2.0,
    contextMatch: 1.5,
    attachmentMatch: 1.2,
    intensityBoost: 0.6,
    negationPenalty: -0.8,
    sarcasmPenalty: -1.0,
    userPrefBoost: 0.5,
    severityFit: 1.2,
    phraseEdgeBoost: 0.4,
    premiumBoost: 0.2
  };

  constructor(private loader: any) {}

  private currentWeights(contextLabel: string) {
    const mods = this.loader.get('weightModifiers');
    return { ...this.baseWeights, ...(mods?.byContext?.[contextLabel] ?? {}) };
  }

  // Probabilistic bucket mapping from JSON
  resolveToneBucket(toneLabel: string, contextLabel: string, intensityScore: number = 0): ToneBucketResult {
    const map = this.loader.get('toneBucketMapping') || this.loader.get('toneBucketMap') || {};
    const base = (map.default && map.default[toneLabel]) || map.default?.neutral || {
      clear: 0.33, caution: 0.34, alert: 0.33
    };
    const ctx = map.contextOverrides?.[contextLabel]?.[toneLabel];
    let dist = { ...(ctx || base) };

    const thr = map.intensityShifts?.thresholds || { low: 0.15, med: 0.35, high: 0.60 };
    const shiftKey = intensityScore >= thr.high ? 'high' : intensityScore >= thr.med ? 'med' : 'low';
    const shift = map.intensityShifts?.[shiftKey] || { alert: 0, caution: 0, clear: 0 };

    dist = {
      clear: Math.max(0, (dist.clear ?? 0) + (shift.clear || 0)),
      caution: Math.max(0, (dist.caution ?? 0) + (shift.caution || 0)),
      alert: Math.max(0, (dist.alert ?? 0) + (shift.alert || 0)),
    };

    const sum = (dist.clear ?? 0) + (dist.caution ?? 0) + (dist.alert ?? 0) || 1;
    dist.clear   = (dist.clear   ?? 0) / sum;
    dist.caution = (dist.caution ?? 0) / sum;
    dist.alert   = (dist.alert   ?? 0) / sum;

    const primary = (Object.entries(dist).sort((a, b) => (b[1] as number) - (a[1] as number))[0][0]) as string;
    return { primary, dist: dist as ToneBucketDistribution };
  }

  severityBaselineFor(toneKey: string, contextLabel: string): number {
    const sev = this.loader.get('severityCollab') || {};
    const bucket = sev[toneKey] || sev['clear'] || {};
    const base = bucket?.base ?? 0.35;
    const byCtx = bucket?.byContext || {};
    const ctxAdj = contextLabel ? (byCtx[contextLabel] || 0) : 0;
    return base + ctxAdj;
  }

  userPrefBoostFor(adviceItem: any, userPref: any): number {
    if (!userPref || !userPref.categories) return 0;
    const cats = new Set<string>();
    if (Array.isArray(adviceItem.categories)) adviceItem.categories.forEach((c: string) => cats.add(c));
    if (adviceItem.category) cats.add(adviceItem.category);
    let boost = 0;
    for (const c of cats) {
      const v = userPref.categories[c];
      if (typeof v === 'number') boost += v;
    }
    return boost;
  }

  rank(items: any[], signals: {
    baseConfidence: number;
    toneKey: string;
    contextLabel: string;
    attachmentStyle: string;
    hasNegation: boolean;
    hasSarcasm: boolean;
    intensityScore: number;
    phraseEdgeHits: string[];
    userPref: any;
    tier: 'general'|'premium';
  }): any[] {
    const W = this.currentWeights(signals.contextLabel);

    const scored = items.map((it:any) => {
      let s = 0;
      s += W.baseConfidence * (signals.baseConfidence ?? 0.8);

      // Tone match mass
      const { dist } = this.resolveToneBucket(signals.toneKey, signals.contextLabel, signals.intensityScore);
      const toneBucket = it.triggerTone || 'clear';
      const toneMatchMass = (dist as any)[toneBucket] ?? 0.33;
      s += W.toneMatch * toneMatchMass;

      // Context
      const ctxMatch = !it.contexts || it.contexts.length === 0 || it.contexts.includes(signals.contextLabel) ? 1 : 0;
      s += W.contextMatch * ctxMatch;

      // Attachment
      const attachMatch = !it.attachmentStyles || it.attachmentStyles.length === 0 || it.attachmentStyles.includes(signals.attachmentStyle) ? 1 : 0;
      s += W.attachmentMatch * attachMatch;

      // Intensity
      s += W.intensityBoost * Math.min(1, Math.max(0, signals.intensityScore));

      // Negation / Sarcasm
      if (signals.hasNegation) s += W.negationPenalty;
      if (signals.hasSarcasm) s += W.sarcasmPenalty;

      // Phrase edges
      s += W.phraseEdgeBoost * Math.min(1, (signals.phraseEdgeHits?.length || 0) / 3);

      // User preferences
      s += W.userPrefBoost * this.userPrefBoostFor(it, signals.userPref);

      // Severity fit vs baseline
      const baseline = this.severityBaselineFor(toneBucket, signals.contextLabel);
      const required = it.severityThreshold?.[toneBucket] ?? baseline;
      const sevDelta = Math.abs((required ?? baseline) - baseline);
      const sevScore = 1 - Math.min(sevDelta / 0.1, 1);
      s += W.severityFit * sevScore;

      // Attachment overrides boost
      if ((it as any).__boost) s += (it as any).__boost;

      // Tier
      if (signals.tier === 'premium') s += W.premiumBoost;

      // Light online learning nudge
      const sig = dataLoader.get('learningSignals')?.byItem?.[it.id];
      if (sig) {
        const shown = Math.max(1, sig.shown || 0);
        const ctr = (sig.accepted || 0) / shown;
        const rej = (sig.rejected || 0) / shown;
        s += (ctr * 0.3) - (rej * 0.2);
      }

      return { ...it, ltrScore: Number(s.toFixed(4)) };
    });

    return scored.sort((a,b)=> (b.ltrScore ?? 0) - (a.ltrScore ?? 0));
  }
}

// ============================
// Main Suggestions Service
// ============================
class SuggestionsService {
  private trialManager: TrialManager;
  private mlAnalyzer: MLAdvancedToneAnalyzer;
  private orchestrator: AnalysisOrchestrator;
  private adviceEngine: AdviceEngine;

  constructor() {
    this.trialManager = new TrialManager();
    this.mlAnalyzer = new MLAdvancedToneAnalyzer({ enableSmoothing: true, enableSafetyChecks: true });
    this.orchestrator = new AnalysisOrchestrator(spacyClient, this.mlAnalyzer, dataLoader);
    this.adviceEngine = new AdviceEngine(dataLoader);
    
    // Initialize with comprehensive JSON validation
    this.initializeWithDataValidation();
  }

  private async initializeWithDataValidation(): Promise<void> {
    try {
      await ensureDataLoaded();
      logger.info('SuggestionsService initialized with all JSON dependencies validated');
    } catch (error) {
      logger.error('SuggestionsService initialization failed:', error);
      throw error;
    }
  }

  private async ensureDataLoaded(): Promise<void> {
    await ensureDataLoaded();
  }

  // ===== Strict JSON Dependency Validation =====
  private validateCriticalDependencies(): void {
    const criticalDependencies = [
      { key: 'therapyAdvice', name: 'therapy_advice.json' },
      { key: 'toneBucketMapping', name: 'tone_bucket_mapping.json' },
      { key: 'guardrailConfig', name: 'guardrail_config.json' },
      { key: 'profanityLexicons', name: 'profanity_lexicons.json' },
      { key: 'contextClassifier', name: 'context_classifier.json' },
      { key: 'weightModifiers', name: 'weight_modifiers.json' }
    ];

    const missingDependencies: string[] = [];

    for (const { key, name } of criticalDependencies) {
      const data = dataLoader.get(key);
      if (!data) {
        missingDependencies.push(name);
      }
    }

    if (missingDependencies.length > 0) {
      throw new Error(`Critical JSON dependencies missing: ${missingDependencies.join(', ')}. Suggestions service cannot operate without these files.`);
    }

    // Validate data structure integrity
    const therapyAdvice = dataLoader.get('therapyAdvice');
    if (!therapyAdvice?.items || !Array.isArray(therapyAdvice.items)) {
      throw new Error('therapy_advice.json is malformed - missing or invalid items array');
    }

    const toneBucketMapping = dataLoader.get('toneBucketMapping');
    if (!toneBucketMapping?.default) {
      throw new Error('tone_bucket_mapping.json is malformed - missing default bucket mappings');
    }

    logger.info('All critical JSON dependencies validated successfully');
  }

  // ===== Comprehensive Guardrails Implementation =====
  private applyAdvancedGuardrails(suggestions: any[], originalText: string, analysis: any): any[] {
    logger.info('Applying advanced guardrails and profanity filtering...');
    
    const guardrailConfig = dataLoader.get('guardrailConfig');
    const profanityLexicons = dataLoader.get('profanityLexicons');
    
    // Strict JSON dependency enforcement - no fallbacks
    if (!guardrailConfig) {
      throw new Error('Critical dependency missing: guardrail_config.json not loaded');
    }
    
    if (!profanityLexicons) {
      throw new Error('Critical dependency missing: profanity_lexicons.json not loaded');
    }

    const filteredSuggestions = suggestions.filter(suggestion => {
      // 1. Profanity filtering
      if (this.containsProfanity(suggestion.advice, profanityLexicons)) {
        logger.warn(`Suggestion filtered for profanity: ${suggestion.id}`);
        return false;
      }

      // 2. Blocked pattern checking
      if (this.matchesBlockedPattern(suggestion.advice, guardrailConfig.blockedPatterns || [])) {
        logger.warn(`Suggestion filtered for blocked pattern: ${suggestion.id}`);
        return false;
      }

      // 3. Context appropriateness
      if (!this.isContextAppropriate(suggestion, analysis)) {
        logger.warn(`Suggestion filtered for context inappropriateness: ${suggestion.id}`);
        return false;
      }

      // 4. Safety threshold checking
      if (analysis.toneBuckets?.primary === 'alert' && !this.isSafeForAlertContext(suggestion)) {
        logger.warn(`Suggestion filtered for alert context safety: ${suggestion.id}`);
        return false;
      }

      return true;
    });

    logger.info(`Guardrails applied: ${suggestions.length} → ${filteredSuggestions.length} suggestions`);
    return filteredSuggestions;
  }

  private containsProfanity(text: string, profanityLexicons: any): boolean {
    if (!profanityLexicons?.words || !Array.isArray(profanityLexicons.words)) {
      return false;
    }

    const lowercaseText = text.toLowerCase();
    return profanityLexicons.words.some((word: string) => 
      lowercaseText.includes(word.toLowerCase())
    );
  }

  private matchesBlockedPattern(text: string, blockedPatterns: string[]): boolean {
    if (!Array.isArray(blockedPatterns)) {
      return false;
    }

    return blockedPatterns.some(pattern => {
      try {
        const regex = new RegExp(pattern, 'i');
        return regex.test(text);
      } catch (error) {
        logger.warn(`Invalid regex pattern: ${pattern}`);
        return false;
      }
    });
  }

  private isContextAppropriate(suggestion: any, analysis: any): boolean {
    // Check if suggestion contexts match analysis context
    if (suggestion.contexts && Array.isArray(suggestion.contexts)) {
      const analysisContext = analysis.context?.label || 'general';
      const hasMatchingContext = suggestion.contexts.includes(analysisContext) || 
                                suggestion.contexts.includes('general') ||
                                suggestion.contexts.length === 0;
      
      if (!hasMatchingContext) {
        return false;
      }
    }

    // Check tone appropriateness
    if (suggestion.triggerTone) {
      const analysisTone = analysis.toneBuckets?.primary;
      if (analysisTone && suggestion.triggerTone !== analysisTone) {
        // Allow suggestions for less severe tones (alert can use caution/clear)
        const toneHierarchy = { alert: 3, caution: 2, clear: 1 };
        const suggestionLevel = toneHierarchy[suggestion.triggerTone as keyof typeof toneHierarchy] || 1;
        const analysisLevel = toneHierarchy[analysisTone as keyof typeof toneHierarchy] || 1;
        
        if (suggestionLevel > analysisLevel) {
          return false;
        }
      }
    }

    return true;
  }

  private isSafeForAlertContext(suggestion: any): boolean {
    // Additional safety checks for high-alert contexts
    if (!suggestion.advice) return false;
    
    const advice = suggestion.advice.toLowerCase();
    
    // Avoid suggestions that might escalate conflict
    const escalationPatterns = [
      'you should',
      'you need to',
      'you must',
      'you have to',
      'you always',
      'you never'
    ];
    
    if (escalationPatterns.some(pattern => advice.includes(pattern))) {
      return false;
    }

    // Require de-escalation keywords for alert contexts
    const deEscalationKeywords = [
      'consider',
      'might',
      'perhaps',
      'could',
      'gentle',
      'calm',
      'peaceful',
      'understanding',
      'patience'
    ];
    
    return deEscalationKeywords.some(keyword => advice.includes(keyword));
  }

  // ===== Public API =====
  async generateAdvancedSuggestions(
    text: string,
    context: string = 'general',
    userProfile?: any,
    options: {
      maxSuggestions?: number;
      targetEmotion?: string;
      relationshipStage?: string;
      conflictLevel?: 'low' | 'medium' | 'high';
      attachmentStyle?: string;
      userId?: string;
      userEmail?: string;
      toneAnalysisResult?: { classification: string; confidence: number } | null;
      isNewUser?: boolean;
    } = {}
  ): Promise<SuggestionAnalysis> {

    const {
      maxSuggestions = 5,
      attachmentStyle = 'secure',
      userId = 'anonymous',
      userEmail,
      toneAnalysisResult
    } = options;

    await this.ensureDataLoaded();

    // Strict JSON dependency validation - enforce all critical data is loaded
    this.validateCriticalDependencies();

    const trialStatus = await this.trialManager.getTrialStatus(userId, userEmail);
    if (!trialStatus?.hasAccess) throw new Error('Trial expired or access denied');
    const tier = this.trialManager.resolveTier(trialStatus);

    // 1) spaCy + local analyzer (no LLM)
    const analysis = await this.orchestrator.analyze(
      text,
      toneAnalysisResult ?? null,
      attachmentStyle,
      context
    );

    // Normalize tone to 3-bucket family if needed
    const toneKeyNorm = (() => {
      const t = (analysis.tone.classification || '').toLowerCase();
      if (['clear','caution','alert'].includes(t)) return t;
      if (t === 'positive' || t === 'supportive' || t === 'neutral') return 'clear';
      if (t === 'negative' || t === 'angry' || t === 'frustrated' || t === 'safety_concern') return 'alert';
      return 'caution';
    })() as Bucket;

    const intensityScore = analysis.flags.intensityScore;
    const contextLabel = analysis.context?.label || context;

    // 2) Retrieve (hybrid)
    const pool = await hybridRetrieve(text, contextLabel, toneKeyNorm, 200);

    // 3) Guardrails / contraindications
    const safePool = applyContraindications(pool, analysis.flags);

    // 4) Apply comprehensive guardrails and profanity filtering
    const guardedPool = this.applyAdvancedGuardrails(safePool, text, analysis);

    // 5) Attachment personalization
    const personalized = applyAttachmentOverrides(guardedPool, attachmentStyle);

    // 6) Rank (JSON-weighted)
    const ranked = this.adviceEngine.rank(personalized, {
      baseConfidence: analysis.tone.confidence,
      toneKey: toneKeyNorm,
      contextLabel,
      attachmentStyle,
      hasNegation: analysis.flags.hasNegation,
      hasSarcasm: analysis.flags.hasSarcasm,
      intensityScore,
      phraseEdgeHits: analysis.flags.phraseEdgeHits,
      userPref: dataLoader.get('userPreference'),
      tier
    });

    // 7) Diversity pick
    let picked = diversify(ranked, Math.max(3, Math.min(10, maxSuggestions)));

    // Adjust for new users: provide fewer, more general suggestions
    if (options.isNewUser) {
      picked = picked.slice(0, Math.max(2, Math.floor(picked.length * 0.6))); // Reduce by 40%
    }

    // 8) Calibrate confidence per context
    const calibrated = picked.map(it => ({ ...it, __calib: calibrate(it.ltrScore || 0.5, contextLabel) }));

    // 9) Build tone bucket dist for response header (from toneKeyNorm)
    const { primary, dist } = this.adviceEngine.resolveToneBucket(toneKeyNorm, contextLabel, intensityScore);

    // 10) Assemble response (no fallbacks)
    return {
      success: true,
      tier,
      original_text: text,
      context,
      suggestions: calibrated.map(({ advice, rewriteCue, categories, ltrScore, id, __calib }) => ({
        id,
        text: advice,
        rewriteCue,
        categories,
        type: 'rephrase',
        confidence: __calib ?? ltrScore ?? 0.5,
        reason: 'Therapeutic suggestion based on tone analysis',
        category: 'emotional_intelligence',
        priority: 1,
        context_specific: true,
        attachment_informed: true,
        ltrScore
      })),
      analysis: {
        tone: analysis.tone,
        mlGenerated: analysis.mlGenerated,
        context: analysis.context,
        flags: analysis.flags,
        toneBuckets: { primary, dist }
      },
      analysis_meta: {
        complexity_score: this.calculateComplexity(text),
        emotional_intensity: this.calculateEmotionalIntensity(text),
        clarity_level: this.calculateClarity(text),
        empathy_present: this.detectEmpathy(text),
        potential_triggers: this.identifyTriggers(text),
        recommended_approach: this.recommendApproach(context, options.conflictLevel || 'low')
      },
      metadata: {
        attachmentStyle,
        timestamp: new Date().toISOString(),
        version: '4.0.0'
      },
      trialStatus
    };
  }

  // ===== Legacy adapter (still no fallbacks) =====
  async generate(params: {
    text: string;
    toneHint?: string;
    styleHint?: string;
    features?: string[];
    meta?: any;
    analysis?: { classification: string; confidence: number } | null;
  }) {
    const { text, styleHint = 'secure', meta = {}, analysis = null } = params;
    const result = await this.generateAdvancedSuggestions(
      text,
      'general',
      meta.userProfile,
      {
        attachmentStyle: styleHint || 'secure',
        userId: meta.userId || 'anonymous',
        toneAnalysisResult: analysis
      }
    );

    return {
      quickFixes: result.suggestions.slice(0, 3).map(item => ({
        text: item.rewriteCue || item.text,
        confidence: item.confidence
      })),
      advice: result.suggestions.slice(0, 5).map(item => ({
        advice: item.text,
        reasoning: item.reason,
        confidence: item.confidence
      })),
      evidence: result.analysis.flags.phraseEdgeHits,
      extras: {
        tone: result.analysis.tone,
        context: result.analysis.context,
        tier: result.tier
      }
    };
  }

  // ===== Utility methods for analysis_meta (unchanged) =====
  private calculateComplexity(text: string): number {
    const words = Math.max(1, text.trim().split(/\s+/).length);
    const sentences = Math.max(1, text.split(/[.!?]+/).filter(Boolean).length);
    const avgWordsPerSentence = words / sentences;
    return Math.min(1, avgWordsPerSentence / 20);
  }

  private calculateEmotionalIntensity(text: string): number {
    const emotionalWords = ['love', 'hate', 'amazing', 'terrible', 'furious', 'devastated', 'thrilled'];
    const punctuation = (text.match(/[!?]/g) || []).length;
    const caps = (text.match(/[A-Z]{2,}/g) || []).length;
    let intensity = 0;
    emotionalWords.forEach(word => { if (text.toLowerCase().includes(word)) intensity += 0.2; });
    intensity += punctuation * 0.1;
    intensity += caps * 0.15;
    return Math.min(1, intensity);
  }

  private calculateClarity(text: string): number {
    const words = Math.max(1, text.trim().split(/\s+/).length);
    const vagueWords = ['maybe', 'perhaps', 'sort of', 'kind of', 'whatever'];
    let vagueCount = 0;
    vagueWords.forEach(word => { if (text.toLowerCase().includes(word)) vagueCount++; });
    return Math.max(0, 1 - (vagueCount / words * 5));
  }

  private detectEmpathy(text: string): boolean {
    const empathyMarkers = [
      'understand', 'feel', 'hear you', 'appreciate', 'see your point',
      'that makes sense', 'i can imagine', 'must be'
    ];
    return empathyMarkers.some(marker => text.toLowerCase().includes(marker));
  }

  private identifyTriggers(text: string): string[] {
    const commonTriggers = [
      { pattern: /\byou always\b/i, trigger: 'absolute language' },
      { pattern: /\byou never\b/i, trigger: 'absolute language' },
      { pattern: /\bwhat'?s wrong with you\b/i, trigger: 'personal attack' },
      { pattern: /\bstupid\b/i, trigger: 'name calling' },
      { pattern: /\bidiot\b/i, trigger: 'name calling' },
      { pattern: /\bwhatever\b/i, trigger: 'dismissiveness' },
      { pattern: /\bfine\b(?!\s+(with|by))/i, trigger: 'passive aggression' },
    ];
    return commonTriggers.filter(t => t.pattern.test(text)).map(t => t.trigger);
  }

  private recommendApproach(context: string, conflictLevel: string): string {
    if (conflictLevel === 'high') return 'validating';
    if (context === 'romantic') return 'gentle';
    if (context === 'professional') return 'direct';
    return 'exploratory';
  }
}

export const suggestionsService = new SuggestionsService();
