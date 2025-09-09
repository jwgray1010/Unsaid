import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/secure_storage_service.dart';
import '../data/attachment_assessment.dart';
import '../data/assessment_integration.dart';

class PersonalityResultsScreen extends StatefulWidget {
  final MergedConfig config;
  final AttachmentScores scores;
  final GoalRoutingResult routing;
  final Map<String, int> responses;

  const PersonalityResultsScreen({
    super.key,
    required this.config,
    required this.scores,
    required this.routing,
    required this.responses,
  });

  @override
  State<PersonalityResultsScreen> createState() =>
      _PersonalityResultsScreenState();
}

class _PersonalityResultsScreenState extends State<PersonalityResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _chartController;
  late AnimationController _contentController;
  late Animation<double> _chartAnimation;
  late Animation<double> _contentAnimation;

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _chartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chartController, curve: Curves.easeOutCubic),
    );

    _contentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    _chartController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      _contentController.forward();
    });

    // Save results to storage
    _savePersonalityResults();
  }

  @override
  void dispose() {
    _chartController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// Save personality test results to secure storage
  Future<void> _savePersonalityResults() async {
    try {
      final storage = SecureStorageService();

      // Save comprehensive results
      await storage.storePersonalityTestResults({
        'responses': widget.responses,
        'anxiety_score': widget.scores.anxiety,
        'avoidance_score': widget.scores.avoidance,
        'reliability_alpha': widget.scores.reliabilityAlpha,
        'attention_passed': widget.scores.attentionPassed,
        'social_desirability': widget.scores.socialDesirability,
        'disorganized_lean': widget.scores.disorganizedLean,
        'attachment_quadrant': widget.scores.quadrant,
        'confidence_label': widget.scores.confidenceLabel,
        'primary_profile': widget.config.primaryProfile,
        'route_tags': widget.routing.routeTags.toList(),
        'recommendation_gating': widget.config.recommendationGating,
        'test_completed_at': DateTime.now().toIso8601String(),
        'assessment_version': 'modern_v1.0',
      });

      // Also push to iOS for keyboard extension
      const channel = MethodChannel('com.example.unsaid/personality');
      await channel.invokeMethod('storeModernPersonality', {
        'anxiety_score': widget.scores.anxiety,
        'avoidance_score': widget.scores.avoidance,
        'attachment_quadrant': widget.scores.quadrant,
        'primary_profile': widget.config.primaryProfile,
        'confidence_label': widget.scores.confidenceLabel,
        'recommendation_gating': widget.config.recommendationGating,
        'test_completed_at': DateTime.now().toIso8601String(),
      });

      print('Modern personality test results saved successfully');
    } catch (e) {
      print('Error saving personality test results: $e');
    }
  }

  Color _getQuadrantColor(String quadrant) {
    switch (quadrant) {
      case 'secure':
        return const Color(0xFF4CAF50); // Green
      case 'anxious':
        return const Color(0xFFFF6B6B); // Red
      case 'avoidant':
        return const Color(0xFF4ECDC4); // Teal
      case 'disorganized_lean':
      case 'mixed':
        return const Color(0xFFFFB74D); // Orange
      default:
        return Colors.grey;
    }
  }

  String _getQuadrantDescription(String quadrant) {
    return AssessmentIntegration.getAttachmentDescription(quadrant);
  }

  String _getProfileDescription(String profile) {
    switch (profile) {
      case 'dating_sensitive':
        return 'Gentle, reassurance-oriented approach for relationship building';
      case 'empathetic_mirror':
        return 'Focuses on validation, reflection, and emotional expression';
      case 'secure_training':
        return 'Builds toward steady, balanced communication patterns';
      case 'coparenting_support':
        return 'Child-centric, solution-focused communication style';
      case 'boundary_forward':
        return 'Clear, firm communication without harsh escalation';
      case 'deescalator':
        return 'Prioritizes calm responses and conflict reduction';
      case 'balanced':
        return 'Neutral, adaptable approach for various situations';
      default:
        return 'Personalized communication recommendations';
    }
  }

  Widget _buildScoreCard(
      String title, String value, String subtitle, Color color, IconData icon) {
    return FadeTransition(
      opacity: _contentAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentChart() {
    return FadeTransition(
      opacity: _chartAnimation,
      child: Container(
        height: 250,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'Attachment Dimensions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: RadarChart(
                RadarChartData(
                  dataSets: [
                    RadarDataSet(
                      dataEntries: [
                        RadarEntry(value: widget.scores.anxiety.toDouble()),
                        RadarEntry(value: widget.scores.avoidance.toDouble()),
                        RadarEntry(value: widget.scores.reliabilityAlpha * 100),
                      ],
                      fillColor: _getQuadrantColor(widget.scores.quadrant)
                          .withOpacity(0.2),
                      borderColor: _getQuadrantColor(widget.scores.quadrant),
                      borderWidth: 2,
                    ),
                  ],
                  radarBorderData: BorderSide(color: Colors.grey.shade300),
                  titleTextStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                  getTitle: (index, angle) {
                    switch (index) {
                      case 0:
                        return RadarChartTitle(
                            text: 'Anxiety\n${widget.scores.anxiety}%');
                      case 1:
                        return RadarChartTitle(
                            text: 'Avoidance\n${widget.scores.avoidance}%');
                      case 2:
                        return RadarChartTitle(
                            text:
                                'Reliability\n${(widget.scores.reliabilityAlpha * 100).round()}%');
                      default:
                        return const RadarChartTitle(text: '');
                    }
                  },
                  tickCount: 5,
                  ticksTextStyle: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                  gridBorderData: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityIndicators() {
    return FadeTransition(
      opacity: _contentAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assessment Quality',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Attention Check
            _buildQualityRow(
              'Attention Check',
              widget.scores.attentionPassed ? 'Passed' : 'Failed',
              widget.scores.attentionPassed ? Icons.check_circle : Icons.error,
              widget.scores.attentionPassed ? Colors.green : Colors.red,
            ),

            // Reliability
            _buildQualityRow(
              'Reliability (α)',
              '${(widget.scores.reliabilityAlpha * 100).round()}%',
              widget.scores.reliabilityAlpha > 0.7
                  ? Icons.psychology
                  : Icons.warning,
              widget.scores.reliabilityAlpha > 0.7
                  ? Colors.green
                  : widget.scores.reliabilityAlpha > 0.6
                      ? Colors.orange
                      : Colors.red,
            ),

            // Confidence
            _buildQualityRow(
              'Confidence',
              widget.scores.confidenceLabel,
              widget.scores.confidenceLabel == 'High'
                  ? Icons.star
                  : widget.scores.confidenceLabel == 'Moderate'
                      ? Icons.star_half
                      : Icons.star_border,
              widget.scores.confidenceLabel == 'High'
                  ? Colors.green
                  : widget.scores.confidenceLabel == 'Moderate'
                      ? Colors.orange
                      : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityRow(
      String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
      String title, String description, IconData icon, Color color) {
    return FadeTransition(
      opacity: _contentAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      height: 1.4,
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

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final quadrantColor = _getQuadrantColor(widget.scores.quadrant);

    return Scaffold(
      backgroundColor: theme.backgroundPrimary,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              quadrantColor.withOpacity(0.1),
              theme.backgroundPrimary,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                FadeTransition(
                  opacity: _contentAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Assessment Results',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Based on validated psychological research',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Key Metrics Row
                Row(
                  children: [
                    Expanded(
                      child: _buildScoreCard(
                        'Attachment Style',
                        widget.scores.quadrant
                            .replaceAll('_', ' ')
                            .toUpperCase(),
                        'Primary pattern',
                        quadrantColor,
                        Icons.favorite,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildScoreCard(
                        'Goal Profile',
                        widget.config.primaryProfile
                            .replaceAll('_', ' ')
                            .toUpperCase(),
                        'Communication focus',
                        const Color(0xFF45B7D1),
                        Icons.track_changes,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Attachment Chart
                _buildAttachmentChart(),

                const SizedBox(height: 24),

                // Quality Indicators
                _buildQualityIndicators(),

                const SizedBox(height: 24),

                // Insights
                _buildInsightCard(
                  'Attachment Insight',
                  _getQuadrantDescription(widget.scores.quadrant),
                  Icons.psychology,
                  quadrantColor,
                ),

                const SizedBox(height: 16),

                _buildInsightCard(
                  'Communication Profile',
                  _getProfileDescription(widget.config.primaryProfile),
                  Icons.chat_bubble_outline,
                  const Color(0xFF45B7D1),
                ),

                const SizedBox(height: 16),

                // Recommendation Gating Warning
                if (widget.config.recommendationGating)
                  _buildInsightCard(
                    'Personalization Notice',
                    'Based on your responses, we\'ll provide more conservative suggestions until we better understand your communication style.',
                    Icons.info_outline,
                    Colors.orange,
                  ),

                const SizedBox(height: 32),

                // Action Button
                FadeTransition(
                  opacity: _contentAnimation,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/premium');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: quadrantColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: quadrantColor.withOpacity(0.3),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rocket_launch, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Start Using Unsaid',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
