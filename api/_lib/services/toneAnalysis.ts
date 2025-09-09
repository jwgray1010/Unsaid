// api/_lib/services/toneAnalysis.ts
/* ============================================================================
  UNSAID — ADVANCED TONE ANALYSIS (TypeScript, JSON-first)
  - Realtime token stream (clear/caution/alert) + sentence finalize
  - spaCy refinement (lemmas, negation scope, POS)
  - JSON-driven: toneBucketMapping, intensityModifiers, toneTriggerWords, etc.
  - Meta JSONs integrated: weightModifiers, guardrailConfig, profanityLexicons, learningSignals, evaluationTones
  - No network calls; no LLMs in the hot path
  - Compatibility exports kept (loadAllData, mapToneToBuckets, createToneAnalyzer, MLAdvancedToneAnalyzer)
============================================================================ */

import { logger } from '../logger';
import { dataLoader } from './dataLoader';
import { processWithSpacy, processWithSpacySync } from './spacyBridge';

// -----------------------------
// Types
// -----------------------------
type Bucket = 'clear'|'caution'|'alert';

export interface AdvancedToneResult {
  primary_tone: string;
  confidence: number;
  emotions: {
    joy: number;
    anger: number;
    fear: number;
    sadness: number;
    analytical: number;
    confident: number;
    tentative: number;
  };
  intensity: number;
  sentiment_score: number;
  linguistic_features: {
    formality_level: number;
    emotional_complexity: number;
    assertiveness: number;
    empathy_indicators: string[];
    potential_misunderstandings: string[];
  };
  context_analysis: {
    appropriateness_score: number;
    relationship_impact: 'positive' | 'neutral' | 'negative';
    suggested_adjustments: string[];
  };
  attachment_insights?: {
    likely_attachment_response: string;
    triggered_patterns: string[];
    healing_suggestions: string[];
  };
}

export interface ToneAnalysisOptions {
  context: string;
  userProfile?: any;
  attachmentStyle?: string;
  relationshipStage?: string;
  includeAttachmentInsights?: boolean;
  deepAnalysis?: boolean;
  isNewUser?: boolean;
}

// -----------------------------
// Utils
// -----------------------------
const clamp01 = (x:number)=>Math.max(0,Math.min(1,x));

function softmax3(log: Record<Bucket, number>): Record<Bucket, number> {
  const m = Math.max(log.clear, log.caution, log.alert, 0);
  const ec = Math.exp((log.clear ?? 0) - m);
  const eo = Math.exp((log.caution ?? 0) - m);
  const ea = Math.exp((log.alert ?? 0) - m);
  const Z = ec + eo + ea || 1;
  return { clear: ec/Z, caution: eo/Z, alert: ea/Z };
}

function normalize3(d: Record<Bucket, number>): Record<Bucket, number> {
  const s = (d.clear ?? 0) + (d.caution ?? 0) + (d.alert ?? 0) || 1;
  return { clear: (d.clear ?? 0)/s, caution: (d.caution ?? 0)/s, alert: (d.alert ?? 0)/s };
}

function plattCalibrate(conf: number, ctx: string) {
  const ev = dataLoader.get('evaluationTones');
  const ls = dataLoader.get('learningSignals');
  // base Platt
  const p = ev?.platt?.[ctx] ?? ev?.platt?.general ?? { a: 1, b: 0 };
  let calibrated = 1 / (1 + Math.exp(-(p.a*conf + p.b)));
  // light online adjustment from learning signals (context-wide slope/offset)
  const adj = ls?.plattAdjust?.[ctx] ?? { a: 1, b: 0 };
  calibrated = 1 / (1 + Math.exp(-(adj.a*calibrated + adj.b)));
  return clamp01(calibrated);
}

// -----------------------------
// spaCy Lite Adapter
// -----------------------------
type SpacyLite = {
  tokens: { text: string; lemma: string; pos: string; i: number }[];
  sents: { start: number; end: number }[];
  negScopes: Array<{ start: number; end: number }>;
  sarcasmCue: boolean;
  contextLabel?: string;
};

async function spacyLite(text: string, hintContext?: string): Promise<SpacyLite> {
  const r = await processWithSpacy(text, 'finalize');

  // Extract tokens from the actual spaCy response structure
  const tokens = (r as any).tokens || [];
  const tokensMapped = tokens.map((t: any, i: number) => ({
    text: t.text || '',
    lemma: (t.lemma || t.text || '').toLowerCase(),
    pos: (t.pos || 'X').toUpperCase(),
    i
  }));

  // Extract negation scopes - using simplified approach since detailed deps may not be available
  const negScopes: Array<{start:number;end:number}> = [];
  const deps = (r as any).deps || [];
  for (const dep of deps) {
    if (dep && dep.rel === 'neg') {
      const subtreeSpan = (r as any).subtreeSpan;
      const span = subtreeSpan?.[dep.head];
      if (span) negScopes.push({ start: span.start, end: span.end });
    }
  }

  // Extract sentence boundaries
  const sents = (r as any).sents || [];
  const sentsMapped = sents.map((s: any) => ({ start: s.start || 0, end: s.end || text.length }));

  return {
    tokens: tokensMapped,
    sents: sentsMapped,
    negScopes,
    sarcasmCue: !!(r as any).sarcasm?.present,
    contextLabel: (r as any).context?.label ?? hintContext ?? 'general'
  };
}

