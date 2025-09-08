// api/_lib/middleware/trialGuard.ts
/**
 * Trial Guard Middleware
 * Enforces 7-day trial + $3.99 premium payment requirement for API access
 */

import { VercelRequest, VercelResponse } from '@vercel/node';
import { logger } from '../logger';

interface TrialGuardConfig {
  allowAnonymous?: boolean;
  feature?: string;
  bypassUsers?: string[]; // Users who bypass payment (for testing)
}

class TrialManager {
  checkApiAccess(userId: string): { hasAccess: boolean; reason?: string; paymentUrl?: string } {
    // Mock premium status check
    const hasPremiumSubscription = this.checkPremiumStatus(userId);
    const trialStatus = this.getTrialStatus(userId);
    
    if (hasPremiumSubscription || trialStatus.daysRemaining > 0) {
      return { hasAccess: true };
    }
    
    return {
      hasAccess: false,
      reason: 'Trial expired. Premium subscription ($3.99/month) required.',
      paymentUrl: this.generatePaymentUrl(userId)
    };
  }

  private checkPremiumStatus(userId: string): boolean {
    // Test users with premium access
    const premiumUsers = ['premium_user', 'paid_user_123', 'subscriber_001'];
    return premiumUsers.includes(userId);
  }

  private getTrialStatus(userId: string) {
    const currentDate = new Date();
    const trialStartDate = new Date(currentDate.getTime() - (2 * 24 * 60 * 60 * 1000)); // 2 days ago
    const daysUsed = Math.floor((currentDate.getTime() - trialStartDate.getTime()) / (24 * 60 * 60 * 1000));
    const daysRemaining = Math.max(0, 7 - daysUsed);
    
    return { daysRemaining };
  }

  private generatePaymentUrl(userId: string): string {
    const baseUrl = process.env.VERCEL_URL || 'https://your-app.vercel.app';
    return `${baseUrl}/payment/checkout?userId=${userId}&plan=premium&price=3.99`;
  }
}

const trialManager = new TrialManager();

/**
 * Middleware to enforce trial/payment requirements
 * Usage: Apply to any API endpoint that requires payment after trial
 */
export function withTrialGuard(config: TrialGuardConfig = {}) {
  return function(handler: (req: VercelRequest, res: VercelResponse) => Promise<void>) {
    return async function(req: VercelRequest, res: VercelResponse) {
      const userId = req.headers['x-user-id'] as string || 
                    req.query.userId as string || 
                    'anonymous';

      // Allow bypass for specific users (testing)
      if (config.bypassUsers?.includes(userId)) {
        return handler(req, res);
      }

      // Check if anonymous users are allowed
      if (userId === 'anonymous' && !config.allowAnonymous) {
        res.status(401).json({
          error: 'Authentication Required',
          message: 'User ID required for API access',
          code: 'AUTH_REQUIRED'
        });
        return;
      }

      // Check trial/payment status
      const accessCheck = trialManager.checkApiAccess(userId);
      
      if (!accessCheck.hasAccess) {
        logger.warn('API access denied - trial expired, payment required', { 
          userId, 
          endpoint: req.url,
          feature: config.feature 
        });
        
        res.status(402).json({ // 402 Payment Required
          error: 'Payment Required',
          message: accessCheck.reason,
          paymentUrl: accessCheck.paymentUrl,
          pricing: {
            monthlyPrice: 3.99,
            currency: 'USD'
          },
          trialInfo: {
            message: 'Your 7-day free trial has expired',
            upgradeRequired: true
          },
          code: 'TRIAL_EXPIRED'
        });
        return;
      }

      // Access granted - continue to handler
      logger.info('API access granted', { 
        userId, 
        endpoint: req.url,
        feature: config.feature 
      });
      
      return handler(req, res);
    };
  };
}

// Specific middleware for different API types
export const withSuggestionsGuard = withTrialGuard({ 
  feature: 'suggestions',
  allowAnonymous: false 
});

export const withToneAnalysisGuard = withTrialGuard({ 
  feature: 'tone-analysis',
  allowAnonymous: false 
});

export const withCommunicatorGuard = withTrialGuard({ 
  feature: 'communicator-profile',
  allowAnonymous: false 
});

export const withAdvancedAnalysisGuard = withTrialGuard({ 
  feature: 'advanced-analysis',
  allowAnonymous: false 
});

export default { withTrialGuard, withSuggestionsGuard, withToneAnalysisGuard, withCommunicatorGuard, withAdvancedAnalysisGuard };
