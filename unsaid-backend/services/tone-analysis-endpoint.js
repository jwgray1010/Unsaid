/**
 * tone-analysis.advanced.js
 *
 * Most-accurate tone analysis module for Unsaid
 * - Designed to serve BOTH new (general) users and premium subscribers
 * - Plugs into your JSON knowledge bases and SpacyService
 * - Produces: rich tone classification + calibrated confidence + evidence
 * - Compatible with Suggestion.advanced.js orchestrator
 *
 * Exports:
 *  - AdvancedFeatureExtractor
 *  - ToneSmoother
 *  - MLAdvancedToneAnalyzer
 */

const fs = require('fs');
const path = require('path');
const { SpacyService } = require('./spacy-service.js');

// -----------------------------
// Utilities
// -----------------------------
const safeReadJson = (p, fb = null) => {
  try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return fb; }
};

// -----------------------------
// DataLoader (local JSONs)
// -----------------------------
class TADataLoader {
  constructor(baseDir = path.join(__dirname, 'data')) {
    this.baseDir = baseDir;
    this.cache = {};
  }
  load() {
    const P = (f) => path.join(this.baseDir, f);
    this.cache.contextClassifier   = safeReadJson(P('context_classifier.json'), { contexts: [] });
    this.cache.toneTriggerwords    = safeReadJson(P('tone_triggerwords.json'), { triggers: [] });
    this.cache.intensityModifiers  = safeReadJson(P('intensity_modifiers.json'), { modifiers: [] });
    this.cache.sarcasmIndicators   = safeReadJson(P('sarcasm_indicators.json'), { sarcasm_indicators: [] });
    this.cache.negationIndicators  = safeReadJson(P('negation_indicators.json'), { negation_indicators: [] });
    this.cache.phraseEdges         = safeReadJson(P('phrase_edges.json'), { edges: [] });
    this.cache.semanticThesaurus   = safeReadJson(P('semantic_thesaurus.json'), {});
    this.cache.severityCollab      = safeReadJson(P('severity_collaboration.json'), { alert:{base:0.55},caution:{base:0.40},clear:{base:0.35} });
    this.cache.weightProfiles      = safeReadJson(P('weightMultiplierProfiles.json'), { version:'1.0', profiles:{} });
    this.cache.toneBucketMap       = safeReadJson(P('tone_bucket_mapping.json'), {
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
      contextOverrides: {},
      intensityShifts: { thresholds:{low:0.15,med:0.35,high:0.60}, low:{alert:-0.1,caution:0.08,clear:0.02}, med:{}, high:{alert:0.12,caution:-0.08,clear:-0.04} }
    });
    return this.cache;
  }
  get(k){ return this.cache[k]; }
}

// -----------------------------
// 1) Advanced Feature Extractor
// -----------------------------
class AdvancedFeatureExtractor {
  constructor(loader) {
    this.loader = loader;
    this.spacy = new SpacyService();
    this._initDefaults();
    this._initGenerators();
  }

