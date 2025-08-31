import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive keyboard data model
class KeyboardAnalyticsData {
  final List<Map<String, dynamic>> interactions;
  final List<Map<String, dynamic>> toneData;
  final List<Map<String, dynamic>> suggestions;
  final List<Map<String, dynamic>> analytics;
  final Map<String, dynamic> metadata;
  final DateTime syncTimestamp;

  KeyboardAnalyticsData({
    required this.interactions,
    required this.toneData,
    required this.suggestions,
    required this.analytics,
    required this.metadata,
    required this.syncTimestamp,
  });

  factory KeyboardAnalyticsData.fromMap(Map<String, dynamic> data) {
    return KeyboardAnalyticsData(
      interactions: List<Map<String, dynamic>>.from(data['interactions'] ?? []),
      toneData: List<Map<String, dynamic>>.from(data['tone_data'] ?? []),
      suggestions: List<Map<String, dynamic>>.from(data['suggestions'] ?? []),
      analytics: List<Map<String, dynamic>>.from(data['analytics'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      syncTimestamp: DateTime.now(),
    );
  }

  /// Get total item count across all data types
  int get totalItems =>
      interactions.length +
      toneData.length +
      suggestions.length +
      analytics.length;

  /// Check if there's any data to process
  bool get hasData => totalItems > 0;

  /// Get summary for logging
  String get summary =>
      'Interactions: ${interactions.length}, Tone: ${toneData.length}, Suggestions: ${suggestions.length}, Analytics: ${analytics.length}';
}

/// Service for safely retrieving and processing keyboard extension data
/// Uses native iOS bridge to get data from SafeKeyboardDataStorage
class KeyboardDataService {
  static const MethodChannel _channel =
      MethodChannel('com.unsaid/keyboard_data_sync');

  // Singleton pattern
  static final KeyboardDataService _instance = KeyboardDataService._internal();
  factory KeyboardDataService() => _instance;
  KeyboardDataService._internal();

  // Data processing callbacks
  static const String _logTag = 'KeyboardDataService';

  /// Retrieve all pending keyboard data from native storage
  /// This should be called when the app starts or becomes active
  Future<KeyboardAnalyticsData?> retrievePendingKeyboardData() async {
    try {
      debugPrint('[$_logTag] 🔄 Retrieving pending keyboard data...');

      final Map<String, dynamic>? rawData =
          await _channel.invokeMapMethod('getAllPendingKeyboardData');

      if (rawData == null) {
        debugPrint('[$_logTag] ✅ No pending keyboard data found');
        return null;
      }

      final data = KeyboardAnalyticsData.fromMap(rawData);
      debugPrint('[$_logTag] 📥 Retrieved keyboard data: ${data.summary}');

      return data;
    } on PlatformException catch (e) {
      debugPrint(
          '[$_logTag] ❌ Platform error retrieving keyboard data: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[$_logTag] ❌ Unexpected error retrieving keyboard data: $e');
      return null;
    }
  }

  /// Get metadata about stored keyboard data without retrieving it
  Future<Map<String, dynamic>?> getKeyboardStorageMetadata() async {
    try {
      final Map<String, dynamic>? metadata =
          await _channel.invokeMapMethod('getKeyboardStorageMetadata');

      if (metadata != null) {
        debugPrint('[$_logTag] 📊 Storage metadata: ${metadata.toString()}');
      }

      return metadata;
    } on PlatformException catch (e) {
      debugPrint('[$_logTag] ❌ Error getting storage metadata: ${e.message}');
      return null;
    }
  }

  /// Clear all pending keyboard data after successful processing
  /// Call this after you've successfully processed the retrieved data
  Future<bool> clearPendingKeyboardData() async {
    try {
      debugPrint('[$_logTag] 🗑️ Clearing pending keyboard data...');

      final bool? success =
          await _channel.invokeMethod('clearAllPendingKeyboardData');

      if (success == true) {
        debugPrint('[$_logTag] ✅ Successfully cleared pending keyboard data');
        return true;
      } else {
        debugPrint('[$_logTag] ⚠️ Failed to clear pending keyboard data');
        return false;
      }
    } on PlatformException catch (e) {
      debugPrint('[$_logTag] ❌ Error clearing keyboard data: ${e.message}');
      return false;
    }
  }

  /// Process and store keyboard analytics data
  /// Override this method to customize how data is processed
  Future<void> processKeyboardData(KeyboardAnalyticsData data) async {
    debugPrint('[$_logTag] 🔄 Processing keyboard data: ${data.summary}');

    try {
      // Process interaction data
      await _processInteractionData(data.interactions);

      // Process tone analysis data
      await _processToneData(data.toneData);

      // Process suggestion data
      await _processSuggestionData(data.suggestions);

      // Process general analytics
      await _processAnalyticsData(data.analytics);

      debugPrint('[$_logTag] ✅ Successfully processed all keyboard data');
    } catch (e) {
      debugPrint('[$_logTag] ❌ Error processing keyboard data: $e');
      rethrow;
    }
  }

  /// Process keyboard interaction data
  Future<void> _processInteractionData(
      List<Map<String, dynamic>> interactions) async {
    if (interactions.isEmpty) return;

    debugPrint('[$_logTag] 📝 Processing ${interactions.length} interactions');

    for (final interaction in interactions) {
      try {
        // Extract interaction data
        final String interactionType =
            interaction['interaction_type'] ?? 'unknown';
        final String toneStatus = interaction['tone_status'] ?? 'neutral';
        final bool suggestionAccepted =
            interaction['suggestion_accepted'] ?? false;

        // Store or process interaction data as needed
        // You can integrate with your existing analytics system here
        debugPrint(
            '[$_logTag] 📊 Interaction: $interactionType, Tone: $toneStatus, Accepted: $suggestionAccepted');
      } catch (e) {
        debugPrint('[$_logTag] ⚠️ Error processing interaction: $e');
      }
    }
  }

  /// Process tone analysis data
  Future<void> _processToneData(List<Map<String, dynamic>> toneData) async {
    if (toneData.isEmpty) return;

    debugPrint('[$_logTag] 🎯 Processing ${toneData.length} tone analyses');

    for (final tone in toneData) {
      try {
        final String toneValue = tone['tone'] ?? 'neutral';
        final double confidence = tone['confidence']?.toDouble() ?? 0.0;

        // Process tone analysis data
        debugPrint(
            '[$_logTag] 🎯 Tone: $toneValue (${(confidence * 100).toStringAsFixed(1)}% confidence)');
      } catch (e) {
        debugPrint('[$_logTag] ⚠️ Error processing tone data: $e');
      }
    }
  }

  /// Process suggestion interaction data
  Future<void> _processSuggestionData(
      List<Map<String, dynamic>> suggestions) async {
    if (suggestions.isEmpty) return;

    debugPrint(
        '[$_logTag] 💡 Processing ${suggestions.length} suggestion interactions');

    for (final suggestion in suggestions) {
      try {
        final bool accepted = suggestion['accepted'] ?? false;
        final int suggestionLength = suggestion['suggestion_length'] ?? 0;

        // Process suggestion data
        debugPrint(
            '[$_logTag] 💡 Suggestion: ${accepted ? 'Accepted' : 'Rejected'} (Length: $suggestionLength)');
      } catch (e) {
        debugPrint('[$_logTag] ⚠️ Error processing suggestion data: $e');
      }
    }
  }

  /// Process general analytics data
  Future<void> _processAnalyticsData(
      List<Map<String, dynamic>> analytics) async {
    if (analytics.isEmpty) return;

    debugPrint('[$_logTag] 📈 Processing ${analytics.length} analytics events');

    for (final event in analytics) {
      try {
        final String eventName = event['event'] ?? 'unknown';

        // Process analytics event
        debugPrint('[$_logTag] 📈 Event: $eventName');
      } catch (e) {
        debugPrint('[$_logTag] ⚠️ Error processing analytics data: $e');
      }
    }
  }

  /// Get the latest API responses from shared storage
  Future<Map<String, dynamic>?> getAPIResponses() async {
    try {
      debugPrint('[$_logTag] 🔄 Getting API responses from shared storage...');

      final Map<String, dynamic>? apiData =
          await _channel.invokeMapMethod('getAPIData');

      if (apiData != null && apiData.isNotEmpty) {
        debugPrint(
            '[$_logTag] 📥 Retrieved API data: ${apiData.keys.join(', ')}');
        return apiData;
      } else {
        debugPrint('[$_logTag] ✅ No API data found in shared storage');
        return null;
      }
    } on PlatformException catch (e) {
      debugPrint('[$_logTag] ❌ Platform error getting API data: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[$_logTag] ❌ Unexpected error getting API data: $e');
      return null;
    }
  }

  /// Get user data from shared storage
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      debugPrint('[$_logTag] 🔄 Getting user data from shared storage...');

      final Map<String, dynamic>? userData =
          await _channel.invokeMapMethod('getUserData');

      if (userData != null) {
        debugPrint(
            '[$_logTag] 📥 Retrieved user data: ${userData.keys.join(', ')}');
        return userData;
      } else {
        debugPrint('[$_logTag] ✅ No user data found in shared storage');
        return null;
      }
    } on PlatformException catch (e) {
      debugPrint('[$_logTag] ❌ Platform error getting user data: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[$_logTag] ❌ Unexpected error getting user data: $e');
      return null;
    }
  }