function spacyLiteSync(text: string, hintContext?: string): SpacyLite {
  const r = processWithSpacySync(text, 'finalize');

  // Extract tokens from the actual spaCy response structure
  const tokens = (r as any).tokens || [];
  const tokensMapped = tokens.map((t: any, i: number) => ({
    text: t.text || '',
    lemma: (t.lemma || t.text || '').toLowerCase(),
    pos: (t.pos || 'X').toUpperCase(),
    i
  }));

  // Extract negation scopes - using simplified approach since detailed deps may not be available
  const negScopes: Array<{start:number;end:number}> = [];
  const deps = (r as any).deps || [];
  for (const dep of deps) {
    if (dep && dep.rel === 'neg') {
      const subtreeSpan = (r as any).subtreeSpan;
      const span = subtreeSpan?.[dep.head];
      if (span) negScopes.push({ start: span.start, end: span.end });
    }
  }

  // Extract sentence boundaries
  const sents = (r as any).sents || [];
  const sentsMapped = sents.map((s: any) => ({ start: s.start || 0, end: s.end || text.length }));

  return {
    tokens: tokensMapped,
    sents: sentsMapped,
    negScopes,
    sarcasmCue: !!(r as any).sarcasm?.present,
    contextLabel: (r as any).context?.label ?? hintContext ?? 'general'
  };
}

// -----------------------------
// JSON-backed detectors
// -----------------------------
class ToneDetectors {
  private trigByLen = new Map<number, {term: string, bucket: Bucket, w: number}[]>();
  private negRegexes: RegExp[] = [];
  private sarcRegexes: RegExp[] = [];
  private edgeRegexes: { re: RegExp, cat: string }[] = [];
  private intensifiers: { re: RegExp, mult: number }[] = [];
  private profanity: string[] = [];

  constructor() {
    // Remove async initialization - will be lazy & sync
  }

  private initSyncIfNeeded() {
    if (this.trigByLen.size > 0) return; // Already initialized

    // DataLoader should already be initialized by ensureBoot()
    if (!dataLoader.isInitialized()) {
      logger.warn('DataLoader not initialized in ToneDetectors.initSyncIfNeeded');
      return;
    }

    const trig = dataLoader.get('toneTriggerWords') || dataLoader.get('toneTriggerwords');
    const negP = dataLoader.get('negationPatterns') || dataLoader.get('negationIndicators');
    const sarc = dataLoader.get('sarcasmIndicators');
    const edges = dataLoader.get('phraseEdges');
    const inten = dataLoader.get('intensityModifiers');
    const prof  = dataLoader.get('profanityLexicons');

    const push = (t: string, bucket: Bucket, w: number) => {
      const L = t.trim().toLowerCase().split(/\s+/).length;
      const arr = this.trigByLen.get(L) || [];
      arr.push({ term: t.toLowerCase(), bucket, w });
      this.trigByLen.set(L, arr);
    };

    // Expected shape from tone_triggerwords.json:
    // trig[style].triggerwords = [{ text, intensity, type, variants }, ...]
    for (const style of Object.keys(trig || {})) {
      const triggerwords = trig[style]?.triggerwords || [];
      triggerwords.forEach((item: any) => {
        const bucket = style as Bucket; // 'alert', 'caution', 'clear'
        const w = item.intensity || 1.0;
        const terms = [item.text, ...(item.variants || [])];
        terms.forEach((t: string) => push(t, bucket, w));
      });
    }

    const safe = (p: string) => { try { return new RegExp(p, 'i'); } catch { return null; } };
    (negP?.patterns || negP || []).forEach((p: string) => { const r = safe(String(p)); if (r) this.negRegexes.push(r); });
    (sarc?.patterns || sarc || []).forEach((p: string) => { const r = safe(String(p)); if (r) this.sarcRegexes.push(r); });
    (edges?.edges || edges || []).forEach((e: any) => { const r = safe(e.pattern); if (r) this.edgeRegexes.push({ re: r, cat: e.category || 'edge' }); });
    (inten?.modifiers || inten || []).forEach((m: any) => { const r = safe(m.pattern || m.regex); if (r) this.intensifiers.push({ re: r, mult: m.multiplier ?? m.baseMultiplier ?? 1 }); });

    this.profanity = prof?.block || [];

    logger.info(`ToneDetectors initialized with ${this.trigByLen.size} trigger word lengths`);
  }

  scanSurface(tokens: string[]): { bucket: Bucket; weight: number; term: string; start: number; end: number }[] { 
    return this.scan(tokens.map(t => t.toLowerCase())); 
  }
  scanLemmas(lemmas: string[]): { bucket: Bucket; weight: number; term: string; start: number; end: number }[] { 
    return this.scan(lemmas); 
  }

