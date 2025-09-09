import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'keyboard_manager.dart';

/// Service for managing partner data and relationship connectivity
class PartnerDataService extends ChangeNotifier {
  static final PartnerDataService _instance = PartnerDataService._internal();
  factory PartnerDataService() => _instance;
  PartnerDataService._internal();

  final KeyboardManager _keyboardManager = KeyboardManager();

  // Partner-related data

  bool _hasPartner = false;
  String? _partnerName;
  String? _partnerUserId;
  String? _inviteCode;
  List<Map<String, dynamic>> _partnerAnalysisHistory = [];

  bool get hasPartner => _hasPartner;
  String? get partnerName => _partnerName;
  String? get partnerUserId => _partnerUserId;
  String? get inviteCode => _inviteCode;
  List<Map<String, dynamic>> get partnerAnalysisHistory =>
      _partnerAnalysisHistory;

  /// Initialize partner data service and load stored data
  Future<void> initialize() async {
    await _loadPartnerData();
    await _loadPartnerAnalysisHistory();
  }

  /// Load partner data from SharedPreferences
  Future<void> _loadPartnerData() async {
    final prefs = await SharedPreferences.getInstance();
    _hasPartner = prefs.getBool('has_partner') ?? false;
    _partnerName = prefs.getString('partner_name');
    _partnerUserId = prefs.getString('partner_user_id');
    _inviteCode = prefs.getString('invite_code');
    notifyListeners();
  }

