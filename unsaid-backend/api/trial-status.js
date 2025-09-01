// Trial Status API endpoint
// Simple TrialManager implementation for serverless environment
class TrialManager {
  constructor() {
    // In a real implementation, this would connect to a database
    // For now, using mock data that assumes most users are in trial
  }

  getTrialStatus(userId, userEmail = null) {
    // Mock implementation - in production this would check a database
    const currentDate = new Date();
    const trialStartDate = new Date(currentDate.getTime() - (2 * 24 * 60 * 60 * 1000)); // 2 days ago
    const daysUsed = Math.floor((currentDate - trialStartDate) / (24 * 60 * 60 * 1000));
    const daysRemaining = Math.max(0, 7 - daysUsed);
    
    return {
      status: daysRemaining > 0 ? 'trial_active' : 'trial_expired',
      daysRemaining: daysRemaining,
      totalTrialDays: 7,
      dailyLimits: {
        'secure_quick_fixes': {
          total: 10,
          used: Math.floor(Math.random() * 8), // Mock usage
          remaining: 10 - Math.floor(Math.random() * 8)
        }
      },
      features: {
        'tone-analysis': true,
        'therapy-advice': true, // Unlimited during trial
        'secure-quick-fixes': daysRemaining > 0 ? true : false, // Limited to 10/day
        'premium-insights': daysRemaining > 0 ? false : false, // Premium only
        'advanced-analytics': daysRemaining > 0 ? false : false // Premium only
      },
      isActive: daysRemaining > 0,
      hasAccess: true,
      trialStartDate: trialStartDate.toISOString(),
      pricing: {
        monthlyPrice: 2.99,
        currency: 'USD'
      }
    };
  }

  startTrial(userId) {
    // Mock implementation - would create trial record in database
    return true;
  }

  hasAccess(userId, feature) {
    const status = this.getTrialStatus(userId);
    
    // Check daily limits for secure quick fixes
    if (feature === 'secure-quick-fixes') {
      if (status.status === 'trial_active') {
        return status.dailyLimits.secure_quick_fixes.remaining > 0;
      }
      return false; // Require premium after trial
    }
    
    // Therapy advice is always available during trial
    if (feature === 'therapy-advice') {
      return status.status === 'trial_active';
    }
    
    // Tone analysis available during trial
    if (feature === 'tone-analysis') {
      return status.status === 'trial_active';
    }
    
    return status.features[feature] || false;
  }

  decrementDailyUsage(userId, feature) {
    // Mock implementation - in production would update database
    // This would decrement the daily usage count for features like secure-quick-fixes
    if (feature === 'secure-quick-fixes') {
      return true; // Mock success
    }
    return false;
  }

  resetDailyLimits(userId) {
    // Mock implementation - in production would reset daily counters
    return true;
  }
}

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
    // Get trial status for user
    try {
      const { userId = 'anonymous', userEmail = null } = req.query;
      const trialManager = new TrialManager();
      const trialStatus = trialManager.getTrialStatus(userId, userEmail);
      
      res.json({
        success: true,
        userId: userId,
        trial: trialStatus,
        pricing: {
          freeFeatures: ['tone-analysis', 'therapy-advice'],
          premiumFeatures: ['unlimited-secure-quick-fixes', 'premium-insights', 'advanced-analytics'],
          trialFeatures: ['tone-analysis', 'therapy-advice', 'limited-secure-quick-fixes'],
          trialDuration: '7 days',
          monthlyPrice: 2.99,
          currency: 'USD',
          dailyLimits: {
            'secure-quick-fixes': 10
          }
        },
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      console.error('Trial Status Error:', error.message);
      res.status(500).json({
        error: {
          code: 'TRIAL_STATUS_ERROR',
          message: error.message
        }
      });
    }
    return;
  }
    if (req.method === 'POST') {
    // Start trial for user (if needed)
    try {
      const { userId = 'anonymous', userEmail = null } = req.body;
      const trialManager = new TrialManager();
      
      // Check current status
      const currentStatus = trialManager.getTrialStatus(userId, userEmail);
      
      if (currentStatus.status === 'new_user') {
        // Start trial
        trialManager.startTrial(userId);
        const newStatus = trialManager.getTrialStatus(userId, userEmail);
        
        res.json({
          success: true,
          message: 'Trial started successfully',
          userId: userId,
          trial: newStatus,
          timestamp: new Date().toISOString()
        });
      } else {
        res.json({
          success: true,
          message: 'User already has trial status',
          userId: userId,
          trial: currentStatus,
          timestamp: new Date().toISOString()
        });
      }
    } catch (error) {
      console.error('Start Trial Error:', error.message);
      res.status(500).json({
        error: {
          code: 'START_TRIAL_ERROR',
          message: error.message
        }
      });
    }
    return;
  }

  res.status(405).json({
    error: {
      code: 'METHOD_NOT_ALLOWED',
      message: 'Only GET, POST, and OPTIONS methods are allowed'
    }
  });
}
