import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'admin_service.dart';
import 'secure_storage_service.dart';
import 'personality_data_bridge.dart';
import '../data/randomized_personality_questions.dart';

/// Service for tracking personality test completion
class PersonalityTestService {
  static const String _testCompletedKey = 'personality_test_completed';
  static const String _testResultsKey = 'personality_test_results';

  /// Check if the personality test has been completed
  static Future<bool> isTestCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Admin bypass: admins can always retake the test
      if (AdminService.instance.canRetakePersonalityTest) {
        AdminService.instance.logAdminAction(
            'Checking personality test completion (admin can retake)');
        return false; // Always allow admin to retake
      }

      return prefs.getBool(_testCompletedKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking test completion: $e');
      }
      return false;
    }
  }

  /// Mark the personality test as completed
  static Future<void> markTestCompleted(List<String> answers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_testCompletedKey, true);
      await prefs.setStringList(_testResultsKey, answers);

      // Process and store personality results for keyboard access
      await _processAndStorePersonalityResults(answers);

      if (AdminService.instance.isCurrentUserAdmin) {
        AdminService.instance.logAdminAction('Completed personality test');
      }

      if (kDebugMode) {
        print('✅ Personality test marked as completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking test complete: $e');
      }
    }
  }

  /// Process personality test answers and store results for keyboard access
  static Future<void> _processAndStorePersonalityResults(
      List<String> answers) async {
    try {
      // Get the randomized questions to match answers
      final questions = RandomizedPersonalityTest.getRandomizedQuestions();

      // Count responses by type
      final Map<String, int> counts = {'A': 0, 'B': 0, 'C': 0, 'D': 0};

      for (int i = 0; i < answers.length && i < questions.length; i++) {
        final answer = answers[i];
        final question = questions[i];

        // Find which option was selected by comparing the answer text
        final optionIndex =
            question.options.indexWhere((option) => option.text == answer);
        if (optionIndex != -1) {
          final type = question.options[optionIndex].type;
          if (type != null) {
            counts[type] = (counts[type] ?? 0) + 1;
          }
        }
      }

      // Find dominant type
      String dominantType = 'B'; // Default to secure
      int maxCount = 0;
      counts.forEach((k, v) {
        if (v > maxCount) {
          dominantType = k;
          maxCount = v;
        }
      });

      // Mapping from personality types to attachment styles for iOS keyboard
      const attachmentStyleMapping = {
        'A': 'anxious',
        'B': 'secure',
        'C': 'avoidant',
        'D': 'disorganized',
      };

      const typeLabels = {
        'A': 'Anxious Attachment',
        'B': 'Secure Attachment',
        'C': 'Dismissive Avoidant',
        'D': 'Disorganized/Fearful Avoidant',
      };

      // Get attachment style for iOS keyboard
      final attachmentStyle = attachmentStyleMapping[dominantType] ?? 'secure';

      // Determine communication style (simplified logic)
      final commStyle = _getDominantCommStyle(counts);

      // Store processed results
      final storage = SecureStorageService();
      await storage.storePersonalityTestResults({
        'answers': answers,
        'communication_answers': <String>[], // Empty for now
        'counts': counts,
        'dominant_type': dominantType,
        'dominant_type_label': typeLabels[dominantType] ?? 'Unknown',
        'attachment_style': attachmentStyle,
        'communication_style': commStyle,
        'communication_style_label': _getCommStyleLabel(commStyle),
        'test_completed_at': DateTime.now().toIso8601String(),
      });

      // Trigger iOS-side storage and debug output
      try {
        final personalityData = {
          'attachment_style': attachmentStyle,
          'communication_style': commStyle,
          'dominant_type': dominantType,
          'test_completed_at': DateTime.now().toIso8601String(),
        };

        await PersonalityDataBridge.storePersonalityData(personalityData);
        await PersonalityDataBridge.debugPersonalityData();

        if (kDebugMode) {
          print('✅ iOS personality data storage triggered');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error triggering iOS personality data storage: $e');
        }
      }

      if (kDebugMode) {
        print('✅ Personality results processed and stored for keyboard access');
        print(
            '   - Dominant type: $dominantType (${typeLabels[dominantType]})');
        print('   - Attachment style: $attachmentStyle');
        print('   - Communication style: $commStyle');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error processing personality results: $e');
      }
    }
  }

  /// Get dominant communication style based on personality type counts
  static String _getDominantCommStyle(Map<String, int> counts) {
    // Simplified logic - in a real app, this would be more sophisticated
    final total = counts.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return 'assertive';

    final secureRatio = (counts['B'] ?? 0) / total;
    final anxiousRatio = (counts['A'] ?? 0) / total;
    final avoidantRatio = (counts['C'] ?? 0) / total;

    if (secureRatio > 0.5) return 'assertive';
    if (anxiousRatio > 0.4) return 'passive';
    if (avoidantRatio > 0.4) return 'aggressive';
    return 'assertive';
  }

  /// Get communication style label
  static String _getCommStyleLabel(String style) {
    const labels = {
      'assertive': 'Assertive',
      'passive': 'Passive',
      'aggressive': 'Aggressive',
      'passive_aggressive': 'Passive-Aggressive',
    };
    return labels[style] ?? 'Assertive';
  }

  /// Get stored personality test results
  static Future<List<String>?> getTestResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_testResultsKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting test results: $e');
      }
      return null;
    }
  }

  /// Reset test completion (for testing purposes only)
  static Future<void> resetTest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_testCompletedKey);
      await prefs.remove(_testResultsKey);
      if (kDebugMode) {
        print('🔄 Personality test reset');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting test: $e');
      }
    }
  }
}