  _initDefaults() {
    // Lightweight fallback lexicons for emotions (used in addition to JSON triggers)
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

  _initGenerators() {
    this.generators = [
      { key:'emotions',        w:0.28, f:this._emotionFeatures.bind(this) },
      { key:'context',         w:0.18, f:this._contextFeatures.bind(this) },
      { key:'attachment',      w:0.12, f:this._attachmentFeatures.bind(this) },
      { key:'intensity',       w:0.10, f:this._intensityFeatures.bind(this) },
      { key:'linguistic',      w:0.10, f:this._linguisticFeatures.bind(this) },
      { key:'temporal',        w:0.04, f:this._temporalFeatures.bind(this) },
      { key:'sentiment',       w:0.06, f:this._sentimentFeatures.bind(this) },
      { key:'negationSarcasm', w:0.06, f:this._negationSarcasmFeatures.bind(this) },
      { key:'phraseEdges',     w:0.06, f:this._phraseEdgeFeatures.bind(this) }
    ];
  }

  extract(text, attachmentStyle='secure') {
    const feats = {};
    let weightSum = 0;
    for (const g of this.generators) {
      try { Object.assign(feats, g.f(text, attachmentStyle)); weightSum += g.w; }
      catch(e){ /* noop but keep going */ }
    }
    // Add spaCy-style processing bundle
    const spacy = this.spacy.process(text, {
      contextClassifier: this.loader.get('contextClassifier'),
      negationIndicators: this.loader.get('negationIndicators'),
      sarcasmIndicators: this.loader.get('sarcasmIndicators'),
      intensityModifiers: this.loader.get('intensityModifiers'),
      phraseEdges: this.loader.get('phraseEdges'),
      semanticThesaurus: this.loader.get('semanticThesaurus')
    });

    return {
      features: { ...feats, spacy },
      weightSum,
      featureCount: Object.keys(feats).length + 1,
      spacy
    };
  }

  // --- feature generators ---
  _emotionFeatures(text){
    const out = {}; const T = text.toLowerCase();
    for (const [emo, list] of Object.entries(this.emotionalLex)) {
      let hits = 0; list.forEach(k=>{ if (T.includes(k)) hits++; });
      out[`emo_${emo}`] = hits / Math.max(1, list.length);
    }
    return out;
  }
  _contextFeatures(text){
    const out = {}; const T = text.toLowerCase();
    const c = this.loader.get('contextClassifier');
    (c.contexts||[]).forEach(ctx=>{
      let score = 0; (ctx.toneCues||ctx.keywords||[]).forEach(k=>{ if (T.includes(k)) score += 1; });
      out[`ctx_${ctx.context||ctx.name}`] = score * ((ctx.weight||1));
    });
    return out;
  }
  _attachmentFeatures(text){
    const out = {}; const T = text.toLowerCase();
    for (const [style, list] of Object.entries(this.attachmentHints)) {
      let hits = 0; list.forEach(k=>{ if (T.includes(k)) hits++; });
      out[`attach_${style}`] = hits / Math.max(1, list.length);
    }
    return out;
  }
  _intensityFeatures(text){
    const out = {}; const T = text.toLowerCase();
    // punctuation
    const q = (text.match(/\?/g)||[]).length; const e = (text.match(/!/g)||[]).length;
    out.int_q = q; out.int_exc = e;
    // caps
    const caps = (text.match(/[A-Z]/g)||[]).length; const letters=(text.match(/[A-Za-z]/g)||[]).length || 1;
    out.int_caps_ratio = caps/letters;
    // elongated words
    out.int_elong = (text.match(/([a-z])\1{2,}/gi)||[]).length;
    // intensifiers from JSON
    const mods = (this.loader.get('intensityModifiers')?.modifiers)||[];
    let modScore = 0;
    mods.forEach(m=>{ if (m.pattern){ try{ const r=new RegExp(m.pattern,'i'); if (r.test(text)) modScore += (m.multiplier||1)-1; }catch{} } });
    out.int_modscore = Math.max(0, modScore);
    return out;
  }
  _linguisticFeatures(text){
    const out = {}; const T = text.toLowerCase();
    const sentences = text.split(/[.!?]+/).filter(s=>s.trim().length>0);
    out.lng_avgLen = sentences.length? sentences.reduce((a,s)=>a+s.length,0)/sentences.length : 0;
    const first = [' i ',' me ',' my ',' mine ',' myself '];
    const second = [' you ',' your ',' yours ',' yourself '];
    out.lng_first = first.reduce((c,p)=>c+(T.split(p).length-1),0);
    out.lng_second= second.reduce((c,p)=>c+(T.split(p).length-1),0);
    out.lng_modal = (T.match(/\b(should|must|need to|have to|ought to)\b/g)||[]).length;
    out.lng_absolutes = (T.match(/\b(always|never|every time)\b/g)||[]).length;
    return out;
  }
  _temporalFeatures(text){
    const T = text.toLowerCase();
    const past = ['yesterday','last','ago','before','earlier','previously','used to'];
    const present = ['now','today','currently','right now','at the moment'];
    const future = ['tomorrow','next','will','going to','planning','soon','later'];
    return {
      tmp_past: past.reduce((n,k)=>n+(T.includes(k)?1:0),0),
      tmp_present: present.reduce((n,k)=>n+(T.includes(k)?1:0),0),
      tmp_future: future.reduce((n,k)=>n+(T.includes(k)?1:0),0)
    };
  }
  _sentimentFeatures(text){
    const T = text.toLowerCase();
    const pos = ['good','great','awesome','amazing','wonderful','excellent','fantastic','love'];
    const neg = ['bad','terrible','awful','horrible','hate','worst','disgusting','pathetic'];
    const pc = pos.reduce((n,w)=>n+(T.includes(w)?1:0),0);
    const nc = neg.reduce((n,w)=>n+(T.includes(w)?1:0),0);
    return { sent_pos: pc, sent_neg: nc, sent_pol: pc-nc };
  }
  _negationSarcasmFeatures(text){
    const out = {}; const conf = { neg:0, sarc:0 };
    try{ const sp = this.spacy.process(text, { negationIndicators:this.loader.get('negationIndicators'), sarcasmIndicators:this.loader.get('sarcasmIndicators')});
      conf.neg = sp.negation?.present? (sp.negation.score||0.3):0; conf.sarc = sp.sarcasm?.present? (sp.sarcasm.score||0.3):0; }catch{}
    out.neg_present = conf.neg; out.sarc_present = conf.sarc; return out;
  }
  _phraseEdgeFeatures(text){
    const out = {}; const hits=[]; const edges=(this.loader.get('phraseEdges')?.edges)||[];
    edges.forEach(e=>{ if (!e?.pattern) return; try{ const r=new RegExp(e.pattern,'i'); if (r.test(text)) hits.push(e.category||'edge'); }catch{} });
    out.edge_hits = hits.length; out.edge_list = hits; return out;
  }
}

// -----------------------------
// 2) Tone Smoother (EWMA + hysteresis + decay)
// -----------------------------
class ToneSmoother {
  constructor(alpha=0.7, hysteresis=0.2, decay=0.95) {
    this.alpha=alpha; this.hysteresis=hysteresis; this.decay=decay;
    this.hist=[]; this.lastTone=null; this.lastConf=0; this.lastTs=null;
  }
  smooth(tone, conf, ts=Date.now()){
    if(!this.lastTone){ this.lastTone=tone; this.lastConf=conf; this.lastTs=ts; this.hist.push({tone,conf,ts}); return {tone,confidence:conf}; }
    const dt=(ts-this.lastTs)/1000; const decayed=this.lastConf*Math.pow(this.decay, dt);
    const changed = tone!==this.lastTone; const diff=Math.abs(conf-decayed);
    let finalTone=tone; let finalConf=conf;
    if (changed && diff < this.hysteresis) { finalTone=this.lastTone; }
    finalConf = this.alpha*conf + (1-this.alpha)*decayed; finalConf=Math.max(0,Math.min(1,finalConf));
    this.lastTone=finalTone; this.lastConf=finalConf; this.lastTs=ts; this.hist.push({tone:finalTone,conf:finalConf,ts});
    if (this.hist.length>10) this.hist.shift();
    return { tone: finalTone, confidence: finalConf };
  }
  stability(){ if(this.hist.length<3) return 0.5; const recent=this.hist.slice(-5).map(h=>h.tone); const uniq=new Set(recent); return 1-(uniq.size-1)/Math.max(1,recent.length-1); }
  trend(){ if(this.hist.length<3) return 0; const r=this.hist.slice(-3).map(h=>h.confidence); return Math.max(-1,Math.min(1,(r[r.length-1]-r[0]))); }
  reset(){ this.hist=[]; this.lastTone=null; this.lastConf=0; this.lastTs=null; }
}

// -----------------------------
// 3) ML Advanced Tone Analyzer (ensemble)
// -----------------------------
class MLAdvancedToneAnalyzer {
  constructor(config={}){
    this.loader = new TADataLoader();
    this.loader.load();
    this.fx = new AdvancedFeatureExtractor(this.loader);
    this.smoother = new ToneSmoother(config.smoothingAlpha||0.7, config.hysteresisThreshold||0.2, config.decayRate||0.95);
    this.config = Object.assign({ enableSmoothing:true, enableSafetyChecks:true, confidenceThreshold:0.25 }, config);

    // Base weights (can be modulated by tier/profile)
    this.weights = {
      emo: 0.40, ctx: 0.20, attach: 0.15, ling: 0.15, intensity: 0.10,
      negPenalty: 0.15, sarcPenalty: 0.18, absolutesBoost: 0.06
    };
  }

