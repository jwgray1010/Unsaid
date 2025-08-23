import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../data/attachment_assessment.dart';
import '../data/assessment_integration.dart';

class ModernPersonalityTestScreen extends StatefulWidget {
  final int currentIndex;
  final Map<String, int> responses;
  final Future<void> Function()? markTestTaken;
  final void Function(MergedConfig config, AttachmentScores scores, GoalRoutingResult routing)? onComplete;

  const ModernPersonalityTestScreen({
    super.key,
    required this.currentIndex,
    required this.responses,
    this.onComplete,
    this.markTestTaken,
  });

  @override
  State<ModernPersonalityTestScreen> createState() =>
      _ModernPersonalityTestScreenState();
}

class _ModernPersonalityTestScreenState extends State<ModernPersonalityTestScreen> {
  int? _selectedValue;
  late List<PersonalityQuestion> _allQuestions;

  // Color mapping for different question types
  static const Map<String, Color> typeColors = {
    'anxiety': Color(0xFFFF6B6B),      // Warm red for anxiety items
    'avoidance': Color(0xFF4ECDC4),    // Teal for avoidance items
    'goal': Color(0xFF45B7D1),         // Blue for goal items
    'attention': Color(0xFFFF9F43),    // Orange for attention checks
    'social': Color(0xFF96CEB4),       // Green for social desirability
    'paradox': Color(0xFFA8E6CF),      // Light green for paradox items
  };

  @override
  void initState() {
    super.initState();
    
    // Combine all questions from the new assessment system
    _allQuestions = [
      ...attachmentItems,
      ...goalItems,
    ];

    // Load existing response for this question
    if (widget.currentIndex < _allQuestions.length) {
      final question = _allQuestions[widget.currentIndex];
      _selectedValue = widget.responses[question.id];
    }
  }

  PersonalityQuestion get currentQuestion => _allQuestions[widget.currentIndex];
  
  double get progress => (widget.currentIndex + 1) / _allQuestions.length;

  Color _getQuestionTypeColor(PersonalityQuestion question) {
    if (question.isAttentionCheck) return typeColors['attention']!;
    if (question.isSocialDesirability) return typeColors['social']!;
    if (question.isGoal) return typeColors['goal']!;
    if (question.dimension == Dimension.anxiety) return typeColors['anxiety']!;
    if (question.dimension == Dimension.avoidance) return typeColors['avoidance']!;
    if (question.id == 'PX1') return typeColors['paradox']!;
    return Colors.grey;
  }

  String _getQuestionTypeLabel(PersonalityQuestion question) {
    if (question.isAttentionCheck) return 'Attention Check';
    if (question.isSocialDesirability) return 'Response Style';
    if (question.isGoal) return 'Goal Setting';
    if (question.dimension == Dimension.anxiety) return 'Attachment - Anxiety';
    if (question.dimension == Dimension.avoidance) return 'Attachment - Avoidance';
    if (question.id == 'PX1') return 'Relationship Patterns';
    return 'Assessment';
  }

