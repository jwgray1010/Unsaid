import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_service.dart';

/// Service for managing onboarding state and navigation
class OnboardingService {
  static OnboardingService? _instance;
  static OnboardingService get instance =>
      _instance ??= OnboardingService._();
  OnboardingService._();

  static const String _onboardingCompleteKey = 'onboarding_complete';

  /// Check if onboarding has been completed
  Future<bool> isOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Admin bypass: admins can always reset/redo onboarding
      if (AdminService.instance.isCurrentUserAdmin) {
        AdminService.instance.logAdminAction('Checking onboarding status (admin bypass available)');
        return prefs.getBool(_onboardingCompleteKey) ?? false;
      }
      
      return prefs.getBool(_onboardingCompleteKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking onboarding completion: $e');
      }
      return false;
    }
  }

  /// Mark onboarding as complete
  Future<void> markOnboardingComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompleteKey, true);
      if (kDebugMode) {
        print('✅ Onboarding marked as complete');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error marking onboarding complete: $e');
      }
    }
  }

  /// Reset onboarding state (for testing and admin use)
  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingCompleteKey);
      
      if (AdminService.instance.isCurrentUserAdmin) {
        AdminService.instance.logAdminAction('Reset onboarding state');
      }
      
      if (kDebugMode) {
        print('🔄 Onboarding state reset');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error resetting onboarding: $e');
      }
    }
  }
}
