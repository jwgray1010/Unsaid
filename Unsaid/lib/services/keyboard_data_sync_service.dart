import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:convert';

/// Service to retrieve keyboard analytics data when main app opens
/// Safely pulls data stored by keyboard extension without impacting keyboard performance
class KeyboardDataSyncService {
  static KeyboardDataSyncService? _instance;
  static KeyboardDataSyncService get shared {
    _instance ??= KeyboardDataSyncService._();
    return _instance!;
  }
  
  KeyboardDataSyncService._();
  
  static const MethodChannel _channel = MethodChannel('com.unsaid/keyboard_data_sync');
  
  // MARK: - Data Models
  
  /// Keyboard interaction data model
  class KeyboardInteractionData {
    final String id;
    final DateTime timestamp;
    final int textLength;
    final String toneStatus;
    final bool suggestionAccepted;
    final int suggestionLength;
    final double analysisTime;
    final String context;
    final String interactionType;
    final int wordCount;
    final String appContext;
    
    KeyboardInteractionData({
      required this.id,
      required this.timestamp,
      required this.textLength,
      required this.toneStatus,
      required this.suggestionAccepted,
      required this.suggestionLength,
      required this.analysisTime,
      required this.context,
      required this.interactionType,
      required this.wordCount,
      required this.appContext,
    });
    
    factory KeyboardInteractionData.fromMap(Map<String, dynamic> map) {
      return KeyboardInteractionData(
        id: map['id'] ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch((map['timestamp'] * 1000).round()),
        textLength: map['text_length'] ?? 0,
        toneStatus: map['tone_status'] ?? 'neutral',
        suggestionAccepted: map['suggestion_accepted'] ?? false,
        suggestionLength: map['suggestion_length'] ?? 0,
        analysisTime: map['analysis_time'] ?? 0.0,
        context: map['context'] ?? '',
        interactionType: map['interaction_type'] ?? 'unknown',
        wordCount: map['word_count'] ?? 0,
        appContext: map['app_context'] ?? 'unknown',
      );
    }
    
    Map<String, dynamic> toMap() {
      return {
        'id': id,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'textLength': textLength,
        'toneStatus': toneStatus,
        'suggestionAccepted': suggestionAccepted,
        'suggestionLength': suggestionLength,
        'analysisTime': analysisTime,
        'context': context,
        'interactionType': interactionType,
        'wordCount': wordCount,
        'appContext': appContext,
      };
    }
  }
  
  /// Tone analysis data model
  class ToneAnalysisData {
    final String id;
    final DateTime timestamp;
    final int textLength;
    final String textHash;
    final String tone;
    final double confidence;
    final double analysisTime;
    final String source;
    
    ToneAnalysisData({
      required this.id,
      required this.timestamp,
      required this.textLength,
      required this.textHash,
      required this.tone,
      required this.confidence,
      required this.analysisTime,
      required this.source,
    });
    
    factory ToneAnalysisData.fromMap(Map<String, dynamic> map) {
      return ToneAnalysisData(
        id: map['id'] ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch((map['timestamp'] * 1000).round()),
        textLength: map['text_length'] ?? 0,
        textHash: map['text_hash']?.toString() ?? '',
        tone: map['tone'] ?? 'neutral',
        confidence: map['confidence'] ?? 0.0,
        analysisTime: map['analysis_time'] ?? 0.0,
        source: map['source'] ?? 'unknown',
      );
    }
    
    Map<String, dynamic> toMap() {
      return {
        'id': id,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'textLength': textLength,
        'textHash': textHash,
        'tone': tone,
        'confidence': confidence,
        'analysisTime': analysisTime,
        'source': source,
      };
    }
  }
  
  /// Suggestion interaction data model
  class SuggestionData {
    final String id;
    final DateTime timestamp;
    final int suggestionLength;
    final bool accepted;
    final String context;
    final String source;
    
    SuggestionData({
      required this.id,
      required this.timestamp,
      required this.suggestionLength,
      required this.accepted,
      required this.context,
      required this.source,
    });
    
    factory SuggestionData.fromMap(Map<String, dynamic> map) {
      return SuggestionData(
        id: map['id'] ?? '',
        timestamp: DateTime.fromMillisecondsSinceEpoch((map['timestamp'] * 1000).round()),
        suggestionLength: map['suggestion_length'] ?? 0,
        accepted: map['accepted'] ?? false,
        context: map['context'] ?? '',
        source: map['source'] ?? 'unknown',
      );
    }
    