  private scan(terms: string[]): { bucket: Bucket; weight: number; term: string; start: number; end: number }[] {
    this.initSyncIfNeeded();   // ✅ No async in hot path

    const hits: { bucket: Bucket; weight: number; term: string; start: number; end: number }[] = [];
    const MAX_N = Math.max(1, ...Array.from(this.trigByLen.keys(), n => n || 1));
    for (let i=0;i<terms.length;i++) {
      for (let n=Math.min(MAX_N, terms.length - i); n>=1; n--) {
        const arr = this.trigByLen.get(n); if (!arr || !arr.length) continue;
        const span = terms.slice(i, i+n).join(' ');
        for (const cand of arr) if (span === cand.term) hits.push({ bucket:cand.bucket, weight:cand.w, term:cand.term, start:i, end:i+n-1 });
      }
    }
    return hits;
  }

  private initializeSync(): void {
    const trig = dataLoader.get('toneTriggerWords') || dataLoader.get('toneTriggerwords');
    const negP = dataLoader.get('negationPatterns') || dataLoader.get('negationIndicators');
    const sarc = dataLoader.get('sarcasmIndicators');
    const edges = dataLoader.get('phraseEdges');
    const inten = dataLoader.get('intensityModifiers');
    const prof  = dataLoader.get('profanityLexicons');

    const push = (t: string, bucket: Bucket, w: number) => {
      const L = t.trim().toLowerCase().split(/\s+/).length;
      const arr = this.trigByLen.get(L) || [];
      arr.push({ term: t.toLowerCase(), bucket, w });
      this.trigByLen.set(L, arr);
    };

    // Expected shape from tone_triggerwords.json:
    // trig[style].triggerwords = [{ text, intensity, type, variants }, ...]
    for (const style of Object.keys(trig || {})) {
      const triggerwords = trig[style]?.triggerwords || [];
      triggerwords.forEach((item: any) => {
        const bucket = style as Bucket; // 'alert', 'caution', 'clear'
        const w = item.intensity || 1.0;
        const terms = [item.text, ...(item.variants || [])];
        terms.forEach((t: string) => push(t, bucket, w));
      });
    }

    const safe = (p: string) => { try { return new RegExp(p, 'i'); } catch { return null; } };
    (negP?.patterns || negP || []).forEach((p: string) => { const r = safe(String(p)); if (r) this.negRegexes.push(r); });
    (sarc?.patterns || sarc || []).forEach((p: string) => { const r = safe(String(p)); if (r) this.sarcRegexes.push(r); });
    (edges?.edges || edges || []).forEach((e: any) => { const r = safe(e.pattern); if (r) this.edgeRegexes.push({ re: r, cat: e.category || 'edge' }); });
    (inten?.modifiers || inten || []).forEach((m: any) => { const r = safe(m.pattern || m.regex); if (r) this.intensifiers.push({ re: r, mult: m.multiplier ?? m.baseMultiplier ?? 1 }); });

    this.profanity = prof?.block || [];
  }

  hasNegation(text: string) { return this.negRegexes.some(r => r.test(text)); }
  hasSarcasm(text: string) { return this.sarcRegexes.some(r => r.test(text)); }
  edgeHits(text: string) { const out:string[]=[]; for (const {re,cat} of this.edgeRegexes) if (re.test(text)) out.push(cat); return out; }
  intensityBump(text: string) { let bump = 0; for (const {re,mult} of this.intensifiers) if (re.test(text)) bump += (mult - 1); return Math.max(0,bump); }
  containsProfanity(text: string) { const T = text.toLowerCase(); return this.profanity.some(w => T.includes(w)); }
}

const detectors = new ToneDetectors();

// -----------------------------
// Bucket mapping from JSON
// -----------------------------
function mapBucketsFromJson(
  toneLabel: string,
  contextKey: string,
  intensity: number
): { primary: Bucket, dist: Record<Bucket, number>, meta: any } {
  const map = dataLoader.get('toneBucketMapping') || dataLoader.get('toneBucketMap');
  const base = map?.default?.[toneLabel] ?? map?.default?.neutral ?? { clear:0.33,caution:0.34,alert:0.33 };
  let dist = { ...base };

  const ctx = map?.contextOverrides?.[contextKey]?.[toneLabel];
  if (ctx) dist = { ...dist, ...ctx };

  const thr = map?.intensityShifts?.thresholds ?? { low:0.15, med:0.35, high:0.60 };
  const key = intensity >= thr.high ? 'high' : intensity >= thr.med ? 'med' : 'low';
  const shift = map?.intensityShifts?.[key] ?? {};
  
  // Apply intensity shifts to the distribution
  dist = {
    clear: Math.max(0,(dist.clear ?? 0)+(shift.clear ?? 0)),
    caution: Math.max(0,(dist.caution ?? 0)+(shift.caution ?? 0)),
    alert: Math.max(0,(dist.alert ?? 0)+(shift.alert ?? 0)),
  };

  const s = dist.clear + dist.caution + dist.alert || 1;
  const normalizedDist = { clear: dist.clear/s, caution: dist.caution/s, alert: dist.alert/s };
  const primary = (Object.entries(normalizedDist).sort((a,b)=>b[1]-a[1])[0][0]) as Bucket;
  return { primary, dist: normalizedDist, meta: { intensity, key } };
}

// -----------------------------
// Realtime Tone Stream
// -----------------------------
export class ToneStream {
  private alpha = 0.6; // EWMA for token updates
  private lastDist: Record<Bucket, number> = { clear:1/3, caution:1/3, alert:1/3 };
  private tokens: string[] = [];
  private sentenceStart = 0;
  private buffer = '';
  private contextKey: string;
  private attachmentStyle: string;

