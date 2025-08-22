import 'package:flutter/foundation.dart';
import 'keyboard_manager.dart';
import 'relationship_insights_service.dart';
import 'conversation_data_service.dart';

/// Unified Analytics Service for all screens
/// Provides centralized access to communication analysis data
class UnifiedAnalyticsService extends ChangeNotifier {
  static final UnifiedAnalyticsService _instance =
      UnifiedAnalyticsService._internal();
  factory UnifiedAnalyticsService() => _instance;
  UnifiedAnalyticsService._internal();

  final KeyboardManager _keyboardManager = KeyboardManager();
  final RelationshipInsightsService _relationshipInsights =
      RelationshipInsightsService();
  final ConversationDataService _conversationService = ConversationDataService();

  /// Get individual user analytics (for insights dashboard)
  Future<Map<String, dynamic>> getIndividualAnalytics() async {
    try {
      final analysisHistory = _keyboardManager.analysisHistory;

      if (analysisHistory.isEmpty) {
        return _generateDefaultIndividualAnalytics();
      }

      return await _processIndividualAnalytics(analysisHistory);
    } catch (e) {
      print('🔧 Analytics service working in offline mode: $e');
      return _generateDefaultIndividualAnalytics();
    }
  }

  /// Get relationship analytics (for relationship dashboard)
  Future<Map<String, dynamic>> getRelationshipAnalytics() async {
    try {
      return await _relationshipInsights.generateRelationshipInsights();
    } catch (e) {
      print('🔧 Relationship analytics working in offline mode: $e');
      return {
        'attachment_style': 'Secure Attachment',
        'communication_score': 0.75,
        'insights': ['App is working in offline mode', 'Set up Firestore to sync data'],
        'offline_mode': true
      };
    }
  }

  /// Get message lab analytics (for message practice/lab)
  Future<Map<String, dynamic>> getMessageLabAnalytics() async {
    try {
      final analysisHistory = _keyboardManager.analysisHistory;
      return _processMessageLabAnalytics(analysisHistory);
    } catch (e) {
      print('🔧 Message lab analytics working in offline mode: $e');
      return {
        'recent_messages': [],
        'improvement_suggestions': ['App is working in offline mode'],
        'offline_mode': true
      };
    }
  }

  /// Get general analytics data
  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      print('📊 Getting general analytics...');

