import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'secure_storage_service.dart';

/// Service for managing user profiles and preferences
class UserProfileService {
  static const String _userCollection = 'users';
  static const String _profileCollection = 'profiles';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SecureStorageService _secureStorage = SecureStorageService();
  
  /// Get user profile data
  Future<Map<String, dynamic>> getUserProfile(String? userId) async {
    try {
      if (userId == null) {
        return _getDefaultProfile();
      }
      
      final doc = await _firestore
          .collection(_userCollection)
          .doc(userId)
          .collection(_profileCollection)
          .doc('profile')
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      } else {
        // Try to get from local storage
        final localProfile = await _getLocalProfile(userId);
        if (localProfile != null) {
          return localProfile;
        }
        
        // Return default profile
        return _getDefaultProfile();
      }
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return _getDefaultProfile();
    }
  }
  
  /// Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      profileData['last_updated'] = FieldValue.serverTimestamp();
      
      await _firestore
          .collection(_userCollection)
          .doc(userId)
          .collection(_profileCollection)
          .doc('profile')
          .set(profileData, SetOptions(merge: true));
      
      // Also store locally as backup
      await _storeLocalProfile(userId, profileData);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      // Store locally as fallback
      await _storeLocalProfile(userId, profileData);
    }
  }
  
  /// Get user attachment style
  Future<String> getUserAttachmentStyle(String? userId) async {
    try {
      final profile = await getUserProfile(userId);
      return profile['attachment_style'] as String? ?? 'secure';
    } catch (e) {
      debugPrint('Error getting user attachment style: $e');
      return 'secure';
    }
  }
  
  /// Update user attachment style
  Future<void> updateUserAttachmentStyle(String userId, String attachmentStyle) async {
    try {
      await updateUserProfile(userId, {
        'attachment_style': attachmentStyle,
        'attachment_style_updated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating user attachment style: $e');
    }
  }
  
  /// Get user preferences
  Future<Map<String, dynamic>> getUserPreferences(String? userId) async {
    try {
      final profile = await getUserProfile(userId);
      return profile['preferences'] as Map<String, dynamic>? ?? _getDefaultPreferences();
    } catch (e) {
      debugPrint('Error getting user preferences: $e');
      return _getDefaultPreferences();
    }
  }
  
  /// Update user preferences
  Future<void> updateUserPreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      await updateUserProfile(userId, {
        'preferences': preferences,
        'preferences_updated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating user preferences: $e');
    }
  }
  
  /// Get user relationship data
  Future<Map<String, dynamic>> getUserRelationshipData(String? userId) async {
    try {
      final profile = await getUserProfile(userId);
      return profile['relationship_data'] as Map<String, dynamic>? ?? _getDefaultRelationshipData();
    } catch (e) {
      debugPrint('Error getting user relationship data: $e');
      return _getDefaultRelationshipData();
    }
  }
  
  /// Update user relationship data
  Future<void> updateUserRelationshipData(String userId, Map<String, dynamic> relationshipData) async {
    try {
      await updateUserProfile(userId, {
        'relationship_data': relationshipData,
        'relationship_data_updated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error updating user relationship data: $e');
    }
  }
  
  /// Store profile locally
  Future<void> _storeLocalProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      final localData = Map<String, dynamic>.from(profileData);
      localData['local_storage_timestamp'] = DateTime.now().toIso8601String();
      
      await _secureStorage.storeSecureJson('user_profile_$userId', localData);
    } catch (e) {
      debugPrint('Error storing local profile: $e');
    }
  }
  
  /// Get profile from local storage
  Future<Map<String, dynamic>?> _getLocalProfile(String userId) async {
    try {
      return await _secureStorage.getSecureJson('user_profile_$userId');
    } catch (e) {
      debugPrint('Error getting local profile: $e');
      return null;
    }
  }
  
  /// Get default profile
  Map<String, dynamic> _getDefaultProfile() {
    return {
      'id': 'default_user',
      'attachment_style': 'secure',
      'preferences': _getDefaultPreferences(),
      'relationship_data': _getDefaultRelationshipData(),
      'created_at': DateTime.now().toIso8601String(),
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
  
  /// Get default preferences
  Map<String, dynamic> _getDefaultPreferences() {
    return {
      'notifications_enabled': true,
      'analytics_enabled': true,
      'theme': 'light',
      'language': 'en',
      'privacy_level': 'standard',
      'data_sharing_consent': false,
      'insights_frequency': 'weekly',
      'reminder_settings': {
        'check_ins': true,
        'reflection_prompts': true,
        'growth_milestones': true,
      },
    };
  }
  
  /// Get default relationship data
  Map<String, dynamic> _getDefaultRelationshipData() {
    return {
      'relationship_type': 'romantic',
      'relationship_duration': 'unknown',
      'communication_style': 'direct',
      'conflict_resolution_style': 'collaborative',
      'love_languages': ['words_of_affirmation', 'quality_time'],
      'shared_goals': [],
      'challenges': [],
      'strengths': [],
      'growth_areas': [],
    };
  }
  
  /// Create new user profile
  Future<void> createUserProfile(String userId, Map<String, dynamic> initialData) async {
    try {
      final profileData = {
        ...initialData,
        'id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
        'preferences': _getDefaultPreferences(),
        'relationship_data': _getDefaultRelationshipData(),
      };
      
      await _firestore
          .collection(_userCollection)
          .doc(userId)
          .collection(_profileCollection)
          .doc('profile')
          .set(profileData);
      
      // Store locally as backup
      await _storeLocalProfile(userId, profileData);
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      // Store locally as fallback
      await _storeLocalProfile(userId, initialData);
    }
  }
  
  /// Delete user profile
  Future<void> deleteUserProfile(String userId) async {
    try {
      await _firestore
          .collection(_userCollection)
          .doc(userId)
          .collection(_profileCollection)
          .doc('profile')
          .delete();
      
      // Delete local storage
      await _secureStorage.deleteSecureData('user_profile_$userId');
    } catch (e) {
      debugPrint('Error deleting user profile: $e');
    }
  }
  
  /// Get user analytics settings
  Future<Map<String, dynamic>> getUserAnalyticsSettings(String? userId) async {
    try {
      final preferences = await getUserPreferences(userId);
      return {
        'analytics_enabled': preferences['analytics_enabled'] ?? true,
        'insights_frequency': preferences['insights_frequency'] ?? 'weekly',
        'privacy_level': preferences['privacy_level'] ?? 'standard',
        'data_sharing_consent': preferences['data_sharing_consent'] ?? false,
      };
    } catch (e) {
      debugPrint('Error getting user analytics settings: $e');
      return {
        'analytics_enabled': true,
        'insights_frequency': 'weekly',
        'privacy_level': 'standard',
        'data_sharing_consent': false,
      };
    }
  }
  
  /// Update user analytics settings
  Future<void> updateUserAnalyticsSettings(String userId, Map<String, dynamic> settings) async {
    try {
      final preferences = await getUserPreferences(userId);
      preferences.addAll(settings);
      await updateUserPreferences(userId, preferences);
    } catch (e) {
      debugPrint('Error updating user analytics settings: $e');
    }
  }
  
  /// Check if user exists
  Future<bool> userExists(String userId) async {
    try {
      final doc = await _firestore
          .collection(_userCollection)
          .doc(userId)
          .collection(_profileCollection)
          .doc('profile')
          .get();
      
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking if user exists: $e');
      return false;
    }
  }
  
  /// Get user profile summary
  Future<Map<String, dynamic>> getUserProfileSummary(String? userId) async {
    try {
      final profile = await getUserProfile(userId);
      return {
        'id': profile['id'],
        'attachment_style': profile['attachment_style'],
        'relationship_type': profile['relationship_data']['relationship_type'],
        'communication_style': profile['relationship_data']['communication_style'],
        'analytics_enabled': profile['preferences']['analytics_enabled'],
        'last_updated': profile['last_updated'],
      };
    } catch (e) {
      debugPrint('Error getting user profile summary: $e');
      return {
        'id': 'default_user',
        'attachment_style': 'secure',
        'relationship_type': 'romantic',
        'communication_style': 'direct',
        'analytics_enabled': true,
        'last_updated': DateTime.now().toIso8601String(),
      };
    }
  }
  
  /// Get current user profile
  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      // Mock user profile data for now
      return {
        'id': 'user_123',
        'name': 'User',
        'attachment_style': 'Secure',
        'communication_preferences': {
          'preferred_tone': 'supportive',
          'conflict_resolution_style': 'collaborative',
        },
        'goals': ['Improve empathy', 'Better conflict resolution'],
        'progress': {
          'empathy_score': 0.75,
          'clarity_score': 0.68,
          'consistency_score': 0.72,
        },
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {};
    }
  }
}
