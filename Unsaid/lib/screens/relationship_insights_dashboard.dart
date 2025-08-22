import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'relationship_couple_goals.dart';
import '../services/keyboard_manager.dart';
import '../services/relationship_insights_service.dart';
import '../services/personality_driven_analyzer.dart';
import '../services/secure_communication_progress_service.dart';
import '../services/secure_storage_service.dart';
import '../services/unified_analytics_service.dart';
import '../services/new_user_experience_service.dart';
import '../services/partner_data_service.dart';
import '../services/conversation_data_service.dart';
import '../services/usage_tracking_service.dart';
import 'secure_couple_tips.dart';

// MARK: - Shared Utilities
class RelationshipInsightsUtils {
  static Color getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  static String getScoreDescription(double score) {
    if (score >= 0.8) return 'Excellent';
    if (score >= 0.6) return 'Good';
    if (score >= 0.4) return 'Fair';
    return 'Needs Attention';
  }

  static const TextStyle chartTitleStyle = TextStyle(
    fontSize: 12, 
    fontWeight: FontWeight.bold, 
    color: Colors.white,
  );

  static TextStyle boldTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    ) ?? const TextStyle(fontWeight: FontWeight.bold);
  }
}

// MARK: - Attachment Lens Component
class AttachmentLensWidget extends StatelessWidget {
  final String attachmentStyle;
  final String communicationStyle;
  final String context;
  final VoidCallback? onTap;

  const AttachmentLensWidget({
    super.key,
    required this.attachmentStyle,
    required this.communicationStyle,
    required this.context,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap ?? () => _showAttachmentLensModal(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.psychology,
              size: 14,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Attachment Lens: ${_formatAttachmentStyle(attachmentStyle)} · ${_formatCommunicationStyle(communicationStyle)}',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAttachmentStyle(String style) {
    switch (style.toLowerCase()) {
      case 'anxious':
        return 'Anxious';
      case 'avoidant':
        return 'Dismissive-Avoidant';
      case 'disorganized':
        return 'Fearful-Avoidant';
      case 'secure':
        return 'Secure';
      default:
        return style;
    }
  }

  String _formatCommunicationStyle(String style) {
    return style.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  void _showAttachmentLensModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AttachmentLensModal(
        attachmentStyle: attachmentStyle,
        communicationStyle: communicationStyle,
        context: this.context,
      ),
    );
  }
}

// MARK: - Attachment Lens Modal
class AttachmentLensModal extends StatelessWidget {
  final String attachmentStyle;
  final String communicationStyle;
  final String context;

