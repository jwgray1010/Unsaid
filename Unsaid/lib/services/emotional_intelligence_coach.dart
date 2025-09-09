// Emotional Intelligence Coach Service
// This service provides emotional analysis and coaching suggestions

class EmotionalStateAnalysis {
  final String primaryEmotion;
  final double intensity;
  final List<String> regulationSuggestions;
  final String emotionalContext;

  EmotionalStateAnalysis({
    required this.primaryEmotion,
    required this.intensity,
    required this.regulationSuggestions,
    required this.emotionalContext,
  });
}

class EmotionalIntelligenceCoach {
  EmotionalIntelligenceCoach();

  Future<EmotionalStateAnalysis> analyzeEmotionalState(
    String message, [
    List<String>? context,
  ]) async {
    // Simulate processing
    await Future.delayed(const Duration(milliseconds: 300));

    final messageLower = message.toLowerCase();

    String primaryEmotion = 'neutral';
    double intensity = 0.5;
    List<String> suggestions = [];
    String context = 'general communication';

    // Analyze emotional markers
    if (_hasAngerMarkers(messageLower)) {
      primaryEmotion = 'frustration';
      intensity = 0.8;
      context = 'potentially heated discussion';
      suggestions.addAll([
        'Take a deep breath before responding',
        'Focus on the issue, not the person',
        'Use "I" statements to express feelings'
      ]);
    } else if (_hasAnxietyMarkers(messageLower)) {
      primaryEmotion = 'anxiety';
      intensity = 0.7;
      context = 'concern about situation';
      suggestions.addAll([
        'Ground yourself by focusing on facts',
        'Consider what you can control',
        'Communicate your specific concerns clearly'
      ]);
    } else if (_hasPositiveMarkers(messageLower)) {
      primaryEmotion = 'appreciation';
      intensity = 0.6;
      context = 'positive interaction';
      suggestions.add('Great emotional awareness and expression!');
    } else if (_hasSadnessMarkers(messageLower)) {
      primaryEmotion = 'disappointment';
      intensity = 0.6;
      context = 'processing difficult emotions';
      suggestions.addAll([
        'It\'s okay to feel disappointed',
        'Focus on solutions moving forward',
        'Express your needs clearly and calmly'
      ]);
    } else {
      suggestions.addAll([
        'Stay aware of your emotional state',
        'Check in with yourself before responding'
      ]);
    }

    return EmotionalStateAnalysis(
      primaryEmotion: primaryEmotion,
      intensity: intensity,
      regulationSuggestions: suggestions,
      emotionalContext: context,
    );
  }

  bool _hasAngerMarkers(String message) {
    final angerWords = [
      'frustrated',
      'angry',
      'mad',
      'upset',
      'ridiculous',
      'unfair',
      'can\'t believe',
      'fed up',
      'sick of'
    ];
    return angerWords.any((word) => message.contains(word));
  }

  bool _hasAnxietyMarkers(String message) {
    final anxietyWords = [
      'worried',
      'concerned',
      'nervous',
      'anxious',
      'what if',
      'afraid',
      'scared',
      'uncertain'
    ];
    return anxietyWords.any((word) => message.contains(word));
  }

  bool _hasPositiveMarkers(String message) {
    final positiveWords = [
      'thank',
      'appreciate',
      'grateful',
      'happy',
      'pleased',
      'glad',
      'excited',
      'love'
    ];
    return positiveWords.any((word) => message.contains(word));
  }

  bool _hasSadnessMarkers(String message) {
    final sadnessWords = [
      'sad',
      'disappointed',
      'hurt',
      'lonely',
      'miss',
      'difficult',
      'hard',
      'struggling'
    ];
    return sadnessWords.any((word) => message.contains(word));
  }
}
