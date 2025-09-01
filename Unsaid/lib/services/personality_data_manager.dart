import 'dart:io';
import 'package:flutter/services.dart';

class PersonalityDataManager {
  static PersonalityDataManager? _instance;
  static PersonalityDataManager get shared {
    _instance ??= PersonalityDataManager._();
    return _instance!;
  }
  
  PersonalityDataManager._();
  
  static const MethodChannel _channel = MethodChannel('com.unsaid/keyboard_data_sync');
  
  /// Collect keyboard analytics data when app opens
  Future<Map<String, dynamic>?> collectKeyboardAnalytics() async {
    try {
      if (Platform.isIOS) {
        print('📊 PersonalityDataManager: Collecting keyboard analytics...');
        final Map<dynamic, dynamic>? data = await _channel.invokeMethod('getAllPendingKeyboardData');
        
        if (data != null) {
          final analytics = Map<String, dynamic>.from(data);
          print('✅ Flutter: Collected keyboard analytics - ${analytics['metadata']?['total_items'] ?? 0} total items');
          return analytics;
        }
        print('📭 No pending keyboard data found');
      }
    } catch (e) {
      print('❌ Error collecting keyboard analytics: $e');
    }
    return null;
  }

  /// Get keyboard storage metadata (counts and status)
  Future<Map<String, dynamic>?> getKeyboardStorageMetadata() async {
    try {
      if (Platform.isIOS) {
        print('📋 PersonalityDataManager: Getting keyboard storage metadata...');
        final Map<dynamic, dynamic>? metadata = await _channel.invokeMethod('getKeyboardStorageMetadata');
        
        if (metadata != null) {
          final storageInfo = Map<String, dynamic>.from(metadata);
          print('📊 Storage metadata: ${storageInfo['total_items']} total items across all queues');
          return storageInfo;
        }
      }
    } catch (e) {
      print('❌ Error getting storage metadata: $e');
    }
    return null;
  }
  
  /// Analyze collected keyboard data for personality insights
  Future<Map<String, dynamic>?> analyzeKeyboardBehavior() async {
    try {
      if (Platform.isIOS) {
        print('🧠 PersonalityDataManager: Analyzing keyboard behavior...');
        
        // First collect the raw data
        final rawData = await collectKeyboardAnalytics();
        if (rawData == null) {
          print('⚠️ No keyboard data available for analysis');
          return null;
        }
        
        // Analyze the collected data
        final analysis = _performBehaviorAnalysis(rawData);
        print('✅ Flutter: Generated behavior analysis - ${analysis.keys.length} insights');
        return analysis;
      }
    } catch (e) {
      print('❌ Error analyzing keyboard behavior: $e');
    }
    return null;
  }

  /// Clear all pending keyboard data after processing
  Future<bool> clearProcessedKeyboardData() async {
    try {
      if (Platform.isIOS) {
        print('🧹 PersonalityDataManager: Clearing processed keyboard data...');
        final bool success = await _channel.invokeMethod('clearAllPendingKeyboardData') ?? false;
        
        if (success) {
          print('✅ Successfully cleared all pending keyboard data');
        } else {
          print('⚠️ Failed to clear keyboard data');
        }
        return success;
      }
    } catch (e) {
      print('❌ Error clearing keyboard data: $e');
    }
    return false;
  }

  /// Get user data from keyboard extension
  Future<Map<String, dynamic>?> getKeyboardUserData() async {
    try {
      if (Platform.isIOS) {
        final Map<dynamic, dynamic>? userData = await _channel.invokeMethod('getUserData');
        return userData != null ? Map<String, dynamic>.from(userData) : null;
      }
    } catch (e) {
      print('❌ Error getting keyboard user data: $e');
    }
    return null;
  }

  /// Get API response data from keyboard extension
  Future<Map<String, dynamic>?> getKeyboardAPIData() async {
    try {
      if (Platform.isIOS) {
        final Map<dynamic, dynamic>? apiData = await _channel.invokeMethod('getAPIData');
        return apiData != null ? Map<String, dynamic>.from(apiData) : null;
      }
    } catch (e) {
      print('❌ Error getting keyboard API data: $e');
    }
    return null;
  }

