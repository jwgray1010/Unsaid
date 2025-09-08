// api/_lib/services/communicatorProfile.ts
import { logger } from '../logger';
import { dataLoader } from './dataLoader';
import { normalizeScores, defaultPriorWeight } from '../utils/priors';

export interface AttachmentEstimate {
  primary: 'anxious' | 'avoidant' | 'disorganized' | 'secure' | null;
  secondary: string | null;
  windowComplete: boolean;
  confidence: number;
}

export interface ProfileData {
  userId: string;
  attachmentStyle?: string;
  communicationHistory: Array<{
    text: string;
    context: string;
    tone: string;
    timestamp: Date;
  }>;
  learningSignals: Record<string, any>;
  preferences: {
    contexts: string[];
    suggestionTypes: string[];
    sensitivity: number;
  };
}

export class CommunicatorProfile {
  private userId: string;
  private data: ProfileData;

  constructor(options: { 
    userId: string; 
    storage?: any; 
  }) {
    this.userId = options.userId;
    this.data = {
      userId: this.userId,
      communicationHistory: [],
      learningSignals: {},
      preferences: {
        contexts: ['general'],
        suggestionTypes: ['advice', 'empathy'],
        sensitivity: 0.5
      }
    };
  }

  async init(): Promise<void> {
    try {
      // DataLoader is now pre-initialized synchronously
      if (!dataLoader.isInitialized()) {
        logger.warn('DataLoader not initialized in CommunicatorProfile');
        return;
      }

      // Load learning signals from dataLoader
      const learningSignalsData = dataLoader.getLearningSignals();
      const learningSignals = learningSignalsData?.signals || [];
      
      this.data.learningSignals = learningSignals.reduce((acc, signal) => {
        acc[signal.signalType] = signal;
        return acc;
      }, {} as Record<string, any>);

      logger.info('CommunicatorProfile initialized', { 
        userId: this.userId,
        hasLearningSignals: Object.keys(this.data.learningSignals).length > 0,
        signalCount: learningSignals.length
      });
    } catch (error) {
      logger.error('Failed to initialize CommunicatorProfile:', error);
      throw error;
    }
  }

  getAttachmentEstimate(): AttachmentEstimate {
    const attachmentLearning = dataLoader.getAttachmentLearning();
    if (!attachmentLearning) {
      throw new Error('attachment_learning.json is required (no fallback)');
    }

    const thresholds = attachmentLearning.scoring?.thresholds;
    if (!thresholds) {
      throw new Error('attachment_learning.json missing scoring.thresholds');
    }

    const daysObserved = Number((this.data.learningSignals as any).daysObserved || 0);
    const learningDays = attachmentLearning.learningDays || 7;

    // Server signals raw extraction
    const s: any = this.data.learningSignals || {};
    const totalSignals = (Number(s.anxious)||0)+(Number(s.avoidant)||0)+(Number(s.disorganized)||0)+(Number(s.secure)||0);

    // If nothing at all and no prior → empty estimate
    // (Prior seeding happens externally; we just consume)
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const localPrior: any = (this as any).data.localPrior; // tolerate absence
    if (totalSignals < 1e-9 && !localPrior) {
      return { primary: null, secondary: null, windowComplete: false, confidence: 0 };
    }

    const serverNorm = normalizeScores({
      anxious: Number(s.anxious)||0,
      avoidant: Number(s.avoidant)||0,
      disorganized: Number(s.disorganized)||0,
      secure: Number(s.secure)||0,
    });

    const priorScores = localPrior?.scores ? normalizeScores(localPrior.scores) : null;
    const wPrior = priorScores ? defaultPriorWeight(daysObserved, learningDays) : 0;
    const wServer = 1 - wPrior;

    const combined = normalizeScores({
      anxious: (priorScores?.anxious||0)*wPrior + serverNorm.anxious*wServer,
      avoidant: (priorScores?.avoidant||0)*wPrior + serverNorm.avoidant*wServer,
      disorganized: (priorScores?.disorganized||0)*wPrior + serverNorm.disorganized*wServer,
      secure: (priorScores?.secure||0)*wPrior + serverNorm.secure*wServer,
    });

  const ranked = (Object.entries(combined) as Array<[string, number]>).sort((a,b)=> b[1]-a[1]);
  const [primaryStyle, primaryScore] = ranked[0];
  const [secondaryStyle, secondaryScore] = ranked[1];

  const primary = primaryScore >= (thresholds.primary as number) ? primaryStyle as AttachmentEstimate['primary'] : null;
  const secondary = primary && secondaryScore >= (thresholds.secondary as number) ? secondaryStyle : null;

  const distance = Math.max(0, (primaryScore as number) - (secondaryScore as number));
    const progress = Math.max(0, Math.min(1, daysObserved / learningDays));
    const confidence = Math.max(0, Math.min(1, 0.25 * distance + 0.75 * progress));

    return {
      primary,
      secondary,
      windowComplete: daysObserved >= learningDays,
      confidence,
    };
  }

  addCommunication(text: string, context: string, tone: string): void {
    this.data.communicationHistory.push({
      text,
      context,
      tone,
      timestamp: new Date()
    });

    // Keep only last 50 communications
    if (this.data.communicationHistory.length > 50) {
      this.data.communicationHistory = this.data.communicationHistory.slice(-50);
    }
  }

  getLearningSignals(): Record<string, any> {
    return this.data.learningSignals;
  }

  getPreferences(): ProfileData['preferences'] {
    return this.data.preferences;
  }

  updatePreferences(updates: Partial<ProfileData['preferences']>): void {
    this.data.preferences = { ...this.data.preferences, ...updates };
  }
}
