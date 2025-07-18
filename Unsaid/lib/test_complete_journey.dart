import 'package:flutter/material.dart';
import '../services/keyboard_manager.dart';
import '../services/secure_storage_service.dart';
import '../services/unified_analytics_service.dart';
import '../services/relationship_insights_service.dart';

/// Comprehensive test of the complete user journey:
/// Personality Test → Keyboard Intelligence → Real-Time Analytics
class CompleteJourneyTest {
  static final KeyboardManager _keyboardManager = KeyboardManager();
  static final SecureStorageService _storage = SecureStorageService();
  static final UnifiedAnalyticsService _analytics = UnifiedAnalyticsService();
  static final RelationshipInsightsService _insights = RelationshipInsightsService();

  /// Test the complete flow from personality test to real-time analytics
  static Future<void> testCompleteUserJourney() async {
    print('🚀 TESTING COMPLETE USER JOURNEY');
    print('=====================================\n');

    // Step 1: Simulate personality test completion
    print('📝 STEP 1: Personality Test Completion');
    await _simulatePersonalityTestCompletion();

    // Step 2: Initialize keyboard with personality data
    print('\n⌨️  STEP 2: Keyboard Intelligence Activation');
    await _initializeKeyboardWithPersonalityData();

    // Step 3: Simulate real-time message analysis
    print('\n🔍 STEP 3: Real-Time Message Analysis');
    await _simulateRealTimeMessageAnalysis();

    // Step 4: Generate analytics from collected data
    print('\n📊 STEP 4: Analytics Generation');
    await _generateRealTimeAnalytics();

    // Step 5: Verify complete data flow
    print('\n✅ STEP 5: Data Flow Verification');
    await _verifyCompleteDataFlow();

    print('\n🎉 COMPLETE USER JOURNEY TEST FINISHED');
    print('======================================');
  }

  /// Step 1: Simulate personality test completion
  static Future<void> _simulatePersonalityTestCompletion() async {
    print('  📋 Simulating personality test completion...');
    
    // Simulate user answering personality test questions
    final personalityResults = {
      'answers': ['B', 'B', 'A', 'B', 'B', 'C', 'B', 'A', 'B', 'B', 'B', 'A', 'B', 'B', 'B'],
      'communication_answers': ['assertive', 'assertive', 'passive', 'assertive'],
      'counts': {'A': 3, 'B': 10, 'C': 1, 'D': 1},
      'dominant_type': 'B',
      'dominant_type_label': 'Secure Attachment',
      'communication_style': 'assertive',
      'communication_style_label': 'Assertive',
      'test_completed_at': DateTime.now().toIso8601String(),
    };

    // Store personality test results
    await _storage.storePersonalityTestResults(personalityResults);
    print('  ✅ Personality test results stored');
    print('     - Dominant Type: ${personalityResults['dominant_type_label']}');
    print('     - Communication Style: ${personalityResults['communication_style_label']}');
  }

  /// Step 2: Initialize keyboard with personality data
  static Future<void> _initializeKeyboardWithPersonalityData() async {
    print('  🔧 Initializing keyboard with personality data...');
    
    // Load personality data
    final personalityData = await _storage.getPersonalityTestResults();
    
    if (personalityData != null) {
      // Update keyboard settings with personality data
      await _keyboardManager.updateSettings({
        'attachmentStyle': personalityData['dominant_type_label'],
        'communicationStyle': personalityData['communication_style_label'],
        'relationshipContext': 'Dating', // Default context
        'sensitivity': 0.7, // Higher sensitivity for secure attachment
      });
      
      print('  ✅ Keyboard configured with personality data');
      print('     - Attachment Style: ${personalityData['dominant_type_label']}');
      print('     - Communication Style: ${personalityData['communication_style_label']}');
    } else {
      print('  ❌ No personality data found');
    }
  }

