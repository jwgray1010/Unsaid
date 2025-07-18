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
}
