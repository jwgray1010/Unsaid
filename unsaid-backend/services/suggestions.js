/**
 * Suggestion.advanced.js
 * Advanced ML‑Enhanced Suggestions API (Therapy‑Advice Focus)
 *
 * Integrates:
 *  - spaCy‑like NLP (SpacyService)
 *  - ML tone analyzer (MLAdvancedToneAnalyzer)
 *  - JSON knowledge bases (contexts, triggers, negation/sarcasm, intensity, phrase_edges,
 *    therapy_advice, semantic_thesaurus, user_preference, severity_collaboration, tone_bucket_mapping)
 *  - Trial/premium gating (general vs premium datasets)
 *  - Learning‑to‑rank scoring w/ probabilistic tone buckets (not all angry == alert)
 *
 * New users: general subsets only. Premium/trial: full library + attachment‑tuned boosts.
 */

// ============================
// 0. Imports & Setup
// ============================
const fs = require('fs');
const path = require('path');
const { MLAdvancedToneAnalyzer } = require('./tone-analysis.js');
const { SpacyService } = require('./spacyservice.js');

function readJsonSafe(filePath, fallback = null) {
  try {
    const raw = fs.readFileSync(filePath, 'utf8');
    return JSON.parse(raw);
  } catch (err) {
    console.warn(`[WARN] Could not load ${filePath}: ${err.message}`);
    return fallback;
  }
}

// ============================
// 1. DataLoader
// ============================
class DataLoader {
  constructor() {
    this.dataDir = path.join(__dirname, 'data');
    this.cache = {};
  }

  loadAll() {
    const p = (f) => path.join(this.dataDir, f);

    this.cache.therapyAdvice = readJsonSafe(p('therapy_advice.json'), { version: '0', items: [] });
    this.cache.contextClassifier = readJsonSafe(p('context_classifier.json'), { version: '0', contexts: [] });
    this.cache.toneTriggerwords = readJsonSafe(p('tone_triggerwords.json'), { version: '0', triggers: [] });
    this.cache.intensityModifiers = readJsonSafe(p('intensity_modifiers.json'), { version: '0', modifiers: [] });
    this.cache.sarcasmIndicators = readJsonSafe(p('sarcasm_indicators.json'), { version: '0', sarcasm_indicators: [] });
    this.cache.negationIndicators = readJsonSafe(p('negation_indicators.json'), { version: '0', negation_indicators: [] });
    this.cache.phraseEdges = readJsonSafe(p('phrase_edges.json'), { version: '0', edges: [] });
    this.cache.severityCollab = readJsonSafe(p('severity_collaboration.json'), { alert: { base: 0.55 }, caution: { base: 0.4 }, clear: { base: 0.35 } });
    this.cache.semanticThesaurus = readJsonSafe(p('semantic_thesaurus.json'), { version: '0' });
    this.cache.userPreference = readJsonSafe(p('user_preference.json'), { categories: {} });
    this.cache.guardrailConfig = readJsonSafe(p('guardrail_config.json'), { blockedPatterns: [] });

    // NEW: probabilistic tone bucket mapping with context/intensity overrides
    this.cache.toneBucketMap = readJsonSafe(p('tone_bucket_mapping.json'), {
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
    });

    return this.cache;
  }

  get(name) { return this.cache[name]; }
}

// ============================
// 2. Trial / Tier Manager
// ============================
class TrialManager {
  async getTrialStatus(userId = 'anonymous', userEmail = null) {
    return {
      status: 'trial_active', inTrial: true, planType: 'trial',
      features: { 'tone-analysis': true, suggestions: true, advice: true },
      isActive: true, hasAccess: true, isAdmin: false,
      daysRemaining: 5, totalTrialDays: 7,
      userId, userEmail, timestamp: new Date().toISOString()
    };
  }
  resolveTier(trialStatus) {
    if (trialStatus?.hasAccess && (trialStatus?.inTrial || trialStatus?.planType === 'premium')) return 'premium';
    return 'general';
  }
}

// ============================
// 3. NLP + ML Orchestrator
// ============================
class AnalysisOrchestrator {
  constructor(spacyService, mlAnalyzer, data) {
    this.spacy = spacyService;
    this.ml = mlAnalyzer;
    this.data = data;
  }

