import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

/// Compatibility service for handling plugin failures on older systems
class CompatibilityService {
  static CompatibilityService? _instance;
  static CompatibilityService get instance =>
      _instance ??= CompatibilityService._();

  CompatibilityService._();

  SharedPreferences? _prefs;
  String? _fallbackDirectory;

  /// Initialize compatibility service with fallbacks
  Future<void> initialize() async {
    await _initializeSharedPreferences();
    await _initializePathProvider();
  }

  /// Initialize shared preferences with fallback
  Future<void> _initializeSharedPreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      if (kDebugMode) {
        print('✅ SharedPreferences initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SharedPreferences failed, using memory fallback: $e');
      }
      // _prefs remains null, we'll use memory storage as fallback
    }
  }

  /// Initialize path provider with fallback
  Future<void> _initializePathProvider() async {
    try {
      final directory = await getApplicationSupportDirectory();
      _fallbackDirectory = directory.path;
      if (kDebugMode) {
        print('✅ PathProvider initialized: $_fallbackDirectory');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ PathProvider failed, using temp directory fallback: $e');
      }
      // Use a fallback directory
      if (Platform.isIOS) {
        _fallbackDirectory = '/tmp/unsaid_fallback';
      } else {
        _fallbackDirectory = './unsaid_fallback';
      }

      try {
        final dir = Directory(_fallbackDirectory!);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Could not create fallback directory: $e');
        }
      }
    }
  }

  /// Get a string preference with fallback
  String? getString(String key) {
    try {
      return _prefs?.getString(key);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get string preference $key: $e');
      }
      return null;
    }
  }

  /// Set a string preference with fallback
  Future<bool> setString(String key, String value) async {
    try {
      return await _prefs?.setString(key, value) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to set string preference $key: $e');
      }
      return false;
    }
  }

  /// Get a boolean preference with fallback
  bool? getBool(String key) {
    try {
      return _prefs?.getBool(key);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to get bool preference $key: $e');
      }
      return null;
    }
  }

  /// Set a boolean preference with fallback
  Future<bool> setBool(String key, bool value) async {
    try {
      return await _prefs?.setBool(key, value) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to set bool preference $key: $e');
      }
      return false;
    }
  }

  /// Get application support directory with fallback
  String? getApplicationSupportPath() {
    return _fallbackDirectory;
  }

  /// Check if shared preferences are working
  bool get isSharedPreferencesAvailable => _prefs != null;

  /// Check if path provider is working
  bool get isPathProviderAvailable => _fallbackDirectory != null;

  /// Get compatibility status
  Map<String, bool> getCompatibilityStatus() {
    return {
      'shared_preferences': isSharedPreferencesAvailable,
      'path_provider': isPathProviderAvailable,
    };
  }
}
