import 'package:flutter/services.dart';

class KeyboardDetectionService {
  static const MethodChannel _channel = MethodChannel('unsaid.keyboard.detection');

  /// Check if the Unsaid Keyboard extension is enabled
  static Future<bool> isKeyboardEnabled() async {
    try {
      final bool isEnabled = await _channel.invokeMethod('isKeyboardEnabled');
      return isEnabled;
    } catch (e) {
      print('Error checking keyboard status: $e');
      return false;
    }
  }

  /// Open iOS Settings to enable keyboard
  static Future<void> openKeyboardSettings() async {
    try {
      await _channel.invokeMethod('openKeyboardSettings');
    } catch (e) {
      print('Error opening keyboard settings: $e');
      // Fallback: try to open general iOS settings
      await _openGeneralSettings();
    }
  }

  /// Fallback to open general iOS settings
  static Future<void> _openGeneralSettings() async {
    try {
      await _channel.invokeMethod('openGeneralSettings');
    } catch (e) {
      print('Error opening general settings: $e');
    }
  }

  /// Check keyboard status and guide user to enable if needed
  static Future<bool> checkAndGuideSetup() async {
    final isEnabled = await isKeyboardEnabled();
    
    if (!isEnabled) {
      // The UI will handle showing instructions
      // This method just returns the status
    }
    
    return isEnabled;
  }

  /// Monitor keyboard status changes (when app returns from background)
  static void startMonitoring(Function(bool) onStatusChange) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'keyboardStatusChanged') {
        final bool isEnabled = call.arguments['enabled'] ?? false;
        onStatusChange(isEnabled);
      }
    });
  }

  /// Request the iOS side to start monitoring
  static Future<void> enableStatusMonitoring() async {
    try {
      await _channel.invokeMethod('startMonitoring');
    } catch (e) {
      print('Error starting keyboard monitoring: $e');
    }
  }

  /// Stop monitoring keyboard status
  static Future<void> stopStatusMonitoring() async {
    try {
      await _channel.invokeMethod('stopMonitoring');
    } catch (e) {
      print('Error stopping keyboard monitoring: $e');
    }
  }
}
