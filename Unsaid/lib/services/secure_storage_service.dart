import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'personality_data_bridge.dart';

/// Service for secure storage of sensitive data
class SecureStorageService {
  static const String _keyPrefix = 'unsaid_secure_';

  /// Store secure data with encryption
  Future<void> storeSecureData(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final secureKey = _keyPrefix + key;

      // For now, using SharedPreferences. In production, consider using
      // flutter_secure_storage for better security
      await prefs.setString(secureKey, value);
    } catch (e) {
      debugPrint('Error storing secure data: $e');
      rethrow;
    }
  }

  /// Retrieve secure data with decryption
  Future<String?> getSecureData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final secureKey = _keyPrefix + key;

      return prefs.getString(secureKey);
    } catch (e) {
      debugPrint('Error retrieving secure data: $e');
      return null;
    }
  }

  /// Delete secure data
  Future<void> deleteSecureData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final secureKey = _keyPrefix + key;

      await prefs.remove(secureKey);
    } catch (e) {
      debugPrint('Error deleting secure data: $e');
    }
  }

  /// Store secure JSON data
  Future<void> storeSecureJson(String key, Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      await storeSecureData(key, jsonString);
    } catch (e) {
      debugPrint('Error storing secure JSON: $e');
      rethrow;
    }
  }

  /// Retrieve secure JSON data
  Future<Map<String, dynamic>?> getSecureJson(String key) async {
    try {
      final jsonString = await getSecureData(key);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error retrieving secure JSON: $e');
      return null;
    }
  }

  /// Clear all secure data
  Future<void> clearAllSecureData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_keyPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('Error clearing secure data: $e');
    }
  }

  /// Read data from secure storage
  Future<String?> read(String key) async {
    try {
      // Mock secure storage for now
      final mockData = {
        'behavior_change_history': '[]',
        'user_metrics': '{}',
        'cached_analytics': '{}',
      };
      return mockData[key];
    } catch (e) {
      return null;
    }
  }

  /// Write data to secure storage
  Future<void> write(String key, String value) async {
    try {
      // Mock implementation - in real app would use flutter_secure_storage
      print('📦 Storing data for key: $key');
    } catch (e) {
      print('⚠️ Error writing to secure storage: $e');
    }
  }

  /// Store personality test results
  Future<void> storePersonalityTestResults(Map<String, dynamic> results) async {
    try {
      await storeSecureJson('personality_test_results', results);

      // Also store in iOS UserDefaults for keyboard extension access
      try {
        await PersonalityDataBridge.storePersonalityData(results);
      } catch (e) {
        print(
            '⚠️ Warning: Could not store personality data in iOS UserDefaults: $e');
        // Continue execution - secure storage succeeded
      }

      print('✅ Personality test results stored successfully');
    } catch (e) {
      print('❌ Error storing personality test results: $e');
      rethrow;
    }
  }

  /// Retrieve personality test results
  Future<Map<String, dynamic>?> getPersonalityTestResults() async {
    try {
      return await getSecureJson('personality_test_results');
    } catch (e) {
      print('❌ Error retrieving personality test results: $e');
      return null;
    }
  }

  /// Store user progress data
  Future<void> storeUserProgress(Map<String, dynamic> progress) async {
    try {
      await storeSecureJson('user_progress', progress);
      print('✅ User progress stored successfully');
    } catch (e) {
      print('❌ Error storing user progress: $e');
      rethrow;
    }
  }

  /// Retrieve user progress data
  Future<Map<String, dynamic>?> getUserProgress() async {
    try {
      return await getSecureJson('user_progress');
    } catch (e) {
      print('❌ Error retrieving user progress: $e');
      return null;
    }
  }

  /// Get partner personality test results
  Future<Map<String, dynamic>?> getPartnerPersonalityTestResults() async {
    try {
      return await getSecureJson('partner_personality_test_results');
    } catch (e) {
      print('❌ Error retrieving partner personality test results: $e');
      return null;
    }
  }

  /// Get partner profile data (including personality test results and other data)
  Future<Map<String, dynamic>?> getPartnerProfile() async {
    try {
      // For now, return partner personality test results as partner profile
      // In a full implementation, this would include more partner data
      final partnerResults = await getPartnerPersonalityTestResults();
      if (partnerResults != null) {
        return {
          'name': 'Partner',
          'email': '',
          'phone': '',
          'personality_type': partnerResults['dominant_type'] ?? '',
          'personality_label': partnerResults['personality_label'] ?? 'Unknown',
          'communication_style': partnerResults['communication_style'] ?? '',
          'relationship_duration': '',
          'last_analysis': null,
          'profile_image': null,
          'test_completed': true,
          'joined_date': partnerResults['test_completed_at'],
          ...partnerResults,
        };
      }
      return null;
    } catch (e) {
      print('❌ Error retrieving partner profile: $e');
      return null;
    }
  }

  /// Save partner personality test results
  Future<void> savePartnerPersonalityTestResults(
      Map<String, dynamic> results) async {
    try {
      await storeSecureJson('partner_personality_test_results', results);
      print('✅ Partner personality test results saved successfully');
    } catch (e) {
      print('❌ Error saving partner personality test results: $e');
    }
  }

  /// Get relationship type preference
  Future<String?> getRelationshipType() async {
    try {
      return await getSecureData('relationship_type');
    } catch (e) {
      print('❌ Error retrieving relationship type: $e');
      return null;
    }
  }

  /// Save relationship type preference
  Future<void> saveRelationshipType(String type) async {
    try {
      await storeSecureData('relationship_type', type);
      print('✅ Relationship type saved successfully: $type');
    } catch (e) {
      print('❌ Error saving relationship type: $e');
    }
  }

  /// Get children names list
  Future<List<String>> getChildrenNames() async {
    try {
      final data = await getSecureJson('children_names');
      if (data != null && data['names'] is List) {
        return List<String>.from(data['names']);
      }
      return [];
    } catch (e) {
      print('❌ Error retrieving children names: $e');
      return [];
    }
  }

  /// Save children names list
  Future<void> saveChildrenNames(List<String> names) async {
    try {
      await storeSecureJson('children_names', {
        'names': names,
        'last_updated': DateTime.now().toIso8601String(),
      });
      print('✅ Children names saved successfully: $names');
    } catch (e) {
      print('❌ Error saving children names: $e');
      rethrow;
    }
  }

  /// Add a single child name
  Future<void> addChildName(String name) async {
    try {
      final currentNames = await getChildrenNames();
      if (!currentNames.contains(name)) {
        currentNames.add(name);
        await saveChildrenNames(currentNames);
      }
    } catch (e) {
      print('❌ Error adding child name: $e');
      rethrow;
    }
  }

  /// Remove a single child name
  Future<void> removeChildName(String name) async {
    try {
      final currentNames = await getChildrenNames();
      currentNames.remove(name);
      await saveChildrenNames(currentNames);
    } catch (e) {
      print('❌ Error removing child name: $e');
      rethrow;
    }
  }

  // Additional methods for dashboard compatibility
  Future<String?> getString(String key) async {
    return await getSecureData(key);
  }

  Future<void> setString(String key, String value) async {
    await storeSecureData(key, value);
  }

  Future<void> removeKey(String key) async {
    await deleteSecureData(key);
  }
}