      // Mock analytics data for now
      return {
        'total_conversations': 50,
        'avg_empathy_score': 0.75,
        'avg_clarity_score': 0.68,
        'improvement_rate': 0.12,
        'communication_patterns': {
          'morning_conversations': 15,
          'afternoon_conversations': 20,
          'evening_conversations': 15,
        },
        'tone_distribution': {
          'supportive': 0.45,
          'neutral': 0.35,
          'assertive': 0.20,
        },
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('⚠️ Error getting analytics: $e');
      return {};
    }
  }

  /// Process individual analytics from analysis history
  Future<Map<String, dynamic>> _processIndividualAnalytics(
    List<Map<String, dynamic>> history,
  ) async {
    final analytics = <String, dynamic>{};

    // Calculate personal communication scores
    analytics['personal_communication_score'] = _calculatePersonalScore(
      history,
    );

    // Generate tone trends
    analytics['tone_trends'] = _generateToneTrends(history);

    // Calculate emotional regulation progress
    analytics['emotional_regulation_progress'] = _calculateEmotionalProgress(
      history,
    );

    // Extract communication patterns
    analytics['communication_patterns'] = _extractCommunicationPatterns(
      history,
    );

    // Generate weekly analysis
    analytics['weekly_analysis'] = _generateWeeklyAnalysis(history);

    // Calculate breakdown by sentiment
    analytics['communication_breakdown'] = _generateCommunicationBreakdown(
      history,
    );

    // Generate growth recommendations
    analytics['growth_recommendations'] = _generateGrowthRecommendations(
      history,
    );

    return analytics;
  }

  /// Process message lab analytics
  Map<String, dynamic> _processMessageLabAnalytics(
    List<Map<String, dynamic>> history,
  ) {
    final analytics = <String, dynamic>{};

    // Calculate success rates by scenario
    analytics['success_by_scenario'] = _calculateSuccessByScenario(history);

    // Track improvement over time
    analytics['improvement_timeline'] = _generateImprovementTimeline(history);

    // Identify most effective message patterns
    analytics['effective_patterns'] = _identifyEffectivePatterns(history);

    // Generate practice recommendations
    analytics['practice_recommendations'] = _generatePracticeRecommendations(
      history,
    );

    return analytics;
  }

  /// Calculate personal communication score
  double _calculatePersonalScore(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return 0.75;

    double totalScore = 0.0;
    int validEntries = 0;

    for (final entry in history) {
      double entryScore = 0.0;
      int factors = 0;

      // Factor in various analysis scores
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
      }

      if (entry['tone_analysis'] != null) {
        final tone = entry['tone_analysis'];
        if (tone['empathy_score'] != null) {
          entryScore += tone['empathy_score'];
          factors++;
        }
        if (tone['clarity_score'] != null) {
          entryScore += tone['clarity_score'];
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
        : 0.75;
  }

  /// Generate tone trends over time
  Map<String, int> _generateToneTrends(List<Map<String, dynamic>> history) {
    final trends = <String, int>{};
    final now = DateTime.now();

    // Generate weekly data
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayKey = _getDayKey(date);

      // Calculate average tone score for this day
      final dayEntries = history.where((entry) {
        if (entry['timestamp'] == null) return false;
        final entryDate = DateTime.tryParse(entry['timestamp']);
        return entryDate != null && _isSameDay(entryDate, date);
      }).toList();

      if (dayEntries.isNotEmpty) {
        double avgScore = 0.0;
        int scoreCount = 0;

        for (final entry in dayEntries) {
          if (entry['tone_analysis'] != null) {
            final tone = entry['tone_analysis'];
            if (tone['empathy_score'] != null &&
                tone['clarity_score'] != null) {
              avgScore += (tone['empathy_score'] + tone['clarity_score']) / 2;
              scoreCount++;
            }
          }
        }

        trends[dayKey] = scoreCount > 0
            ? (avgScore / scoreCount * 100).round()
            : 75;
      } else {
        trends[dayKey] = 75; // Default neutral score
      }
    }

    return trends;
  }

  /// Calculate emotional regulation progress
  double _calculateEmotionalProgress(List<Map<String, dynamic>> history) {
    if (history.length < 2) return 0.0;

    final recentEntries = history.length > 5
        ? history.sublist(history.length - 5)
        : history;
    final olderEntries = history.length > 5
        ? history.sublist(0, history.length - 5)
        : <Map<String, dynamic>>[];

    if (olderEntries.isEmpty) return 0.0;

    double recentRegulation = _calculateAverageRegulation(recentEntries);
    double olderRegulation = _calculateAverageRegulation(olderEntries);

    return recentRegulation - olderRegulation;
  }

  /// Extract communication patterns
  List<String> _extractCommunicationPatterns(
    List<Map<String, dynamic>> history,
  ) {
    final patterns = <String>[];

    // Analyze patterns in the data
    final tonePatterns = _analyzeTonePatterns(history);
    final timePatterns = _analyzeTimePatterns(history);
    final scenarioPatterns = _analyzeScenarioPatterns(history);

    patterns.addAll(tonePatterns);
    patterns.addAll(timePatterns);
    patterns.addAll(scenarioPatterns);

    return patterns.take(5).toList();
  }

  /// Generate weekly analysis
  Map<String, int> _generateWeeklyAnalysis(List<Map<String, dynamic>> history) {
    final weeklyData = <String, int>{};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayKey = _getDayKey(date);

      final dayScore = _calculateDayScore(history, date);
      weeklyData[dayKey] = dayScore;
    }

    return weeklyData;
  }

  /// Generate communication breakdown
  List<Map<String, dynamic>> _generateCommunicationBreakdown(
    List<Map<String, dynamic>> history,
  ) {
    int positive = 0, neutral = 0, challenging = 0;

    for (final entry in history) {
      if (entry['tone_analysis'] != null) {
        final tone = entry['tone_analysis'];
        final empathyScore = tone['empathy_score'] ?? 0.5;
        final clarityScore = tone['clarity_score'] ?? 0.5;
        final avgScore = (empathyScore + clarityScore) / 2;

        if (avgScore >= 0.7) {
          positive++;
        } else if (avgScore >= 0.4) {
          neutral++;
        } else {
          challenging++;
        }
      }
    }

    final total = positive + neutral + challenging;
    if (total == 0) {
      return [
        {
          'category': 'Positive',
          'percentage': 68,
          'color': 'green',
          'count': 0,
        },
        {'category': 'Neutral', 'percentage': 22, 'color': 'blue', 'count': 0},
        {
          'category': 'Challenging',
          'percentage': 10,
          'color': 'orange',
          'count': 0,
        },
      ];
    }

    return [
      {
        'category': 'Positive',
        'percentage': ((positive / total) * 100).round(),
        'color': 'green',
        'count': positive,
      },
      {
        'category': 'Neutral',
        'percentage': ((neutral / total) * 100).round(),
        'color': 'blue',
        'count': neutral,
      },
      {
        'category': 'Challenging',
        'percentage': ((challenging / total) * 100).round(),
        'color': 'orange',
        'count': challenging,
      },
    ];
  }

  /// Generate growth recommendations
  List<String> _generateGrowthRecommendations(
    List<Map<String, dynamic>> history,
  ) {
    final recommendations = <String>[];

    // Analyze weak areas and provide recommendations
    final weakAreas = _identifyWeakAreas(history);

    if (weakAreas.contains('empathy')) {
      recommendations.add('Practice active listening and perspective-taking');
    }
    if (weakAreas.contains('clarity')) {
      recommendations.add('Work on clear, direct communication');
    }
    if (weakAreas.contains('emotional_regulation')) {
      recommendations.add('Develop emotional regulation techniques');
    }
    if (weakAreas.contains('timing')) {
      recommendations.add(
        'Consider optimal timing for difficult conversations',
      );
    }

    return recommendations.take(3).toList();
  }

  /// Helper methods
  String _getDayKey(DateTime date) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[date.weekday % 7];
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  double _calculateAverageRegulation(List<Map<String, dynamic>> entries) {
    double total = 0.0;
    int count = 0;

    for (final entry in entries) {
      if (entry['coparenting_analysis'] != null) {
        final coParenting = entry['coparenting_analysis'];
        if (coParenting['emotional_regulation_score'] != null) {
          total += coParenting['emotional_regulation_score'];
          count++;
        }
      }
    }

    return count > 0 ? total / count : 0.5;
  }

  int _calculateDayScore(List<Map<String, dynamic>> history, DateTime date) {
    final dayEntries = history.where((entry) {
      if (entry['timestamp'] == null) return false;
      final entryDate = DateTime.tryParse(entry['timestamp']);
      return entryDate != null && _isSameDay(entryDate, date);
    }).toList();

    if (dayEntries.isEmpty) return 75;

    double avgScore = 0.0;
    int scoreCount = 0;

    for (final entry in dayEntries) {
      final score = _calculatePersonalScore([entry]);
      avgScore += score;
      scoreCount++;
    }

    return scoreCount > 0 ? (avgScore / scoreCount * 100).round() : 75;
  }

  List<String> _identifyWeakAreas(List<Map<String, dynamic>> history) {
    final weakAreas = <String>[];

    // Calculate average scores for different areas
    double empathySum = 0, claritySum = 0, regulationSum = 0;
    int empathyCount = 0, clarityCount = 0, regulationCount = 0;

    for (final entry in history) {
      if (entry['tone_analysis'] != null) {
        final tone = entry['tone_analysis'];
        if (tone['empathy_score'] != null) {
          empathySum += tone['empathy_score'];
          empathyCount++;
        }
        if (tone['clarity_score'] != null) {
          claritySum += tone['clarity_score'];
          clarityCount++;
        }
      }

      if (entry['coparenting_analysis'] != null) {
        final coParenting = entry['coparenting_analysis'];
        if (coParenting['emotional_regulation_score'] != null) {
          regulationSum += coParenting['emotional_regulation_score'];
          regulationCount++;
        }
      }
    }

    // Identify areas below threshold
    if (empathyCount > 0 && empathySum / empathyCount < 0.6) {
      weakAreas.add('empathy');
    }
    if (clarityCount > 0 && claritySum / clarityCount < 0.6) {
      weakAreas.add('clarity');
    }
    if (regulationCount > 0 && regulationSum / regulationCount < 0.6) {
      weakAreas.add('emotional_regulation');
    }

    return weakAreas;
  }

  List<String> _analyzeTonePatterns(List<Map<String, dynamic>> history) {
    // Analyze tone patterns - simplified implementation
    return ['Consistent empathetic tone', 'Improving clarity over time'];
  }

  List<String> _analyzeTimePatterns(List<Map<String, dynamic>> history) {
    // Analyze timing patterns - simplified implementation
    return ['Better communication in mornings'];
  }

  List<String> _analyzeScenarioPatterns(List<Map<String, dynamic>> history) {
    // Analyze scenario patterns - simplified implementation
    return ['Strongest in logistics discussions'];
  }

  Map<String, double> _calculateSuccessByScenario(
    List<Map<String, dynamic>> history,
  ) {
    final scenarios = <String, List<double>>{};

    for (final entry in history) {
      final context = entry['context'];
      if (context != null && context['relationship'] != null) {
        final scenario = context['relationship'];
        final score = _calculatePersonalScore([entry]);

        scenarios.putIfAbsent(scenario, () => []).add(score);
      }
    }

    final results = <String, double>{};
    scenarios.forEach((scenario, scores) {
      results[scenario] = scores.reduce((a, b) => a + b) / scores.length;
    });

    return results;
  }

  List<Map<String, dynamic>> _generateImprovementTimeline(
    List<Map<String, dynamic>> history,
  ) {
    // Generate improvement timeline - simplified implementation
    return [];
  }

  List<String> _identifyEffectivePatterns(List<Map<String, dynamic>> history) {
    // Identify effective patterns - simplified implementation
    return ['Direct questions work well', 'Positive framing improves outcomes'];
  }

  List<String> _generatePracticeRecommendations(
    List<Map<String, dynamic>> history,
  ) {
    // Generate practice recommendations - simplified implementation
    return [
      'Practice conflict resolution scenarios',
      'Work on empathy expressions',
    ];
  }

  /// Default analytics when no history is available
  Map<String, dynamic> _generateDefaultIndividualAnalytics() {
    return {
      'personal_communication_score': 0.75,
      'tone_trends': {
        'Mon': 75,
        'Tue': 80,
        'Wed': 78,
        'Thu': 82,
        'Fri': 85,
        'Sat': 88,
        'Sun': 83,
      },
      'emotional_regulation_progress': 0.1,
      'communication_patterns': [
        'Building empathy skills',
        'Improving clarity',
        'Developing consistency',
      ],
      'weekly_analysis': {
        'Mon': 75,
        'Tue': 80,
        'Wed': 78,
        'Thu': 82,
        'Fri': 85,
        'Sat': 88,
        'Sun': 83,
      },
      'communication_breakdown': [
        {
          'category': 'Positive',
          'percentage': 68,
          'color': 'green',
          'count': 0,
        },
        {'category': 'Neutral', 'percentage': 22, 'color': 'blue', 'count': 0},
        {
          'category': 'Challenging',
          'percentage': 10,
          'color': 'orange',
          'count': 0,
        },
      ],
      'growth_recommendations': [
        'Practice active listening',
        'Work on emotional regulation',
        'Develop clearer communication',
      ],
    };
  }

  /// Get comprehensive conversation analytics
  Future<Map<String, dynamic>> getConversationAnalytics({
    String? userId,
    String? relationshipId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final conversationHistory = await _conversationService.getConversationHistory(
        userId: userId,
        relationshipId: relationshipId,
        startDate: startDate,
        endDate: endDate,
      );
      
      final stats = await _conversationService.getConversationStats(
        userId: userId,
        relationshipId: relationshipId,
        startDate: startDate,
        endDate: endDate,
      );
      
      return {
        'conversation_history': conversationHistory,
        'conversation_stats': stats,
        'processed_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting conversation analytics: $e');
      return {
        'conversation_history': [],
        'conversation_stats': {},
        'error': true,
        'processed_at': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Store conversation for future analysis
  Future<void> recordConversation(Map<String, dynamic> conversationData) async {
    try {
      await _conversationService.storeConversation(conversationData);
      notifyListeners(); // Refresh analytics
    } catch (e) {
      debugPrint('Error recording conversation: $e');
    }
  }

  /// Store message for analysis
  Future<void> recordMessage(String conversationId, Map<String, dynamic> messageData) async {
    try {
      await _conversationService.storeMessage(conversationId, messageData);
      notifyListeners(); // Refresh analytics
    } catch (e) {
      debugPrint('Error recording message: $e');
    }
  }

  /// Get recent conversations for quick insights
  Future<List<Map<String, dynamic>>> getRecentConversations({int limit = 10}) async {
    try {
      return await _conversationService.getConversationHistory(
        endDate: DateTime.now(),
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        limit: limit,
      );
    } catch (e) {
      debugPrint('Error getting recent conversations: $e');
      return [];
    }
  }

  /// Clear cached data and refresh
  Future<void> refreshAnalytics() async {
    notifyListeners();
  }

  /// Get analysis history for direct access
  List<Map<String, dynamic>> get analysisHistory =>
      _keyboardManager.analysisHistory;
}