  /// Test API connectivity and data flow
  Future<bool> testAPIConnection() async {
    debugPrint('[$_logTag] 🧪 Testing API connection and data flow...');

    try {
      // 1. Check for user data
      final userData = await getUserData();
      if (userData != null) {
        debugPrint('[$_logTag] ✅ User data available: ${userData['user_id']}');
      }

      // 2. Check for API responses
      final apiData = await getAPIResponses();
      if (apiData != null) {
        debugPrint('[$_logTag] ✅ API data available');

        // Process latest suggestion
        if (apiData['latest_suggestion'] != null) {
          final suggestion =
              apiData['latest_suggestion'] as Map<String, dynamic>;
          debugPrint(
              '[$_logTag] 📥 Latest suggestion from API: ${suggestion['response']}');
        }

        // Process latest trial status
        if (apiData['latest_trial_status'] != null) {
          final trialStatus =
              apiData['latest_trial_status'] as Map<String, dynamic>;
          debugPrint(
              '[$_logTag] 📥 Latest trial status from API: ${trialStatus['response']}');
        }

        return true;
      } else {
        debugPrint(
            '[$_logTag] ⚠️ No API data found - keyboard extension may not have called APIs yet');
        return false;
      }
    } catch (e) {
      debugPrint('[$_logTag] ❌ API connection test failed: $e');
      return false;
    }
  }

