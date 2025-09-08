// api/v1/index.ts
import { VercelRequest, VercelResponse } from '@vercel/node';
import { withCors, withMethods, withErrorHandling, withLogging } from '../_lib/wrappers';
import { success } from '../_lib/http';
import { env } from '../_lib/env';

const handler = async (req: VercelRequest, res: VercelResponse) => {
  const apiInfo = {
    service: 'Unsaid API',
    version: 'v1.0.0',
    status: 'operational',
    timestamp: new Date().toISOString(),
    documentation: 'https://api.unsaid.com/docs',
    endpoints: {
      health: '/api/v1/health',
      tone_analysis: '/api/v1/tone',
      suggestions: '/api/v1/suggestions',
      communicator: '/api/v1/communicator',
      trial_status: '/api/v1/trial-status',
    },
    features: env.ENABLED_FEATURES.split(','),
    rate_limits: {
      window_ms: 900000, // 15 minutes
      max_requests: 100,
    },
    supported_contexts: [
      'general',
      'romantic', 
      'professional',
      'family',
      'friendship',
      'conflict_resolution'
    ],
    supported_languages: ['en'],
  };
  
  success(res, apiInfo);
};

export default withErrorHandling(
  withLogging(
    withCors(
      withMethods(['GET'], handler)
    )
  )
);