  const AttachmentLensModal({
    super.key,
    required this.attachmentStyle,
    required this.communicationStyle,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final insights = _getPersonalizedInsights();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Header
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Your Attachment Lens',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Attachment type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_formatAttachmentStyle(attachmentStyle)} · ${_formatCommunicationStyle(communicationStyle)}',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Insights
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        insight['icon'],
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        insight['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    insight['description'],
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
          
          const SizedBox(height: 20),
          
          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Got it'),
            ),
          ),
          
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  String _formatAttachmentStyle(String style) {
    switch (style.toLowerCase()) {
      case 'anxious':
        return 'Anxious-Preoccupied';
      case 'avoidant':
        return 'Dismissive-Avoidant';
      case 'disorganized':
        return 'Fearful-Avoidant';
      case 'secure':
        return 'Secure';
      default:
        return style;
    }
  }

  String _formatCommunicationStyle(String style) {
    return style.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  List<Map<String, dynamic>> _getPersonalizedInsights() {
    final insights = <Map<String, dynamic>>[];

    // Generate insights based on attachment style and communication patterns
    if (attachmentStyle.toLowerCase() == 'avoidant') {
      insights.addAll([
        {
          'icon': Icons.favorite_outline,
          'title': 'When Overwhelmed',
          'description': 'You tend to keep messages short and withdraw. Try adding one validating line before ending the conversation: "I care about this, I just need a moment to process."'
        },
        {
          'icon': Icons.chat_bubble_outline,
          'title': 'Connection Strategy',
          'description': 'Your independence is valuable, but small gestures of emotional availability can strengthen your bond without feeling overwhelming.'
        },
      ]);
    } else if (attachmentStyle.toLowerCase() == 'anxious') {
      insights.addAll([
        {
          'icon': Icons.schedule,
          'title': 'When Worried',
          'description': 'You may send longer messages seeking reassurance. Try stating your need clearly: "I\'m feeling uncertain and would love to hear that we\'re okay."'
        },
        {
          'icon': Icons.self_improvement,
          'title': 'Self-Soothing',
          'description': 'Before sending that third follow-up, take a breath. Your partner\'s delayed response usually isn\'t about you.'
        },
      ]);
    } else if (attachmentStyle.toLowerCase() == 'disorganized') {
      insights.addAll([
        {
          'icon': Icons.balance,
          'title': 'Mixed Signals',
          'description': 'You might alternate between seeking closeness and creating distance. Acknowledging this pattern can help: "I\'m feeling conflicted right now."'
        },
        {
          'icon': Icons.healing,
          'title': 'Safety First',
          'description': 'Grounding techniques before difficult conversations can help you stay present: "Let me take a moment to center myself."'
        },
      ]);
    } else { // secure
      insights.addAll([
        {
          'icon': Icons.emoji_emotions,
          'title': 'Your Strength',
          'description': 'Your natural ability to communicate needs and stay emotionally regulated is a gift to your relationship.'
        },
        {
          'icon': Icons.support,
          'title': 'Supporting Growth',
          'description': 'You can help model healthy communication patterns while being patient with your partner\'s attachment style.'
        },
      ]);
    }

    // Add communication style insights
    if (communicationStyle.toLowerCase().contains('direct')) {
      insights.add({
        'icon': Icons.straighten,
        'title': 'Direct Communication',
        'description': 'Your clarity is helpful, but softening with empathy can prevent defensiveness: "I notice..." instead of "You always..."'
      });
    } else if (communicationStyle.toLowerCase().contains('gentle')) {
      insights.add({
        'icon': Icons.spa,
        'title': 'Gentle Approach',
        'description': 'Your considerate style creates safety. Don\'t forget to also express your own needs clearly.'
      });
    }

    return insights;
  }
}

// MARK: - Conflict Heatmap Widget
class ConflictHeatmap extends StatelessWidget {
  final List<Map<String, dynamic>> analyses;

  const ConflictHeatmap({super.key, required this.analyses});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Build 7x24 matrix of scores 0..1
    final matrix = List.generate(7, (_) => List.filled(24, 0.0));
    final counts = List.generate(7, (_) => List.filled(24, 0));
    
    for (final analysis in analyses) {
      final timestamp = analysis['timestamp'] as String?;
      final DateTime? dateTime = timestamp != null ? DateTime.tryParse(timestamp) : null;
      
      if (dateTime != null) {
        final day = dateTime.weekday % 7; // 0..6
        final hour = dateTime.hour;
        final tone = (analysis['tone_status'] ?? 'neutral') as String;
        
        // Assign conflict scores: alert=1.0, caution=0.6, neutral/clear=0.2
        final conflictValue = switch (tone) {
          'alert' => 1.0,
          'caution' => 0.6,
          _ => 0.2,
        };
        
        if (day >= 0 && day < 7 && hour >= 0 && hour < 24) {
          matrix[day][hour] += conflictValue;
          counts[day][hour] += 1;
        }
      }
    }
    
    // Average the scores
    for (var d = 0; d < 7; d++) {
      for (var h = 0; h < 24; h++) {
        if (counts[d][h] > 0) {
          matrix[d][h] /= counts[d][h];
        }
      }
    }

    Color getCellColor(double value) {
      if (value >= 0.8) return Colors.red.shade400;
      if (value >= 0.5) return Colors.orange.shade400;
      if (value > 0.2) return Colors.green.shade300;
      return colorScheme.surfaceVariant.withOpacity(0.3);
    }

    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grid_on, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Conflict Heatmap',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tension patterns by day and time',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            
            // Time labels (hours)
            Row(
              children: [
                const SizedBox(width: 40), // Space for day labels
                Expanded(
                  child: Row(
                    children: List.generate(6, (index) {
                      final hour = index * 4; // Show every 4 hours
                      return Expanded(
                        child: Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: Theme.of(context).textTheme.labelSmall,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // Heatmap grid
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  // Day labels
                  SizedBox(
                    width: 40,
                    child: Column(
                      children: dayLabels.map((day) => Expanded(
                        child: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            day,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                  
                  // Grid
                  Expanded(
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 24,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 1,
                        mainAxisSpacing: 1,
                      ),
                      itemCount: 7 * 24,
                      itemBuilder: (context, index) {
                        final day = index ~/ 24;
                        final hour = index % 24;
                        final value = matrix[day][hour];
                        
                        return GestureDetector(
                          onTap: () => _showHeatmapDetail(context, day, hour, value),
                          child: Container(
                            decoration: BoxDecoration(
                              color: getCellColor(value),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Legend
            Row(
              children: [
                Text(
                  'Low tension',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(width: 8),
                Container(width: 12, height: 12, color: Colors.green.shade300),
                const Spacer(),
                Container(width: 12, height: 12, color: Colors.orange.shade400),
                const SizedBox(width: 8),
                Container(width: 12, height: 12, color: Colors.red.shade400),
                const SizedBox(width: 8),
                Text(
                  'High tension',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            
            if (_getBestWorstTimes(matrix).isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Insight',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getBestWorstTimes(matrix),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showHeatmapDetail(BuildContext context, int day, int hour, double value) {
    final dayLabels = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${dayLabels[day]} ${displayHour}:00 $period'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tension Level: ${_getTensionDescription(value)}'),
            const SizedBox(height: 8),
            if (value > 0.6)
              const Text(
                '💡 Consider avoiding heavy topics during this time',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getTensionDescription(double value) {
    if (value >= 0.8) return 'High';
    if (value >= 0.5) return 'Moderate';
    if (value > 0.2) return 'Low';
    return 'Minimal';
  }

  String _getBestWorstTimes(List<List<double>> matrix) {
    double maxValue = 0;
    double minValue = 1;
    int worstDay = -1, worstHour = -1;
    int bestDay = -1, bestHour = -1;
    
    for (var d = 0; d < 7; d++) {
      for (var h = 0; h < 24; h++) {
        if (matrix[d][h] > maxValue) {
          maxValue = matrix[d][h];
          worstDay = d;
          worstHour = h;
        }
        if (matrix[d][h] > 0 && matrix[d][h] < minValue) {
          minValue = matrix[d][h];
          bestDay = d;
          bestHour = h;
        }
      }
    }
    
    if (worstDay == -1 || bestDay == -1) return '';
    
    final dayLabels = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final worstPeriod = worstHour < 12 ? 'morning' : (worstHour < 18 ? 'afternoon' : 'evening');
    final bestPeriod = bestHour < 12 ? 'morning' : (bestHour < 18 ? 'afternoon' : 'evening');
    
    return 'Your best communication time: ${dayLabels[bestDay]} ${bestPeriod}. '
           'Consider postponing difficult conversations from ${dayLabels[worstDay]} ${worstPeriod}.';
  }
}

// MARK: - Rupture-Repair Tracker
class RuptureRepairTracker extends StatelessWidget {
  final List<Map<String, dynamic>> analyses;

  const RuptureRepairTracker({super.key, required this.analyses});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final repairData = _calculateRepairMetrics();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.healing, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Rupture & Repair Tracker',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'How well do you recover from tense moments?',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Repair Rate Gauge
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Repair Rate',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${(repairData['repairRate'] * 100).toInt()}%',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: _getRepairRateColor(repairData['repairRate']),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _getRepairRateIcon(repairData['repairRate']),
                            color: _getRepairRateColor(repairData['repairRate']),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRepairRateDescription(repairData['repairRate']),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 80,
                    child: CircularProgressIndicator(
                      value: repairData['repairRate'],
                      strokeWidth: 8,
                      backgroundColor: colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getRepairRateColor(repairData['repairRate']),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Weekly breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'This Week',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${repairData['weeklyRuptures']} ruptures, ${repairData['weeklyRepairs']} repairs',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: repairData['weeklyRuptures'] > 0 ? 
                           repairData['weeklyRepairs'] / repairData['weeklyRuptures'] : 0,
                    backgroundColor: colorScheme.errorContainer,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Coaching tip
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Repair Micro-Habit',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getRepairCoachingTip(repairData['repairRate']),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            if (repairData['recentRuptures'].isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Recent Ruptures',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...repairData['recentRuptures'].take(3).map<Widget>((rupture) => 
                _buildRuptureItem(context, rupture)
              ).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateRepairMetrics() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    final recentAnalyses = analyses.where((analysis) {
      final timestamp = analysis['timestamp'] as String?;
      if (timestamp == null) return false;
      final dateTime = DateTime.tryParse(timestamp);
      return dateTime != null && dateTime.isAfter(weekAgo);
    }).toList();

    // Identify ruptures (alert/caution tones)
    final ruptures = recentAnalyses.where((analysis) {
      final tone = analysis['tone_status'] as String? ?? 'neutral';
      return tone == 'alert' || tone == 'caution';
    }).toList();

    // Simple repair detection: look for neutral/clear tones within 24h after ruptures
    int repairCount = 0;
    final recentRuptures = <Map<String, dynamic>>[];

    for (final rupture in ruptures) {
      final ruptureTime = DateTime.tryParse(rupture['timestamp'] as String? ?? '');
      if (ruptureTime == null) continue;

      recentRuptures.add({
        'timestamp': ruptureTime,
        'tone': rupture['tone_status'],
        'text': rupture['text'] ?? 'No text available',
        'repaired': false,
      });

      // Look for repairs within 24 hours
      final repairWindow = ruptureTime.add(const Duration(hours: 24));
      final hasRepair = recentAnalyses.any((analysis) {
        final analysisTime = DateTime.tryParse(analysis['timestamp'] as String? ?? '');
        if (analysisTime == null) return false;
        
        final tone = analysis['tone_status'] as String? ?? 'neutral';
        return analysisTime.isAfter(ruptureTime) && 
               analysisTime.isBefore(repairWindow) &&
               (tone == 'neutral' || tone == 'clear') &&
               _isRepairAttempt(analysis['text'] as String? ?? '');
      });

      if (hasRepair) {
        repairCount++;
        recentRuptures.last['repaired'] = true;
      }
    }

    final repairRate = ruptures.isEmpty ? 0.0 : repairCount / ruptures.length;

    return {
      'repairRate': repairRate,
      'weeklyRuptures': ruptures.length,
      'weeklyRepairs': repairCount,
      'recentRuptures': recentRuptures.reversed.toList(),
    };
  }

  bool _isRepairAttempt(String text) {
    final repairKeywords = [
      'sorry', 'apologize', 'my fault', 'i was wrong', 'understand', 
      'see your point', 'appreciate', 'thank you', 'love you',
      'can we', 'let\'s try', 'want to understand', 'help me understand'
    ];
    
    final lowerText = text.toLowerCase();
    return repairKeywords.any((keyword) => lowerText.contains(keyword));
  }

  Color _getRepairRateColor(double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.6) return Colors.orange;
    return Colors.red;
  }

  IconData _getRepairRateIcon(double rate) {
    if (rate >= 0.8) return Icons.emoji_emotions;
    if (rate >= 0.6) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }

  String _getRepairRateDescription(double rate) {
    if (rate >= 0.8) return 'Excellent recovery';
    if (rate >= 0.6) return 'Good resilience';
    if (rate >= 0.4) return 'Room for improvement';
    return 'Focus on repair skills';
  }

  String _getRepairCoachingTip(double rate) {
    if (rate >= 0.8) {
      return 'You\'re great at bouncing back! Keep modeling healthy repair for your relationship.';
    } else if (rate >= 0.6) {
      return 'When you notice tension (⚠️), try: "I want to understand—can we rewind and try that again?"';
    } else {
      return 'Next time you see ⚠️, pause and try a repair micro-habit: "I care about this conversation. Can we slow down?"';
    }
  }

  Widget _buildRuptureItem(BuildContext context, Map<String, dynamic> rupture) {
    final colorScheme = Theme.of(context).colorScheme;
    final isRepaired = rupture['repaired'] as bool;
    final tone = rupture['tone'] as String;
    final timestamp = rupture['timestamp'] as DateTime;
    final text = rupture['text'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isRepaired ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isRepaired ? Icons.check_circle_outline : Icons.warning_outlined,
            size: 16,
            color: isRepaired ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatDate(timestamp)} - ${tone.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text.length > 50 ? '${text.substring(0, 50)}...' : text,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isRepaired)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Repaired',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${date.month}/${date.day}';
  }
}

// MARK: - Micro-Habits Experiments
class MicroHabitsExperiment extends StatefulWidget {
  final List<Map<String, dynamic>> analyses;

  const MicroHabitsExperiment({super.key, required this.analyses});

  @override
  State<MicroHabitsExperiment> createState() => _MicroHabitsExperimentState();
}

class _MicroHabitsExperimentState extends State<MicroHabitsExperiment> {
  String? selectedExperiment;
  bool experimentStarted = false;
  int currentDay = 1;
  int completedUses = 0;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentExperiment();
  }

  Future<void> _loadCurrentExperiment() async {
    final storage = SecureStorageService();
    final savedExperiment = await storage.getString('current_micro_habit_experiment');
    final savedDay = await storage.getString('micro_habit_day');
    final savedUses = await storage.getString('micro_habit_completed_uses');
    
    if (savedExperiment != null && mounted) {
      setState(() {
        selectedExperiment = savedExperiment;
        experimentStarted = true;
        currentDay = int.tryParse(savedDay ?? '1') ?? 1;
        completedUses = int.tryParse(savedUses ?? '0') ?? 0;
      });
    }
  }

  Future<void> _startExperiment() async {
    if (selectedExperiment == null) return;
    
    final storage = SecureStorageService();
    await storage.setString('current_micro_habit_experiment', selectedExperiment!);
    await storage.setString('micro_habit_day', '1');
    await storage.setString('micro_habit_completed_uses', '0');
    await storage.setString('micro_habit_start_date', DateTime.now().toIso8601String());
    
    setState(() {
      experimentStarted = true;
      currentDay = 1;
      completedUses = 0;
    });
  }

  Future<void> _logExperimentUse(bool successful) async {
    final storage = SecureStorageService();
    final analytics = UnifiedAnalyticsService();
    
    if (successful) {
      completedUses++;
      await storage.setString('micro_habit_completed_uses', completedUses.toString());
      
      // Log to analytics
      await analytics.logEvent('micro_habit_success', {
        'experiment_type': selectedExperiment,
        'day': currentDay,
        'total_uses': completedUses,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } else {
      // Log missed opportunity
      await analytics.logEvent('micro_habit_missed', {
        'experiment_type': selectedExperiment,
        'day': currentDay,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
    
    // Update daily progress
    await _updateDailyProgress();
    
    setState(() {});
  }

  Future<void> _updateDailyProgress() async {
    final storage = SecureStorageService();
    final startDateStr = await storage.getString('micro_habit_start_date');
    
    if (startDateStr != null) {
      final startDate = DateTime.parse(startDateStr);
      final daysSinceStart = DateTime.now().difference(startDate).inDays + 1;
      
      setState(() {
        currentDay = daysSinceStart.clamp(1, 7);
      });
      
      await storage.setString('micro_habit_day', currentDay.toString());
      
      // Check if experiment is complete
      if (currentDay >= 7) {
        await _completeExperiment();
      }
    }
  }

  Future<void> _completeExperiment() async {
    final storage = SecureStorageService();
    final analytics = UnifiedAnalyticsService();
    
    // Log completion
    await analytics.logEvent('micro_habit_completed', {
      'experiment_type': selectedExperiment,
      'total_uses': completedUses,
      'success_rate': completedUses / 7, // Assuming daily target
      'completion_date': DateTime.now().toIso8601String(),
    });
    
    // Clear current experiment
    await storage.removeKey('current_micro_habit_experiment');
    await storage.removeKey('micro_habit_day');
    await storage.removeKey('micro_habit_completed_uses');
    await storage.removeKey('micro_habit_start_date');
    
    setState(() {
      experimentStarted = false;
      selectedExperiment = null;
      currentDay = 1;
      completedUses = 0;
    });
    
    // Show completion dialog
    if (mounted) {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Experiment Complete!'),
        content: Text(
          'Congratulations! You completed the ${experiments[selectedExperiment]!['title']} experiment.\n\n'
          'Success rate: ${(completedUses / 7 * 100).round()}%\n\n'
          'Ready to try another micro-habit?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Choose New Experiment'),
          ),
        ],
      ),
    );
  }

  final Map<String, Map<String, dynamic>> experiments = {
    'pause_before_react': {
      'title': '3-Second Pause',
      'description': 'Take 3 deep breaths before responding to tense messages',
      'icon': Icons.pause_circle_outline,
      'commitment': '7 days',
      'tracking': 'Track: Did I pause before responding?',
      'science': 'Activates prefrontal cortex, reduces reactive responses by 40%',
    },
    'appreciation_sandwich': {
      'title': 'Appreciation Sandwich',
      'description': 'Start difficult conversations with something you appreciate',
      'icon': Icons.favorite_outline,
      'commitment': '5 conversations',
      'tracking': 'Track: Did I start with appreciation?',
      'science': 'Positive priming increases receptivity to feedback by 60%',
    },
    'repair_phrase': {
      'title': 'Magic Repair Phrase',
      'description': 'Use "Help me understand..." when you feel defensive',
      'icon': Icons.build_outlined,
      'commitment': '3 uses',
      'tracking': 'Track: Did I use repair phrase when triggered?',
      'science': 'Curiosity language reduces defensive responses by 50%',
    },
    'tone_check': {
      'title': 'Tone Check-In',
      'description': 'Ask "How did that land?" after important messages',
      'icon': Icons.feedback_outlined,
      'commitment': '7 days',
      'tracking': 'Track: Did I check in about my tone?',
      'science': 'Meta-communication reduces misunderstandings by 35%',
    },
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Micro-Habits Lab',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tiny experiments. Big relationship changes.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            if (!experimentStarted) ...[
              // Experiment selection
              Text(
                'Choose Your Next Experiment',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...experiments.entries.map((entry) => 
                _buildExperimentOption(context, entry.key, entry.value)
              ).toList(),
              const SizedBox(height: 16),
              if (selectedExperiment != null)
                ElevatedButton(
                  onPressed: () async {
                    await _startExperiment();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  child: Text(
                    'Start ${experiments[selectedExperiment]!['commitment']} Experiment',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ] else ...[
              // Active experiment tracking
              _buildActiveExperiment(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExperimentOption(BuildContext context, String key, Map<String, dynamic> experiment) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selectedExperiment == key;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedExperiment = key;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
            ? colorScheme.primaryContainer.withOpacity(0.5)
            : colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? colorScheme.primary 
              : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  experiment['icon'] as IconData,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    experiment['title'] as String,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              experiment['description'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    experiment['commitment'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    experiment['science'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveExperiment(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final experiment = experiments[selectedExperiment]!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withOpacity(0.1),
                colorScheme.primaryContainer.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    experiment['icon'] as IconData,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Active: ${experiment['title']}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Day $currentDay of 7',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                experiment['description'] as String,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                experiment['tracking'] as String,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Progress tracking
        Text(
          'This Week\'s Progress',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        Row(
          children: List.generate(7, (index) {
            final isComplete = index < currentDay; 
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 6 ? 4 : 0),
                height: 8,
                decoration: BoxDecoration(
                  color: isComplete 
                    ? colorScheme.primary 
                    : colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        
        const SizedBox(height: 4),
        Text(
          '$currentDay of 7 days completed • $completedUses successful uses',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Quick log buttons
        Text(
          'Quick Log',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _logExperimentUse(true);
                },
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Used it!'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _logExperimentUse(false);
                },
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Missed it'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // End experiment option
        TextButton(
          onPressed: () async {
            await _completeExperiment();
          },
          child: Text(
            'End Experiment & Choose New One',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class RelationshipInsightsDashboard extends StatefulWidget {
  const RelationshipInsightsDashboard({
    super.key,
    this.userPersonalityType,
    this.userCommunicationStyle,
    this.partnerPersonalityType,
    this.partnerCommunicationStyle,
  });

  final String? userPersonalityType;
  final String? userCommunicationStyle;
  final String? partnerPersonalityType;
  final String? partnerCommunicationStyle;

  @override
  State<RelationshipInsightsDashboard> createState() =>
      _RelationshipInsightsDashboardState();
}

class _RelationshipInsightsDashboardState
    extends State<RelationshipInsightsDashboard>
    with TickerProviderStateMixin {
  
  // Controllers
  TabController? _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Services
  final RelationshipInsightsService _insightsService = RelationshipInsightsService();
  final KeyboardManager _keyboardManager = KeyboardManager();
  final PersonalityDrivenAnalyzer _personalityAnalyzer = PersonalityDrivenAnalyzer();
  final SecureCommunicationProgressService _progressService = SecureCommunicationProgressService();
  final SecureStorageService _storageService = SecureStorageService();
  final UnifiedAnalyticsService _analyticsService = UnifiedAnalyticsService();

  // Data storage
  Map<String, dynamic> _insights = {};
  Map<String, dynamic> _coupleExperience = {};
  Map<String, dynamic> _progressData = {};
  Map<String, dynamic>? _personalityResults;
  Map<String, dynamic>? _partnerPersonalityResults;
  List<Map<String, dynamic>> _communicationPatterns = [];
  List<Map<String, dynamic>> _relationshipGoals = [];
  
  // Loading states
  bool _isLoading = true;
  bool _isLoadingCoupleData = true;
  bool _isLoadingProgress = true;
  bool _isLoadingPersonality = true;
  String? _error;

  // Relationship type (couples or co-parents)
  String _relationshipType = 'couples'; // 'couples' or 'co-parents'
  
  // Time filtering
  String _selectedTimeframe = 'Last 7 Days';
  final List<String> _timeframeOptions = [
    'Last 24 Hours',
    'Last 7 Days', 
    'Last 30 Days',
    'Last 3 Months',
    'All Time'
  ];

  // Chart data
  List<FlSpot> _relationshipProgressData = [];
  List<PieChartSectionData> _communicationBalanceData = [];
  List<BarChartGroupData> _goalsProgressData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Load all data in parallel for better performance
    _initializeData();
  }

  /// Initialize all data sources
  Future<void> _initializeData() async {
    if (!mounted) return;
    
    try {
      // Load data in parallel
      await Future.wait([
        _loadRelationshipType(),
        _loadPersonalityResults(),
        _loadInsightsData(),
        _loadCoupleExperience(),
        _loadProgressData(),
      ]);

      // Start animations after data is loaded
      if (mounted) {
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('Error initializing relationship dashboard: $e');
    }
  }

  /// Refresh all insights data
  Future<void> _refreshInsights() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _initializeData();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to refresh insights: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Load personality test results for both partners
  Future<void> _loadPersonalityResults() async {
    if (!mounted) return;
    
    setState(() => _isLoadingPersonality = true);
    
    try {
      // Load user personality results
      final userResults = await _storageService.getPersonalityTestResults();
      // Load partner personality results (if available)
      final partnerResults = await _storageService.getPartnerPersonalityTestResults();
      
      if (mounted) {
        setState(() {
          _personalityResults = userResults;
          _partnerPersonalityResults = partnerResults;
          _isLoadingPersonality = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading personality results: $e');
      if (mounted) {
        setState(() {
          _personalityResults = null;
          _partnerPersonalityResults = null;
          _isLoadingPersonality = false;
        });
      }
    }
  }

  // Load relationship type preference
  Future<void> _loadRelationshipType() async {
    try {
      final type = await _storageService.getRelationshipType();
      if (mounted) {
        setState(() {
          _relationshipType = type ?? 'couples';
        });
      }
    } catch (e) {
      debugPrint('Error loading relationship type: $e');
    }
  }

  // Save relationship type preference
  Future<void> _saveRelationshipType(String type) async {
    try {
      await _storageService.saveRelationshipType(type);
      setState(() {
        _relationshipType = type;
      });
      // Refresh insights based on new type
      _loadInsightsData();
    } catch (e) {
      debugPrint('Error saving relationship type: $e');
    }
  }

  /// Load relationship insights from real analysis data
  Future<void> _loadInsightsData() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get real keyboard data first
      final realKeyboardData = await _keyboardManager.getComprehensiveRealData();
      final relationshipInsights = await _insightsService.generateRelationshipInsights();
      final analyticsData = await _analyticsService.getRelationshipAnalytics();

      if (mounted) {
        setState(() {
          // Check if user has real data
          if (realKeyboardData['real_data'] == true && (realKeyboardData['total_interactions'] ?? 0) > 0) {
            // User has real data - use it
            _insights = relationshipInsights;
          } else {
            // NEW USER - use encouraging fallback
            _insights = _generateFallbackInsights();
          }
          _isLoading = false;
        });
        
        // Generate charts with combined data
        _generateChartData();
        
        // Start animations if not already started
        if (!_animationController.isAnimating) {
          _animationController.forward();
        }
      }
    } catch (e) {
      debugPrint('Error loading relationship insights: $e');
      if (mounted) {
        setState(() {
          _error = null; // Don't show error to new users - show encouragement instead
          _isLoading = false;
          // Always provide encouraging fallback for new users
          _insights = _generateFallbackInsights();
        });
        _generateChartData();
      }
    }
  }

  /// Enhanced fallback insights for new users with encouraging messaging
  Map<String, dynamic> _generateFallbackInsights() {
    return {
      'isNewUser': true,
      'compatibility_score': 0.0,
      'communication_trend': 'ready_to_start',
      'weekly_messages': 0,
      'positive_sentiment': 0.0,
      'growth_areas': ['Building Communication Patterns', 'Discovering Your Style'],
      'relationship_strengths': ['Starting Fresh', 'Ready to Grow'],
      'recent_improvements': [],
      'communication_health': 0,
      'emotional_support': 0,
      'intimacy_cooperation': 0,
      'overall_health': 0,
      'newUserMessages': {
        'welcome': '💕 Building Your Relationship Insights',
        'subtitle': 'Your personalized relationship dashboard will develop as you use Unsaid',
        'encouragement': 'Start conversations with the Unsaid keyboard to unlock insights about your communication patterns',
        'nextSteps': [
          '1. Enable the Unsaid keyboard in Settings',
          '2. Start messaging with your partner',
          '3. Watch your insights grow over time'
        ]
      },
    };
  }

  /// Load couple-specific experience based on both personalities
  Future<void> _loadCoupleExperience() async {
    if (!mounted) return;
    
    if (widget.userPersonalityType == null ||
        widget.userCommunicationStyle == null ||
        widget.partnerPersonalityType == null ||
        widget.partnerCommunicationStyle == null) {
      setState(() {
        _isLoadingCoupleData = false;
      });
      return;
    }

    try {
      final experience = await _personalityAnalyzer.generatePersonalizedExperience(
        personalityType: widget.userPersonalityType!,
        communicationStyle: widget.userCommunicationStyle!,
        partnerPersonalityType: widget.partnerPersonalityType,
        partnerCommunicationStyle: widget.partnerCommunicationStyle,
      );

      if (mounted) {
        setState(() {
          _coupleExperience = experience['couple_experience'] ?? {};
          _isLoadingCoupleData = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading couple experience: $e');
      if (mounted) {
        setState(() {
          _isLoadingCoupleData = false;
        });
      }
    }
  }

  /// Load secure communication progress data
  Future<void> _loadProgressData() async {
    if (!mounted) return;
    
    try {
      final progress = await _progressService.getSecureCommunicationProgress(
        userPersonalityType: widget.userPersonalityType,
        userCommunicationStyle: widget.userCommunicationStyle,
        partnerPersonalityType: widget.partnerPersonalityType,
        partnerCommunicationStyle: widget.partnerCommunicationStyle,
      );

      if (mounted) {
        setState(() {
          _progressData = progress;
          _isLoadingProgress = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading progress data: $e');
      if (mounted) {
        setState(() {
          _isLoadingProgress = false;
        });
      }
    }
  }

  // Generate chart data for relationship analytics
  void _generateChartData() {
    _generateRelationshipProgressData();
    _generateCommunicationBalanceData();
    _generateGoalsProgressData();
  }

  // Generate relationship progress line chart data
  void _generateRelationshipProgressData() {
    _relationshipProgressData.clear();
    
    final analysisHistory = _keyboardManager.analysisHistory;
    if (analysisHistory.isEmpty) {
      // Default data for new relationships
      _relationshipProgressData = [
        const FlSpot(0, 0.6),
        const FlSpot(1, 0.6),
        const FlSpot(2, 0.6),
      ];
      return;
    }
    
    // Filter by timeframe and calculate relationship health score
    final filteredData = _filterDataByTimeframe(analysisHistory);
    
    for (int i = 0; i < filteredData.length; i++) {
      final confidence = (filteredData[i]['confidence'] as double?) ?? 0.6;
      final emotion = filteredData[i]['emotion']?.toString().toLowerCase() ?? '';
      
      // Calculate relationship health score based on positive communication
      double healthScore = confidence;
      if (['happy', 'supportive', 'loving', 'understanding'].contains(emotion)) {
        healthScore = (healthScore + 0.2).clamp(0.0, 1.0);
      } else if (['angry', 'frustrated', 'dismissive'].contains(emotion)) {
        healthScore = (healthScore - 0.2).clamp(0.0, 1.0);
      }
      
      _relationshipProgressData.add(FlSpot(i.toDouble(), healthScore));
    }
  }

  // Generate communication balance pie chart data
  void _generateCommunicationBalanceData() {
    _communicationBalanceData.clear();
    
    final partnerService = Provider.of<PartnerDataService>(context, listen: false);
    final analysisHistory = _keyboardManager.analysisHistory;
    
    if (analysisHistory.isEmpty && !partnerService.hasPartner) {
      // Default balance for new relationships
      _communicationBalanceData = [
        PieChartSectionData(
          color: Colors.blue.withOpacity(0.8),
          value: 50,
          title: 'You\n50%',
          titleStyle: RelationshipInsightsUtils.chartTitleStyle,
          radius: 80,
        ),
        PieChartSectionData(
          color: Colors.green.withOpacity(0.8),
          value: 50,
          title: 'Partner\n50%',
          titleStyle: RelationshipInsightsUtils.chartTitleStyle,
          radius: 80,
        ),
      ];
      return;
    }
    
    // Get actual message counts from partner service
    final messageCounts = partnerService.getMessageCounts();
    final userMessages = messageCounts['user'] ?? 0;
    final partnerMessages = messageCounts['partner'] ?? 0;
    final total = messageCounts['total'] ?? 0;
    
    if (total > 0) {
      _communicationBalanceData = [
        PieChartSectionData(
          color: Colors.blue.withOpacity(0.8),
          value: (userMessages / total * 100),
          title: 'You\n${(userMessages / total * 100).round()}%',
          titleStyle: RelationshipInsightsUtils.chartTitleStyle,
          radius: 80,
        ),
        PieChartSectionData(
          color: Colors.green.withOpacity(0.8),
          value: (partnerMessages / total * 100),
          title: '${partnerService.partnerName ?? 'Partner'}\n${(partnerMessages / total * 100).round()}%',
          titleStyle: RelationshipInsightsUtils.chartTitleStyle,
          radius: 80,
        ),
      ];
    } else {
      // Fallback for when no data exists
      _communicationBalanceData = [
        PieChartSectionData(
          color: Colors.blue.withOpacity(0.8),
          value: 50,
          title: 'You\n50%',
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          radius: 80,
        ),
        PieChartSectionData(
          color: Colors.green.withOpacity(0.8),
          value: 50,
          title: '${partnerService.partnerName ?? 'Partner'}\n50%',
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          radius: 80,
        ),
      ];
    }
  }

  // Generate relationship goals progress bar chart data
  void _generateGoalsProgressData() async {
    _goalsProgressData.clear();
    
    // Load real goals progress from keyboard data and user interactions
    try {
      final realKeyboardData = await _keyboardManager.getComprehensiveRealData();
      final analysisHistory = _keyboardManager.analysisHistory;
      
      if (analysisHistory.isNotEmpty) {
        // Calculate progress based on real communication patterns
        final recentAnalyses = analysisHistory.take(20).toList();
        
        double listeningProgress = _calculateListeningProgress(recentAnalyses);
        double supportProgress = _calculateSupportProgress(recentAnalyses);
        double conflictProgress = _calculateConflictProgress(recentAnalyses);
        double qualityTimeProgress = _calculateQualityTimeProgress(recentAnalyses);
        
        final goals = [
          {'name': 'Active Listening', 'progress': listeningProgress},
          {'name': 'Emotional Support', 'progress': supportProgress},
          {'name': 'Conflict Resolution', 'progress': conflictProgress},
          {'name': 'Quality Time', 'progress': qualityTimeProgress},
        ];
        
        for (int i = 0; i < goals.length; i++) {
          final progress = goals[i]['progress'] as double;
          _goalsProgressData.add(
            BarChartGroupData(
              x: i,
          barRods: [
            BarChartRodData(
              toY: progress,
              color: _getProgressColor(progress),
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }
      } else {
        // Fallback for new users with no analysis history
        final goals = [
          {'name': 'Active Listening', 'progress': 0.0},
          {'name': 'Emotional Support', 'progress': 0.0},
          {'name': 'Conflict Resolution', 'progress': 0.0},
          {'name': 'Quality Time', 'progress': 0.0},
        ];
        
        for (int i = 0; i < goals.length; i++) {
          final progress = goals[i]['progress'] as double;
          _goalsProgressData.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: progress,
                  color: _getProgressColor(progress),
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('Error generating goals progress data: $e');
      // Fallback to empty data
      _goalsProgressData.clear();
    }
  }

  // Calculate listening progress based on recent analyses
  double _calculateListeningProgress(List<Map<String, dynamic>> analyses) {
    if (analyses.isEmpty) return 0.0;
    
    int positiveListeningIndicators = 0;
    for (final analysis in analyses) {
      final suggestions = analysis['suggestions'] as List<dynamic>? ?? [];
      final text = analysis['original_text']?.toString().toLowerCase() ?? '';
      
      // Look for positive listening patterns
      if (text.contains('understand') || text.contains('hear you') || 
          text.contains('what you mean') || text.contains('tell me more')) {
        positiveListeningIndicators++;
      }
      
      // Check for listening-related suggestions
      for (final suggestion in suggestions) {
        if (suggestion.toString().toLowerCase().contains('listen') ||
            suggestion.toString().toLowerCase().contains('understand')) {
          positiveListeningIndicators++;
          break;
        }
      }
    }
    
    return (positiveListeningIndicators / analyses.length).clamp(0.0, 1.0);
  }

  // Calculate emotional support progress
  double _calculateSupportProgress(List<Map<String, dynamic>> analyses) {
    if (analyses.isEmpty) return 0.0;
    
    int supportiveIndicators = 0;
    for (final analysis in analyses) {
      final tone = analysis['tone_status']?.toString().toLowerCase() ?? '';
      final text = analysis['original_text']?.toString().toLowerCase() ?? '';
      
      // Look for supportive language
      if (text.contains('support') || text.contains('help') || 
          text.contains('care') || text.contains('love')) {
        supportiveIndicators++;
      }
      
      // Positive tone indicates good emotional support
      if (tone == 'clear' || tone == 'positive') {
        supportiveIndicators++;
      }
    }
    
    return (supportiveIndicators / (analyses.length * 2)).clamp(0.0, 1.0);
  }

  // Calculate conflict resolution progress
  double _calculateConflictProgress(List<Map<String, dynamic>> analyses) {
    if (analyses.isEmpty) return 0.0;
    
    int conflictResolutionIndicators = 0;
    int totalConflicts = 0;
    
    for (final analysis in analyses) {
      final tone = analysis['tone_status']?.toString().toLowerCase() ?? '';
      final text = analysis['original_text']?.toString().toLowerCase() ?? '';
      
      // Identify potential conflicts
      if (tone == 'alert' || tone == 'angry' || 
          text.contains('angry') || text.contains('upset') || 
          text.contains('frustrated')) {
        totalConflicts++;
        
        // Look for resolution indicators
        if (text.contains('sorry') || text.contains('understand') || 
            text.contains('work together') || text.contains('resolve')) {
          conflictResolutionIndicators++;
        }
      }
    }
    
    if (totalConflicts == 0) return 0.8; // Good if no conflicts
    return (conflictResolutionIndicators / totalConflicts).clamp(0.0, 1.0);
  }

  // Calculate quality time progress
  double _calculateQualityTimeProgress(List<Map<String, dynamic>> analyses) {
    if (analyses.isEmpty) return 0.0;
    
    int qualityTimeIndicators = 0;
    for (final analysis in analyses) {
      final text = analysis['original_text']?.toString().toLowerCase() ?? '';
      
      // Look for quality time language
      if (text.contains('together') || text.contains('time with') || 
          text.contains('date') || text.contains('spend time') ||
          text.contains('do something') || text.contains('plan')) {
        qualityTimeIndicators++;
      }
    }
    
    return (qualityTimeIndicators / analyses.length).clamp(0.0, 1.0);
  }
  }

  // Get color based on progress
  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.6) return Colors.orange;
    return Colors.red;
  }

  // Filter data by selected timeframe
  List<Map<String, dynamic>> _filterDataByTimeframe(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return data;
    
    try {
      final now = DateTime.now();
      DateTime cutoff;
      
      switch (_selectedTimeframe) {
        case 'Last 24 Hours':
          cutoff = now.subtract(const Duration(hours: 24));
          break;
        case 'Last 7 Days':
          cutoff = now.subtract(const Duration(days: 7));
          break;
        case 'Last 30 Days':
          cutoff = now.subtract(const Duration(days: 30));
          break;
        case 'Last 3 Months':
          cutoff = now.subtract(const Duration(days: 90));
          break;
        case 'All Time':
        default:
          return data;
      }
      
      return data.where((item) {
        final timestamp = item['timestamp'] as String?;
        if (timestamp == null || timestamp.isEmpty) return false;
        
        try {
          final date = DateTime.parse(timestamp);
          return date.isAfter(cutoff);
        } catch (e) {
          debugPrint('Error parsing timestamp: $timestamp');
          return false;
        }
      }).toList();
    } catch (e) {
      debugPrint('Error filtering data by timeframe: $e');
      return data;
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer2<NewUserExperienceService, PartnerDataService>(
      builder: (context, newUserService, partnerService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_relationshipType == 'couples' ? 'Couple Insights' : 'Co-Parent Insights'),
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              // Relationship type toggle
              PopupMenuButton<String>(
                icon: Icon(
                  _relationshipType == 'couples' ? Icons.favorite : Icons.family_restroom,
                  color: theme.colorScheme.primary,
                ),
                onSelected: _saveRelationshipType,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'couples',
                    child: Row(
                      children: [
                        Icon(Icons.favorite, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('Couple'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'co-parents',
                    child: Row(
                      children: [
                        Icon(Icons.family_restroom, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('Co-Parents'),
                      ],
                    ),
                  ),
                ],
              ),
              // Partner status indicator
              if (partnerService.hasPartner)
                IconButton(
                  icon: Icon(
                    Icons.people,
                    color: Colors.green,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Connected to ${partnerService.partnerName}'),
                      ),
                    );
                  },
                ),
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshInsights,
              ),
            ],
            bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Analytics'),
            Tab(text: 'Goals'),
          ],
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState(theme)
          : _error != null
              ? _buildErrorState(theme)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(theme, partnerService, newUserService),
                    _buildAnalyticsTab(theme, partnerService, newUserService),
                    _buildGoalsTab(theme, partnerService, newUserService),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to secure communication tips
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SecureCoupleTips(
                userPersonalityType: widget.userPersonalityType,
                partnerPersonalityType: widget.partnerPersonalityType,
              ),
            ),
          );
        },
        label: Text(_relationshipType == 'couples' ? 'Couple Tips' : 'Co-Parent Tips'),
        icon: const Icon(Icons.lightbulb),
        backgroundColor: theme.colorScheme.primary,
      ),
        );
      },
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Building your relationship insights...',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('Unable to load insights', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            _error ?? 'An unexpected error occurred',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshInsights,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme, PartnerDataService partnerService, NewUserExperienceService newUserService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show partner connection status if not connected
          if (!partnerService.hasPartner) 
            _buildPartnerInviteCard(theme, partnerService),
          if (!partnerService.hasPartner) 
            const SizedBox(height: 24),
          
          _buildRelationshipHealthSummary(theme, partnerService),
          const SizedBox(height: 24),
          _buildRecentActivity(theme, partnerService),
          const SizedBox(height: 24),
          _buildQuickActions(theme),
          const SizedBox(height: 24),
          _buildChildrenNamesWidget(theme),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(ThemeData theme, PartnerDataService partnerService, NewUserExperienceService newUserService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time range filter
          _buildTimeRangeFilter(theme),
          const SizedBox(height: 24),
          
          // Relationship progress chart
          _buildRelationshipProgressChart(theme, partnerService),
          const SizedBox(height: 24),
          
          // Communication balance chart
          _buildCommunicationBalanceChart(theme, partnerService),
          const SizedBox(height: 24),
          
          // Secure communication insights
          _buildSecureCommunicationInsights(theme, partnerService),
        ],
      ),
    );
  }

  Widget _buildGoalsTab(ThemeData theme, PartnerDataService partnerService, NewUserExperienceService newUserService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGoalsProgress(theme, partnerService),
          const SizedBox(height: 24),
          _buildRelationshipGoals(theme, partnerService),
          const SizedBox(height: 24),
          _buildSecureCommunicationTips(theme, partnerService),
        ],
      ),
    );
  }
  Widget _buildRelationshipHealthSummary(ThemeData theme, PartnerDataService partnerService) {
    final healthScore = _calculateRelationshipHealthScore(partnerService);
    final healthLabel = _getHealthLabel(healthScore);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _relationshipType == 'couples' ? 'Relationship Health' : 'Co-Parenting Health',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (partnerService.hasPartner)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Combined Data',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric(
                    theme,
                    'Overall Health',
                    '${(healthScore * 100).round()}%',
                    Icons.favorite,
                    RelationshipInsightsUtils.getScoreColor(healthScore),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildHealthMetric(
                    theme,
                    'Communication',
                    _getCommunicationScore(),
                    Icons.chat,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric(
                    theme,
                    'Emotional Support',
                    _getEmotionalSupportScore(),
                    Icons.support,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildHealthMetric(
                    theme,
                    _relationshipType == 'couples' ? 'Intimacy' : 'Cooperation',
                    _getConnectionScore(),
                    _relationshipType == 'couples' ? Icons.favorite_border : Icons.handshake,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetric(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentActivity(ThemeData theme, PartnerDataService partnerService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._generateRecentActivityItems(theme, partnerService),
          ],
        ),
      ),
    );
  }

  List<Widget> _generateRecentActivityItems(ThemeData theme, PartnerDataService partnerService) {
    final combinedHistory = partnerService.hasPartner 
        ? partnerService.getCombinedAnalysisHistory()
        : _keyboardManager.analysisHistory;
    final List<Widget> items = [];
    
    if (combinedHistory.isEmpty) {
      // Default activities for new users
      items.addAll([
        _buildActivityItem(
          theme,
          'Welcome to ${_relationshipType == 'couples' ? 'Couple' : 'Co-Parent'} Insights',
          'Start messaging to see insights',
          Icons.favorite,
          theme.colorScheme.primary,
        ),
        _buildActivityItem(
          theme,
          'Set up your first relationship goal',
          'Tap Goals tab to get started',
          Icons.flag,
          Colors.blue,
        ),
        _buildActivityItem(
          theme,
          'Explore secure communication tips',
          'Available in the tips section',
          Icons.lightbulb,
          Colors.orange,
        ),
      ]);
    } else {
      // Generate activities based on combined data
      final recentAnalyses = combinedHistory.take(10).toList();
      
      // Show partner connection activity
      if (partnerService.hasPartner) {
        items.add(_buildActivityItem(
          theme,
          'Connected to ${partnerService.partnerName}',
          'Now showing combined insights',
          Icons.people,
          Colors.green,
        ));
      }
      
      // Communication trend
      final positiveCount = recentAnalyses.where((a) => 
        ['happy', 'loving', 'supportive', 'grateful'].contains(a['emotional_tone'])
      ).length;
      
      if (positiveCount > recentAnalyses.length * 0.6) {
        items.add(_buildActivityItem(
          theme,
          'Positive communication increased',
          'Last 7 days across both partners',
          Icons.trending_up,
          Colors.green,
        ));
      }
      
      // Message frequency
      final messageCounts = partnerService.getMessageCounts();
      final totalMessages = messageCounts['total'] ?? 0;
      if (totalMessages > 0) {
        items.add(_buildActivityItem(
          theme,
          'Messages analyzed: $totalMessages',
          partnerService.hasPartner ? 'Combined from both partners' : 'This week',
          Icons.message,
          Colors.blue,
        ));
      }
      
      // Compatibility score if partner exists
      if (partnerService.hasPartner) {
        final compatibilityScore = partnerService.getCompatibilityScore();
        items.add(_buildActivityItem(
          theme,
          'Compatibility Score: ${(compatibilityScore * 100).round()}%',
          'Based on communication patterns',
          Icons.favorite,
          Colors.red,
        ));
      }
      
      // Growth areas
      final growthAreas = _insights['growth_areas'] as List<dynamic>? ?? [];
      if (growthAreas.isNotEmpty) {
        items.add(_buildActivityItem(
          theme,
          'Focus area: ${growthAreas.first}',
          'Continue improving together',
          Icons.psychology,
          Colors.orange,
        ));
      }
    }
    
    return items.take(4).toList(); // Show maximum 4 items
  }

  Widget _buildActivityItem(ThemeData theme, String title, String subtitle, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    theme,
                    'Analytics',
                    Icons.analytics,
                    () => _tabController?.animateTo(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    theme,
                    'Goals',
                    Icons.flag,
                    () => _tabController?.animateTo(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    theme,
                    'Tips',
                    Icons.lightbulb,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SecureCoupleTips(
                            userPersonalityType: widget.userPersonalityType,
                            partnerPersonalityType: widget.partnerPersonalityType,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    theme,
                    'Progress',
                    Icons.trending_up,
                    () => _tabController?.animateTo(1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme, String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget for managing children's names for co-parenting
  Widget _buildChildrenNamesWidget(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.child_care,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _relationshipType == 'co-parents' ? 'Children Names' : 'Family Names',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddChildDialog(theme),
                  tooltip: 'Add child name',
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<String>>(
              future: _loadChildrenNames(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                final childrenNames = snapshot.data ?? [];
                
                if (childrenNames.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.child_friendly,
                          size: 48,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _relationshipType == 'co-parents' 
                            ? 'Add your children\'s names to get personalized communication suggestions'
                            : 'Add family member names for better conversation insights',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showAddChildDialog(theme),
                          icon: const Icon(Icons.add),
                          label: Text(_relationshipType == 'co-parents' ? 'Add Child' : 'Add Name'),
                        ),
                      ],
                    ),
                  );
                }
                
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: childrenNames.map((name) => _buildChildNameChip(theme, name)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual child name chip with delete option
  Widget _buildChildNameChip(ThemeData theme, String name) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      label: Text(name),
      deleteIcon: Icon(
        Icons.close,
        size: 18,
        color: theme.colorScheme.onSurface.withOpacity(0.6),
      ),
      onDeleted: () => _removeChildName(name),
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
    );
  }

  /// Show dialog to add a new child's name
  void _showAddChildDialog(ThemeData theme) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_relationshipType == 'co-parents' ? 'Add Child\'s Name' : 'Add Family Name'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: _relationshipType == 'co-parents' ? 'Enter child\'s name' : 'Enter family member\'s name',
                  prefixIcon: const Icon(Icons.person),
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  if (value.trim().length > 20) {
                    return 'Name must be less than 20 characters';
                  }
                  return null;
                },
                onFieldSubmitted: (_) {
                  if (formKey.currentState?.validate() ?? false) {
                    _addChildName(nameController.text.trim());
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: 12),
              Text(
                _relationshipType == 'co-parents' 
                  ? 'Adding your children\'s names helps the Unsaid keyboard provide personalized co-parenting communication suggestions.'
                  : 'Adding family names helps personalize your communication suggestions.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                _addChildName(nameController.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Load children names from secure storage
  Future<List<String>> _loadChildrenNames() async {
    try {
      return await _storageService.getChildrenNames();
    } catch (e) {
      debugPrint('Error loading children names: $e');
      return [];
    }
  }

  /// Add a new child's name
  Future<void> _addChildName(String name) async {
    try {
      final currentNames = await _loadChildrenNames();
      
      // Check for duplicates (case insensitive)
      if (currentNames.any((existing) => existing.toLowerCase() == name.toLowerCase())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name is already in the list'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }
      
      final updatedNames = [...currentNames, name];
      await _storageService.saveChildrenNames(updatedNames);
      
      // Sync with keyboard extension
      await _keyboardManager.syncChildrenNames(updatedNames);
      
      if (mounted) {
        setState(() {}); // Refresh the widget
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding child name: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add $name'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Remove a child's name
  Future<void> _removeChildName(String name) async {
    try {
      final currentNames = await _loadChildrenNames();
      final updatedNames = currentNames.where((n) => n != name).toList();
      
      await _storageService.saveChildrenNames(updatedNames);
      
      // Sync with keyboard extension
      await _keyboardManager.syncChildrenNames(updatedNames);
      
      if (mounted) {
        setState(() {}); // Refresh the widget
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name removed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error removing child name: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove $name'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Helper methods for calculating scores
  double _calculateRelationshipHealthScore(PartnerDataService partnerService) {
    final combinedHistory = partnerService.hasPartner 
        ? partnerService.getCombinedAnalysisHistory()
        : _keyboardManager.analysisHistory;
    
    if (combinedHistory.isEmpty) {
      return (_insights['overall_health'] ?? 80) / 100.0;
    }

    double totalScore = 0.0;
    int validAnalyses = 0;

    for (final analysis in combinedHistory.take(30)) { // Last 30 analyses
      if (analysis['confidence'] != null) {
        final confidence = analysis['confidence'] as double;
        final emotionalTone = analysis['emotional_tone'] as String? ?? 'neutral';
        
        double analysisScore = confidence;
        
        // Boost score for positive emotions
        if (['happy', 'excited', 'grateful', 'loving', 'supportive'].contains(emotionalTone)) {
          analysisScore = (analysisScore + 0.2).clamp(0.0, 1.0);
        }
        // Reduce score for negative emotions
        else if (['angry', 'frustrated', 'dismissive', 'sad'].contains(emotionalTone)) {
          analysisScore = (analysisScore - 0.15).clamp(0.0, 1.0);
        }
        
        totalScore += analysisScore;
        validAnalyses++;
      }
    }

    final baseScore = validAnalyses > 0 
        ? (totalScore / validAnalyses).clamp(0.0, 1.0)
        : 0.80;

    // Boost score if partner is connected (shows commitment)
    if (partnerService.hasPartner) {
      final compatibilityScore = partnerService.getCompatibilityScore();
      return ((baseScore + compatibilityScore) / 2.0).clamp(0.0, 1.0);
    }

    return baseScore;
  }

  String _getCommunicationScore() {
    final analysisHistory = _keyboardManager.analysisHistory;
    
    if (analysisHistory.isEmpty) {
      return '${_insights['communication_health'] ?? 85}%';
    }

    final recentMessages = analysisHistory.take(20).toList();
    final positiveMessages = recentMessages.where((msg) => 
      ['happy', 'supportive', 'loving', 'understanding', 'grateful', 'excited'].contains(
        msg['emotional_tone']?.toString().toLowerCase()
      )
    ).length;
    
    final score = recentMessages.isNotEmpty 
        ? (positiveMessages / recentMessages.length * 100).round()
        : 85;
    
    return '${score}%';
  }

  String _getEmotionalSupportScore() {
    final analysisHistory = _keyboardManager.analysisHistory;
    
    if (analysisHistory.isEmpty) {
      return '${_insights['emotional_support'] ?? 80}%';
    }

    // Calculate based on supportive language patterns
    final supportiveKeywords = ['support', 'understand', 'help', 'care', 'love', 'comfort'];
    int supportiveCount = 0;
    int totalMessages = 0;

    for (final analysis in analysisHistory.take(50)) {
      if (analysis['original_message'] != null) {
        final message = analysis['original_message'].toString().toLowerCase();
        totalMessages++;
        
        for (final keyword in supportiveKeywords) {
          if (message.contains(keyword)) {
            supportiveCount++;
            break;
          }
        }
      }
    }

    final score = totalMessages > 0 
        ? (supportiveCount / totalMessages * 100).round()
        : 80;
    
    return '${score}%';
  }

  String _getConnectionScore() {
    final analysisHistory = _keyboardManager.analysisHistory;
    
    if (analysisHistory.isEmpty) {
      return '${_insights['intimacy_cooperation'] ?? 75}%';
    }

    // Calculate based on connection indicators
    final connectionKeywords = _relationshipType == 'couples' 
        ? ['love', 'miss', 'together', 'us', 'we', 'our']
        : ['team', 'together', 'cooperate', 'work', 'support', 'family'];
    
    int connectionCount = 0;
    int totalMessages = 0;

    for (final analysis in analysisHistory.take(50)) {
      if (analysis['original_message'] != null) {
        final message = analysis['original_message'].toString().toLowerCase();
        totalMessages++;
        
        for (final keyword in connectionKeywords) {
          if (message.contains(keyword)) {
            connectionCount++;
            break;
          }
        }
      }
    }

    final score = totalMessages > 0 
        ? (connectionCount / totalMessages * 100).round()
        : 75;
    
    return '${score}%';
  }

  String _getHealthLabel(double score) {
    if (score >= 0.9) return 'Excellent';
    if (score >= 0.8) return 'Very Good';
    if (score >= 0.7) return 'Good';
    if (score >= 0.6) return 'Fair';
    return 'Needs Attention';
  }

  Widget _buildTimeRangeFilter(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.date_range, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              'Time Range:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButton<String>(
                value: _selectedTimeframe,
                isExpanded: true,
                underline: Container(),
                items: _timeframeOptions.map((String timeframe) {
                  return DropdownMenuItem<String>(
                    value: timeframe,
                    child: Text(timeframe),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedTimeframe = newValue;
                      _generateChartData();
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelationshipProgressChart(ThemeData theme, PartnerDataService partnerService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  _relationshipType == 'couples' ? 'Relationship Progress' : 'Co-Parenting Progress',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              partnerService.hasPartner 
                  ? 'Track your relationship health over time (combined data)'
                  : 'Track your relationship health over time',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: _relationshipProgressData.isNotEmpty
                  ? LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${(value * 100).round()}%',
                                  style: theme.textTheme.bodySmall,
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.round()}',
                                  style: theme.textTheme.bodySmall,
                                );
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _relationshipProgressData,
                            isCurved: true,
                            color: theme.colorScheme.primary,
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: theme.colorScheme.primary.withOpacity(0.1),
                            ),
                          ),
                        ],
                        minY: 0,
                        maxY: 1,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start Communicating',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use the keyboard extension to track your relationship progress',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunicationBalanceChart(ThemeData theme, PartnerDataService partnerService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.balance, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Communication Balance',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              partnerService.hasPartner 
                  ? 'Balance of communication between you and ${partnerService.partnerName}'
                  : 'Balance of communication between partners',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 100, // Reduced by 50% from 200 to 100
              child: PieChart(
                PieChartData(
                  sections: _communicationBalanceData,
                  centerSpaceRadius: 30, // Also reduced center radius
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      // Add touch interaction if needed
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecureCommunicationInsights(ThemeData theme, PartnerDataService partnerService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure Communication',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Insights',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._generateSecureCommunicationInsights(theme, partnerService),
          ],
        ),
      ),
    );
  }

  List<Widget> _generateSecureCommunicationInsights(ThemeData theme, PartnerDataService partnerService) {
    final combinedHistory = partnerService.hasPartner 
        ? partnerService.getCombinedAnalysisHistory()
        : _keyboardManager.analysisHistory;
    final List<Widget> insights = [];
    
    if (combinedHistory.isEmpty) {
      // Default insights for new users
      insights.addAll([
        _buildInsightTile(
          theme,
          'Start Your Journey',
          'Begin messaging to unlock personalized insights',
          Icons.play_arrow,
          theme.colorScheme.primary,
        ),
        _buildInsightTile(
          theme,
          'Secure Communication',
          'Learn to express yourself safely and effectively',
          Icons.security,
          Colors.green,
        ),
        _buildInsightTile(
          theme,
          'Build Trust',
          'Develop patterns that strengthen your relationship',
          Icons.favorite,
          Colors.red,
        ),
      ]);
    } else {
      // Generate insights based on combined data
      final recentAnalyses = combinedHistory.take(50).toList();
      
      // Emotional regulation insight
      final emotionalMessages = recentAnalyses.where((a) => 
        ['happy', 'grateful', 'calm', 'understanding'].contains(a['emotional_tone'])
      ).length;
      final emotionalPercentage = ((emotionalMessages / recentAnalyses.length) * 100).round();
      
      insights.add(_buildInsightTile(
        theme,
        'Emotional Regulation',
        emotionalPercentage > 60 
            ? 'Great emotional balance in your messages ($emotionalPercentage%)'
            : 'Focus on emotional awareness ($emotionalPercentage% positive)',
        Icons.mood,
        emotionalPercentage > 60 ? Colors.green : Colors.orange,
      ));
      
      // Communication clarity
      final clarityScore = recentAnalyses.fold<double>(0, (sum, a) => 
        sum + (a['confidence'] as double? ?? 0.5)
      ) / recentAnalyses.length;
      
      insights.add(_buildInsightTile(
        theme,
        'Communication Clarity',
        clarityScore > 0.7 
            ? 'Your messages are clear and well-structured'
            : 'Consider being more specific in your communication',
        Icons.lightbulb_outline,
        clarityScore > 0.7 ? Colors.green : Colors.orange,
      ));
      
      // Partner-specific insights
      if (partnerService.hasPartner) {
        final compatibilityScore = partnerService.getCompatibilityScore();
        insights.add(_buildInsightTile(
          theme,
          'Partner Compatibility',
          compatibilityScore > 0.8 
              ? 'Excellent communication compatibility with ${partnerService.partnerName}'
              : 'Working on building better communication patterns together',
          Icons.people,
          compatibilityScore > 0.8 ? Colors.green : Colors.orange,
        ));
      } else {
        // Relationship-specific insight
        final relationshipInsight = _relationshipType == 'couples'
            ? _buildCoupleSpecificInsight(theme, recentAnalyses)
            : _buildCoParentSpecificInsight(theme, recentAnalyses);
        
        insights.add(relationshipInsight);
      }
    }
    
    return insights;
  }

  Widget _buildCoupleSpecificInsight(ThemeData theme, List<Map<String, dynamic>> analyses) {
    final romanticKeywords = ['love', 'miss', 'beautiful', 'special', 'together'];
    final romanticCount = analyses.where((a) {
      final message = a['original_message']?.toString().toLowerCase() ?? '';
      return romanticKeywords.any((keyword) => message.contains(keyword));
    }).length;
    
    return _buildInsightTile(
      theme,
      'Romantic Connection',
      romanticCount > 0
          ? 'You\'re expressing love and affection regularly'
          : 'Consider sharing more appreciation with your partner',
      Icons.favorite,
      romanticCount > 0 ? Colors.red : Colors.orange,
    );
  }

  Widget _buildCoParentSpecificInsight(ThemeData theme, List<Map<String, dynamic>> analyses) {
    final cooperativeKeywords = ['team', 'together', 'help', 'support', 'family'];
    final cooperativeCount = analyses.where((a) {
      final message = a['original_message']?.toString().toLowerCase() ?? '';
      return cooperativeKeywords.any((keyword) => message.contains(keyword));
    }).length;
    
    return _buildInsightTile(
      theme,
      'Co-Parenting Teamwork',
      cooperativeCount > 0
          ? 'Strong teamwork focus in your communication'
          : 'Consider emphasizing collaboration and support',
      Icons.family_restroom,
      cooperativeCount > 0 ? Colors.blue : Colors.orange,
    );
  }

  Widget _buildInsightTile(ThemeData theme, String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsProgress(ThemeData theme, PartnerDataService partnerService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _relationshipType == 'couples' ? 'Relationship Goals' : 'Co-Parenting Goals',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Progress',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: _goalsProgressData,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value * 100).round()}%',
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final goals = ['Listening', 'Support', 'Conflict', 'Quality'];
                          if (value.toInt() < goals.length) {
                            return Text(
                              goals[value.toInt()],
                              style: theme.textTheme.bodySmall,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  gridData: FlGridData(show: true),
                  maxY: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelationshipGoals(ThemeData theme, PartnerDataService partnerService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  _relationshipType == 'couples' ? 'Couple Goals' : 'Co-Parenting Goals',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: RelationshipCoupleGoals(
                yourAttachment: _insights['your_style'] ?? 'Secure',
                partnerAttachment: _insights['partner_style'] ?? 'Secure',
                yourComm: _insights['your_comm'] ?? 'Assertive',
                partnerComm: _insights['partner_comm'] ?? 'Assertive',
                context: _relationshipType == 'couples' ? 'marriage' : 'co-parenting',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecureCommunicationTips(ThemeData theme, PartnerDataService partnerService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure Communication',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tips',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._getPersonalizedSecureCommunicationTips().map((tip) => 
              _buildTipTile(theme, tip),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SecureCoupleTips(
                        userPersonalityType: widget.userPersonalityType,
                        partnerPersonalityType: widget.partnerPersonalityType,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: Text('View All ${_relationshipType == 'couples' ? 'Couple' : 'Co-Parent'} Tips'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getPersonalizedSecureCommunicationTips() {
    final analysisHistory = _keyboardManager.analysisHistory;
    final baseTips = _getBaseTips();
    
    if (analysisHistory.isEmpty) {
      return baseTips.take(3).toList();
    }
    
    // Personalize tips based on analysis history
    final recentAnalyses = analysisHistory.take(30).toList();
    final emotionalTones = recentAnalyses.map((a) => a['emotional_tone']).toSet();
    
    List<Map<String, dynamic>> personalizedTips = [];
    
    // Add tips based on emotional patterns
    if (emotionalTones.contains('angry') || emotionalTones.contains('frustrated')) {
      personalizedTips.add({
        'title': 'Emotional Regulation',
        'description': 'Take deep breaths before responding when feeling intense emotions',
        'icon': Icons.self_improvement,
        'color': Colors.orange,
      });
    }
    
    if (emotionalTones.contains('sad') || emotionalTones.contains('hurt')) {
      personalizedTips.add({
        'title': 'Express Vulnerability',
        'description': 'Share your feelings openly while asking for support',
        'icon': Icons.favorite_border,
        'color': Colors.pink,
      });
    }
    
    // Add relationship-specific tips
    personalizedTips.addAll(baseTips);
    
    return personalizedTips.take(3).toList();
  }

  List<Map<String, dynamic>> _getBaseTips() {
    if (_relationshipType == 'couples') {
      return [
        {
          'title': 'Express Needs Clearly',
          'description': 'Use "I" statements to express your needs without blame',
          'icon': Icons.record_voice_over,
          'color': Colors.blue,
        },
        {
          'title': 'Practice Active Listening',
          'description': 'Focus on understanding your partner\'s perspective',
          'icon': Icons.hearing,
          'color': Colors.green,
        },
        {
          'title': 'Validate Emotions',
          'description': 'Acknowledge your partner\'s feelings before problem-solving',
          'icon': Icons.favorite,
          'color': Colors.red,
        },
        {
          'title': 'Take Breaks During Conflict',
          'description': 'Pause heated discussions to regulate emotions',
          'icon': Icons.pause_circle,
          'color': Colors.orange,
        },
      ];
    } else {
      return [
        {
          'title': 'Focus on the Children',
          'description': 'Keep discussions centered on your children\'s wellbeing',
          'icon': Icons.child_care,
          'color': Colors.purple,
        },
        {
          'title': 'Stay Business-Like',
          'description': 'Keep communication professional and solution-focused',
          'icon': Icons.business,
          'color': Colors.blue,
        },
        {
          'title': 'Use Shared Calendars',
          'description': 'Coordinate schedules transparently to avoid conflicts',
          'icon': Icons.calendar_today,
          'color': Colors.green,
        },
        {
          'title': 'Respect Boundaries',
          'description': 'Maintain appropriate boundaries in your co-parenting relationship',
          'icon': Icons.shield,
          'color': Colors.orange,
        },
      ];
    }
  }

  Widget _buildTipTile(ThemeData theme, Map<String, dynamic> tip) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (tip['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (tip['color'] as Color).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (tip['color'] as Color).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              tip['icon'] as IconData,
              color: tip['color'] as Color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip['title'] as String,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip['description'] as String,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build partner invite card for users who haven't connected with their partner
  Widget _buildPartnerInviteCard(ThemeData theme, PartnerDataService partnerService) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people_alt,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Unlock Full Relationship Insights',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Invite your ${_relationshipType == 'couples' ? 'partner' : 'co-parent'} to get deeper insights by combining both of your communication patterns.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showInvitePartnerDialog(partnerService),
                    icon: const Icon(Icons.send),
                    label: const Text('Send Invite'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showJoinPartnerDialog(partnerService),
                    icon: const Icon(Icons.login),
                    label: const Text('Join Partner'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show dialog to invite partner
  void _showInvitePartnerDialog(PartnerDataService partnerService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Your Partner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generate an invite code to share with your partner:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FutureBuilder<String>(
              future: partnerService.generateInviteCode(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            snapshot.data!,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // Copy to clipboard
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copied to clipboard')),
                            );
                          },
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show dialog to join partner using invite code
  void _showJoinPartnerDialog(PartnerDataService partnerService) {
    final codeController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Partner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Partner\'s Invite Code',
                hintText: 'Enter 8-digit code',
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Partner\'s Name',
                hintText: 'Enter your partner\'s name',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isNotEmpty && nameController.text.isNotEmpty) {
                final success = await partnerService.acceptInviteCode(
                  codeController.text.toUpperCase(),
                  nameController.text,
                );
                
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Connected to ${nameController.text}!')),
                  );
                  _refreshInsights(); // Refresh to show combined data
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid invite code')),
                  );
                }
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}

// MARK: - Enhanced Co-Parenting Intelligence
class CoParentingIntelligence extends StatelessWidget {
  final List<Map<String, dynamic>> analyses;

  const CoParentingIntelligence({super.key, required this.analyses});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final insights = _analyzeCoParentingPatterns();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.family_restroom, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Co-Parenting Intelligence',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'How your communication affects the kids',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Child-First Score
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.1),
                    colorScheme.primaryContainer.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Child-First Score',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getChildFirstDescription(insights['childFirstScore']),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: RelationshipInsightsUtils.getScoreColor(insights['childFirstScore']).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${(insights['childFirstScore'] * 100).toInt()}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: RelationshipInsightsUtils.getScoreColor(insights['childFirstScore']),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: insights['childFirstScore'],
                    backgroundColor: colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      RelationshipInsightsUtils.getScoreColor(insights['childFirstScore']),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Key Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Unity Score',
                    '${(insights['unityScore'] * 100).toInt()}%',
                    'How often you present united front',
                    Icons.handshake_outlined,
                    RelationshipInsightsUtils.getScoreColor(insights['unityScore']),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Child Shield',
                    '${(insights['childShieldScore'] * 100).toInt()}%',
                    'Protecting kids from conflict',
                    Icons.shield_outlined,
                    RelationshipInsightsUtils.getScoreColor(insights['childShieldScore']),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Schedule Harmony',
                    '${(insights['scheduleHarmony'] * 100).toInt()}%',
                    'Coordination without conflict',
                    Icons.schedule,
                    RelationshipInsightsUtils.getScoreColor(insights['scheduleHarmony']),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    'Emotional Safety',
                    '${(insights['emotionalSafety'] * 100).toInt()}%',
                    'Creating secure environment',
                    Icons.favorite_outline,
                    RelationshipInsightsUtils.getScoreColor(insights['emotionalSafety']),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Conversation Type Breakdown
            Text(
              'Communication Breakdown',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            ...insights['conversationTypes'].entries.map<Widget>((entry) {
              final percentage = entry.value as double;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getConversationTypeColor(entry.key),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _getConversationTypeLabel(entry.key),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getConversationTypeColor(entry.key),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(percentage * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 20),

            // Coaching Insights
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Child Development Insight',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getCoParentingInsight(insights),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            if (insights['riskFactors'].isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_outlined,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Watch For',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...insights['riskFactors'].map<Widget>((factor) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.arrow_right,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                factor as String,
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ).toList(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _analyzeCoParentingPatterns() {
    // Analyze child-focused language vs conflict language
    int childFocusedMessages = 0;
    int conflictMessages = 0;
    int logisticsMessages = 0;
    int supportiveMessages = 0;
    int totalMessages = analyses.length;

    final riskFactors = <String>[];
    final conversationTypes = <String, double>{};

    for (final analysis in analyses) {
      final text = (analysis['text'] as String? ?? '').toLowerCase();
      final tone = analysis['tone_status'] as String? ?? 'neutral';

      // Categorize conversation types
      if (_isChildFocused(text)) {
        childFocusedMessages++;
      } else if (_isLogistics(text)) {
        logisticsMessages++;
      } else if (_isSupportive(text)) {
        supportiveMessages++;
      } else if (tone == 'alert' || tone == 'caution') {
        conflictMessages++;
      }
    }

    if (totalMessages > 0) {
      conversationTypes['child_focused'] = childFocusedMessages / totalMessages;
      conversationTypes['logistics'] = logisticsMessages / totalMessages;
      conversationTypes['supportive'] = supportiveMessages / totalMessages;
      conversationTypes['conflict'] = conflictMessages / totalMessages;
    }

    // Calculate scores
    final childFirstScore = totalMessages > 0 
      ? (childFocusedMessages + supportiveMessages) / totalMessages 
      : 0.0;
    
    final unityScore = totalMessages > 0 
      ? 1.0 - (conflictMessages / totalMessages) 
      : 1.0;
    
    final childShieldScore = _calculateChildShieldScore();
    final scheduleHarmony = _calculateScheduleHarmony();
    final emotionalSafety = _calculateEmotionalSafety();

    // Identify risk factors
    if (conflictMessages > childFocusedMessages) {
      riskFactors.add('More conflict than child-focused communication');
    }
    if (childFirstScore < 0.3) {
      riskFactors.add('Low child-first language detected');
    }
    if (_hasTriangulation()) {
      riskFactors.add('Potential child triangulation patterns');
    }

    return {
      'childFirstScore': childFirstScore,
      'unityScore': unityScore,
      'childShieldScore': childShieldScore,
      'scheduleHarmony': scheduleHarmony,
      'emotionalSafety': emotionalSafety,
      'conversationTypes': conversationTypes,
      'riskFactors': riskFactors,
    };
  }

  bool _isChildFocused(String text) {
    final childKeywords = [
      'kids', 'children', 'son', 'daughter', 'school', 'homework',
      'bedtime', 'pickup', 'activities', 'doctor', 'teacher',
      'happy', 'proud', 'excited', 'loves', 'enjoys', 'needs',
    ];
    return childKeywords.any((keyword) => text.contains(keyword));
  }

  bool _isLogistics(String text) {
    final logisticsKeywords = [
      'time', 'when', 'where', 'schedule', 'calendar', 'appointment',
      'meeting', 'event', 'practice', 'game', 'lesson',
    ];
    return logisticsKeywords.any((keyword) => text.contains(keyword));
  }

  bool _isSupportive(String text) {
    final supportKeywords = [
      'thank you', 'appreciate', 'great job', 'well done', 'agree',
      'support', 'help', 'together', 'team', 'partnership',
    ];
    return supportKeywords.any((keyword) => text.contains(keyword));
  }

  double _calculateChildShieldScore() {
    if (analyses.isEmpty) return 0.0;
    
    int protectiveMessages = 0;
    int totalMessages = analyses.length;
    
    for (final analysis in analyses) {
      final text = (analysis['text'] as String? ?? '').toLowerCase();
      final tone = analysis['tone_status'] as String? ?? 'neutral';
      
      // Look for protective language that shields children from conflict
      final protectiveKeywords = [
        'let\'s talk later', 'not in front of', 'when kids are asleep',
        'privately', 'between us', 'away from kids', 'discuss this later',
        'protect', 'shield', 'keep peaceful', 'their wellbeing'
      ];
      
      // Positive indicators: redirecting conflict away from children
      final hasProtectiveLanguage = protectiveKeywords.any((keyword) => text.contains(keyword));
      
      // Negative indicators: involving children or exposing them to conflict
      final exposingKeywords = [
        'tell the kids', 'ask them', 'they need to know', 'in front of them'
      ];
      final isExposing = exposingKeywords.any((keyword) => text.contains(keyword));
      
      if (hasProtectiveLanguage && !isExposing) {
        protectiveMessages++;
      } else if (tone == 'alert' && _mentionsChildren(text)) {
        // Deduct for conflict that mentions children
        protectiveMessages--;
      }
    }
    
    return (protectiveMessages / totalMessages).clamp(0.0, 1.0);
  }

  double _calculateScheduleHarmony() {
    if (analyses.isEmpty) return 0.0;
    
    int schedulingMessages = 0;
    int smoothSchedulingMessages = 0;
    
    for (final analysis in analyses) {
      final text = (analysis['text'] as String? ?? '').toLowerCase();
      final tone = analysis['tone_status'] as String? ?? 'neutral';
      
      final schedulingKeywords = [
        'pickup', 'drop off', 'schedule', 'time', 'when', 'where',
        'appointment', 'event', 'practice', 'school', 'activity'
      ];
      
      if (schedulingKeywords.any((keyword) => text.contains(keyword))) {
        schedulingMessages++;
        
        // Smooth scheduling indicators
        final cooperativeKeywords = [
          'works for me', 'sounds good', 'that\'s fine', 'no problem',
          'i can do', 'let me check', 'i\'ll handle', 'we can work'
        ];
        
        if (tone != 'alert' && cooperativeKeywords.any((keyword) => text.contains(keyword))) {
          smoothSchedulingMessages++;
        }
      }
    }
    
    return schedulingMessages > 0 
      ? (smoothSchedulingMessages / schedulingMessages).clamp(0.0, 1.0)
      : 0.8; // Default good score if no scheduling discussions
  }

  double _calculateEmotionalSafety() {
    if (analyses.isEmpty) return 0.0;
    
    int emotionalMessages = 0;
    int safeEmotionalMessages = 0;
    
    for (final analysis in analyses) {
      final text = (analysis['text'] as String? ?? '').toLowerCase();
      final tone = analysis['tone_status'] as String? ?? 'neutral';
      
      // Look for emotional content
      final emotionalKeywords = [
        'feel', 'hurt', 'sad', 'angry', 'upset', 'frustrated',
        'happy', 'excited', 'worried', 'anxious', 'love', 'care'
      ];
      
      if (emotionalKeywords.any((keyword) => text.contains(keyword))) {
        emotionalMessages++;
        
        // Safe emotional expression indicators
        final safeEmotionalKeywords = [
          'i feel', 'i\'m feeling', 'it makes me', 'i experience',
          'help me understand', 'i need', 'i would like'
        ];
        
        final isIStatement = safeEmotionalKeywords.any((keyword) => text.contains(keyword));
        
        if ((tone == 'neutral' || tone == 'clear') && isIStatement) {
          safeEmotionalMessages++;
        }
      }
    }
    
    return emotionalMessages > 0 
      ? (safeEmotionalMessages / emotionalMessages).clamp(0.0, 1.0)
      : 0.7; // Default moderate score if no emotional discussions
  }

  bool _hasTriangulation() {
    if (analyses.isEmpty) return false;
    
    for (final analysis in analyses) {
      final text = (analysis['text'] as String? ?? '').toLowerCase();
      
      // Triangulation patterns: putting children in the middle
      final triangulationKeywords = [
        'tell your dad', 'tell your mom', 'ask your father', 'ask your mother',
        'kids said', 'they told me', 'go ask', 'tell them that',
        'your dad thinks', 'your mom said', 'take sides', 'choose between'
      ];
      
      if (triangulationKeywords.any((keyword) => text.contains(keyword))) {
        return true;
      }
    }
    
    return false;
  }

  bool _mentionsChildren(String text) {
    final childKeywords = [
      'kids', 'children', 'son', 'daughter', 'child', 'baby',
      'toddler', 'teenager', 'student'
    ];
    return childKeywords.any((keyword) => text.contains(keyword));
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    String description,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getChildFirstDescription(double score) {
    if (score >= 0.8) return 'Excellent child-centered communication';
    if (score >= 0.6) return 'Good focus on children\'s needs';
    if (score >= 0.4) return 'Some child-focused language';
    return 'Focus more on children\'s wellbeing';
  }

  Color _getConversationTypeColor(String type) {
    switch (type) {
      case 'child_focused': return Colors.green;
      case 'supportive': return Colors.blue;
      case 'logistics': return Colors.purple;
      case 'conflict': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getConversationTypeLabel(String type) {
    switch (type) {
      case 'child_focused': return 'Child-Focused';
      case 'supportive': return 'Supportive';
      case 'logistics': return 'Logistics';
      case 'conflict': return 'Conflict';
      default: return 'Other';
    }
  }

  String _getCoParentingInsight(Map<String, dynamic> insights) {
    final childFirstScore = insights['childFirstScore'] as double;
    final unityScore = insights['unityScore'] as double;

    if (childFirstScore >= 0.8 && unityScore >= 0.8) {
      return 'Your unified, child-centered approach creates emotional security. Children of cooperative co-parents show 40% better emotional regulation.';
    } else if (childFirstScore >= 0.6) {
      return 'You\'re doing well focusing on the children. Research shows kids thrive when parents maintain child-first communication, even during disagreements.';
    } else {
      return 'Try shifting more conversations toward your children\'s needs and experiences. Kids benefit most when they feel like the priority, not the problem.';
    }
  }
}
