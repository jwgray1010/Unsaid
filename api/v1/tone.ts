// api/v1/tone.ts
import { VercelRequest, VercelResponse } from '@vercel/node';
import { withCors, withMethods, withValidation, withErrorHandling, withLogging, withRateLimit } from '../_lib/wrappers';
import { success } from '../_lib/http';
import { toneRequestSchema } from '../_lib/schemas/toneRequest';
import { toneAnalysisService } from '../_lib/services/toneAnalysis';
import { CommunicatorProfile } from '../_lib/services/communicatorProfile';
import { logger } from '../_lib/logger';
import { ensureBoot } from '../_lib/bootstrap';
import * as path from 'path';

function getUserId(req: VercelRequest): string {
  return req.headers['x-user-id'] as string || 'anonymous';
}

const handler = async (req: VercelRequest, res: VercelResponse, data: any) => {
  const startTime = Date.now();
  const userId = getUserId(req);
  
  logger.info('Processing advanced tone analysis request', { 
    textLength: data.text.length,
    context: data.context,
    userId
  });
  
  try {
    // ✅ Guarantee JSON is in memory before any analysis
    await ensureBoot();
    
    // Initialize user profile
    const profile = new CommunicatorProfile({
      userId
    });
    await profile.init();
    
    // Get attachment estimate
    const attachmentEstimate = profile.getAttachmentEstimate();
    const isNewUser = !attachmentEstimate.primary || attachmentEstimate.confidence < 0.3;
    
    // Perform advanced analysis using the dedicated service
    const result = await toneAnalysisService.analyzeAdvancedTone(data.text, {
      context: data.context,
      attachmentStyle: attachmentEstimate.primary || undefined,
      relationshipStage: data.meta?.relationshipStage,
      includeAttachmentInsights: true,
      deepAnalysis: true,
      isNewUser,
      userProfile: {
        id: userId,
        attachment: attachmentEstimate.primary,
        secondary: attachmentEstimate.secondary,
        windowComplete: attachmentEstimate.windowComplete
      }
    });
    
    // Add communication to profile history
    profile.addCommunication(data.text, data.context, result.primary_tone);
    
    const processingTime = Date.now() - startTime;
    
    logger.info('Advanced tone analysis completed', { 
      processingTime,
      tone: result.primary_tone,
      confidence: result.confidence,
      userId,
      attachment: attachmentEstimate.primary,
      isNewUser
    });
    
    const response = {
      ok: true,
      userId,
      attachmentEstimate,
      isNewUser,
      tone: result.primary_tone,
      confidence: result.confidence,
      analysis: {
        primary_tone: result.primary_tone,
        emotions: result.emotions,
        intensity: result.intensity,
        sentiment_score: result.sentiment_score,
        linguistic_features: result.linguistic_features,
        context_analysis: result.context_analysis,
        attachment_insights: result.attachment_insights,
      },
      metadata: {
        processing_time_ms: processingTime,
        model_version: 'v1.0.0-advanced',
        attachment_informed: true,
        status: isNewUser ? 'learning' : 'active'
      }
    };
    
    success(res, response);
  } catch (error) {
    logger.error('Advanced tone analysis failed:', error);
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
