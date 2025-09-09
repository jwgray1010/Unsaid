// api/v1/trial-status.ts
import { VercelRequest, VercelResponse } from '@vercel/node';
import { withCors, withMethods, withErrorHandling, withLogging } from '../_lib/wrappers';
import { success } from '../_lib/http';
import { logger } from '../_lib/logger';
import { ensureBoot } from '../_lib/bootstrap';

const bootPromise = ensureBoot();

interface TrialStatus {
  status: 'trial_active' | 'trial_expired' | 'premium';
  daysRemaining: number;
  totalTrialDays: number;
  hasAccess: boolean; // Core access flag - false after trial without payment
  planType: 'trial' | 'premium' | 'expired';
  pricing: {
    monthlyPrice: number;
    currency: string;
    paymentRequired: boolean;
  };
  dailyLimits: Record<string, {
    total: number;
    used: number;
    remaining: number;
  }>;
  features: Record<string, boolean>;
  userId: string;
  userEmail?: string | null;
  trialStartDate: string;
  trialEndDate: string;
  subscriptionStatus?: 'active' | 'canceled' | 'past_due' | null;
  paymentUrl?: string; // URL to initiate payment
  message: string;
  blockingMessage?: string; // Message when access is blocked
}

class TrialManager {
  constructor() {
    // In a real implementation, this would connect to a database
    // For now, using mock data that assumes most users are in trial
  }

  getTrialStatus(userId: string, userEmail?: string | null): TrialStatus {
    // Mock implementation - in production this would check a database
    const currentDate = new Date();
    const trialStartDate = new Date(currentDate.getTime() - (2 * 24 * 60 * 60 * 1000)); // 2 days ago
    const trialEndDate = new Date(trialStartDate.getTime() + (7 * 24 * 60 * 60 * 1000)); // 7 days from start
    const daysUsed = Math.floor((currentDate.getTime() - trialStartDate.getTime()) / (24 * 60 * 60 * 1000));
    const daysRemaining = Math.max(0, 7 - daysUsed);
    
    // Check if user has premium subscription (mock - would check payment processor in production)
    const hasPremiumSubscription = this.checkPremiumStatus(userId, userEmail);
    
    // Determine status and access
    let status: 'trial_active' | 'trial_expired' | 'premium';
    let planType: 'trial' | 'premium' | 'expired';
    let hasAccess: boolean;
    let message: string;
    let blockingMessage: string | undefined;
    
    if (hasPremiumSubscription) {
      status = 'premium';
      planType = 'premium';
      hasAccess = true;
      message = 'Premium subscription active. Full access to all features!';
    } else if (daysRemaining > 0) {
      status = 'trial_active';
      planType = 'trial';
      hasAccess = true;
      message = `Your trial has ${daysRemaining} days remaining. Enjoy full access to all features!`;
    } else {
      status = 'trial_expired';
      planType = 'expired';
      hasAccess = false; // CRITICAL: No access after trial without payment
      message = 'Your 7-day trial has expired.';
      blockingMessage = 'Upgrade to Premium ($3.99/month) to continue using API services.';
    }
    
    // Features available only during trial or with premium subscription
    const features = hasAccess ? {
      'tone-analysis': true,
      'suggestions': true,
      'therapy-advice': true,
      'advanced-analysis': true,
      'personality-integration': true,
      'communication-insights': true,
      'real-time-suggestions': true,
      'attachment-analysis': true
    } : {
      // No features available without payment after trial
      'tone-analysis': false,
      'suggestions': false,
      'therapy-advice': false,
      'advanced-analysis': false,
      'personality-integration': false,
      'communication-insights': false,
      'real-time-suggestions': false,
      'attachment-analysis': false
    };
    
    return {
      status,
      daysRemaining,
      totalTrialDays: 7,
      hasAccess,
      planType,
      pricing: {
        monthlyPrice: 3.99,
        currency: 'USD',
        paymentRequired: !hasAccess && !hasPremiumSubscription
      },
      dailyLimits: hasAccess ? {
        'api_calls': {
          total: 1000, // Generous limit for trial/premium
          used: Math.floor(Math.random() * 100),
          remaining: 1000 - Math.floor(Math.random() * 100)
        },
        'suggestions': {
          total: 50,
          used: Math.floor(Math.random() * 20),
          remaining: 50 - Math.floor(Math.random() * 20)
        }
      } : {
        // Zero limits for expired users
        'api_calls': { total: 0, used: 0, remaining: 0 },
        'suggestions': { total: 0, used: 0, remaining: 0 }
      },
      features,
      userId,
      userEmail,
      trialStartDate: trialStartDate.toISOString(),
      trialEndDate: trialEndDate.toISOString(),
      subscriptionStatus: hasPremiumSubscription ? 'active' : null,
      paymentUrl: !hasAccess ? this.generatePaymentUrl(userId, userEmail) : undefined,
      message,
      blockingMessage
    };
  }

