import 'package:flutter/material.dart';
import 'keyboard_manager.dart';

/// Service for generating relationship insights from historical analysis data
class RelationshipInsightsService extends ChangeNotifier {
  static final RelationshipInsightsService _instance =
      RelationshipInsightsService._internal();
  factory RelationshipInsightsService() => _instance;
  RelationshipInsightsService._internal();

  final KeyboardManager _keyboardManager = KeyboardManager();

  /// Generate comprehensive relationship insights from historical data
  Future<Map<String, dynamic>> generateRelationshipInsights() async {
    try {
      final analysisHistory = _keyboardManager.analysisHistory;

      if (analysisHistory.isEmpty) {
        return _generateMockInsights(); // Fallback to mock data if no history
      }

      return await _analyzeHistoricalData(analysisHistory);
    } catch (e) {
      print('Error generating relationship insights: $e');
      return _generateMockInsights();
    }
  }

  /// Analyze historical conversation data to generate insights
  Future<Map<String, dynamic>> _analyzeHistoricalData(
    List<Map<String, dynamic>> history,
  ) async {
    final insights = <String, dynamic>{};

    // Calculate compatibility score based on historical data
    insights['compatibility_score'] = _calculateCompatibilityScore(history);

    // Analyze communication trends
    insights['communication_trend'] = _analyzeCommunicationTrend(history);

    // Count weekly messages
    insights['weekly_messages'] = _countWeeklyMessages(history);

    // Calculate positive sentiment
    insights['positive_sentiment'] = _calculatePositiveSentiment(history);

    // Extract growth areas from AI suggestions
    insights['growth_areas'] = _extractGrowthAreas(history);

    // Identify relationship strengths
    insights['strengths'] = _identifyStrengths(history);

    // Generate weekly analysis chart data
    insights['weekly_analysis'] = _generateWeeklyAnalysis(history);

    // Extract attachment and communication styles
    final styles = _extractStyles(history);
    insights['your_style'] = styles['your_attachment'];
    insights['partner_style'] = styles['partner_attachment'];
    insights['your_comm'] = styles['your_communication'];
    insights['partner_comm'] = styles['partner_communication'];

    // Generate AI recommendations based on patterns
    insights['ai_recommendations'] = _generateAIRecommendations(history);

    return insights;
  }

  /// Calculate compatibility score from historical analysis
  double _calculateCompatibilityScore(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return 0.87; // Default fallback

    double totalScore = 0.0;
    int validEntries = 0;

    for (final entry in history) {
      double entryScore = 0.0;
      int factors = 0;

      // Factor in co-parenting analysis scores
      if (entry['coparenting_analysis'] != null) {
        final coParenting = entry['coparenting_analysis'];
        if (coParenting['child_focus_score'] != null) {
          entryScore += coParenting['child_focus_score'];
          factors++;
        }
        if (coParenting['emotional_regulation_score'] != null) {
          entryScore += coParenting['emotional_regulation_score'];
          factors++;
        }
        if (coParenting['constructiveness_score'] != null) {
          entryScore += coParenting['constructiveness_score'];
          factors++;
        }
      }

      // Factor in tone analysis scores
      if (entry['tone_analysis'] != null) {
        final toneAnalysis = entry['tone_analysis'];
        if (toneAnalysis['empathy_score'] != null) {
          entryScore += toneAnalysis['empathy_score'];
          factors++;
        }
        if (toneAnalysis['clarity_score'] != null) {
          entryScore += toneAnalysis['clarity_score'];
          factors++;
        }
      }

      // Factor in predictive analysis success probability
      if (entry['predictive_analysis'] != null) {
        final predictive = entry['predictive_analysis'];
        if (predictive['success_probability'] != null) {
          entryScore += predictive['success_probability'];
          factors++;
        }
      }

      if (factors > 0) {
        totalScore += entryScore / factors;
        validEntries++;
      }
    }

    return validEntries > 0
        ? (totalScore / validEntries).clamp(0.0, 1.0)
        : 0.87;
  }