  constructor(contextKey: string, attachmentStyle: string) {
    this.contextKey = contextKey;
    this.attachmentStyle = attachmentStyle;
  }

  feedChar(ch: string) {
    this.buffer += ch;
    if (/\s/.test(ch)) {
      const t = this.buffer.trim();
      if (t) this._fastToken(t);
      this.buffer = '';
    }
    if (/[.!?]/.test(ch)) {
      return this.finalizeSentence();
    }
    return null;
  }

  private _fastToken(token: string) {
    this.tokens.push(token);
    const win = this.tokens.slice(Math.max(0, this.tokens.length - 8));
    const hits = detectors.scanSurface(win);

    let log: Record<Bucket,number> = { clear:0,caution:0,alert:0 };
    for (const h of hits) log[h.bucket] += h.weight;

    const txt = win.join(' ');
    const bump = detectors.intensityBump(txt);
    log.alert += bump * 0.6; log.caution += bump * 0.2;

    // Guardrail: profanity instantly nudges toward alert
    if (detectors.containsProfanity(txt)) { log.alert += 0.5; log.clear -= 0.1; }

    const dist = softmax3(log);
    this.lastDist = normalize3({
      clear: this.alpha*dist.clear + (1-this.alpha)*this.lastDist.clear,
      caution: this.alpha*dist.caution + (1-this.alpha)*this.lastDist.caution,
      alert: this.alpha*dist.alert + (1-this.alpha)*this.lastDist.alert,
    });
  }

  private finalizeSentence() {
    if (this.tokens.length === 0) return;
    const win = this.tokens.slice(Math.max(0, this.tokens.length - 8));
    const hits = detectors.scanSurface(win);

    let log: Record<Bucket,number> = { clear:0,caution:0,alert:0 };
    for (const h of hits) log[h.bucket] += h.weight;

    const txt = win.join(' ');
    const bump = detectors.intensityBump(txt);
    log.alert += bump * 0.6; log.caution += bump * 0.2;

    // Guardrail: profanity instantly nudges toward alert
    if (detectors.containsProfanity(txt)) { log.alert += 0.5; log.clear -= 0.1; }

    const dist = softmax3(log);
    this.lastDist = normalize3({
      clear: this.alpha*dist.clear + (1-this.alpha)*this.lastDist.clear,
      caution: this.alpha*dist.caution + (1-this.alpha)*this.lastDist.caution,
      alert: this.alpha*dist.alert + (1-this.alpha)*this.lastDist.alert
    });

    this.tokens = [];
  }

  getCurrent() { return { ...this.lastDist }; }
}

export class ToneLiveController {
  private map = new Map<string, ToneStream>();
  get(fieldId: string, context='general', style='secure') {
    if (!this.map.has(fieldId)) this.map.set(fieldId, new ToneStream(context, style));
    return this.map.get(fieldId)!;
  }
  reset(fieldId: string) { this.map.delete(fieldId); }
}
export const toneLive = new ToneLiveController();

// -----------------------------
// Feature Extractor (JSON-aware)
// -----------------------------
class AdvancedFeatureExtractor {
  private emotionalLex: any;
  private attachmentHints: any;

  constructor() {
    this.emotionalLex = {
      anger: ['angry','mad','furious','frustrated','annoyed','irritated','pissed','livid','outraged'],
      sadness: ['sad','hurt','disappointed','upset','down','devastated','heartbroken'],
      anxiety: ['worried','anxious','nervous','scared','concerned','stressed','fearful','panicked'],
      joy: ['happy','excited','thrilled','delighted','joyful','glad','cheerful','ecstatic'],
      affection: ['love','adore','cherish','treasure','appreciate','care','affection','devoted']
    };
    this.attachmentHints = {
      secure: ['confident','trust','comfortable','open','balanced'],
      anxious: ['worried','need','please','afraid','insecure','clingy'],
      avoidant: ['fine','whatever','independent','space','alone']
    };
  }

