import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// API Response models for type safety
class TrialStatusResponse {
  final bool success;
  final String userId;
  final TrialData trial;
  final String timestamp;

  TrialStatusResponse({
    required this.success,
    required this.userId,
    required this.trial,
    required this.timestamp,
  });

  factory TrialStatusResponse.fromJson(Map<String, dynamic> json) {
    return TrialStatusResponse(
      success: json['success'] ?? false,
      userId: json['userId'] ?? '',
      trial: TrialData.fromJson(json['trial'] ?? {}),
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class TrialData {
  final String status;
  final int daysRemaining;
  final int totalTrialDays;
  final Map<String, bool> features;
  final bool isActive;
  final bool hasAccess;
  final Map<String, DailyLimit>? dailyLimits;
  final String? trialStartDate;
  final PricingInfo? pricing;

  TrialData({
    required this.status,
    required this.daysRemaining,
    required this.totalTrialDays,
    required this.features,
    required this.isActive,
    required this.hasAccess,
    this.dailyLimits,
    this.trialStartDate,
    this.pricing,
  });

  factory TrialData.fromJson(Map<String, dynamic> json) {
    Map<String, DailyLimit>? dailyLimits;
    if (json['dailyLimits'] != null) {
      final limitsJson = json['dailyLimits'] as Map<String, dynamic>;
      dailyLimits = limitsJson.map(
        (key, value) => MapEntry(key, DailyLimit.fromJson(value)),
      );
    }

    return TrialData(
      status: json['status'] ?? '',
      daysRemaining: json['daysRemaining'] ?? 0,
      totalTrialDays: json['totalTrialDays'] ?? 7,
      features: Map<String, bool>.from(json['features'] ?? {}),
      isActive: json['isActive'] ?? false,
      hasAccess: json['hasAccess'] ?? false,
      dailyLimits: dailyLimits,
      trialStartDate: json['trialStartDate'],
      pricing: json['pricing'] != null
          ? PricingInfo.fromJson(json['pricing'])
          : null,
    );
  }
}

class DailyLimit {
  final int total;
  final int used;
  final int remaining;

  DailyLimit({
    required this.total,
    required this.used,
    required this.remaining,
  });

  factory DailyLimit.fromJson(Map<String, dynamic> json) {
    return DailyLimit(
      total: json['total'] ?? 0,
      used: json['used'] ?? 0,
      remaining: json['remaining'] ?? 0,
    );
  }
}

class PricingInfo {
  final double monthlyPrice;
  final String currency;

  PricingInfo({
    required this.monthlyPrice,
    required this.currency,
  });

  factory PricingInfo.fromJson(Map<String, dynamic> json) {
    return PricingInfo(
      monthlyPrice: (json['monthlyPrice'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
    );
  }
}

class SuggestionResponse {
  final bool success;
  final List<TherapeuticSuggestion> suggestions;
  final String primaryTone;
  final double confidence;
  final String attachmentStyle;
  final bool mlAnalysisUsed;
  final Map<String, dynamic> finalToneAnalysis;
  final TrialData? trialStatus;

  SuggestionResponse({
    required this.success,
    required this.suggestions,
    required this.primaryTone,
    required this.confidence,
    required this.attachmentStyle,
    required this.mlAnalysisUsed,
    required this.finalToneAnalysis,
    this.trialStatus,
  });

  factory SuggestionResponse.fromJson(Map<String, dynamic> json) {
    return SuggestionResponse(
      success: json['success'] ?? false,
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => TherapeuticSuggestion.fromJson(e))
              .toList() ??
          [],
      primaryTone: json['primaryTone'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      attachmentStyle: json['attachmentStyle'] ?? 'secure',
      mlAnalysisUsed: json['mlAnalysisUsed'] ?? false,
      finalToneAnalysis: json['finalToneAnalysis'] ?? {},
      trialStatus: json['trialStatus'] != null
          ? TrialData.fromJson(json['trialStatus'])
          : null,
    );
  }
}

class TherapeuticSuggestion {
  final String text;
  final String type;
  final double confidence;
  final String category;
  final String source;

  TherapeuticSuggestion({
    required this.text,
    required this.type,
    required this.confidence,
    required this.category,
    required this.source,
  });

  factory TherapeuticSuggestion.fromJson(Map<String, dynamic> json) {
    return TherapeuticSuggestion(
      text: json['text'] ?? '',
      type: json['type'] ?? 'therapy_suggestion',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      category: json['category'] ?? 'general',
      source: json['source'] ?? 'therapeutic_advice',
    );
  }
}

/// Service to communicate with Unsaid API endpoints
class UnsaidApiService {
  static final UnsaidApiService _instance = UnsaidApiService._internal();
  factory UnsaidApiService() => _instance;
  UnsaidApiService._internal();

  static const String _baseUrl = 'https://api.myunsaidapp.com/api';
  static const Duration _requestTimeout = Duration(seconds: 30);

  /// Get current user ID from auth service
  String get _currentUserId {
    return AuthService.instance.user?.uid ?? 'anonymous';
  }

  /// Common headers for API requests
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'User-Agent': 'UnsaidApp/1.0',
      };

  /// Get trial status for current user
  Future<TrialStatusResponse?> getTrialStatus() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/trial-status?userId=$_currentUserId'),
            headers: _headers,
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TrialStatusResponse.fromJson(data);
      } else {
        if (kDebugMode) {
          print('❌ Trial status API error: ${response.statusCode}');
          print('Response: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Trial status request failed: $e');
      }
      return null;
    }
  }

  /// Get AI-powered suggestions for text
  Future<SuggestionResponse?> getSuggestions({
    required String text,
    String context = 'general',
    String attachmentStyle = 'secure',
    Map<String, dynamic>? toneAnalysisResult,
  }) async {
    try {
      final requestBody = {
        'text': text,
        'userId': _currentUserId,
        'context': context,
        'attachmentStyle': attachmentStyle,
        if (toneAnalysisResult != null)
          'toneAnalysisResult': toneAnalysisResult,
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl/suggestions'),
            headers: _headers,
            body: jsonEncode(requestBody),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SuggestionResponse.fromJson(data);
      } else if (response.statusCode == 403) {
        // Trial access required
        if (kDebugMode) {
          print('⚠️ Trial access required for suggestions');
        }
        return null;
      } else {
        if (kDebugMode) {
          print('❌ Suggestions API error: ${response.statusCode}');
          print('Response: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Suggestions request failed: $e');
      }
      return null;
    }
  }

  /// Test API connectivity
  Future<bool> testConnectivity() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/suggestions'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      // A GET request to suggestions should return method info
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('❌ API connectivity test failed: $e');
      }
      return false;
    }
  }

  /// Get API status and features
  Future<Map<String, dynamic>?> getApiStatus() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/suggestions'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ API status request failed: $e');
      }
      return null;
    }
  }
}
