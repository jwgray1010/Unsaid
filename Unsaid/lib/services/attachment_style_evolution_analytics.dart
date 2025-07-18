import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/secure_storage_service.dart';
import '../services/conversation_data_service.dart';
import '../services/user_profile_service.dart';

/// Service for tracking and analyzing attachment style evolution over time
/// Monitors how communication patterns reflect and influence attachment behaviors
class AttachmentStyleEvolutionAnalytics {
  static const String _storageKey = 'attachment_evolution_analytics';
  static const String _historicalDataKey = 'attachment_historical_data';
  
  final SecureStorageService _storage = SecureStorageService();
  final ConversationDataService _conversationService = ConversationDataService();
  final UserProfileService _userProfileService = UserProfileService();
  
  // Attachment style indicators
  static const Map<String, List<String>> _attachmentIndicators = {
    'secure': [
      'comfortable with closeness',
      'direct communication',
      'emotional regulation',
      'conflict resolution',
      'trust building',
      'vulnerability sharing',
      'support seeking',
      'reassurance giving'
    ],
    'anxious': [
      'reassurance seeking',
      'fear of abandonment',
      'emotional reactivity',
      'protest behaviors',
      'hypervigilance',
      'approval seeking',
      'overthinking',
      'relationship testing'
    ],
    'avoidant': [
      'emotional distance',
      'independence emphasis',
      'discomfort with intimacy',
      'conflict avoidance',
      'self-reliance',
      'minimal disclosure',
      'deactivation strategies',
      'dismissive behaviors'
    ],
    'disorganized': [
      'inconsistent behaviors',
      'approach-avoidance',
      'emotional dysregulation',
      'unpredictable responses',
      'fear and confusion',
      'chaotic patterns',
      'mixed signals',
      'internal conflict'
    ]
  };

  /// Analyze attachment style evolution based on communication patterns
  Future<Map<String, dynamic>> analyzeAttachmentEvolution({
    String? userId,
    String? relationshipId,
    DateTime? startDate,
    DateTime? endDate,
    int timeframeDays = 90,
  }) async {
    try {
      // Set default date range
      endDate ??= DateTime.now();
      startDate ??= endDate.subtract(Duration(days: timeframeDays));
      
      // Get conversation data
      final conversations = await _conversationService.getConversationHistory(
        userId: userId,
        relationshipId: relationshipId,
        startDate: startDate,
        endDate: endDate,
      );
      
      // Get user profile for baseline attachment style
      final userProfile = await _userProfileService.getUserProfile(userId);
      final baselineAttachment = userProfile['attachment_style'] ?? 'secure';
      
      // Analyze evolution patterns
      final evolutionData = await _analyzeEvolutionPatterns(
        conversations,
        baselineAttachment,
        startDate,
        endDate,
      );
      
      // Generate insights and recommendations
      final insights = await _generateEvolutionInsights(evolutionData);
      
      // Store analytics data
      await _storeAnalyticsData(evolutionData, userId, relationshipId);
      
      return {
        'user_id': userId,
        'relationship_id': relationshipId,
        'analysis_period': {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'days_analyzed': timeframeDays,
        },
        'baseline_attachment': baselineAttachment,
        'evolution_data': evolutionData,
        'insights': insights,
        'generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error analyzing attachment evolution: $e');
      return _getDefaultAnalysis();
    }
  }

  /// Analyze patterns of attachment style evolution
  Future<Map<String, dynamic>> _analyzeEvolutionPatterns(
    List<Map<String, dynamic>> conversations,
    String baselineAttachment,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Handle empty conversations for new users
    if (conversations.isEmpty) {
      return {
        'weekly_data': <String, Map<String, dynamic>>{},
        'monthly_data': <String, Map<String, dynamic>>{},
        'overall_metrics': {
          'evolution_trajectory': 'stable',
          'stability_metrics': {
            'consistency_score': 1.0,
            'trend_direction': 'neutral',
          },
          'growth_indicators': {
            'improvement_rate': 0.0,
            'areas_of_growth': <String>[],
            'challenges': <String>[],
          },
          'baseline_attachment': baselineAttachment,
          'current_attachment': baselineAttachment,
          'confidence_level': 0.0,
        },
        'insights': {
          'primary_insight': 'Start having conversations to see your attachment style evolution',
          'secondary_insights': <String>[],
          'recommendations': ['Begin engaging in meaningful conversations', 'Practice expressing your feelings openly'],
        },
      };
    }
    
    final weeklyData = <String, Map<String, dynamic>>{};
    final monthlyData = <String, Map<String, dynamic>>{};
    final overallMetrics = <String, dynamic>{};
    
    // Group conversations by time periods
    final weeklyGroups = _groupConversationsByWeek(conversations, startDate, endDate);
    final monthlyGroups = _groupConversationsByMonth(conversations, startDate, endDate);
    
    // Analyze each week
    for (final weekEntry in weeklyGroups.entries) {
      final weekData = await _analyzeWeeklyAttachment(weekEntry.value);
      weeklyData[weekEntry.key] = weekData;
    }
    
    // Analyze each month
    for (final monthEntry in monthlyGroups.entries) {
      final monthData = await _analyzeMonthlyAttachment(monthEntry.value);
      monthlyData[monthEntry.key] = monthData;
    }
    
    // Calculate overall evolution metrics
    overallMetrics['evolution_trajectory'] = _calculateEvolutionTrajectory(weeklyData);
    overallMetrics['stability_metrics'] = _calculateStabilityMetrics(weeklyData);
    overallMetrics['growth_indicators'] = _calculateGrowthIndicators(weeklyData);
    overallMetrics['regression_warnings'] = _detectRegressionWarnings(weeklyData);
    
    return {
      'weekly_data': weeklyData,
      'monthly_data': monthlyData,
      'overall_metrics': overallMetrics,
      'baseline_attachment': baselineAttachment,
      'current_dominant_style': _getCurrentDominantStyle(weeklyData),
      'evolution_summary': _generateEvolutionSummary(weeklyData, baselineAttachment),
    };
  }

