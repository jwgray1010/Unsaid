// api/_lib/services/spacyClient.ts
import { logger } from '../logger';
import { readFileSync } from 'fs';
import { join, resolve } from 'path';
import { env } from 'process';

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
}

export interface SpacyEntity {
  text: string;
  label: string;
  start: number;
  end: number;
}

export interface SpacyDependency {
  text: string;
  relation: string;
  start: number;
  end: number;
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
    position: number;
    scope: string;
    type: string;
  }>;
  negationCount: number;
}

export interface SarcasmAnalysis {
  hasSarcasm: boolean;
  sarcasmIndicators: Array<{
    pattern: string;
    position: number;
    type: string;
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
    level: string;
    multiplier: number;
    scope: string;
  }>;
  intensityCount: number;
  overallIntensity: number;
  dominantLevel: string;
}

export interface SpacyProcessResult {
  context: {
    label: string;
    score: number;
  };
  entities: SpacyEntity[];
  negation: {
    present: boolean;
    score: number;
  };
  sarcasm: {
    present: boolean;
    score: number;
  };
  intensity: {
    score: number;
  };
  phraseEdges: {
    hits: string[];
  };
  features: {
    featureCount: number;
  };
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
}

class SpacyService {
  private dataPath: string;
  private thresholds: {
    toneDetection: number;
    rewriteScore: number;
    confidenceMinimum: number;
  };
  private scoringWeights: {
    exactPattern: number;
    triggerWord: number;
    contextMatch: number;
    intensityBoost: number;
    negationPenalty: number;
    sarcasmPenalty: number;
  };
  private entityPatterns: {
    PERSON: RegExp;
    EMOTION: RegExp;
    INTENSITY: RegExp;
    NEGATION: RegExp;
  };
  private dependencyPatterns: {
    subject: RegExp;
  };
  private contextClassifiers: any;
  private negationIndicators: any;
  private sarcasmIndicators: any;
  private intensityModifiers: any;
  private phraseEdges: any;
  private semanticThesaurus: any;