  async analyze(text, providedTone, attachmentStyle, contextHint) {
    const spacy = this.spacy.process(text, {
      contextClassifier: this.data.get('contextClassifier'),
      negationIndicators: this.data.get('negationIndicators'),
      sarcasmIndicators: this.data.get('sarcasmIndicators'),
      intensityModifiers: this.data.get('intensityModifiers'),
      phraseEdges: this.data.get('phraseEdges'),
      semanticThesaurus: this.data.get('semanticThesaurus')
    });

    let toneResult = providedTone;
    let mlGenerated = false;

    if (!toneResult) {
      const ml = await this.ml.analyzeTone(text, attachmentStyle, contextHint || spacy.context?.label || 'general');
      if (ml?.success) {
        toneResult = { classification: ml.tone.classification, confidence: ml.tone.confidence };
        mlGenerated = true;
      } else {
        toneResult = { classification: 'neutral', confidence: 0.5, error: ml?.error };
      }
    }

    return {
      tone: toneResult,
      context: spacy.context, // { label, score }
      entities: spacy.entities,
      flags: {
        hasNegation: spacy.negation?.present || false,
        hasSarcasm: spacy.sarcasm?.present || false,
        intensityScore: spacy.intensity?.score || 0,
        phraseEdgeHits: spacy.phraseEdges?.hits || []
      },
      features: spacy.features,
      mlGenerated
    };
  }
}