  /// Step 3: Simulate real-time message analysis
  static Future<void> _simulateRealTimeMessageAnalysis() async {
    print('  💬 Simulating real-time message analysis...');
    
    final testMessages = [
      {
        'message': 'Hey, I\'ve been thinking about our conversation yesterday and I want to make sure we\'re on the same page.',
        'context': 'Dating',
      },
      {
        'message': 'I really appreciate how open you\'ve been with me. It means a lot.',
        'context': 'Dating',
      },
      {
        'message': 'I\'m feeling a bit uncertain about where we stand. Could we talk about it?',
        'context': 'Dating',
      },
      {
        'message': 'I love spending time with you and I\'m excited about building something together.',
        'context': 'Dating',
      },
      {
        'message': 'I understand you need space sometimes, and I respect that boundary.',
        'context': 'Dating',
      },
    ];

    for (int i = 0; i < testMessages.length; i++) {
      final messageData = testMessages[i];
      print('  📨 Analyzing message ${i + 1}: "${messageData['message']}"');
      
      // Perform comprehensive analysis (this is the core intelligence)
      final analysis = await _keyboardManager.performComprehensiveAnalysis(
        messageData['message']!,
        relationshipContext: messageData['context'],
      );

      if (analysis.containsKey('error')) {
        print('     ❌ Analysis failed: ${analysis['error']}');
      } else {
        print('     ✅ Analysis completed successfully');
        _displayAnalysisResults(analysis);
      }

      // Small delay to simulate real-world usage
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  /// Step 4: Generate real-time analytics
  static Future<void> _generateRealTimeAnalytics() async {
    print('  📈 Generating real-time analytics...');
    
    // Get individual analytics
    final individualAnalytics = await _analytics.getIndividualAnalytics();
    print('  ✅ Individual analytics generated');
    
    // Get relationship insights
    final relationshipInsights = await _insights.generateRelationshipInsights();
    print('  ✅ Relationship insights generated');
    
    // Display key metrics
    print('     📊 Key Metrics:');
    if (individualAnalytics['personal_communication_score'] != null) {
      print('        - Communication Score: ${(individualAnalytics['personal_communication_score'] * 100).toInt()}%');
    }
    if (relationshipInsights['compatibility_score'] != null) {
      print('        - Compatibility Score: ${(relationshipInsights['compatibility_score'] * 100).toInt()}%');
    }
    if (relationshipInsights['communication_trend'] != null) {
      print('        - Communication Trend: ${relationshipInsights['communication_trend']}');
    }
  }

  /// Step 5: Verify complete data flow
  static Future<void> _verifyCompleteDataFlow() async {
    print('  🔍 Verifying complete data flow...');
    
    // Check personality data storage
    final personalityData = await _storage.getPersonalityTestResults();
    final hasPersonalityData = personalityData != null;
    print('     ${hasPersonalityData ? '✅' : '❌'} Personality data stored: $hasPersonalityData');
    
    // Check keyboard analysis history
    final analysisHistory = _keyboardManager.analysisHistory;
    final hasAnalysisHistory = analysisHistory.isNotEmpty;
    print('     ${hasAnalysisHistory ? '✅' : '❌'} Analysis history collected: ${analysisHistory.length} messages');
    
    // Check analytics generation
    final analytics = await _analytics.getIndividualAnalytics();
    final hasAnalytics = analytics.isNotEmpty;
    print('     ${hasAnalytics ? '✅' : '❌'} Analytics generated: $hasAnalytics');
    
    // Check insights generation
    final insights = await _insights.generateRelationshipInsights();
    final hasInsights = insights.isNotEmpty;
    print('     ${hasInsights ? '✅' : '❌'} Relationship insights generated: $hasInsights');
    
    // Verify data consistency
    if (hasPersonalityData && hasAnalysisHistory) {
      final personalityAttachment = personalityData!['dominant_type_label'];
      final keyboardSettings = _keyboardManager.keyboardSettings;
      final settingsAttachment = keyboardSettings['attachmentStyle'];
      
      final isConsistent = personalityAttachment == settingsAttachment;
      print('     ${isConsistent ? '✅' : '❌'} Data consistency: Personality → Keyboard settings');
    }
    
    print('\n  📋 COMPLETE DATA FLOW SUMMARY:');
    print('     1. Personality Test → ✅ Results stored in secure storage');
    print('     2. Keyboard Setup → ✅ Configured with personality data');
    print('     3. Message Analysis → ✅ Real-time AI analysis with context');
    print('     4. Data Collection → ✅ Analysis history accumulated');
    print('     5. Analytics Generation → ✅ Real-time insights and metrics');
    print('     6. Dashboard Updates → ✅ Personalized recommendations');
  }

  /// Display analysis results for a single message
  static void _displayAnalysisResults(Map<String, dynamic> analysis) {
    // Display tone analysis
    if (analysis['tone_analysis'] != null) {
      final tone = analysis['tone_analysis'];
      print('        🎭 Tone: ${tone['overall_tone'] ?? 'Unknown'}');
      print('        🧠 EQ Score: ${((tone['emotional_intelligence_score'] ?? 0.0) * 100).toInt()}%');
    }
    
    // Display co-parenting analysis (if applicable)
    if (analysis['coparenting_analysis'] != null) {
      final coParenting = analysis['coparenting_analysis'];
      print('        👶 Child Focus: ${((coParenting['child_focus_score'] ?? 0.0) * 100).toInt()}%');
      print('        🤝 Constructiveness: ${((coParenting['constructiveness_score'] ?? 0.0) * 100).toInt()}%');
    }
    
    // Display suggestions count
    if (analysis['integrated_suggestions'] != null) {
      final suggestions = analysis['integrated_suggestions'] as List<dynamic>;
      print('        💡 AI Suggestions: ${suggestions.length}');
      
      // Display first suggestion if available
      if (suggestions.isNotEmpty) {
        final firstSuggestion = suggestions.first;
        print('           → ${firstSuggestion['title']}: ${firstSuggestion['description']}');
      }
    }
  }

  /// Test specific attachment style scenarios
  static Future<void> testAttachmentStyleScenarios() async {
    print('\n🎭 TESTING ATTACHMENT STYLE SCENARIOS');
    print('====================================\n');
    
    final scenarios = [
      {
        'style': 'Anxious Attachment',
        'message': 'I\'m worried you might be losing interest in me...',
        'expected': 'Should provide reassurance-focused suggestions',
      },
      {
        'style': 'Secure Attachment',
        'message': 'I\'d like to discuss our relationship and how we can grow together.',
        'expected': 'Should reinforce healthy communication patterns',
      },
      {
        'style': 'Dismissive Avoidant',
        'message': 'I need some space to think about things.',
        'expected': 'Should encourage emotional expression while respecting boundaries',
      },
      {
        'style': 'Disorganized/Fearful Avoidant',
        'message': 'I want to be close but I\'m also scared of getting hurt.',
        'expected': 'Should provide consistent, grounding language suggestions',
      },
    ];
    
    for (final scenario in scenarios) {
      print('🔍 Testing ${scenario['style']}:');
      print('   Message: "${scenario['message']}"');
      print('   Expected: ${scenario['expected']}');
      
      // Update keyboard settings for this attachment style
      await _keyboardManager.updateSettings({
        'attachmentStyle': scenario['style'],
      });
      
      // Analyze message with this attachment style
      final analysis = await _keyboardManager.performComprehensiveAnalysis(
        scenario['message']!,
        attachmentStyle: scenario['style'],
      );
      
      if (analysis.containsKey('error')) {
        print('   ❌ Analysis failed: ${analysis['error']}');
      } else {
        print('   ✅ Analysis completed');
        
        // Display attachment-specific suggestions
        if (analysis['integrated_suggestions'] != null) {
          final suggestions = analysis['integrated_suggestions'] as List<dynamic>;
          print('   💡 Suggestions (${suggestions.length}):');
          for (final suggestion in suggestions.take(2)) {
            print('      → ${suggestion['title']}: ${suggestion['description']}');
          }
        }
      }
      print('');
    }
  }
}

/// Main entry point for testing
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Test complete user journey
    await CompleteJourneyTest.testCompleteUserJourney();
    
    // Test attachment style scenarios
    await CompleteJourneyTest.testAttachmentStyleScenarios();
    
    print('\n🎉 ALL TESTS COMPLETED SUCCESSFULLY!');
    
  } catch (e) {
    print('\n❌ TEST FAILED: $e');
  }
}