  void _selectAnswer(int value) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedValue = value;
      widget.responses[currentQuestion.id] = value;
    });
  }

  Future<void> _goNext() async {
    if (_selectedValue == null) {
      _showSelectionRequired();
      return;
    }

    HapticFeedback.mediumImpact();

    if (widget.currentIndex < _allQuestions.length - 1) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ModernPersonalityTestScreen(
              currentIndex: widget.currentIndex + 1,
              responses: widget.responses,
              onComplete: widget.onComplete,
              markTestTaken: widget.markTestTaken,
            ),
          ),
        );
      }
    } else {
      await _completeTest();
    }
  }

  Future<void> _goPrevious() async {
    if (widget.currentIndex > 0) {
      HapticFeedback.lightImpact();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ModernPersonalityTestScreen(
              currentIndex: widget.currentIndex - 1,
              responses: widget.responses,
              onComplete: widget.onComplete,
              markTestTaken: widget.markTestTaken,
            ),
          ),
        );
      }
    }
  }

  Future<void> _completeTest() async {
    if (widget.markTestTaken != null) {
      await widget.markTestTaken!();
    }

    try {
      // Run the new assessment system
      final assessmentResult = AttachmentAssessment.run(widget.responses);
      final mergedConfig = await AssessmentIntegration.selectConfiguration(
        assessmentResult.scores,
        assessmentResult.routing,
      );

      if (widget.onComplete != null) {
        widget.onComplete!(mergedConfig, assessmentResult.scores, assessmentResult.routing);
      }

      // Navigate to results with new data
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/personality_results_modern',
          arguments: {
            'config': mergedConfig,
            'scores': assessmentResult.scores,
            'routing': assessmentResult.routing,
            'responses': widget.responses,
          },
        );
      }
    } catch (e) {
      print('Error completing assessment: $e');
      // Fallback to legacy system or show error
      if (mounted) {
        _showError('Assessment processing failed. Please try again.');
      }
    }
  }

  void _showSelectionRequired() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 20,
              semanticLabel: 'Warning',
            ),
            const SizedBox(width: 12),
            Text(
              'Please select an answer to continue',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppTheme.spaceMD),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.currentIndex < 0 || widget.currentIndex >= _allQuestions.length) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
          child: const Center(
            child: Text(
              'Invalid question index',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      );
    }

    final question = currentQuestion;
    final questionTypeColor = _getQuestionTypeColor(question);
    final questionTypeLabel = _getQuestionTypeLabel(question);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header with progress
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceLG),
                child: Column(
                  children: [
                    // Progress bar
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spaceMD),

                    // Question counter and type
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${widget.currentIndex + 1} of ${_allQuestions.length}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: questionTypeColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: questionTypeColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            questionTypeLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLG),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTheme.spaceLG),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                          boxShadow: [
                            BoxShadow(
                              color: questionTypeColor.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Question type indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: questionTypeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: questionTypeColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: questionTypeColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    questionTypeLabel,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: questionTypeColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppTheme.spaceLG),

                            // Question text
                            Text(
                              question.question,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.white.withOpacity(0.5),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),

                            // Special instructions for attention check
                            if (question.isAttentionCheck) ...[
                              const SizedBox(height: AppTheme.spaceMD),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.orange.shade700,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Please read carefully and follow the instruction',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w500,
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

                      const SizedBox(height: AppTheme.spaceLG),

                      // Answer options
                      ...question.options.asMap().entries.map((entry) {
                        final option = entry.value;
                        final isSelected = _selectedValue == option.value;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppTheme.spaceMD),
                          child: GestureDetector(
                            onTap: () => _selectAnswer(option.value),
                            child: Container(
                              padding: const EdgeInsets.all(AppTheme.spaceLG),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                                border: Border.all(
                                  color: isSelected
                                      ? questionTypeColor
                                      : Colors.white.withOpacity(0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: questionTypeColor.withOpacity(0.2),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  // Selection indicator
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? questionTypeColor
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? questionTypeColor
                                            : Colors.white.withOpacity(0.7),
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16,
                                            semanticLabel: 'Selected',
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: AppTheme.spaceMD),
                                  Expanded(
                                    child: Text(
                                      option.text,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: isSelected
                                            ? questionTypeColor
                                            : Colors.white,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                  
                                  // Show route tag for goal questions
                                  if (question.isGoal && option.routeTag != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: questionTypeColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        option.routeTag!.replaceAll('_', ' '),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: isSelected
                                              ? questionTypeColor
                                              : Colors.white.withOpacity(0.8),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: AppTheme.space2XL),
                    ],
                  ),
                ),
              ),

              // Navigation buttons
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceLG),
                child: Row(
                  children: [
                    // Previous button
                    if (widget.currentIndex > 0)
                      Expanded(
                        child: Container(
                          height: 56,
                          margin: const EdgeInsets.only(right: AppTheme.spaceMD),
                          child: OutlinedButton.icon(
                            onPressed: _goPrevious,
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                              size: 18,
                              semanticLabel: 'Previous',
                            ),
                            label: Text(
                              'Previous',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Next button
                    Expanded(
                      flex: widget.currentIndex > 0 ? 1 : 1,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.9),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _goNext,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.currentIndex < _allQuestions.length - 1
                                        ? 'Next'
                                        : 'Complete Assessment',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spaceSM),
                                  Icon(
                                    widget.currentIndex < _allQuestions.length - 1
                                        ? Icons.arrow_forward_ios
                                        : Icons.psychology,
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                    semanticLabel: widget.currentIndex < _allQuestions.length - 1
                                        ? 'Next'
                                        : 'Complete',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Entry point to start the modern assessment
  static void startAssessment(BuildContext context, {
    Future<void> Function()? markTestTaken,
    void Function(MergedConfig config, AttachmentScores scores, GoalRoutingResult routing)? onComplete,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModernPersonalityTestScreen(
          currentIndex: 0,
          responses: const <String, int>{},
          markTestTaken: markTestTaken,
          onComplete: onComplete,
        ),
      ),
    );
  }
}