  extract(text: string, attachmentStyle: string = 'secure') {
    const T = text.toLowerCase();
    const features: any = {};

    // emotions
    for (const [emo, list] of Object.entries(this.emotionalLex)) {
      let hits = 0; (list as string[]).forEach(k => { if (T.includes(k)) hits++; });
      features[`emo_${emo}`] = hits / Math.max(1, (list as string[]).length);
    }

    // simple counts
    const q = (text.match(/\?/g) || []).length; 
    const e = (text.match(/!/g) || []).length;
    features.int_q = q; features.int_exc = e;
    const caps = (text.match(/[A-Z]/g) || []).length; 
    const letters = (text.match(/[A-Za-z]/g) || []).length || 1;
    features.int_caps_ratio = caps / letters;
    features.int_elong = (text.match(/([a-z])\1{2,}/gi) || []).length;

    // intensity modifiers from JSON
    const intensityData = dataLoader.get('intensityModifiers');
    const mods = intensityData?.modifiers || [];
    let modScore = 0;
    mods.forEach((m: any) => { 
      if (m.pattern) { 
        try { 
          const r = new RegExp(m.pattern, 'i'); 
          if (r.test(text)) modScore += (m.multiplier || m.baseMultiplier || 1) - 1; 
        } catch {}
      } 
    });
    features.int_modscore = Math.max(0, modScore);

    // linguistics
    const S = text.split(/[.!?]+/).filter(s => s.trim().length > 0);
    features.lng_avgLen = S.length ? S.reduce((a, s) => a + s.length, 0) / S.length : 0;
    const first = [' i ',' me ',' my ',' mine ',' myself '];
    const second = [' you ',' your ',' yours ',' yourself '];
    const tpad = ` ${T} `;
    features.lng_first  = first.reduce((c, p) => c + (tpad.split(p).length - 1), 0);
    features.lng_second = second.reduce((c, p) => c + (tpad.split(p).length - 1), 0);
    features.lng_modal = (T.match(/\b(should|must|need to|have to|ought to)\b/g) || []).length;
    features.lng_absolutes = (T.match(/\b(always|never|every time)\b/g) || []).length;

    // attachment cues
    for (const [style, list] of Object.entries(this.attachmentHints)) {
      let hits = 0; (list as string[]).forEach(k => { if (T.includes(k)) hits++; });
      features[`attach_${style}`] = hits / Math.max(1, (list as string[]).length);
    }

    // negation/sarcasm regex fallback (spaCy will refine later)
    const neg = dataLoader.get('negationPatterns') || dataLoader.get('negationIndicators');
    const sar = dataLoader.get('sarcasmIndicators');
    const hasNeg = (neg?.patterns || neg || []).some((p:string)=>new RegExp(p,'i').test(text));
    const hasSarc = (sar?.patterns || sar || []).some((p:string)=>new RegExp(p,'i').test(text));
    features.neg_present = hasNeg ? 0.3 : 0;
    features.sarc_present = hasSarc ? 0.3 : 0;

    // phrase edges
    const phraseData = dataLoader.get('phraseEdges');
    const edges = phraseData?.edges || [];
    const hits: string[] = [];
    edges.forEach((e: any) => { 
      if (!e?.pattern) return; 
      try { const r = new RegExp(e.pattern, 'i'); if (r.test(text)) hits.push(e.category || 'edge'); } catch {}
    });
    features.edge_hits = hits.length; 
    features.edge_list = hits;

    return { features };
  }
}

// -----------------------------
// Tone Analysis Service (JSON-weighted)
// -----------------------------
export class ToneAnalysisService {
  private fx = new AdvancedFeatureExtractor();

  constructor(private config: any = {}) {
    this.config = Object.assign({ 
      enableSmoothing: true, 
      enableSafetyChecks: true, 
      confidenceThreshold: 0.25 
    }, config);
    this.ensureDataLoaded();
  }

  private async ensureDataLoaded(): Promise<void> {
    // DataLoader is now pre-initialized synchronously
    if (!dataLoader.isInitialized()) {
      logger.warn('DataLoader not initialized in ToneAnalysisService');
    }
  }

  private _weights(context: string) {
    const W = {
      emo: 0.40, ctx: 0.20, attach: 0.15, ling: 0.15, intensity: 0.10,
      negPenalty: 0.15, sarcPenalty: 0.18, absolutesBoost: 0.06
    };
    const mods = dataLoader.get('weightModifiers')?.byContext?.[context];
    if (mods) {
      // Allow additive overrides for transparency/simplicity
      for (const [k,v] of Object.entries(mods)) {
        if ((W as any)[k] !== undefined && typeof v === 'number') {
          (W as any)[k] = (W as any)[k] + v;
        }
      }
    }
    return W;
  }