  // Public entry
  async analyzeTone(text, attachmentStyle='secure', contextHint='general', tier='general'){
    try {
      const fr = this.fx.extract(text, attachmentStyle);

      // Tier-aware multiplier profiles
      const profileKey = tier==='premium' ? 'power_user' : 'general_user';
      const prof = (this.loader.get('weightProfiles')?.profiles?.[profileKey]) || { intensityBoost:1.0, sarcasmSensitivity:1.0, negationSensitivity:1.0 };

      const scores = this._scoreTones(fr, text, attachmentStyle, contextHint, prof);
      const distribution = this._softmax(scores);
      let classification = this._argmax(distribution);
      let confidence = distribution[classification] || 0.33;

      // Safety override
      if (this.config.enableSafetyChecks) {
        const safety = this._safetyOverride(text);
        if (safety) { classification='safety_concern'; confidence=Math.max(confidence,0.95); }
      }

      // Smoothing
      let finalTone = { classification, confidence };
      if (this.config.enableSmoothing) {
        const sm = this.smoother.smooth(classification, confidence);
        finalTone = { classification: sm.tone, confidence: sm.confidence, isSmoothed:true, stability:this.smoother.stability(), confidenceTrend:this.smoother.trend() };
      }

      return { success:true, tone: finalTone, scores, distribution, features: { count: fr.featureCount, bundle: fr.features }, metadata:{ attachmentStyle, context: contextHint, tier, timestamp:new Date().toISOString() } };
    } catch (e) {
      console.error('Tone analysis error', e);
      return { success:false, tone:{ classification:'neutral', confidence:0.1, error:e.message } };
    }
  }

