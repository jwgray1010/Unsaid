// Co-Parenting AI Service
// This service provides AI analysis for co-parenting communication

enum AttachmentStyle {
  secure,
  anxious,
  avoidant,
  disorganized,
}

enum CommunicationStyle {
  direct,
  gentle,
  analytical,
  empathetic,
  avoidant,
  assertive,
}

enum CoParentingTopic {
  communication,
  scheduling,
  discipline,
  financial,
  medical,
  educational,
  general,
}

enum RelationshipStage {
  married,
  separated,
  divorced,
  neverMarried,
}

enum CommunicationFrequency {
  daily,
  weekly,
  normal,
  minimal,
  asNeeded,
}

class UserProfile {
  final String userId;
  final AttachmentStyle attachmentStyle;
  final CommunicationStyle communicationStyle;
  final List<String> triggers;
  final double? stressLevel;

  UserProfile({
    required this.userId,
    required this.attachmentStyle,
    required this.communicationStyle,
    required this.triggers,
    this.stressLevel,
  });
}

class PartnerProfile {
  final AttachmentStyle attachmentStyle;
  final CommunicationStyle communicationStyle;
  final List<String> triggers;
  final List<String>? knownTriggers;

  PartnerProfile({
    required this.attachmentStyle,
    required this.communicationStyle,
    required this.triggers,
    this.knownTriggers,
  });
}

class CoParentingContext {
  final CoParentingTopic topic;
  final DateTime timeOfDay;
  final RelationshipStage relationshipStage;
  final CommunicationFrequency communicationFrequency;
  final int? childAge;
  final double? emotionalStressLevel;
  final int? recentConflicts;
  final bool? isUrgent;

  CoParentingContext({
    required this.topic,
    required this.timeOfDay,
    required this.relationshipStage,
    required this.communicationFrequency,
    this.childAge,
    this.emotionalStressLevel,
    this.recentConflicts,
    this.isUrgent,
  });
}

class CoParentingAnalysis {
  final String communicationPattern;
  final List<String> suggestions;
  final double effectiveness;
  final String tone;

  CoParentingAnalysis({
    required this.communicationPattern,
    required this.suggestions,
    required this.effectiveness,
    required this.tone,
  });
}

class CoParentingAIService {
  CoParentingAIService();

  Future<CoParentingAnalysis> analyzeMessage(
    String message, {
    UserProfile? userProfile,
    PartnerProfile? partnerProfile,
    CoParentingContext? context,
  }) async {
    // Simulate processing
    await Future.delayed(const Duration(milliseconds: 500));

    final messageLower = message.toLowerCase();

    // Basic analysis
    String pattern = 'neutral';
    double effectiveness = 0.7;
    List<String> suggestions = [];
    String tone = 'neutral';

    if (_isCollaborative(messageLower)) {
      pattern = 'collaborative';
      effectiveness = 0.9;
      tone = 'positive';
      suggestions.add('Great collaborative approach!');
    } else if (_isAssertive(messageLower)) {
      pattern = 'assertive';
      effectiveness = 0.8;
      tone = 'firm but respectful';
      suggestions.add('Good use of assertive communication');
    } else if (_hasConflictMarkers(messageLower)) {
      pattern = 'potentially confrontational';
      effectiveness = 0.4;
      tone = 'tense';
      suggestions.add('Consider softening the language');
      suggestions.add('Focus on the child\'s needs');
    } else {
      suggestions.add('Consider being more specific about your needs');
    }

    return CoParentingAnalysis(
      communicationPattern: pattern,
      suggestions: suggestions,
      effectiveness: effectiveness,
      tone: tone,
    );
  }

  // Alias method for backward compatibility
  Future<CoParentingAnalysis> analyzeCoParentingMessage(
    String message, {
    UserProfile? userProfile,
    PartnerProfile? partnerProfile,
    CoParentingContext? context,
  }) async {
    return analyzeMessage(
      message,
      userProfile: userProfile,
      partnerProfile: partnerProfile,
      context: context,
    );
  }

  bool _isCollaborative(String message) {
    final collaborativeWords = [
      'together',
      'both',
      'we can',
      'let\'s',
      'what do you think',
      'would you be okay with',
      'how about'
    ];
    return collaborativeWords.any((word) => message.contains(word));
  }

  bool _isAssertive(String message) {
    final assertiveWords = [
      'i need',
      'i would like',
      'it\'s important',
      'i prefer',
      'i feel',
      'my perspective'
    ];
    return assertiveWords.any((word) => message.contains(word));
  }

  bool _hasConflictMarkers(String message) {
    final conflictWords = [
      'you always',
      'you never',
      'that\'s wrong',
      'you should',
      'ridiculous',
      'impossible',
      'terrible'
    ];
    return conflictWords.any((word) => message.contains(word));
  }
}

// Legacy class for backward compatibility
class CoParentingAI extends CoParentingAIService {
  CoParentingAI() : super();
}
