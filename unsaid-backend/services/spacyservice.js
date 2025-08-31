const fs = require('fs');
const path = require('path');

/**
 * spacy-service.advanced.js
 *
 * Drop-in upgrade for your SpacyService that
 * - aligns JSON filenames with the rest of the stack
 * - exposes a lightweight .process() that returns the exact shape your
 *   Suggestion.advanced.js / tone-analysis.advanced.js orchestrators expect
 * - keeps your richer .processText() for full diagnostics
 */
class SpacyService {
  constructor(opts = {}) {
    this.dataPath = opts.dataPath || path.join(__dirname, 'data');
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

    // Regex bundles (kept from your version, expanded as needed)
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

  // ----------- I/O helpers -----------
  _readJsonSafe(file, fb = null) {
    try {
      const p = path.join(this.dataPath, file);
      return JSON.parse(fs.readFileSync(p, 'utf8'));
    } catch (e) {
      console.warn(`[SpacyService] missing or invalid ${file}: ${e.message}`);
      return fb;
    }
  }

  _loadAll() {
    // Align file names with the other modules
    this.contextClassifiers = this._readJsonSafe('context_classifier.json', { contexts: [] });
    this.negationIndicators  = this._readJsonSafe('negation_indicators.json', { negation_indicators: [] });
    this.sarcasmIndicators   = this._readJsonSafe('sarcasm_indicators.json', { sarcasm_indicators: [] });
    this.intensityModifiers  = this._readJsonSafe('intensity_modifiers.json', { modifiers: [] });
    this.phraseEdges         = this._readJsonSafe('phrase_edges.json', { edges: [] });
    this.semanticThesaurus   = this._readJsonSafe('semantic_thesaurus.json', {});
  }

  // ===================================
  // Public: compact .process() for orchestrators
  // ===================================
  process(text, opts = {}) {
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
      sarcasm:  { present: diag.sarcasmAnalysis.hasSarcasm, score: sarcScore },
      intensity:{ score: intensityScore },
      phraseEdges: { hits: edgeHits },
      features: { featureCount: diag.tokens.length }
    };
  }