  // ---- scoring ensemble ----
  _scoreTones(fr, text, attachmentStyle, contextHint, prof){
    const f = fr.features; const sp = f.spacy || {};
    const out = { neutral: 0.1, positive: 0.1, supportive: 0.1, anxious: 0, angry: 0, frustrated: 0, sad: 0, assertive: 0 };

    // Emotion-driven
    out.angry      += (f.emo_anger||0) * (this.weights.emo + (sp.intensity?.score||0)*0.2);
    out.sad        += (f.emo_sadness||0) * this.weights.emo;
    out.anxious    += (f.emo_anxiety||0) * this.weights.emo;
    out.positive   += (f.emo_joy||0) * (this.weights.emo*0.9);
    out.supportive += (f.emo_affection||0) * (this.weights.emo*0.9);

    // Context cues
    if ((f[`ctx_conflict`]||0)>0) { out.angry += 0.25; out.frustrated += 0.20; }
    if ((f[`ctx_planning`]||0)>0) { out.assertive += 0.12; out.neutral += 0.08; }
    if ((f[`ctx_repair`]||0)>0)   { out.supportive += 0.18; }

    // Linguistic (absolutes & modals tilt toward confront/defend)
    out.angry      += Math.min(0.25, (f.lng_absolutes||0) * this.weights.absolutesBoost);
    out.assertive  += Math.min(0.20, (f.lng_modal||0) * 0.03);

    // Attachment adjustments
    if (attachmentStyle==='anxious') { out.anxious += (f.attach_anxious||0)*0.35; }
    if (attachmentStyle==='avoidant'){ out.frustrated += (f.attach_avoidant||0)*0.25; }
    if (attachmentStyle==='secure')  { out.supportive += (f.attach_secure||0)*0.25; }

    // Intensity (punctuation, caps, elongation)
    const intensity = Math.min(1, (f.int_q||0)*0.05 + (f.int_exc||0)*0.08 + (f.int_caps_ratio||0)*0.8 + (f.int_elong||0)*0.08 + (f.int_modscore||0));
    out.angry      += intensity*0.35; out.frustrated += intensity*0.25; out.supportive -= intensity*0.05;

    // Negation/sarcasm penalties (tier sensitivity)
    const neg = (f.neg_present||0) * (prof.negationSensitivity||1);
    const sar = (f.sarc_present||0) * (prof.sarcasmSensitivity||1);
    out.supportive -= sar*this.weights.sarcPenalty; out.positive -= sar*(this.weights.sarcPenalty*0.6);
    out.angry      += sar*0.12; out.frustrated += sar*0.10;
    out.angry      += neg*0.10; out.frustrated += neg*0.08; out.neutral -= neg*0.05;

    // Phrase edges (rupture etc.)
    const edgeHits = Array.isArray(f.edge_list)? f.edge_list : [];
    if (edgeHits.includes('rupture')) { out.angry += 0.25; out.frustrated += 0.15; }
    if (edgeHits.includes('repair'))  { out.supportive += 0.22; }

    // Normalize small floor
    for (const k of Object.keys(out)) out[k] = Math.max(0, out[k]);
    return out;
  }

  _softmax(scores){
    // Convert arbitrary positive scores to probabilities
    const vals = Object.values(scores);
    const max = Math.max(...vals, 0);
    const exps = {}; let sum=0;
    for (const [k,v] of Object.entries(scores)) { const e = Math.exp(v - max); exps[k]=e; sum+=e; }
    const dist={}; for(const [k,e] of Object.entries(exps)) dist[k]= e/(sum||1);
    return dist;
  }
  _argmax(dist){ return Object.entries(dist).sort((a,b)=>b[1]-a[1])[0][0]; }

  _safetyOverride(text){
    const t=text.toLowerCase();
    const kw=['kill','die','suicide','hurt myself','end it all','harm'];
    return kw.some(k=>t.includes(k));
  }
}

module.exports = { AdvancedFeatureExtractor, ToneSmoother, MLAdvancedToneAnalyzer };