// ============================
// 4. Advice Engine (probabilistic tone buckets)
// ============================
class AdviceEngine {
  constructor(dataLoader) {
    this.data = dataLoader;
    this.weights = {
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
  }

  resolveToneBucket(toneLabel, contextLabel, intensityScore = 0) {
    const map = this.data.get('toneBucketMap') || {};
    const base = (map.default && map.default[toneLabel]) || map.default?.neutral || { clear: 0.33, caution: 0.34, alert: 0.33 };
    // Context override
    const ctx = map.contextOverrides?.[contextLabel]?.[toneLabel];
    let dist = { ...(ctx || base) };
    // Intensity shift
    const thr = map.intensityShifts?.thresholds || { low: 0.15, med: 0.35, high: 0.60 };
    const shiftKey = intensityScore >= thr.high ? 'high' : intensityScore >= thr.med ? 'med' : 'low';
    const shift = map.intensityShifts?.[shiftKey] || { alert: 0, caution: 0, clear: 0 };
    dist = {
      clear:   Math.max(0, dist.clear   + (shift.clear   || 0)),
      caution: Math.max(0, dist.caution + (shift.caution || 0)),
      alert:   Math.max(0, dist.alert   + (shift.alert   || 0))
    };
    const sum = dist.clear + dist.caution + dist.alert || 1;
    dist.clear /= sum; dist.caution /= sum; dist.alert /= sum;
    const primary = Object.entries(dist).sort((a,b)=>b[1]-a[1])[0][0];
    return { primary, dist };
  }

  severityBaselineFor(toneKey, contextLabel) {
    const sev = this.data.get('severityCollab');
    const bucket = sev[toneKey] || sev['clear'];
    const base = bucket?.base ?? 0.35;
    const byCtx = bucket?.byContext || {};
    const ctxAdj = contextLabel ? (byCtx[contextLabel] || 0) : 0;
    return base + ctxAdj;
  }

  userPrefBoostFor(adviceItem, userPref) {
    if (!userPref || !userPref.categories) return 0;
    const cats = new Set([]);
    if (Array.isArray(adviceItem.categories)) adviceItem.categories.forEach((c) => cats.add(c));
    if (adviceItem.category) cats.add(adviceItem.category);
    let boost = 0;
    for (const c of cats) {
      const v = userPref.categories[c];
      if (typeof v === 'number') boost += v;
    }
    return boost;
  }

  retrieveCandidates(tier, toneKey, contextLabel, attachmentStyle, intensityScore = 0) {
    const db = this.data.get('therapyAdvice') || { items: [] };
    let items = db.items || [];

    // 1) Tier filter
    items = items.filter((it) => (it.tier ? it.tier === tier || tier === 'premium' : tier === 'general' ? (it.tier !== 'premium') : true));

    // 2) Context soft filter
    let ctxMatches = items.filter((it) => !it.contexts || it.contexts.length === 0 || it.contexts.includes(contextLabel));
    if (ctxMatches.length === 0) ctxMatches = items;

    // 3) Tone soft filter using probabilistic primary bucket
    const { primary } = this.resolveToneBucket(toneKey, contextLabel, intensityScore);
    let toneMatches = ctxMatches.filter((it) => !it.triggerTone || it.triggerTone === primary);
    if (toneMatches.length === 0) toneMatches = ctxMatches;

    // 4) Attachment soft filter
    let attachMatches = toneMatches.filter((it) => !it.attachmentStyles || it.attachmentStyles.length === 0 || it.attachmentStyles.includes(attachmentStyle));
    if (attachMatches.length === 0) attachMatches = toneMatches;

    return attachMatches.length ? attachMatches : items;
  }

  score(item, signals) {
    const {
      baseConfidence = 0.8,
      toneKey,
      contextLabel,
      attachmentStyle,
      hasNegation,
      hasSarcasm,
      intensityScore,
      phraseEdgeHits = [],
      userPref,
      tier
    } = signals;

    let score = 0;
    score += this.weights.baseConfidence * baseConfidence;

    // Tone match (probabilistic mass on item.triggerTone)
    const { dist } = this.resolveToneBucket(toneKey, contextLabel, intensityScore);
    const toneBucket = item.triggerTone || 'clear';
    const toneMatchMass = dist[toneBucket] ?? 0.33;
    score += this.weights.toneMatch * toneMatchMass;

    // Context match
    const ctxMatch = !item.contexts || item.contexts.length === 0 || item.contexts.includes(contextLabel) ? 1 : 0;
    score += this.weights.contextMatch * ctxMatch;

    // Attachment match
    const attachMatch = !item.attachmentStyles || item.attachmentStyles.length === 0 || item.attachmentStyles.includes(attachmentStyle) ? 1 : 0;
    score += this.weights.attachmentMatch * attachMatch;

    // Intensity boost
    score += this.weights.intensityBoost * Math.min(1, Math.max(0, intensityScore));

    // Negation / Sarcasm penalties
    if (hasNegation) score += this.weights.negationPenalty;
    if (hasSarcasm) score += this.weights.sarcasmPenalty;

    // Phrase edge hits
    score += this.weights.phraseEdgeBoost * Math.min(1, phraseEdgeHits.length / 3);

    // User preferences
    score += this.weights.userPrefBoost * this.userPrefBoostFor(item, userPref);

    // Severity fit vs baseline (by item threshold for bucket)
    const baseline = this.severityBaselineFor(toneBucket, contextLabel);
    const required = item.severityThreshold?.[toneBucket] ?? baseline;
    const sevDelta = Math.abs((required ?? baseline) - baseline);
    const sevScore = 1 - Math.min(sevDelta / 0.1, 1); // within ±0.1 is best
    score += this.weights.severityFit * sevScore;

    if (tier === 'premium') score += this.weights.premiumBoost;
    return score;
  }

  rank(items, signals) {
    return items
      .map((it) => ({ it, s: this.score(it, signals) }))
      .sort((a,b)=>b.s-a.s)
      .map(({it,s}) => ({ ...it, ltrScore: Number(s.toFixed(4)) }));
  }
}

// ============================
// 5. API Handler (Express/Vercel style)
// ============================
const dataLoader = new DataLoader();
const loaded = dataLoader.loadAll();
const trialManager = new TrialManager();
const mlToneAnalyzer = new MLAdvancedToneAnalyzer({ enableSmoothing: true, enableSafetyChecks: true });
const spacyService = new SpacyService();
const orchestrator = new AnalysisOrchestrator(spacyService, mlToneAnalyzer, dataLoader);
const adviceEngine = new AdviceEngine(dataLoader);

module.exports = {
  handler: async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-API-Key');
  if (req.method === 'OPTIONS') return res.status(200).end();

  if (req.method === 'GET') {
    return res.json({
      status: 'operational', type: 'ml-enhanced-suggestions', version: '3.0.0',
      notes: 'Probabilistic tone buckets + premium gating for therapy advice.',
      datasets: Object.keys(loaded || {}),
      gating: { free: 'general subset', premium: 'full library', trial: 'full to showcase' }
    });
  }

  if (req.method === 'POST') {
    try {
      const {
        text,
        toneAnalysisResult,
        attachmentStyle = 'secure',
        context = 'general',
        userId = 'anonymous',
        userEmail = null,
        // iOS aliases
        attachment_style = null,
        user_profile = null,
        communication_style = null,
        emotional_state = null,
        emotional_bucket = null,
        maxResults = 5
      } = req.body || {};

      if (!text) return res.status(400).json({ error: 'Missing required field: text' });

      const personalityData = {
        attachmentStyle: attachment_style || attachmentStyle,
        userProfile: user_profile,
        communicationStyle: communication_style,
        emotionalState: emotional_state,
        emotionalBucket: emotional_bucket
      };

      const trialStatus = await trialManager.getTrialStatus(userId, userEmail);
      if (!trialStatus?.hasAccess) return res.status(403).json({ error: 'Trial expired or access denied', trialStatus });
      const tier = trialManager.resolveTier(trialStatus); // 'general' | 'premium'

      // Run analysis (spaCy + ML fallback)
      const analysis = await orchestrator.analyze(text, toneAnalysisResult, personalityData.attachmentStyle, context);
      const toneKey = analysis.tone.classification;
      const intensityScore = analysis.flags.intensityScore;
      const contextLabel = analysis.context?.label || context;

      // Retrieve + rank advice
      const candidates = adviceEngine.retrieveCandidates(
        tier,
        toneKey,
        contextLabel,
        personalityData.attachmentStyle,
        intensityScore
      );

      const ranked = adviceEngine.rank(candidates, {
        baseConfidence: analysis.tone.confidence,
        toneKey,
        contextLabel,
        attachmentStyle: personalityData.attachmentStyle,
        hasNegation: analysis.flags.hasNegation,
        hasSarcasm: analysis.flags.hasSarcasm,
        intensityScore,
        phraseEdgeHits: analysis.flags.phraseEdgeHits,
        userPref: dataLoader.get('userPreference'),
        tier
      });

      // Top N
      const top = ranked.slice(0, Math.max(3, Math.min(10, maxResults)));

      // Response
      const { primary, dist } = adviceEngine.resolveToneBucket(toneKey, contextLabel, intensityScore);
      return res.json({
        success: true,
        tier,
        suggestions: top.map(({ advice, rewriteCue, categories, ltrScore, id }) => ({ id, text: advice, rewriteCue, categories, confidence: ltrScore })),
        analysis: {
          tone: analysis.tone,
          mlGenerated: analysis.mlGenerated,
          context: analysis.context,
          flags: analysis.flags,
          toneBuckets: { primary, dist }
        },
        metadata: {
          attachmentStyle: personalityData.attachmentStyle,
          timestamp: new Date().toISOString(),
          version: '3.0.0'
        },
        trialStatus
      });
    } catch (err) {
      console.error('Suggestions API Error:', err);
      return res.status(500).json({ error: 'Internal server error', message: err.message, type: 'suggestions_error' });
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
  },
  
  // Export service classes for use by other modules
  DataLoader,
  TrialManager,
  AnalysisOrchestrator,
  AdviceEngine,
  SuggestionsService: class SuggestionsService {
    constructor() {
      this.dataLoader = dataLoader;
      this.trialManager = trialManager;
      this.orchestrator = orchestrator;
      this.adviceEngine = adviceEngine;
    }
    
    async generate(params) {
      const {
        text,
        toneHint,
        styleHint,
        features = [],
        meta = {},
        analysis = null
      } = params;
      
      // Generate suggestions using the same logic as the handler
      const trialStatus = await this.trialManager.getTrialStatus(meta.userId || 'anonymous');
      const tier = this.trialManager.resolveTier(trialStatus);
      
      const analysisResult = analysis || await this.orchestrator.analyze(
        text, 
        null, 
        styleHint || 'secure', 
        'general'
      );
      
      const candidates = this.adviceEngine.retrieveCandidates(
        tier,
        analysisResult.tone.classification,
        analysisResult.context?.label || 'general',
        styleHint || 'secure',
        analysisResult.flags.intensityScore
      );
      
      const ranked = this.adviceEngine.rank(candidates, {
        baseConfidence: analysisResult.tone.confidence,
        toneKey: analysisResult.tone.classification,
        contextLabel: analysisResult.context?.label || 'general',
        attachmentStyle: styleHint || 'secure',
        hasNegation: analysisResult.flags.hasNegation,
        hasSarcasm: analysisResult.flags.hasSarcasm,
        intensityScore: analysisResult.flags.intensityScore,
        phraseEdgeHits: analysisResult.flags.phraseEdgeHits,
        userPref: this.dataLoader.get('userPreference'),
        tier
      });
      
      return {
        quickFixes: ranked.slice(0, 3).map(item => ({
          text: item.rewriteCue || item.advice,
          confidence: item.ltrScore || 0.5
        })),
        advice: ranked.slice(0, 5).map(item => ({
          advice: item.advice,
          reasoning: item.explanation || 'Therapeutic suggestion',
          confidence: item.ltrScore || 0.5
        })),
        evidence: analysisResult.flags.phraseEdgeHits || [],
        extras: {
          tone: analysisResult.tone,
          context: analysisResult.context,
          tier
        }
      };
    }
  }
};