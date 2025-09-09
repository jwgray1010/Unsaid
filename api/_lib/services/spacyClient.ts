// api/_lib/services/spacyClient.ts
// -----------------------------------------------------------------------------
// Local-only "spaCy helper" (no cloud, no Python). Lightweight heuristics
// that provide just enough NLP signal for your JSON-first tone engine:
// - tokens (text/lemma/POS)
// - sentence spans (char offsets)
// - dependency-ish negation scopes (neg -> head + subtree span)
// - cheap sarcasm/intensity/edge hits via your JSON config (precompiled)
// - context classification (JSON)
//
// Design goals:
// - Safe: input clamp, time/complexity budgets, graceful degradation
// - Fast: precompiled regexes; LRU caching
// - Compatible: preserves legacy exports + shapes used by toneAnalysis.ts
// -----------------------------------------------------------------------------

import { readFileSync } from 'fs';
import { join, resolve } from 'path';
import { env } from 'process';
import { performance } from 'perf_hooks';
import { logger } from '../logger';

// -----------------------------
// Public types (kept for compatibility)
// -----------------------------
export interface SpacyToken {
  text: string;
  lemma: string;
  pos: string;
  tag?: string;
  dep?: string;
  ent_type?: string;
  is_alpha: boolean;
  is_stop: boolean;
  is_punct: boolean;
  index: number;
  start?: number; // char start (added)
  end?: number;   // char end   (added)
}

export interface SpacyEntity {
  text: string;
  label: string;
  start: number;
  end: number;
}

export interface SpacyDependency {
  text: string;     // surface text for the relation span
  relation: string; // e.g., 'neg'
  start: number;    // char start of the relation span
  end: number;      // char end of the relation span
  head?: number;    // token index of the head
  token?: number;   // token index of the dependent (neg trigger)
}

export interface ContextClassification {
  primaryContext: string;
  secondaryContext: string | null;
  allContexts: Array<{
    context: string;
    score: number;
    confidence: number;
    matchedPatterns: string[];
    description?: string;
  }>;
  confidence: number;
}

export interface NegationAnalysis {
  hasNegation: boolean;
  negations: Array<{
    negationWord: string;
    position: number; // char offset
    scope: string;    // substring window
    type: string;     // simple | contraction | absolute | complex_pattern
  }>;
  negationCount: number;
}

export interface SarcasmAnalysis {
  hasSarcasm: boolean;
  sarcasmIndicators: Array<{
    pattern: string;
    position: number; // char offset
    type: string;     // linguistic_pattern | punctuation_pattern | json_indicator
    confidence: number;
  }>;
  sarcasmScore: number;
  overallSarcasmProbability: number;
}

export interface IntensityAnalysis {
  hasIntensity: boolean;
  intensityWords: Array<{
    word: string;
    position: number;
    level: string;      // low | moderate | moderate-high | high | custom
    multiplier: number; // numeric weight
    scope: string;
  }>;
  intensityCount: number;
  overallIntensity: number;
  dominantLevel: string;
}

export interface SpacyProcessResult {
  // Compact surface for orchestrators (kept for compatibility)
  context: { label: string; score: number };
  entities: SpacyEntity[];
  negation: { present: boolean; score: number };
  sarcasm: { present: boolean; score: number };
  intensity: { score: number };
  phraseEdges: { hits: string[] };
  features: { featureCount: number };

  // Extra fields used by toneAnalysis.ts (spacyLiteSync expects these):
  tokens?: SpacyToken[];
  sents?: Array<{ start: number; end: number }>;
  deps?: Array<{ rel: string; head: number; token: number; start: number; end: number }>;
  subtreeSpan?: Record<number, { start: number; end: number }>; // by head index
}

export interface SpacyFullAnalysis {
  originalText: string;
  tokens: SpacyToken[];
  entities: SpacyEntity[];
  dependencies: SpacyDependency[];
  contextClassification: ContextClassification;
  negationAnalysis: NegationAnalysis;
  sarcasmAnalysis: SarcasmAnalysis;
  intensityAnalysis: IntensityAnalysis;
  _phraseEdgeHits: string[];
  processingTimeMs: number;
  timestamp: string;
  // extras for convenience
  sents: Array<{ start: number; end: number }>;
  deps: Array<{ rel: string; head: number; token: number; start: number; end: number }>;
  subtreeSpan: Record<number, { start: number; end: number }>;
}