  // Mock premium status check - in production would integrate with Stripe/payment processor
  private checkPremiumStatus(userId: string, userEmail?: string | null): boolean {
    // Mock: For demo purposes, let's say users with email containing "premium" have paid
    // In production, this would check your payment processor (Stripe, etc.)
    if (userEmail && userEmail.includes('premium')) {
      return true;
    }
    // For testing: specific user IDs that have "paid"
    const premiumUsers = ['premium_user', 'paid_user_123', 'subscriber_001'];
    return premiumUsers.includes(userId);
  }

  // Generate payment URL - integrate with your payment processor
  private generatePaymentUrl(userId: string, userEmail?: string | null): string {
    // In production, this would generate a Stripe Checkout URL or similar
    const baseUrl = process.env.VERCEL_URL || 'https://your-app.vercel.app';
    const params = new URLSearchParams({
      userId,
      plan: 'premium',
      price: '3.99',
      currency: 'USD'
    });
    if (userEmail) params.append('email', userEmail);
    
    return `${baseUrl}/payment/checkout?${params.toString()}`;
  }

  checkFeatureAccess(userId: string, feature: string): boolean {
    const status = this.getTrialStatus(userId);
    
    // STRICT ENFORCEMENT: No access to ANY features without payment after trial
    if (!status.hasAccess) {
      logger.warn('Feature access denied - trial expired and no premium subscription', { 
        userId, 
        feature, 
        status: status.status,
        daysRemaining: status.daysRemaining 
      });
      return false;
    }
    
    return status.features[feature] || false;
  }

  // Check if user has any API access at all
  checkApiAccess(userId: string): { hasAccess: boolean; reason?: string; paymentUrl?: string } {
    const status = this.getTrialStatus(userId);
    
    if (!status.hasAccess) {
      return {
        hasAccess: false,
        reason: status.blockingMessage || 'Trial expired. Premium subscription required.',
        paymentUrl: status.paymentUrl
      };
    }
    
    return { hasAccess: true };
  }

  incrementUsage(userId: string, feature: string): boolean {
    // Mock implementation - would update database in production
    logger.info('Usage incremented', { userId, feature });
    return true;
  }
}

function getUserId(req: VercelRequest): string {
  return req.headers['x-user-id'] as string || 'anonymous';
}

const trialManager = new TrialManager();

const handler = async (req: VercelRequest, res: VercelResponse) => {
  await bootPromise;
  const userId = getUserId(req);
  
  try {
    if (req.method === 'GET') {
      // Get trial status
      const userEmail = req.query.email as string || null;
      const status = trialManager.getTrialStatus(userId, userEmail);
      
      logger.info('Trial status retrieved', { 
        userId, 
        status: status.status,
        daysRemaining: status.daysRemaining,
        hasAccess: status.hasAccess,
        planType: status.planType
      });
      
      return success(res, status);
      
    } else if (req.method === 'POST') {
      // Check specific feature access or increment usage
      const { feature, action } = req.body;
      
      if (action === 'check') {
        const hasAccess = trialManager.checkFeatureAccess(userId, feature);
        const status = trialManager.getTrialStatus(userId);
        
        return success(res, { 
          userId,
          feature,
          hasAccess,
          planType: status.planType,
          paymentRequired: status.pricing.paymentRequired,
          paymentUrl: status.paymentUrl,
          message: hasAccess 
            ? 'Feature access granted' 
            : (status.blockingMessage || 'Feature access denied - premium subscription required')
        });
        
      } else if (action === 'increment') {
        // First check if user has access
        const accessCheck = trialManager.checkApiAccess(userId);
        if (!accessCheck.hasAccess) {
          res.status(403).json({
            error: 'Access Denied',
            message: accessCheck.reason,
            paymentUrl: accessCheck.paymentUrl,
            pricing: { monthlyPrice: 3.99, currency: 'USD' }
          });
          return;
        }
        
        const success_increment = trialManager.incrementUsage(userId, feature);
        const updatedStatus = trialManager.getTrialStatus(userId);
        
        return success(res, { 
          userId,
          feature,
          success: success_increment,
          updatedLimits: updatedStatus.dailyLimits,
          message: 'Usage updated successfully'
        });
        
      } else if (action === 'verify-access') {
        // New action to verify overall API access
        const accessCheck = trialManager.checkApiAccess(userId);
        const status = trialManager.getTrialStatus(userId);
        
        if (!accessCheck.hasAccess) {
          res.status(403).json({
            userId,
            hasAccess: false,
            reason: accessCheck.reason,
            paymentUrl: accessCheck.paymentUrl,
            pricing: status.pricing,
            trialInfo: {
              daysRemaining: status.daysRemaining,
              trialEndDate: status.trialEndDate
            }
          });
          return;
        }
        
        success(res, {
          userId,
          hasAccess: true,
          planType: status.planType,
          message: 'API access granted'
        });
        
      } else {
        throw new Error('Invalid action. Use "check", "increment", or "verify-access"');
      }
    }
  } catch (error) {
    logger.error('Trial status error:', error);
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