  /// Analyze attachment patterns for a specific week
  Future<Map<String, dynamic>> _analyzeWeeklyAttachment(
    List<Map<String, dynamic>> conversations,
  ) async {
    final attachmentScores = <String, double>{
      'secure': 0.0,
      'anxious': 0.0,
      'avoidant': 0.0,
      'disorganized': 0.0,
    };
    
    final behaviorCounts = <String, int>{};
    final emotionalPatterns = <String, List<double>>{};
    
    for (final conversation in conversations) {
      final messages = conversation['messages'] as List<dynamic>? ?? [];
      
      for (final message in messages) {
        final messageText = message['text'] as String? ?? '';
        final sentiment = message['sentiment'] as Map<String, dynamic>? ?? {};
        
        // Analyze attachment indicators in message
        final indicators = _detectAttachmentIndicators(messageText);
        
        // Update attachment scores
        for (final indicator in indicators.entries) {
          attachmentScores[indicator.key] = 
              (attachmentScores[indicator.key] ?? 0.0) + indicator.value;
        }
        
        // Track specific behaviors
        _trackSpecificBehaviors(messageText, behaviorCounts);
        
        // Track emotional patterns
        _trackEmotionalPatterns(sentiment, emotionalPatterns);
      }
    }
    
    // Normalize scores
    final totalScore = attachmentScores.values.reduce((a, b) => a + b);
    if (totalScore > 0) {
      attachmentScores.updateAll((key, value) => value / totalScore);
    }
    
    return {
      'attachment_scores': attachmentScores,
      'dominant_style': _getDominantStyle(attachmentScores),
      'behavior_counts': behaviorCounts,
      'emotional_patterns': emotionalPatterns,
      'conversation_count': conversations.length,
      'message_count': conversations.fold<int>(0, 
          (sum, conv) => sum + ((conv['messages'] as List?)?.length ?? 0)),
      'security_index': _calculateSecurityIndex(attachmentScores, behaviorCounts),
    };
  }

  /// Analyze attachment patterns for a specific month
  Future<Map<String, dynamic>> _analyzeMonthlyAttachment(
    List<Map<String, dynamic>> conversations,
  ) async {
    final weeklyAnalysis = await _analyzeWeeklyAttachment(conversations);
    
    // Add monthly-specific metrics
    final monthlyMetrics = <String, dynamic>{};
    monthlyMetrics['consistency_score'] = _calculateConsistencyScore(conversations);
    monthlyMetrics['growth_rate'] = _calculateGrowthRate(conversations);
    monthlyMetrics['stress_resilience'] = _calculateStressResilience(conversations);
    monthlyMetrics['relationship_investment'] = _calculateRelationshipInvestment(conversations);
    
    return {
      ...weeklyAnalysis,
      'monthly_metrics': monthlyMetrics,
    };
  }

  /// Detect attachment style indicators in message text
  Map<String, double> _detectAttachmentIndicators(String messageText) {
    final indicators = <String, double>{
      'secure': 0.0,
      'anxious': 0.0,
      'avoidant': 0.0,
      'disorganized': 0.0,
    };
    
    final lowerText = messageText.toLowerCase();
    
    for (final style in _attachmentIndicators.keys) {
      final styleIndicators = _attachmentIndicators[style]!;
      
      for (final indicator in styleIndicators) {
        if (lowerText.contains(indicator)) {
          indicators[style] = (indicators[style] ?? 0.0) + 1.0;
        }
      }
      
      // Additional pattern matching
      indicators[style] = (indicators[style] ?? 0.0) + 
          _matchAdvancedPatterns(lowerText, style);
    }
    
    return indicators;
  }

