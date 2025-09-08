// api/cron/validate-data.ts
import { VercelRequest, VercelResponse } from '@vercel/node';
import { withCors, withMethods, withErrorHandling, withLogging } from '../_lib/wrappers';
import { success } from '../_lib/http';
import { dataLoader } from '../_lib/services/dataLoader';
import { logger } from '../_lib/logger';

interface ValidationResult {
  file: string;
  valid: boolean;
  errors: string[];
  recordCount?: number;
  lastModified?: string;
}

interface DataValidationReport {
  timestamp: string;
  totalFiles: number;
  validFiles: number;
  invalidFiles: number;
  results: ValidationResult[];
  overallStatus: 'healthy' | 'warning' | 'error';
}

const handler = async (req: VercelRequest, res: VercelResponse) => {
  const startTime = Date.now();
  
  try {
    logger.info('Starting data validation cron job');
    
    // DataLoader is now pre-initialized synchronously
    if (!dataLoader.isInitialized()) {
      logger.warn('DataLoader not initialized in validate-data cron');
      return;
    }
    
    const results: ValidationResult[] = [];
    
    // Validate all data files
    const validationChecks = [
      { name: 'attachment_learning.json', getter: () => dataLoader.getAttachmentLearning() },
      { name: 'therapy_advice.json', getter: () => dataLoader.getTherapyAdvice() },
      { name: 'tone_patterns.json', getter: () => dataLoader.getTonePatterns() },
      { name: 'evaluation_tones.json', getter: () => dataLoader.getEvaluationTones() },
      { name: 'semantic_thesaurus.json', getter: () => dataLoader.getSemanticThesaurus() },
      { name: 'context_classifier.json', getter: () => dataLoader.getContextClassifier() },
      { name: 'intensity_modifiers.json', getter: () => dataLoader.getIntensityModifiers() },
      { name: 'learning_signals.json', getter: () => dataLoader.getLearningSignals() },
      { name: 'guardrail_config.json', getter: () => dataLoader.getGuardrailConfig() },
      { name: 'tone_bucket_mapping.json', getter: () => dataLoader.getToneBucketMapping() },
      { name: 'negation_indicators.json', getter: () => dataLoader.getNegationIndicators() },
      { name: 'profanity_lexicons.json', getter: () => dataLoader.getProfanityLexicons() },
      { name: 'sarcasm_indicators.json', getter: () => dataLoader.getSarcasmIndicators() },
      { name: 'weight_modifiers.json', getter: () => dataLoader.getWeightModifiers() },
    ];
    
    for (const check of validationChecks) {
      try {
        const data = check.getter();
        const errors: string[] = [];
        
        if (!data) {
          errors.push('Data not loaded or null');
        } else if (Array.isArray(data) && data.length === 0) {
          errors.push('Array is empty');
        } else if (typeof data === 'object' && Object.keys(data).length === 0) {
          errors.push('Object is empty');
        }
        
        // Additional validations based on data type
        if (Array.isArray(data)) {
          // Check for required fields in array items
          if (check.name === 'therapy_advice.json' && data.length > 0) {
            const sample = data[0] as any;
            if (!sample.advice || !sample.triggerTone) {
              errors.push('Missing required fields: advice, triggerTone');
            }
          }
          if (check.name === 'tone_patterns.json' && data.length > 0) {
            const sample = data[0] as any;
            if (!sample.tone || !sample.pattern) {
              errors.push('Missing required fields: tone, pattern');
            }
          }
        }
        
        results.push({
          file: check.name,
          valid: errors.length === 0,
          errors,
          recordCount: Array.isArray(data) ? data.length : 1
        });
        
      } catch (error) {
        results.push({
          file: check.name,
          valid: false,
          errors: [`Validation error: ${error instanceof Error ? error.message : 'Unknown error'}`]
        });
      }
    }
    
    const validFiles = results.filter(r => r.valid).length;
    const invalidFiles = results.filter(r => !r.valid).length;
    const totalFiles = results.length;
    
    let overallStatus: 'healthy' | 'warning' | 'error' = 'healthy';
    if (invalidFiles > 0) {
      overallStatus = invalidFiles > totalFiles * 0.3 ? 'error' : 'warning';
    }
    
    const report: DataValidationReport = {
      timestamp: new Date().toISOString(),
      totalFiles,
      validFiles,
      invalidFiles,
      results,
      overallStatus
    };
    
    const processingTime = Date.now() - startTime;
    
    logger.info('Data validation completed', {
      processingTime,
      totalFiles,
      validFiles,
      invalidFiles,
      status: overallStatus
    });
    
    // Log warnings/errors
    if (overallStatus !== 'healthy') {
      const invalidResults = results.filter(r => !r.valid);
      logger.warn('Data validation issues found', { invalidResults });
    }
    
    success(res, {
      report,
      metadata: {
        processingTimeMs: processingTime,
        cronJob: 'validate-data',
        version: '1.0.0'
      }
    });
    
  } catch (error) {
    logger.error('Data validation cron job failed:', error);
    throw error;
  }
};

export default withErrorHandling(
  withLogging(
    withCors(
      withMethods(['GET', 'POST'], handler)
    )
  )
);