  /// Perform detailed behavior analysis on collected keyboard data
  Map<String, dynamic> _performBehaviorAnalysis(Map<String, dynamic> rawData) {
    final analysis = <String, dynamic>{};
    
    // Extract data categories
    final interactions = rawData['interactions'] as List<dynamic>? ?? [];
    final toneData = rawData['tone_data'] as List<dynamic>? ?? [];
    final suggestions = rawData['suggestions'] as List<dynamic>? ?? [];
    final analytics = rawData['analytics'] as List<dynamic>? ?? [];
    final apiSuggestions = rawData['api_suggestions'] as List<dynamic>? ?? [];
    final metadata = rawData['metadata'] as Map<String, dynamic>? ?? {};
    
    // Calculate interaction patterns
    analysis['interaction_patterns'] = _analyzeInteractionPatterns(interactions);
    
    // Calculate tone patterns
    analysis['tone_patterns'] = _analyzeTonePatterns(toneData);
    
    // Calculate suggestion patterns
    analysis['suggestion_patterns'] = _analyzeSuggestionPatterns(suggestions, apiSuggestions);
    
    // Calculate usage patterns
    analysis['usage_patterns'] = _analyzeUsagePatterns(analytics);
    
    // Generate behavioral insights
    analysis['behavioral_insights'] = _generateBehaviorInsights(analysis);
    
    // Add metadata
    analysis['analysis_metadata'] = {
      'total_data_points': metadata['total_items'] ?? 0,
      'analysis_timestamp': DateTime.now().millisecondsSinceEpoch,
      'data_quality_score': _calculateDataQuality(rawData),
    };
    
    return analysis;
  }

  /// Analyze interaction patterns (keystrokes, selections, deletions)
  Map<String, dynamic> _analyzeInteractionPatterns(List<dynamic> interactions) {
    if (interactions.isEmpty) return {'no_data': true};
    
    int keystrokeCount = 0;
    int suggestionCount = 0;
    int deletionCount = 0;
    int totalEvents = interactions.length;
    
    for (final interaction in interactions) {
      final type = interaction['type'] as String? ?? '';
      switch (type) {
        case 'keystroke':
          keystrokeCount++;
          break;
        case 'suggestion_selected':
          suggestionCount++;
          break;
        case 'text_deleted':
          deletionCount++;
          break;
      }
    }
    
    return {
      'total_interactions': totalEvents,
      'keystroke_count': keystrokeCount,
      'suggestion_count': suggestionCount,
      'deletion_count': deletionCount,
      'suggestion_acceptance_rate': totalEvents > 0 ? suggestionCount / totalEvents : 0.0,
      'deletion_rate': totalEvents > 0 ? deletionCount / totalEvents : 0.0,
      'typing_efficiency': totalEvents > 0 ? keystrokeCount / totalEvents : 0.0,
    };
  }

  /// Analyze tone patterns and emotional indicators
  Map<String, dynamic> _analyzeTonePatterns(List<dynamic> toneData) {
    if (toneData.isEmpty) return {'no_data': true};
    
    final toneDistribution = <String, int>{};
    double totalConfidence = 0.0;
    int confidenceCount = 0;
    
    for (final tone in toneData) {
      final toneType = tone['tone'] as String? ?? 'neutral';
      final confidence = tone['confidence'] as double? ?? 0.0;
      
      toneDistribution[toneType] = (toneDistribution[toneType] ?? 0) + 1;
      
      if (confidence > 0) {
        totalConfidence += confidence;
        confidenceCount++;
      }
    }
    
    return {
      'total_tone_analyses': toneData.length,
      'tone_distribution': toneDistribution,
      'average_confidence': confidenceCount > 0 ? totalConfidence / confidenceCount : 0.0,
      'most_common_tone': toneDistribution.entries.isNotEmpty 
          ? toneDistribution.entries.reduce((a, b) => a.value > b.value ? a : b).key 
          : 'neutral',
    };
  }

