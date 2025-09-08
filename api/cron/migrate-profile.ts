// api/cron/migrate-profile.ts
import { VercelRequest, VercelResponse } from '@vercel/node';
import { withCors, withMethods, withErrorHandling, withLogging } from '../_lib/wrappers';
import { success } from '../_lib/http';
import { CommunicatorProfile } from '../_lib/services/communicatorProfile';
import { logger } from '../_lib/logger';

interface MigrationResult {
  userId: string;
  migrated: boolean;
  previousVersion?: string;
  currentVersion: string;
  changes: string[];
  errors: string[];
}

interface ProfileMigrationReport {
  timestamp: string;
  totalProfiles: number;
  migratedProfiles: number;
  failedProfiles: number;
  results: MigrationResult[];
  overallStatus: 'success' | 'partial' | 'failed';
}

const handler = async (req: VercelRequest, res: VercelResponse) => {
  const startTime = Date.now();
  
  try {
    logger.info('Starting profile migration cron job');
    
    // Mock user IDs for migration (in production, this would come from a database)
    const userIds = [
      'user_001', 'user_002', 'user_003', 'user_004', 'user_005',
      'test_user', 'demo_user', 'anonymous'
    ];
    
    const results: MigrationResult[] = [];
    
    for (const userId of userIds) {
      try {
        const profile = new CommunicatorProfile({ userId });
        await profile.init();
        
        // Check if profile needs migration
        const attachmentEstimate = profile.getAttachmentEstimate();
        const changes: string[] = [];
        
        // Mock migration logic - in production, this would check version compatibility
        let needsMigration = false;
        
        // Example migration scenarios
        if (!attachmentEstimate.windowComplete) {
          changes.push('Initialized attachment analysis window');
          needsMigration = true;
        }
        
        if (attachmentEstimate.confidence < 0.5) {
          changes.push('Updated confidence calculation algorithm');
          needsMigration = true;
        }
        
        // Simulate data structure updates
        if (Math.random() > 0.7) { // Random migration need for demo
          changes.push('Updated learning signals format');
          changes.push('Migrated communication history structure');
          needsMigration = true;
        }
        
        results.push({
          userId,
          migrated: needsMigration,
          previousVersion: needsMigration ? '1.0.0' : '2.0.0',
          currentVersion: '2.0.0',
          changes,
          errors: []
        });
        
        if (needsMigration) {
          logger.info('Profile migrated', { userId, changes });
        }
        
      } catch (error) {
        results.push({
          userId,
          migrated: false,
          currentVersion: '2.0.0',
          changes: [],
          errors: [`Migration failed: ${error instanceof Error ? error.message : 'Unknown error'}`]
        });
        
        logger.error('Profile migration failed', { userId, error });
      }
    }
    
    const migratedProfiles = results.filter(r => r.migrated).length;
    const failedProfiles = results.filter(r => r.errors.length > 0).length;
    const totalProfiles = results.length;
    
    let overallStatus: 'success' | 'partial' | 'failed' = 'success';
    if (failedProfiles > 0) {
      overallStatus = failedProfiles > totalProfiles * 0.5 ? 'failed' : 'partial';
    }
    
    const report: ProfileMigrationReport = {
      timestamp: new Date().toISOString(),
      totalProfiles,
      migratedProfiles,
      failedProfiles,
      results,
      overallStatus
    };
    
    const processingTime = Date.now() - startTime;
    
    logger.info('Profile migration completed', {
      processingTime,
      totalProfiles,
      migratedProfiles,
      failedProfiles,
      status: overallStatus
    });
    
    success(res, {
      report,
      metadata: {
        processingTimeMs: processingTime,
        cronJob: 'migrate-profile',
        version: '1.0.0'
      }
    });
    
  } catch (error) {
    logger.error('Profile migration cron job failed:', error);
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
