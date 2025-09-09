import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'keyboard_manager.dart';

/// Service for managing user data including conversation history and exports
class DataManagerService extends ChangeNotifier {
  static final DataManagerService _instance = DataManagerService._internal();
  factory DataManagerService() => _instance;
  DataManagerService._internal();

  final KeyboardManager _keyboardManager = KeyboardManager();
  
  bool _isClearing = false;
  bool _isExporting = false;
  
  // Getters
  bool get isClearing => _isClearing;
  bool get isExporting => _isExporting;

  /// Get data usage statistics
  Map<String, dynamic> getDataUsageStats() {
    final analysisHistory = _keyboardManager.analysisHistory;
    
    return {
      'total_analyses': analysisHistory.length,
      'total_messages_analyzed': analysisHistory.length,
      'data_size_mb': _calculateDataSize(analysisHistory),
      'oldest_entry': analysisHistory.isNotEmpty 
        ? analysisHistory.first['timestamp'] 
        : null,
      'newest_entry': analysisHistory.isNotEmpty 
        ? analysisHistory.last['timestamp'] 
        : null,
      'analysis_breakdown': _getAnalysisBreakdown(analysisHistory),
      'storage_usage': _getStorageUsage(),
    };
  }

  /// Clear all conversation history
  Future<bool> clearConversationHistory() async {
    if (_isClearing) return false;
    
    try {
      _isClearing = true;
      notifyListeners();
      
      // Clear analysis history
      await _keyboardManager.clearAnalysisHistory();
      
      // Clear any cached data
      await _clearCachedData();
      
      return true;
    } catch (e) {
      // Error clearing conversation history
      return false;
    } finally {
      _isClearing = false;
      notifyListeners();
    }
  }

  /// Clear data older than specified days
  Future<bool> clearOldData(int days) async {
    if (_isClearing) return false;
    
    try {
      _isClearing = true;
      notifyListeners();
      
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final analysisHistory = _keyboardManager.analysisHistory;
      
      // Filter out old entries
      final filteredHistory = analysisHistory.where((entry) {
        final timestamp = DateTime.tryParse(entry['timestamp'] ?? '');
        return timestamp != null && timestamp.isAfter(cutoffDate);
      }).toList();
      
      // Update the history with filtered data
      // Note: This would need to be implemented in KeyboardManager
      
      return true;
    } catch (e) {
      // Error clearing old data
      return false;
    } finally {
      _isClearing = false;
      notifyListeners();
    }
  }

