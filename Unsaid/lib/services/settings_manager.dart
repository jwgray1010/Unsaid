import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Service for managing app settings including export/import functionality
class SettingsManager extends ChangeNotifier {
  static final SettingsManager _instance = SettingsManager._internal();
  factory SettingsManager() => _instance;
  SettingsManager._internal();

  SharedPreferences? _prefs;

  // Settings keys
  static const String _sensitivityKey = 'analysis_sensitivity';
  static const String _toneKey = 'default_tone';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _darkModeKey = 'dark_mode_enabled';
  static const String _aiAnalysisKey = 'ai_analysis_enabled';
  static const String _realTimeAnalysisKey = 'real_time_analysis';
  static const String _shareAnalyticsKey = 'share_analytics';
  static const String _languageKey = 'selected_language';
  static const String _fontSizeKey = 'font_size';
  static const String _highContrastKey = 'high_contrast_mode';
  static const String _backupEnabledKey = 'backup_enabled';

  /// Initialize the settings manager
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get all current settings as a map
  Map<String, dynamic> getAllSettings() {
    if (_prefs == null) return {};
    
    return {
      'analysis_sensitivity': _prefs!.getDouble(_sensitivityKey) ?? 0.5,
      'default_tone': _prefs!.getString(_toneKey) ?? 'Polite',
      'notifications_enabled': _prefs!.getBool(_notificationsKey) ?? true,
      'dark_mode_enabled': _prefs!.getBool(_darkModeKey) ?? false,
      'ai_analysis_enabled': _prefs!.getBool(_aiAnalysisKey) ?? true,
      'real_time_analysis': _prefs!.getBool(_realTimeAnalysisKey) ?? false,
      'share_analytics': _prefs!.getBool(_shareAnalyticsKey) ?? false,
      'selected_language': _prefs!.getString(_languageKey) ?? 'English',
      'font_size': _prefs!.getDouble(_fontSizeKey) ?? 14.0,
      'high_contrast_mode': _prefs!.getBool(_highContrastKey) ?? false,
      'backup_enabled': _prefs!.getBool(_backupEnabledKey) ?? true,
      'export_date': DateTime.now().toIso8601String(),
      'app_version': '1.0.0',
    };
  }

  /// Import settings from a map
  Future<bool> importSettings(Map<String, dynamic> settings) async {
    try {
      if (_prefs == null) await initialize();
      
      // Validate settings structure
      if (!_validateSettingsStructure(settings)) {
        return false;
      }

      // Import each setting with validation
      if (settings.containsKey('analysis_sensitivity')) {
        final sensitivity = settings['analysis_sensitivity'] as double?;
        if (sensitivity != null && sensitivity >= 0.0 && sensitivity <= 1.0) {
          await _prefs!.setDouble(_sensitivityKey, sensitivity);
        }
      }

      if (settings.containsKey('default_tone')) {
        final tone = settings['default_tone'] as String?;
        if (tone != null && _isValidTone(tone)) {
          await _prefs!.setString(_toneKey, tone);
        }
      }

      if (settings.containsKey('notifications_enabled')) {
        await _prefs!.setBool(_notificationsKey, settings['notifications_enabled'] ?? true);
      }

      if (settings.containsKey('dark_mode_enabled')) {
        await _prefs!.setBool(_darkModeKey, settings['dark_mode_enabled'] ?? false);
      }

      if (settings.containsKey('ai_analysis_enabled')) {
        await _prefs!.setBool(_aiAnalysisKey, settings['ai_analysis_enabled'] ?? true);
      }

      if (settings.containsKey('real_time_analysis')) {
        await _prefs!.setBool(_realTimeAnalysisKey, settings['real_time_analysis'] ?? false);
      }

      if (settings.containsKey('share_analytics')) {
        await _prefs!.setBool(_shareAnalyticsKey, settings['share_analytics'] ?? false);
      }

      if (settings.containsKey('selected_language')) {
        final language = settings['selected_language'] as String?;
        if (language != null && _isValidLanguage(language)) {
          await _prefs!.setString(_languageKey, language);
        }
      }

      if (settings.containsKey('font_size')) {
        final fontSize = settings['font_size'] as double?;
        if (fontSize != null && fontSize >= 10.0 && fontSize <= 24.0) {
          await _prefs!.setDouble(_fontSizeKey, fontSize);
        }
      }

      if (settings.containsKey('high_contrast_mode')) {
        await _prefs!.setBool(_highContrastKey, settings['high_contrast_mode'] ?? false);
      }

      if (settings.containsKey('backup_enabled')) {
        await _prefs!.setBool(_backupEnabledKey, settings['backup_enabled'] ?? true);
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('Error importing settings: $e');
      return false;
    }
  }

  /// Export settings to a JSON file
  Future<String?> exportSettingsToFile() async {
    try {
      final settings = getAllSettings();
      final jsonString = jsonEncode(settings);
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/unsaid_settings_$timestamp.json');
      
      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      print('Error exporting settings: $e');
      return null;
    }
  }

  /// Import settings from a JSON file
  Future<bool> importSettingsFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      
      final jsonString = await file.readAsString();
      final settings = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return await importSettings(settings);
    } catch (e) {
      print('Error importing settings from file: $e');
      return false;
    }
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    if (_prefs == null) await initialize();
    