  private _scoreTones(fr: any, text: string, attachmentStyle: string, contextHint: string) {
    const f = fr.features || {};
    const W = this._weights(contextHint);
    const out: any = { 
      neutral: 0.1, positive: 0.1, supportive: 0.1, 
      anxious: 0, angry: 0, frustrated: 0, sad: 0, assertive: 0 
    };

    // Emotion-driven
    out.angry      += (f.emo_anger || 0) * W.emo;
    out.sad        += (f.emo_sadness || 0) * W.emo;
    out.anxious    += (f.emo_anxiety || 0) * W.emo;
    out.positive   += (f.emo_joy || 0) * (W.emo * 0.9);
    out.supportive += (f.emo_affection || 0) * (W.emo * 0.9);

    // Context cues
    const ctx = (contextHint || 'general').toLowerCase();
    if (ctx === 'conflict') { out.angry += 0.25; out.frustrated += 0.20; }
    if (ctx === 'planning') { out.assertive += 0.12; out.neutral += 0.08; }
    if (ctx === 'repair')   { out.supportive += 0.18; }

    // Linguistic (absolutes & modals tilt toward confront/defend)
    out.angry     += Math.min(0.25, (f.lng_absolutes || 0) * (W.absolutesBoost ?? 0.06));
    out.assertive += Math.min(0.20, (f.lng_modal || 0) * 0.03);

    // Attachment adjustments
    if (attachmentStyle === 'anxious')  { out.anxious    += (f.attach_anxious || 0) * 0.35; }
    if (attachmentStyle === 'avoidant') { out.frustrated += (f.attach_avoidant || 0) * 0.25; }
    if (attachmentStyle === 'secure')   { out.supportive += (f.attach_secure || 0) * 0.25; }

    // Intensity (punctuation, caps, elongation, modifiers)
    const intensity = clamp01(
      (f.int_q || 0) * 0.05 + 
      (f.int_exc || 0) * 0.08 + 
      (f.int_caps_ratio || 0) * 0.8 + 
      (f.int_elong || 0) * 0.08 + 
      (f.int_modscore || 0)
    );
    out.angry      += intensity * (0.35 + (W.intensity ?? 0)*0.1); 
    out.frustrated += intensity * 0.25; 
    out.supportive -= intensity * 0.05;

    // Negation/sarcasm penalties
    const neg = f.neg_present || 0;
    const sar = f.sarc_present || 0;
    out.supportive -= sar * (W.sarcPenalty ?? 0.18); 
    out.positive   -= sar * ((W.sarcPenalty ?? 0.18) * 0.6);
    out.angry      += sar * 0.12; 
    out.frustrated += sar * 0.10;
    out.angry      += neg * (0.10 + (W.negPenalty ?? 0.15)*0.05); 
    out.frustrated += neg * 0.08; 
    out.neutral    -= neg * 0.05;

    // Phrase edges (rupture/repair)
    const edgeHits = Array.isArray(f.edge_list) ? f.edge_list : [];
    if (edgeHits.includes('rupture')) { out.angry += 0.25; out.frustrated += 0.15; }
    if (edgeHits.includes('repair'))  { out.supportive += 0.22; }

    // Profanity guardrail: push toward alert and dampen supportive
    if (detectors.containsProfanity(text)) { out.angry += 0.3; out.supportive = Math.max(0, out.supportive - 0.2); }

    for (const k of Object.keys(out)) out[k] = Math.max(0, out[k]);
    return { scores: out, intensity };
  }

  private _softmaxScores(scores: any) {
    const vals = Object.values(scores) as number[];
    const max = Math.max(...vals, 0);
    const exps: any = {}; let sum = 0;
    for (const [k, v] of Object.entries(scores)) { const e = Math.exp((v as number) - max); exps[k] = e; sum += e; }
    const dist: any = {}; 
    for (const [k, e] of Object.entries(exps)) dist[k] = (e as number) / (sum || 1);
    return dist;
  }

  private _primaryFromDist(dist: any) {
    return Object.entries(dist).sort((a: any, b: any) => b[1] - a[1])[0][0];
  }

  private _safety(text: string): boolean {
    const g = dataLoader.get('guardrailConfig');
    const t = text.toLowerCase();
    const kw: string[] = g?.selfHarmKeywords ?? ['kill','die','suicide','hurt myself','end it all','harm'];
    return kw.some(k => t.includes(k));
  }

  private _formality(text: string): number {
    const formal = ['please','thank you','regards','sincerely','furthermore','however'];
    const informal = ['gonna','wanna','hey','yeah','lol','omg'];
    const T = text.toLowerCase();
    const f = formal.reduce((n,w)=>n+(T.includes(w)?1:0),0);
    const i = informal.reduce((n,w)=>n+(T.includes(w)?1:0),0);
    if (!f && !i) return 0.5;
    return f / (f+i);
  }

  private _empathyIndicators(text: string): string[] {
    const indicators = [
      { pattern: /\bi understand\b/i, indicator: 'understanding acknowledgment' },
      { pattern: /\bi can see\b/i, indicator: 'perspective taking' },
      { pattern: /\bthat must be\b/i, indicator: 'emotional validation' },
      { pattern: /\bi hear you\b/i, indicator: 'active listening' },
      { pattern: /\bi appreciate\b/i, indicator: 'gratitude expression' },
      { pattern: /\bmakes sense\b/i, indicator: 'validation' },
    ];
    return indicators.filter(i => i.pattern.test(text)).map(i => i.indicator);
  }

  private _misunderstandings(text: string): string[] {
    const issues = [
      { pattern: /\byou always\b/i, issue: 'absolute language may trigger defensiveness' },
      { pattern: /\byou never\b/i, issue: 'absolute language may trigger defensiveness' },
      { pattern: /\bobviously\b/i, issue: 'may sound condescending' },
      { pattern: /\bwhatever\b/i, issue: 'dismissive tone' },
      { pattern: /\bfine\b(?!\s+(with|by))/i, issue: 'may indicate passive aggression' },
      { pattern: /\bshould have\b/i, issue: 'may sound judgmental' },
    ];
    return issues.filter(i => i.pattern.test(text)).map(i => i.issue);
  }

  private _detectPrimaryToneHeuristic(text: string): string {
    const T = text.toLowerCase();
    if (T.includes('love') || T.includes('appreciate') || T.includes('grateful')) return 'positive';
    if (T.includes('hate') || T.includes('angry') || T.includes('frustrated')) return 'negative';
    if (T.includes('?') || T.includes('maybe') || T.includes('perhaps')) return 'tentative';
    if (T.includes('!') || T.includes('definitely') || T.includes('absolutely')) return 'confident';
    return 'neutral';
  }

