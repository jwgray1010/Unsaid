import '../services/keyboard_manager.dart';
import '../services/relationship_insights_service.dart';

/// Demo script showing how relationship insights integrate with the advanced analyzer
/// This demonstrates the complete flow from message analysis to relationship insights
class RelationshipInsightsDemoScript {
  static final KeyboardManager _keyboardManager = KeyboardManager();
  static final RelationshipInsightsService _insightsService =
      RelationshipInsightsService();

  /// Comprehensive demo of relationship insights integration
  static Future<void> runRelationshipInsightsDemo() async {
    print('=== RELATIONSHIP INSIGHTS INTEGRATION DEMO ===');
    print('Demonstrating how the Advanced Text Communication Analyzer');
    print('feeds into the Relationship Insights Dashboard\n');

    // Step 1: Simulate message analysis history
    print('Step 1: Simulating message analysis history...');
    await _simulateMessageAnalysisHistory();

    // Step 2: Generate relationship insights
    print(
      '\nStep 2: Generating relationship insights from analysis history...',
    );
    final insights = await _insightsService.generateRelationshipInsights();

    // Step 3: Display insights dashboard data
    print('\nStep 3: Relationship Insights Dashboard Data:');
    _displayInsightsData(insights);

    // Step 4: Show how insights update with new analysis
    print('\nStep 4: Demonstrating real-time updates...');
    await _simulateNewAnalysisAndUpdate();

    print('\n=== DEMO COMPLETE ===');
    print(
      'The relationship page now uses real analyzer data instead of mock data!',
    );
  }

