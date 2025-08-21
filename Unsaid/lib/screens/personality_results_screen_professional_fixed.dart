import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_button.dart';
import '../services/secure_storage_service.dart';
import '../data/randomized_personality_questions.dart';
import '../data/attachment_assessment.dart';
import '../data/assessment_integration.dart';

class PersonalityResultsScreenProfessional extends StatefulWidget {
  final List<String> answers;
  final List<String>?
      communicationAnswers; // Optional: pass communication answers

  const PersonalityResultsScreenProfessional({
    super.key,
    required this.answers,
    this.communicationAnswers,
  });

  @override
  State<PersonalityResultsScreenProfessional> createState() =>
      _PersonalityResultsScreenProfessionalState();
}

class _PersonalityResultsScreenProfessionalState
    extends State<PersonalityResultsScreenProfessional>
    with TickerProviderStateMixin {
  static const Map<String, String> typeLabels = {
    'A': "Anxious Attachment",
    'B': "Secure Attachment",
    'C': "Dismissive Avoidant",
    'D': "Disorganized/Fearful Avoidant",
  };

  static const Map<String, String> typeDescriptions = {
    'A':
        "You crave deep connection but sometimes worry about your relationships. You may need frequent reassurance and fear abandonment, but you're also highly empathetic and caring.",
    'B':
        "You communicate openly and handle conflicts constructively. You're comfortable with both intimacy and independence, and you trust that relationships can be secure and lasting.",
    'C':
        "You value your independence and prefer emotional self-reliance. You may feel uncomfortable with too much closeness and prefer to process emotions internally rather than sharing them.",
    'D':
        "You have a complex relationship with closeness - both craving and fearing it. You may struggle with trust and send mixed signals about how much connection you want.",
  };

  static const Map<String, List<String>> typeStrengths = {
    'A': [
      "Highly empathetic and caring",
      "Intuitive about emotions",
      "Seeks meaningful connections",
      "Emotionally expressive",
    ],
    'B': [
      "Emotionally balanced",
      "Clear communicator",
      "Handles conflict constructively",
      "Comfortable with intimacy",
    ],
    'C': [
      "Independent and self-reliant",
      "Respects personal boundaries",
      "Thoughtful decision maker",
      "Emotionally self-sufficient",
    ],
    'D': [
      "Adaptable to different situations",
      "Complex emotional understanding",
      "Aware of relationship dynamics",
      "Capable of deep connections",
    ],
  };

  static const Map<String, String> commLabels = {
    'assertive': "Assertive",
    'passive': "Passive",
    'aggressive': "Aggressive",
    'passive-aggressive': "Passive-Aggressive",
  };

  static const Map<String, String> commDescriptions = {
    'assertive': "Clear, direct, respectful communication.",
    'passive': "Avoids conflict, may not express needs.",
    'aggressive': "Forceful, dominating, may disregard others.",
    'passive-aggressive': "Indirect, may express anger subtly.",
  };

  static const Map<String, Color> commColors = {
    'assertive': Color(0xFF4CAF50), // Green
    'passive': Color(0xFFFFD600), // Yellow
    'aggressive': Color(0xFFFF1744), // Red
    'passive-aggressive': Color(0xFF9C27B0), // Purple
  };

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

    // Save personality test results
    _savePersonalityResults();
  }

  /// Normalize to the 4 styles your UI supports
  String _normalizeCommStyle(String raw) {
    switch (raw) {
      case 'direct': // map to a supported bucket
        return 'assertive';
      case 'supportive':
        return 'passive'; // or 'assertive'—pick your intended bucket
      default:
        return raw; // assertive, passive, aggressive, passive-aggressive
    }
  }

  /// Save personality test results to secure storage
  Future<void> _savePersonalityResults() async {
    try {
      final storage = SecureStorageService();

      // Get the questions to match answers for modern scoring
      final questions = PersonalityTest.getQuestionsWithShuffledAnswers();

      // Use modern dimensional scoring
      final dimensions =
          PersonalityTest.calculateDimensionalScores(widget.answers, questions);
      final attachmentStyle = inferAttachmentStyle(dimensions);

      // Legacy counts for backward compatibility and display
      final Map<String, int> counts = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
      for (int i = 0; i < widget.answers.length && i < questions.length; i++) {
        final answer = widget.answers[i];
        final question = questions[i];
        final optionIndex =
            question.options.indexWhere((option) => option.text == answer);
        if (optionIndex != -1 && question.options[optionIndex].type != null) {
          final type = question.options[optionIndex].type!;
          counts[type] = (counts[type] ?? 0) + 1;
        }
      }

      // Map attachment style enum to string and legacy type
      final attachmentStyleString = attachmentStyle.shortName.toLowerCase();
      final dominantType = attachmentStyleString == 'anxious'
          ? 'A'
          : attachmentStyleString == 'secure'
              ? 'B'
              : attachmentStyleString == 'avoidant'
                  ? 'C'
                  : 'D';

      // Get communication style and normalize it
      final rawCommStyle = _getDominantCommStyleFromAttachment(
          attachmentStyleString, dimensions);
      final commStyle = _normalizeCommStyle(rawCommStyle);

      // Save the results to secure storage
      await storage.storePersonalityTestResults({
        'answers': widget.answers,
        'communication_answers': widget.communicationAnswers ?? [],
        'counts': counts,
        'dimensions': dimensions, // Store continuous scores
        'dominant_type': dominantType,
        'dominant_type_label': typeLabels[dominantType] ?? 'Unknown',
        'attachment_style':
            attachmentStyleString, // Use modern attachment style
        'communication_style': commStyle,
        'communication_style_label': commLabels[commStyle] ?? 'Unknown',
        'test_completed_at': DateTime.now().toIso8601String(),
      });

      // Also push to iOS so the keyboard bridge can see it immediately
      const channel = MethodChannel('com.example.unsaid/personality');
      await channel.invokeMethod('storePersonality', {
        'counts': counts, // Map<String,int>
        'dimensions': dimensions, // Map<String,double>
        'dominant_type': dominantType, // "A"/"B"/"C"/"D"
        'dominant_type_label': typeLabels[dominantType] ?? 'Unknown',
        'attachment_style':
            attachmentStyleString, // "anxious"/"secure"/"avoidant"/"disorganized"
        'communication_style': commStyle, // normalized value
        'communication_style_label': commLabels[commStyle] ?? 'Unknown',
        'test_completed_at': DateTime.now().toIso8601String(),
      });

      print('Personality test results saved successfully');
    } catch (e) {
      print('Error saving personality test results: $e');
    }
  }

  @override
  void dispose() {
    _chartController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Map<String, Color> get typeColors => {
        'A': AppTheme.of(context).error,
        'B': AppTheme.of(context).success,
        'C': AppTheme.of(context).info,
        'D': AppTheme.of(context).warning,
      };

  /// Get dominant communication style based on attachment style and dimensional scores
  String _getDominantCommStyleFromAttachment(
      String attachmentStyle, Map<String, double> dimensions) {
    final anxiety = dimensions['anxiety'] ?? 3.0;
    final avoidance = dimensions['avoidance'] ?? 3.0;

    // Base communication style on attachment style with nuance from dimensional scores
    switch (attachmentStyle) {
      case 'secure':
        return 'assertive';
      case 'anxious':
        // High anxiety typically correlates with more passive or emotional communication
        return anxiety > 4.0 ? 'passive' : 'assertive';
      case 'avoidant':
        // High avoidance typically correlates with more direct/blunt communication
        return avoidance > 4.0 ? 'direct' : 'assertive';
      case 'disorganized':
        // Disorganized may fluctuate, but lean toward more careful communication
        return 'supportive';
      default:
        return 'assertive';
    }
  }

  // Mock: Determine dominant communication style from answers (replace with real logic)
  String getDominantCommStyle() {
    // Legacy method - kept for backward compatibility if needed elsewhere
    final commAnswers = widget.communicationAnswers ?? [];
    if (commAnswers.isEmpty) return 'assertive'; // fallback
    final Map<String, int> counts = {
      'assertive': 0,
      'passive': 0,
      'aggressive': 0,
      'passive-aggressive': 0,
    };
    for (final ans in commAnswers) {
      final key = ans.toLowerCase();
      if (counts.containsKey(key)) counts[key] = counts[key]! + 1;
    }
    String dominant = 'assertive';
    int max = 0;
    counts.forEach((k, v) {
      if (v > max) {
        dominant = k;
        max = v;
      }
    });
    return dominant;
  }

  // Personalized tip based on attachment style
  String getPersonalizedTip(String type, String commStyle) {
    switch (type) {
      case 'A':
        return "Growth Tip: Practice self-soothing techniques and remind yourself that your worth isn't dependent on others' approval. Try expressing your needs directly rather than waiting for reassurance.";
      case 'B':
        return "Growth Tip: You have a healthy attachment style! Continue nurturing your relationships through open communication and being present for both yourself and others.";
      case 'C':
        return "Growth Tip: Consider gradually sharing more of your inner world with trusted people. Remember that vulnerability can strengthen relationships without compromising your independence.";
      case 'D':
        return "Growth Tip: Notice when you're sending mixed signals and try to identify what you really need. Practice grounding techniques to help you feel more secure in your connections.";
      default:
        return "Growth Tip: Focus on understanding your attachment patterns and how they affect your relationships.";
    }
  }

  /// Check if user qualifies for modern assessment upgrade
  bool _shouldOfferUpgrade(String dominantType, Map<String, double> dimensions) {
    // Offer upgrade if:
    // 1. User shows mixed attachment patterns (close dimensional scores)
    // 2. Has anxious or disorganized attachment (could benefit from detailed insights)
    // 3. Dimensional scores are close to boundaries (uncertain results)
    
    final anxiety = dimensions['anxiety'] ?? 3.0;
    final avoidance = dimensions['avoidance'] ?? 3.0;
    final disorganized = dimensions['disorganized'] ?? 3.0;
    
    // Check for mixed patterns (scores close to thresholds)
    bool mixedPattern = (anxiety - 2.5).abs() < 0.5 || (avoidance - 2.5).abs() < 0.5;
    
    // Check for anxious or disorganized patterns that could benefit from detailed assessment
    bool complexPattern = dominantType == 'A' || dominantType == 'D';
    
    // Check for high dimensional scores (intense patterns)
    bool intensePattern = anxiety > 4.0 || avoidance > 4.0 || disorganized > 4.0;
    
    return mixedPattern || complexPattern || intensePattern;
  }

  Widget _buildUpgradeOption(BuildContext context, AppTheme theme, String dominantType, Map<String, double> dimensions) {
    if (!_shouldOfferUpgrade(dominantType, dimensions)) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(theme.spacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primary.withOpacity(0.1),
            theme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(theme.radius.lg),
        border: Border.all(
          color: theme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                color: theme.primary,
                size: 24,
              ),
              SizedBox(width: theme.spacing.sm),
              Expanded(
                child: Text(
                  'Enhanced Assessment Available',
                  style: theme.typography.subtitle.copyWith(
                    color: theme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: theme.spacing.sm),
          Text(
            'Your results suggest you might benefit from our enhanced attachment assessment. Get deeper insights with validated psychological measures and personalized recommendations.',
            style: theme.typography.body.copyWith(
              color: theme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: theme.spacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/personality_test_modern');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primary,
                side: BorderSide(color: theme.primary, width: 1.5),
                padding: EdgeInsets.symmetric(
                  vertical: theme.spacing.md,
                  horizontal: theme.spacing.lg,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(theme.radius.md),
                ),
              ),
              icon: const Icon(Icons.upgrade, size: 20),
              label: Text(
                'Take Enhanced Assessment',
                style: theme.typography.button.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    // Get questions and use modern scoring
    final questions = PersonalityTest.getQuestionsWithShuffledAnswers();
    final dimensions =
        PersonalityTest.calculateDimensionalScores(widget.answers, questions);
    final attachmentStyle = inferAttachmentStyle(dimensions);

    // Legacy counts for display purposes
    final Map<String, int> counts = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
    for (int i = 0; i < widget.answers.length && i < questions.length; i++) {
      final answer = widget.answers[i];
      final question = questions[i];
      final optionIndex =
          question.options.indexWhere((option) => option.text == answer);
      if (optionIndex != -1 && question.options[optionIndex].type != null) {
        final type = question.options[optionIndex].type!;
        counts[type] = (counts[type] ?? 0) + 1;
      }
    }

    // Map modern attachment style to legacy type for display
    final attachmentStyleString = attachmentStyle.shortName.toLowerCase();
    final dominantType = attachmentStyleString == 'anxious'
        ? 'A'
        : attachmentStyleString == 'secure'
            ? 'B'
            : attachmentStyleString == 'avoidant'
                ? 'C'
                : 'D';

    // Pie chart data (based on dimensional scores for better accuracy)
    final List<PieChartSectionData> pieSections = [
      if (dimensions['anxiety']! > 2.5)
        PieChartSectionData(
          color: typeColors['A'],
          value: dimensions['anxiety']!,
          title: '${(dimensions['anxiety']! * 20).toInt()}%',
          titleStyle: theme.typography.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          radius: 80,
          titlePositionPercentageOffset: 0.6,
        ),
      if (dimensions['anxiety']! <= 2.5 && dimensions['avoidance']! <= 2.5)
        PieChartSectionData(
          color: typeColors['B'],
          value: 5.0 - dimensions['anxiety']! - dimensions['avoidance']!,
          title:
              '${((5.0 - dimensions['anxiety']! - dimensions['avoidance']!) * 20).toInt()}%',
          titleStyle: theme.typography.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          radius: 80,
          titlePositionPercentageOffset: 0.6,
        ),
      if (dimensions['avoidance']! > 2.5)
        PieChartSectionData(
          color: typeColors['C'],
          value: dimensions['avoidance']!,
          title: '${(dimensions['avoidance']! * 20).toInt()}%',
          titleStyle: theme.typography.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          radius: 80,
          titlePositionPercentageOffset: 0.6,
        ),
      if (dimensions['disorganized']! > 3.0)
        PieChartSectionData(
          color: typeColors['D'],
          value: dimensions['disorganized']!,
          title: '${(dimensions['disorganized']! * 20).toInt()}%',
          titleStyle: theme.typography.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          radius: 80,
          titlePositionPercentageOffset: 0.6,
        ),
    ];

    // Communication style logic using modern approach with normalization
    final String rawCommStyle =
        _getDominantCommStyleFromAttachment(attachmentStyleString, dimensions);
    final String dominantCommStyle = _normalizeCommStyle(rawCommStyle);
    final Color commColor = commColors[dominantCommStyle] ?? Colors.grey;
    final String commLabel = commLabels[dominantCommStyle] ?? 'Unknown';
    final String commDesc = commDescriptions[dominantCommStyle] ?? '';

    final String tip = getPersonalizedTip(dominantType, dominantCommStyle);

    return Scaffold(
      backgroundColor: theme.backgroundPrimary,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.backgroundPrimary, theme.backgroundSecondary],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(theme.spacing.lg),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(theme.spacing.md),
                        decoration: BoxDecoration(
                          color: theme.surfacePrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            theme.borderRadius.md,
                          ),
                        ),
                        child: Image.asset(
                          'assets/logo_icon.png',
                          width: 40,
                          height: 40,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Your Results',
                        style: theme.typography.headingLarge.copyWith(
                          color: theme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 60), // Balance the logo button
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: theme.spacing.lg),
                  child: Column(
                    children: [
                      // Logo and main title
                      Container(
                        padding: EdgeInsets.all(theme.spacing.xl),
                        decoration: BoxDecoration(
                          color: theme.surfacePrimary,
                          borderRadius: BorderRadius.circular(
                            theme.borderRadius.lg,
                          ),
                          boxShadow: theme.shadows.medium,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [theme.primary, theme.secondary],
                                ),
                                borderRadius: BorderRadius.circular(
                                  theme.borderRadius.lg,
                                ),
                                boxShadow: theme.shadows.small,
                              ),
                              child: const Icon(
                                Icons.psychology_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            SizedBox(height: theme.spacing.lg),
                            Text(
                              'Your Communication Type',
                              style: theme.typography.headingMedium.copyWith(
                                color: theme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: theme.spacing.xl * 2),
                      // Chart section
                      AnimatedBuilder(
                        animation: _chartAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _chartAnimation.value,
                            child: Container(
                              padding: EdgeInsets.all(
                                theme.spacing.xl * 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: theme.surfacePrimary,
                                borderRadius: BorderRadius.circular(
                                  theme.borderRadius.lg,
                                ),
                                boxShadow: theme.shadows.medium,
                              ),
                              child: Column(
                                children: [
                                  SizedBox(height: theme.spacing.lg),
                                  SizedBox(
                                    height: 200,
                                    child: pieSections.isNotEmpty
                                        ? PieChart(
                                            PieChartData(
                                              sections: pieSections,
                                              centerSpaceRadius: 60,
                                              sectionsSpace: 4,
                                              startDegreeOffset: -90,
                                            ),
                                            swapAnimationDuration:
                                                const Duration(
                                              milliseconds: 800,
                                            ),
                                            swapAnimationCurve:
                                                Curves.easeInOutCubic,
                                          )
                                        : Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.pie_chart_outline,
                                                  size: 48,
                                                  color: theme.textSecondary,
                                                ),
                                                SizedBox(
                                                  height: theme.spacing.sm,
                                                ),
                                                Text(
                                                  'No personality data available',
                                                  style: theme
                                                      .typography.bodyMedium
                                                      .copyWith(
                                                    color: theme.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                  SizedBox(height: theme.spacing.xl * 2),
                                  // Legend
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: theme.spacing.md,
                                    runSpacing: theme.spacing.sm,
                                    children: typeLabels.entries.map((entry) {
                                      return Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: theme.spacing.md,
                                          vertical: theme.spacing.sm,
                                        ),
                                        decoration: BoxDecoration(
                                          color: typeColors[entry.key]!
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            theme.borderRadius.sm,
                                          ),
                                          border: Border.all(
                                            color: typeColors[entry.key]!
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: typeColors[entry.key],
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            SizedBox(width: theme.spacing.xs),
                                            Text(
                                              entry.value,
                                              style: theme.typography.bodySmall
                                                  .copyWith(
                                                color: theme.textPrimary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  SizedBox(height: theme.spacing.lg),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: theme.spacing.xl * 2),
                      // Results content
                      FadeTransition(
                        opacity: _contentAnimation,
                        child: Column(
                          children: [
                            // Dominant type card
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(theme.spacing.xl),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    typeColors[dominantType]!.withOpacity(0.1),
                                    typeColors[dominantType]!.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  theme.borderRadius.lg,
                                ),
                                border: Border.all(
                                  color: typeColors[dominantType]!.withOpacity(
                                    0.3,
                                  ),
                                  width: 2,
                                ),
                                boxShadow: theme.shadows.medium,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(theme.spacing.md),
                                    decoration: BoxDecoration(
                                      color: typeColors[dominantType],
                                      borderRadius: BorderRadius.circular(
                                        theme.borderRadius.md,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.star_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  SizedBox(height: theme.spacing.lg),
                                  Text(
                                    'You are most likely:',
                                    style: theme.typography.bodyLarge.copyWith(
                                      color: theme.textSecondary,
                                    ),
                                  ),
                                  SizedBox(height: theme.spacing.sm),
                                  Text(
                                    typeLabels[dominantType]!,
                                    style:
                                        theme.typography.headingLarge.copyWith(
                                      color: typeColors[dominantType],
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: theme.spacing.lg),
                                  Text(
                                    typeDescriptions[dominantType]!,
                                    style: theme.typography.bodyMedium.copyWith(
                                      color: theme.textPrimary,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: theme.spacing.lg * 2),
                                  // Communication style surfaced here
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: commColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            commLabel,
                                            style: theme.typography.bodyLarge
                                                .copyWith(
                                              color: commColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            commDesc,
                                            style: theme.typography.bodySmall
                                                .copyWith(
                                              color: theme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (tip.isNotEmpty) ...[
                                    SizedBox(height: theme.spacing.lg),
                                    Container(
                                      padding: EdgeInsets.all(theme.spacing.md),
                                      decoration: BoxDecoration(
                                        color: commColor.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(
                                          theme.borderRadius.md,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.lightbulb,
                                              color: commColor, size: 20),
                                          SizedBox(width: theme.spacing.sm),
                                          Expanded(
                                            child: Text(
                                              tip,
                                              style: theme.typography.bodySmall
                                                  .copyWith(
                                                color: commColor,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            SizedBox(height: theme.spacing.xl),

                            // Strengths section
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(theme.spacing.xl),
                              decoration: BoxDecoration(
                                color: theme.surfacePrimary,
                                borderRadius: BorderRadius.circular(
                                  theme.borderRadius.lg,
                                ),
                                boxShadow: theme.shadows.medium,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.emoji_events_rounded,
                                        color: theme.primary,
                                        size: 24,
                                      ),
                                      SizedBox(width: theme.spacing.sm),
                                      Text(
                                        'Your Strengths',
                                        style: theme.typography.headingMedium
                                            .copyWith(color: theme.textPrimary),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: theme.spacing.lg),
                                  ...typeStrengths[dominantType]!.map(
                                    (strength) => Padding(
                                      padding: EdgeInsets.only(
                                        bottom: theme.spacing.sm,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: theme.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          SizedBox(width: theme.spacing.sm),
                                          Expanded(
                                            child: Text(
                                              strength,
                                              style: theme.typography.bodyMedium
                                                  .copyWith(
                                                color: theme.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: theme.spacing.xl),

                      // Modern Assessment Upgrade Option
                      _buildUpgradeOption(context, theme, dominantType, dimensions),

                      SizedBox(height: theme.spacing.lg),

                      // Next button
                      PremiumButton(
                        text: 'Continue to Tone Tutorial',
                        onPressed: () {
                          Navigator.pushNamed(context, '/tone_tutorial');
                        },
                        fullWidth: true,
                      ),

                      SizedBox(height: theme.spacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
