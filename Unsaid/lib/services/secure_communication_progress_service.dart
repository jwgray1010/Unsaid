import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'relationship_insights_service.dart';
import 'unified_analytics_service.dart';
import 'personality_driven_analyzer.dart';

/// Service for tracking and calculating secure communication progress
class SecureCommunicationProgressService {
  static const String _progressKey = 'secure_communication_progress';
  static const String _milestoneKey = 'secure_communication_milestones';
  static const String _lastCalculationKey = 'last_progress_calculation';
  
  final RelationshipInsightsService _insightsService = RelationshipInsightsService();
  final UnifiedAnalyticsService _analyticsService = UnifiedAnalyticsService();
  final PersonalityDrivenAnalyzer _personalityAnalyzer = PersonalityDrivenAnalyzer();

  /// Get comprehensive secure communication progress
  Future<Map<String, dynamic>> getSecureCommunicationProgress({
    String? userPersonalityType,
    String? userCommunicationStyle,
    String? partnerPersonalityType,
    String? partnerCommunicationStyle,
  }) async {
    try {
      // Get real data from existing services
      final insights = await _insightsService.generateRelationshipInsights();
      final analytics = await _analyticsService.getAnalytics();
      
      // Calculate progress based on real data
      final progress = await _calculateProgress(
        insights: insights,
        analytics: analytics,
        userPersonalityType: userPersonalityType,
        userCommunicationStyle: userCommunicationStyle,
        partnerPersonalityType: partnerPersonalityType,
        partnerCommunicationStyle: partnerCommunicationStyle,
      );
      
      // Store progress for trend tracking
      await _storeProgress(progress);
      
      return progress;
    } catch (e) {
      print('Error getting secure communication progress: $e');
      return _getDefaultProgress();
    }
  }

  /// Calculate progress based on real data from existing services
  Future<Map<String, dynamic>> _calculateProgress({
    required Map<String, dynamic> insights,
    required Map<String, dynamic> analytics,
    String? userPersonalityType,
    String? userCommunicationStyle,
    String? partnerPersonalityType,
    String? partnerCommunicationStyle,
  }) async {
    
    // Base progress calculation from attachment styles
    double baseProgress = _calculateAttachmentProgress(
      userPersonalityType ?? insights['your_style'],
      partnerPersonalityType ?? insights['partner_style'],
    );
    
    // Communication style progress
    double commProgress = _calculateCommunicationProgress(
      userCommunicationStyle ?? insights['your_comm'],
      partnerCommunicationStyle ?? insights['partner_comm'],
    );
    
    // Behavioral progress from analytics
    double behavioralProgress = _calculateBehavioralProgress(analytics);
    
    // Real-time usage progress
    double usageProgress = _calculateUsageProgress(insights, analytics);
    
    // Combine all progress metrics
    double overallProgress = (baseProgress * 0.3) + 
                           (commProgress * 0.25) + 
                           (behavioralProgress * 0.25) + 
                           (usageProgress * 0.2);
    
    // Ensure progress is between 0 and 1
    overallProgress = overallProgress.clamp(0.0, 1.0);
    
    // Determine if this is an individual user
    bool isIndividual = (partnerPersonalityType == null || partnerCommunicationStyle == null);
    
    // Calculate milestones
    final milestones = await _calculateMilestones(overallProgress, insights, analytics, isIndividual: isIndividual);
    
    // Calculate next steps
    final nextSteps = _calculateNextSteps(overallProgress, insights, analytics, isIndividual: isIndividual);
    
    // Calculate weekly trend
    final weeklyTrend = await _calculateWeeklyTrend();
    
    return {
      'overall_progress': overallProgress,
      'progress_percentage': (overallProgress * 100).round(),
      'progress_level': _getProgressLevel(overallProgress, isIndividual: isIndividual),
      'progress_label': _getProgressLabel(overallProgress),
      'milestones': milestones,
      'next_steps': nextSteps,
      'weekly_trend': weeklyTrend,
      'breakdown': {
        'attachment_security': baseProgress,
        'communication_effectiveness': commProgress,
        'behavioral_patterns': behavioralProgress,
        'active_usage': usageProgress,
      },
      'time_to_next_level': _calculateTimeToNextLevel(overallProgress, analytics),
      'achievements': _getAchievements(overallProgress, insights, analytics, isIndividual: isIndividual),
      'focus_areas': _getFocusAreas(insights, analytics, isIndividual: isIndividual),
      'is_individual': isIndividual,
    };
  }