// Helper doc shape (local helper only, no network)
export type SpacyHelperField = 'tokens'|'sents'|'neg_scopes'|'pos_counts'|'entities';
export interface SpacyHelperDoc {
  tokens?: Array<{ text: string; lemma: string; pos: string; i: number }>;
  sents?: Array<{ start: number; end: number }>;
  neg_scopes?: Array<{ start: number; end: number; trigger: string }>;
  pos_counts?: Record<string, number>;
  entities?: SpacyEntity[];
  context?: { label: string; score: number };
  sarcasm?: { present: boolean };
}

// -----------------------------
// Implementation
// -----------------------------

type Mode = 'lite'|'balanced'|'max';

export class SpacyService {
  private dataPath: string;
  private mode: Mode;
  private budgets = { maxMillis: 60, maxChars: 2000, maxTokens: 400 };

  // caches
  private _analysisLRU = new Map<string, SpacyFullAnalysis>();
  private _helperLRU   = new Map<string, SpacyHelperDoc>();
  private _LRU_MAX = 128;

  // precompiled JSON-driven patterns
  private negationPatterns: RegExp[] = [];
  private sarcasmPatterns: Array<{rx:RegExp; conf:number}> = [];
  private edgePatterns: Array<{rx:RegExp; cat:string}> = [];
  private intensityPatterns: Array<{rx:RegExp; mult:number; level?:string}> = [];

  // raw config sets (loaded once)
  private contextClassifiers: any = { contexts: [] };
  private negationIndicators: any = { patterns: [] };
  private sarcasmIndicators: any = { patterns: [] };
  private intensityModifiers: any = { modifiers: [] };
  private phraseEdges: any = { edges: [] };

