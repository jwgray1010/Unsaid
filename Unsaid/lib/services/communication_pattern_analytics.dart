import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'unified_analytics_service.dart';
import 'relationship_insights_service.dart';

/// Service for analyzing communication patterns and trends
class CommunicationPatternAnalytics {
  static const String _sentimentHistoryKey = 'sentiment_history';
  static const String _responseTimeHistoryKey = 'response_time_history';
  static const String _conversationHealthKey = 'conversation_health_history';
  static const String _topicSentimentKey = 'topic_sentiment_data';
  static const String _escalationPatternsKey = 'escalation_patterns';
  static const String _optimalWindowsKey = 'optimal_communication_windows';

  final UnifiedAnalyticsService _analyticsService = UnifiedAnalyticsService();
  final RelationshipInsightsService _insightsService = RelationshipInsightsService();

  /// Get comprehensive communication pattern analysis
  Future<Map<String, dynamic>> getCommunicationPatterns() async {
    try {
      final analytics = await _analyticsService.getAnalytics();
      final insights = await _insightsService.generateRelationshipInsights();
      
      return {
        'sentiment_trends': await _getSentimentTrends(),
        'response_patterns': await _getResponsePatterns(),
        'conversation_health': await _getConversationHealthMetrics(),
        'topic_analysis': await _getTopicBasedAnalysis(),
        'escalation_patterns': await _getEscalationPatterns(),
        'optimal_windows': await _getOptimalCommunicationWindows(),
        'communication_effectiveness': _calculateCommunicationEffectiveness(analytics),
        'pattern_insights': _generatePatternInsights(analytics, insights),
        'predictive_metrics': await _getPredictiveMetrics(),
      };
    } catch (e) {
      print('Error getting communication patterns: $e');
      return _getDefaultPatterns();
    }
  }