  /// Calculate progress based on attachment styles
  double _calculateAttachmentProgress(String? userStyle, String? partnerStyle) {
    final attachmentScores = {
      'Secure': 1.0,
      'Secure Attachment': 1.0,
      'Anxious': 0.4,
      'Anxious Attachment': 0.4,
      'Avoidant': 0.3,
      'Dismissive Avoidant': 0.3,
      'Disorganized': 0.2,
      'Disorganized/Fearful Avoidant': 0.2,
      'Fearful-Avoidant': 0.25,
    };
    
    double userScore = attachmentScores[userStyle] ?? 0.5;
    
    // If no partner, focus on individual growth toward secure attachment
    if (partnerStyle == null) {
      // Individual progress: weight more heavily on personal growth
      return userScore * 0.8 + 0.2; // Add base progress for self-awareness
    }
    
    double partnerScore = attachmentScores[partnerStyle] ?? 0.5;
    
    // Couple progress: average the scores
    return (userScore + partnerScore) / 2;
  }

  /// Calculate progress based on communication styles
  double _calculateCommunicationProgress(String? userComm, String? partnerComm) {
    final commScores = {
      'Assertive': 1.0,
      'Diplomatic': 0.8,
      'Direct': 0.7,
      'Passive': 0.4,
      'Aggressive': 0.2,
    };
    
    double userScore = commScores[userComm] ?? 0.5;
    
    // If no partner, focus on individual communication skills
    if (partnerComm == null) {
      // Individual progress: reward self-awareness and skill building
      return userScore * 0.9 + 0.1; // Slight boost for working on self
    }
    
    double partnerScore = commScores[partnerComm] ?? 0.5;
    
    return (userScore + partnerScore) / 2;
  }

  /// Calculate behavioral progress from analytics
  double _calculateBehavioralProgress(Map<String, dynamic> analytics) {
    double score = 0.0;
    
    // Positive sentiment score
    final positiveSentiment = (analytics['positive_sentiment'] as double?) ?? 0.0;
    score += positiveSentiment * 0.3;
    
    // Consistency score (messages per week)
    final weeklyMessages = (analytics['weekly_messages'] as int?) ?? 0;
    double consistencyScore = (weeklyMessages / 50).clamp(0.0, 1.0); // Normalize to 50 messages
    score += consistencyScore * 0.2;
    
    // Compatibility score
    final compatibilityScore = (analytics['compatibility_score'] as double?) ?? 0.0;
    score += compatibilityScore * 0.3;
    
    // Growth trend
    final trend = analytics['communication_trend'] as String? ?? 'steady';
    double trendScore = trend == 'improving' ? 0.2 : (trend == 'steady' ? 0.1 : 0.0);
    score += trendScore;
    
    return score.clamp(0.0, 1.0);
  }

  /// Calculate usage progress
  double _calculateUsageProgress(Map<String, dynamic> insights, Map<String, dynamic> analytics) {
    double score = 0.0;
    
    // Active usage of analyzer
    final weeklyMessages = (analytics['weekly_messages'] as int?) ?? 0;
    if (weeklyMessages > 0) score += 0.3;
    
    // Has recommendations
    final recommendations = insights['ai_recommendations'] as List<dynamic>? ?? [];
    if (recommendations.isNotEmpty) score += 0.2;
    
    // Has growth areas identified
    final growthAreas = insights['growth_areas'] as List<dynamic>? ?? [];
    if (growthAreas.isNotEmpty) score += 0.2;
    
    // Has strengths identified
    final strengths = insights['strengths'] as List<dynamic>? ?? [];
    if (strengths.isNotEmpty) score += 0.2;
    
    // Regular usage (more than 5 messages this week)
    if (weeklyMessages > 5) score += 0.1;
    
    return score.clamp(0.0, 1.0);
  }