  async analyzeAdvancedTone(text: string, options: ToneAnalysisOptions = { context: 'general' }): Promise<AdvancedToneResult> {
    try {
      this.ensureDataLoaded();

      const style = options.attachmentStyle || 'secure';

      // Use spaCy bridge with reliability features
      const doc = await spacyLite(text, options.context);

      // Extract features
      const fr = this.fx.extract(text, style);
      // Replace naive neg/sarc with spaCy scoped values
      fr.features.neg_present = doc.negScopes.length > 0 ? 0.3 : 0;
      fr.features.sarc_present = doc.sarcasmCue ? 0.3 : 0;

      // POS-aware intensity facets
      const advBump = doc.tokens.filter(t => t.pos === 'ADV').length * 0.04;
      const excl = (text.match(/!/g)||[]).length * 0.08;
      const q = (text.match(/\?/g)||[]).length * 0.04;
      const caps = (text.match(/[A-Z]{2,}/g)||[]).length * 0.12;

      // Score
      const { scores, intensity: baseIntensity } = this._scoreTones(fr, text, style, doc.contextLabel || options.context || 'general');
      const intensity = clamp01(baseIntensity + advBump + excl + q + caps);

      // Softmax
      const distribution = this._softmaxScores(scores);
      let classification = this._primaryFromDist(distribution);
      let confidence = distribution[classification] || 0.33;

      // Guardrail: safety override
      if (this.config.enableSafetyChecks && this._safety(text)) {
        classification = 'safety_concern';
        confidence = Math.max(confidence, 0.95);
      }

      // LearningSignals: nudge thresholds (e.g., reduce false "positive" in conflict)
      const ls = dataLoader.get('learningSignals');
      const ctxAdj = ls?.toneBias?.[(doc.contextLabel || options.context || 'general')];
      if (ctxAdj?.[classification] !== undefined) {
        confidence = clamp01(confidence + ctxAdj[classification]);
      }

      // Confidence calibration (Platt + learningSignals adjustment)
      confidence = plattCalibrate(confidence, doc.contextLabel || options.context || 'general');

      // Adjust for new users: reduce confidence to encourage learning
      if (options.isNewUser) {
        confidence = Math.max(0.1, confidence * 0.7); // Reduce confidence by 30% for new users
      }

      // Pack result
      const emotions = {
        joy: scores.positive || 0,
        anger: scores.angry || 0,
        fear: scores.anxious || 0,
        sadness: scores.sad || 0,
        analytical: scores.assertive || 0,
        confident: scores.supportive || 0,
        tentative: scores.neutral || 0
      };

      const sentiment_score = clamp01((emotions.joy + emotions.confident) - (emotions.anger + emotions.sadness + emotions.fear));

      const result: AdvancedToneResult = {
        primary_tone: classification,
        confidence,
        emotions,
        intensity,
        sentiment_score,
        linguistic_features: {
          formality_level: this._formality(text),
          emotional_complexity: Object.values(emotions).filter(v => v > 0.1).length / 7,
          assertiveness: emotions.analytical,
          empathy_indicators: this._empathyIndicators(text),
          potential_misunderstandings: this._misunderstandings(text),
        },
        context_analysis: {
          appropriateness_score: Math.max(0, 1 - emotions.anger - emotions.fear),
          relationship_impact: sentiment_score > 0.2 ? 'positive' : sentiment_score < -0.2 ? 'negative' : 'neutral',
          suggested_adjustments: emotions.anger > 0.4 ? ['Consider softening the tone'] : []
        },
      };

      if (options.includeAttachmentInsights) {
        result.attachment_insights = {
          likely_attachment_response: style,
          triggered_patterns: emotions.fear > 0.4 ? ['anxiety triggers detected'] : [],
          healing_suggestions: emotions.confident > 0.3 ? ['Continue supportive communication'] : []
        };
      }

      return result;
    } catch (err) {
      logger.error('Advanced tone analysis failed:', err);
      // no LLM fallback; return neutral minimal result
      return {
        primary_tone: 'neutral',
        confidence: 0.3,
        emotions: { joy:0, anger:0, fear:0, sadness:0, analytical:0, confident:0, tentative:0.3 },
        intensity: 0.3,
        sentiment_score: 0,
        linguistic_features: {
          formality_level: 0.5,
          emotional_complexity: 0.3,
          assertiveness: 0.3,
          empathy_indicators: [],
          potential_misunderstandings: ['Analysis failed - using fallback']
        },
        context_analysis: {
          appropriateness_score: 0.5,
          relationship_impact: 'neutral',
          suggested_adjustments: ['Try again with different text']
        }
      };
    }
  }
}

export const toneAnalysisService = new ToneAnalysisService();

