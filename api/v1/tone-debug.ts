// api/v1/tone-debug.ts
import type { VercelRequest, VercelResponse } from '@vercel/node';
import { logger } from '../_lib/logger';
import { dataLoader } from '../_lib/services/dataLoader';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  try {
    const text = req.body?.text || "I feel so overwhelmed and stressed out";
    logger.info('Starting tone debug with text:', text);
    
    // Force initialize dataLoader
    if (!dataLoader.isInitialized()) {
      await dataLoader.initialize();
    }
    
    // Test each data source the tone analysis needs
    const tonePatterns = dataLoader.getTonePatterns();
    const evaluationTones = dataLoader.getEvaluationTones();
    const intensityModifiers = dataLoader.getIntensityModifiers();
    const attachmentLearning = dataLoader.getAttachmentLearning();
    const toneTriggerWords = dataLoader.getToneTriggerWords();
    
    logger.info('Data loaded successfully');
    
    // Test the specific data structures
    const debugInfo = {
      tonePatterns: {
        type: Array.isArray(tonePatterns) ? 'array' : typeof tonePatterns,
        keys: tonePatterns ? Object.keys(tonePatterns) : [],
        patternsArray: tonePatterns?.patterns ? Array.isArray(tonePatterns.patterns) : false,
        patternsLength: tonePatterns?.patterns?.length || 0
      },
      evaluationTones: {
        type: Array.isArray(evaluationTones) ? 'array' : typeof evaluationTones,
        keys: evaluationTones ? Object.keys(evaluationTones) : [],
        tonesArray: evaluationTones?.tones ? Array.isArray(evaluationTones.tones) : false,
        tonesLength: evaluationTones?.tones?.length || 0
      },
      intensityModifiers: {
        type: Array.isArray(intensityModifiers) ? 'array' : typeof intensityModifiers,
        keys: intensityModifiers ? Object.keys(intensityModifiers) : [],
        modifiersArray: intensityModifiers?.modifiers ? Array.isArray(intensityModifiers.modifiers) : false,
        modifiersLength: intensityModifiers?.modifiers?.length || 0
      },
      attachmentLearning: {
        type: Array.isArray(attachmentLearning) ? 'array' : typeof attachmentLearning,
        keys: attachmentLearning ? Object.keys(attachmentLearning) : [],
        hasScoring: !!attachmentLearning?.scoring,
        hasThresholds: !!attachmentLearning?.scoring?.thresholds
      },
      toneTriggerWords: {
        type: Array.isArray(toneTriggerWords) ? 'array' : typeof toneTriggerWords,
        keys: toneTriggerWords ? Object.keys(toneTriggerWords) : [],
        triggersArray: toneTriggerWords?.triggers ? Array.isArray(toneTriggerWords.triggers) : false,
        triggersLength: toneTriggerWords?.triggers?.length || 0
      }
    };
    
    // Now try to import and test the toneAnalysisService step by step
    logger.info('Importing toneAnalysisService...');
    const { toneAnalysisService } = await import('../_lib/services/toneAnalysis');
    
    logger.info('Testing ensureDataLoaded...');
    await (toneAnalysisService as any).ensureDataLoaded();
    
    res.status(200).json({
      success: true,
      text,
      debugInfo,
      message: 'All data structures verified and toneAnalysisService imported successfully'
    });
    
  } catch (error) {
    logger.error('Tone debug error:', error);
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      stack: error instanceof Error ? error.stack : undefined
    });
  }
}