  // ===================================
  // Rich pipeline (sync) used by .process
  // ===================================
  processTextSync(text, options = {}) {
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
  async processText(text, options = {}) { return this.processTextSync(text, options); }

  // -------- Context Classification --------
  classifyContext(text, tokens) {
    const contexts = [];
    const lowerText = text.toLowerCase();
    const confs = this.contextClassifiers?.contexts || [];

    for (const ctx of confs) {
      let score = 0; const matched = [];
      const keys = ctx.keywords || ctx.toneCues || [];
      const phrases = ctx.phrases || [];
      const w = ctx.weight || 1.0;
      keys.forEach(k=>{ if (lowerText.includes(k.toLowerCase())) { score += w; matched.push(k); } });
      phrases.forEach(p=>{ if (lowerText.includes(p.toLowerCase())) { score += w*1.5; matched.push(p); } });
      if (score>0) contexts.push({ context: ctx.context || ctx.name, score, confidence: Math.min(score/3.0,1.0), matchedPatterns: matched, description: ctx.description });
    }

    contexts.sort((a,b)=>b.score-a.score);
    return {
      primaryContext: contexts[0]?.context || 'general',
      secondaryContext: contexts[1]?.context || null,
      allContexts: contexts,
      confidence: contexts[0]?.confidence || 0.1
    };
  }

  // -------- Negation --------
  detectNegation(text, tokens) {
    const negations = [];
    const lower = text.toLowerCase();
    const rx = this.entityPatterns.NEGATION;
    let m; while ((m = rx.exec(lower)) !== null) {
      const word = m[0];
      const pos = m.index;
      negations.push({ negationWord: word, position: pos, scope: this.findNegationScope(text, pos), type: this.classifyNegationType(word) });
    }

    // JSON patterns
    const pats = this.negationIndicators?.negation_indicators || this.negationIndicators?.patterns || [];
    pats.forEach(p=>{ try{ const r=new RegExp(p.pattern||p,'i'); if (r.test(text)) negations.push({ negationWord: p.id||p, position: -1, scope: 'json', type: 'complex_pattern' }); }catch{} });

    return { hasNegation: negations.length>0, negations, negationCount: negations.length };
  }

  // -------- Sarcasm --------
  detectSarcasm(text, tokens) {
    const hits = [];
    const base = [
      /oh\s+(?:great|wonderful|fantastic|perfect|brilliant)/gi,
      /yeah\s+(?:right|sure|ok)/gi,
      /(?:sure|fine|whatever)(?:\s*[.!]){2,}/gi,
      /\b(?:obviously|clearly|definitely)\b.*\?/gi
    ];
    base.forEach(rx=>{ let m; while((m=rx.exec(text))!==null){ hits.push({ pattern:m[0], position:m.index, type:'linguistic_pattern', confidence:0.7 }); } });

    const cfg = this.sarcasmIndicators?.sarcasm_indicators || this.sarcasmIndicators?.patterns || [];
    cfg.forEach(entry=>{
      const rx = entry.pattern ? new RegExp(entry.pattern,'i') : null;
      try { if (rx && rx.test(text)) hits.push({ pattern: entry.id||entry.pattern, position:-1, type:'json_indicator', confidence: entry.impact? Math.min(1,Math.abs(entry.impact)):0.6 }); } catch {}
    });

    // punctuation
    const punct = /[!]{2,}|[?]{2,}|[.]{3,}/g; let m; while((m=punct.exec(text))!==null){ hits.push({ pattern:m[0], position:m.index, type:'punctuation_pattern', confidence:0.4 }); }

    const score = hits.length ? Math.min(1, hits.reduce((s,h)=>s+(h.confidence||0.4),0)/Math.max(1,hits.length)) : 0;
    return { hasSarcasm: hits.length>0, sarcasmIndicators: hits, sarcasmScore: score, overallSarcasmProbability: Math.min(hits.length*0.3,1) };
  }

  // -------- Intensity --------
  detectIntensity(text, tokens) {
    const words = []; const lower=text.toLowerCase();
    let m; const rx=this.entityPatterns.INTENSITY; while((m=rx.exec(text))!==null){
      const w=m[0].toLowerCase(); const pos=m.index; let level='moderate'; let mult=1.0;
      if (['extremely','incredibly','totally','completely','absolutely','utterly'].includes(w)) { level='high'; mult=1.5; }
      else if (['very','really','quite'].includes(w)) { level='moderate-high'; mult=1.2; }
      else if (['somewhat','a little','slightly','barely','hardly'].includes(w)) { level='low'; mult=0.7; }
      words.push({ word:w, position:pos, level, multiplier:mult, scope:this.findIntensityScope(text,pos) });
    }

    // JSON modifiers (two common schemas supported)
    const mods = this.intensityModifiers?.modifiers || this.intensityModifiers || [];
    if (Array.isArray(mods)) {
      mods.forEach(mod=>{ try { const r = new RegExp(mod.pattern,'i'); if (r.test(text)) words.push({ word: mod.label||'modifier', position:-1, level: mod.class||'custom', multiplier: mod.multiplier||1.0, scope:'json' }); } catch {} });
    } else if (typeof mods === 'object') {
      Object.entries(mods).forEach(([lvl, dict])=>{
        Object.entries(dict||{}).forEach(([k,v])=>{ if (lower.includes(k.toLowerCase())) words.push({ word:k, position: lower.indexOf(k.toLowerCase()), level:lvl, multiplier:v, scope:'json' }); });
      });
    }

    return {
      hasIntensity: words.length>0,
      intensityWords: words,
      intensityCount: words.length,
      overallIntensity: this.calculateOverallIntensity(words),
      dominantLevel: this.getDominantIntensityLevel(words)
    };
  }

  // -------- Phrase edges --------
  detectPhraseEdges(text){
    const hits=[]; const edges=(this.phraseEdges?.edges)||[];
    edges.forEach(e=>{ if(!e?.pattern) return; try{ const r=new RegExp(e.pattern,'i'); if(r.test(text)) hits.push(e.category||'edge'); }catch{} });
    return hits;
  }

  // -------- Utility NLP --------
  simplePOSTag(word){
    const w=word.toLowerCase(); const pron=['i','you','he','she','it','we','they','me','him','her','us','them'];
    const verbs=['am','is','are','was','were','have','has','had','do','does','did','will','would','could','should'];
    if (pron.includes(w)) return 'PRON'; if (verbs.includes(w)) return 'VERB';
    if (/^[A-Z]/.test(word)) return 'PROPN'; if (/ing$/.test(w)) return 'VERB'; if (/ed$/.test(w)) return 'VERB'; if (/ly$/.test(w)) return 'ADV';
    return 'NOUN';
  }
  basicLemmatize(word){ const w=word.toLowerCase(); if (w.endsWith('ing')) return w.slice(0,-3); if (w.endsWith('ed')) return w.slice(0,-2); if (w.endsWith('s') && w.length>3) return w.slice(0,-1); return w; }
  tokenize(text){ return text.split(/\s+/).filter(t=>t.length>0).map((t,i)=>({ text:t, index:i, pos:this.simplePOSTag(t), lemma:this.basicLemmatize(t) })); }
  extractNamedEntities(text){ const ents=[]; let m; const rx=this.entityPatterns.PERSON; while((m=rx.exec(text))!==null){ ents.push({ text:m[0], label:'PERSON', start:m.index, end:m.index+m[0].length }); } return ents; }
  parseDependencies(text){ const deps=[]; let m; const rx=this.dependencyPatterns.subject; while((m=rx.exec(text))!==null){ deps.push({ text:m[0], relation:'subject', start:m.index, end:m.index+m[0].length }); } return deps; }
  findNegationScope(text,pos){ return text.substring(pos, pos+20).trim(); }
  findIntensityScope(text,pos){ const rest=text.substring(pos); const next=rest.split(/\s+/)[1]; return next||''; }
  classifyNegationType(w){ const contr=["don't","won't","can't","shouldn't","wouldn't","couldn't","haven't","hasn't","hadn't","isn't","aren't","wasn't","weren't"]; if(contr.includes(w)) return 'contraction'; if(['not','no'].includes(w)) return 'simple'; if(['never','nothing','nobody','nowhere'].includes(w)) return 'absolute'; return 'other'; }
  calculateOverallIntensity(words){ if(!words.length) return 1.0; const total=words.reduce((s,w)=>s+(w.multiplier||1),0); return total/words.length; }
  getDominantIntensityLevel(words){ if(!words.length) return 'neutral'; const map={}; words.forEach(w=>{ map[w.level]=(map[w.level]||0)+1; }); return Object.entries(map).sort((a,b)=>b[1]-a[1])[0][0]; }

  // -------- Status helpers --------
  getProcessingSummary(){
    return {
      contexts: this.contextClassifiers?.contexts?.length || 0,
      negation_patterns: (this.negationIndicators?.negation_indicators||this.negationIndicators?.patterns||[]).length,
      sarcasm_patterns: (this.sarcasmIndicators?.sarcasm_indicators||this.sarcasmIndicators?.patterns||[]).length,
      intensity_modifiers: Array.isArray(this.intensityModifiers?.modifiers)? this.intensityModifiers.modifiers.length : Object.keys(this.intensityModifiers||{}).length,
      edges: (this.phraseEdges?.edges||[]).length
    };
  }
  getServiceStatus(){
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

}

module.exports = { SpacyService };
    return {
      status: 'operational',
      dataFilesLoaded: {
        context_classifiers: !!this.contextClassifiers,
        negation_indicators: !!this.negationIndicators,
        sarcasm_indicators: !!this.sarcasmIndicators,
        intensity_modifiers: !!this.intensityModifiers
      },
      summary: this.getProcessingSummary()
    };

// ========================================
// VERCEL SERVERLESS FUNCTION HANDLER
// ========================================

// Initialize the SpacyService instance
const spacyService = new SpacyService();

module.exports = async function handler(req, res) {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-API-Key');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method === 'GET') {
    // Get service status
    try {
      const status = spacyService.getServiceStatus();
      res.json({
        status: 'operational',
        type: 'spacy-nlp-service',
        version: '1.0.0',
        description: 'Advanced NLP processing with context classification, negation detection, and intensity analysis',
        capabilities: [
          'tokenization',
          'pos_tagging', 
          'named_entity_recognition',
          'dependency_parsing',
          'context_classification',
          'negation_detection',
          'sarcasm_detection',
          'intensity_analysis'
        ],
        dataStatus: status.dataFilesLoaded,
        processingStats: status.summary,
        note: 'Placeholder-free NLP processing service'
      });
    } catch (error) {
      console.error('SpacyService status error:', error);
      res.status(500).json({
        error: {
          code: 'SERVICE_STATUS_ERROR',
          message: 'Failed to get service status',
          details: error.message
        }
      });
    }
    return;
  }

  if (req.method === 'POST') {
    try {
      const { text, options = {}, userId = 'anonymous' } = req.body;

      if (!text) {
        return res.status(400).json({
          error: {
            code: 'MISSING_TEXT',
            message: 'Text is required for NLP processing'
          }
        });
      }

      if (typeof text !== 'string') {
        return res.status(400).json({
          error: {
            code: 'INVALID_TEXT_TYPE',
            message: 'Text must be a string'
          }
        });
      }

      // Process the text using SpacyService
      const nlpResult = await spacyService.processText(text, options);

      // Return successful response
      res.json({
        success: true,
        userId: userId,
        ...nlpResult,
        note: 'Advanced NLP processing completed successfully'
      });

    } catch (error) {
      console.error('SpacyService processing error:', error);
      res.status(500).json({
        error: {
          code: 'NLP_PROCESSING_FAILED',
          message: 'Failed to process text with NLP service',
          details: error.message
        }
      });
    }
    return;
  }

  res.status(405).json({ error: 'Method not allowed' });
};
    