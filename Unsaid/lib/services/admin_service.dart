import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// Admin service for managing admin privileges and bypassing restrictions
class AdminService {
  static AdminService? _instance;
  static AdminService get instance => _instance ??= AdminService._();
  AdminService._();

  // Admin user IDs - add your Firebase Auth UID here
  static const List<String> _adminUserIds = [
    // Add your Firebase Auth UID here when you know it
    'ADMIN_USER_ID_PLACEHOLDER',
    // You can add more admin user IDs as needed
  ];

  /// Check if the current user is an admin
  bool get isCurrentUserAdmin {
    final user = AuthService.instance.user;
    if (user == null) return false;
    
    // Check if user ID is in admin list
    bool isAdmin = _adminUserIds.contains(user.uid);
    
    // Admin emails - these will work in both debug and production
    const adminEmails = [
      'john.gray@usd286.org',
      'jwgray4219425@gmail.com',
      // Add more admin emails as needed
    ];
    
    if (user.email != null && adminEmails.contains(user.email!.toLowerCase())) {
      isAdmin = true;
    }
    
    return isAdmin;
  }

  /// Check if current user can bypass restrictions
  bool get canBypassRestrictions => isCurrentUserAdmin;

  /// Check if current user has unlimited test access
  bool get hasUnlimitedTestAccess => isCurrentUserAdmin;

  /// Check if current user can retake personality tests
  bool get canRetakePersonalityTest => isCurrentUserAdmin;

  /// Check if current user can access all features
  bool get hasFullFeatureAccess => isCurrentUserAdmin;

  /// Get current user's admin status info
  Map<String, dynamic> get adminStatus {
    final user = AuthService.instance.user;
    
    return {
      'is_admin': isCurrentUserAdmin,
      'user_id': user?.uid,
      'email': user?.email,
      'can_bypass_restrictions': canBypassRestrictions,
      'unlimited_test_access': hasUnlimitedTestAccess,
      'can_retake_tests': canRetakePersonalityTest,
      'full_feature_access': hasFullFeatureAccess,
    };
  }

  /// Log admin actions for debugging
  void logAdminAction(String action) {
    if (kDebugMode && isCurrentUserAdmin) {
      print('🔧 Admin Action: $action by ${AuthService.instance.user?.email ?? 'Unknown'}');
    }
  }

  /// Update admin user IDs (for runtime configuration)
  /// This is mainly for development - in production, admin IDs should be hardcoded
  static void addAdminUser(String userId) {
    if (kDebugMode) {
      // Note: This won't actually modify the const list, but serves as a reference
      // for what IDs should be added to the _adminUserIds list
      print('🔧 Admin user to add: $userId');
    }
  }

  /// Display current user ID for admin setup
  String getCurrentUserId() {
    return AuthService.instance.user?.uid ?? 'No user authenticated';
  }

  /// Display current user email for admin setup
  String getCurrentUserEmail() {
    return AuthService.instance.user?.email ?? 'No email available';
  }
}
