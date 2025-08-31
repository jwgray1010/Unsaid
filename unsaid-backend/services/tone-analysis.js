/**
* tone-analysis.functional.js
*
* JSON‑powered, functional implementation (no classes) for Unsaid
* - Loads JSON knowledge bases
* - Feature extraction via pure functions
* - Tone classification (ensemble + safety + sarcasm/negation/edges)
* - Optional EWMA smoothing via closure
* - Mapping to suggestion buckets via tone_bucket_mapping.json
*
* Exports (CommonJS):
* - loadAllData(baseDir)
* - createToneSmoother(opts)
* - analyzeToneOnce(text, opts)
* - mapToneToBuckets(toneResult, attachmentStyle, contextKey, data, config)
* - createToneAnalyzer(config) => { analyzeTone, mapToneToBuckets, getToneHistory, reset }
*/


const fs = require('fs');
const path = require('path');


/*********************
* 0) DATA LOADING *
*********************/
const safeRead = (p, fb = null) => {
try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return fb; }
};

// Import the class-based implementation for reuse
const { MLAdvancedToneAnalyzer } = require('./tone-analysis-endpoint');

function loadAllData(baseDir = path.join(__dirname, '../data')) {
  const P = (f) => path.join(baseDir, f);
  return {
    contextClassifier: safeRead(P('context_classifier.json'), { contexts: [] }),
    toneTriggerwords: safeRead(P('tone_triggerwords.json'), { triggers: [] }),
    intensityModifiers: safeRead(P('intensity_modifiers.json'), { modifiers: [] }),
    sarcasmIndicators: safeRead(P('sarcasm_indicators.json'), { sarcasm_indicators: [] }),
    negationIndicators: safeRead(P('negation_indicators.json'), { negation_indicators: [] }),
    phraseEdges: safeRead(P('phrase_edges.json'), { edges: [] }),
    semanticThesaurus: safeRead(P('semantic_thesaurus.json'), {}),
    toneBucketMap: safeRead(P('tone_bucket_mapping.json'), {
      version: '1.0',
      default: {
        neutral: { clear: 0.70, caution: 0.25, alert: 0.05 },
        positive: { clear: 0.80, caution: 0.18, alert: 0.02 },
        supportive: { clear: 0.85, caution: 0.13, alert: 0.02 },
        angry: { clear: 0.05, caution: 0.30, alert: 0.65 },
        frustrated: { clear: 0.10, caution: 0.55, alert: 0.35 },
        anxious: { clear: 0.15, caution: 0.60, alert: 0.25 },
        sad: { clear: 0.25, caution: 0.60, alert: 0.15 }
      },
      contextOverrides: {},
      intensityShifts: { 
        thresholds: { low: 0.15, med: 0.35, high: 0.60 }, 
        low: { alert: -0.1, caution: 0.08, clear: 0.02 }, 
        med: {}, 
        high: { alert: 0.12, caution: -0.08, clear: -0.04 } 
      }
    })
  };
}

function mapToneToBuckets(toneResult, attachmentStyle = 'secure', contextKey = 'default', data = null, config = {}) {
  if (!data) {
    data = loadAllData(config.dataDir);
  }
  
  const bucketMap = data.toneBucketMap || {};
  const defaultBuckets = bucketMap.default || {};
  const contextOverrides = bucketMap.contextOverrides || {};
  const intensityShifts = bucketMap.intensityShifts || {};
  
  const tone = toneResult.classification || toneResult.tone?.classification || 'neutral';
  const confidence = toneResult.confidence || toneResult.tone?.confidence || 0.5;
  
  // Get base bucket probabilities
  let buckets = { clear: 0.5, caution: 0.3, alert: 0.2 };
  
  if (defaultBuckets[tone]) {
    buckets = { ...defaultBuckets[tone] };
  }
  
  // Apply context overrides if available
  if (contextOverrides[contextKey] && contextOverrides[contextKey][tone]) {
    buckets = { ...buckets, ...contextOverrides[contextKey][tone] };
  }
  
  // Apply intensity shifts based on confidence
  const thresholds = intensityShifts.thresholds || { low: 0.15, med: 0.35, high: 0.60 };
  let intensityLevel = 'med';
  
  if (confidence < thresholds.low) intensityLevel = 'low';
  else if (confidence > thresholds.high) intensityLevel = 'high';
  
  const shifts = intensityShifts[intensityLevel] || {};
  for (const [bucket, shift] of Object.entries(shifts)) {
    if (buckets[bucket] !== undefined) {
      buckets[bucket] = Math.max(0, Math.min(1, buckets[bucket] + shift));
    }
  }
  
  // Normalize to ensure probabilities sum to 1
  const total = Object.values(buckets).reduce((sum, val) => sum + val, 0);
  if (total > 0) {
    for (const bucket of Object.keys(buckets)) {
      buckets[bucket] = buckets[bucket] / total;
    }
  }
  
  return {
    buckets,
    metadata: {
      tone,
      confidence,
      attachmentStyle,
      contextKey,
      intensityLevel
    }
  };
}

function createToneAnalyzer(config = {}) {
  const {
    premium = false,
    confidenceThreshold = 0.25,
    dataDir = path.join(__dirname, '../data'),
    enableSmoothing = true,
    smoothingAlpha = 0.7,
    hysteresisThreshold = 0.2,
    decayRate = 0.95
  } = config;
  
  // Create the underlying analyzer with tier configuration
  const tier = premium ? 'premium' : 'general';
  const analyzer = new MLAdvancedToneAnalyzer({
    enableSmoothing,
    enableSafetyChecks: true,
    confidenceThreshold,
    smoothingAlpha,
    hysteresisThreshold,
    decayRate
  });
  
  // Load data once
  const data = loadAllData(dataDir);
  
  return {
    async analyzeTone(text, attachmentStyle = 'secure', contextHint = 'general') {
      return await analyzer.analyzeTone(text, attachmentStyle, contextHint, tier);
    },
    
    mapToneToBuckets(toneResult, attachmentStyle = 'secure', contextKey = 'default') {
      return mapToneToBuckets(toneResult, attachmentStyle, contextKey, data, config);
    },
    
    getToneHistory() {
      return analyzer.smoother ? {
        history: analyzer.smoother.hist || [],
        stability: analyzer.smoother.stability(),
        trend: analyzer.smoother.trend()
      } : null;
    },
    
    reset() {
      if (analyzer.smoother) {
        analyzer.smoother.reset();
      }
    },
    
    // Additional utility methods
    getConfig() {
      return { ...config, tier };
    },
    
    updateConfig(newConfig) {
      Object.assign(config, newConfig);
      return this;
    }
  };
}

// Export all functions
module.exports = {
  loadAllData,
  mapToneToBuckets,
  createToneAnalyzer,
  MLAdvancedToneAnalyzer // Re-export for compatibility
};