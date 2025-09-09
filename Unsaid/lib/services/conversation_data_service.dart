import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'secure_storage_service.dart';

/// Service for managing conversation data and history
class ConversationDataService {
  static const String _conversationCollection = 'conversations';
  static const String _messageCollection = 'messages';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SecureStorageService _secureStorage = SecureStorageService();
  
  /// Get conversation history for analysis
  Future<List<Map<String, dynamic>>> getConversationHistory({
    String? userId,
    String? relationshipId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore.collection(_conversationCollection);
      
      // Apply filters
      if (userId != null) {
        query = query.where('user_id', isEqualTo: userId);
      }
      
      if (relationshipId != null) {
        query = query.where('relationship_id', isEqualTo: relationshipId);
      }
      
      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }
      
      // Order by timestamp and limit
      query = query.orderBy('timestamp', descending: true).limit(limit);
      
      final querySnapshot = await query.get();
      final conversations = <Map<String, dynamic>>[];
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        // Get messages for this conversation
        final messages = await _getMessagesForConversation(doc.id);
        data['messages'] = messages;
        
        conversations.add(data);
      }
      
      return conversations;
    } catch (e) {
      debugPrint('Error getting conversation history: $e');
      
      // For permission errors or when starting fresh, return empty list
      if (e.toString().contains('permission-denied') || 
          e.toString().contains('Missing or insufficient permissions')) {
        debugPrint('Firestore permissions issue - returning empty conversation history for new user');
        return [];
      }
      
      // For other errors, return mock data for development
      return _getMockConversationHistory();
    }
  }
  
  /// Get messages for a specific conversation
  Future<List<Map<String, dynamic>>> _getMessagesForConversation(String conversationId) async {
    try {
      final messagesSnapshot = await _firestore
          .collection(_conversationCollection)
          .doc(conversationId)
          .collection(_messageCollection)
          .orderBy('timestamp', descending: false)
          .get();
      
      return messagesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting messages for conversation: $e');
      return [];
    }
  }
  
  /// Store conversation data
  Future<void> storeConversation(Map<String, dynamic> conversationData) async {
    try {
      await _firestore.collection(_conversationCollection).add(conversationData);
    } catch (e) {
      debugPrint('Error storing conversation: $e');
      // Store locally as fallback
      await _storeConversationLocally(conversationData);
    }
  }
  
  /// Store message data
  Future<void> storeMessage(String conversationId, Map<String, dynamic> messageData) async {
    try {
      await _firestore
          .collection(_conversationCollection)
          .doc(conversationId)
          .collection(_messageCollection)
          .add(messageData);
    } catch (e) {
      debugPrint('Error storing message: $e');
      // Store locally as fallback
      await _storeMessageLocally(conversationId, messageData);
    }
  }
  
  /// Store conversation locally as fallback
  Future<void> _storeConversationLocally(Map<String, dynamic> conversationData) async {
    try {
      final localConversations = await _getLocalConversations();
      localConversations.add(conversationData);
      
      await _secureStorage.storeSecureJson('local_conversations', {
        'conversations': localConversations,
        'last_updated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error storing conversation locally: $e');
    }
  }
  
  /// Store message locally as fallback
  Future<void> _storeMessageLocally(String conversationId, Map<String, dynamic> messageData) async {
    try {
      final localMessages = await _getLocalMessages(conversationId);
      localMessages.add(messageData);
      
      await _secureStorage.storeSecureJson('local_messages_$conversationId', {
        'messages': localMessages,
        'last_updated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error storing message locally: $e');
    }
  }
  
  /// Get local conversations
  Future<List<Map<String, dynamic>>> _getLocalConversations() async {
    try {
      final data = await _secureStorage.getSecureJson('local_conversations');
      if (data != null && data['conversations'] != null) {
        return List<Map<String, dynamic>>.from(data['conversations']);
      }
      return [];
    } catch (e) {
      debugPrint('Error getting local conversations: $e');
      return [];
    }
  }
  
  /// Get local messages for a conversation
  Future<List<Map<String, dynamic>>> _getLocalMessages(String conversationId) async {
    try {
      final data = await _secureStorage.getSecureJson('local_messages_$conversationId');
      if (data != null && data['messages'] != null) {
        return List<Map<String, dynamic>>.from(data['messages']);
      }
      return [];
    } catch (e) {
      debugPrint('Error getting local messages: $e');
      return [];
    }
  }
  
  /// Get conversation statistics
  Future<Map<String, dynamic>> getConversationStats({
    String? userId,
    String? relationshipId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final conversations = await getConversationHistory(
        userId: userId,
        relationshipId: relationshipId,
        startDate: startDate,
        endDate: endDate,
      );
      
      int totalMessages = 0;
      int totalWords = 0;
      final emotionCounts = <String, int>{};
      
      for (final conversation in conversations) {
        final messages = conversation['messages'] as List<dynamic>? ?? [];
        totalMessages += messages.length;
        
        for (final message in messages) {
          final text = message['text'] as String? ?? '';
          totalWords += text.split(' ').length;
          
          // Count emotions from sentiment analysis
          final sentiment = message['sentiment'] as Map<String, dynamic>? ?? {};
          for (final emotion in sentiment.keys) {
            emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
          }
        }
      }
      
      return {
        'total_conversations': conversations.length,
        'total_messages': totalMessages,
        'total_words': totalWords,
        'average_messages_per_conversation': totalMessages / (conversations.length + 1),
        'emotion_counts': emotionCounts,
        'analysis_period': {
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        },
      };
    } catch (e) {
      debugPrint('Error getting conversation stats: $e');
      return _getDefaultStats();
    }
  }
  
  /// Get default stats for error cases
  Map<String, dynamic> _getDefaultStats() {
    return {
      'total_conversations': 0,
      'total_messages': 0,
      'total_words': 0,
      'average_messages_per_conversation': 0.0,
      'emotion_counts': {},
      'analysis_period': {
        'start_date': null,
        'end_date': null,
      },
    };
  }
  
  /// Get mock conversation history for development
  List<Map<String, dynamic>> _getMockConversationHistory() {
    return [
      {
        'id': 'conv_1',
        'user_id': 'user_123',
        'relationship_id': 'rel_456',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'messages': [
          {
            'id': 'msg_1',
            'text': 'I appreciate how you always listen to me when I need to talk.',
            'sender': 'user',
            'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            'sentiment': {
              'joy': 0.8,
              'sadness': 0.1,
              'anger': 0.0,
              'fear': 0.0,
              'surprise': 0.1,
              'disgust': 0.0,
            },
          },
          {
            'id': 'msg_2',
            'text': 'That means so much to me. I love being here for you.',
            'sender': 'partner',
            'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            'sentiment': {
              'joy': 0.9,
              'sadness': 0.0,
              'anger': 0.0,
              'fear': 0.0,
              'surprise': 0.0,
              'disgust': 0.1,
            },
          },
        ],
      },
      {
        'id': 'conv_2',
        'user_id': 'user_123',
        'relationship_id': 'rel_456',
        'timestamp': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        'messages': [
          {
            'id': 'msg_3',
            'text': 'I feel anxious when you don\'t respond quickly to my messages.',
            'sender': 'user',
            'timestamp': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
            'sentiment': {
              'joy': 0.0,
              'sadness': 0.3,
              'anger': 0.2,
              'fear': 0.5,
              'surprise': 0.0,
              'disgust': 0.0,
            },
          },
          {
            'id': 'msg_4',
            'text': 'I understand. I\'ll try to be more mindful of responding promptly.',
            'sender': 'partner',
            'timestamp': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
            'sentiment': {
              'joy': 0.2,
              'sadness': 0.1,
              'anger': 0.0,
              'fear': 0.0,
              'surprise': 0.0,
              'disgust': 0.0,
            },
          },
        ],
      },
    ];
  }
  
  /// Get conversations data
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      // Mock conversation data for now
      return [
        {
          'id': '1',
          'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'content': 'How was your day?',
          'empathy_score': 0.8,
          'clarity_score': 0.7,
          'tone': 'supportive',
        },
        {
          'id': '2',
          'timestamp': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'content': 'Can we talk about the schedule?',
          'empathy_score': 0.6,
          'clarity_score': 0.9,
          'tone': 'neutral',
        },
      ];
    } catch (e) {
      return [];
    }
  }
}
