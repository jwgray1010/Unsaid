// api/v1/test-data.ts
import type { VercelRequest, VercelResponse } from '@vercel/node';
import { dataLoader } from '../_lib/services/dataLoader';
import { logger } from '../_lib/logger';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  try {
    logger.info('Testing dataLoader functionality');
    
    // Test loading some data
    const toneData = dataLoader.getToneTriggerWords();
    const therapyData = dataLoader.getTherapyAdvice();
    const contextData = dataLoader.getContextClassifier();
    const learningSignals = dataLoader.getLearningSignals();
    const attachmentLearning = dataLoader.getAttachmentLearning();
    
    res.status(200).json({
      success: true,
      data: {
        dataLoader: {
          initialized: dataLoader.isInitialized(),
          cacheKeys: Object.keys(dataLoader['cache'] || {}),
          dataPath: dataLoader['dataPath']
        },
        sampleData: {
          toneDataKeys: Object.keys(toneData || {}),
          therapyDataKeys: Object.keys(therapyData || {}),
          contextDataKeys: Object.keys(contextData || {}),
          learningSignalsType: Array.isArray(learningSignals) ? 'array' : typeof learningSignals,
          learningSignalsKeys: learningSignals ? Object.keys(learningSignals) : [],
          attachmentLearningType: Array.isArray(attachmentLearning) ? 'array' : typeof attachmentLearning,
          attachmentLearningKeys: attachmentLearning ? Object.keys(attachmentLearning) : []
        }
      }
    });
  } catch (error) {
    logger.error('Error testing dataLoader:', error);
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      stack: error instanceof Error ? error.stack : undefined
    });
  }
}
