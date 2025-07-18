import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';

/// Feedback collection service for beta users
/// Collects user feedback, bug reports, and feature requests
class FeedbackService {
  static FeedbackService? _instance;
  static FeedbackService get instance => _instance ??= FeedbackService._();
  FeedbackService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submit user feedback
  Future<bool> submitFeedback({
    required String type, // 'bug', 'feature', 'general', 'rating'
    required String title,
    required String description,
    int? rating, // 1-5 stars
    String? category, // 'ui', 'performance', 'accuracy', 'feature'
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final User? user = AuthService.instance.user;
      if (user == null) {
        if (kDebugMode) {
          print('❌ Cannot submit feedback: user not authenticated');
        }
        return false;
      }

      final Map<String, dynamic> feedbackData = {
        'userId': user.uid,
        'isAnonymous': user.isAnonymous,
        'type': type,
        'title': title,
        'description': description,
        'rating': rating,
        'category': category,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'new',
        'deviceInfo': await _getDeviceInfo(),
        'appVersion': await _getAppVersion(),
      };

      await _firestore.collection('feedback').add(feedbackData);

      if (kDebugMode) {
        print('✅ Feedback submitted successfully: $type');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error submitting feedback: $e');
      }
      return false;
    }
  }

  /// Submit bug report with detailed information
  Future<bool> submitBugReport({
    required String title,
    required String description,
    required String stepsToReproduce,
    String? expectedBehavior,
    String? actualBehavior,
    String? severity, // 'low', 'medium', 'high', 'critical'
    List<String>? screenshots,
  }) async {
    return await submitFeedback(
      type: 'bug',
      title: title,
      description: description,
      category: 'bug',
      metadata: {
        'stepsToReproduce': stepsToReproduce,
        'expectedBehavior': expectedBehavior,
        'actualBehavior': actualBehavior,
        'severity': severity,
        'screenshots': screenshots ?? [],
        'userAgent': await _getUserAgent(),
        'stackTrace': null, // Could be populated if error occurs
      },
    );
  }

  /// Submit feature request
  Future<bool> submitFeatureRequest({
    required String title,
    required String description,
    String? useCase,
    String? priority, // 'low', 'medium', 'high'
    List<String>? tags,
  }) async {
    return await submitFeedback(
      type: 'feature',
      title: title,
      description: description,
      category: 'feature',
      metadata: {'useCase': useCase, 'priority': priority, 'tags': tags ?? []},
    );
  }

  /// Submit app rating and review
  Future<bool> submitRating({
    required int rating, // 1-5
    String? review,
    String? category, // 'overall', 'accuracy', 'ui', 'performance'
  }) async {
    return await submitFeedback(
      type: 'rating',
      title: 'App Rating',
      description: review ?? '',
      rating: rating,
      category: category ?? 'overall',
    );
  }

  /// Get user's previous feedback
  Future<List<Map<String, dynamic>>> getUserFeedback() async {
    try {
      final User? user = AuthService.instance.user;
      if (user == null) return [];

      final QuerySnapshot snapshot = await _firestore
          .collection('feedback')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user feedback: $e');
      }
      return [];
    }
  }

  /// Get feedback statistics for the app
  Future<Map<String, dynamic>> getFeedbackStats() async {
    try {
      // Get overall rating
      final QuerySnapshot ratingSnapshot = await _firestore
          .collection('feedback')
          .where('type', isEqualTo: 'rating')
          .get();

      double averageRating = 0.0;
      int totalRatings = 0;
      Map<int, int> ratingDistribution = {};

      for (final doc in ratingSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final int? rating = data['rating'];
        if (rating != null) {
          averageRating += rating;
          totalRatings++;
          ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
        }
      }

      if (totalRatings > 0) {
        averageRating /= totalRatings;
      }

      // Get feedback counts by type
      final QuerySnapshot allFeedback = await _firestore
          .collection('feedback')
          .get();

      Map<String, int> feedbackByType = {};
      Map<String, int> feedbackByCategory = {};

      for (final doc in allFeedback.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String type = data['type'] ?? 'unknown';
        final String category = data['category'] ?? 'unknown';

        feedbackByType[type] = (feedbackByType[type] ?? 0) + 1;
        feedbackByCategory[category] = (feedbackByCategory[category] ?? 0) + 1;
      }

      return {
        'averageRating': averageRating,
        'totalRatings': totalRatings,
        'ratingDistribution': ratingDistribution,
        'feedbackByType': feedbackByType,
        'feedbackByCategory': feedbackByCategory,
        'totalFeedback': allFeedback.size,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting feedback stats: $e');
      }
      return {};
    }
  }

  /// Check if user should be prompted for feedback
  Future<bool> shouldPromptForFeedback() async {
    try {
      final User? user = AuthService.instance.user;
      if (user == null) return false;

      // Check if user has submitted feedback recently
      final DateTime oneWeekAgo = DateTime.now().subtract(
        const Duration(days: 7),
      );

      final QuerySnapshot recentFeedback = await _firestore
          .collection('feedback')
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThan: oneWeekAgo)
          .limit(1)
          .get();

      // Don't prompt if user has given feedback in the last week
      if (recentFeedback.docs.isNotEmpty) {
        return false;
      }

      // Check usage level to determine if appropriate to ask
      // (This would integrate with UsageTrackingService)
      // For now, return true if no recent feedback
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking feedback prompt: $e');
      }
      return false;
    }
  }

  /// Get device information for debugging
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      // This would typically use device_info_plus package
      // For now, return basic info
      return {
        'platform': defaultTargetPlatform.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'error': 'Unable to get device info'};
    }
  }

  /// Get app version information
  Future<String> _getAppVersion() async {
    try {
      // This would typically use package_info_plus
      // For now, return placeholder
      return '1.0.0+1';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Get user agent string
  Future<String> _getUserAgent() async {
    try {
      // This would typically get browser user agent or device info
      return 'UnsaidApp/1.0.0';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Submit crash report
  Future<bool> submitCrashReport({
    required String error,
    required String stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    return await submitFeedback(
      type: 'crash',
      title: 'App Crash',
      description: error,
      category: 'crash',
      metadata: {
        'stackTrace': stackTrace,
        'context': context,
        'additionalData': additionalData ?? {},
        'automaticReport': true,
      },
    );
  }

  /// Get trending feedback topics
  Future<List<String>> getTrendingTopics() async {
    try {
      final DateTime lastWeek = DateTime.now().subtract(
        const Duration(days: 7),
      );

      final QuerySnapshot snapshot = await _firestore
          .collection('feedback')
          .where('timestamp', isGreaterThan: lastWeek)
          .get();

      Map<String, int> topicCounts = {};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String category = data['category'] ?? 'general';
        topicCounts[category] = (topicCounts[category] ?? 0) + 1;
      }

      // Sort by count and return top topics
      final List<MapEntry<String, int>> sortedTopics =
          topicCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      return sortedTopics.take(5).map((entry) => entry.key).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting trending topics: $e');
      }
      return [];
    }
  }
}