  /// Load partner's analysis history from SharedPreferences
  Future<void> _loadPartnerAnalysisHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('partner_analysis_history');
    if (historyJson != null) {
      try {
        final List<dynamic> decoded = json.decode(historyJson);
        _partnerAnalysisHistory = decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        print('Error loading partner analysis history: $e');
        _partnerAnalysisHistory = [];
      }
    }
  }

  /// Save partner data to SharedPreferences
  Future<void> _savePartnerData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_partner', _hasPartner);
    if (_partnerName != null) {
      await prefs.setString('partner_name', _partnerName!);
    }
    if (_partnerUserId != null) {
      await prefs.setString('partner_user_id', _partnerUserId!);
    }
    if (_inviteCode != null) {
      await prefs.setString('invite_code', _inviteCode!);
    }
  }

  /// Save partner analysis history to SharedPreferences
  Future<void> _savePartnerAnalysisHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = json.encode(_partnerAnalysisHistory);
    await prefs.setString('partner_analysis_history', historyJson);
  }

  /// Generate an invite code for the partner
  Future<String> generateInviteCode() async {
    final random = Random();
    final code = List.generate(
        8, (index) => String.fromCharCode(random.nextInt(26) + 65)).join();

    _inviteCode = code;
    await _savePartnerData();
    notifyListeners();

    return code;
  }

  /// Accept an invite code and connect to partner
  Future<bool> acceptInviteCode(String code, String partnerName) async {
    // In a real app, this would validate the invite code against a backend
    // For demo purposes, we'll simulate successful connection
    if (code.length >= 6) {
      _hasPartner = true;
      _partnerName = partnerName;
      _partnerUserId = 'partner_${DateTime.now().millisecondsSinceEpoch}';
      _inviteCode = code;

      await _savePartnerData();
      await _generateInitialPartnerData();
      notifyListeners();

      return true;
    }
    return false;
  }

  /// Disconnect from partner
  Future<void> disconnectPartner() async {
    _hasPartner = false;
    _partnerName = null;
    _partnerUserId = null;
    _inviteCode = null;
    _partnerAnalysisHistory = [];

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('has_partner');
    await prefs.remove('partner_name');
    await prefs.remove('partner_user_id');
    await prefs.remove('invite_code');
    await prefs.remove('partner_analysis_history');

    notifyListeners();
  }

  /// Generate initial partner data (simulated for demo)
  Future<void> _generateInitialPartnerData() async {
    // In a real app, this would sync actual partner data from their device
    // For demo purposes, we'll generate realistic simulated data
    _partnerAnalysisHistory = _generateSimulatedPartnerData();
    await _savePartnerAnalysisHistory();
  }

  /// Get combined analysis history (user + partner)
  List<Map<String, dynamic>> getCombinedAnalysisHistory() {
    final userHistory = _keyboardManager.analysisHistory;
    final combinedHistory = <Map<String, dynamic>>[];

    // Add user history with source indicator
    for (final entry in userHistory) {
      combinedHistory.add({
        ...entry,
        'source': 'user',
        'participant_name': 'You',
      });
    }

    // Add partner history with source indicator
    for (final entry in _partnerAnalysisHistory) {
      combinedHistory.add({
        ...entry,
        'source': 'partner',
        'participant_name': _partnerName ?? 'Partner',
      });
    }

    // Sort by timestamp
    combinedHistory.sort((a, b) {
      final aTime = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
      final bTime = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();
      return aTime.compareTo(bTime);
    });

    return combinedHistory;
  }

  /// Get user vs partner message counts
  Map<String, int> getMessageCounts() {
    final userCount = _keyboardManager.analysisHistory.length;
    final partnerCount = _partnerAnalysisHistory.length;

    return {
      'user': userCount,
      'partner': partnerCount,
      'total': userCount + partnerCount,
    };
  }

  /// Get compatibility score between user and partner
  double getCompatibilityScore() {
    if (!_hasPartner || _partnerAnalysisHistory.isEmpty) {
      return 0.87; // Default fallback
    }

    final userHistory = _keyboardManager.analysisHistory;
    if (userHistory.isEmpty) return 0.87;

    // Calculate compatibility based on communication patterns
    double userAvgTone = _calculateAverageScore(userHistory, 'tone_analysis');
    double partnerAvgTone =
        _calculateAverageScore(_partnerAnalysisHistory, 'tone_analysis');

    double userAvgEmpathy =
        _calculateAverageScore(userHistory, 'empathy_score');
    double partnerAvgEmpathy =
        _calculateAverageScore(_partnerAnalysisHistory, 'empathy_score');

    // Calculate compatibility based on similarity and complementary traits
    double toneCompatibility = 1.0 - (userAvgTone - partnerAvgTone).abs() / 2.0;
    double empathyCompatibility =
        1.0 - (userAvgEmpathy - partnerAvgEmpathy).abs() / 2.0;

    return ((toneCompatibility + empathyCompatibility) / 2.0).clamp(0.0, 1.0);
  }

  /// Calculate average score for a specific metric
  double _calculateAverageScore(
      List<Map<String, dynamic>> history, String metric) {
    if (history.isEmpty) return 0.5;

    double total = 0.0;
    int count = 0;

    for (final entry in history) {
      double value = 0.0;

      if (metric == 'tone_analysis') {
        final toneAnalysis = entry['tone_analysis'];
        if (toneAnalysis != null) {
          value = (toneAnalysis['empathy_score'] ?? 0.5) +
              (toneAnalysis['clarity_score'] ?? 0.5) +
              (toneAnalysis['constructiveness_score'] ?? 0.5);
          value /= 3.0;
        }
      } else if (metric == 'empathy_score') {
        final toneAnalysis = entry['tone_analysis'];
        if (toneAnalysis != null) {
          value = toneAnalysis['empathy_score'] ?? 0.5;
        }
      }

      total += value;
      count++;
    }

    return count > 0 ? total / count : 0.5;
  }

  /// Generate simulated partner data for demo purposes
  List<Map<String, dynamic>> _generateSimulatedPartnerData() {
    final random = Random();
    final now = DateTime.now();
    final data = <Map<String, dynamic>>[];

    // Generate 15-30 entries over the past month
    final entryCount = 15 + random.nextInt(16);

    for (int i = 0; i < entryCount; i++) {
      final timestamp = now.subtract(Duration(
        days: random.nextInt(30),
        hours: random.nextInt(24),
        minutes: random.nextInt(60),
      ));

      data.add({
        'timestamp': timestamp.toIso8601String(),
        'text_analyzed': 'Simulated partner message ${i + 1}',
        'tone_analysis': {
          'primary_tone': _getRandomTone(),
          'empathy_score': 0.6 + random.nextDouble() * 0.4,
          'clarity_score': 0.5 + random.nextDouble() * 0.5,
          'constructiveness_score': 0.7 + random.nextDouble() * 0.3,
          'emotional_indicators': _getRandomEmotionalIndicators(),
        },
        'attachment_analysis': {
          'primary_style': _getRandomAttachmentStyle(),
          'confidence': 0.7 + random.nextDouble() * 0.3,
          'secondary_traits': _getRandomSecondaryTraits(),
        },
        'coparenting_analysis': {
          'child_focus_score': 0.8 + random.nextDouble() * 0.2,
          'emotional_regulation_score': 0.6 + random.nextDouble() * 0.4,
          'constructiveness_score': 0.7 + random.nextDouble() * 0.3,
        },
        'predictive_analysis': {
          'success_probability': 0.7 + random.nextDouble() * 0.3,
          'risk_factors': _getRandomRiskFactors(),
        },
        'ai_suggestions': _getRandomAISuggestions(),
      });
    }

    return data;
  }

  String _getRandomTone() {
    final tones = [
      'supportive',
      'analytical',
      'empathetic',
      'confident',
      'gentle'
    ];
    return tones[Random().nextInt(tones.length)];
  }

  List<String> _getRandomEmotionalIndicators() {
    final indicators = [
      'caring',
      'supportive',
      'understanding',
      'patient',
      'loving'
    ];
    return indicators.take(2 + Random().nextInt(3)).toList();
  }

  String _getRandomAttachmentStyle() {
    final styles = ['Secure', 'Anxious', 'Avoidant', 'Disorganized'];
    return styles[Random().nextInt(styles.length)];
  }

  List<String> _getRandomSecondaryTraits() {
    final traits = ['empathetic', 'analytical', 'supportive', 'decisive'];
    return traits.take(1 + Random().nextInt(2)).toList();
  }

  List<String> _getRandomRiskFactors() {
    final factors = ['time_pressure', 'emotional_stress', 'communication_gap'];
    return factors.take(Random().nextInt(2)).toList();
  }

  List<String> _getRandomAISuggestions() {
    final suggestions = [
      'Consider expressing appreciation more frequently',
      'Try active listening techniques',
      'Focus on shared goals and values',
      'Practice empathy in responses',
    ];
    return suggestions.take(1 + Random().nextInt(2)).toList();
  }

  /// Simulate receiving new partner data (would be real-time in production)
  Future<void> simulatePartnerDataUpdate() async {
    if (!_hasPartner) return;

    final newEntry = _generateSimulatedPartnerData().first;
    _partnerAnalysisHistory.add(newEntry);
    await _savePartnerAnalysisHistory();
    notifyListeners();
  }
}