  /// Calculate milestones based on progress
  Future<List<Map<String, dynamic>>> _calculateMilestones(
    double progress, 
    Map<String, dynamic> insights, 
    Map<String, dynamic> analytics,
    {bool isIndividual = false}
  ) async {
    final milestones = <Map<String, dynamic>>[];
    
    if (isIndividual) {
      // Individual milestones focused on personal growth
      milestones.add({
        'title': 'Self-Awareness',
        'description': 'Discovered your communication and attachment patterns',
        'progress_required': 0.2,
        'completed': progress >= 0.2,
        'icon': 'lightbulb',
      });
      
      milestones.add({
        'title': 'Personal Growth',
        'description': 'Actively working on secure communication skills',
        'progress_required': 0.4,
        'completed': progress >= 0.4,
        'icon': 'psychology',
      });
      
      milestones.add({
        'title': 'Emotional Regulation',
        'description': 'Managing emotions and responses effectively',
        'progress_required': 0.6,
        'completed': progress >= 0.6,
        'icon': 'favorite',
      });
      
      milestones.add({
        'title': 'Secure Individual',
        'description': 'Demonstrating secure attachment patterns',
        'progress_required': 0.8,
        'completed': progress >= 0.8,
        'icon': 'verified',
      });
      
      milestones.add({
        'title': 'Communication Master',
        'description': 'Ready for healthy relationships',
        'progress_required': 1.0,
        'completed': progress >= 1.0,
        'icon': 'star',
      });
    } else {
      // Couple milestones (existing code)
      milestones.add({
        'title': 'Communication Awareness',
        'description': 'Started using the analyzer and identifying patterns',
        'progress_required': 0.2,
        'completed': progress >= 0.2,
        'icon': 'lightbulb',
      });
      
      milestones.add({
        'title': 'Pattern Recognition',
        'description': 'Recognized your communication and attachment styles',
        'progress_required': 0.4,
        'completed': progress >= 0.4,
        'icon': 'psychology',
      });
      
      milestones.add({
        'title': 'Active Improvement',
        'description': 'Consistently working on identified growth areas',
        'progress_required': 0.6,
        'completed': progress >= 0.6,
        'icon': 'trending_up',
      });
      
      milestones.add({
        'title': 'Secure Communication',
        'description': 'Demonstrating secure communication patterns',
        'progress_required': 0.8,
        'completed': progress >= 0.8,
        'icon': 'verified',
      });
      
      milestones.add({
        'title': 'Relationship Mastery',
        'description': 'Maintaining secure attachment and communication',
        'progress_required': 1.0,
        'completed': progress >= 1.0,
        'icon': 'star',
      });
    }
    
    return milestones;
  }

  /// Calculate next steps based on current progress
  List<Map<String, dynamic>> _calculateNextSteps(
    double progress, 
    Map<String, dynamic> insights, 
    Map<String, dynamic> analytics,
    {bool isIndividual = false}
  ) {
    final nextSteps = <Map<String, dynamic>>[];
    
    if (isIndividual) {
      // Individual-focused next steps
      if (progress < 0.2) {
        nextSteps.add({
          'title': 'Discover Your Patterns',
          'description': 'Take time to understand your communication style and attachment patterns',
          'priority': 'high',
          'estimated_time': '1-2 weeks',
        });
      } else if (progress < 0.4) {
        nextSteps.add({
          'title': 'Practice Self-Reflection',
          'description': 'Journal about your communication patterns and triggers',
          'priority': 'high',
          'estimated_time': '2-3 weeks',
        });
      } else if (progress < 0.6) {
        nextSteps.add({
          'title': 'Build Emotional Skills',
          'description': 'Practice emotional regulation and self-soothing techniques',
          'priority': 'medium',
          'estimated_time': '3-4 weeks',
        });
      } else if (progress < 0.8) {
        nextSteps.add({
          'title': 'Maintain Growth',
          'description': 'Continue practicing secure communication in all relationships',
          'priority': 'medium',
          'estimated_time': '4-6 weeks',
        });
      } else {
        nextSteps.add({
          'title': 'Model Security',
          'description': 'Help others by modeling secure communication',
          'priority': 'low',
          'estimated_time': 'Ongoing',
        });
      }
    } else {
      // Couple-focused next steps (existing logic)
      if (progress < 0.2) {
        nextSteps.add({
          'title': 'Use the Analyzer More',
          'description': 'Start using the keyboard analyzer when messaging',
          'priority': 'high',
          'estimated_time': '1-2 weeks',
        });
      } else if (progress < 0.4) {
        nextSteps.add({
          'title': 'Identify Growth Areas',
          'description': 'Focus on the growth areas identified in your insights',
          'priority': 'high',
          'estimated_time': '2-3 weeks',
        });
      } else if (progress < 0.6) {
        nextSteps.add({
          'title': 'Practice Secure Behaviors',
          'description': 'Use Partner Practice and follow AI recommendations',
          'priority': 'medium',
          'estimated_time': '3-4 weeks',
        });
      } else if (progress < 0.8) {
        nextSteps.add({
          'title': 'Maintain Consistency',
          'description': 'Keep up your secure communication patterns',
          'priority': 'medium',
          'estimated_time': '4-6 weeks',
        });
      } else {
        nextSteps.add({
          'title': 'Help Others',
          'description': 'Share your secure communication knowledge',
          'priority': 'low',
          'estimated_time': 'Ongoing',
        });
      }
    }
    
    return nextSteps;
  }