  // simple entity + token regexes
  private entityPatterns = {
    PERSON: /\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\b/g,
    INTENSITY: /\b(very|extremely|really|quite|somewhat|a little|slightly|incredibly|totally|completely|barely|hardly|absolutely|utterly)\b/gi,
    NEGATION: /\b(not|don't|won't|can't|shouldn't|wouldn't|couldn't|haven't|hasn't|hadn't|isn't|aren't|wasn't|weren't|never|no|none|nothing|nobody|nowhere)\b/gi
  } as const;

  constructor(opts: any = {}) {
    this.dataPath = opts.dataPath || resolve(process.cwd(), 'data');
    this.mode = (opts.mode as Mode) || (env.SPACY_MODE as Mode) || 'balanced';
    if (opts.budgets) this.budgets = { ...this.budgets, ...opts.budgets };
    this._loadAll();
    this._precompile();
  }

  // ---------- LRU helpers ----------
  private _lruGet<T>(m: Map<string, T>, k: string): T | null {
    const v = m.get(k);
    if (!v) return null;
    m.delete(k); m.set(k, v);
    return v;
  }
  private _lruSet<T>(m: Map<string, T>, k: string, v: T) {
    if (m.has(k)) m.delete(k);
    m.set(k, v);
    if (m.size > this._LRU_MAX) {
      const firstKey = m.keys().next().value as string;
      m.delete(firstKey);
    }
  }

  // ---------- data loading ----------
  private _readJsonSafe(file: string, fb: any = null): any {
    const tries = [
      join(process.cwd(), 'data', file),
      join(this.dataPath, file),
      join(resolve(__dirname, '../../../data'), file),
      join(resolve(__dirname, '../../../../data'), file),
      join(resolve('/vercel/path0', 'data'), file),
      join(resolve(env.LAMBDA_TASK_ROOT || process.cwd(), 'data'), file)
    ];
    for (const p of tries) {
      try {
        const content = readFileSync(p, 'utf8');
        logger.info(`[SpacyService] Loaded ${file} from ${p} (${content.length} chars)`);
        return JSON.parse(content);
      } catch (e: any) {
        logger.debug(`[SpacyService] Failed ${file}@${p}: ${e.message}`);
      }
    }
    logger.warn(`[SpacyService] Falling back for ${file}`);
    return fb;
  }

  private _loadAll(): void {
    this.contextClassifiers  = this._readJsonSafe('context_classifier.json', { contexts: [] });
    this.negationIndicators  = this._readJsonSafe('negation_indicators.json', { patterns: [] });
    this.sarcasmIndicators   = this._readJsonSafe('sarcasm_indicators.json', { patterns: [] });
    this.intensityModifiers  = this._readJsonSafe('intensity_modifiers.json', { modifiers: [] });
    this.phraseEdges         = this._readJsonSafe('phrase_edges.json', { edges: [] });
  }

  private _precompile(): void {
    // Negation
    const neg = (this.negationIndicators?.negation_indicators || this.negationIndicators?.patterns || []) as any[];
    this.negationPatterns = neg.map((p) => {
      try { return new RegExp(p.pattern || p, 'i'); } catch { return null; }
    }).filter(Boolean) as RegExp[];

    // Sarcasm (merge base + JSON)
    const baseSarcasm = [
      /oh\s+(?:great|wonderful|fantastic|perfect|brilliant)/i,
      /yeah\s+(?:right|sure|ok)/i,
      /(?:sure|fine|whatever)(?:\s*[.!]){2,}/i,
      /\b(?:obviously|clearly|definitely)\b.*\?/i
    ].map(rx => ({ rx, conf: 0.7 }));

    const jsonSarcasm = ((this.sarcasmIndicators?.sarcasm_indicators || this.sarcasmIndicators?.patterns || []) as any[])
      .map((e) => { try { return { rx: new RegExp(e.pattern || e, 'i'), conf: e.impact ? Math.min(1, Math.abs(e.impact)) : 0.6 }; } catch { return null; } })
      .filter(Boolean) as Array<{rx:RegExp; conf:number}>;

    this.sarcasmPatterns = [...baseSarcasm, ...jsonSarcasm];

    // Phrase edges
    this.edgePatterns = ((this.phraseEdges?.edges || []) as any[])
      .map((e) => { try { return { rx: new RegExp(e.pattern, 'i'), cat: e.category || 'edge' }; } catch { return null; } })
      .filter(Boolean) as Array<{rx:RegExp; cat:string}>;

    // Intensity modifiers
    const mods = (this.intensityModifiers?.modifiers || this.intensityModifiers || []) as any;
    if (Array.isArray(mods)) {
      this.intensityPatterns = mods.map((m: any) => {
        try { return { rx: new RegExp(m.pattern || m.regex, 'i'), mult: m.multiplier ?? m.baseMultiplier ?? 1, level: m.class }; }
        catch { return null; }
      }).filter(Boolean) as Array<{rx:RegExp; mult:number; level?:string}>;
    } else if (mods && typeof mods === 'object') {
      this.intensityPatterns = [];
      Object.entries(mods).forEach(([lvl, dict]: [string, any]) => {
        Object.entries(dict || {}).forEach(([k, v]: [string, any]) => {
          try { this.intensityPatterns.push({ rx: new RegExp(k, 'i'), mult: Number(v) || 1, level: lvl }); } catch {}
        });
      });
    }
  }

  // ---------- tiny NLP helpers ----------
  private simplePOSTag(word: string): string {
    const w = word.toLowerCase();
    const pron = ['i','you','he','she','it','we','they','me','him','her','us','them','my','your','our','their'];
    const aux  = ['am','is','are','was','were','be','been','being','do','does','did','have','has','had','will','would','could','should','may','might','must'];
    if (pron.includes(w)) return 'PRON';
    if (aux.includes(w)) return 'AUX';
    if (/ing$/.test(w) || /ed$/.test(w)) return 'VERB';
    if (/ly$/.test(w)) return 'ADV';
    if (/^[A-Z]/.test(word)) return 'PROPN';
    return 'NOUN';
  }

  private basicLemmatize(word: string): string {
    const w = word.toLowerCase();
    if (w.endsWith("n't")) return w.replace("n't"," not");
    if (w.endsWith('ing') && w.length > 4) return w.slice(0, -3);
    if (w.endsWith('ed') && w.length > 3) return w.slice(0, -2);
    if (w.endsWith('s') && w.length > 3) return w.slice(0, -1);
    return w;
  }

  private isStopWord(word: string): boolean {
    const stop = ['the','a','an','and','or','but','in','on','at','to','for','of','with','by','from','as','that','this'];
    return stop.includes(word.toLowerCase());
  }

  private clamp(text: string): string {
    return text.length > this.budgets.maxChars ? text.slice(0, this.budgets.maxChars) : text;
  }

  private splitTokens(text: string): SpacyToken[] {
    const tokens: SpacyToken[] = [];
    const rx = /\w+|[^\s\w]/g; // words or single punctuation
    let m: RegExpExecArray | null;
    let i = 0;
    while ((m = rx.exec(text)) !== null) {
      const t = m[0];
      const start = m.index;
      const end = m.index + t.length;
      tokens.push({
        text: t,
        index: i++,
        pos: this.simplePOSTag(t),
        lemma: this.basicLemmatize(t),
        is_alpha: /^[A-Za-z]+$/.test(t),
        is_stop: this.isStopWord(t),
        is_punct: /^[^\w\s]+$/.test(t),
        start, end
      });
    }
    return tokens;
  }

  private splitSents(text: string): Array<{start:number; end:number}> {
    const spans: Array<{start:number; end:number}> = [];
    const rx = /[.!?]+|\n+/g;
    let last = 0; let m: RegExpExecArray | null;
    while ((m = rx.exec(text)) !== null) {
      const end = m.index + m[0].length;
      const slice = text.slice(last, end).trim();
      if (slice) spans.push({ start: last, end });
      last = end;
    }
    if (last < text.length) {
      const slice = text.slice(last).trim();
      if (slice) spans.push({ start: last, end: text.length });
    }
    return spans.length ? spans : [{ start: 0, end: text.length }];
  }

  private extractEntities(text: string): SpacyEntity[] {
    const ents: SpacyEntity[] = [];
    let m: RegExpExecArray | null;
    const rx = this.entityPatterns.PERSON;
    while ((m = rx.exec(text)) !== null) {
      ents.push({ text: m[0], label: 'PERSON', start: m.index, end: m.index + m[0].length });
    }
    return ents;
  }

  private classifyNegationType(w: string): string {
    const contr = ["don't","won't","can't","shouldn't","wouldn't","couldn't","haven't","hasn't","hadn't","isn't","aren't","wasn't","weren't"];
    if (contr.includes(w)) return 'contraction';
    if (['not','no'].includes(w)) return 'simple';
    if (['never','nothing','nobody','nowhere'].includes(w)) return 'absolute';
    return 'other';
  }

  private findNegationDeps(text: string, toks: SpacyToken[], sents: Array<{start:number;end:number}>) {
    // Build dependency-like links: neg trigger -> nearest verb head (within window)
    const deps: Array<{ rel: string; head: number; token: number; start: number; end: number }> = [];
    const subtreeSpan: Record<number, { start: number; end: number }> = {};

    const negWordSet = new Set([
      'not','dont','don\'t','wont','won\'t','cant','can\'t','shouldnt','shouldn\'t','wouldnt','wouldn\'t',
      'couldnt','couldn\'t','havent','haven\'t','hasnt','hasn\'t','hadnt','hadn\'t','isnt','isn\'t','arent','aren\'t',
      'wasnt','wasn\'t','werent','weren\'t','never','no','nothing','nobody','nowhere'
    ]);

    for (let i = 0; i < toks.length; i++) {
      const t = toks[i];
      const norm = t.text.toLowerCase();
      if (!negWordSet.has(norm)) continue;

      // find nearest verb/adjective to the right, then left (window 5)
      let head = -1;
      for (let j = i+1; j <= Math.min(i+5, toks.length-1); j++) {
        if (toks[j].pos === 'VERB' || toks[j].pos === 'AUX' || toks[j].pos === 'ADJ') { head = j; break; }
      }
      if (head === -1) {
        for (let j = i-1; j >= Math.max(0, i-5); j--) {
          if (toks[j].pos === 'VERB' || toks[j].pos === 'AUX' || toks[j].pos === 'ADJ') { head = j; break; }
        }
      }
      if (head === -1) head = i; // fallback to self

      // scope: use sentence containing the head
      const headChar = toks[head].start ?? 0;
      const sent = sents.find(s => headChar >= s.start && headChar <= s.end) || { start: 0, end: text.length };
      deps.push({ rel: 'neg', head, token: i, start: sent.start, end: sent.end });
      if (!subtreeSpan[head]) subtreeSpan[head] = { start: sent.start, end: sent.end };
    }

    return { deps, subtreeSpan };
  }

  private detectNegation(text: string): NegationAnalysis {
    const negations: any[] = [];
    const lower = text.toLowerCase();
    // literal words
    let m: RegExpExecArray | null;
    const rx = this.entityPatterns.NEGATION;
    while ((m = rx.exec(lower)) !== null) {
      const word = m[0];
      const pos = m.index;
      negations.push({ negationWord: word, position: pos, scope: this.scopeWindow(text, pos), type: this.classifyNegationType(word) });
    }
    // json patterns
    for (const r of this.negationPatterns) {
      try { if (r.test(text)) negations.push({ negationWord: r.source, position: -1, scope: 'json', type: 'complex_pattern' }); } catch {}
    }
    return { hasNegation: negations.length > 0, negations, negationCount: negations.length };
  }

  private detectSarcasm(text: string): SarcasmAnalysis {
    const hits: any[] = [];
    for (const { rx, conf } of this.sarcasmPatterns) {
      const m = rx.exec(text);
      if (m) hits.push({ pattern: m[0], position: m.index, type: 'linguistic_pattern', confidence: conf });
    }
    // punctuation cues
    const punct = /[!]{2,}|[?]{2,}|[.]{3,}/g; let mm: RegExpExecArray | null;
    while ((mm = punct.exec(text)) !== null) hits.push({ pattern: mm[0], position: mm.index, type: 'punctuation_pattern', confidence: 0.4 });

    const score = hits.length ? Math.min(1, hits.reduce((s, h) => s + (h.confidence || 0.4), 0) / hits.length) : 0;
    return { hasSarcasm: hits.length > 0, sarcasmIndicators: hits, sarcasmScore: score, overallSarcasmProbability: Math.min(hits.length * 0.3, 1) };
  }

  private detectIntensity(text: string): IntensityAnalysis {
    const words: any[] = [];
    const rx = this.entityPatterns.INTENSITY;
    let m: RegExpExecArray | null;
    while ((m = rx.exec(text)) !== null) {
      const w = m[0].toLowerCase();
      let level = 'moderate'; let mult = 1.0;
      if (['extremely','incredibly','totally','completely','absolutely','utterly'].includes(w)) { level = 'high'; mult = 1.5; }
      else if (['very','really','quite'].includes(w)) { level = 'moderate-high'; mult = 1.2; }
      else if (['somewhat','a little','slightly','barely','hardly'].includes(w)) { level = 'low'; mult = 0.7; }
      words.push({ word: w, position: m.index, level, multiplier: mult, scope: this.peekNext(text, m.index) });
    }
    // JSON modifiers
    for (const pat of this.intensityPatterns) {
      try { if (pat.rx.test(text)) words.push({ word: pat.rx.source, position: -1, level: pat.level || 'custom', multiplier: pat.mult, scope: 'json' }); } catch {}
    }
    const overall = words.length ? words.reduce((s: number, w: any) => s + (w.multiplier || 1), 0) / words.length : 1.0;
    const dom = (() => { const m: Record<string,number> = {}; words.forEach((w:any)=>m[w.level]=(m[w.level]||0)+1); return Object.entries(m).sort((a,b)=>b[1]-a[1])[0]?.[0] || 'neutral'; })();
    return { hasIntensity: words.length>0, intensityWords: words, intensityCount: words.length, overallIntensity: overall, dominantLevel: dom };
  }

  private detectEdges(text: string): string[] {
    const hits: string[] = [];
    for (const { rx, cat } of this.edgePatterns) { try { if (rx.test(text)) hits.push(cat); } catch {} }
    return hits;
  }

  private classifyContext(text: string): ContextClassification {
    const contexts: any[] = [];
    const lower = text.toLowerCase();
    const confs = this.contextClassifiers?.contexts || [];
    for (const ctx of confs) {
      let score = 0; const matched: string[] = [];
      const keys = ctx.keywords || ctx.toneCues || [];
      const phrases = ctx.phrases || [];
      const w = ctx.weight || 1.0;
      keys.forEach((k: string) => { if (lower.includes(String(k).toLowerCase())) { score += w; matched.push(k); } });
      phrases.forEach((p: string) => { if (lower.includes(String(p).toLowerCase())) { score += w * 1.5; matched.push(p); } });
      if (score > 0) contexts.push({ context: ctx.context || ctx.name, score, confidence: Math.min(score/3.0, 1.0), matchedPatterns: matched, description: ctx.description });
    }
    contexts.sort((a,b)=>b.score-a.score);
    return { primaryContext: contexts[0]?.context || 'general', secondaryContext: contexts[1]?.context || null, allContexts: contexts, confidence: contexts[0]?.confidence || 0.1 };
  }

  // ---------- tiny utils ----------
  private scopeWindow(text: string, pos: number): string {
    const after = text.slice(pos);
    const m = after.match(/^.{0,160}?(?=[\.!\?\n]|$)/);
    return (m?.[0] || after.slice(0,160)).trim();
  }
  private peekNext(text: string, pos: number): string {
    const rest = text.substring(pos).trimStart();
    const m = rest.match(/^\S+\s+(\S+)/);
    return m?.[1] || '';
  }

  // -----------------------------
  // Public API
  // -----------------------------

  /**
   * Main entry used by toneAnalysis.ts (spacyLiteSync).
   * Returns compact result + extra fields (tokens/sents/deps/subtreeSpan).
   */
  process(text: string, opts: any = {}): SpacyProcessResult {
    const start = performance.now();
    const original = this.clamp(text);

    // LRU (by mode + text)
    const key = `${this.mode}:${original}`;
    const cached = this._lruGet(this._analysisLRU, key);
    if (cached && cached.processingTimeMs < this.budgets.maxMillis) {
      return this._toProcessResult(cached);
    }

    // Tokenize first (cheap)
    const tokens = this.splitTokens(original);
    const tooMany = tokens.length > this.budgets.maxTokens;

    // Minimal always-on
    const sents = this.splitSents(original);
    const entities = this.extractEntities(original);
    const contextClassification = this.classifyContext(original);

    // Negation deps + spans
    const { deps, subtreeSpan } = this.findNegationDeps(original, tokens, sents);

    // Medium/Heavy (gated)
    const negationAnalysis = this.detectNegation(original);
    const sarcasmAnalysis  = (!tooMany ? this.detectSarcasm(original) : { hasSarcasm:false, sarcasmIndicators:[], sarcasmScore:0, overallSarcasmProbability:0 });
    const intensityAnalysis= (!tooMany ? this.detectIntensity(original) : { hasIntensity:false, intensityWords:[], intensityCount:0, overallIntensity:1, dominantLevel:'neutral' });
    const edgeHits = this.detectEdges(original);

    const processingTime = performance.now() - start;

    const full: SpacyFullAnalysis = {
      originalText: original,
      tokens,
      entities,
      dependencies: deps.map(d => ({ text: original.slice(d.start, d.end), relation: d.rel, start: d.start, end: d.end, head: d.head, token: d.token })),
      contextClassification,
      negationAnalysis,
      sarcasmAnalysis,
      intensityAnalysis,
      _phraseEdgeHits: edgeHits,
      processingTimeMs: processingTime,
      timestamp: new Date().toISOString(),
      sents,
      deps,
      subtreeSpan
    };

    this._lruSet(this._analysisLRU, key, full);
    return this._toProcessResult(full);
  }

  private _toProcessResult(diag: SpacyFullAnalysis): SpacyProcessResult {
    const contextTop = diag.contextClassification.allContexts[0];
    const context = { label: diag.contextClassification.primaryContext, score: contextTop?.confidence || 0.1 };

    const negScore = Math.min(1, 0.3 + 0.1 * (diag.negationAnalysis.negationCount || 0));
    const sarcScore = diag.sarcasmAnalysis.sarcasmScore || 0;
    const intensityScore = (() => {
      const capsRatio = (() => {
        const caps = (diag.originalText.match(/[A-Z]/g) || []).length;
        const letters = (diag.originalText.match(/[A-Za-z]/g) || []).length || 1;
        return caps / letters;
      })();
      return Math.max(0, Math.min(1,
        (diag.intensityAnalysis.intensityCount || 0) * 0.08 +
        capsRatio * 0.8
      ));
    })();

    return {
      context,
      entities: diag.entities,
      negation: { present: diag.negationAnalysis.hasNegation, score: diag.negationAnalysis.hasNegation ? negScore : 0 },
      sarcasm: { present: diag.sarcasmAnalysis.hasSarcasm, score: sarcScore },
      intensity: { score: intensityScore },
      phraseEdges: { hits: diag._phraseEdgeHits },
      features: { featureCount: diag.tokens.length },

      // extras expected by spacyLiteSync
      tokens: diag.tokens,
      sents: diag.sents,
      deps: diag.deps,
      subtreeSpan: diag.subtreeSpan
    };
  }

  /** Rich analysis (sync wrapper) */
  processTextSync(text: string, options: any = {}): SpacyFullAnalysis {
    // Delegate to process() and backfill fields to match type strictly
    const r = this.process(text, options) as any;
    return {
      originalText: text,
      tokens: r.tokens || [],
      entities: r.entities || [],
      dependencies: (r.deps || []).map((d: any) => ({ text: text.slice(d.start, d.end), relation: d.rel, start: d.start, end: d.end, head: d.head, token: d.token })),
      contextClassification: {
        primaryContext: r.context?.label || 'general',
        secondaryContext: null,
        allContexts: [{ context: r.context?.label || 'general', score: r.context?.score || 0.1, confidence: r.context?.score || 0.1, matchedPatterns: [] }],
        confidence: r.context?.score || 0.1,
      },
      negationAnalysis: { hasNegation: r.negation?.present || false, negations: [], negationCount: r.negation?.present ? 1 : 0 },
      sarcasmAnalysis: { hasSarcasm: r.sarcasm?.present || false, sarcasmIndicators: [], sarcasmScore: r.sarcasm?.score || 0, overallSarcasmProbability: r.sarcasm?.score || 0 },
      intensityAnalysis: { hasIntensity: (r.intensity?.score || 0) > 0, intensityWords: [], intensityCount: 0, overallIntensity: r.intensity?.score || 1, dominantLevel: 'neutral' },
      _phraseEdgeHits: r.phraseEdges?.hits || [],
      processingTimeMs: 0,
      timestamp: new Date().toISOString(),
      sents: r.sents || [],
      deps: r.deps || [],
      subtreeSpan: r.subtreeSpan || {}
    };
  }

  async processText(text: string, options: any = {}): Promise<SpacyFullAnalysis> {
    return this.processTextSync(text, options);
  }

  async analyze(text: string, patterns?: any[]): Promise<SpacyFullAnalysis> {
    return this.processText(text, { patterns });
  }

  // Minimal helper doc (local; mirrors serverless bridge shape but without network)
  helperDoc(text: string, fields: SpacyHelperField[] = ['tokens','sents','neg_scopes','pos_counts']): SpacyHelperDoc {
    const original = this.clamp(text);
    const key = fields.sort().join(',') + '::' + original;
    const cached = this._lruGet(this._helperLRU, key);
    if (cached) return cached;

    const out: SpacyHelperDoc = {};
    const tokens = this.splitTokens(original);
    const sents = this.splitSents(original);

    if (fields.includes('tokens')) {
      out.tokens = tokens.map(t => ({ text: t.text, lemma: t.lemma, pos: t.pos, i: t.index }));
    }
    if (fields.includes('sents')) {
      out.sents = sents;
    }
    if (fields.includes('neg_scopes')) {
      const { deps, subtreeSpan } = this.findNegationDeps(original, tokens, sents);
      out.neg_scopes = deps.filter(d => d.rel==='neg').map(d => ({ start: d.start, end: d.end, trigger: tokens[d.token]?.text || 'not' }));
    }
    if (fields.includes('pos_counts')) {
      const pc: Record<string, number> = { NOUN:0, VERB:0, ADJ:0, ADV:0, PRON:0 };
      tokens.forEach(t => { if (pc[t.pos] !== undefined) pc[t.pos]++; });
      out.pos_counts = pc;
    }
    if (fields.includes('entities')) {
      out.entities = this.extractEntities(original);
    }

    this._lruSet(this._helperLRU, key, out);
    return out;
  }

  // Status & health
  getProcessingSummary(): any {
    return {
      contexts: this.contextClassifiers?.contexts?.length || 0,
      negation_patterns: this.negationPatterns.length,
      sarcasm_patterns: this.sarcasmPatterns.length,
      intensity_modifiers: this.intensityPatterns.length,
      edges: this.edgePatterns.length
    };
  }

  getServiceStatus(): any {
    return {
      status: 'operational',
      dataFilesLoaded: {
        context_classifiers: !!this.contextClassifiers,
        negation_indicators: !!this.negationIndicators,
        sarcasm_indicators: !!this.sarcasmIndicators,
        intensity_modifiers: !!this.intensityModifiers,
        phrase_edges: !!this.phraseEdges
      },
      summary: this.getProcessingSummary()
    };
  }

  async healthCheck(): Promise<boolean> { logger.info('SpaCy (local helper) health: OK'); return true; }

  // Simple numeric vector for downstream heuristics (kept from prior version)
  async embed(text: string): Promise<number[]> {
    try {
      const analysis = this.process(text);
      const tokens = analysis.tokens || [];
      const features: number[] = [];
      features.push(tokens.length / 100);
      features.push((tokens.filter(t=>t.is_alpha).length) / Math.max(1, tokens.length));
      features.push((tokens.filter(t=>t.is_stop).length) / Math.max(1, tokens.length));
      features.push((tokens.filter(t=>t.pos==='NOUN').length) / Math.max(1, tokens.length));
      features.push((tokens.filter(t=>t.pos==='VERB').length) / Math.max(1, tokens.length));
      features.push((tokens.filter(t=>t.pos==='ADJ').length) / Math.max(1, tokens.length));
      features.push((analysis.entities?.length || 0) / Math.max(1, tokens.length));
      const negCount = (analysis.deps || []).filter(d=>d.rel==='neg').length;
      features.push(negCount / Math.max(1, tokens.length));
      features.push(analysis.sarcasm?.score || 0);
      features.push(analysis.intensity?.score || 1);
      const contextTypes = ['general','conflict','planning','repair','emotional','professional','personal','urgent','casual','formal'];
      const ctxLabel = analysis.context?.label || 'general';
      contextTypes.forEach(type => features.push(type === ctxLabel ? 1 : 0));
      const lower = text.toLowerCase();
      const emoGroups: Record<string,string[]> = {
        joy:['happy','joy','excited','pleased','delighted'],
        anger:['angry','mad','furious','annoyed','frustrated'],
        sadness:['sad','hurt','disappointed','upset','down'],
        fear:['scared','afraid','worried','anxious','nervous'],
        trust:['trust','confident','secure','safe','reliable'],
        surprise:['surprised','shocked','amazed','astonished'],
        disgust:['disgusted','revolted','repulsed','sickened'],
        anticipation:['excited','eager','hopeful','expecting'],
        neutral:['okay','fine','normal','regular'],
        mixed:['conflicted','confused','uncertain','ambivalent']
      };
      Object.values(emoGroups).forEach(words => {
        const c = words.reduce((s,w)=>s+(lower.includes(w)?1:0),0);
        features.push(c / Math.max(1, words.length));
      });
      while (features.length < 30) features.push(0);
      return features.slice(0,30);
    } catch (e) {
      logger.error('Embedding generation failed', e);
      return new Array(30).fill(0);
    }
  }

  async analyzeEnhanced(text: string, options: any = {}): Promise<SpacyFullAnalysis & { embeddings: number[] }> {
    const analysis = await this.processText(text, options);
    const embeddings = await this.embed(text);
    return { ...analysis, embeddings };
  }
}

// Singleton instance
export const spacyClient = new SpacyService();
export { SpacyService as SpacyClient };
export default spacyClient;
