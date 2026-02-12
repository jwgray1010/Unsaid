export type LiveMultimodalMetrics = {
  elapsedSeconds: number;
  sampleCount: number;
  speakingRatio: number;
  avgVolume: number;
  highVolumeRatio: number;
  facePresenceRatio: number | null;
  centeredFaceRatio: number | null;
  motionScore: number;
};

export function buildLiveFeedback(params: {
  metrics: LiveMultimodalMetrics;
  faceDetectionAvailable: boolean;
}): string[] {
  const { metrics, faceDetectionAvailable } = params;

  if (metrics.elapsedSeconds < 20 || metrics.sampleCount < 8) {
    return [
      "Warming up... keep talking naturally for 20-30 seconds to get stable feedback.",
      "Aim for calm pacing and short pauses after each thought.",
    ];
  }

  const tips: string[] = [];

  if (metrics.speakingRatio < 0.35) {
    tips.push("You may be under-speaking. Add a bit more context so the conversation has momentum.");
  } else if (metrics.speakingRatio > 0.75) {
    tips.push("You may be over-talking. Pause briefly after key points to invite reciprocity.");
  }

  if (metrics.highVolumeRatio > 0.22) {
    tips.push("Volume spikes are frequent. Slow your breath and soften emphasis to sound more grounded.");
  }

  if (faceDetectionAvailable && metrics.facePresenceRatio !== null && metrics.facePresenceRatio < 0.75) {
    tips.push("Your face is often out of frame. Keep your head and shoulders visible for stronger presence.");
  }

  if (faceDetectionAvailable && metrics.centeredFaceRatio !== null && metrics.centeredFaceRatio < 0.6) {
    tips.push("You drift off-center frequently. Re-center to appear more attentive and connected.");
  }

  if (metrics.motionScore > 0.18) {
    tips.push("Detected elevated movement/fidgeting. Ground your posture and reduce rapid movement.");
  }

  if (tips.length === 0) {
    tips.push("Nice balance so far. Keep this pace and maintain warm eye-level presence.");
    tips.push("Try one curious follow-up question after each personal share.");
  }

  return tips.slice(0, 4);
}