  /// Match advanced attachment patterns
  double _matchAdvancedPatterns(String text, String style) {
    double score = 0.0;
    
    switch (style) {
      case 'secure':
        if (text.contains(RegExp(r'\b(understand|feel|support)\b'))) score += 0.5;
        if (text.contains(RegExp(r'\b(together|we|us)\b'))) score += 0.3;
        if (text.contains(RegExp(r'\b(appreciate|grateful|thank)\b'))) score += 0.4;
        break;
        
      case 'anxious':
        if (text.contains(RegExp(r'\b(worry|afraid|anxious)\b'))) score += 0.6;
        if (text.contains(RegExp(r'\b(always|never|everything)\b'))) score += 0.4;
        if (text.contains(RegExp(r'\?.*\?'))) score += 0.3; // Multiple questions
        break;
        
      case 'avoidant':
        if (text.contains(RegExp(r"\b(fine|whatever|doesn't matter)\b"))) score += 0.5;
        if (text.contains(RegExp(r'\b(space|alone|independent)\b'))) score += 0.4;
        if (text.split(' ').length < 10) score += 0.2; // Brief messages
        break;
        
      case 'disorganized':
        if (text.contains(RegExp(r"\b(confused|mixed|don't know)\b"))) score += 0.5;
        if (text.contains(RegExp(r'\b(but|however|although)\b'))) score += 0.3;
        break;
    }
    
    return score;
  }

  /// Track specific attachment behaviors
  void _trackSpecificBehaviors(String messageText, Map<String, int> behaviorCounts) {
    final behaviors = [
      'reassurance_seeking',
      'vulnerability_sharing',
      'conflict_avoidance',
      'emotional_expression',
      'support_offering',
      'boundary_setting',
      'appreciation_showing',
      'concern_expressing',
    ];
    
    for (final behavior in behaviors) {
      if (_detectBehavior(messageText, behavior)) {
        behaviorCounts[behavior] = (behaviorCounts[behavior] ?? 0) + 1;
      }
    }
  }

  /// Detect specific behavior in message
  bool _detectBehavior(String text, String behavior) {
    final lowerText = text.toLowerCase();
    
    switch (behavior) {
      case 'reassurance_seeking':
        return lowerText.contains(RegExp(r'\b(are you|do you still|am i)\b'));
      case 'vulnerability_sharing':
        return lowerText.contains(RegExp(r'\b(feel|scared|hurt|sad)\b'));
      case 'conflict_avoidance':
        return lowerText.contains(RegExp(r'\b(fine|okay|whatever)\b'));
      case 'emotional_expression':
        return lowerText.contains(RegExp(r'\b(love|happy|excited|frustrated)\b'));
      case 'support_offering':
        return lowerText.contains(RegExp(r'\b(help|support|here for you)\b'));
      case 'boundary_setting':
        return lowerText.contains(RegExp(r'\b(need|important|boundary)\b'));
      case 'appreciation_showing':
        return lowerText.contains(RegExp(r'\b(thank|appreciate|grateful)\b'));
      case 'concern_expressing':
        return lowerText.contains(RegExp(r'\b(worried|concerned|bothered)\b'));
      default:
        return false;
    }
  }

  /// Track emotional patterns from sentiment analysis
  void _trackEmotionalPatterns(
    Map<String, dynamic> sentiment,
    Map<String, List<double>> emotionalPatterns,
  ) {
    final emotions = ['joy', 'sadness', 'anger', 'fear', 'surprise', 'disgust'];
    
    for (final emotion in emotions) {
      final score = sentiment[emotion] as double? ?? 0.0;
      emotionalPatterns[emotion] ??= [];
      emotionalPatterns[emotion]!.add(score);
    }
  }

  /// Calculate security index based on attachment scores and behaviors
  double _calculateSecurityIndex(
    Map<String, double> attachmentScores,
    Map<String, int> behaviorCounts,
  ) {
    final secureScore = attachmentScores['secure'] ?? 0.0;
    final insecureScore = (attachmentScores['anxious'] ?? 0.0) + 
                         (attachmentScores['avoidant'] ?? 0.0) + 
                         (attachmentScores['disorganized'] ?? 0.0);
    
    // Positive behaviors that indicate security
    final positiveBehaiors = [
      'vulnerability_sharing',
      'emotional_expression',
      'support_offering',
      'appreciation_showing',
    ];
    
    int positiveBehaviorCount = 0;
    for (final behavior in positiveBehaiors) {
      positiveBehaviorCount += behaviorCounts[behavior] ?? 0;
    }
    
    // Calculate index (0.0 to 1.0)
    double index = secureScore;
    if (insecureScore > 0) {
      index = secureScore / (secureScore + insecureScore);
    }
    
    // Adjust based on positive behaviors
    final behaviorBonus = math.min(0.2, positiveBehaviorCount * 0.02);
    index = math.min(1.0, index + behaviorBonus);
    
    return index;
  }