  /// Analyze communication trend from historical data
  String _analyzeCommunicationTrend(List<Map<String, dynamic>> history) {
    if (history.length < 2) return 'improving';

    final recentEntries = history.length > 10
        ? history.sublist(history.length - 10).cast<Map<String, dynamic>>()
        : history.cast<Map<String, dynamic>>();
    final olderEntries = history.length > 10
        ? history.sublist(0, history.length - 10)
        : [];

    if (olderEntries.isEmpty) return 'steady';

    double recentAvg = _calculateAverageScore(recentEntries);
    double olderAvg = _calculateAverageScore(olderEntries.cast<Map<String, dynamic>>());

    if (recentAvg > olderAvg + 0.1) return 'improving';
    if (recentAvg < olderAvg - 0.1) return 'declining';
    return 'steady';
  }

  /// Count messages from the past week
  int _countWeeklyMessages(List<Map<String, dynamic>> history) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return history.where((entry) {
      if (entry['timestamp'] == null) return false;
      final timestamp = DateTime.tryParse(entry['timestamp']);
      return timestamp != null && timestamp.isAfter(weekAgo);
    }).length;
  }

  /// Calculate positive sentiment from tone analysis
  double _calculatePositiveSentiment(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return 0.84;

    double totalSentiment = 0.0;
    int validEntries = 0;

    for (final entry in history) {
      if (entry['tone_analysis'] != null) {
        final toneAnalysis = entry['tone_analysis'];

        // Look for positive emotional indicators
        if (toneAnalysis['emotional_indicators'] != null) {
          final indicators =
              toneAnalysis['emotional_indicators'] as List<dynamic>;
          double positiveScore = 0.0;

          for (final indicator in indicators) {
            if (indicator is String) {
              if (_isPositiveIndicator(indicator)) {
                positiveScore += 0.2;
              }
            }
          }

          totalSentiment += positiveScore.clamp(0.0, 1.0);
          validEntries++;
        }
      }
    }

    return validEntries > 0
        ? (totalSentiment / validEntries).clamp(0.0, 1.0)
        : 0.84;
  }

  /// Extract growth areas from AI suggestions
  List<String> _extractGrowthAreas(List<Map<String, dynamic>> history) {
    final growthAreas = <String>{};

    for (final entry in history) {
      if (entry['integrated_suggestions'] != null) {
        final suggestions = entry['integrated_suggestions'] as List<dynamic>;
        for (final suggestion in suggestions) {
          if (suggestion is Map<String, dynamic>) {
            final title = suggestion['title'] as String?;
            if (title != null) {
              growthAreas.add(_extractGrowthArea(title));
            }
          }
        }
      }
    }

    final result = growthAreas.toList();
    if (result.isEmpty) {
      return [
        'Active listening',
        'Expressing needs clearly',
        'Managing stress together',
      ];
    }

    return result.take(3).toList();
  }

  /// Identify relationship strengths from positive patterns
  List<String> _identifyStrengths(List<Map<String, dynamic>> history) {
    final strengths = <String>{};

    for (final entry in history) {
      if (entry['coparenting_analysis'] != null) {
        final coParenting = entry['coparenting_analysis'];
        if (coParenting['child_focus_score'] != null &&
            coParenting['child_focus_score'] > 0.8) {
          strengths.add('Child-focused communication');
        }
        if (coParenting['emotional_regulation_score'] != null &&
            coParenting['emotional_regulation_score'] > 0.8) {
          strengths.add('Emotional regulation');
        }
      }

      if (entry['tone_analysis'] != null) {
        final toneAnalysis = entry['tone_analysis'];
        if (toneAnalysis['empathy_score'] != null &&
            toneAnalysis['empathy_score'] > 0.8) {
          strengths.add('Empathetic communication');
        }
        if (toneAnalysis['clarity_score'] != null &&
            toneAnalysis['clarity_score'] > 0.8) {
          strengths.add('Clear communication');
        }
      }
    }

    final result = strengths.toList();
    if (result.isEmpty) {
      return ['Emotional support', 'Shared humor', 'Conflict resolution'];
    }

    return result.take(3).toList();
  }

  /// Generate weekly analysis chart data
  List<Map<String, dynamic>> _generateWeeklyAnalysis(
    List<Map<String, dynamic>> history,
  ) {
    final weekData = <String, List<double>>{};
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Initialize with empty lists
    for (final day in days) {
      weekData[day] = [];
    }

    // Process historical data
    for (final entry in history) {
      if (entry['timestamp'] != null) {
        final timestamp = DateTime.tryParse(entry['timestamp']);
        if (timestamp != null) {
          final dayName = _getDayName(timestamp.weekday);
          final score = _calculateEntryScore(entry);
          weekData[dayName]?.add(score);
        }
      }
    }

    // Calculate averages
    return days.map((day) {
      final scores = weekData[day] ?? [];
      final average = scores.isEmpty
          ? 0.85
          : scores.reduce((a, b) => a + b) / scores.length;
      return {'day': day, 'score': average.clamp(0.0, 1.0)};
    }).toList();
  }

  /// Extract attachment and communication styles from historical data
  Map<String, String> _extractStyles(List<Map<String, dynamic>> history) {
    // For now, extract from the most recent entries or use defaults
    // In a real implementation, this would analyze patterns over time

    String yourAttachment = 'Secure';
    String partnerAttachment = 'Secure';
    String yourCommunication = 'Assertive';
    String partnerCommunication = 'Assertive';

    // Look for patterns in recent entries
    if (history.isNotEmpty) {
      final recentEntries = history.length > 5
          ? history.sublist(history.length - 5)
          : history;

      for (final entry in recentEntries) {
        if (entry['context'] != null) {
          final context = entry['context'];
          if (context['attachment_style'] != null) {
            yourAttachment = context['attachment_style'];
          }
          if (context['communication_style'] != null) {
            yourCommunication = context['communication_style'];
          }
        }
      }
    }

    return {
      'your_attachment': yourAttachment,
      'partner_attachment': partnerAttachment,
      'your_communication': yourCommunication,
      'partner_communication': partnerCommunication,
    };
  }

  /// Generate AI recommendations based on historical patterns
  List<Map<String, dynamic>> _generateAIRecommendations(
    List<Map<String, dynamic>> history,
  ) {
    final recommendations = <Map<String, dynamic>>[];

    // Analyze patterns and generate personalized recommendations
    final commonIssues = _identifyCommonIssues(history);
    final communicationPatterns = _analyzeCommunicationPatterns(history);

    if (commonIssues.isNotEmpty) {
      recommendations.add({
        'title': 'Pattern Recognition',
        'description':
            'Based on your recent conversations, focusing on ${commonIssues.first} could improve your communication flow.',
        'type': 'pattern_based',
      });
    }

    if (communicationPatterns.isNotEmpty) {
      recommendations.add({
        'title': 'Communication Style Tip',
        'description':
            'Your partner responds most positively to messages that ${communicationPatterns.first}. Try incorporating this approach more often.',
        'type': 'style_based',
      });
    }

    return recommendations;
  }

  /// Helper methods

  double _calculateAverageScore(List<Map<String, dynamic>> entries) {
    if (entries.isEmpty) return 0.5;

    double total = 0.0;
    int count = 0;

    for (final entry in entries) {
      total += _calculateEntryScore(entry);
      count++;
    }

    return count > 0 ? total / count : 0.5;
  }

  double _calculateEntryScore(Map<String, dynamic> entry) {
    double score = 0.0;
    int factors = 0;

    if (entry['coparenting_analysis'] != null) {
      final coParenting = entry['coparenting_analysis'];
      if (coParenting['constructiveness_score'] != null) {
        score += coParenting['constructiveness_score'];
        factors++;
      }
    }

    if (entry['tone_analysis'] != null) {
      final toneAnalysis = entry['tone_analysis'];
      if (toneAnalysis['empathy_score'] != null) {
        score += toneAnalysis['empathy_score'];
        factors++;
      }
    }

    if (entry['predictive_analysis'] != null) {
      final predictive = entry['predictive_analysis'];
      if (predictive['success_probability'] != null) {
        score += predictive['success_probability'];
        factors++;
      }
    }

    return factors > 0 ? score / factors : 0.5;
  }

  bool _isPositiveIndicator(String indicator) {
    const positiveIndicators = [
      'supportive',
      'encouraging',
      'understanding',
      'empathetic',
      'calm',
      'constructive',
      'positive',
      'grateful',
      'loving',
    ];
    return positiveIndicators.any(
      (positive) => indicator.toLowerCase().contains(positive),
    );
  }

  String _extractGrowthArea(String suggestionTitle) {
    if (suggestionTitle.toLowerCase().contains('listen')) {
      return 'Active listening';
    }
    if (suggestionTitle.toLowerCase().contains('express')) {
      return 'Expressing needs clearly';
    }
    if (suggestionTitle.toLowerCase().contains('stress')) {
      return 'Managing stress together';
    }
    if (suggestionTitle.toLowerCase().contains('empathy')) {
      return 'Showing empathy';
    }
    if (suggestionTitle.toLowerCase().contains('conflict')) {
      return 'Conflict resolution';
    }
    return 'Communication improvement';
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  List<String> _identifyCommonIssues(List<Map<String, dynamic>> history) {
    final issues = <String>[];

    // Analyze integrated suggestions to identify common themes
    final suggestionCounts = <String, int>{};

    for (final entry in history) {
      if (entry['integrated_suggestions'] != null) {
        final suggestions = entry['integrated_suggestions'] as List<dynamic>;
        for (final suggestion in suggestions) {
          if (suggestion is Map<String, dynamic>) {
            final title = suggestion['title'] as String?;
            if (title != null) {
              final theme = _extractTheme(title);
              suggestionCounts[theme] = (suggestionCounts[theme] ?? 0) + 1;
            }
          }
        }
      }
    }

    // Sort by frequency and return top issues
    final sortedIssues = suggestionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedIssues.take(3).map((e) => e.key).toList();
  }

  List<String> _analyzeCommunicationPatterns(
    List<Map<String, dynamic>> history,
  ) {
    final patterns = <String>[];

    // Analyze tone analysis results for successful patterns
    for (final entry in history) {
      if (entry['tone_analysis'] != null) {
        final toneAnalysis = entry['tone_analysis'];
        if (toneAnalysis['empathy_score'] != null &&
            toneAnalysis['empathy_score'] > 0.8) {
          patterns.add('acknowledge their feelings first');
        }
        if (toneAnalysis['clarity_score'] != null &&
            toneAnalysis['clarity_score'] > 0.8) {
          patterns.add('use clear, direct language');
        }
      }
    }

    return patterns.take(2).toList();
  }

  String _extractTheme(String suggestionTitle) {
    final title = suggestionTitle.toLowerCase();
    if (title.contains('listen')) return 'listening skills';
    if (title.contains('empathy')) return 'empathy';
    if (title.contains('stress')) return 'stress management';
    if (title.contains('conflict')) return 'conflict resolution';
    if (title.contains('express')) return 'expression';
    return 'communication';
  }

  /// Generate mock insights as fallback
  Map<String, dynamic> _generateMockInsights() {
    return {
      'compatibility_score': 0.87,
      'communication_trend': 'improving',
      'weekly_messages': 127,
      'positive_sentiment': 0.84,
      'growth_areas': [
        'Active listening',
        'Expressing needs clearly',
        'Managing stress together',
      ],
      'strengths': ['Emotional support', 'Shared humor', 'Conflict resolution'],
      'weekly_analysis': [
        {'day': 'Mon', 'score': 0.82},
        {'day': 'Tue', 'score': 0.85},
        {'day': 'Wed', 'score': 0.79},
        {'day': 'Thu', 'score': 0.91},
        {'day': 'Fri', 'score': 0.88},
        {'day': 'Sat', 'score': 0.94},
        {'day': 'Sun', 'score': 0.87},
      ],
      'your_style': 'Secure',
      'partner_style': 'Anxious',
      'your_comm': 'Assertive',
      'partner_comm': 'Passive',
      'ai_recommendations': [
        {
          'title': 'Today\'s Insight',
          'description':
              'Your partner responds most positively to messages that acknowledge their feelings first. Try starting with "I understand..." or "I can see that..."',
          'type': 'daily_insight',
        },
      ],
    };
  }
}
