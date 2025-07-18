import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_button.dart';
import '../services/secure_storage_service.dart';
import '../services/personality_data_bridge.dart';

class PersonalityResultsScreenProfessional extends StatefulWidget {
  final List<String> answers;
  final List<String>? communicationAnswers; // Optional: pass communication answers

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

  // Mapping from personality types to attachment style strings for iOS keyboard
  static const Map<String, String> attachmentStyleMapping = {
    'A': "anxious",
    'B': "secure",
    'C': "avoidant",
    'D': "disorganized",
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

  /// Save personality test results to secure storage
  Future<void> _savePersonalityResults() async {
    try {
      final storage = SecureStorageService();
      
      // Count each type
      final Map<String, int> counts = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
      for (final type in widget.answers) {
        if (counts.containsKey(type)) counts[type] = counts[type]! + 1;
      }

      // Find the dominant type
      String dominantType = 'A';
      int maxCount = counts['A']!;
      counts.forEach((k, v) {
        if (v > maxCount) {
          dominantType = k;
          maxCount = v;
        }
      });

      // Get communication style
      final commStyle = getDominantCommStyle();

      // Get attachment style for iOS keyboard
      final attachmentStyle = attachmentStyleMapping[dominantType] ?? 'unknown';

      // Save the results
      await storage.storePersonalityTestResults({
        'answers': widget.answers,
        'communication_answers': widget.communicationAnswers ?? [],
        'counts': counts,
        'dominant_type': dominantType,
        'dominant_type_label': typeLabels[dominantType] ?? 'Unknown',
        'attachment_style': attachmentStyle,  // Add attachment style for iOS keyboard
        'communication_style': commStyle,
        'communication_style_label': commLabels[commStyle] ?? 'Unknown',
        'test_completed_at': DateTime.now().toIso8601String(),
      });
      
      // Trigger debug output from iOS PersonalityDataManager
      try {
        await PersonalityDataBridge.debugPersonalityData();
      } catch (e) {
        print('Debug call failed: $e');
      }
      
      print(' Personality test results saved successfully');
    } catch (e) {
      print(' Error saving personality test results: $e');
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

  // Mock: Determine dominant communication style from answers (replace with real logic)
  String getDominantCommStyle() {
    // If you have communicationAnswers, count them
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

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    // Count each type
    final Map<String, int> counts = {'A': 0, 'B': 0, 'C': 0, 'D': 0};
    for (final type in widget.answers) {
      if (counts.containsKey(type)) counts[type] = counts[type]! + 1;
    }

    // Find the dominant type
    String dominantType = 'A';
    int maxCount = counts['A']!;
    counts.forEach((k, v) {
      if (v > maxCount) {
        dominantType = k;
        maxCount = v;
      }
    });

    // Pie chart data
    final totalAnswers = widget.answers.isNotEmpty
        ? widget.answers.length
        : 15; // fallback to 15 for mock data
    final List<PieChartSectionData> pieSections = counts.entries
        .where((e) => e.value > 0)
        .map(
          (e) => PieChartSectionData(
            color: typeColors[e.key],
            value: e.value.toDouble(),
            title: e.value > 0
                ? '${((e.value / totalAnswers) * 100).toInt()}%'
                : '',
            titleStyle: theme.typography.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            radius: 80,
            titlePositionPercentageOffset: 0.6,
          ),
        )
        .toList();

    // Communication style logic
    final String dominantCommStyle = getDominantCommStyle();
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
                    SizedBox(width: 60), // Balance the logo button
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
                              child: Icon(
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
                                                      .typography
                                                      .bodyMedium
                                                      .copyWith(
                                                        color:
                                                            theme.textSecondary,
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
                                    child: Icon(
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
                                    style: theme.typography.headingLarge
                                        .copyWith(
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            commLabel,
                                            style: theme.typography.bodyLarge.copyWith(
                                              color: commColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            commDesc,
                                            style: theme.typography.bodySmall.copyWith(
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
                                          Icon(Icons.lightbulb, color: commColor, size: 20),
                                          SizedBox(width: theme.spacing.sm),
                                          Expanded(
                                            child: Text(
                                              tip,
                                              style: theme.typography.bodySmall.copyWith(
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
