// Predictive AI Service for Co-Parenting Communication
// This service provides AI-powered predictions for message outcomes

enum AttachmentStyle {
  secure,
  anxious,
  avoidant,
  disorganized,
}

enum CommunicationStyle {
  assertive,
  passive,
  aggressive,
  passiveAggressive,
}

class MessageContext {
  final DateTime timeOfDay;
  final String topic;

  MessageContext({
    required this.timeOfDay,
    required this.topic,
  });
}

class PartnerProfile {
  final List<String> triggers;
  final AttachmentStyle attachmentStyle;
  final CommunicationStyle communicationStyle;

  PartnerProfile({
    required this.triggers,
    required this.attachmentStyle,
    required this.communicationStyle,
  });
}

class ConversationHistory {
  final bool hasRecentConflicts;
  final int length;

  ConversationHistory({
    required this.hasRecentConflicts,
    required this.length,
  });
}

class PredictionResult {
  final String outcome;
  final List<String> risks;
  final List<String> suggestions;
  final double confidence;

  PredictionResult({
    required this.outcome,
    required this.risks,
    required this.suggestions,
    required this.confidence,
  });
}

class ConversationOutcomePrediction {
  final String predictedOutcome;
  final double confidence;
  final List<String> riskFactors;
  final List<String> recommendations;

  ConversationOutcomePrediction({
    required this.predictedOutcome,
    required this.confidence,
    required this.riskFactors,
    required this.recommendations,
  });
}

class PredictiveCoParentingAI {
  PredictiveCoParentingAI();

  Future<PredictionResult> predictMessageOutcome(
    String message, {
    required PartnerProfile partnerProfile,
    required ConversationHistory history,
    required MessageContext context,
  }) async {
    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 1500));

    // Basic analysis based on message content and context
    final messageAnalysis = _analyzeMessage(message, context, partnerProfile);

    return PredictionResult(
      outcome: messageAnalysis['outcome'] as String,
      risks: List<String>.from(messageAnalysis['risks'] as List),
      suggestions: List<String>.from(messageAnalysis['suggestions'] as List),
      confidence: messageAnalysis['confidence'] as double,
    );
  }

  Map<String, dynamic> _analyzeMessage(
    String message,
    MessageContext context,
    PartnerProfile profile,
  ) {
    final messageLower = message.toLowerCase();
    String outcome = 'Neutral';
    List<String> risks = [];
    List<String> suggestions = [];
    double confidence = 0.7;

    // Analyze tone and content
    if (_containsNegativeLanguage(messageLower)) {
      outcome = 'Likely to cause tension';
      confidence = 0.8;
      risks.add('Message may trigger defensive response');
      suggestions.add('Consider rephrasing with more positive language');
      suggestions.add('Focus on collaboration rather than blame');
    } else if (_containsPositiveLanguage(messageLower)) {
      outcome = 'Positive response expected';
      confidence = 0.85;
      suggestions.add('Great approach! This message shows empathy');
    } else if (_isRequestingChange(messageLower)) {
      outcome = 'May require negotiation';
      confidence = 0.75;
      risks.add('Schedule changes can be stressful');
      suggestions.add('Provide alternative options when requesting changes');
      suggestions.add('Acknowledge any inconvenience caused');
    }

    // Factor in partner profile
    if (profile.attachmentStyle == AttachmentStyle.anxious) {
      if (outcome.contains('tension')) {
        risks.add('Partner may need extra reassurance');
        suggestions.add(
            'Include affirming language about your co-parenting relationship');
      }
    } else if (profile.attachmentStyle == AttachmentStyle.avoidant) {
      if (messageLower.contains('we need to talk')) {
        risks.add('Partner may prefer written communication');
        suggestions.add('Be specific about the topic to reduce anxiety');
      }
    }

    // Factor in communication style
    if (profile.communicationStyle == CommunicationStyle.passive) {
      suggestions.add('Be direct but gentle in your approach');
    } else if (profile.communicationStyle == CommunicationStyle.aggressive) {
      if (outcome.contains('tension')) {
        risks.add('May escalate into conflict');
        suggestions.add('Use "I" statements to reduce defensiveness');
      }
    }

    // Factor in context
    if (context.topic == 'Schedule Change' &&
        _containsShortNotice(messageLower)) {
      risks.add('Short notice may cause stress or resentment');
      suggestions.add('Acknowledge the short notice and express appreciation');
    }

    if (context.topic == 'Discipline Discussion') {
      risks.add('Parenting decisions can be emotionally charged');
      suggestions.add('Focus on the child\'s well-being as common ground');
      suggestions
          .add('Share your perspective without criticizing their approach');
    }

    return {
      'outcome': outcome,
      'risks': risks,
      'suggestions': suggestions,
      'confidence': confidence,
    };
  }

  bool _containsNegativeLanguage(String message) {
    final negativeWords = [
      'never',
      'always',
      'wrong',
      'bad',
      'terrible',
      'hate',
      'stupid',
      'ridiculous',
      'impossible',
      'you should',
      'you need to',
      'you have to'
    ];
    return negativeWords.any((word) => message.contains(word));
  }

  bool _containsPositiveLanguage(String message) {
    final positiveWords = [
      'thank',
      'appreciate',
      'understand',
      'together',
      'collaborate',
      'support',
      'help',
      'please',
      'could we',
      'would it be possible'
    ];
    return positiveWords.any((word) => message.contains(word));
  }

  bool _isRequestingChange(String message) {
    final changeIndicators = [
      'change',
      'switch',
      'reschedule',
      'different time',
      'another day',
      'move',
      'adjust',
      'modify'
    ];
    return changeIndicators.any((indicator) => message.contains(indicator));
  }

  bool _containsShortNotice(String message) {
    final shortNoticeIndicators = [
      'today',
      'tomorrow',
      'this evening',
      'right now',
      'immediately',
      'asap',
      'urgent'
    ];
    return shortNoticeIndicators
        .any((indicator) => message.contains(indicator));
  }
}
