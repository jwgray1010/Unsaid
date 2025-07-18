import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io' show Platform;

/// Swift Keyboard Data Bridge
/// Reads real-time data from the Swift keyboard extension using SharedPreferences
/// and platform channels for seamless integration
class SwiftKeyboardDataBridge {
  static const MethodChannel _channel = MethodChannel('com.unsaid.keyboard_data');
  
  // Cached data from Swift keyboard extension
  static Map<String, dynamic>? _cachedKeyboardData;
  static DateTime? _lastDataFetch;
  
  /// Read keyboard events from Swift extension
  static Future<List<Map<String, dynamic>>> getKeyboardEvents() async {
    try {
      // On iOS, use platform channel to read from app group UserDefaults
      if (Platform.isIOS) {
        final String? jsonData = await _channel.invokeMethod('getKeyboardEvents');
        if (jsonData != null) {
          final List<dynamic> events = json.decode(jsonData);
          return events.cast<Map<String, dynamic>>();
        }
      }
      
      // Fallback to SharedPreferences for cross-platform compatibility
      final prefs = await SharedPreferences.getInstance();
      final String? eventsJson = prefs.getString('keyboard_events');
      if (eventsJson != null) {
        final List<dynamic> events = json.decode(eventsJson);
        return events.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      print('Error reading keyboard events: $e');
      return [];
    }
  }
  
  /// Read user profile data from Swift extension
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (Platform.isIOS) {
        final String? jsonData = await _channel.invokeMethod('getUserProfile');
        if (jsonData != null) {
          return json.decode(jsonData);
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      final String? profileJson = prefs.getString('user_profile');
      if (profileJson != null) {
        return json.decode(profileJson);
      }
      
      return null;
    } catch (e) {
      print('Error reading user profile: $e');
      return null;
    }
  }
  
  /// Read current analysis data from Swift extension
  static Future<Map<String, dynamic>?> getCurrentAnalysis() async {
    try {
      if (Platform.isIOS) {
        final String? jsonData = await _channel.invokeMethod('getCurrentAnalysis');
        if (jsonData != null) {
          return json.decode(jsonData);
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      final String? analysisJson = prefs.getString('current_analysis');
      if (analysisJson != null) {
        return json.decode(analysisJson);
      }
      
      return null;
    } catch (e) {
      print('Error reading current analysis: $e');
      return null;
    }
  }
  
  /// Read session analytics from Swift extension
  static Future<Map<String, dynamic>?> getSessionAnalytics() async {
    try {
      if (Platform.isIOS) {
        final String? jsonData = await _channel.invokeMethod('getSessionAnalytics');
        if (jsonData != null) {
          return json.decode(jsonData);
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      final String? analyticsJson = prefs.getString('session_analytics');
      if (analyticsJson != null) {
        return json.decode(analyticsJson);
      }
      
      return null;
    } catch (e) {
      print('Error reading session analytics: $e');
      return null;
    }
  }
  
  /// Read suggestion acceptance analytics from Swift extension
  static Future<Map<String, dynamic>?> getSuggestionAcceptanceAnalytics() async {
    try {
      if (Platform.isIOS) {
        final String? jsonData = await _channel.invokeMethod('getSuggestionAcceptanceAnalytics');
        if (jsonData != null) {
          return json.decode(jsonData);
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      final String? analyticsJson = prefs.getString('suggestion_acceptance_analytics');
      if (analyticsJson != null) {
        return json.decode(analyticsJson);
      }
      
      return null;
    } catch (e) {
      print('Error reading suggestion acceptance analytics: $e');
      return null;
    }
  }
  
  /// Read keyboard coaching settings from Swift extension
  static Future<Map<String, dynamic>?> getKeyboardCoachingSettings() async {
    try {
      if (Platform.isIOS) {
        final String? jsonData = await _channel.invokeMethod('getKeyboardCoachingSettings');
        if (jsonData != null) {
          return json.decode(jsonData);
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      final String? settingsJson = prefs.getString('keyboard_coaching_settings');
      if (settingsJson != null) {
        return json.decode(settingsJson);
      }
      
      return null;
    } catch (e) {
      print('Error reading keyboard coaching settings: $e');
      return null;
    }
  }
  
  /// Get comprehensive keyboard data for dashboards
  static Future<Map<String, dynamic>> getComprehensiveKeyboardData() async {
    // Use cached data if it's recent (within 5 seconds)
    if (_cachedKeyboardData != null && 
        _lastDataFetch != null && 
        DateTime.now().difference(_lastDataFetch!).inSeconds < 5) {
      return _cachedKeyboardData!;
    }
    
    try {
      final results = await Future.wait([
        getKeyboardEvents(),
        getUserProfile(),
        getCurrentAnalysis(),
        getSessionAnalytics(),
        getSuggestionAcceptanceAnalytics(),
        getKeyboardCoachingSettings(),
      ]);
      
      _cachedKeyboardData = {
        'keyboard_events': results[0],
        'user_profile': results[1],
        'current_analysis': results[2],
        'session_analytics': results[3],
        'suggestion_acceptance_analytics': results[4],
        'keyboard_coaching_settings': results[5],
        'last_updated': DateTime.now().toIso8601String(),
      };
      
      _lastDataFetch = DateTime.now();
      return _cachedKeyboardData!;
    } catch (e) {
      print('Error getting comprehensive keyboard data: $e');
      return {
        'keyboard_events': <Map<String, dynamic>>[],
        'user_profile': null,
        'current_analysis': null,
        'session_analytics': null,
        'suggestion_acceptance_analytics': null,
        'keyboard_coaching_settings': null,
        'last_updated': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }
  
  /// Clear cached data to force fresh read
  static void clearCache() {
    _cachedKeyboardData = null;
    _lastDataFetch = null;
  }
  
  /// Convert Swift ToneStatus to Flutter-compatible string
  static String mapToneStatus(String? swiftToneStatus) {
    switch (swiftToneStatus) {
      case 'clear':
        return 'positive';
      case 'caution':
        return 'neutral';
      case 'alert':
        return 'negative';
      case 'neutral':
        return 'neutral';
      case 'analyzing':
        return 'analyzing';
      default:
        return 'unknown';
    }
  }
  
  /// Convert Swift AttachmentStyle to Flutter-compatible string
  static String mapAttachmentStyle(String? swiftAttachmentStyle) {
    switch (swiftAttachmentStyle) {
      case 'secure':
        return 'secure';
      case 'anxious':
        return 'anxious';
      case 'avoidant':
        return 'avoidant';
      case 'disorganized':
        return 'disorganized';
      case 'unknown':
        return 'unknown';
      default:
        return 'unknown';
    }
  }
}