  /// Complete data sync workflow
  /// Call this when the app starts or becomes active
  Future<bool> performDataSync() async {
    try {
      debugPrint('[$_logTag] 🔄 Starting keyboard data sync...');

      // 1. Test API connection first
      await testAPIConnection();

      // 2. Check if there's data to sync
      final metadata = await getKeyboardStorageMetadata();
      if (metadata?['has_pending_data'] != true) {
        debugPrint('[$_logTag] ✅ No pending keyboard data to sync');
        return true;
      }

      // 3. Retrieve pending data
      final keyboardData = await retrievePendingKeyboardData();
      if (keyboardData == null || !keyboardData.hasData) {
        debugPrint('[$_logTag] ✅ No keyboard data retrieved');
        return true;
      }

      // 4. Process the data
      await processKeyboardData(keyboardData);

      // 5. Clear the data after successful processing
      final cleared = await clearPendingKeyboardData();
      if (!cleared) {
        debugPrint(
            '[$_logTag] ⚠️ Failed to clear keyboard data after processing');
        return false;
      }

      debugPrint('[$_logTag] ✅ Keyboard data sync completed successfully');
      return true;
    } catch (e) {
      debugPrint('[$_logTag] ❌ Keyboard data sync failed: $e');
      return false;
    }
  }
}