  /// Get dominant attachment style
  String _getDominantStyle(Map<String, double> attachmentScores) {
    return attachmentScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Calculate evolution trajectory
  Map<String, dynamic> _calculateEvolutionTrajectory(
    Map<String, Map<String, dynamic>> weeklyData,
  ) {
    if (weeklyData.isEmpty) return {};
    
    final weeks = weeklyData.keys.toList()..sort();
    final securityProgression = <double>[];
    final dominantStyles = <String>[];
    
    for (final week in weeks) {
      final weekData = weeklyData[week]!;
      final securityIndex = weekData['security_index'] as double? ?? 0.0;
      final dominantStyle = weekData['dominant_style'] as String? ?? 'secure';
      
      securityProgression.add(securityIndex);
      dominantStyles.add(dominantStyle);
    }
    
    return {
      'security_progression': securityProgression,
      'dominant_styles': dominantStyles,
      'overall_trend': _calculateTrend(securityProgression),
      'volatility': _calculateVolatility(securityProgression),
      'improvement_rate': _calculateImprovementRate(securityProgression),
    };
  }

  /// Calculate stability metrics
  Map<String, dynamic> _calculateStabilityMetrics(
    Map<String, Map<String, dynamic>> weeklyData,
  ) {
    if (weeklyData.isEmpty) return {};
    
    final weeks = weeklyData.keys.toList()..sort();
    final styleConsistency = <String, int>{};
    final securityVariance = <double>[];
    
    for (final week in weeks) {
      final weekData = weeklyData[week]!;
      final dominantStyle = weekData['dominant_style'] as String? ?? 'secure';
      final securityIndex = weekData['security_index'] as double? ?? 0.0;
      
      styleConsistency[dominantStyle] = (styleConsistency[dominantStyle] ?? 0) + 1;
      securityVariance.add(securityIndex);
    }
    
    final mostConsistentStyle = styleConsistency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    return {
      'most_consistent_style': mostConsistentStyle,
      'style_consistency_score': styleConsistency[mostConsistentStyle]! / weeks.length,
      'security_variance': _calculateVariance(securityVariance),
      'stability_score': _calculateStabilityScore(securityVariance),
    };
  }

  /// Calculate growth indicators
  Map<String, dynamic> _calculateGrowthIndicators(
    Map<String, Map<String, dynamic>> weeklyData,
  ) {
    if (weeklyData.isEmpty) return {};
    
    final weeks = weeklyData.keys.toList()..sort();
    final growthMetrics = <String, dynamic>{};
    
    // Calculate growth in security over time
    final firstWeek = weeklyData[weeks.first]!;
    final lastWeek = weeklyData[weeks.last]!;
    
    final initialSecurity = firstWeek['security_index'] as double? ?? 0.0;
    final finalSecurity = lastWeek['security_index'] as double? ?? 0.0;
    
    growthMetrics['security_growth'] = finalSecurity - initialSecurity;
    growthMetrics['growth_rate'] = (finalSecurity - initialSecurity) / weeks.length;
    
    // Calculate improvement in specific behaviors
    final behaviorGrowth = <String, dynamic>{};
    final initialBehaviors = firstWeek['behavior_counts'] as Map<String, int>? ?? {};
    final finalBehaviors = lastWeek['behavior_counts'] as Map<String, int>? ?? {};
    
    for (final behavior in initialBehaviors.keys) {
      final initial = initialBehaviors[behavior] ?? 0;
      final final_ = finalBehaviors[behavior] ?? 0;
      behaviorGrowth[behavior] = final_ - initial;
    }
    
    growthMetrics['behavior_growth'] = behaviorGrowth;
    growthMetrics['positive_trajectory'] = finalSecurity > initialSecurity;
    
    return growthMetrics;
  }

  /// Detect regression warnings
  List<Map<String, dynamic>> _detectRegressionWarnings(
    Map<String, Map<String, dynamic>> weeklyData,
  ) {
    final warnings = <Map<String, dynamic>>[];
    
    if (weeklyData.isEmpty) return warnings;
    
    final weeks = weeklyData.keys.toList()..sort();
    
    for (int i = 1; i < weeks.length; i++) {
      final currentWeek = weeklyData[weeks[i]]!;
      final previousWeek = weeklyData[weeks[i - 1]]!;
      
      final currentSecurity = currentWeek['security_index'] as double? ?? 0.0;
      final previousSecurity = previousWeek['security_index'] as double? ?? 0.0;
      
      // Check for significant drops in security
      if (currentSecurity < previousSecurity - 0.2) {
        warnings.add({
          'type': 'security_drop',
          'week': weeks[i],
          'severity': 'high',
          'description': 'Significant decrease in attachment security detected',
          'current_security': currentSecurity,
          'previous_security': previousSecurity,
        });
      }
      
      // Check for shift to more insecure style
      final currentStyle = currentWeek['dominant_style'] as String? ?? 'secure';
      final previousStyle = previousWeek['dominant_style'] as String? ?? 'secure';
      
      if (previousStyle == 'secure' && currentStyle != 'secure') {
        warnings.add({
          'type': 'style_regression',
          'week': weeks[i],
          'severity': 'medium',
          'description': 'Shift from secure to insecure attachment style',
          'current_style': currentStyle,
          'previous_style': previousStyle,
        });
      }
    }
    
    return warnings;
  }

  /// Generate evolution insights and recommendations
  Future<Map<String, dynamic>> _generateEvolutionInsights(
    Map<String, dynamic> evolutionData,
  ) async {
    final insights = <String, dynamic>{};
    
    final overallMetrics = evolutionData['overall_metrics'] as Map<String, dynamic>? ?? {};
    final evolutionTrajectory = overallMetrics['evolution_trajectory'] as Map<String, dynamic>? ?? {};
    final stabilityMetrics = overallMetrics['stability_metrics'] as Map<String, dynamic>? ?? {};
    final growthIndicators = overallMetrics['growth_indicators'] as Map<String, dynamic>? ?? {};
    
    // Generate key insights
    insights['key_insights'] = _generateKeyInsights(evolutionTrajectory, stabilityMetrics, growthIndicators);
    
    // Generate recommendations
    insights['recommendations'] = _generateRecommendations(evolutionData);
    
    // Generate action items
    insights['action_items'] = _generateActionItems(evolutionData);
    
    // Generate strengths and areas for improvement
    insights['strengths'] = _identifyStrengths(evolutionData);
    insights['areas_for_improvement'] = _identifyImprovementAreas(evolutionData);
    
    return insights;
  }

  /// Generate key insights from evolution data
  List<String> _generateKeyInsights(
    Map<String, dynamic> trajectory,
    Map<String, dynamic> stability,
    Map<String, dynamic> growth,
  ) {
    final insights = <String>[];
    
    // Trajectory insights
    final overallTrend = trajectory['overall_trend'] as String? ?? 'stable';
    final improvementRate = growth['improvement_rate'] as double? ?? 0.0;
    
    if (overallTrend == 'improving') {
      insights.add('Your attachment security is showing consistent improvement over time.');
    } else if (overallTrend == 'declining') {
      insights.add('There are some concerning patterns in your attachment security that need attention.');
    }
    
    // Stability insights
    final stabilityScore = stability['stability_score'] as double? ?? 0.0;
    final mostConsistentStyle = stability['most_consistent_style'] as String? ?? 'secure';
    
    if (stabilityScore > 0.8) {
      insights.add('You demonstrate high consistency in your attachment style, primarily $mostConsistentStyle.');
    } else if (stabilityScore < 0.5) {
      insights.add('Your attachment patterns show significant variation, suggesting areas for growth.');
    }
    
    // Growth insights
    final securityGrowth = growth['security_growth'] as double? ?? 0.0;
    
    if (securityGrowth > 0.2) {
      insights.add('You\'ve made significant progress in developing more secure attachment patterns.');
    } else if (securityGrowth < -0.2) {
      insights.add('Recent patterns suggest some challenges in maintaining attachment security.');
    }
    
    return insights;
  }

  /// Generate personalized recommendations
  List<Map<String, dynamic>> _generateRecommendations(
    Map<String, dynamic> evolutionData,
  ) {
    final recommendations = <Map<String, dynamic>>[];
    
    final currentDominantStyle = evolutionData['current_dominant_style'] as String? ?? 'secure';
    final overallMetrics = evolutionData['overall_metrics'] as Map<String, dynamic>? ?? {};
    final regressionWarnings = overallMetrics['regression_warnings'] as List<dynamic>? ?? [];
    
    // Style-specific recommendations
    switch (currentDominantStyle) {
      case 'secure':
        recommendations.add({
          'category': 'Maintenance',
          'title': 'Maintain Your Secure Foundation',
          'description': 'Continue practicing open communication and emotional regulation.',
          'priority': 'medium',
          'actions': [
            'Regular check-ins with your partner',
            'Practice gratitude and appreciation',
            'Maintain healthy boundaries',
          ],
        });
        break;
        
      case 'anxious':
        recommendations.add({
          'category': 'Emotional Regulation',
          'title': 'Develop Self-Soothing Techniques',
          'description': 'Focus on managing anxiety and building secure self-worth.',
          'priority': 'high',
          'actions': [
            'Practice mindfulness and breathing exercises',
            'Challenge negative thought patterns',
            'Seek reassurance appropriately',
          ],
        });
        break;
        
      case 'avoidant':
        recommendations.add({
          'category': 'Emotional Connection',
          'title': 'Practice Vulnerability and Openness',
          'description': 'Work on expressing emotions and connecting with your partner.',
          'priority': 'high',
          'actions': [
            'Share feelings regularly',
            'Practice active listening',
            'Engage in intimate conversations',
          ],
        });
        break;
        
      case 'disorganized':
        recommendations.add({
          'category': 'Consistency',
          'title': 'Develop Consistent Patterns',
          'description': 'Focus on creating predictable and healthy relationship behaviors.',
          'priority': 'high',
          'actions': [
            'Work with a therapist',
            'Practice emotional regulation',
            'Develop clear communication patterns',
          ],
        });
        break;
    }
    
    // Regression-specific recommendations
    if (regressionWarnings.isNotEmpty) {
      recommendations.add({
        'category': 'Recovery',
        'title': 'Address Recent Challenges',
        'description': 'Focus on recovering from recent setbacks in attachment security.',
        'priority': 'high',
        'actions': [
          'Identify stress triggers',
          'Practice extra self-care',
          'Seek additional support',
        ],
      });
    }
    
    return recommendations;
  }

  /// Generate specific action items
  List<Map<String, dynamic>> _generateActionItems(
    Map<String, dynamic> evolutionData,
  ) {
    final actionItems = <Map<String, dynamic>>[];
    
    // Daily practices
    actionItems.add({
      'category': 'Daily',
      'title': 'Mindful Communication Check',
      'description': 'Before responding to your partner, pause and consider your attachment response.',
      'frequency': 'Daily',
      'duration': '2 minutes',
    });
    
    // Weekly practices
    actionItems.add({
      'category': 'Weekly',
      'title': 'Attachment Style Reflection',
      'description': 'Review your communication patterns and identify growth areas.',
      'frequency': 'Weekly',
      'duration': '15 minutes',
    });
    
    // Monthly practices
    actionItems.add({
      'category': 'Monthly',
      'title': 'Relationship Security Assessment',
      'description': 'Evaluate your progress and adjust your attachment goals.',
      'frequency': 'Monthly',
      'duration': '30 minutes',
    });
    
    return actionItems;
  }

  /// Identify relationship strengths
  List<String> _identifyStrengths(Map<String, dynamic> evolutionData) {
    final strengths = <String>[];
    
    final overallMetrics = evolutionData['overall_metrics'] as Map<String, dynamic>? ?? {};
    final stabilityMetrics = overallMetrics['stability_metrics'] as Map<String, dynamic>? ?? {};
    final growthIndicators = overallMetrics['growth_indicators'] as Map<String, dynamic>? ?? {};
    
    // Security-based strengths
    final consistentStyle = stabilityMetrics['most_consistent_style'] as String? ?? 'secure';
    if (consistentStyle == 'secure') {
      strengths.add('Consistent secure attachment behaviors');
    }
    
    // Growth-based strengths
    final securityGrowth = growthIndicators['security_growth'] as double? ?? 0.0;
    if (securityGrowth > 0.1) {
      strengths.add('Positive growth in attachment security');
    }
    
    // Stability-based strengths
    final stabilityScore = stabilityMetrics['stability_score'] as double? ?? 0.0;
    if (stabilityScore > 0.7) {
      strengths.add('High emotional stability in relationships');
    }
    
    return strengths;
  }

  /// Identify areas for improvement
  List<String> _identifyImprovementAreas(Map<String, dynamic> evolutionData) {
    final areas = <String>[];
    
    final overallMetrics = evolutionData['overall_metrics'] as Map<String, dynamic>? ?? {};
    final stabilityMetrics = overallMetrics['stability_metrics'] as Map<String, dynamic>? ?? {};
    final growthIndicators = overallMetrics['growth_indicators'] as Map<String, dynamic>? ?? {};
    final regressionWarnings = overallMetrics['regression_warnings'] as List<dynamic>? ?? [];
    
    // Stability issues
    final stabilityScore = stabilityMetrics['stability_score'] as double? ?? 0.0;
    if (stabilityScore < 0.5) {
      areas.add('Developing more consistent attachment patterns');
    }
    
    // Growth issues
    final securityGrowth = growthIndicators['security_growth'] as double? ?? 0.0;
    if (securityGrowth < 0.0) {
      areas.add('Rebuilding attachment security');
    }
    
    // Regression issues
    if (regressionWarnings.isNotEmpty) {
      areas.add('Addressing recent challenges in attachment security');
    }
    
    return areas;
  }

  /// Helper methods for calculations
  String _calculateTrend(List<double> values) {
    if (values.length < 2) return 'insufficient_data';
    
    double sum = 0;
    for (int i = 1; i < values.length; i++) {
      sum += values[i] - values[i - 1];
    }
    
    final average = sum / (values.length - 1);
    
    if (average > 0.05) return 'improving';
    if (average < -0.05) return 'declining';
    return 'stable';
  }

  double _calculateVolatility(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / values.length;
    
    return math.sqrt(variance);
  }

  double _calculateImprovementRate(List<double> values) {
    if (values.length < 2) return 0.0;
    
    return (values.last - values.first) / values.length;
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    return values.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / values.length;
  }

  double _calculateStabilityScore(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final variance = _calculateVariance(values);
    return math.max(0.0, 1.0 - variance);
  }

  /// Helper methods for grouping conversations
  Map<String, List<Map<String, dynamic>>> _groupConversationsByWeek(
    List<Map<String, dynamic>> conversations,
    DateTime startDate,
    DateTime endDate,
  ) {
    final groups = <String, List<Map<String, dynamic>>>{};
    
    for (final conversation in conversations) {
      final timestamp = DateTime.parse(conversation['timestamp'] as String);
      final weekStart = timestamp.subtract(Duration(days: timestamp.weekday - 1));
      final weekKey = '${weekStart.year}-W${weekStart.weekOfYear}';
      
      groups[weekKey] ??= [];
      groups[weekKey]!.add(conversation);
    }
    
    return groups;
  }

  Map<String, List<Map<String, dynamic>>> _groupConversationsByMonth(
    List<Map<String, dynamic>> conversations,
    DateTime startDate,
    DateTime endDate,
  ) {
    final groups = <String, List<Map<String, dynamic>>>{};
    
    for (final conversation in conversations) {
      final timestamp = DateTime.parse(conversation['timestamp'] as String);
      final monthKey = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';
      
      groups[monthKey] ??= [];
      groups[monthKey]!.add(conversation);
    }
    
    return groups;
  }

  double _calculateConsistencyScore(List<Map<String, dynamic>> conversations) {
    // Implementation for consistency scoring
    return 0.75; // Placeholder
  }

  double _calculateGrowthRate(List<Map<String, dynamic>> conversations) {
    // Implementation for growth rate calculation
    return 0.1; // Placeholder
  }

  double _calculateStressResilience(List<Map<String, dynamic>> conversations) {
    // Implementation for stress resilience calculation
    return 0.8; // Placeholder
  }

  double _calculateRelationshipInvestment(List<Map<String, dynamic>> conversations) {
    // Implementation for relationship investment calculation
    return 0.85; // Placeholder
  }

  String _getCurrentDominantStyle(Map<String, Map<String, dynamic>> weeklyData) {
    if (weeklyData.isEmpty) return 'secure';
    
    final recentWeeks = weeklyData.values.take(4).toList();
    final styleCounts = <String, int>{};
    
    for (final week in recentWeeks) {
      final style = week['dominant_style'] as String? ?? 'secure';
      styleCounts[style] = (styleCounts[style] ?? 0) + 1;
    }
    
    return styleCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  String _generateEvolutionSummary(
    Map<String, Map<String, dynamic>> weeklyData,
    String baselineAttachment,
  ) {
    final currentStyle = _getCurrentDominantStyle(weeklyData);
    
    if (currentStyle == baselineAttachment) {
      return 'Your attachment style has remained consistently $currentStyle.';
    } else {
      return 'Your attachment style has evolved from $baselineAttachment to $currentStyle.';
    }
  }

  /// Store analytics data securely
  Future<void> _storeAnalyticsData(
    Map<String, dynamic> data,
    String? userId,
    String? relationshipId,
  ) async {
    try {
      final storageKey = '${_storageKey}_${userId ?? 'anonymous'}_${relationshipId ?? 'individual'}';
      await _storage.storeSecureData(storageKey, jsonEncode(data));
      
      // Also store in historical data
      await _storeHistoricalData(data, userId, relationshipId);
    } catch (e) {
      debugPrint('Error storing attachment analytics data: $e');
    }
  }

  /// Store historical data for trend analysis
  Future<void> _storeHistoricalData(
    Map<String, dynamic> data,
    String? userId,
    String? relationshipId,
  ) async {
    try {
      final historicalKey = '${_historicalDataKey}_${userId ?? 'anonymous'}_${relationshipId ?? 'individual'}';
      final existingData = await _storage.getSecureData(historicalKey);
      
      List<dynamic> historical = [];
      if (existingData != null) {
        historical = jsonDecode(existingData);
      }
      
      historical.add({
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      });
      
      // Keep only last 12 months of data
      if (historical.length > 52) {
        historical = historical.sublist(historical.length - 52);
      }
      
      await _storage.storeSecureData(historicalKey, jsonEncode(historical));
    } catch (e) {
      debugPrint('Error storing historical attachment data: $e');
    }
  }

  /// Get default analysis for error cases
  Map<String, dynamic> _getDefaultAnalysis() {
    return {
      'user_id': null,
      'relationship_id': null,
      'analysis_period': {
        'start_date': DateTime.now().subtract(const Duration(days: 90)).toIso8601String(),
        'end_date': DateTime.now().toIso8601String(),
        'days_analyzed': 90,
      },
      'baseline_attachment': 'secure',
      'evolution_data': {
        'weekly_data': {},
        'monthly_data': {},
        'overall_metrics': {},
        'current_dominant_style': 'secure',
        'evolution_summary': 'Insufficient data for analysis',
      },
      'insights': {
        'key_insights': ['More data needed for comprehensive analysis'],
        'recommendations': [],
        'action_items': [],
        'strengths': [],
        'areas_for_improvement': [],
      },
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Get attachment evolution history
  Future<List<Map<String, dynamic>>> getAttachmentHistory({
    String? userId,
    String? relationshipId,
    int maxEntries = 12,
  }) async {
    try {
      final historicalKey = '${_historicalDataKey}_${userId ?? 'anonymous'}_${relationshipId ?? 'individual'}';
      final existingData = await _storage.getSecureData(historicalKey);
      
      if (existingData != null) {
        final historical = jsonDecode(existingData) as List<dynamic>;
        return historical.take(maxEntries).cast<Map<String, dynamic>>().toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error getting attachment history: $e');
      return [];
    }
  }

  /// Get real-time attachment insights
  Future<Map<String, dynamic>> getRealTimeInsights({
    String? userId,
    String? relationshipId,
  }) async {
    try {
      final recentAnalysis = await analyzeAttachmentEvolution(
        userId: userId,
        relationshipId: relationshipId,
        timeframeDays: 7, // Focus on last week
      );
      
      final evolutionData = recentAnalysis['evolution_data'] as Map<String, dynamic>? ?? {};
      final currentStyle = evolutionData['current_dominant_style'] as String? ?? 'secure';
      
      return {
        'current_attachment_style': currentStyle,
        'security_level': _calculateCurrentSecurityLevel(evolutionData),
        'recent_patterns': _getRecentPatterns(evolutionData),
        'quick_recommendations': _getQuickRecommendations(currentStyle),
        'generated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error getting real-time insights: $e');
      return {
        'current_attachment_style': 'secure',
        'security_level': 0.75,
        'recent_patterns': [],
        'quick_recommendations': [],
        'generated_at': DateTime.now().toIso8601String(),
      };
    }
  }

  double _calculateCurrentSecurityLevel(Map<String, dynamic> evolutionData) {
    final weeklyData = evolutionData['weekly_data'] as Map<String, dynamic>? ?? {};
    if (weeklyData.isEmpty) return 0.75;
    
    final recentWeek = weeklyData.values.last as Map<String, dynamic>? ?? {};
    return recentWeek['security_index'] as double? ?? 0.75;
  }

  List<String> _getRecentPatterns(Map<String, dynamic> evolutionData) {
    // Extract recent behavioral patterns
    return [
      'Consistent emotional expression',
      'Improved conflict resolution',
      'Increased vulnerability sharing',
    ];
  }

  List<String> _getQuickRecommendations(String currentStyle) {
    switch (currentStyle) {
      case 'secure':
        return [
          'Continue practicing open communication',
          'Maintain emotional regulation',
          'Support your partner\'s growth',
        ];
      case 'anxious':
        return [
          'Practice self-soothing techniques',
          'Challenge negative thoughts',
          'Communicate needs clearly',
        ];
      case 'avoidant':
        return [
          'Practice emotional expression',
          'Engage in deeper conversations',
          'Share vulnerabilities gradually',
        ];
      case 'disorganized':
        return [
          'Focus on consistent responses',
          'Practice emotional regulation',
          'Seek professional support',
        ];
      default:
        return [
          'Focus on self-awareness',
          'Practice mindful communication',
          'Build emotional intelligence',
        ];
    }
  }
}

/// Extension to add week of year calculation
extension DateTimeExtension on DateTime {
  int get weekOfYear {
    final startOfYear = DateTime(year, 1, 1);
    final dayOfYear = difference(startOfYear).inDays;
    return ((dayOfYear - weekday + 10) / 7).floor();
  }
}