    Map<String, dynamic> toMap() {
      return {
        'id': id,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'suggestionLength': suggestionLength,
        'accepted': accepted,
        'context': context,
        'source': source,
      };
    }
  }
  
  /// Combined keyboard analytics data
  class KeyboardAnalyticsBundle {
    final List<KeyboardInteractionData> interactions;
    final List<ToneAnalysisData> toneAnalyses;
    final List<SuggestionData> suggestions;
    final List<Map<String, dynamic>> generalAnalytics;
    final Map<String, dynamic> metadata;
    
    KeyboardAnalyticsBundle({
      required this.interactions,
      required this.toneAnalyses,
      required this.suggestions,
      required this.generalAnalytics,
      required this.metadata,
    });
    
    /// Generate usage statistics from the data
    Map<String, dynamic> generateStatistics() {
      final stats = <String, dynamic>{};
      
      // Basic counts
      stats['total_interactions'] = interactions.length;
      stats['total_tone_analyses'] = toneAnalyses.length;
      stats['total_suggestions'] = suggestions.length;
      stats['total_analytics_events'] = generalAnalytics.length;
      
      // Interaction analysis
      if (interactions.isNotEmpty) {
        final suggestionAcceptanceRate = interactions
            .where((i) => i.suggestionAccepted)
            .length / interactions.length;
        stats['suggestion_acceptance_rate'] = suggestionAcceptanceRate;
        
        final averageAnalysisTime = interactions
            .map((i) => i.analysisTime)
            .reduce((a, b) => a + b) / interactions.length;
        stats['average_analysis_time'] = averageAnalysisTime;
        
        final totalWordsTyped = interactions
            .map((i) => i.wordCount)
            .reduce((a, b) => a + b);
        stats['total_words_typed'] = totalWordsTyped;
        
        // Tone distribution
        final toneDistribution = <String, int>{};
        for (final interaction in interactions) {
          toneDistribution[interaction.toneStatus] = 
              (toneDistribution[interaction.toneStatus] ?? 0) + 1;
        }
        stats['tone_distribution'] = toneDistribution;
      }
      
      // Tone analysis insights
      if (toneAnalyses.isNotEmpty) {
        final averageConfidence = toneAnalyses
            .map((t) => t.confidence)
            .reduce((a, b) => a + b) / toneAnalyses.length;
        stats['average_tone_confidence'] = averageConfidence;
        
        final toneFrequency = <String, int>{};
        for (final analysis in toneAnalyses) {
          toneFrequency[analysis.tone] = 
              (toneFrequency[analysis.tone] ?? 0) + 1;
        }
        stats['tone_frequency'] = toneFrequency;
      }
      
      // Suggestion insights
      if (suggestions.isNotEmpty) {
        final acceptanceRate = suggestions
            .where((s) => s.accepted)
            .length / suggestions.length;
        stats['suggestion_acceptance_rate'] = acceptanceRate;
        
        final contextDistribution = <String, int>{};
        for (final suggestion in suggestions) {
          contextDistribution[suggestion.context] = 
              (contextDistribution[suggestion.context] ?? 0) + 1;
        }
        stats['suggestion_context_distribution'] = contextDistribution;
      }
      
      // Time range
      final allTimestamps = [
        ...interactions.map((i) => i.timestamp),
        ...toneAnalyses.map((t) => t.timestamp),
        ...suggestions.map((s) => s.timestamp),
      ];
      
      if (allTimestamps.isNotEmpty) {
        allTimestamps.sort();
        stats['data_time_range'] = {
          'start': allTimestamps.first.toIso8601String(),
          'end': allTimestamps.last.toIso8601String(),
          'duration_hours': allTimestamps.last
              .difference(allTimestamps.first)
              .inHours,
        };
      }
      
      return stats;
    }
  }
  
  // MARK: - Main App Data Retrieval
  
  /// Sync all keyboard data when app opens (call this on app startup)
  Future<KeyboardAnalyticsBundle?> syncKeyboardData() async {
    try {
      if (!Platform.isIOS) {
        print('ℹ️ KeyboardDataSyncService: Not iOS platform, skipping sync');
        return null;
      }
      
      print('🔄 KeyboardDataSyncService: Starting data sync...');
      
      // Get all pending data from keyboard extension
      final Map<dynamic, dynamic>? rawData = 
          await _channel.invokeMethod('getAllPendingKeyboardData');
      
      if (rawData == null || rawData.isEmpty) {
        print('📭 KeyboardDataSyncService: No pending keyboard data found');
        return null;
      }
      
      // Parse the data safely
      final bundle = _parseKeyboardData(rawData.cast<String, dynamic>());
      
      print('✅ KeyboardDataSyncService: Successfully synced keyboard data');
      print('   📊 Interactions: ${bundle.interactions.length}');
      print('   🎯 Tone Analyses: ${bundle.toneAnalyses.length}');
      print('   💡 Suggestions: ${bundle.suggestions.length}');
      print('   📈 Analytics Events: ${bundle.generalAnalytics.length}');
      
      // Clear the data from keyboard storage after successful sync
      await _clearKeyboardData();
      
      return bundle;
      
    } catch (e) {
      print('⚠️ KeyboardDataSyncService: Failed to sync keyboard data: $e');
      return null;
    }
  }
  