  /// Analyze suggestion patterns and acceptance rates
  Map<String, dynamic> _analyzeSuggestionPatterns(List<dynamic> suggestions, List<dynamic> apiSuggestions) {
    final totalSuggestions = suggestions.length + apiSuggestions.length;
    if (totalSuggestions == 0) return {'no_data': true};
    
    int acceptedCount = 0;
    int rejectedCount = 0;
    
    // Analyze local suggestions
    for (final suggestion in suggestions) {
      final accepted = suggestion['accepted'] as bool? ?? false;
      if (accepted) {
        acceptedCount++;
      } else {
        rejectedCount++;
      }
    }
    
    // Analyze API suggestions
    for (final apiSuggestion in apiSuggestions) {
      final accepted = apiSuggestion['accepted'] as bool? ?? false;
      if (accepted) {
        acceptedCount++;
      } else {
        rejectedCount++;
      }
    }
    
    return {
      'total_suggestions': totalSuggestions,
      'local_suggestions': suggestions.length,
      'api_suggestions': apiSuggestions.length,
      'accepted_count': acceptedCount,
      'rejected_count': rejectedCount,
      'acceptance_rate': totalSuggestions > 0 ? acceptedCount / totalSuggestions : 0.0,
      'api_vs_local_ratio': suggestions.length > 0 ? apiSuggestions.length / suggestions.length : 0.0,
    };
  }

  /// Analyze usage patterns and timing
  Map<String, dynamic> _analyzeUsagePatterns(List<dynamic> analytics) {
    if (analytics.isEmpty) return {'no_data': true};
    
    final timeDistribution = <String, int>{};
    final appDistribution = <String, int>{};
    
    for (final event in analytics) {
      final timestamp = event['timestamp'] as int? ?? 0;
      final app = event['app'] as String? ?? 'unknown';
      
      if (timestamp > 0) {
        final hour = DateTime.fromMillisecondsSinceEpoch(timestamp).hour;
        final timeSlot = _getTimeSlot(hour);
        timeDistribution[timeSlot] = (timeDistribution[timeSlot] ?? 0) + 1;
      }
      
      appDistribution[app] = (appDistribution[app] ?? 0) + 1;
    }
    
    return {
      'total_events': analytics.length,
      'time_distribution': timeDistribution,
      'app_distribution': appDistribution,
      'most_active_time': timeDistribution.entries.isNotEmpty 
          ? timeDistribution.entries.reduce((a, b) => a.value > b.value ? a : b).key 
          : 'unknown',
      'most_used_app': appDistribution.entries.isNotEmpty 
          ? appDistribution.entries.reduce((a, b) => a.value > b.value ? a : b).key 
          : 'unknown',
    };
  }

  /// Generate high-level behavioral insights
  Map<String, dynamic> _generateBehaviorInsights(Map<String, dynamic> analysis) {
    final insights = <String, dynamic>{};
    
    // Engagement level
    final interactions = analysis['interaction_patterns'] as Map<String, dynamic>? ?? {};
    final totalInteractions = interactions['total_interactions'] as int? ?? 0;
    insights['engagement_level'] = _calculateEngagementLevel(totalInteractions);
    
    // Tone stability
    final tonePatterns = analysis['tone_patterns'] as Map<String, dynamic>? ?? {};
    final avgConfidence = tonePatterns['average_confidence'] as double? ?? 0.0;
    insights['tone_stability'] = avgConfidence > 0.7 ? 'stable' : avgConfidence > 0.4 ? 'moderate' : 'variable';
    
    // Suggestion receptivity
    final suggestionPatterns = analysis['suggestion_patterns'] as Map<String, dynamic>? ?? {};
    final acceptanceRate = suggestionPatterns['acceptance_rate'] as double? ?? 0.0;
    insights['suggestion_receptivity'] = acceptanceRate > 0.6 ? 'high' : acceptanceRate > 0.3 ? 'moderate' : 'low';
    
    // Communication style
    final deletionRate = interactions['deletion_rate'] as double? ?? 0.0;
    insights['communication_style'] = deletionRate > 0.3 ? 'deliberate' : deletionRate > 0.1 ? 'balanced' : 'spontaneous';
    
    return insights;
  }

  /// Calculate data quality score based on completeness and validity
  double _calculateDataQuality(Map<String, dynamic> rawData) {
    double score = 0.0;
    int factors = 0;
    
    // Check data completeness
    final categories = ['interactions', 'tone_data', 'suggestions', 'analytics'];
    for (final category in categories) {
      final data = rawData[category] as List<dynamic>? ?? [];
      if (data.isNotEmpty) {
        score += 0.25;
      }
      factors++;
    }
    
    // Check metadata quality
    final metadata = rawData['metadata'] as Map<String, dynamic>? ?? {};
    if (metadata.containsKey('total_items') && metadata['total_items'] > 0) {
      score += 0.1;
    }
    
    return factors > 0 ? score : 0.0;
  }

