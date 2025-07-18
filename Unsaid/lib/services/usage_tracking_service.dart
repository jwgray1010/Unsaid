import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'auth_service.dart';

/// Usage tracking and rate limiting service for API calls
/// Helps prevent abuse and track beta user engagement
class UsageTrackingService extends ChangeNotifier {
  static UsageTrackingService? _instance;
  static UsageTrackingService get instance =>
      _instance ??= UsageTrackingService._();
  UsageTrackingService._();

  SharedPreferences? _prefs;
  Map<String, int> _dailyUsage = {};
  Map<String, DateTime> _lastUsage = {};

  // Rate limits for beta users
  static const Map<String, int> _dailyLimits = {
    'tone_analysis': 100,
    'coaching_suggestions': 50,
    'ai_chat': 20,
    'relationship_insights': 10,
    'message_generation': 30,
  };

  // Rate limits per hour
  static const Map<String, int> _hourlyLimits = {
    'tone_analysis': 20,
    'coaching_suggestions': 15,
    'ai_chat': 10,
    'relationship_insights': 5,
    'message_generation': 10,
  };

  /// Initialize the usage tracking service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadUsageData();

      if (kDebugMode) {
        print('📊 UsageTrackingService initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing UsageTrackingService: $e');
      }
    }
  }

  /// Load usage data from persistent storage
  Future<void> _loadUsageData() async {
    if (_prefs == null) return;

    try {
      final String today = _getTodayKey();
      final String? dailyUsageJson = _prefs!.getString('daily_usage_$today');

      if (dailyUsageJson != null) {
        _dailyUsage = Map<String, int>.from(json.decode(dailyUsageJson));
      }

      final String? lastUsageJson = _prefs!.getString('last_usage');
      if (lastUsageJson != null) {
        final Map<String, String> lastUsageMap = Map<String, String>.from(
          json.decode(lastUsageJson),
        );
        _lastUsage = lastUsageMap.map(
          (key, value) => MapEntry(key, DateTime.parse(value)),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading usage data: $e');
      }
    }
  }

  /// Save usage data to persistent storage
  Future<void> _saveUsageData() async {
    if (_prefs == null) return;

    try {
      final String today = _getTodayKey();
      await _prefs!.setString('daily_usage_$today', json.encode(_dailyUsage));

      final Map<String, String> lastUsageMap = _lastUsage.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      );
      await _prefs!.setString('last_usage', json.encode(lastUsageMap));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving usage data: $e');
      }
    }
  }

  /// Check if user can make a request for the given feature
  Future<bool> canMakeRequest(String feature) async {
    if (!AuthService.instance.isAuthenticated) {
      if (kDebugMode) {
        print('❌ Rate limit check failed: User not authenticated');
      }
      return false;
    }

    // Check daily limit
    final int dailyUsage = _dailyUsage[feature] ?? 0;
    final int dailyLimit = _dailyLimits[feature] ?? 0;

    if (dailyUsage >= dailyLimit) {
      if (kDebugMode) {
        print(
          '❌ Daily rate limit exceeded for $feature: $dailyUsage/$dailyLimit',
        );
      }
      return false;
    }

    // Check hourly limit
    final DateTime now = DateTime.now();
    final DateTime? lastUsage = _lastUsage[feature];

    if (lastUsage != null) {
      final int hourlyUsage = _getHourlyUsage(feature, now);
      final int hourlyLimit = _hourlyLimits[feature] ?? 0;

      if (hourlyUsage >= hourlyLimit) {
        if (kDebugMode) {
          print(
            '❌ Hourly rate limit exceeded for $feature: $hourlyUsage/$hourlyLimit',
          );
        }
        return false;
      }
    }

    return true;
  }

  /// Track usage for a feature
  Future<void> trackUsage(
    String feature, {
    Map<String, dynamic>? metadata,
  }) async {
    if (!AuthService.instance.isAuthenticated) return;

    try {
      final DateTime now = DateTime.now();

      // Update daily usage
      _dailyUsage[feature] = (_dailyUsage[feature] ?? 0) + 1;
      _lastUsage[feature] = now;

      // Save to persistent storage
      await _saveUsageData();

      // Track user engagement
      await _trackUserEngagement(feature, metadata);

      if (kDebugMode) {
        print('📊 Usage tracked for $feature: ${_dailyUsage[feature]} today');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error tracking usage: $e');
      }
    }
  }

  /// Get current usage stats
  Map<String, dynamic> getUsageStats() {
    final Map<String, dynamic> stats = {};

    for (final feature in _dailyLimits.keys) {
      final int used = _dailyUsage[feature] ?? 0;
      final int limit = _dailyLimits[feature] ?? 0;

      stats[feature] = {
        'used': used,
        'limit': limit,
        'remaining': limit - used,
        'percentage': limit > 0 ? (used / limit * 100).round() : 0,
      };
    }

    return stats;
  }

  /// Get usage for a specific feature
  Map<String, dynamic> getFeatureUsage(String feature) {
    final int used = _dailyUsage[feature] ?? 0;
    final int limit = _dailyLimits[feature] ?? 0;

    return {
      'used': used,
      'limit': limit,
      'remaining': limit - used,
      'percentage': limit > 0 ? (used / limit * 100).round() : 0,
      'lastUsed': _lastUsage[feature]?.toIso8601String(),
    };
  }

  /// Reset daily usage (called at midnight)
  Future<void> resetDailyUsage() async {
    try {
      _dailyUsage.clear();
      await _saveUsageData();

      if (kDebugMode) {
        print('🔄 Daily usage reset');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error resetting daily usage: $e');
      }
    }
  }

  /// Get today's key for storage
  String _getTodayKey() {
    final DateTime now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Get hourly usage for a feature
  int _getHourlyUsage(String feature, DateTime now) {
    final DateTime? lastUsage = _lastUsage[feature];
    if (lastUsage == null) return 0;

    final DateTime hourAgo = now.subtract(const Duration(hours: 1));

    // For simplicity, return 0 if last usage was more than an hour ago
    // In a real implementation, you'd store all usage timestamps
    return lastUsage.isAfter(hourAgo) ? 1 : 0;
  }

  /// Track user engagement metrics
  Future<void> _trackUserEngagement(
    String feature,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      final String? userId = AuthService.instance.user?.uid;
      if (userId == null) return;

      final Map<String, dynamic> engagement = {
        'userId': userId,
        'feature': feature,
        'timestamp': DateTime.now().toIso8601String(),
        'isAnonymous': AuthService.instance.isAnonymous,
        'metadata': metadata ?? {},
      };

      // Store engagement data locally for now
      // In the future, this could be sent to analytics service
      final String engagementKey =
          'engagement_${DateTime.now().millisecondsSinceEpoch}';
      await _prefs?.setString(engagementKey, json.encode(engagement));

      if (kDebugMode) {
        print('📈 User engagement tracked: $feature');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error tracking engagement: $e');
      }
    }
  }

  /// Get user engagement summary
  Future<Map<String, dynamic>> getEngagementSummary() async {
    try {
      final Map<String, dynamic> summary = {
        'totalSessions': 0,
        'featuresUsed': <String>{},
        'lastActive': null,
        'isAnonymous': AuthService.instance.isAnonymous,
      };

      if (_prefs == null) return summary;

      final Set<String> keys = _prefs!.getKeys();
      for (final key in keys) {
        if (key.startsWith('engagement_')) {
          try {
            final String? value = _prefs!.getString(key);
            if (value != null) {
              final Map<String, dynamic> engagement = json.decode(value);
              summary['totalSessions'] = (summary['totalSessions'] as int) + 1;
              (summary['featuresUsed'] as Set<String>).add(
                engagement['feature'],
              );
              summary['lastActive'] = engagement['timestamp'];
            }
          } catch (e) {
            // Skip invalid engagement data
          }
        }
      }

      summary['featuresUsed'] = (summary['featuresUsed'] as Set<String>)
          .toList();
      return summary;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting engagement summary: $e');
      }
      return {};
    }
  }

  /// Clear all usage data (for testing or user account deletion)
  Future<void> clearUsageData() async {
    try {
      _dailyUsage.clear();
      _lastUsage.clear();

      if (_prefs != null) {
        final Set<String> keys = _prefs!.getKeys();
        for (final key in keys) {
          if (key.startsWith('daily_usage_') ||
              key.startsWith('last_usage') ||
              key.startsWith('engagement_')) {
            await _prefs!.remove(key);
          }
        }
      }

      if (kDebugMode) {
        print('🗑️ Usage data cleared');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error clearing usage data: $e');
      }
    }
  }
}