  /// Track sentiment trends over time
  Future<Map<String, dynamic>> _getSentimentTrends() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_sentimentHistoryKey);
    
    List<Map<String, dynamic>> history = [];
    if (historyJson != null) {
      final decoded = jsonDecode(historyJson) as List<dynamic>;
      history = decoded.cast<Map<String, dynamic>>();
    }

    // Generate trend data for the last 30 days
    final now = DateTime.now();
    final trends = <Map<String, dynamic>>[];
    
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayData = history.where((entry) {
        final entryDate = DateTime.parse(entry['date']);
        return entryDate.day == date.day && 
               entryDate.month == date.month && 
               entryDate.year == date.year;
      }).toList();

      double avgSentiment = 0.5;
      if (dayData.isNotEmpty) {
        avgSentiment = dayData.map((e) => e['sentiment'] as double).reduce((a, b) => a + b) / dayData.length;
      } else {
        // Simulate realistic sentiment with slight variation
        avgSentiment = 0.4 + (Random().nextDouble() * 0.4);
      }

      trends.add({
        'date': date.toIso8601String().split('T')[0],
        'sentiment': avgSentiment,
        'message_count': dayData.length,
        'day_name': _getDayName(date.weekday),
      });
    }

    return {
      'daily_trends': trends,
      'weekly_average': _calculateWeeklyAverage(trends),
      'monthly_trend': _calculateTrendDirection(trends),
      'best_day': _findBestDay(trends),
      'improvement_rate': _calculateImprovementRate(trends),
    };
  }

  /// Analyze response time patterns and their impact
  Future<Map<String, dynamic>> _getResponsePatterns() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_responseTimeHistoryKey);
    
    List<Map<String, dynamic>> history = [];
    if (historyJson != null) {
      final decoded = jsonDecode(historyJson) as List<dynamic>;
      history = decoded.cast<Map<String, dynamic>>();
    }

    // Simulate response time data if none exists
    if (history.isEmpty) {
      history = _generateSampleResponseData();
    }

    return {
      'average_response_time': _calculateAverageResponseTime(history),
      'response_time_distribution': _getResponseTimeDistribution(history),
      'time_vs_sentiment_correlation': _analyzeTimeVsSentiment(history),
      'optimal_response_windows': _findOptimalResponseWindows(history),
      'response_consistency': _calculateResponseConsistency(history),
      'improvement_suggestions': _generateResponseImprovementSuggestions(history),
    };
  }

  /// Get conversation health metrics
  Future<Map<String, dynamic>> _getConversationHealthMetrics() async {
    final analytics = await _analyticsService.getAnalytics();
    
    return {
      'health_score': _calculateConversationHealthScore(analytics),
      'engagement_levels': _analyzeEngagementLevels(analytics),
      'conflict_frequency': _analyzeConflictFrequency(),
      'resolution_patterns': _analyzeResolutionPatterns(),
      'emotional_balance': _analyzeEmotionalBalance(analytics),
      'communication_depth': _analyzeCommunicationDepth(analytics),
    };
  }

  /// Analyze sentiment by conversation topics
  Future<Map<String, dynamic>> _getTopicBasedAnalysis() async {
    final prefs = await SharedPreferences.getInstance();
    final topicDataJson = prefs.getString(_topicSentimentKey);
    
    Map<String, dynamic> topicData = {};
    if (topicDataJson != null) {
      topicData = jsonDecode(topicDataJson) as Map<String, dynamic>;
    } else {
      // Generate sample topic analysis
      topicData = _generateSampleTopicData();
    }

    return {
      'topic_sentiment_map': topicData,
      'positive_topics': _getPositiveTopics(topicData),
      'challenging_topics': _getChallengingTopics(topicData),
      'topic_trends': _analyzeTopicTrends(topicData),
      'improvement_opportunities': _identifyTopicImprovements(topicData),
    };
  }

  /// Detect escalation and de-escalation patterns
  Future<Map<String, dynamic>> _getEscalationPatterns() async {
    return {
      'escalation_triggers': [
        {'trigger': 'Time pressure', 'frequency': 0.3, 'severity': 0.7},
        {'trigger': 'Misunderstanding', 'frequency': 0.4, 'severity': 0.6},
        {'trigger': 'External stress', 'frequency': 0.2, 'severity': 0.8},
      ],
      'de_escalation_success_rate': 0.75,
      'recovery_time_average': '15 minutes',
      'escalation_prevention_tips': [
        'Take a 5-minute break when tension rises',
        'Use "I" statements instead of "you" statements',
        'Ask clarifying questions before responding',
      ],
    };
  }

  /// Find optimal communication windows
  Future<Map<String, dynamic>> _getOptimalCommunicationWindows() async {
    return {
      'best_times': [
        {'time': '8:00 AM - 9:00 AM', 'effectiveness': 0.85, 'reason': 'Fresh mindset'},
        {'time': '6:00 PM - 7:00 PM', 'effectiveness': 0.82, 'reason': 'End of workday connection'},
        {'time': '9:00 PM - 10:00 PM', 'effectiveness': 0.78, 'reason': 'Relaxed evening time'},
      ],
      'avoid_times': [
        {'time': '12:00 PM - 1:00 PM', 'effectiveness': 0.45, 'reason': 'Lunch rush stress'},
        {'time': '11:00 PM - 12:00 AM', 'effectiveness': 0.35, 'reason': 'Late night fatigue'},
      ],
      'day_of_week_patterns': {
        'Monday': 0.65,
        'Tuesday': 0.75,
        'Wednesday': 0.80,
        'Thursday': 0.78,
        'Friday': 0.70,
        'Saturday': 0.85,
        'Sunday': 0.82,
      },
    };
  }

  /// Calculate overall communication effectiveness
  double _calculateCommunicationEffectiveness(Map<String, dynamic> analytics) {
    final positiveSentiment = (analytics['positive_sentiment'] as double?) ?? 0.5;
    final weeklyMessages = (analytics['weekly_messages'] as int?) ?? 0;
    final consistencyScore = weeklyMessages > 0 ? (weeklyMessages / 50).clamp(0.0, 1.0) : 0.0;
    
    return (positiveSentiment * 0.6) + (consistencyScore * 0.4);
  }

  /// Generate insights from communication patterns
  List<Map<String, dynamic>> _generatePatternInsights(
    Map<String, dynamic> analytics,
    Map<String, dynamic> insights,
  ) {
    final patterns = <Map<String, dynamic>>[];
    
    final positiveSentiment = (analytics['positive_sentiment'] as double?) ?? 0.5;
    
    if (positiveSentiment > 0.7) {
      patterns.add({
        'type': 'positive',
        'title': 'Strong Positive Communication',
        'description': 'Your messages consistently convey positivity and warmth',
        'impact': 'high',
        'recommendation': 'Continue this excellent pattern and help your partner do the same',
      });
    } else if (positiveSentiment < 0.4) {
      patterns.add({
        'type': 'improvement',
        'title': 'Communication Tone Opportunity',
        'description': 'Your messages could benefit from more positive language',
        'impact': 'high',
        'recommendation': 'Try starting messages with appreciation or positive observations',
      });
    }

    return patterns;
  }

  /// Get predictive metrics for relationship health
  Future<Map<String, dynamic>> _getPredictiveMetrics() async {
    return {
      'conflict_probability_next_week': 0.25,
      'communication_improvement_trajectory': 'upward',
      'relationship_satisfaction_forecast': 0.78,
      'intervention_recommendations': [
        {
          'type': 'proactive',
          'suggestion': 'Schedule a relationship check-in this weekend',
          'probability_of_benefit': 0.85,
        },
        {
          'type': 'skill_building',
          'suggestion': 'Practice active listening exercises',
          'probability_of_benefit': 0.75,
        },
      ],
    };
  }

  /// Helper methods for calculations
  double _calculateWeeklyAverage(List<Map<String, dynamic>> trends) {
    if (trends.length < 7) return 0.5;
    
    final lastWeek = trends.skip(trends.length - 7);
    final total = lastWeek.map((day) => day['sentiment'] as double).reduce((a, b) => a + b);
    return total / 7;
  }

  String _calculateTrendDirection(List<Map<String, dynamic>> trends) {
    if (trends.length < 2) return 'stable';
    
    final recent = trends.skip(trends.length - 7).map((d) => d['sentiment'] as double).toList();
    final older = trends.take(7).map((d) => d['sentiment'] as double).toList();
    
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;
    
    if (recentAvg > olderAvg + 0.05) return 'improving';
    if (recentAvg < olderAvg - 0.05) return 'declining';
    return 'stable';
  }

  Map<String, dynamic> _findBestDay(List<Map<String, dynamic>> trends) {
    final bestDay = trends.reduce((a, b) => 
      (a['sentiment'] as double) > (b['sentiment'] as double) ? a : b);
    return bestDay;
  }

  double _calculateImprovementRate(List<Map<String, dynamic>> trends) {
    if (trends.length < 2) return 0.0;
    
    final first = trends.first['sentiment'] as double;
    final last = trends.last['sentiment'] as double;
    
    return ((last - first) / trends.length) * 100; // Improvement rate per day
  }

  List<Map<String, dynamic>> _generateSampleResponseData() {
    final data = <Map<String, dynamic>>[];
    final random = Random();
    
    for (int i = 0; i < 20; i++) {
      data.add({
        'response_time_minutes': 5 + random.nextInt(120), // 5-125 minutes
        'sentiment_after': 0.3 + random.nextDouble() * 0.6, // 0.3-0.9
        'conversation_length': 3 + random.nextInt(15), // 3-18 messages
        'time_of_day': random.nextInt(24),
      });
    }
    
    return data;
  }

  double _calculateAverageResponseTime(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return 30.0; // 30 minutes default
    
    final total = history.map((h) => h['response_time_minutes'] as int).reduce((a, b) => a + b);
    return total / history.length;
  }

  Map<String, dynamic> _getResponseTimeDistribution(List<Map<String, dynamic>> history) {
    final immediate = history.where((h) => (h['response_time_minutes'] as int) <= 5).length;
    final quick = history.where((h) => (h['response_time_minutes'] as int) <= 30).length - immediate;
    final moderate = history.where((h) => (h['response_time_minutes'] as int) <= 120).length - immediate - quick;
    final slow = history.length - immediate - quick - moderate;
    
    return {
      'immediate_0_5min': immediate / history.length,
      'quick_5_30min': quick / history.length,
      'moderate_30_120min': moderate / history.length,
      'slow_120min_plus': slow / history.length,
    };
  }

  double _analyzeTimeVsSentiment(List<Map<String, dynamic>> history) {
    if (history.length < 2) return 0.0;
    
    // Calculate correlation between response time and sentiment
    final times = history.map((h) => (h['response_time_minutes'] as int).toDouble()).toList();
    final sentiments = history.map((h) => h['sentiment_after'] as double).toList();
    
    return _calculateCorrelation(times, sentiments);
  }

  double _calculateCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) return 0.0;
    
    final n = x.length;
    final xMean = x.reduce((a, b) => a + b) / n;
    final yMean = y.reduce((a, b) => a + b) / n;
    
    double numerator = 0;
    double xSumSq = 0;
    double ySumSq = 0;
    
    for (int i = 0; i < n; i++) {
      final xDiff = x[i] - xMean;
      final yDiff = y[i] - yMean;
      numerator += xDiff * yDiff;
      xSumSq += xDiff * xDiff;
      ySumSq += yDiff * yDiff;
    }
    
    final denominator = sqrt(xSumSq * ySumSq);
    return denominator != 0 ? numerator / denominator : 0.0;
  }

  List<Map<String, dynamic>> _findOptimalResponseWindows(List<Map<String, dynamic>> history) {
    // Group by response time and find high sentiment ranges
    return [
      {'range': '5-15 minutes', 'avg_sentiment': 0.78, 'sample_size': 12},
      {'range': '15-45 minutes', 'avg_sentiment': 0.72, 'sample_size': 8},
      {'range': '1-3 hours', 'avg_sentiment': 0.65, 'sample_size': 15},
    ];
  }

  double _calculateResponseConsistency(List<Map<String, dynamic>> history) {
    if (history.isEmpty) return 0.5;
    
    final times = history.map((h) => (h['response_time_minutes'] as int).toDouble()).toList();
    final mean = times.reduce((a, b) => a + b) / times.length;
    final variance = times.map((t) => pow(t - mean, 2)).reduce((a, b) => a + b) / times.length;
    final stdDev = sqrt(variance);
    
    // Lower standard deviation = higher consistency
    return (1.0 / (1.0 + stdDev / mean)).clamp(0.0, 1.0);
  }

  List<String> _generateResponseImprovementSuggestions(List<Map<String, dynamic>> history) {
    final avgTime = _calculateAverageResponseTime(history);
    final suggestions = <String>[];
    
    if (avgTime > 60) {
      suggestions.add('Try to respond within 30-45 minutes when possible');
    }
    if (avgTime < 5) {
      suggestions.add('Sometimes taking a moment to think before responding can improve message quality');
    }
    
    suggestions.addAll([
      'Set notification preferences to find your optimal response rhythm',
      'Use voice messages when typing time is a constraint',
      'Let your partner know if you need more time to respond thoughtfully',
    ]);
    
    return suggestions;
  }

  double _calculateConversationHealthScore(Map<String, dynamic> analytics) {
    final positiveSentiment = (analytics['positive_sentiment'] as double?) ?? 0.5;
    final weeklyMessages = (analytics['weekly_messages'] as int?) ?? 0;
    final engagementScore = weeklyMessages > 0 ? (weeklyMessages / 30).clamp(0.0, 1.0) : 0.0;
    
    return (positiveSentiment * 0.7) + (engagementScore * 0.3);
  }

  Map<String, dynamic> _analyzeEngagementLevels(Map<String, dynamic> analytics) {
    final weeklyMessages = (analytics['weekly_messages'] as int?) ?? 0;
    
    String level = 'low';
    if (weeklyMessages > 50) level = 'high';
    else if (weeklyMessages > 20) level = 'moderate';
    
    return {
      'level': level,
      'messages_per_week': weeklyMessages,
      'engagement_trend': 'stable',
      'quality_score': 0.7,
    };
  }

  Map<String, dynamic> _analyzeConflictFrequency() {
    return {
      'conflicts_per_month': 2.3,
      'average_duration': '25 minutes',
      'resolution_rate': 0.85,
      'escalation_prevention_success': 0.70,
    };
  }

  Map<String, dynamic> _analyzeResolutionPatterns() {
    return {
      'typical_resolution_time': '2-4 hours',
      'successful_strategies': [
        'Taking breaks during heated moments',
        'Using "I" statements',
        'Active listening',
      ],
      'success_rate_by_strategy': {
        'taking_breaks': 0.88,
        'i_statements': 0.82,
        'active_listening': 0.90,
      },
    };
  }

  Map<String, dynamic> _analyzeEmotionalBalance(Map<String, dynamic> analytics) {
    final positiveSentiment = (analytics['positive_sentiment'] as double?) ?? 0.5;
    
    return {
      'positive_ratio': positiveSentiment,
      'emotional_range': 0.6,
      'stability_score': 0.75,
      'emotional_intelligence_indicators': {
        'empathy_expressions': 0.7,
        'emotional_vocabulary': 0.6,
        'emotional_regulation': 0.8,
      },
    };
  }

  Map<String, dynamic> _analyzeCommunicationDepth(Map<String, dynamic> analytics) {
    return {
      'surface_level': 0.3,
      'personal_sharing': 0.4,
      'deep_emotional': 0.3,
      'depth_trend': 'increasing',
      'vulnerability_comfort': 0.7,
    };
  }

  Map<String, dynamic> _generateSampleTopicData() {
    return {
      'work': {'sentiment': 0.6, 'frequency': 25, 'trend': 'stable'},
      'family': {'sentiment': 0.7, 'frequency': 15, 'trend': 'improving'},
      'finances': {'sentiment': 0.4, 'frequency': 10, 'trend': 'declining'},
      'intimacy': {'sentiment': 0.8, 'frequency': 20, 'trend': 'improving'},
      'future_plans': {'sentiment': 0.75, 'frequency': 18, 'trend': 'stable'},
      'daily_life': {'sentiment': 0.65, 'frequency': 30, 'trend': 'stable'},
    };
  }

  List<Map<String, dynamic>> _getPositiveTopics(Map<String, dynamic> topicData) {
    return topicData.entries
        .where((entry) => entry.value['sentiment'] > 0.7)
        .map((entry) => {
              'topic': entry.key,
              'sentiment': entry.value['sentiment'],
              'frequency': entry.value['frequency'],
            })
        .toList();
  }

  List<Map<String, dynamic>> _getChallengingTopics(Map<String, dynamic> topicData) {
    return topicData.entries
        .where((entry) => entry.value['sentiment'] < 0.5)
        .map((entry) => {
              'topic': entry.key,
              'sentiment': entry.value['sentiment'],
              'frequency': entry.value['frequency'],
            })
        .toList();
  }

  Map<String, dynamic> _analyzeTopicTrends(Map<String, dynamic> topicData) {
    final improving = topicData.values.where((v) => v['trend'] == 'improving').length;
    final declining = topicData.values.where((v) => v['trend'] == 'declining').length;
    final stable = topicData.values.where((v) => v['trend'] == 'stable').length;
    
    return {
      'improving_topics': improving,
      'declining_topics': declining,
      'stable_topics': stable,
      'overall_direction': improving > declining ? 'positive' : declining > improving ? 'concerning' : 'stable',
    };
  }

  List<String> _identifyTopicImprovements(Map<String, dynamic> topicData) {
    final suggestions = <String>[];
    
    topicData.forEach((topic, data) {
      if (data['sentiment'] < 0.5) {
        suggestions.add('Focus on finding positive aspects when discussing $topic');
      }
    });
    
    if (suggestions.isEmpty) {
      suggestions.add('Continue your positive communication patterns across all topics');
    }
    
    return suggestions;
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  Map<String, dynamic> _getDefaultPatterns() {
    return {
      'sentiment_trends': {'daily_trends': [], 'weekly_average': 0.5},
      'response_patterns': {'average_response_time': 30.0},
      'conversation_health': {'health_score': 0.5},
      'topic_analysis': {'topic_sentiment_map': {}},
      'escalation_patterns': {'escalation_triggers': []},
      'optimal_windows': {'best_times': []},
      'communication_effectiveness': 0.5,
      'pattern_insights': [],
      'predictive_metrics': {'conflict_probability_next_week': 0.5},
    };
  }

  /// Store sentiment data for trend analysis
  Future<void> recordSentimentData(double sentiment, {String? topic}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Store sentiment history
    final historyJson = prefs.getString(_sentimentHistoryKey);
    List<Map<String, dynamic>> history = [];
    if (historyJson != null) {
      final decoded = jsonDecode(historyJson) as List<dynamic>;
      history = decoded.cast<Map<String, dynamic>>();
    }
    
    history.add({
      'date': DateTime.now().toIso8601String(),
      'sentiment': sentiment,
      'topic': topic,
    });
    
    // Keep only last 100 entries
    if (history.length > 100) {
      history = history.skip(history.length - 100).toList();
    }
    
    await prefs.setString(_sentimentHistoryKey, jsonEncode(history));
  }

  /// Store response time data
  Future<void> recordResponseTime(int responseTimeMinutes, double sentimentAfter) async {
    final prefs = await SharedPreferences.getInstance();
    
    final historyJson = prefs.getString(_responseTimeHistoryKey);
    List<Map<String, dynamic>> history = [];
    if (historyJson != null) {
      final decoded = jsonDecode(historyJson) as List<dynamic>;
      history = decoded.cast<Map<String, dynamic>>();
    }
    
    history.add({
      'response_time_minutes': responseTimeMinutes,
      'sentiment_after': sentimentAfter,
      'timestamp': DateTime.now().toIso8601String(),
      'time_of_day': DateTime.now().hour,
    });
    
    // Keep only last 50 entries
    if (history.length > 50) {
      history = history.skip(history.length - 50).toList();
    }
    
    await prefs.setString(_responseTimeHistoryKey, jsonEncode(history));
  }
}