  /// Get storage metadata without syncing data
  Future<Map<String, dynamic>?> getKeyboardStorageMetadata() async {
    try {
      if (!Platform.isIOS) return null;
      
      final Map<dynamic, dynamic>? metadata = 
          await _channel.invokeMethod('getKeyboardStorageMetadata');
      
      return metadata?.cast<String, dynamic>();
      
    } catch (e) {
      print('⚠️ KeyboardDataSyncService: Failed to get metadata: $e');
      return null;
    }
  }
  
  /// Manually clear keyboard data storage
  Future<bool> clearKeyboardDataStorage() async {
    try {
      if (!Platform.isIOS) return false;
      
      await _channel.invokeMethod('clearAllPendingKeyboardData');
      print('🗑️ KeyboardDataSyncService: Cleared keyboard data storage');
      return true;
      
    } catch (e) {
      print('⚠️ KeyboardDataSyncService: Failed to clear storage: $e');
      return false;
    }
  }
  
  // MARK: - Private Methods
  
  /// Parse raw keyboard data into structured models
  KeyboardAnalyticsBundle _parseKeyboardData(Map<String, dynamic> rawData) {
    // Parse interactions
    final interactionsData = rawData['interactions'] as List<dynamic>? ?? [];
    final interactions = interactionsData
        .cast<Map<String, dynamic>>()
        .map((data) => KeyboardInteractionData.fromMap(data))
        .toList();
    
    // Parse tone analyses
    final toneData = rawData['tone_data'] as List<dynamic>? ?? [];
    final toneAnalyses = toneData
        .cast<Map<String, dynamic>>()
        .map((data) => ToneAnalysisData.fromMap(data))
        .toList();
    
    // Parse suggestions
    final suggestionsData = rawData['suggestions'] as List<dynamic>? ?? [];
    final suggestions = suggestionsData
        .cast<Map<String, dynamic>>()
        .map((data) => SuggestionData.fromMap(data))
        .toList();
    
    // Parse general analytics
    final analyticsData = rawData['analytics'] as List<dynamic>? ?? [];
    final generalAnalytics = analyticsData.cast<Map<String, dynamic>>();
    
    // Parse metadata
    final metadata = rawData['metadata'] as Map<String, dynamic>? ?? {};
    
    return KeyboardAnalyticsBundle(
      interactions: interactions,
      toneAnalyses: toneAnalyses,
      suggestions: suggestions,
      generalAnalytics: generalAnalytics,
      metadata: metadata,
    );
  }
  
  /// Clear keyboard data after successful sync
  Future<void> _clearKeyboardData() async {
    await _channel.invokeMethod('clearAllPendingKeyboardData');
  }
  
  // MARK: - Data Export
  
  /// Export keyboard analytics to JSON for analysis
  Map<String, dynamic> exportToJson(KeyboardAnalyticsBundle bundle) {
    return {
      'export_timestamp': DateTime.now().toIso8601String(),
      'data_summary': bundle.generateStatistics(),
      'interactions': bundle.interactions.map((i) => i.toMap()).toList(),
      'tone_analyses': bundle.toneAnalyses.map((t) => t.toMap()).toList(),
      'suggestions': bundle.suggestions.map((s) => s.toMap()).toList(),
      'general_analytics': bundle.generalAnalytics,
      'metadata': bundle.metadata,
    };
  }
  
  /// Save keyboard analytics to local file
  Future<bool> saveToLocalFile(KeyboardAnalyticsBundle bundle, String filePath) async {
    try {
      final file = File(filePath);
      final jsonData = exportToJson(bundle);
      final jsonString = JsonEncoder.withIndent('  ').convert(jsonData);
      
      await file.writeAsString(jsonString);
      
      print('💾 KeyboardDataSyncService: Saved analytics to $filePath');
      return true;
      
    } catch (e) {
      print('⚠️ KeyboardDataSyncService: Failed to save file: $e');
      return false;
    }
  }
}
