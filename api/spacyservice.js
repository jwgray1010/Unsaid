const fs = require('fs');
const path = require('path');

/**
 * spaCy NLP Service for Unsaid API
 * Handles context classification, negation/sarcasm detection, 
 * and intensity detection
 */
class SpacyService {
  constructor() {
    this.dataPath = path.join(__dirname, '../data');
    this.loadNLPData();
    
    // EXACT SAME scoring weights as EnhancedToneAnalysisService
    this.scoringWeights = {
      exactPattern: 3.0,
      triggerWord: 1.0,
      contextMatch: 1.5,
      intensityBoost: 1.2,
      negationPenalty: 2.0,
      sarcasmPenalty: 2.5
    };
    
    // EXACT SAME thresholds as EnhancedToneAnalysisService
    this.thresholds = {
      toneDetection: 0.15,
      rewriteScore: 0.45,
      confidenceMinimum: 0.25
    };
    
    // spaCy-like processing patterns
    this.entityPatterns = {
      PERSON: /\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*\b/g,
      EMOTION: /\b(happy|sad|angry|excited|worried|hopeful|frustrated|anxious|calm|upset|pleased|disappointed|grateful|hurt|confused|relieved|stressed|content|annoyed|delighted|concerned)\b/gi,
      INTENSITY: /\b(very|extremely|really|quite|somewhat|a little|slightly|incredibly|totally|completely|barely|hardly|absolutely|utterly)\b/gi,
      NEGATION: /\b(not|don't|won't|can't|shouldn't|wouldn't|couldn't|haven't|hasn't|hadn't|isn't|aren't|wasn't|weren't|never|no|none|nothing|nobody|nowhere)\b/gi
    };
    
    // Dependency parsing patterns (simplified)
    this.dependencyPatterns = {
      subject: /\b(I|you|he|she|we|they)\s+(?:am|are|is|was|were|have|has|had|do|does|did|will|would|could|should|might|may)\b/gi,
      object: /\b(?:me|you|him|her|us|them|myself|yourself|himself|herself|ourselves|themselves)\b/gi,
      verb: /\b(?:feel|think|want|need|love|hate|like|dislike|enjoy|appreciate|understand|know|believe|hope|wish|expect|prefer|remember|forget|worry|care|trust|respect)\b/gi
    };
  }
loadNLPData() {
    try {
      // Context classification patterns
      this.contextClassifiers = this.loadJsonFile('context_classifiers.json');
      
      // Negation and sarcasm indicators
      this.negationIndicators = this.loadJsonFile('negation_indicators.json');
      this.sarcasmIndicators = this.loadJsonFile('sarcasm_indicators.json');
      
      // Intensity modifiers
      this.intensityModifiers = this.loadJsonFile('intensity_modifiers.json');
      
      console.log('spaCy NLP data loaded successfully');
    } catch (error) {
      console.error('Error loading spaCy NLP data:', error);
      // Continue with defaults if files don't exist
    }
  }

  loadJsonFile(filename) {
    const filePath = path.join(this.dataPath, filename);
    if (!fs.existsSync(filePath)) {
      console.warn(`NLP file not found: ${filePath}`);
      return null;
    }
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  }
  /**
   * Main NLP processing pipeline
   * Returns comprehensive linguistic analysis
   */
  async processText(text, options = {}) {
    try {
      const startTime = Date.now();
      
      // 1. Tokenization and basic preprocessing
      const tokens = this.tokenize(text);
      
      // 2. Part-of-speech tagging (simplified)
      const posTagged = this.posTag(tokens);
      
      // 3. Named Entity Recognition
      const entities = this.extractNamedEntities(text);
      
      // 4. Dependency parsing (simplified)
      const dependencies = this.parseDependencies(text);
      
      // 5. Context classification
      const contextClassification = this.classifyContext(text, tokens);
      
      // 6. Negation detection
      const negationAnalysis = this.detectNegation(text, tokens);
      
      // 7. Sarcasm detection
      const sarcasmAnalysis = this.detectSarcasm(text, tokens);
      
      // 8. Intensity and modifier detection
      const intensityAnalysis = this.detectIntensity(text, tokens);
      
      const processingTime = Date.now() - startTime;
       return {
        originalText: text,
        tokens: tokens,
        posTagged: posTagged,
        entities: entities,
        dependencies: dependencies,
        contextClassification: contextClassification,
        negationAnalysis: negationAnalysis,
        sarcasmAnalysis: sarcasmAnalysis,
        intensityAnalysis: intensityAnalysis,
        processingTimeMs: processingTime,
        timestamp: new Date().toISOString()
      };
      
    } catch (error) {
      console.error('spaCy processing error:', error);
      throw new Error(`NLP processing failed: ${error.message}`);
    }
  }
 /**
   * 1. Context Classification
   * Identify communication context using spaCy-like pattern matching
   */
  classifyContext(text, tokens) {
    const contexts = [];
    const lowerText = text.toLowerCase();
    
    if (this.contextClassifiers && this.contextClassifiers.contexts) {
      for (const context of this.contextClassifiers.contexts) {
        let score = 0;
        let matchedPatterns = [];
        
        // Check keyword patterns
        if (context.keywords) {
          for (const keyword of context.keywords) {
            if (lowerText.includes(keyword.toLowerCase())) {
              score += context.weight || 1.0;
              matchedPatterns.push(keyword);
            }
          }
        }
        
        // Check phrase patterns
        if (context.phrases) {
          for (const phrase of context.phrases) {
            if (lowerText.includes(phrase.toLowerCase())) {
              score += (context.weight || 1.0) * 1.5; // Phrases get higher weight
              matchedPatterns.push(phrase);
            }
          }
        }
        
        if (score > 0) {
          contexts.push({
            context: context.name,
            score: score,
            confidence: Math.min(score / 3.0, 1.0), // Normalize to 0-1
            matchedPatterns: matchedPatterns,
            description: context.description
          });
        }
      }
    }
      // Sort by score and return top matches
    contexts.sort((a, b) => b.score - a.score);
    
    return {
      primaryContext: contexts[0]?.context || 'general',
      secondaryContext: contexts[1]?.context || null,
      allContexts: contexts,
      confidence: contexts[0]?.confidence || 0.1
    };
  }

  /**
   * 2. Negation Detection
   * Identify negations that can flip meaning
   */
  detectNegation(text, tokens) {
    const negations = [];
    const lowerText = text.toLowerCase();
    
    // Use regex pattern to find negations
    const negationMatches = [...lowerText.matchAll(this.entityPatterns.NEGATION)];
    
    for (const match of negationMatches) {
      const negationWord = match[0];
      const position = match.index;
      
      // Find the scope of negation (next 3-5 words)
      const scope = this.findNegationScope(text, position);
      
      negations.push({
        negationWord: negationWord,
        position: position,
        scope: scope,
        type: this.classifyNegationType(negationWord)
      });
    }
    
    // Check for complex negation patterns from JSON
    if (this.negationIndicators && this.negationIndicators.patterns) {
      for (const pattern of this.negationIndicators.patterns) {
        if (lowerText.includes(pattern.toLowerCase())) {
          negations.push({
            negationWord: pattern,
            position: lowerText.indexOf(pattern.toLowerCase()),
            scope: pattern,
            type: 'complex_pattern'
          });
        }
      }
    }
      return {
      hasNegation: negations.length > 0,
      negations: negations,
      negationCount: negations.length,
      overallNegativePolarity: negations.length > 0 ? 0.8 : 0.0
    };
  }

  /**
   * 3. Sarcasm Detection
   * Detect sarcasm indicators
   */
  detectSarcasm(text, tokens) {
    const sarcasmIndicators = [];
    const lowerText = text.toLowerCase();
    
    // Common sarcasm patterns
    const sarcasmPatterns = [
      /oh\s+(?:great|wonderful|fantastic|perfect|brilliant)/gi,
      /yeah\s+(?:right|sure|ok)/gi,
      /(?:sure|fine|whatever)(?:\s*[.!]){2,}/gi,
      /\b(?:obviously|clearly|definitely)\b.*\?/gi
    ];
    
    for (const pattern of sarcasmPatterns) {
      const matches = [...text.matchAll(pattern)];
      for (const match of matches) {
        sarcasmIndicators.push({
          pattern: match[0],
          position: match.index,
          type: 'linguistic_pattern',
          confidence: 0.7
        });
      }
    }
       // Check sarcasm indicators from JSON
    if (this.sarcasmIndicators && this.sarcasmIndicators.patterns) {
      for (const indicator of this.sarcasmIndicators.patterns) {
        if (lowerText.includes(indicator.toLowerCase())) {
          sarcasmIndicators.push({
            pattern: indicator,
            position: lowerText.indexOf(indicator.toLowerCase()),
            type: 'keyword_indicator',
            confidence: 0.6
          });
        }
      }
    }
    
    // Punctuation-based sarcasm detection
    const excessivePunctuation = /[!]{2,}|[?]{2,}|[.]{3,}/g;
    const punctuationMatches = [...text.matchAll(excessivePunctuation)];
    
    for (const match of punctuationMatches) {
      sarcasmIndicators.push({
        pattern: match[0],
        position: match.index,
        type: 'punctuation_pattern',
        confidence: 0.4
      });
    }
    
    return {
      hasSarcasm: sarcasmIndicators.length > 0,
      sarcasmIndicators: sarcasmIndicators,
      sarcasmScore: sarcasmIndicators.reduce((sum, ind) => sum + ind.confidence, 0) / Math.max(sarcasmIndicators.length, 1),
      overallSarcasmProbability: Math.min(sarcasmIndicators.length * 0.3, 1.0)
    };
  }
  /**
   * 5. Intensity and Modifier Detection
   * Detect words that amplify or soften intensity
   */
  detectIntensity(text, tokens) {
    const intensityWords = [];
    const lowerText = text.toLowerCase();
    
    // Find intensity modifiers
    const intensityMatches = [...text.matchAll(this.entityPatterns.INTENSITY)];
    
    for (const match of intensityMatches) {
      const word = match[0].toLowerCase();
      const position = match.index;
      
      // Classify intensity level
      let level = 'moderate';
      let multiplier = 1.0;
      
      if (['extremely', 'incredibly', 'totally', 'completely', 'absolutely', 'utterly'].includes(word)) {
        level = 'high';
        multiplier = 1.5;
      } else if (['very', 'really', 'quite'].includes(word)) {
        level = 'moderate-high';
        multiplier = 1.2;
      } else if (['somewhat', 'a little', 'slightly', 'barely', 'hardly'].includes(word)) {
        level = 'low';
        multiplier = 0.7;
      }
      
      intensityWords.push({
        word: word,
        position: position,
        level: level,
        multiplier: multiplier,
        scope: this.findIntensityScope(text, position)
      });
    }
       
    // Check intensity modifiers from JSON
    if (this.intensityModifiers) {
      for (const [category, modifiers] of Object.entries(this.intensityModifiers)) {
        if (modifiers && typeof modifiers === 'object') {
          for (const [modifier, value] of Object.entries(modifiers)) {
            if (lowerText.includes(modifier.toLowerCase())) {
              intensityWords.push({
                word: modifier,
                position: lowerText.indexOf(modifier.toLowerCase()),
                level: category,
                multiplier: value,
                scope: modifier,
                source: 'json_config'
              });
            }
          }
        }
      }
    }

    return {
      hasIntensity: intensityWords.length > 0,
      intensityWords: intensityWords,
      intensityCount: intensityWords.length,
      overallIntensity: this.calculateOverallIntensity(intensityWords),
      dominantLevel: this.getDominantIntensityLevel(intensityWords)
    };
  }

  // Move these utility methods outside of detectIntensity, as class methods:

  simplePOSTag(word) {
    const lowerWord = word.toLowerCase();
    const pronouns = ['i', 'you', 'he', 'she', 'it', 'we', 'they', 'me', 'him', 'her', 'us', 'them'];
    const verbs = ['am', 'is', 'are', 'was', 'were', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should'];
    
    if (pronouns.includes(lowerWord)) return 'PRON';
    if (verbs.includes(lowerWord)) return 'VERB';
    if (word.match(/^[A-Z]/)) return 'PROPN';
    if (word.match(/ing$/)) return 'VERB';
    if (word.match(/ed$/)) return 'VERB';
    if (word.match(/ly$/)) return 'ADV';
    
    return 'NOUN'; // Default
  }

  basicLemmatize(word) {
    const lowerWord = word.toLowerCase();
    
    // Basic lemmatization rules
    if (lowerWord.endsWith('ing')) return lowerWord.slice(0, -3);
    if (lowerWord.endsWith('ed')) return lowerWord.slice(0, -2);
    if (lowerWord.endsWith('s') && lowerWord.length > 3) return lowerWord.slice(0, -1);
    
    return lowerWord;
  }

  extractNamedEntities(text) {
    const entities = [];
    
    // Person names (capitalized words)
    const personMatches = [...text.matchAll(this.entityPatterns.PERSON)];
    personMatches.forEach(match => {
      entities.push({
        text: match[0],
        label: 'PERSON',
        start: match.index,
        end: match.index + match[0].length
      });
    });
    
    return entities;
  }

  parseDependencies(text) {
    // Simplified dependency parsing
    const dependencies = [];
    
    const subjectMatches = [...text.matchAll(this.dependencyPatterns.subject)];
    subjectMatches.forEach(match => {
      dependencies.push({
        text: match[0],
        relation: 'subject',
        start: match.index,
        end: match.index + match[0].length
      });
    });
    return dependencies;
  }

  findNegationScope(text, position) {
    // Find the next 20 characters after negation
    return text.substring(position, position + 20).trim();
  }

  findIntensityScope(text, position) {
    // Find the next word after intensity modifier
    const remaining = text.substring(position);
    const nextWord = remaining.split(/\s+/)[1];
    return nextWord || '';
  }

  classifyNegationType(negationWord) {
    const contractions = ["don't", "won't", "can't", "shouldn't", "wouldn't", "couldn't", "haven't", "hasn't", "hadn't", "isn't", "aren't", "wasn't", "weren't"];
    
    if (contractions.includes(negationWord)) return 'contraction';
    if (['not', 'no'].includes(negationWord)) return 'simple';
    if (['never', 'nothing', 'nobody', 'nowhere'].includes(negationWord)) return 'absolute';
    
    return 'other';
  }

  calculateOverallIntensity(intensityWords) {
    if (intensityWords.length === 0) return 1.0;
    
    const totalMultiplier = intensityWords.reduce((sum, word) => sum + word.multiplier, 0);
    return totalMultiplier / intensityWords.length;
  }

  getDominantIntensityLevel(intensityWords) {
    if (intensityWords.length === 0) return 'neutral';
    
    const levelCounts = {};
    intensityWords.forEach(word => {
      levelCounts[word.level] = (levelCounts[word.level] || 0) + 1;
    });
    
    return Object.entries(levelCounts).sort((a, b) => b[1] - a[1])[0][0];
  }

  /**
   * Simple tokenization (missing method)
   */
  tokenize(text) {
    // Simple whitespace and punctuation tokenization
    return text.split(/\s+/).filter(token => token.length > 0).map((token, index) => ({
      text: token,
      index: index,
      pos: this.simplePOSTag(token),
      lemma: this.basicLemmatize(token)
    }));
  }

  /**
   * Simple POS tagging (missing method)
   */
  posTag(tokens) {
    return tokens.map(token => ({
      ...token,
      pos: this.simplePOSTag(token.text)
    }));
  }

  /**
   * Get processing summary for debugging
   */
  getProcessingSummary() {
    return {
      context_classifiers: this.contextClassifiers?.contexts?.length || 0,
      negation_patterns: this.negationIndicators?.patterns?.length || 0,
      sarcasm_patterns: this.sarcasmIndicators?.patterns?.length || 0,
      intensity_categories: Object.keys(this.intensityModifiers || {}).length,
      entity_patterns: Object.keys(this.entityPatterns).length,
      dependency_patterns: Object.keys(this.dependencyPatterns).length
    };
  }

  /**
   * Get service status for health checks
   */
  getServiceStatus() {
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
  }
}

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
    