  /// Simulate a history of message analyses to demonstrate the integration
  static Future<void> _simulateMessageAnalysisHistory() async {
    final sampleMessages = [
      {
        'message': 'Hey, can we talk about our communication?',
        'context': 'marriage',
        'attachment': 'Secure',
        'comm_style': 'Assertive',
      },
      {
        'message': 'I feel like you never listen to me anymore...',
        'context': 'marriage',
        'attachment': 'Anxious',
        'comm_style': 'Passive',
      },
      {
        'message': 'Whatever, I don\'t want to discuss this right now.',
        'context': 'marriage',
        'attachment': 'Avoidant',
        'comm_style': 'Passive-Aggressive',
      },
      {
        'message':
            'I understand you\'re frustrated. Can we work through this together?',
        'context': 'marriage',
        'attachment': 'Secure',
        'comm_style': 'Assertive',
      },
      {
        'message':
            'I appreciate you wanting to resolve this. Let\'s set aside time to talk.',
        'context': 'marriage',
        'attachment': 'Secure',
        'comm_style': 'Assertive',
      },
    ];

    print('Analyzing sample messages:');
    for (int i = 0; i < sampleMessages.length; i++) {
      final messageData = sampleMessages[i];
      print('  ${i + 1}. "${messageData['message']}"');

      // Perform comprehensive analysis
      final analysis = await _keyboardManager.performComprehensiveAnalysis(
        messageData['message']!,
        relationshipContext: messageData['context']!,
        attachmentStyle: messageData['attachment']!,
        communicationStyle: messageData['comm_style']!,
      );

      if (analysis.containsKey('error')) {
        print('     → Analysis failed: ${analysis['error']}');
      } else {
        print('     → Analysis completed successfully');
        _displayAnalysisHighlights(analysis);
      }

      // Small delay to simulate real usage
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Display key highlights from a single analysis
  static void _displayAnalysisHighlights(Map<String, dynamic> analysis) {
    // Display tone analysis
    if (analysis['tone_analysis'] != null) {
      final toneAnalysis = analysis['tone_analysis'];
      print('       Tone: ${toneAnalysis['dominant_tone'] ?? 'Unknown'}');
      print('       Empathy Score: ${toneAnalysis['empathy_score'] ?? 'N/A'}');
      print('       Clarity Score: ${toneAnalysis['clarity_score'] ?? 'N/A'}');
    }

    // Display co-parenting analysis
    if (analysis['coparenting_analysis'] != null) {
      final coParentingAnalysis = analysis['coparenting_analysis'];
      print(
        '       Child Focus: ${coParentingAnalysis['child_focus_score'] ?? 'N/A'}',
      );
      print(
        '       Constructiveness: ${coParentingAnalysis['constructiveness_score'] ?? 'N/A'}',
      );
    }

    // Display predictive analysis
    if (analysis['predictive_analysis'] != null) {
      final predictiveAnalysis = analysis['predictive_analysis'];
      print(
        '       Success Probability: ${predictiveAnalysis['success_probability'] ?? 'N/A'}',
      );
      print(
        '       Escalation Risk: ${predictiveAnalysis['escalation_risk'] ?? 'N/A'}',
      );
    }

    // Display integrated suggestions count
    if (analysis['integrated_suggestions'] != null) {
      final suggestions = analysis['integrated_suggestions'] as List<dynamic>;
      print('       Suggestions Generated: ${suggestions.length}');
    }
  }

  /// Display the generated relationship insights
  static void _displayInsightsData(Map<String, dynamic> insights) {
    print('📊 RELATIONSHIP INSIGHTS DASHBOARD DATA:');
    print(
      '  Compatibility Score: ${((insights['compatibility_score'] ?? 0.0) * 100).toInt()}%',
    );
    print(
      '  Communication Trend: ${insights['communication_trend'] ?? 'Unknown'}',
    );
    print('  Weekly Messages: ${insights['weekly_messages'] ?? 0}');
    print(
      '  Positive Sentiment: ${((insights['positive_sentiment'] ?? 0.0) * 100).toInt()}%',
    );

    print('\n  Your Style: ${insights['your_style'] ?? 'Unknown'}');
    print('  Partner Style: ${insights['partner_style'] ?? 'Unknown'}');
    print('  Your Communication: ${insights['your_comm'] ?? 'Unknown'}');
    print('  Partner Communication: ${insights['partner_comm'] ?? 'Unknown'}');

    // Growth Areas
    print('\n  Growth Areas:');
    final growthAreas = insights['growth_areas'] as List<dynamic>? ?? [];
    for (final area in growthAreas) {
      print('    • $area');
    }

    // Strengths
    print('\n  Strengths:');
    final strengths = insights['strengths'] as List<dynamic>? ?? [];
    for (final strength in strengths) {
      print('    • $strength');
    }

    // AI Recommendations
    print('\n  AI Recommendations:');
    final recommendations =
        insights['ai_recommendations'] as List<dynamic>? ?? [];
    if (recommendations.isEmpty) {
      print('    • No specific recommendations yet (using mock data fallback)');
    } else {
      for (final rec in recommendations) {
        final recommendation = rec as Map<String, dynamic>;
        print(
          '    • ${recommendation['title']}: ${recommendation['description']}',
        );
      }
    }

    // Weekly Analysis Chart Data
    print('\n  Weekly Analysis Chart:');
    final weeklyAnalysis = insights['weekly_analysis'] as List<dynamic>? ?? [];
    for (final dayData in weeklyAnalysis) {
      final day = dayData['day'];
      final score = ((dayData['score'] ?? 0.0) * 100).toInt();
      print('    $day: $score%');
    }
  }

  /// Simulate new analysis and show how insights update
  static Future<void> _simulateNewAnalysisAndUpdate() async {
    print('Adding new message analysis...');

    // Analyze a new message
    final newMessage =
        'I really appreciate how we worked through that conflict together. I feel closer to you now.';
    print('New message: "$newMessage"');

    final analysis = await _keyboardManager.performComprehensiveAnalysis(
      newMessage,
      relationshipContext: 'marriage',
      attachmentStyle: 'Secure',
      communicationStyle: 'Assertive',
    );

    if (analysis.containsKey('error')) {
      print('Analysis failed: ${analysis['error']}');
      return;
    }

    print('Analysis completed successfully!');
    _displayAnalysisHighlights(analysis);

    // Re-generate insights with updated history
    print('\nRegenerating insights with updated history...');
    final updatedInsights = await _insightsService
        .generateRelationshipInsights();

    print(
      'Updated Compatibility Score: ${((updatedInsights['compatibility_score'] ?? 0.0) * 100).toInt()}%',
    );
    print(
      'Updated Communication Trend: ${updatedInsights['communication_trend'] ?? 'Unknown'}',
    );

    // Show how the UI would update
    print('\n UI UPDATE SIMULATION:');
    print('  → Dashboard compatibility score updates in real-time');
    print('  → New insights appear in AI recommendations');
    print(
      '  → Growth areas and strengths are refined based on latest patterns',
    );
    print('  → Weekly chart updates with new data point');
    print('  → Communication style detection improves with more data');
  }

  /// Demo the specific features from the Advanced Text Communication Analyzer
  static void demoAdvancedAnalyzerFeatures() {
    print('\n=== ADVANCED ANALYZER FEATURES IN RELATIONSHIP INSIGHTS ===');

    print(' ATTACHMENT STYLE ANALYSIS:');
    print(
      '  • Identifies your attachment style (Secure, Anxious, Avoidant, Disorganized)',
    );
    print(
      '  • Detects partner\'s likely attachment style from communication patterns',
    );
    print('  • Provides attachment-specific coaching and suggestions');
    print('  • Surfaces attachment style clashes and compatibility insights');

    print('\n COMMUNICATION PATTERN DETECTION:');
    print('  • Analyzes 81+ communication issues and patterns');
    print('  • Tracks emotional regulation and constructiveness scores');
    print(
      '  • Identifies passive-aggressive behaviors and conflict escalation',
    );
    print('  • Detects overthinking patterns and self-doubt language');

    print('\n PERSONALIZED RECOMMENDATIONS:');
    print('  • Generates communication scripts for your attachment style');
    print(
      '  • Provides self-soothing tools and emergency de-escalation scripts',
    );
    print(
      '  • Offers daily check-ins and relationship maintenance suggestions',
    );
    print('  • Surfaces core wound healing insights and repair strategies');

    print('\n RELATIONSHIP METRICS:');
    print('  • Compatibility scoring based on communication analysis');
    print('  • Positive sentiment tracking and emotional tone analysis');
    print('  • Success probability predictions for conversations');
    print('  • Growth area identification from repeated patterns');

    print('\n REAL-TIME INSIGHTS:');
    print('  • Dashboard updates as you use the keyboard analyzer');
    print('  • Historical pattern recognition and trend analysis');
    print('  • Personalized coaching based on your specific challenges');
    print('  • Integration with iOS keyboard for seamless analysis');

    print('\n CONTINUOUS IMPROVEMENT:');
    print('  • Insights become more accurate with more usage');
    print('  • Machine learning from your communication patterns');
    print('  • Adaptive suggestions based on what works for your relationship');
    print('  • Long-term relationship health tracking and goals');
  }
}

/// Main entry point for running the demo
void main() async {
  await RelationshipInsightsDemoScript.runRelationshipInsightsDemo();
  RelationshipInsightsDemoScript.demoAdvancedAnalyzerFeatures();
}