  constructor(opts: any = {}) {
    this.dataPath = opts.dataPath || resolve(__dirname, '../../../data');
    this.thresholds = Object.assign({
      toneDetection: 0.15,
      rewriteScore: 0.45,
      confidenceMinimum: 0.25
    }, opts.thresholds || {});

    this.scoringWeights = Object.assign({
      exactPattern: 3.0,
      triggerWord: 1.0,
      contextMatch: 1.5,
      intensityBoost: 1.2,
      negationPenalty: 2.0,
      sarcasmPenalty: 2.5
    }, opts.scoringWeights || {});

    // Regex bundles
    this.entityPatterns = {
      PERSON: /\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\b/g,
      EMOTION: /\b(happy|sad|angry|excited|worried|hopeful|frustrated|anxious|calm|upset|pleased|disappointed|grateful|hurt|confused|relieved|stressed|content|annoyed|delighted|concerned)\b/gi,
      INTENSITY: /\b(very|extremely|really|quite|somewhat|a little|slightly|incredibly|totally|completely|barely|hardly|absolutely|utterly)\b/gi,
      NEGATION: /\b(not|don\'t|won\'t|can\'t|shouldn\'t|wouldn\'t|couldn\'t|haven\'t|hasn\'t|hadn\'t|isn\'t|aren\'t|wasn\'t|weren\'t|never|no|none|nothing|nobody|nowhere)\b/gi
    };

    this.dependencyPatterns = {
      subject: /\b(I|you|he|she|we|they)\s+(?:am|are|is|was|were|have|has|had|do|does|did|will|would|could|should|might|may)\b/gi
    };

    this._loadAll();
  }

  private _readJsonSafe(file: string, fb: any = null): any {
    // Try multiple possible data paths like dataLoader does
    const possiblePaths = [
      join(this.dataPath, file),
      join(resolve(__dirname, '../../../data'), file),
      join(resolve(__dirname, '../../../../data'), file),
      join(resolve(process.cwd(), 'data'), file),
      join(resolve('/vercel/path0', 'data'), file),
      join(resolve(env.LAMBDA_TASK_ROOT || process.cwd(), 'data'), file)
    ];

    for (const filepath of possiblePaths) {
      try {
        const content = readFileSync(filepath, 'utf8');
        logger.info(`Successfully loaded ${file} from ${filepath} (${content.length} chars)`);
        return JSON.parse(content);
      } catch (e: any) {
        // Continue to next path
        logger.debug(`Failed to load ${file} from ${filepath}: ${e.message}`);
      }
    }

    logger.warn(`[SpacyService] Could not load ${file} from any path, using fallback`);
    return fb;
  }

  private _loadAll(): void {
    // Align file names with the other modules
    this.contextClassifiers = this._readJsonSafe('context_classifier.json', { contexts: [] });
    this.negationIndicators = this._readJsonSafe('negation_indicators.json', { negation_indicators: [] });
    this.sarcasmIndicators = this._readJsonSafe('sarcasm_indicators.json', { sarcasm_indicators: [] });
    this.intensityModifiers = this._readJsonSafe('intensity_modifiers.json', { modifiers: [] });
    this.phraseEdges = this._readJsonSafe('phrase_edges.json', { edges: [] });
    this.semanticThesaurus = this._readJsonSafe('semantic_thesaurus.json', {});
  }

  // ===================================
  // Public: compact .process() for orchestrators
  // ===================================
  process(text: string, opts: any = {}): SpacyProcessResult {
    const diag = this.processTextSync(text, opts);

    // Map to the compact shape used by our orchestrators
    const contextTop = diag.contextClassification.allContexts[0];
    const context = {
      label: diag.contextClassification.primaryContext,
      score: contextTop?.confidence || 0.1
    };

    const negScore = Math.min(1, 0.3 + 0.1 * (diag.negationAnalysis.negationCount || 0));
    const sarcScore = diag.sarcasmAnalysis.sarcasmScore || 0;
    const intensityScore = Math.max(
      0,
      Math.min(
        1,
        // punctuation + caps + lengthened + JSON modifiers (rough composite)
        (diag.intensityAnalysis.intensityCount || 0) * 0.08 +
        (diag.tokens.filter(t => /[A-Z]/.test(t.text)).length / Math.max(1, diag.tokens.length)) * 0.8
      )
    );

    // Phrase edge hits
    const edgeHits = diag._phraseEdgeHits || [];

    return {
      context,
      entities: diag.entities,
      negation: { present: diag.negationAnalysis.hasNegation, score: diag.negationAnalysis.hasNegation ? negScore : 0 },
      sarcasm: { present: diag.sarcasmAnalysis.hasSarcasm, score: sarcScore },
      intensity: { score: intensityScore },
      phraseEdges: { hits: edgeHits },
      features: { featureCount: diag.tokens.length }
    };
  }

  // ===================================
  // Rich pipeline (sync) used by .process
  // ===================================
  processTextSync(text: string, options: any = {}): SpacyFullAnalysis {
    const startTime = Date.now();

    const tokens = this.tokenize(text);
    const entities = this.extractNamedEntities(text);
    const dependencies = this.parseDependencies(text);
    const contextClassification = this.classifyContext(text, tokens);
    const negationAnalysis = this.detectNegation(text, tokens);
    const sarcasmAnalysis = this.detectSarcasm(text, tokens);
    const intensityAnalysis = this.detectIntensity(text, tokens);
    const _phraseEdgeHits = this.detectPhraseEdges(text);

    const processingTime = Date.now() - startTime;
    return {
      originalText: text,
      tokens,
      entities,
      dependencies,
      contextClassification,
      negationAnalysis,
      sarcasmAnalysis,
      intensityAnalysis,
      _phraseEdgeHits,
      processingTimeMs: processingTime,
      timestamp: new Date().toISOString()
    };
  }

  // ===================================
  // Original async facade retained for compatibility
  // ===================================
  async processText(text: string, options: any = {}): Promise<SpacyFullAnalysis> { 
    return this.processTextSync(text, options); 
  }

  // Legacy analyze method for compatibility
  async analyze(text: string, patterns?: any[]): Promise<SpacyFullAnalysis> {
    return this.processText(text, { patterns });
  }

  // -------- Context Classification --------
  classifyContext(text: string, tokens: SpacyToken[]): ContextClassification {
    const contexts: any[] = [];
    const lowerText = text.toLowerCase();
    const confs = this.contextClassifiers?.contexts || [];

    for (const ctx of confs) {
      let score = 0;
      const matched: string[] = [];
      const keys = ctx.keywords || ctx.toneCues || [];
      const phrases = ctx.phrases || [];
      const w = ctx.weight || 1.0;
      
      keys.forEach((k: string) => {
        if (lowerText.includes(k.toLowerCase())) { 
          score += w; 
          matched.push(k); 
        }
      });
      
      phrases.forEach((p: string) => {
        if (lowerText.includes(p.toLowerCase())) { 
          score += w * 1.5; 
          matched.push(p); 
        }
      });
      
      if (score > 0) {
        contexts.push({
          context: ctx.context || ctx.name,
          score,
          confidence: Math.min(score / 3.0, 1.0),
          matchedPatterns: matched,
          description: ctx.description
        });
      }
    }

    contexts.sort((a, b) => b.score - a.score);
    return {
      primaryContext: contexts[0]?.context || 'general',
      secondaryContext: contexts[1]?.context || null,
      allContexts: contexts,
      confidence: contexts[0]?.confidence || 0.1
    };
  }

  // -------- Negation --------
  detectNegation(text: string, tokens: SpacyToken[]): NegationAnalysis {
    const negations: any[] = [];
    const lower = text.toLowerCase();
    const rx = this.entityPatterns.NEGATION;
    let m: RegExpExecArray | null;
    
    while ((m = rx.exec(lower)) !== null) {
      const word = m[0];
      const pos = m.index;
      negations.push({
        negationWord: word,
        position: pos,
        scope: this.findNegationScope(text, pos),
        type: this.classifyNegationType(word)
      });
    }

    // JSON patterns
    const pats = this.negationIndicators?.negation_indicators || this.negationIndicators?.patterns || [];
    pats.forEach((p: any) => {
      try {
        const r = new RegExp(p.pattern || p, 'i');
        if (r.test(text)) {
          negations.push({
            negationWord: p.id || p,
            position: -1,
            scope: 'json',
            type: 'complex_pattern'
          });
        }
      } catch {
        // ignore regex errors
      }
    });

    return {
      hasNegation: negations.length > 0,
      negations,
      negationCount: negations.length
    };
  }

  // -------- Sarcasm --------
  detectSarcasm(text: string, tokens: SpacyToken[]): SarcasmAnalysis {
    const hits: any[] = [];
    const base = [
      /oh\s+(?:great|wonderful|fantastic|perfect|brilliant)/gi,
      /yeah\s+(?:right|sure|ok)/gi,
      /(?:sure|fine|whatever)(?:\s*[.!]){2,}/gi,
      /\b(?:obviously|clearly|definitely)\b.*\?/gi
    ];
    
    base.forEach(rx => {
      let m: RegExpExecArray | null;
      while ((m = rx.exec(text)) !== null) {
        hits.push({
          pattern: m[0],
          position: m.index,
          type: 'linguistic_pattern',
          confidence: 0.7
        });
      }
    });

    const cfg = this.sarcasmIndicators?.sarcasm_indicators || this.sarcasmIndicators?.patterns || [];
    cfg.forEach((entry: any) => {
      const rx = entry.pattern ? new RegExp(entry.pattern, 'i') : null;
      try {
        if (rx && rx.test(text)) {
          hits.push({
            pattern: entry.id || entry.pattern,
            position: -1,
            type: 'json_indicator',
            confidence: entry.impact ? Math.min(1, Math.abs(entry.impact)) : 0.6
          });
        }
      } catch {
        // ignore regex errors
      }
    });

    // punctuation
    const punct = /[!]{2,}|[?]{2,}|[.]{3,}/g;
    let m: RegExpExecArray | null;
    while ((m = punct.exec(text)) !== null) {
      hits.push({
        pattern: m[0],
        position: m.index,
        type: 'punctuation_pattern',
        confidence: 0.4
      });
    }

    const score = hits.length ? Math.min(1, hits.reduce((s, h) => s + (h.confidence || 0.4), 0) / Math.max(1, hits.length)) : 0;
    return {
      hasSarcasm: hits.length > 0,
      sarcasmIndicators: hits,
      sarcasmScore: score,
      overallSarcasmProbability: Math.min(hits.length * 0.3, 1)
    };
  }

  // -------- Intensity --------
  detectIntensity(text: string, tokens: SpacyToken[]): IntensityAnalysis {
    const words: any[] = [];
    const lower = text.toLowerCase();
    let m: RegExpExecArray | null;
    const rx = this.entityPatterns.INTENSITY;
    
    while ((m = rx.exec(text)) !== null) {
      const w = m[0].toLowerCase();
      const pos = m.index;
      let level = 'moderate';
      let mult = 1.0;
      
      if (['extremely', 'incredibly', 'totally', 'completely', 'absolutely', 'utterly'].includes(w)) {
        level = 'high';
        mult = 1.5;
      } else if (['very', 'really', 'quite'].includes(w)) {
        level = 'moderate-high';
        mult = 1.2;
      } else if (['somewhat', 'a little', 'slightly', 'barely', 'hardly'].includes(w)) {
        level = 'low';
        mult = 0.7;
      }
      
      words.push({
        word: w,
        position: pos,
        level,
        multiplier: mult,
        scope: this.findIntensityScope(text, pos)
      });
    }

    // JSON modifiers (two common schemas supported)
    const mods = this.intensityModifiers?.modifiers || this.intensityModifiers || [];
    if (Array.isArray(mods)) {
      mods.forEach((mod: any) => {
        try {
          const r = new RegExp(mod.pattern, 'i');
          if (r.test(text)) {
            words.push({
              word: mod.label || 'modifier',
              position: -1,
              level: mod.class || 'custom',
              multiplier: mod.multiplier || 1.0,
              scope: 'json'
            });
          }
        } catch {
          // ignore regex errors
        }
      });
    } else if (typeof mods === 'object') {
      Object.entries(mods).forEach(([lvl, dict]: [string, any]) => {
        Object.entries(dict || {}).forEach(([k, v]: [string, any]) => {
          if (lower.includes(k.toLowerCase())) {
            words.push({
              word: k,
              position: lower.indexOf(k.toLowerCase()),
              level: lvl,
              multiplier: v,
              scope: 'json'
            });
          }
        });
      });
    }

    return {
      hasIntensity: words.length > 0,
      intensityWords: words,
      intensityCount: words.length,
      overallIntensity: this.calculateOverallIntensity(words),
      dominantLevel: this.getDominantIntensityLevel(words)
    };
  }

  // -------- Phrase edges --------
  detectPhraseEdges(text: string): string[] {
    const hits: string[] = [];
    const edges = (this.phraseEdges?.edges) || [];
    edges.forEach((e: any) => {
      if (!e?.pattern) return;
      try {
        const r = new RegExp(e.pattern, 'i');
        if (r.test(text)) hits.push(e.category || 'edge');
      } catch {
        // ignore regex errors
      }
    });
    return hits;
  }

  // -------- Utility NLP --------
  simplePOSTag(word: string): string {
    const w = word.toLowerCase();
    const pron = ['i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them'];
    const verbs = ['am', 'is', 'are', 'was', 'were', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should'];
    
    if (pron.includes(w)) return 'PRON';
    if (verbs.includes(w)) return 'VERB';
    if (/^[A-Z]/.test(word)) return 'PROPN';
    if (/ing$/.test(w)) return 'VERB';
    if (/ed$/.test(w)) return 'VERB';
    if (/ly$/.test(w)) return 'ADV';
    return 'NOUN';
  }

  basicLemmatize(word: string): string {
    const w = word.toLowerCase();
    if (w.endsWith('ing')) return w.slice(0, -3);
    if (w.endsWith('ed')) return w.slice(0, -2);
    if (w.endsWith('s') && w.length > 3) return w.slice(0, -1);
    return w;
  }

  tokenize(text: string): SpacyToken[] {
    return text.split(/\s+/).filter(t => t.length > 0).map((t, i) => ({
      text: t,
      index: i,
      pos: this.simplePOSTag(t),
      lemma: this.basicLemmatize(t),
      is_alpha: /^[a-zA-Z]+$/.test(t),
      is_stop: this.isStopWord(t),
      is_punct: /^[^\w\s]+$/.test(t)
    }));
  }

  extractNamedEntities(text: string): SpacyEntity[] {
    const ents: SpacyEntity[] = [];
    let m: RegExpExecArray | null;
    const rx = this.entityPatterns.PERSON;
    while ((m = rx.exec(text)) !== null) {
      ents.push({
        text: m[0],
        label: 'PERSON',
        start: m.index,
        end: m.index + m[0].length
      });
    }
    return ents;
  }

  parseDependencies(text: string): SpacyDependency[] {
    const deps: SpacyDependency[] = [];
    let m: RegExpExecArray | null;
    const rx = this.dependencyPatterns.subject;
    while ((m = rx.exec(text)) !== null) {
      deps.push({
        text: m[0],
        relation: 'subject',
        start: m.index,
        end: m.index + m[0].length
      });
    }
    return deps;
  }

  findNegationScope(text: string, pos: number): string {
    return text.substring(pos, pos + 20).trim();
  }

  findIntensityScope(text: string, pos: number): string {
    const rest = text.substring(pos);
    const next = rest.split(/\s+/)[1];
    return next || '';
  }

  classifyNegationType(w: string): string {
    const contr = ["don't", "won't", "can't", "shouldn't", "wouldn't", "couldn't", "haven't", "hasn't", "hadn't", "isn't", "aren't", "wasn't", "weren't"];
    if (contr.includes(w)) return 'contraction';
    if (['not', 'no'].includes(w)) return 'simple';
    if (['never', 'nothing', 'nobody', 'nowhere'].includes(w)) return 'absolute';
    return 'other';
  }

  calculateOverallIntensity(words: any[]): number {
    if (!words.length) return 1.0;
    const total = words.reduce((s, w) => s + (w.multiplier || 1), 0);
    return total / words.length;
  }

  getDominantIntensityLevel(words: any[]): string {
    if (!words.length) return 'neutral';
    const map: Record<string, number> = {};
    words.forEach(w => {
      map[w.level] = (map[w.level] || 0) + 1;
    });
    return Object.entries(map).sort((a, b) => b[1] - a[1])[0][0];
  }

  private isStopWord(word: string): boolean {
    const stopWords = ['the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by'];
    return stopWords.includes(word.toLowerCase());
  }

  // -------- Status helpers --------
  getProcessingSummary(): any {
    return {
      contexts: this.contextClassifiers?.contexts?.length || 0,
      negation_patterns: (this.negationIndicators?.negation_indicators || this.negationIndicators?.patterns || []).length,
      sarcasm_patterns: (this.sarcasmIndicators?.sarcasm_indicators || this.sarcasmIndicators?.patterns || []).length,
      intensity_modifiers: Array.isArray(this.intensityModifiers?.modifiers) ? this.intensityModifiers.modifiers.length : Object.keys(this.intensityModifiers || {}).length,
      edges: (this.phraseEdges?.edges || []).length
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

  async healthCheck(): Promise<boolean> {
    logger.info('SpaCy health check: OK');
    return true;
  }

  // Embedding method for semantic similarity
  async embed(text: string): Promise<number[]> {
    try {
      // For now, create a simple embedding based on linguistic features
      // In production, this would call an actual embedding model
      const analysis = this.processTextSync(text);
      const tokens = analysis.tokens;
      
      // Create a feature vector based on spaCy analysis
      const features: number[] = [];
      
      // Lexical features (0-9)
      features.push(tokens.length / 100); // normalized token count
      features.push(tokens.filter(t => t.is_alpha).length / Math.max(1, tokens.length)); // alpha ratio
      features.push(tokens.filter(t => t.is_stop).length / Math.max(1, tokens.length)); // stop word ratio
      features.push(tokens.filter(t => t.pos === 'NOUN').length / Math.max(1, tokens.length)); // noun ratio
      features.push(tokens.filter(t => t.pos === 'VERB').length / Math.max(1, tokens.length)); // verb ratio
      features.push(tokens.filter(t => t.pos === 'ADJ').length / Math.max(1, tokens.length)); // adjective ratio
      features.push(analysis.entities.length / Math.max(1, tokens.length)); // entity density
      features.push(analysis.negationAnalysis.negationCount / Math.max(1, tokens.length)); // negation density
      features.push(analysis.sarcasmAnalysis.sarcasmScore); // sarcasm score
      features.push(analysis.intensityAnalysis.overallIntensity); // intensity score
      
      // Context features (10-19)
      const contexts = analysis.contextClassification.allContexts;
      const contextTypes = ['general', 'conflict', 'planning', 'repair', 'emotional', 'professional', 'personal', 'urgent', 'casual', 'formal'];
      contextTypes.forEach(type => {
        const ctx = contexts.find(c => c.context === type);
        features.push(ctx ? ctx.confidence : 0);
      });
      
      // Emotional features (20-29)
      const emotionWords = {
        joy: ['happy', 'joy', 'excited', 'pleased', 'delighted'],
        anger: ['angry', 'mad', 'furious', 'annoyed', 'frustrated'],
        sadness: ['sad', 'hurt', 'disappointed', 'upset', 'down'],
        fear: ['scared', 'afraid', 'worried', 'anxious', 'nervous'],
        trust: ['trust', 'confident', 'secure', 'safe', 'reliable'],
        surprise: ['surprised', 'shocked', 'amazed', 'astonished'],
        disgust: ['disgusted', 'revolted', 'repulsed', 'sickened'],
        anticipation: ['excited', 'eager', 'hopeful', 'expecting'],
        neutral: ['okay', 'fine', 'normal', 'regular'],
        mixed: ['conflicted', 'confused', 'uncertain', 'ambivalent']
      };
      
      const lowerText = text.toLowerCase();
      Object.values(emotionWords).forEach(words => {
        const count = words.reduce((sum, word) => sum + (lowerText.includes(word) ? 1 : 0), 0);
        features.push(count / Math.max(1, words.length));
      });
      
      // Ensure we have exactly 30 features
      while (features.length < 30) {
        features.push(0);
      }
      
      return features.slice(0, 30);
    } catch (error) {
      logger.error('Embedding generation failed:', error);
      // Return zero vector as fallback
      return new Array(30).fill(0);
    }
  }

  // Enhanced analysis with spaCy integration
  async analyzeEnhanced(text: string, options: any = {}): Promise<SpacyFullAnalysis & { embeddings: number[] }> {
    const analysis = await this.processText(text, options);
    const embeddings = await this.embed(text);
    
    return {
      ...analysis,
      embeddings
    };
  }
}

// Export singleton instance
export const spacyClient = new SpacyService();
export { SpacyService };

// Legacy compatibility exports
export const SpacyClient = SpacyService;
export default spacyClient;
