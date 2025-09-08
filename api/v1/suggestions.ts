// api/v1/suggestions.ts
import { VercelRequest, VercelResponse } from '@vercel/node';
import { withCors, withMethods, withValidation, withErrorHandling, withLogging, withRateLimit } from '../_lib/wrappers';
import { success } from '../_lib/http';
import { toneRequestSchema } from '../_lib/schemas/toneRequest';
import { suggestionsService } from '../_lib/services/suggestions';
import { CommunicatorProfile } from '../_lib/services/communicatorProfile';
import { logger } from '../_lib/logger';
import * as path from 'path';

function getUserId(req: VercelRequest): string {
  return req.headers['x-user-id'] as string || 'anonymous';
}

const handler = async (req: VercelRequest, res: VercelResponse, data: any) => {
  const startTime = Date.now();
  const userId = getUserId(req);
  
  logger.info('Processing advanced suggestions request', { 
    textLength: data.text.length,
    context: data.context,
    userId
  });
  
  try {
    // Initialize user profile
    const profile = new CommunicatorProfile({
      userId
    });
    await profile.init();
    
    // Get attachment estimate
    const attachmentEstimate = profile.getAttachmentEstimate();
    const isNewUser = !attachmentEstimate.primary || attachmentEstimate.confidence < 0.3;
    
    // Generate suggestions using the dedicated service
    const suggestionAnalysis = await suggestionsService.generateAdvancedSuggestions(
      data.text,
      data.context,
      {
        id: userId,
        attachment: attachmentEstimate.primary,
        secondary: attachmentEstimate.secondary,
        windowComplete: attachmentEstimate.windowComplete
      },
      {
        maxSuggestions: data.count || 3,
        attachmentStyle: attachmentEstimate.primary || undefined,
        relationshipStage: data.meta?.relationshipStage,
        conflictLevel: data.meta?.conflictLevel || 'low',
        isNewUser
      }
    );
    
    // Add communication to profile history (using a fallback tone since we don't have tone analysis)
    profile.addCommunication(data.text, data.context, 'neutral');
    
    const processingTime = Date.now() - startTime;
    
    logger.info('Advanced suggestions generated', { 
      processingTime,
      count: suggestionAnalysis.suggestions.length,
      userId,
      attachment: attachmentEstimate.primary,
      isNewUser
    });
    
    const response = {
      ok: true,
      userId,
      original_text: suggestionAnalysis.original_text,
      context: suggestionAnalysis.context,
      attachmentEstimate,
      isNewUser,
      suggestions: suggestionAnalysis.suggestions.map((s, index) => ({
        id: index + 1,
        text: s.text,
        type: s.type,
        confidence: s.confidence,
        reason: s.reason,
        category: s.category,
        priority: s.priority,
        context_specific: s.context_specific,
        attachment_informed: s.attachment_informed
      })),
      analysis_meta: suggestionAnalysis.analysis_meta,
      metadata: {
        processing_time_ms: processingTime,
        model_version: 'v1.0.0-advanced',
        attachment_informed: true,
        suggestion_count: suggestionAnalysis.suggestions.length,
        status: isNewUser ? 'learning' : 'active'
      }
    };
    
    success(res, response);
  } catch (error) {
    logger.error('Advanced suggestions generation failed:', error);
    throw error;
  }
};

export default withErrorHandling(
  withLogging(
    withRateLimit()(
      withCors(
        withMethods(['POST'], 
          withValidation(toneRequestSchema, handler)
        )
      )
    )
  )
);
