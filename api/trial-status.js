// Trial Status API endpoint
// Simple TrialManager implementation for serverless environment
class TrialManager {
  constructor() {
    // In a real implementation, this would connect to a database
    // For now, using mock data that assumes most users are in trial
  }

  getTrialStatus(userId, userEmail = null) {
    // Mock implementation - in production this would check a database
    return {
      status: 'trial_active',
      daysRemaining: 5,
      totalTrialDays: 7,
      features: {
        'tone-analysis': true,
        'suggestions': true,
        'spell-check': true,
        'openai-secure-fix': true
      },
      isActive: true,
      hasAccess: true
    };
  }

  startTrial(userId) {
    // Mock implementation - would create trial record in database
    return true;
  }

  hasAccess(userId, feature) {
    const status = this.getTrialStatus(userId);
    return status.features[feature] || false;
  }
}

export default async function handler(req, res) {
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
          freeFeatures: ['tone-analysis'],
          premiumFeatures: ['openai-secure-fix', 'spell-check', 'suggestions'],
          trialDuration: '7 days'
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
