import 'dart:io';
import 'package:flutter/services.dart';

class PersonalityDataManager {
  static PersonalityDataManager? _instance;
  static PersonalityDataManager get shared {
    _instance ??= PersonalityDataManager._();
    return _instance!;
  }
  
  PersonalityDataManager._();
  
  static const MethodChannel _channel = MethodChannel('com.unsaid/personality_data');
  
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
}
