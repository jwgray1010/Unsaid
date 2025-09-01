import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/keyboard_manager.dart';
import '../services/unified_analytics_service.dart';
import '../services/secure_storage_service.dart';
import '../services/personality_data_manager.dart';

class InsightsDashboardEnhanced extends StatefulWidget {
  const InsightsDashboardEnhanced({super.key});

  @override
  _InsightsDashboardEnhancedState createState() =>
      _InsightsDashboardEnhancedState();
}

class _InsightsDashboardEnhancedState extends State<InsightsDashboardEnhanced>
    with TickerProviderStateMixin {
  // Controllers
  TabController? _tabController;

  // Service instances - REAL DATA INTEGRATION
  final KeyboardManager _keyboardManager = KeyboardManager();
  final SecureStorageService _storageService = SecureStorageService();
  final PersonalityDataManager _personalityManager = PersonalityDataManager.shared;

  // Real data storage
  Map<String, dynamic>? _realInsightsData;
  // ignore: unused_field
  Map<String, dynamic>? _unifiedAnalyticsData;
  Map<String, dynamic>? _personalityResults;
  Map<String, dynamic>? _keyboardAnalytics;
  List<Map<String, dynamic>> _communicationPatterns = [];
  List<Map<String, dynamic>> _attachmentEvolution = [];
  // ignore: unused_field
  List<Map<String, dynamic>> _behavioralChanges = [];
  bool _isLoadingRealData = true;
  bool _isLoadingUnifiedData = true;
  // ignore: unused_field
  bool _isLoadingPersonality = true;
  bool _isLoadingKeyboardData = true;

  // Enhanced filtering and display options
  String _selectedTimeframe = 'Last 7 Days';
  final List<String> _timeframeOptions = [
    'Last 24 Hours',
    'Last 7 Days',
    'Last 30 Days',
    'Last 3 Months',
    'All Time'
  ];

  // Chart data
  List<FlSpot> _toneProgressData = [];
  List<PieChartSectionData> _attachmentDistribution = [];
  List<BarChartGroupData> _communicationFrequency = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load all data immediately including keyboard analytics
    _loadPersonalityResults();
    _loadRealInsightsData();
    _loadUnifiedAnalyticsData();
    _loadKeyboardAnalytics();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // Load personality test results for personalized insights
  Future<void> _loadPersonalityResults() async {
    if (!mounted) return;

    setState(() => _isLoadingPersonality = true);

    try {
      final results = await _storageService.getPersonalityTestResults();

      if (mounted) {
        setState(() {
          _personalityResults = results;
          _isLoadingPersonality = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading personality results: $e');
      if (mounted) {
        setState(() {
          _personalityResults = null;
          _isLoadingPersonality = false;
        });
      }
    }
  }

  // Load keyboard analytics from PersonalityDataManager
  Future<void> _loadKeyboardAnalytics() async {
    if (!mounted) return;

    setState(() => _isLoadingKeyboardData = true);

    try {
      // Get real keyboard analytics from PersonalityDataManager
      final analytics = await _personalityManager.performStartupKeyboardAnalysis();

      if (mounted) {
        setState(() {
          _keyboardAnalytics = analytics;
          _isLoadingKeyboardData = false;
          
          // Process and integrate keyboard analytics data
          if (_keyboardAnalytics != null) {
            _integrateKeyboardAnalytics();
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading keyboard analytics: $e');
      if (mounted) {
        setState(() {
          _keyboardAnalytics = null;
          _isLoadingKeyboardData = false;
        });
      }
    }
  }

  // Integrate keyboard analytics with insights data
  void _integrateKeyboardAnalytics() {
    if (_keyboardAnalytics == null) return;

    final behaviorAnalysis = _keyboardAnalytics!['behavior_analysis'] as Map<String, dynamic>? ?? {};
    final analysisMetadata = _keyboardAnalytics!['analysis_summary'] as Map<String, dynamic>? ?? {};
    final interactionPatterns = behaviorAnalysis['interaction_patterns'] as Map<String, dynamic>? ?? {};
    final tonePatterns = behaviorAnalysis['tone_patterns'] as Map<String, dynamic>? ?? {};
    final suggestionPatterns = behaviorAnalysis['suggestion_patterns'] as Map<String, dynamic>? ?? {};

    // Enhance _realInsightsData with keyboard analytics
    if (_realInsightsData != null) {
      _realInsightsData!.addAll({
        'enhanced_with_analytics': true,
        'engagement_level': analysisMetadata['engagement_level'],
        'tone_stability': analysisMetadata['tone_stability'],
        'communication_style': analysisMetadata['communication_style'],
        'suggestion_receptivity': analysisMetadata['suggestion_receptivity'],
        'analytics_total_interactions': interactionPatterns['total_interactions'],
        'analytics_suggestion_rate': suggestionPatterns['acceptance_rate'],
        'analytics_tone_confidence': tonePatterns['average_confidence'],
        'analytics_data_quality': analysisMetadata['data_quality_score'],
      });
    }

    // Generate enhanced communication patterns based on analytics
    _generateEnhancedCommunicationPatterns();
    
    // Update chart data with real analytics
    _updateChartsWithAnalytics();
  }

  // Generate communication patterns from real keyboard analytics
  void _generateEnhancedCommunicationPatterns() {
    if (_keyboardAnalytics == null) return;

    final behaviorAnalysis = _keyboardAnalytics!['behavior_analysis'] as Map<String, dynamic>? ?? {};
    final usagePatterns = behaviorAnalysis['usage_patterns'] as Map<String, dynamic>? ?? {};
    final timeDistribution = usagePatterns['time_distribution'] as Map<String, dynamic>? ?? {};
    final appDistribution = usagePatterns['app_distribution'] as Map<String, dynamic>? ?? {};

    _communicationPatterns = [];

    // Add time-based patterns
    timeDistribution.forEach((timeSlot, count) {
      _communicationPatterns.add({
        'type': 'time_pattern',
        'label': 'Most Active in $timeSlot',
        'value': count,
        'percentage': _calculatePercentage(count, usagePatterns['total_events'] ?? 1),
        'trend': 'stable',
        'insight': _getTimeSlotInsight(timeSlot),
      });
    });

    // Add app-based patterns
    appDistribution.forEach((app, count) {
      if (count > 0) {
        _communicationPatterns.add({
          'type': 'app_pattern',
          'label': 'Active in $app',
          'value': count,
          'percentage': _calculatePercentage(count, usagePatterns['total_events'] ?? 1),
          'trend': 'growing',
          'insight': _getAppUsageInsight(app),
        });
      }
    });
  }

  // Update charts with real analytics data
  void _updateChartsWithAnalytics() {
    if (_keyboardAnalytics == null) return;

    final behaviorAnalysis = _keyboardAnalytics!['behavior_analysis'] as Map<String, dynamic>? ?? {};
    final tonePatterns = behaviorAnalysis['tone_patterns'] as Map<String, dynamic>? ?? {};
    final toneDistribution = tonePatterns['tone_distribution'] as Map<String, dynamic>? ?? {};

    // Update tone distribution pie chart
    _attachmentDistribution = [];
    int index = 0;
    toneDistribution.forEach((tone, count) {
      if (count > 0) {
        _attachmentDistribution.add(
          PieChartSectionData(
            color: _getToneColor(tone),
            value: count.toDouble(),
            title: '${tone.toUpperCase()}\n${count}',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
        index++;
      }
    });

    // Generate tone progress over time (simulated based on confidence)
    final avgConfidence = tonePatterns['average_confidence'] as double? ?? 0.0;
    _toneProgressData = [
      FlSpot(0, avgConfidence * 100),
      FlSpot(1, (avgConfidence * 100) + 5),
      FlSpot(2, (avgConfidence * 100) + 10),
      FlSpot(3, (avgConfidence * 100) + 15),
      FlSpot(4, (avgConfidence * 100) + 20),
    ];
  }

  // Helper methods for analytics integration
  double _calculatePercentage(int value, int total) {
    return total > 0 ? (value / total) * 100 : 0.0;
  }

  String _getTimeSlotInsight(String timeSlot) {
    switch (timeSlot.toLowerCase()) {
      case 'morning':
        return 'You communicate thoughtfully in the morning hours';
      case 'afternoon':
        return 'Afternoon conversations show consistent engagement';
      case 'evening':
        return 'Evening communication tends to be more personal';
      case 'night':
        return 'Late-night messages show deeper emotional connection';
      default:
        return 'Consistent communication patterns throughout the day';
    }
  }

  String _getAppUsageInsight(String app) {
    if (app.toLowerCase().contains('message')) {
      return 'Strong personal communication focus';
    } else if (app.toLowerCase().contains('mail')) {
      return 'Professional communication excellence';
    } else if (app.toLowerCase().contains('social')) {
      return 'Active social engagement patterns';
    } else {
      return 'Versatile communication across platforms';
    }
  }

  Color _getToneColor(String tone) {
    switch (tone.toLowerCase()) {
      case 'positive':
      case 'happy':
      case 'excited':
        return Colors.green;
      case 'negative':
      case 'sad':
      case 'angry':
        return Colors.red;
      case 'anxious':
      case 'worried':
        return Colors.orange;
      case 'calm':
      case 'peaceful':
        return Colors.blue;
      case 'neutral':
      default:
        return Colors.grey;
    }
  }

  // Load real insights data from Swift keyboard extension
  Future<void> _loadRealInsightsData() async {
    if (!mounted) return;

    setState(() => _isLoadingRealData = true);

    try {
      // Get real data from Swift keyboard extension
      final realData = await _keyboardManager.getComprehensiveRealData();

      if (mounted) {
        setState(() {
          if (realData['real_data'] == true) {
            // Process real Swift keyboard data
            _realInsightsData = {
              'messageCount': realData['total_interactions'] ?? 0,
              'dominantTone': _mapDominantTone(realData['tone_distribution']),
              'score': _calculateToneScore(realData['tone_distribution']),
              'dominantMood': realData['current_tone_status'] ?? 'neutral',
              'emotionalRange':
                  _calculateEmotionalRange(realData['tone_distribution']),
              'attachmentStyle': realData['attachment_style'] ?? 'unknown',
              'suggestionAcceptanceRate':
                  realData['suggestion_acceptance_rate'] ?? 0,
              'improvementTrend': realData['improvement_trend'] ?? 0.0,
              'lastUpdated': realData['last_updated'],
              'realDataAvailable': true,
            };
          } else {
            // NEW USER EXPERIENCE: Encouraging onboarding messages
            _realInsightsData = {
              'messageCount': 0,
              'dominantTone': '🌟 Ready to start your journey!',
              'score': 0,
              'dominantMood': 'excited',
              'emotionalRange':
                  '💬 Use the Unsaid keyboard to begin building personalized insights',
              'attachmentStyle': 'unknown',
              'suggestionAcceptanceRate': 0,
              'improvementTrend': 0.0,
              'realDataAvailable': false,
              'isNewUser': true,
              'onboardingMessage':
                  'Your communication insights will appear here as you use the Unsaid keyboard. Start typing to see real-time analysis!',
            };
          }
          _isLoadingRealData = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading real insights data: $e');
      if (mounted) {
        setState(() {
          _realInsightsData = {
            'messageCount': 0,
            'dominantTone': '🚀 Getting started...',
            'score': 0,
            'dominantMood': 'optimistic',
            'emotionalRange':
                '✨ Enable the Unsaid keyboard to unlock personalized insights',
            'attachmentStyle': 'unknown',
            'suggestionAcceptanceRate': 0,
            'improvementTrend': 0.0,
            'realDataAvailable': false,
            'error': e.toString(),
            'isNewUser': true,
            'onboardingMessage':
                'Having trouble? Make sure the Unsaid keyboard is enabled in your settings.',
          };
          _isLoadingRealData = false;
        });
      }
    }
  }

  // Map tone distribution to dominant tone
  String _mapDominantTone(Map<String, dynamic>? toneDistribution) {
    if (toneDistribution == null || toneDistribution.isEmpty) {
      return 'Building insights...';
    }

    int maxCount = 0;
    String dominantTone = 'neutral';

    toneDistribution.forEach((tone, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantTone = tone;
      }
    });

    switch (dominantTone) {
      case 'positive':
        return 'Positive & Clear';
      case 'negative':
        return 'Needs Attention';
      case 'neutral':
        return 'Balanced';
      default:
        return 'Analyzing...';
    }
  }

  // Calculate tone score from distribution
  int _calculateToneScore(Map<String, dynamic>? toneDistribution) {
    if (toneDistribution == null || toneDistribution.isEmpty) {
      return 0;
    }

    final positive = toneDistribution['positive'] ?? 0;
    final neutral = toneDistribution['neutral'] ?? 0;
    final negative = toneDistribution['negative'] ?? 0;
    final total = positive + neutral + negative;

    if (total == 0) return 0;

    // Score: positive weight = 1, neutral = 0.5, negative = 0
    final score = ((positive * 1.0 + neutral * 0.5) / total * 100).round();
    return score.clamp(0, 100);
  }

  // Calculate emotional range from tone distribution
  String _calculateEmotionalRange(Map<String, dynamic>? toneDistribution) {
    if (toneDistribution == null || toneDistribution.isEmpty) {
      return 'Use keyboard to build insights';
    }

    final positive = toneDistribution['positive'] ?? 0;
    final negative = toneDistribution['negative'] ?? 0;
    final total = positive + negative + (toneDistribution['neutral'] ?? 0);

    if (total == 0) return 'Building insights...';

    final positiveRatio = positive / total;
    final negativeRatio = negative / total;

    if (positiveRatio > 0.7) {
      return 'Consistently positive';
    } else if (negativeRatio > 0.3) {
      return 'High emotional variance';
    } else {
      return 'Balanced emotional range';
    }
  }

  /// Loads unified analytics data from the analytics service, updates relevant state variables,
  /// and generates chart data for display; handles errors gracefully and provides fallback data.
  Future<void> _loadUnifiedAnalyticsData() async {
    if (!mounted) return;

    setState(() => _isLoadingUnifiedData = true);

    try {
      // Get analytics data with graceful fallback
      final unifiedService = UnifiedAnalyticsService();
      final analytics = await unifiedService.getIndividualAnalytics();

      if (mounted) {
        setState(() {
          _unifiedAnalyticsData = analytics;
          // Set up communication patterns from real data
          _communicationPatterns = _buildPatternsFromAnalytics(analytics);
          _attachmentEvolution = (analytics['attachment_evolution'] != null)
              ? List<Map<String, dynamic>>.from(
                  analytics['attachment_evolution'])
              : [];
          _behavioralChanges = (analytics['behavioral_changes'] != null)
              ? List<Map<String, dynamic>>.from(analytics['behavioral_changes'])
              : [];

          // Generate chart data
          _generateChartData();
          _isLoadingUnifiedData = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading unified analytics data: $e');
      if (mounted) {
        setState(() {
          _unifiedAnalyticsData = null;
          _communicationPatterns = [
            {
              'description': 'Start using the keyboard to see patterns',
              'timestamp': 'Soon',
              'pattern': 'Ready to learn',
              'frequency': 0
            }
          ];
          _attachmentEvolution = [];
          _behavioralChanges = [];
          _generateChartData();
          _isLoadingUnifiedData = false;
        });
      }
    }
  }

  // Helper method to build patterns from analytics
  List<Map<String, dynamic>> _buildPatternsFromAnalytics(
      Map<String, dynamic> analytics) {
    final patterns = <Map<String, dynamic>>[];

    try {
      if (analytics.containsKey('communication_patterns')) {
        final rawPatterns = analytics['communication_patterns'];
        if (rawPatterns is List) {
          for (final pattern in rawPatterns) {
            if (pattern is Map<String, dynamic>) {
              patterns.add(pattern);
            }
          }
        }
      }

      // If no patterns, add getting started message
      if (patterns.isEmpty) {
        patterns.add({
          'description': 'Building communication patterns...',
          'timestamp': 'Soon',
          'pattern': 'Getting started',
          'frequency': 0
        });
      }
    } catch (e) {
      debugPrint('Error building patterns from analytics: $e');
      patterns.clear();
      patterns.add({
        'description': 'Building communication patterns...',
        'timestamp': 'Soon',
        'pattern': 'Getting started',
        'frequency': 0
      });
    }

    return patterns;
  }

  // Generate chart data from real analytics
  void _generateChartData() {
    try {
      _generateToneProgressData();
      _generateAttachmentDistribution();
      _generateCommunicationFrequency();
    } catch (e) {
      debugPrint('Error generating chart data: $e');
      // Provide default chart data if generation fails
      _toneProgressData = [
        const FlSpot(0, 0.5),
        const FlSpot(1, 0.5),
        const FlSpot(2, 0.5),
      ];
      _attachmentDistribution = [
        PieChartSectionData(
          color: Colors.blue.withOpacity(0.8),
          value: 100,
          title: 'Getting Started',
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          radius: 50, // Reduced from 60 to 50 for smaller pie chart
        ),
      ];
      _communicationFrequency = [
        BarChartGroupData(x: 0, barRods: [
          BarChartRodData(toY: 0.3, color: Colors.blue.withOpacity(0.8))
        ]),
        BarChartGroupData(x: 1, barRods: [
          BarChartRodData(toY: 0.3, color: Colors.green.withOpacity(0.8))
        ]),
        BarChartGroupData(x: 2, barRods: [
          BarChartRodData(toY: 0.3, color: Colors.orange.withOpacity(0.8))
        ]),
      ];
    }
  }

  // Generate tone progress line chart data
  void _generateToneProgressData() {
    final analysisHistory = _keyboardManager.analysisHistory;
    _toneProgressData.clear();

    if (analysisHistory.isEmpty) {
      // Default data for new users
      _toneProgressData = [
        const FlSpot(0, 0.5),
        const FlSpot(1, 0.5),
        const FlSpot(2, 0.5),
      ];
      return;
    }

    // Filter by timeframe
    final filteredData = _filterDataByTimeframe(analysisHistory);

    for (int i = 0; i < filteredData.length; i++) {
      final confidence = (filteredData[i]['confidence'] as double?) ?? 0.5;
      _toneProgressData.add(FlSpot(i.toDouble(), confidence));
    }
  }

  // Generate attachment style distribution pie chart
  void _generateAttachmentDistribution() {
    _attachmentDistribution.clear();

    if (_personalityResults != null && _personalityResults!['counts'] != null) {
      final counts = Map<String, int>.from(_personalityResults!['counts']);
      final total = counts.values.fold(0, (sum, count) => sum + count);

      if (total > 0) {
        final colors = [
          Colors.red.withOpacity(0.8), // Anxious
          Colors.green.withOpacity(0.8), // Secure
          Colors.blue.withOpacity(0.8), // Avoidant
          Colors.orange.withOpacity(0.8), // Disorganized
        ];

        final labels = ['Anxious', 'Secure', 'Avoidant', 'Disorganized'];
        final keys = ['A', 'B', 'C', 'D'];

        for (int i = 0; i < keys.length; i++) {
          final count = counts[keys[i]] ?? 0;
          if (count > 0) {
            final percentage = (count / total) * 100;
            _attachmentDistribution.add(
              PieChartSectionData(
                color: colors[i],
                value: percentage,
                title: '${percentage.round()}%',
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                radius: 50, // Reduced from 60 to 50 for smaller pie chart
              ),
            );
          }
        }
      }
    }

    // Default data for new users
    if (_attachmentDistribution.isEmpty) {
      _attachmentDistribution = [
        PieChartSectionData(
          color: Colors.green.withOpacity(0.8),
          value: 100,
          title: 'Take Test',
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          radius: 50, // Reduced from 60 to 50 for smaller pie chart
        ),
      ];
    }
  }

  // Generate communication frequency bar chart
  void _generateCommunicationFrequency() {
    _communicationFrequency.clear();

    final analysisHistory = _keyboardManager.analysisHistory;
    if (analysisHistory.isEmpty) {
      // Default data for new users
      _communicationFrequency = [
        BarChartGroupData(x: 0, barRods: [
          BarChartRodData(toY: 0.5, color: Colors.blue.withOpacity(0.8))
        ]),
        BarChartGroupData(x: 1, barRods: [
          BarChartRodData(toY: 0.3, color: Colors.green.withOpacity(0.8))
        ]),
        BarChartGroupData(x: 2, barRods: [
          BarChartRodData(toY: 0.7, color: Colors.orange.withOpacity(0.8))
        ]),
      ];
      return;
    }

    // Analyze communication frequency by day of week
    final dayFrequency = <int, int>{};

    for (final analysis in analysisHistory) {
      final timestamp = analysis['timestamp'] as String?;
      if (timestamp != null) {
        try {
          final date = DateTime.parse(timestamp);
          final weekday = date.weekday; // 1 = Monday, 7 = Sunday
          dayFrequency[weekday] = (dayFrequency[weekday] ?? 0) + 1;
        } catch (e) {
          // Skip invalid timestamps
        }
      }
    }

    final maxFreq = dayFrequency.values.isNotEmpty
        ? dayFrequency.values.reduce((a, b) => a > b ? a : b)
        : 1;

    for (int i = 1; i <= 7; i++) {
      final freq = dayFrequency[i] ?? 0;
      final normalizedFreq = maxFreq > 0 ? freq / maxFreq : 0.0;

      _communicationFrequency.add(
        BarChartGroupData(
          x: i - 1,
          barRods: [
            BarChartRodData(
              toY: normalizedFreq,
              color: _getWeekdayColor(i),
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }
  }

  // Filter data by selected timeframe
  List<Map<String, dynamic>> _filterDataByTimeframe(
      List<Map<String, dynamic>> data) {
    if (data.isEmpty) return data;

    try {
      final now = DateTime.now();
      DateTime cutoff;

      switch (_selectedTimeframe) {
        case 'Last 24 Hours':
          cutoff = now.subtract(const Duration(hours: 24));
          break;
        case 'Last 7 Days':
          cutoff = now.subtract(const Duration(days: 7));
          break;
        case 'Last 30 Days':
          cutoff = now.subtract(const Duration(days: 30));
          break;
        case 'Last 3 Months':
          cutoff = now.subtract(const Duration(days: 90));
          break;
        case 'All Time':
        default:
          return data;
      }

      return data.where((item) {
        final timestamp = item['timestamp'] as String?;
        if (timestamp == null || timestamp.isEmpty) return false;

        try {
          final date = DateTime.parse(timestamp);
          return date.isAfter(cutoff);
        } catch (e) {
          debugPrint('Error parsing timestamp: $timestamp');
          return false;
        }
      }).toList();
    } catch (e) {
      debugPrint('Error filtering data by timeframe: $e');
      return data;
    }
  }

  // Get color for weekday bars
  Color _getWeekdayColor(int weekday) {
    final colors = [
      Colors.blue, // Monday
      Colors.green, // Tuesday
      Colors.orange, // Wednesday
      Colors.purple, // Thursday
      Colors.red, // Friday
      Colors.teal, // Saturday
      Colors.indigo, // Sunday
    ];
    return colors[(weekday - 1) % colors.length].withOpacity(0.8);
  }

  // Get user's dominant attachment style
  String get dominantAttachmentStyle {
    if (_personalityResults == null ||
        _personalityResults!['dominant_type'] == null) {
      return 'Take the personality test to see your attachment style';
    }

    final labels = {
      'A': 'Anxious Attachment',
      'B': 'Secure Attachment',
      'C': 'Dismissive Avoidant',
      'D': 'Disorganized/Fearful Avoidant',
    };

    return labels[_personalityResults!['dominant_type']] ?? 'Unknown';
  }

  // Get personalized insights based on attachment style
  List<String> get personalizedInsights {
    if (_personalityResults == null ||
        _personalityResults!['dominant_type'] == null) {
      return [
        'Complete the personality test to unlock personalized insights',
        'Your attachment style influences your communication patterns',
        'Understanding your style helps improve relationships'
      ];
    }

    final type = _personalityResults!['dominant_type'] as String;
    final analysisCount = _keyboardManager.analysisHistory.length;

    switch (type) {
      case 'A': // Anxious
        return [
          'Your anxious attachment style shows high emotional awareness',
          'You seek reassurance in communication - this is natural',
          analysisCount > 5
              ? 'Your recent messages show ${_getLatestToneDescription()} tone patterns'
              : 'Keep using the keyboard to track your communication evolution',
          'Focus on self-soothing techniques before important conversations'
        ];
      case 'B': // Secure
        return [
          'Your secure attachment style supports healthy communication',
          'You balance emotional expression with logical thinking well',
          analysisCount > 5
              ? 'Your tone analysis shows consistent ${_getLatestToneDescription()} patterns'
              : 'Your secure foundation will help build rich communication insights',
          'Continue modeling healthy communication for your relationships'
        ];
      case 'C': // Avoidant
        return [
          'Your avoidant style values independence and direct communication',
          'You process emotions internally - consider sharing more openly',
          analysisCount > 5
              ? 'Your ${_getLatestToneDescription()} tone suggests growing emotional expression'
              : 'Track how your communication evolves as you become more comfortable',
          'Small steps toward vulnerability can strengthen your relationships'
        ];
      case 'D': // Disorganized
        return [
          'Your complex attachment style brings both depth and challenges',
          'You experience rich emotional ranges - this is your strength',
          analysisCount > 5
              ? 'Recent analysis shows ${_getLatestToneDescription()} communication patterns'
              : 'Use the keyboard to understand your communication patterns better',
          'Consistency in communication style can help stabilize relationships'
        ];
      default:
        return ['Take the personality test for personalized insights'];
    }
  }

  // Get description of latest tone patterns
  String _getLatestToneDescription() {
    try {
      final history = _keyboardManager.analysisHistory;
      if (history.isEmpty) return 'balanced';

      final recentAnalyses = history.take(5).toList();
      final tones = recentAnalyses
          .map((a) => a['dominant_tone'] as String?)
          .where((t) => t != null && t.isNotEmpty)
          .toList();

      if (tones.isEmpty) return 'balanced';

      // Find most common tone
      final toneCount = <String, int>{};
      for (final tone in tones) {
        toneCount[tone!] = (toneCount[tone] ?? 0) + 1;
      }

      if (toneCount.isEmpty) return 'balanced';

      final mostCommon =
          toneCount.entries.reduce((a, b) => a.value > b.value ? a : b);

      return mostCommon.key.toLowerCase();
    } catch (e) {
      debugPrint('Error getting latest tone description: $e');
      return 'balanced';
    }
  }

  void _showPreSendCoach() {
    showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (_) {
          bool v = false, n = false, a = false;
          return StatefulBuilder(builder: (ctx, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Row(children: [
                  Icon(Icons.shield_moon),
                  SizedBox(width: 8),
                  Text('Pre-Send Coach',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 12),
                CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: v,
                    onChanged: (b) => setState(() => v = b ?? false),
                    title: const Text(
                        'Validation: "I can see how this affects you."')),
                CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: n,
                    onChanged: (b) => setState(() => n = b ?? false),
                    title: const Text('Need: "What I need is…"')),
                CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: a,
                    onChanged: (b) => setState(() => a = b ?? false),
                    title: const Text('Ask: "Could we try…?"')),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Looks good'),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
              ]),
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication Insights'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Analytics'),
            Tab(text: 'Growth'),
          ],
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(theme),
          _buildAnalyticsTab(theme),
          _buildGrowthTab(theme),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    if (_isLoadingRealData || _isLoadingUnifiedData) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Building your insights...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInsightsSummary(theme),
          const SizedBox(height: 16),
          SecureStreakAndRepairCard(
              analysisHistory: _keyboardManager.analysisHistory),
          const SizedBox(height: 24),
          _buildRecentActivity(theme),
          const SizedBox(height: 24),
          _buildQuickActions(theme),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time range filter
          _buildTimeRangeFilter(theme),
          const SizedBox(height: 24),

          // Attachment Style Distribution Chart
          _buildAttachmentStyleChart(theme),
          const SizedBox(height: 24),

          // Tone Progress Line Chart
          _buildToneProgressChart(theme),
          const SizedBox(height: 24),

          // Communication Frequency Bar Chart
          _buildCommunicationFrequencyChart(theme),
          const SizedBox(height: 24),

          // Personalized Insights Card
          _buildPersonalizedInsightsCard(theme),
          const SizedBox(height: 24),

          // Communication Patterns Card
          _buildCommunicationPatternsCard(theme),
        ],
      ),
    );
  }

  Widget _buildGrowthTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MicroHabitOfWeek(
              attachment:
                  (_personalityResults?['dominant_type'] ?? 'B').toString()),
          const SizedBox(height: 24),
          _buildIndividualGoals(theme),
          const SizedBox(height: 24),
          _buildRecommendations(theme),
        ],
      ),
    );
  }

  Widget _buildInsightsSummary(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Communication Snapshot',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_realInsightsData != null) ...[
              _buildInsightMetric(
                theme,
                'Messages Analyzed',
                _realInsightsData!['messageCount']?.toString() ?? '0',
                Icons.message,
              ),
              _buildInsightMetric(
                theme,
                'Emotional Tone',
                _realInsightsData!['dominantTone'] ?? 'Neutral',
                Icons.mood,
              ),
              _buildInsightMetric(
                theme,
                'Communication Score',
                '${_realInsightsData!['score'] ?? 75}%',
                Icons.trending_up,
              ),
            ] else ...[
              _buildEmptyStateMessage(
                  'Start using the keyboard to see insights'),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInsightMetric(
      ThemeData theme, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_communicationPatterns.isNotEmpty) ...[
              ..._communicationPatterns.take(3).map(
                    (pattern) => _buildActivityItem(
                      theme,
                      pattern['description'] ?? 'Recent communication',
                      pattern['timestamp'] ?? 'Just now',
                      Icons.chat_bubble_outline,
                    ),
                  ),
            ] else ...[
              _buildEmptyStateMessage('No recent activity'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
      ThemeData theme, String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    theme,
                    'Growth Tips',
                    Icons.trending_up,
                    () {
                      // Navigate to growth tab
                      _tabController?.animateTo(2);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    theme,
                    'Analytics',
                    Icons.analytics,
                    () {
                      // Navigate to analytics tab
                      _tabController?.animateTo(1);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    theme,
                    'Pre-Send',
                    Icons.shield_moon,
                    _showPreSendCoach,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      ThemeData theme, String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunicationPatternsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Communication Patterns',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_communicationPatterns.isNotEmpty) ...[
              ..._communicationPatterns.map(
                (pattern) => _buildPatternTile(theme, pattern),
              ),
            ] else ...[
              _buildEmptyStateMessage('Building communication patterns...'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPatternTile(ThemeData theme, Map<String, dynamic> pattern) {
    return ListTile(
      leading: Icon(
        Icons.trending_up,
        color: theme.colorScheme.primary,
      ),
      title: Text(pattern['pattern'] ?? 'Communication Pattern'),
      subtitle: Text(pattern['description'] ?? 'Pattern description'),
      trailing: Text(
        '${pattern['frequency'] ?? 0}%',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildAttachmentEvolutionCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Attachment Style Evolution',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_attachmentEvolution.isNotEmpty) ...[
              ..._attachmentEvolution.map(
                (evolution) => _buildEvolutionItem(theme, evolution),
              ),
            ] else ...[
              _buildEmptyStateMessage('Building attachment insights...'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEvolutionItem(ThemeData theme, Map<String, dynamic> evolution) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timeline,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evolution['milestone'] ?? 'Growth milestone',
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  evolution['description'] ?? 'Progress description',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildEmotionalInsightCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emotional Insights',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_realInsightsData != null) ...[
              _buildEmotionalMetric(
                theme,
                'Dominant Mood',
                _realInsightsData!['dominantMood']?.toString() ?? 'Neutral',
                _getMoodIcon(_realInsightsData!['dominantMood']?.toString() ??
                    'neutral'),
              ),
              _buildEmotionalMetric(
                theme,
                'Emotional Range',
                _realInsightsData!['emotionalRange']?.toString() ?? 'Balanced',
                Icons.favorite,
              ),
            ] else ...[
              _buildEmptyStateMessage(
                  'Start communicating to see emotional insights'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionalMetric(
      ThemeData theme, String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildGrowthMetrics(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure Communication',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Progress',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSecureProgressMetrics(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSecureProgressMetrics(ThemeData theme) {
    // Calculate secure communication progress from real data
    final analysisHistory = _keyboardManager.analysisHistory;
    final totalMessages = analysisHistory.length;

    if (totalMessages == 0) {
      return _buildEmptyStateMessage(
          'Start messaging to track your secure communication progress');
    }

    // Calculate secure communication indicators
    final recentMessages = analysisHistory.take(10).toList();
    final positiveEmotions = recentMessages
        .where((msg) => ['happy', 'confident', 'calm', 'supportive']
            .contains(msg['emotion']?.toString().toLowerCase()))
        .length;

    final balancedTones = recentMessages
        .where((msg) => ['neutral', 'professional', 'supportive', 'confident']
            .contains(msg['dominant_tone']?.toString().toLowerCase()))
        .length;

    final secureScore = totalMessages > 0
        ? ((positiveEmotions + balancedTones) /
                (recentMessages.length * 2) *
                100)
            .round()
        : 0;

    return Column(
      children: [
        _buildProgressMetric(
          theme,
          'Secure Communication Score',
          '$secureScore%',
          secureScore / 100,
          Icons.security,
          _getSecureScoreColor(secureScore),
        ),
        const SizedBox(height: 12),
        _buildProgressMetric(
          theme,
          'Emotional Regulation',
          '${(positiveEmotions / (recentMessages.isNotEmpty ? recentMessages.length : 1) * 100).round()}%',
          positiveEmotions /
              (recentMessages.isNotEmpty ? recentMessages.length : 1),
          Icons.mood,
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildProgressMetric(
          theme,
          'Balanced Communication',
          '${(balancedTones / (recentMessages.isNotEmpty ? recentMessages.length : 1) * 100).round()}%',
          balancedTones /
              (recentMessages.isNotEmpty ? recentMessages.length : 1),
          Icons.balance,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildProgressMetric(ThemeData theme, String label, String value,
      double progress, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Color _getSecureScoreColor(int score) {
    if (score >= 70) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  Widget _buildRecommendations(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Path to Secure',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Communication',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._getSecureCommunicationRecommendations().map(
              (rec) => _buildSecureRecommendationTile(theme, rec),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Text(
                'These tools offer relationship coaching, not medical or clinical treatment. If communication feels unsafe or overwhelming, consider speaking with a licensed professional.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getSecureCommunicationRecommendations() {
    final analysisHistory = _keyboardManager.analysisHistory;
    final personalityType = _personalityResults?['dominant_type'];
    final recommendations = <Map<String, dynamic>>[];

    // Base secure communication principles
    recommendations.add({
      'title': 'Practice Emotional Regulation',
      'description':
          'Secure communicators manage their emotions before responding. Take a breath and reflect before reacting.',
      'icon': Icons.self_improvement,
      'priority': 'high',
    });

    recommendations.add({
      'title': 'Express Needs Clearly',
      'description':
          'Secure attachment means being direct about your needs without being demanding or passive.',
      'icon': Icons.record_voice_over,
      'priority': 'high',
    });

    recommendations.add({
      'title': 'Listen for Understanding',
      'description':
          'Focus on truly understanding your partner\'s perspective before formulating your response.',
      'icon': Icons.hearing,
      'priority': 'medium',
    });

    recommendations.add({
      'title': 'Validate Before Problem-Solving',
      'description':
          'Acknowledge your partner\'s feelings before trying to fix or solve their concerns.',
      'icon': Icons.favorite,
      'priority': 'medium',
    });

    // Attachment-specific recommendations
    if (personalityType != null) {
      switch (personalityType) {
        case 'A': // Anxious
          recommendations.add({
            'title': 'Build Self-Soothing Skills',
            'description':
                'Your anxious style can become secure by learning to calm yourself before communicating.',
            'icon': Icons.spa,
            'priority': 'high',
          });
          break;
        case 'C': // Avoidant
          recommendations.add({
            'title': 'Practice Emotional Openness',
            'description':
                'Your avoidant style can become secure by gradually sharing more of your inner world.',
            'icon': Icons.open_in_new,
            'priority': 'high',
          });
          break;
        case 'D': // Disorganized
          recommendations.add({
            'title': 'Create Consistent Patterns',
            'description':
                'Your complex style can become secure by establishing predictable communication routines.',
            'icon': Icons.schedule,
            'priority': 'high',
          });
          break;
        case 'B': // Already secure
          recommendations.add({
            'title': 'Maintain Your Secure Base',
            'description':
                'Continue modeling healthy communication and help others feel secure too.',
            'icon': Icons.support,
            'priority': 'medium',
          });
          break;
      }
    }

    // Data-driven recommendations
    if (analysisHistory.isNotEmpty) {
      final recentTones = analysisHistory
          .take(10)
          .map((msg) => msg['dominant_tone']?.toString().toLowerCase())
          .where((tone) => tone != null)
          .toList();

      final hasNegativeTones = recentTones.any((tone) =>
          ['aggressive', 'frustrated', 'angry', 'dismissive'].contains(tone));

      if (hasNegativeTones) {
        recommendations.add({
          'title': 'Soften Your Approach',
          'description':
              'Your recent messages show some intensity. Try starting with validation before expressing concerns.',
          'icon': Icons.water_drop,
          'priority': 'high',
        });
      }
    }

    return recommendations;
  }

  Widget _buildSecureRecommendationTile(
      ThemeData theme, Map<String, dynamic> rec) {
    final priority = rec['priority'] as String? ?? 'medium';
    final priorityColor = priority == 'high' ? Colors.orange : Colors.blue;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: priorityColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              rec['icon'] as IconData,
              color: priorityColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec['title'] as String,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rec['description'] as String,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.insights,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }

  // Time range filter widget
  Widget _buildTimeRangeFilter(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.date_range, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              'Time Range:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButton<String>(
                value: _selectedTimeframe,
                isExpanded: true,
                underline: Container(),
                items: _timeframeOptions.map((String timeframe) {
                  return DropdownMenuItem<String>(
                    value: timeframe,
                    child: Text(timeframe),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedTimeframe = newValue;
                      _generateChartData(); // Regenerate charts with new timeframe
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Attachment Style Distribution Pie Chart
  Widget _buildAttachmentStyleChart(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Attachment Style Distribution',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_personalityResults != null)
              SizedBox(
                height: 180, // Reduced to 180 for even smaller pie chart
                child: PieChart(
                  PieChartData(
                    sections: _attachmentDistribution,
                    centerSpaceRadius: 35, // Reduced from 40 to 35
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        // Add touch interaction if needed
                      },
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 300,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 64,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Take Personality Test',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete the personality assessment to see your attachment style distribution',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to personality test
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Start Test'),
                    ),
                  ],
                ),
              ),
            if (_personalityResults != null) ...[
              const SizedBox(height: 16),
              _buildAttachmentStyleLegend(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentStyleLegend(ThemeData theme) {
    final labels = ['Anxious', 'Secure', 'Avoidant', 'Disorganized'];
    final colors = [
      Colors.red.withOpacity(0.8),
      Colors.green.withOpacity(0.8),
      Colors.blue.withOpacity(0.8),
      Colors.orange.withOpacity(0.8),
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: List.generate(labels.length, (index) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: colors[index],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              labels[index],
              style: theme.textTheme.bodyMedium,
            ),
          ],
        );
      }),
    );
  }

  // Tone Progress Line Chart
  Widget _buildToneProgressChart(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Communication Tone\nProgress',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Track your communication confidence over time',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: _toneProgressData.isNotEmpty
                  ? LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${(value * 100).round()}%',
                                  style: theme.textTheme.bodySmall,
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.round()}',
                                  style: theme.textTheme.bodySmall,
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _toneProgressData,
                            isCurved: true,
                            color: theme.colorScheme.primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: theme.colorScheme.primary.withOpacity(0.1),
                            ),
                          ),
                        ],
                        minY: 0,
                        maxY: 1,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start Messaging',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use the keyboard extension to track your communication progress',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Communication Frequency Bar Chart
  Widget _buildCommunicationFrequencyChart(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Communication Frequency',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your messaging patterns by day of the week',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: _communicationFrequency.isNotEmpty
                  ? BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.round().toString(),
                                  style: theme.textTheme.bodySmall,
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                const days = [
                                  'Mon',
                                  'Tue',
                                  'Wed',
                                  'Thu',
                                  'Fri',
                                  'Sat',
                                  'Sun'
                                ];
                                if (value.round() >= 0 &&
                                    value.round() < days.length) {
                                  return Text(
                                    days[value.round()],
                                    style: theme.textTheme.bodySmall,
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        barGroups: _communicationFrequency,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart_outlined,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Building Patterns',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Communication frequency patterns will appear as you use the app more',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Personalized Insights Card
  Widget _buildPersonalizedInsightsCard(ThemeData theme) {
    return Column(
      children: [
        TriggerTopicsChart(analysisHistory: _keyboardManager.analysisHistory),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Personal Insights',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_personalityResults != null) ...[
                  _buildPersonalityInsight(theme),
                  const SizedBox(height: 16),
                  _buildCommunicationStyleInsight(theme),
                  const SizedBox(height: 16),
                  _buildAttachmentGrowthTips(theme),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          size: 48,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Complete Personality Test',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Take the personality assessment to unlock personalized insights based on your attachment and communication style',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Personality-based insight
  Widget _buildPersonalityInsight(ThemeData theme) {
    if (_personalityResults == null) {
      return const SizedBox.shrink();
    }

    final dominantType = _personalityResults!['dominant_type'] ?? 'B';
    final typeLabel =
        _personalityResults!['dominant_type_label'] ?? 'Secure Attachment';

    final insights = {
      'A':
          'Your anxious attachment style means you value deep emotional connection. Focus on self-soothing techniques and direct communication of your needs.',
      'B':
          'Your secure attachment style allows for balanced relationships. Continue practicing open communication and emotional availability.',
      'C':
          'Your avoidant attachment style values independence. Try gradually sharing more of your inner world with trusted people.',
      'D':
          'Your disorganized attachment style shows complex relationship patterns. Focus on identifying your needs and practicing grounding techniques.',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                typeLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insights[dominantType] ??
                'Continue developing your communication skills.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // Communication style insight
  Widget _buildCommunicationStyleInsight(ThemeData theme) {
    if (_personalityResults == null) {
      return const SizedBox.shrink();
    }

    final commStyle =
        _personalityResults!['communication_style'] ?? 'assertive';
    final commLabel =
        _personalityResults!['communication_style_label'] ?? 'Assertive';

    final insights = {
      'assertive':
          'Your assertive communication style is ideal for healthy relationships. Continue expressing your needs clearly and respectfully.',
      'passive':
          'Your passive style shows you value harmony. Try gradually expressing your needs more directly to strengthen your relationships.',
      'aggressive':
          'Your direct approach shows confidence. Focus on softening your delivery while maintaining your clear communication.',
      'passive-aggressive':
          'Your indirect style may create confusion. Practice expressing feelings directly rather than through hints.',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                commLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insights[commStyle] ??
                'Continue developing your communication skills.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // Attachment-specific growth tips for secure communication
  Widget _buildAttachmentGrowthTips(ThemeData theme) {
    if (_personalityResults == null) {
      return const SizedBox.shrink();
    }

    final dominantType = _personalityResults!['dominant_type'] ?? 'B';

    final tips = {
      'A': [
        'Practice self-soothing: Take 3 deep breaths before responding to triggering messages',
        'Express needs directly: Instead of "You never..." try "I need..." statements',
        'Build secure base: Remind yourself of your partner\'s consistent caring actions',
      ],
      'B': [
        'Model secure communication: Continue being emotionally available and consistent',
        'Support others\' security: Help anxious partners feel safe and avoidant partners feel accepted',
        'Maintain emotional balance: Keep expressing feelings clearly without overwhelming others',
      ],
      'C': [
        'Practice emotional sharing: Share one feeling per day, starting with positive ones',
        'Stay present during conflict: Notice when you want to withdraw and gently stay engaged',
        'Build intimacy gradually: Small steps toward vulnerability create secure connections',
      ],
      'D': [
        'Create predictable patterns: Establish consistent communication routines with your partner',
        'Use grounding techniques: When overwhelmed, pause and focus on your breath or surroundings',
        'Practice self-compassion: Be gentle with yourself as you work toward secure communication',
      ],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Path to Secure Communication',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...tips[dominantType]!.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.arrow_forward,
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildIndividualGoals(ThemeData theme) {
    // Get user's attachment style (with fallback for new users)
    String attachmentStyle =
        _personalityResults?['attachment_style'] ?? 'Secure';
    String communicationStyle =
        _personalityResults?['communication_style'] ?? 'Assertive';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Personal Growth Goals',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400, // Fixed height instead of screen percentage
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.primaryContainer.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attachment Style: $attachmentStyle',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Communication Style: $communicationStyle',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Personalized growth recommendations based on your communication patterns will appear here as you use the keyboard.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMoodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
      case 'joy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
      case 'melancholy':
        return Icons.sentiment_very_dissatisfied;
      case 'angry':
      case 'frustrated':
        return Icons.sentiment_dissatisfied;
      case 'excited':
      case 'enthusiastic':
        return Icons.celebration;
      case 'calm':
      case 'peaceful':
        return Icons.spa;
      default:
        return Icons.sentiment_neutral;
    }
  }
}

class SecureStreakAndRepairCard extends StatelessWidget {
  const SecureStreakAndRepairCard({
    super.key,
    required this.analysisHistory,
  });

  final List<Map<String, dynamic>> analysisHistory;

  bool _isRupture(Map<String, dynamic> a) {
    final tone = (a['tone_status'] ?? a['dominant_tone'] ?? 'neutral')
        .toString()
        .toLowerCase();
    return tone == 'alert' ||
        tone == 'angry' ||
        tone == 'aggressive' ||
        tone == 'caution';
  }

  bool _isRepair(Map<String, dynamic> a) {
    final msg = (a['original_message'] ?? a['original_text'] ?? '')
        .toString()
        .toLowerCase();
    const repairWords = [
      'sorry',
      'apologize',
      'understand',
      'i see',
      'makes sense',
      'thank you',
      'appreciate',
      'can we restart',
      'let me try again',
      'want to work together'
    ];
    return repairWords.any((w) => msg.contains(w));
  }

  int _secureStreakDays(List<Map<String, dynamic>> hist) {
    if (hist.isEmpty) return 0;
    // group by date -> if any rupture in a day, that day is insecure
    final byDate = <DateTime, bool>{}; // true = secure day
    for (final a in hist) {
      final ts = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
      final day = DateTime(ts.year, ts.month, ts.day);
      byDate[day] = (byDate[day] ?? true) && !_isRupture(a);
    }
    // count back from today until first insecure day
    int streak = 0;
    DateTime d = DateTime.now();
    for (;;) {
      final day = DateTime(d.year, d.month, d.day);
      if (byDate.containsKey(day) && byDate[day] == true) {
        streak++;
      } else {
        break;
      }
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  double _repairRateLast7d(List<Map<String, dynamic>> hist) {
    if (hist.isEmpty) return 0;
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recent = hist.where((a) {
      final ts = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
      return ts.isAfter(cutoff);
    }).toList()
      ..sort((a, b) {
        final ta = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime(2000);
        final tb = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime(2000);
        return ta.compareTo(tb);
      });

    int ruptures = 0, repairs = 0;
    for (int i = 0; i < recent.length; i++) {
      if (_isRupture(recent[i])) {
        ruptures++;
        // look ahead 24h for a repair
        final t0 =
            DateTime.tryParse(recent[i]['timestamp'] ?? '') ?? DateTime.now();
        for (int j = i + 1; j < recent.length; j++) {
          final tj =
              DateTime.tryParse(recent[j]['timestamp'] ?? '') ?? DateTime.now();
          if (tj.difference(t0).inHours > 24) break;
          if (_isRepair(recent[j])) {
            repairs++;
            break;
          }
        }
      }
    }
    if (ruptures == 0) return 1.0; // treat no ruptures as 100%
    return (repairs / ruptures).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final streak = _secureStreakDays(analysisHistory);
    final repairRate = _repairRateLast7d(analysisHistory);
    final theme = Theme.of(context);

    Color repairColor;
    if (repairRate >= 0.7) {
      repairColor = Colors.green;
    } else if (repairRate >= 0.4)
      repairColor = Colors.orange;
    else
      repairColor = Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.verified_user, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Secure Streak & Repair Rate',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _metricTile(context, 'Secure Streak', '${streak}d',
                    Icons.local_fire_department, Colors.amber)),
            const SizedBox(width: 12),
            Expanded(
                child: _metricTile(
                    context,
                    'Repair Rate (7d)',
                    '${(repairRate * 100).round()}%',
                    Icons.build_circle,
                    repairColor)),
          ]),
          const SizedBox(height: 8),
          Text(
              repairRate >= 0.7
                  ? 'Great repair habit—keep validating + restating needs.'
                  : 'Aim for a quick repair after tense moments: validate → need → next step.',
              style: theme.textTheme.bodySmall),
        ]),
      ),
    );
  }

  Widget _metricTile(BuildContext ctx, String label, String value,
      IconData icon, Color color) {
    final t = Theme.of(ctx);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(children: [
        Icon(icon, color: color),
        const SizedBox(height: 6),
        Text(value,
            style: t.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: t.textTheme.bodySmall),
      ]),
    );
  }
}

class TriggerTopicsChart extends StatelessWidget {
  const TriggerTopicsChart({super.key, required this.analysisHistory});

  final List<Map<String, dynamic>> analysisHistory;

  bool _isTense(Map<String, dynamic> a) {
    final tone = (a['tone_status'] ?? a['dominant_tone'] ?? 'neutral')
        .toString()
        .toLowerCase();
    return tone == 'alert' ||
        tone == 'angry' ||
        tone == 'aggressive' ||
        tone == 'caution';
  }

  String _topicFor(String text) {
    final t = text.toLowerCase();
    if (RegExp(r'\bmoney|budget|pay|rent|bills?\b').hasMatch(t)) return 'Money';
    if (RegExp(r'\bplan|schedule|time|when|later|tomorrow|date\b').hasMatch(t)) {
      return 'Plans/Time';
    }
    if (RegExp(r'\bchores?|dishes|laundry|clean|trash\b').hasMatch(t)) {
      return 'Chores';
    }
    if (RegExp(r'\bfamily|mom|dad|kids?|child|baby\b').hasMatch(t)) {
      return 'Family';
    }
    if (RegExp(r'\bsex|intimacy|affection|touch\b').hasMatch(t)) {
      return 'Intimacy';
    }
    if (RegExp(r'\bwork|job|deadline|meeting\b').hasMatch(t)) return 'Work';
    return 'Other';
  }

  @override
  Widget build(BuildContext context) {
    final recent = analysisHistory.take(200).toList();
    final counts = <String, int>{};
    for (final a in recent) {
      final msg =
          (a['original_message'] ?? a['original_text'] ?? '').toString();
      final topic = _topicFor(msg);
      if (_isTense(a)) counts[topic] = (counts[topic] ?? 0) + 1;
    }
    if (counts.isEmpty) {
      return const Card(
        child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No tense topics detected yet.')),
      );
    }
    final items = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final bars = <BarChartGroupData>[];
    for (int i = 0; i < items.length; i++) {
      bars.add(
        BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: items[i].value.toDouble(),
            color: Colors.orange.withOpacity(0.9),
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ]),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.flag_circle,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text('Trigger Topics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
          ]),
          const SizedBox(height: 8),
          Text('Where caution/alert spikes most (last 200 msgs)',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                barGroups: bars,
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: true),
                titlesData: FlTitlesData(
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: true)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      if (v.toInt() >= 0 && v.toInt() < items.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(items[v.toInt()].key,
                              style: const TextStyle(fontSize: 10)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  )),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tip: Pre-agree "how we\'ll talk" rules for your top 1-2 tricky topics.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ]),
      ),
    );
  }
}

class MicroHabitOfWeek extends StatefulWidget {
  const MicroHabitOfWeek({super.key, required this.attachment});
  final String attachment; // 'A'|'B'|'C'|'D' or label

  @override
  State<MicroHabitOfWeek> createState() => _MicroHabitOfWeekState();
}

class _MicroHabitOfWeekState extends State<MicroHabitOfWeek> {
  late Map<String, String> habit;
  int completions = 0; // simple local counter

  Map<String, String> _pickHabit(String a) {
    switch (a) {
      case 'A':
        return {
          'title': 'Validate before asking',
          'desc': 'Add one sentence of understanding before your request.'
        };
      case 'C':
        return {
          'title': 'Name one feeling',
          'desc': 'Include a single feeling word in one message per day.'
        };
      case 'D':
        return {
          'title': 'One need + one ask',
          'desc': 'Keep it simple: "I feel __, I need __, could we __?"'
        };
      default:
        return {
          'title': 'Appreciation first',
          'desc': 'Start tough messages with a brief appreciation.'
        };
    }
  }

  @override
  void initState() {
    super.initState();
    habit = _pickHabit(widget.attachment);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.check_circle, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Micro-Habit of the Week',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Text(habit['title']!, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(habit['desc']!, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => setState(() => completions++),
                icon: const Icon(Icons.done),
                label: const Text('Mark done today'),
              ),
            ),
            const SizedBox(width: 12),
            Text('Done: $completions',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ]),
        ]),
      ),
    );
  }
}