  /// Calculate weekly trend
  Future<List<Map<String, dynamic>>> _calculateWeeklyTrend() async {
    final prefs = await SharedPreferences.getInstance();
    final savedProgress = prefs.getStringList(_progressKey) ?? [];
    
    final trend = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    // Generate last 7 days of data
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayName = _getDayName(date.weekday);
      
      // Try to find real data for this day, otherwise simulate based on current progress
      double dayProgress = 0.0;
      if (savedProgress.isNotEmpty) {
        // Use real saved data if available
        final recentProgress = savedProgress.length > i ? 
          double.tryParse(savedProgress[savedProgress.length - 1 - i]) ?? 0.0 : 0.0;
        dayProgress = recentProgress;
      } else {
        // Simulate realistic progress trend
        dayProgress = 0.3 + (Random().nextDouble() * 0.4);
      }
      
      trend.add({
        'day': dayName,
        'progress': dayProgress,
        'date': date.toIso8601String(),
      });
    }
    
    return trend;
  }

  /// Get progress level name
  String _getProgressLevel(double progress, {bool isIndividual = false}) {
    if (isIndividual) {
      if (progress >= 0.8) return 'Secure Individual';
      if (progress >= 0.6) return 'Growing Individual';
      if (progress >= 0.4) return 'Self-Aware Individual';
      if (progress >= 0.2) return 'Learning Individual';
      return 'Beginning Individual';
    } else {
      if (progress >= 0.8) return 'Secure Attachment';
      if (progress >= 0.6) return 'Growing Communicator';
      if (progress >= 0.4) return 'Aware Communicator';
      if (progress >= 0.2) return 'Learning Communicator';
      return 'Beginning Communicator';
    }
  }

  /// Get progress label
  String _getProgressLabel(double progress) {
    if (progress >= 0.8) return 'Excellent';
    if (progress >= 0.6) return 'Good';
    if (progress >= 0.4) return 'Developing';
    if (progress >= 0.2) return 'Starting';
    return 'Beginning';
  }

  /// Calculate time to next level
  String _calculateTimeToNextLevel(double progress, Map<String, dynamic> analytics) {
    final weeklyMessages = (analytics['weekly_messages'] as int?) ?? 0;
    final trend = analytics['communication_trend'] as String? ?? 'steady';
    
    double weeklyGrowth = 0.02; // Base growth rate
    
    if (trend == 'improving') weeklyGrowth = 0.05;
    if (weeklyMessages > 10) weeklyGrowth += 0.02;
    if (weeklyMessages > 20) weeklyGrowth += 0.02;
    
    double progressToNextLevel = 0.2 - (progress % 0.2);
    if (progressToNextLevel == 0.0) progressToNextLevel = 0.2;
    
    int weeksToNext = (progressToNextLevel / weeklyGrowth).ceil();
    
    if (weeksToNext <= 1) return '1 week';
    if (weeksToNext <= 4) return '$weeksToNext weeks';
    if (weeksToNext <= 8) return '${(weeksToNext / 4).ceil()} months';
    return '2+ months';
  }

  /// Get achievements based on progress
  List<Map<String, dynamic>> _getAchievements(
    double progress, 
    Map<String, dynamic> insights, 
    Map<String, dynamic> analytics,
    {bool isIndividual = false}
  ) {
    final achievements = <Map<String, dynamic>>[];
    
    final weeklyMessages = (analytics['weekly_messages'] as int?) ?? 0;
    final positiveSentiment = (analytics['positive_sentiment'] as double?) ?? 0.0;
    
    if (weeklyMessages > 0) {
      achievements.add({
        'title': isIndividual ? 'Self-Discovery Started' : 'First Analysis',
        'description': isIndividual 
          ? 'Began your journey of self-understanding'
          : 'Completed your first message analysis',
        'icon': 'play_circle',
        'earned': true,
      });
    }
    
    if (weeklyMessages >= 10) {
      achievements.add({
        'title': isIndividual ? 'Committed to Growth' : 'Active Communicator',
        'description': isIndividual
          ? 'Consistently working on self-improvement'
          : 'Analyzed 10+ messages this week',
        'icon': 'message',
        'earned': true,
      });
    }
    
    if (positiveSentiment >= 0.7) {
      achievements.add({
        'title': 'Positive Mindset',
        'description': isIndividual
          ? 'Maintaining positive self-talk and outlook'
          : 'Maintained 70%+ positive sentiment',
        'icon': 'sentiment_very_satisfied',
        'earned': true,
      });
    }
    
    if (progress >= 0.5) {
      achievements.add({
        'title': isIndividual ? 'Self-Awareness Hero' : 'Halfway Hero',
        'description': isIndividual
          ? 'Reached 50% secure individual progress'
          : 'Reached 50% secure communication progress',
        'icon': 'halfway',
        'earned': true,
      });
    }
    
    // Individual-specific achievements
    if (isIndividual && progress >= 0.3) {
      achievements.add({
        'title': 'Inner Work Champion',
        'description': 'Dedicated to personal growth and healing',
        'icon': 'psychology',
        'earned': true,
      });
    }
    
    return achievements;
  }

  /// Get focus areas for improvement
  List<Map<String, dynamic>> _getFocusAreas(
    Map<String, dynamic> insights, 
    Map<String, dynamic> analytics,
    {bool isIndividual = false}
  ) {
    final focusAreas = <Map<String, dynamic>>[];
    
    final growthAreas = insights['growth_areas'] as List<dynamic>? ?? [];
    final positiveSentiment = (analytics['positive_sentiment'] as double?) ?? 0.0;
    final weeklyMessages = (analytics['weekly_messages'] as int?) ?? 0;
    
    if (growthAreas.isNotEmpty) {
      focusAreas.add({
        'title': isIndividual ? 'Personal Growth Areas' : 'Growth Areas',
        'description': isIndividual
          ? 'Work on identified areas for personal development'
          : 'Work on identified areas for improvement',
        'priority': 'high',
        'action': 'Review AI recommendations',
      });
    }
    
    if (positiveSentiment < 0.6) {
      focusAreas.add({
        'title': isIndividual ? 'Self-Compassion' : 'Positive Communication',
        'description': isIndividual
          ? 'Practice self-kindness and positive self-talk'
          : 'Increase positive sentiment in messages',
        'priority': 'medium',
        'action': isIndividual 
          ? 'Practice daily affirmations'
          : 'Practice gratitude and appreciation',
      });
    }
    
    if (weeklyMessages < 5) {
      focusAreas.add({
        'title': 'Consistent Practice',
        'description': isIndividual
          ? 'Use the analyzer to track your communication patterns'
          : 'Use the analyzer more consistently',
        'priority': 'medium',
        'action': 'Set reminders to use analyzer',
      });
    }
    
    // Individual-specific focus areas
    if (isIndividual) {
      focusAreas.add({
        'title': 'Self-Reflection',
        'description': 'Regular journaling and self-awareness practices',
        'priority': 'medium',
        'action': 'Keep a daily reflection journal',
      });
    }
    
    return focusAreas;
  }

  /// Store progress for trend tracking
  Future<void> _storeProgress(Map<String, dynamic> progress) async {
    final prefs = await SharedPreferences.getInstance();
    final savedProgress = prefs.getStringList(_progressKey) ?? [];
    
    savedProgress.add(progress['overall_progress'].toString());
    
    // Keep only last 30 days
    if (savedProgress.length > 30) {
      savedProgress.removeAt(0);
    }
    
    await prefs.setStringList(_progressKey, savedProgress);
    await prefs.setString(_lastCalculationKey, DateTime.now().toIso8601String());
  }

  /// Get default progress when no data is available
  Map<String, dynamic> _getDefaultProgress() {
    return {
      'overall_progress': 0.0,
      'progress_percentage': 0,
      'progress_level': 'Beginning Communicator',
      'progress_label': 'Beginning',
      'milestones': [],
      'next_steps': [
        {
          'title': 'Start Your Journey',
          'description': 'Begin using the keyboard analyzer',
          'priority': 'high',
          'estimated_time': '1 week',
        }
      ],
      'weekly_trend': [],
      'breakdown': {
        'attachment_security': 0.0,
        'communication_effectiveness': 0.0,
        'behavioral_patterns': 0.0,
        'active_usage': 0.0,
      },
      'time_to_next_level': '2-3 weeks',
      'achievements': [],
      'focus_areas': [],
      'is_individual': false,
    };
  }

  /// Get day name from weekday number
  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
