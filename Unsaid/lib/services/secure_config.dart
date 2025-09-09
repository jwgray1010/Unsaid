import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

/// Security exception for configuration errors
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}

/// Secure configuration service to manage API keys and sensitive data
class SecureConfig {
  static SecureConfig? _instance;
  static SecureConfig get instance => _instance ??= SecureConfig._();
  SecureConfig._();

  // Secure fallback - NO HARDCODED KEYS
  static const String _fallbackApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '', // REMOVED HARDCODED KEY FOR SECURITY
  );

  // Backend endpoint - Updated with deployed Firebase Functions URL
  static const String _configEndpoint =
      'https://us-central1-unsaid-3bc7c.cloudfunctions.net/getConfig';

  String? _cachedApiKey;
  DateTime? _lastFetch;
  static const Duration _cacheTimeout = Duration(hours: 1);

  /// Get OpenAI API key securely
  Future<String> getOpenAIKey() async {
    // Check cache first
    if (_cachedApiKey != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheTimeout) {
      return _cachedApiKey!;
    }

    try {
      // Get Firebase ID token for authentication
      final String? idToken = await AuthService.instance.getIdToken();

      if (idToken == null) {
        if (kDebugMode) {
          print('⚠️ No authentication token available, using fallback');
        }
        return _getFallbackKey();
      }

      // Try to fetch from secure backend
      final response = await http
          .get(
            Uri.parse(_configEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final apiKey = data['openai_key'] as String?;
        
        if (apiKey != null && isValidApiKey(apiKey)) {
          _cachedApiKey = apiKey;
          _lastFetch = DateTime.now();

          if (kDebugMode) {
            print('✅ API key fetched securely from backend');
          }

          return _cachedApiKey!;
        } else {
          if (kDebugMode) {
            print('⚠️ Invalid API key received from backend');
          }
        }
      } else {
        if (kDebugMode) {
          print(
            '⚠️ Backend returned status ${response.statusCode}: ${response.body}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Backend config unavailable, using fallback: $e');
      }
    }

    // Fallback to environment variable (temporary for beta)
    return _getFallbackKey();
  }

  /// Get fallback API key with proper validation
  String _getFallbackKey() {
    const key = _fallbackApiKey;
    if (key.isEmpty) {
      throw SecurityException('No API key available - please configure backend or environment variables');
    }
    if (!isValidApiKey(key)) {
      throw SecurityException('Invalid API key format');
    }
    return key;
  }

  /// Clear cached credentials
  void clearCache() {
    _cachedApiKey = null;
    _lastFetch = null;
  }

  /// Validate API key format
  bool isValidApiKey(String key) {
    // Check for proper OpenAI API key format
    if (key.isEmpty || key == 'your_openai_api_key_here') {
      return false;
    }
    
    // OpenAI API keys start with sk- and are typically 48-51 characters
    if (!key.startsWith('sk-') || key.length < 20) {
      return false;
    }
    
    // Additional validation for known placeholder values
    if (key.contains('your_') || key.contains('placeholder') || key.contains('demo')) {
      return false;
    }
    
    return true;
  }
}
