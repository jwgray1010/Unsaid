import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

/// Unsaid Keyboard Extension
/// Provides platform channel integration for custom keyboard features,
/// including advanced analysis and real-time feedback.
class UnsaidKeyboardExtension {
  static const MethodChannel _channel = MethodChannel('unsaid_keyboard');

  /// Checks if the custom keyboard is available/installed.
  static Future<bool> isKeyboardAvailable() async {
    try {
      final bool? result = await _channel.invokeMethod('isKeyboardAvailable');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error checking keyboard availability: ${e.message}');
      return false;
    }
  }

  /// Enables or disables the custom keyboard.
  static Future<bool> enableKeyboard(bool enable) async {
    try {
      final bool? result = await _channel.invokeMethod('enableKeyboard', {
        'enable': enable,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error enabling keyboard: ${e.message}');
      return false;
    }
  }

  /// Opens the device's keyboard settings.
  static Future<void> openKeyboardSettings() async {
    try {
      if (Platform.isIOS) {
        // Try to open directly to keyboard settings on iOS
        const settingsUrl = 'app-settings:';
        if (await canLaunchUrl(Uri.parse(settingsUrl))) {
          await launchUrl(Uri.parse(settingsUrl));
        } else {
          // Fallback: use platform channel
          await _channel.invokeMethod('openKeyboardSettings');
        }
      } else {
        // For Android, use platform channel
        await _channel.invokeMethod('openKeyboardSettings');
      }
    } on PlatformException catch (e) {
      print('Error opening keyboard settings: ${e.message}');
      // Final fallback: try to open general settings
      try {
        if (Platform.isIOS) {
          await launchUrl(Uri.parse('app-settings:'));
        }
      } catch (e2) {
        print('Could not open settings: $e2');
      }
    }
  }

  /// Sends tone analysis results to the keyboard for real-time feedback.
  static Future<void> sendToneAnalysisPayload(
    Map<String, dynamic> payload,
  ) async {
    try {
      await _channel.invokeMethod('sendToneAnalysis', payload);
    } on PlatformException catch (e) {
      print('Error sending tone analysis: ${e.message}');
    }
  }

  /// Real-time tone analysis for keyboard co-pilot feature
  static Future<void> analyzeTextForKeyboard(
    String text, {
    String? attachmentStyle,
    String? relationshipContext,
  }) async {
    try {
      // Quick tone analysis
      final toneResult = _performQuickToneAnalysis(text);
      
      // Enhanced payload with attachment style awareness
      final payload = {
        'text': text,
        'toneStatus': toneResult['status'],
        'toneColor': toneResult['color'],
        'suggestions': toneResult['suggestions'],
        'autoFixText': toneResult['autoFix'],
        'attachmentStyle': attachmentStyle ?? 'unknown',
        'relationshipContext': relationshipContext ?? 'general',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _channel.invokeMethod('sendRealtimeToneAnalysis', payload);
    } on PlatformException catch (e) {
      print('Error sending realtime tone analysis: ${e.message}');
    }
  }

  /// Quick tone analysis (simplified version of advanced analysis)
  static Map<String, dynamic> _performQuickToneAnalysis(String text) {
    final lowercaseText = text.toLowerCase();
    
    // Alert indicators (red)
    final alertWords = [
      'stupid', 'ridiculous', 'hate', 'terrible', 'awful', 'worst', 
      'pathetic', 'useless', 'abandoning', 'rejecting', 'ignoring'
    ];
    
    // Caution indicators (yellow)
    final cautionWords = [
      'should', 'must', 'need to', 'have to', 'immediately', 'urgent', 
      'wrong', 'prove', 'guarantee', 'always', 'never'
    ];
    
    // Positive indicators (green)
    final positiveWords = [
      'thanks', 'appreciate', 'grateful', 'please', 'understand', 
      'help', 'support', 'i feel', 'i need', 'can we'
    ];
    
    String status = 'neutral';
    String color = 'white';
    List<String> suggestions = [];
    String autoFix = text;
    
    // Determine tone status
    if (alertWords.any((word) => lowercaseText.contains(word))) {
      status = 'alert';
      color = 'red';
      suggestions = [
        'This message might feel hurtful',
        'Consider using "I" statements',
        'Try expressing your feelings instead'
      ];
      autoFix = _generateAutoFix(text, 'alert');
    } else if (cautionWords.any((word) => lowercaseText.contains(word))) {
      status = 'caution';
      color = 'yellow';
      suggestions = [
        'This could come across as demanding',
        'Try softening with "please"',
        'Consider the other person\'s perspective'
      ];
      autoFix = _generateAutoFix(text, 'caution');
    } else if (positiveWords.any((word) => lowercaseText.contains(word))) {
      status = 'clear';
      color = 'green';
      suggestions = [
        'Great! This sounds supportive',
        'Your tone is clear and kind'
      ];
    } else {
      suggestions = [
        'Consider adding warmth to your message',
        'How might the other person receive this?'
      ];
    }
    
    return {
      'status': status,
      'color': color,
      'suggestions': suggestions,
      'autoFix': autoFix,
    };
  }

  /// Generate AI co-pilot auto-fix suggestions
  static String _generateAutoFix(String text, String toneStatus) {
    String improved = text;
    
    if (toneStatus == 'alert') {
      // Replace harsh words with softer alternatives
      final replacements = {
        'stupid': 'unclear',
        'ridiculous': 'unusual',
        'hate': 'don\'t like',
        'terrible': 'challenging',
        'awful': 'difficult',
        'worst': 'least preferred',
        'pathetic': 'concerning',
        'useless': 'not helpful',
      };
      
      replacements.forEach((harsh, gentle) {
        improved = improved.replaceAll(RegExp(harsh, caseSensitive: false), gentle);
      });
      
      // Add "I feel" if not present
      if (!improved.toLowerCase().contains('i feel') && 
          !improved.toLowerCase().contains('i think')) {
        improved = 'I feel like $improved';
      }
    } else if (toneStatus == 'caution') {
      // Soften demanding language
      final replacements = {
        'must': 'could you please',
        'need to': 'would you mind',
        'have to': 'it would help if you could',
        'should': 'it might be good to',
        'immediately': 'when you have a chance',
        'urgent': 'important',
      };
      
      replacements.forEach((demanding, polite) {
        improved = improved.replaceAll(RegExp(demanding, caseSensitive: false), polite);
      });
      
      // Add please if missing
      if (!improved.toLowerCase().contains('please') && 
          !improved.toLowerCase().contains('thank')) {
        improved = '$improved please';
      }
    }
    
    return improved;
  }

  /// Sends co-parenting analysis results to the keyboard.
  static Future<void> sendCoParentingAnalysis(
    String text,
    Map<String, dynamic> coParentingAnalysis,
  ) async {
    try {
      await _channel.invokeMethod('sendCoParentingAnalysis', {
        'text': text,
        'coParentingAnalysis': coParentingAnalysis,
      });
    } on PlatformException catch (e) {
      print('Error sending co-parenting analysis: ${e.message}');
    }
  }

  /// Sends child development analysis results to the keyboard.
  static Future<void> sendChildDevelopmentAnalysis(
    String text,
    Map<String, dynamic> childDevAnalysis,
  ) async {
    try {
      await _channel.invokeMethod('sendChildDevelopmentAnalysis', {
        'text': text,
        'childDevAnalysis': childDevAnalysis,
      });
    } on PlatformException catch (e) {
      print('Error sending child development analysis: ${e.message}');
    }
  }

  /// Sends emotional intelligence coaching results to the keyboard.
  static Future<void> sendEQCoaching(
    String text,
    Map<String, dynamic> eqCoaching,
  ) async {
    try {
      await _channel.invokeMethod('sendEQCoaching', {
        'text': text,
        'eqCoaching': eqCoaching,
      });
    } on PlatformException catch (e) {
      print('Error sending EQ coaching: ${e.message}');
    }
  }

  /// Gets the current keyboard status (enabled, permissions, etc.).
  static Future<Map<String, dynamic>> getKeyboardStatus() async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
        'getKeyboardStatus',
      );
      return Map<String, dynamic>.from(result ?? {});
    } on PlatformException catch (e) {
      print('Error getting keyboard status: ${e.message}');
      return {};
    }
  }