  /// Get time slot for hour-based analysis
  String _getTimeSlot(int hour) {
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 18) return 'afternoon';
    if (hour >= 18 && hour < 22) return 'evening';
    return 'night';
  }

  /// Calculate engagement level based on interaction count
  String _calculateEngagementLevel(int interactions) {
    if (interactions > 100) return 'high';
    if (interactions > 30) return 'moderate';
    if (interactions > 5) return 'low';
    return 'minimal';
  }
  
  /// Store personality assessment results and sync to keyboard
  Future<void> storePersonalityData(Map<String, dynamic> personalityData) async {
    try {
      if (Platform.isIOS) {
        await _channel.invokeMethod('storePersonalityData', personalityData);
        print('✅ Flutter: Personality data stored and synced to keyboard');
      }
    } catch (e) {
      print('⚠️ Warning: Failed to store personality data: $e');
    }
  }
  
  /// Store user's emotional state and bridge to iOS
  Future<void> setUserEmotionalState({
    required String state,
    required String bucket,
    required String label,
  }) async {
    try {
      if (Platform.isIOS) {
        await _channel.invokeMethod('setUserEmotionalState', {
          'state': state,
          'bucket': bucket,
          'label': label,
        });
        print('✅ Flutter: Emotional state bridged to iOS - $label ($bucket)');
      } else {
        print('ℹ️ Platform not iOS, emotional state stored locally only');
      }
    } catch (e) {
      print('⚠️ Warning: Failed to bridge emotional state to iOS: $e');
    }
  }
  
  /// Get user's current emotional state from iOS
  Future<String> getUserEmotionalState() async {
    try {
      if (Platform.isIOS) {
        final String state = await _channel.invokeMethod('getUserEmotionalState');
        return state;
      }
    } catch (e) {
      print('⚠️ Warning: Failed to get emotional state from iOS: $e');
    }
    return 'neutral_distracted';
  }
  
  /// Get user's current emotional bucket from iOS
  Future<String> getUserEmotionalBucket() async {
    try {
      if (Platform.isIOS) {
        final String bucket = await _channel.invokeMethod('getUserEmotionalBucket');
        return bucket;
      }
    } catch (e) {
      print('⚠️ Warning: Failed to get emotional bucket from iOS: $e');
    }
    return 'moderate';
  }
  
  /// Store complete personality test results and bridge to iOS
  Future<void> storePersonalityTestResults(Map<String, dynamic> results) async {
    try {
      if (Platform.isIOS) {
        await _channel.invokeMethod('storePersonalityTestResults', results);
        print('✅ Flutter: Personality test results bridged to iOS');
        print('   📊 Results: ${results.keys.join(', ')}');
      } else {
        print('ℹ️ Platform not iOS, personality test results stored locally only');
      }
    } catch (e) {
      print('⚠️ Warning: Failed to bridge personality test results to iOS: $e');
    }
  }
  
  /// Store individual personality components and bridge to iOS
  Future<void> storePersonalityComponents({
    required String attachmentStyle,
    required String communicationPattern,
    required String conflictResolution,
    required String primaryPersonalityType,
    required String typeLabel,
    required Map<String, int> scores,
  }) async {
    try {
      if (Platform.isIOS) {
        await _channel.invokeMethod('storePersonalityComponents', {
          'attachmentStyle': attachmentStyle,
          'communicationPattern': communicationPattern,
          'conflictResolution': conflictResolution,
          'primaryPersonalityType': primaryPersonalityType,
          'typeLabel': typeLabel,
          'scores': scores,
        });
        print('✅ Flutter: Personality components bridged to iOS');
        print('   🎭 Attachment Style: $attachmentStyle');
        print('   💬 Communication Pattern: $communicationPattern');
        print('   🤝 Conflict Resolution: $conflictResolution');
        print('   🧠 Personality Type: $primaryPersonalityType ($typeLabel)');
      } else {
        print('ℹ️ Platform not iOS, personality components stored locally only');
      }
    } catch (e) {
      print('⚠️ Warning: Failed to bridge personality components to iOS: $e');
    }
  }
  
  /// Get complete personality test results from iOS
  Future<Map<String, dynamic>?> getPersonalityTestResults() async {
    try {
      if (Platform.isIOS) {
        final Map<dynamic, dynamic>? results = await _channel.invokeMethod('getPersonalityTestResults');
        return results?.cast<String, dynamic>();
      }
    } catch (e) {
      print('⚠️ Warning: Failed to get personality test results from iOS: $e');
    }
    return null;
  }
  
  /// Get dominant personality type from iOS
  Future<String?> getDominantPersonalityType() async {
    try {
      if (Platform.isIOS) {
        return await _channel.invokeMethod('getDominantPersonalityType');
      }
    } catch (e) {
      print('⚠️ Warning: Failed to get dominant personality type from iOS: $e');
    }
    return null;
  }
  
  /// Get personality type label from iOS
  Future<String?> getPersonalityTypeLabel() async {
    try {
      if (Platform.isIOS) {
        return await _channel.invokeMethod('getPersonalityTypeLabel');
      }
    } catch (e) {
      print('⚠️ Warning: Failed to get personality type label from iOS: $e');
    }
    return null;
  }
  
  /// Get personality scores from iOS
  Future<Map<String, int>?> getPersonalityScores() async {
    try {
      if (Platform.isIOS) {
        final Map<dynamic, dynamic>? scores = await _channel.invokeMethod('getPersonalityScores');
        return scores?.cast<String, int>();
      }
    } catch (e) {
      print('⚠️ Warning: Failed to get personality scores from iOS: $e');
    }
    return null;
  }
  
  /// Check if personality test is complete
  Future<bool> isPersonalityTestComplete() async {
    try {
      if (Platform.isIOS) {
        return await _channel.invokeMethod('isPersonalityTestComplete');
      }
    } catch (e) {
      print('⚠️ Warning: Failed to check personality test completion from iOS: $e');
    }
    return false;
  }
  
  /// Generate personality context for API calls
  Future<String> generatePersonalityContext() async {
    try {
      if (Platform.isIOS) {
        return await _channel.invokeMethod('generatePersonalityContext');
      }
    } catch (e) {
      print('⚠️ Warning: Failed to generate personality context from iOS: $e');
    }
    return 'No personality context available';
  }
  
  /// Generate personality context dictionary for API calls
  Future<Map<String, dynamic>?> generatePersonalityContextDictionary() async {
    try {
      if (Platform.isIOS) {
        final Map<dynamic, dynamic>? context = await _channel.invokeMethod('generatePersonalityContextDictionary');
        return context?.cast<String, dynamic>();
      }
    } catch (e) {
      print('⚠️ Warning: Failed to generate personality context dictionary from iOS: $e');
    }
    return null;
  }
  
  /// Clear all personality data
  Future<void> clearPersonalityData() async {
    try {
      if (Platform.isIOS) {
        await _channel.invokeMethod('clearPersonalityData');
        print('✅ Flutter: Personality data cleared from iOS');
      } else {
        print('ℹ️ Platform not iOS, personality data cleared locally only');
      }
    } catch (e) {
      print('⚠️ Warning: Failed to clear personality data from iOS: $e');
    }
  }
  
  /// Debug print personality data
  Future<void> debugPrintPersonalityData() async {
    try {
      if (Platform.isIOS) {
        await _channel.invokeMethod('debugPrintPersonalityData');
      }
    } catch (e) {
      print('⚠️ Warning: Failed to debug print personality data from iOS: $e');
    }
  }
  
  /// Set test personality data for development
  Future<void> setTestPersonalityData() async {
    try {
      if (Platform.isIOS) {
        await _channel.invokeMethod('setTestPersonalityData');
        print('✅ Flutter: Test personality data set in iOS');
      } else {
        print('ℹ️ Platform not iOS, test personality data set locally only');
      }
    } catch (e) {
      print('⚠️ Warning: Failed to set test personality data in iOS: $e');
    }
  }

  /// Comprehensive startup method to collect and analyze all keyboard data
  /// Call this when the main app opens to gather insights from keyboard usage
  Future<Map<String, dynamic>?> performStartupKeyboardAnalysis() async {
    try {
      print('🚀 PersonalityDataManager: Starting comprehensive keyboard analysis...');
      
      // First, check if there's any data to analyze
      final metadata = await getKeyboardStorageMetadata();
      if (metadata == null || metadata['total_items'] == 0) {
        print('📭 No keyboard data available for analysis');
        return null;
      }
      
      print('📊 Found ${metadata['total_items']} items in keyboard storage');
      
      // Collect all keyboard data
      final keyboardData = await collectKeyboardAnalytics();
      if (keyboardData == null) {
        print('⚠️ Failed to collect keyboard data');
        return null;
      }
      
      // Perform comprehensive behavior analysis
      final behaviorAnalysis = await analyzeKeyboardBehavior();
      if (behaviorAnalysis == null) {
        print('⚠️ Failed to analyze keyboard behavior');
        return null;
      }
      
      // Get user data and API data for additional context
      final userData = await getKeyboardUserData();
      final apiData = await getKeyboardAPIData();
      
      // Combine all insights
      final comprehensiveAnalysis = {
        'behavior_analysis': behaviorAnalysis,
        'raw_keyboard_data': keyboardData,
        'user_context': userData,
        'api_context': apiData,
        'storage_metadata': metadata,
        'analysis_summary': _generateAnalysisSummary(behaviorAnalysis),
        'collection_timestamp': DateTime.now().toIso8601String(),
      };
      
      print('✅ Comprehensive keyboard analysis complete!');
      print('📈 Analysis summary: ${comprehensiveAnalysis['analysis_summary']}');
      
      // Optional: Clear processed data after successful analysis
      // await clearProcessedKeyboardData();
      
      return comprehensiveAnalysis;
    } catch (e) {
      print('❌ Error during startup keyboard analysis: $e');
      return null;
    }
  }

  /// Generate a human-readable summary of the analysis
  Map<String, dynamic> _generateAnalysisSummary(Map<String, dynamic> behaviorAnalysis) {
    final insights = behaviorAnalysis['behavioral_insights'] as Map<String, dynamic>? ?? {};
    final interactionPatterns = behaviorAnalysis['interaction_patterns'] as Map<String, dynamic>? ?? {};
    final tonePatterns = behaviorAnalysis['tone_patterns'] as Map<String, dynamic>? ?? {};
    final suggestionPatterns = behaviorAnalysis['suggestion_patterns'] as Map<String, dynamic>? ?? {};
    
    return {
      'engagement_level': insights['engagement_level'] ?? 'unknown',
      'tone_stability': insights['tone_stability'] ?? 'unknown',
      'suggestion_receptivity': insights['suggestion_receptivity'] ?? 'unknown',
      'communication_style': insights['communication_style'] ?? 'unknown',
      'total_interactions': interactionPatterns['total_interactions'] ?? 0,
      'most_common_tone': tonePatterns['most_common_tone'] ?? 'neutral',
      'suggestion_acceptance_rate': suggestionPatterns['acceptance_rate'] ?? 0.0,
      'data_quality_score': behaviorAnalysis['analysis_metadata']?['data_quality_score'] ?? 0.0,
    };
  }

  /// Quick method to check if keyboard data is available
  Future<bool> hasKeyboardDataAvailable() async {
    try {
      final metadata = await getKeyboardStorageMetadata();
      return metadata != null && (metadata['total_items'] as int? ?? 0) > 0;
    } catch (e) {
      print('❌ Error checking keyboard data availability: $e');
      return false;
    }
  }

  /// Get a quick summary of available keyboard data
  Future<String> getKeyboardDataSummary() async {
    try {
      final metadata = await getKeyboardStorageMetadata();
      if (metadata == null) return 'No data available';
      
      final totalItems = metadata['total_items'] as int? ?? 0;
      final interactionCount = metadata['interaction_count'] as int? ?? 0;
      final toneCount = metadata['tone_count'] as int? ?? 0;
      final suggestionCount = metadata['suggestion_count'] as int? ?? 0;
      
      return 'Total: $totalItems items ($interactionCount interactions, $toneCount tone analyses, $suggestionCount suggestions)';
    } catch (e) {
      return 'Error retrieving summary: $e';
    }
  }
}
