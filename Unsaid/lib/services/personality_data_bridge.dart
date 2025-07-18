import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Service for sharing personality data with iOS keyboard extension
/// Bridges Flutter personality data to iOS SharedUserDefaults for keyboard access
class PersonalityDataBridge {
  static const MethodChannel _channel = MethodChannel('com.unsaid/personality_data');
  
  /// Store personality test results in iOS UserDefaults for keyboard access
  /// - Parameter results: Map containing personality test results
  static Future<bool> storePersonalityData(Map<String, dynamic> results) async {
    try {
      final bool success = await _channel.invokeMethod('storePersonalityData', results);
      if (kDebugMode) {
        print('✅ PersonalityDataBridge: Stored personality data - success: $success');
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ PersonalityDataBridge: Error storing personality data: $e');
      }
      return false;
    }
  }
  
  /// Get personality data from iOS UserDefaults
  /// - Returns: Map containing personality data, or empty map if not available
  static Future<Map<String, dynamic>> getPersonalityData() async {
    try {
      final Map<dynamic, dynamic> data = await _channel.invokeMethod('getPersonalityData');
      final Map<String, dynamic> typedData = Map<String, dynamic>.from(data);
      if (kDebugMode) {
        print('✅ PersonalityDataBridge: Retrieved personality data with ${typedData.keys.length} keys');
      }
      return typedData;
    } catch (e) {
      if (kDebugMode) {
        print('❌ PersonalityDataBridge: Error getting personality data: $e');
      }
      return <String, dynamic>{};
    }
  }
  
  /// Check if personality test is complete in iOS storage
  /// - Returns: Boolean indicating if personality test is complete
  static Future<bool> isPersonalityTestComplete() async {
    try {
      final bool isComplete = await _channel.invokeMethod('isPersonalityTestComplete');
      if (kDebugMode) {
        print('✅ PersonalityDataBridge: Personality test complete: $isComplete');
      }
      return isComplete;
    } catch (e) {
      if (kDebugMode) {
        print('❌ PersonalityDataBridge: Error checking personality test completion: $e');
      }
      return false;
    }
  }
  
  /// Clear all personality data from iOS storage
  /// - Returns: Boolean indicating if clear was successful
  static Future<bool> clearPersonalityData() async {
    try {
      final bool success = await _channel.invokeMethod('clearPersonalityData');
      if (kDebugMode) {
        print('✅ PersonalityDataBridge: Cleared personality data - success: $success');
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ PersonalityDataBridge: Error clearing personality data: $e');
      }
      return false;
    }
  }
  
  /// Debug: Print personality data from iOS storage
  /// - Returns: Boolean indicating if debug was successful
  static Future<bool> debugPersonalityData() async {
    try {
      final bool success = await _channel.invokeMethod('debugPersonalityData');
      if (kDebugMode) {
        print('✅ PersonalityDataBridge: Debug print completed - success: $success');
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ PersonalityDataBridge: Error debugging personality data: $e');
      }
      return false;
    }
  }
}