// -----------------------------
// Compatibility exports (JS parity)
// -----------------------------
export function loadAllData(baseDir?: string): any {
  return {
    contextClassifier: dataLoader.get('contextClassifier'),
    toneTriggerwords: dataLoader.get('toneTriggerWords') || dataLoader.get('toneTriggerwords'),
    intensityModifiers: dataLoader.get('intensityModifiers'),
    sarcasmIndicators: dataLoader.get('sarcasmIndicators'),
    negationIndicators: dataLoader.get('negationIndicators') || dataLoader.get('negationPatterns'),
    phraseEdges: dataLoader.get('phraseEdges'),
    semanticThesaurus: dataLoader.get('semanticThesaurus'),
    toneBucketMap: dataLoader.get('toneBucketMapping') || dataLoader.get('toneBucketMap'),
    // meta sets exposed too
    weightModifiers: dataLoader.get('weightModifiers'),
    guardrailConfig: dataLoader.get('guardrailConfig'),
    profanityLexicons: dataLoader.get('profanityLexicons'),
    learningSignals: dataLoader.get('learningSignals'),
    evaluationTones: dataLoader.get('evaluationTones'),
  };
}

export function mapToneToBuckets(
  toneResult: any, 
  attachmentStyle: string = 'secure', 
  contextKey: string = 'default', 
  data: any = null, 
  config: any = {}
): any {
  if (!data) {
    data = loadAllData(config.dataDir);
  }
  
  const bucketMap = data.toneBucketMap || {};
  const defaultBuckets = bucketMap.default || {};
  const contextOverrides = bucketMap.contextOverrides || {};
  const intensityShifts = bucketMap.intensityShifts || {};
  
  const tone = toneResult.classification || toneResult.tone?.classification || toneResult.primary_tone || 'neutral';
  const confidence = toneResult.confidence || toneResult.tone?.confidence || 0.5;
  
  // Get base bucket probabilities
  let buckets = { clear: 0.5, caution: 0.3, alert: 0.2 };
  if (defaultBuckets[tone]) buckets = { ...defaultBuckets[tone] };
  
  // Apply context overrides if available
  if (contextOverrides[contextKey] && contextOverrides[contextKey][tone]) {
    buckets = { ...buckets, ...contextOverrides[contextKey][tone] };
  }
  
  // Apply intensity shifts based on confidence (proxy)
  const thresholds = intensityShifts.thresholds || { low: 0.15, med: 0.35, high: 0.60 };
  let intensityLevel: 'low'|'med'|'high' = 'med';
  if (confidence < thresholds.low) intensityLevel = 'low';
  else if (confidence > thresholds.high) intensityLevel = 'high';
  
  const shifts = intensityShifts[intensityLevel] || {};
  for (const [bucket, shift] of Object.entries(shifts)) {
    if ((buckets as any)[bucket] !== undefined) {
      (buckets as any)[bucket] = Math.max(0, Math.min(1, (buckets as any)[bucket] + (shift as number)));
    }
  }
  
  // Normalize
  const total = Object.values(buckets).reduce((sum, val) => sum + (val as number), 0);
  if (total > 0) {
    (['clear','caution','alert'] as Bucket[]).forEach(b => (buckets as any)[b] = (buckets as any)[b] / total);
  }
  
  return {
    buckets,
    metadata: { tone, confidence, attachmentStyle, contextKey, intensityLevel }
  };
}

export function createToneAnalyzer(config: any = {}): any {
  const {
    premium = false,
    confidenceThreshold = 0.25,
    dataDir,
    enableSmoothing = true,
    smoothingAlpha = 0.7,
    hysteresisThreshold = 0.2,
    decayRate = 0.95
  } = config;

  const tier = premium ? 'premium' : 'general';
  const data = loadAllData(dataDir);

  return {
    async analyzeTone(text: string, attachmentStyle: string = 'secure', contextHint: string = 'general') {
      const result = await toneAnalysisService.analyzeAdvancedTone(text, {
        context: contextHint,
        attachmentStyle,
        includeAttachmentInsights: premium
      });
      return {
        success: true,
        tone: { classification: result.primary_tone, confidence: result.confidence },
        emotions: result.emotions,
        intensity: result.intensity,
        metadata: { attachmentStyle, context: contextHint, tier, timestamp: new Date().toISOString() }
      };
    },
    mapToneToBuckets(toneResult: any, attachmentStyle: string = 'secure', contextKey: string = 'default') {
      return mapToneToBuckets(toneResult, attachmentStyle, contextKey, data, config);
    },
    getConfig() { return { ...config, tier }; },
    updateConfig(newConfig: any) { Object.assign(config, newConfig); return this; }
  };
}

// -----------------------------
// MLAdvancedToneAnalyzer (compat shim)
// -----------------------------
export class MLAdvancedToneAnalyzer {
  private cfg: any;
  constructor(config: any = {}) { this.cfg = config; }
  async analyzeTone(text: string, attachmentStyle: string = 'secure', contextHint: string = 'general', tier: string = 'general') {
    try {
      const res = await toneAnalysisService.analyzeAdvancedTone(text, {
        context: contextHint,
        attachmentStyle,
        includeAttachmentInsights: tier === 'premium'
      });
      return {
        success: true,
        tone: { classification: res.primary_tone, confidence: res.confidence },
        scores: res.emotions,
        distribution: res.emotions,
        features: { count: Object.keys(res.linguistic_features || {}).length, bundle: res.linguistic_features },
        metadata: { attachmentStyle, context: contextHint, tier, timestamp: new Date().toISOString() }
      };
    } catch (error:any) {
      logger.error('Tone analysis error', error);
      return { success: false, tone: { classification: 'neutral', confidence: 0.1, error: error?.message || 'Unknown' } };
    }
  }
}