    await _prefs!.clear();
    notifyListeners();
  }

  /// Individual setting getters
  double getSensitivity() => _prefs?.getDouble(_sensitivityKey) ?? 0.5;
  String getTone() => _prefs?.getString(_toneKey) ?? 'Polite';
  bool getNotificationsEnabled() => _prefs?.getBool(_notificationsKey) ?? true;
  bool getDarkModeEnabled() => _prefs?.getBool(_darkModeKey) ?? false;
  bool getAIAnalysisEnabled() => _prefs?.getBool(_aiAnalysisKey) ?? true;
  bool getRealTimeAnalysis() => _prefs?.getBool(_realTimeAnalysisKey) ?? false;
  bool getShareAnalytics() => _prefs?.getBool(_shareAnalyticsKey) ?? false;
  String getLanguage() => _prefs?.getString(_languageKey) ?? 'English';
  double getFontSize() => _prefs?.getDouble(_fontSizeKey) ?? 14.0;
  bool getHighContrastMode() => _prefs?.getBool(_highContrastKey) ?? false;
  bool getBackupEnabled() => _prefs?.getBool(_backupEnabledKey) ?? true;

  /// Individual setting setters
  Future<void> setSensitivity(double value) async {
    await _prefs?.setDouble(_sensitivityKey, value);
    notifyListeners();
  }

  Future<void> setTone(String value) async {
    await _prefs?.setString(_toneKey, value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs?.setBool(_notificationsKey, value);
    notifyListeners();
  }

  Future<void> setDarkModeEnabled(bool value) async {
    await _prefs?.setBool(_darkModeKey, value);
    notifyListeners();
  }

  Future<void> setAIAnalysisEnabled(bool value) async {
    await _prefs?.setBool(_aiAnalysisKey, value);
    notifyListeners();
  }

  Future<void> setRealTimeAnalysis(bool value) async {
    await _prefs?.setBool(_realTimeAnalysisKey, value);
    notifyListeners();
  }

  Future<void> setShareAnalytics(bool value) async {
    await _prefs?.setBool(_shareAnalyticsKey, value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    await _prefs?.setString(_languageKey, value);
    notifyListeners();
  }

  Future<void> setFontSize(double value) async {
    await _prefs?.setDouble(_fontSizeKey, value);
    notifyListeners();
  }

  Future<void> setHighContrastMode(bool value) async {
    await _prefs?.setBool(_highContrastKey, value);
    notifyListeners();
  }

  Future<void> setBackupEnabled(bool value) async {
    await _prefs?.setBool(_backupEnabledKey, value);
    notifyListeners();
  }

  /// Validation helpers
  bool _validateSettingsStructure(Map<String, dynamic> settings) {
    // Check if it contains at least some expected keys
    final expectedKeys = [
      'analysis_sensitivity', 'default_tone', 'notifications_enabled',
      'dark_mode_enabled', 'ai_analysis_enabled'
    ];
    
    return expectedKeys.any((key) => settings.containsKey(key));
  }

  bool _isValidTone(String tone) {
    const validTones = ['Polite', 'Gentle', 'Direct', 'Neutral'];
    return validTones.contains(tone);
  }

  bool _isValidLanguage(String language) {
    const validLanguages = ['English', 'Spanish', 'French', 'German', 'Italian'];
    return validLanguages.contains(language);
  }
}