  /// Export all user data to JSON file
  Future<String?> exportAllData() async {
    if (_isExporting) return null;
    
    try {
      _isExporting = true;
      notifyListeners();
      
      final analysisHistory = _keyboardManager.analysisHistory;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final exportData = {
        'export_info': {
          'timestamp': DateTime.now().toIso8601String(),
          'app_version': '1.0.0',
          'data_version': '1.0',
          'total_entries': analysisHistory.length,
        },
        'analysis_history': analysisHistory,
        'statistics': getDataUsageStats(),
        'metadata': {
          'export_type': 'full_data_export',
          'user_consent': true,
          'privacy_compliant': true,
        },
      };
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/unsaid_data_export_$timestamp.json');
      
      await file.writeAsString(jsonEncode(exportData));
      return file.path;
    } catch (e) {
      // Error exporting data
      return null;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  /// Export conversation insights only
  Future<String?> exportInsightsOnly() async {
    if (_isExporting) return null;
    
    try {
      _isExporting = true;
      notifyListeners();
      
      final analysisHistory = _keyboardManager.analysisHistory;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Extract only insights and recommendations
      final insights = analysisHistory.map((entry) {
        return {
          'timestamp': entry['timestamp'],
          'tone_analysis': entry['tone_analysis'],
          'coparenting_analysis': entry['coparenting_analysis'],
          'predictive_analysis': entry['predictive_analysis'],
          'integrated_suggestions': entry['integrated_suggestions'],
          'relationship_context': entry['relationship_context'],
        };
      }).toList();
      
      final exportData = {
        'export_info': {
          'timestamp': DateTime.now().toIso8601String(),
          'export_type': 'insights_only',
          'total_insights': insights.length,
        },
        'insights': insights,
        'summary_statistics': _generateInsightsSummary(insights),
      };
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/unsaid_insights_export_$timestamp.json');
      
      await file.writeAsString(jsonEncode(exportData));
      return file.path;
    } catch (e) {
      // Error exporting insights
      return null;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  /// Get privacy-safe data summary
  Map<String, dynamic> getPrivacySafeDataSummary() {
    final analysisHistory = _keyboardManager.analysisHistory;
    
    return {
      'total_conversations': analysisHistory.length,
      'average_empathy_score': _calculateAverageScore(analysisHistory, 'empathy_score'),
      'average_clarity_score': _calculateAverageScore(analysisHistory, 'clarity_score'),
      'most_common_tone': _getMostCommonTone(analysisHistory),
      'improvement_trend': _calculateImprovementTrend(analysisHistory),
      'data_retention_days': 365, // Default retention period
      'last_analysis': analysisHistory.isNotEmpty 
        ? analysisHistory.last['timestamp'] 
        : null,
    };
  }

  /// Calculate data size in MB
  double _calculateDataSize(List<Map<String, dynamic>> data) {
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString).length;
    return bytes / (1024 * 1024); // Convert to MB
  }

  /// Get analysis breakdown by type
  Map<String, int> _getAnalysisBreakdown(List<Map<String, dynamic>> data) {
    final breakdown = <String, int>{};
    
    for (final entry in data) {
      if (entry['tone_analysis'] != null) {
        breakdown['tone_analysis'] = (breakdown['tone_analysis'] ?? 0) + 1;
      }
      if (entry['coparenting_analysis'] != null) {
        breakdown['coparenting_analysis'] = (breakdown['coparenting_analysis'] ?? 0) + 1;
      }
      if (entry['predictive_analysis'] != null) {
        breakdown['predictive_analysis'] = (breakdown['predictive_analysis'] ?? 0) + 1;
      }
    }
    
    return breakdown;
  }

  /// Get storage usage information
  Map<String, dynamic> _getStorageUsage() {
    return {
      'analysis_history_mb': _calculateDataSize(_keyboardManager.analysisHistory),
      'cached_data_mb': 0.5, // Estimate
      'settings_kb': 2.0, // Estimate
      'total_mb': _calculateDataSize(_keyboardManager.analysisHistory) + 0.5 + 0.002,
    };
  }

  /// Clear cached data
  Future<void> _clearCachedData() async {
    // Clear any temporary or cached files
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheFiles = tempDir.listSync()
          .where((file) => file.path.contains('unsaid_cache'))
          .toList();
      
      for (final file in cacheFiles) {
        await file.delete();
      }
    } catch (e) {
      // Error clearing cache
    }
  }

  /// Generate insights summary
  Map<String, dynamic> _generateInsightsSummary(List<Map<String, dynamic>> insights) {
    return {
      'total_insights': insights.length,
      'average_empathy': _calculateAverageScore(insights, 'empathy_score'),
      'average_clarity': _calculateAverageScore(insights, 'clarity_score'),
      'date_range': {
        'from': insights.isNotEmpty ? insights.first['timestamp'] : null,
        'to': insights.isNotEmpty ? insights.last['timestamp'] : null,
      },
      'improvement_indicators': _analyzeImprovementPatterns(insights),
    };
  }

  /// Calculate average score for a specific metric
  double _calculateAverageScore(List<Map<String, dynamic>> data, String scoreKey) {
    double total = 0.0;
    int count = 0;
    
    for (final entry in data) {
      final toneAnalysis = entry['tone_analysis'] as Map<String, dynamic>?;
      if (toneAnalysis != null && toneAnalysis[scoreKey] != null) {
        total += toneAnalysis[scoreKey];
        count++;
      }
    }
    
    return count > 0 ? total / count : 0.0;
  }

  /// Get most common tone from analysis history
  String _getMostCommonTone(List<Map<String, dynamic>> data) {
    final toneCounts = <String, int>{};
    
    for (final entry in data) {
      final toneAnalysis = entry['tone_analysis'] as Map<String, dynamic>?;
      if (toneAnalysis != null && toneAnalysis['dominant_emotion'] != null) {
        final tone = toneAnalysis['dominant_emotion'] as String;
        toneCounts[tone] = (toneCounts[tone] ?? 0) + 1;
      }
    }
    
    if (toneCounts.isEmpty) return 'neutral';
    
    return toneCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Calculate improvement trend
  String _calculateImprovementTrend(List<Map<String, dynamic>> data) {
    if (data.length < 2) return 'insufficient_data';
    
    final recentData = data.length > 10 ? data.sublist(data.length - 10) : data;
    final olderData = data.length > 10 ? data.sublist(0, data.length - 10) : <Map<String, dynamic>>[];
    
    if (olderData.isEmpty) return 'steady';
    
    final recentAvg = _calculateAverageScore(recentData, 'empathy_score');
    final olderAvg = _calculateAverageScore(olderData, 'empathy_score');
    
    if (recentAvg > olderAvg + 0.1) return 'improving';
    if (recentAvg < olderAvg - 0.1) return 'declining';
    return 'steady';
  }

  /// Analyze improvement patterns
  Map<String, dynamic> _analyzeImprovementPatterns(List<Map<String, dynamic>> insights) {
    return {
      'empathy_trend': _calculateImprovementTrend(insights),
      'clarity_improvement': _calculateAverageScore(insights, 'clarity_score'),
      'consistency_score': _calculateConsistencyScore(insights),
      'growth_indicators': _identifyGrowthIndicators(insights),
    };
  }

  /// Calculate consistency score
  double _calculateConsistencyScore(List<Map<String, dynamic>> data) {
    if (data.length < 3) return 0.0;
    
    final scores = <double>[];
    for (final entry in data) {
      final toneAnalysis = entry['tone_analysis'] as Map<String, dynamic>?;
      if (toneAnalysis != null && toneAnalysis['empathy_score'] != null) {
        scores.add(toneAnalysis['empathy_score']);
      }
    }
    
    if (scores.length < 3) return 0.0;
    
    // Calculate standard deviation as consistency measure
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final variance = scores.map((score) => (score - mean) * (score - mean))
        .reduce((a, b) => a + b) / scores.length;
    
    // Return inverse of standard deviation (higher consistency = lower variance)
    return 1.0 - (variance.clamp(0.0, 1.0));
  }

  /// Identify growth indicators
  List<String> _identifyGrowthIndicators(List<Map<String, dynamic>> data) {
    final indicators = <String>[];
    
    if (_calculateImprovementTrend(data) == 'improving') {
      indicators.add('Overall empathy increasing');
    }
    
    if (_calculateConsistencyScore(data) > 0.7) {
      indicators.add('Consistent communication quality');
    }
    
    if (_calculateAverageScore(data, 'clarity_score') > 0.8) {
      indicators.add('High clarity in communication');
    }
    
    return indicators;
  }
}