  /// Updates keyboard settings.
  static Future<bool> updateKeyboardSettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      final bool? result = await _channel.invokeMethod(
        'updateKeyboardSettings',
        settings,
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error updating keyboard settings: ${e.message}');
      return false;
    }
  }

  /// Processes text input from the keyboard (e.g., for real-time suggestions).
  static Future<String> processTextInput(String text) async {
    try {
      // Automatically analyze text for tone when processing input
      await analyzeTextForKeyboard(text);
      
      final String? result = await _channel.invokeMethod('processTextInput', {
        'text': text,
      });
      return result ?? text;
    } on PlatformException catch (e) {
      print('Error processing text input: ${e.message}');
      return text;
    }
  }

  /// Enhanced text processing with attachment style awareness
  static Future<String> processTextWithContext(
    String text, {
    String? attachmentStyle,
    String? relationshipContext,
    String? partnerAttachmentStyle,
  }) async {
    try {
      // Perform comprehensive analysis
      await analyzeTextForKeyboard(
        text,
        attachmentStyle: attachmentStyle,
        relationshipContext: relationshipContext,
      );
      
      // Enhanced payload with full context
      final payload = {
        'text': text,
        'attachmentStyle': attachmentStyle ?? 'unknown',
        'relationshipContext': relationshipContext ?? 'general',
        'partnerAttachmentStyle': partnerAttachmentStyle ?? 'unknown',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      final String? result = await _channel.invokeMethod('processTextWithContext', payload);
      return result ?? text;
    } on PlatformException catch (e) {
      print('Error processing text with context: ${e.message}');
      return text;
    }
  }

  /// Start real-time keyboard monitoring
  static Future<void> startKeyboardMonitoring({
    String? userAttachmentStyle,
    String? relationshipContext,
  }) async {
    try {
      await _channel.invokeMethod('startKeyboardMonitoring', {
        'userAttachmentStyle': userAttachmentStyle ?? 'unknown',
        'relationshipContext': relationshipContext ?? 'general',
      });
    } on PlatformException catch (e) {
      print('Error starting keyboard monitoring: ${e.message}');
    }
  }

  /// Stop real-time keyboard monitoring
  static Future<void> stopKeyboardMonitoring() async {
    try {
      await _channel.invokeMethod('stopKeyboardMonitoring');
    } on PlatformException catch (e) {
      print('Error stopping keyboard monitoring: ${e.message}');
    }
  }

  /// Checks if the user has enabled the keyboard in system settings.
  static Future<bool> isKeyboardEnabled() async {
    try {
      final bool? result = await _channel.invokeMethod('isKeyboardEnabled');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error checking if keyboard is enabled: ${e.message}');
      return false;
    }
  }

  /// Requests keyboard permissions from the user.
  static Future<bool> requestKeyboardPermissions() async {
    try {
      final bool? result = await _channel.invokeMethod(
        'requestKeyboardPermissions',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error requesting keyboard permissions: ${e.message}');
      return false;
    }
  }
}

/// Accessibility/UX Note:
/// When surfacing keyboard status or permissions in the UI,
/// use plain language and semantic labels for screen readers.
