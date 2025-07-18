import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/keyboard_manager.dart';
import '../widgets/tone_indicator.dart';

class KeyboardSetupScreen extends StatefulWidget {
  const KeyboardSetupScreen({super.key});

  @override
  State<KeyboardSetupScreen> createState() => _KeyboardSetupScreenState();
}

class _KeyboardSetupScreenState extends State<KeyboardSetupScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;

  final KeyboardManager _keyboardManager = KeyboardManager();
  bool _isLoading = false;
  final int _currentStep = 0;
  bool _faqExpanded = false;

  // Context and AI suggestion state
  String? _aiSuggestion;
  ToneStatus? _detectedToneStatus;
  final TextEditingController _previewTextController = TextEditingController(
    text: 'I appreciate your help!',
  );

  final List<String> _setupSteps = [
    'Add Keyboard',
    'Enable Full Access',
    'Set as Primary',
    'Test Keyboard',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeKeyboard();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _initializeKeyboard() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _keyboardManager.initialize();
    } catch (e) {
      // Handle initialization error
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleInstallKeyboard() async {
    // Keyboard installation logic
    try {
      await _keyboardManager.requestKeyboardInstallation();
    } catch (e) {
      // Handle installation error
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _previewTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    
    return Scaffold(
      backgroundColor: theme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: theme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Keyboard Setup',
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(AppThemeWrapper theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(theme.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(theme),
          SizedBox(height: theme.spacing.xl),
          _buildSetupSteps(theme),
          SizedBox(height: theme.spacing.xl),
          _buildDetailedInstructions(theme),
          SizedBox(height: theme.spacing.xl),
          _buildPreviewSection(theme),
          SizedBox(height: theme.spacing.xl),
          _buildFAQSection(theme),
          SizedBox(height: theme.spacing.xl),
          _buildActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(AppThemeWrapper theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Keyboard Extension',
          style: theme.textTheme.displayMedium?.copyWith(
            color: theme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: theme.spacing.sm),
        Text(
          'Get AI-powered tone suggestions and communication insights directly in your keyboard.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSetupSteps(AppThemeWrapper theme) {
    return Container(
      padding: EdgeInsets.all(theme.spacing.lg),
      decoration: BoxDecoration(
        color: theme.surfacePrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(theme.borderRadius.lg),
        border: Border.all(
          color: theme.borderColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Setup Steps',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: theme.spacing.md),
          ...List.generate(_setupSteps.length, (index) {
            final isCurrentStep = index == _currentStep;
            final isCompleted = index < _currentStep;
            
            return Padding(
              padding: EdgeInsets.only(bottom: theme.spacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted 
                          ? theme.success 
                          : isCurrentStep 
                              ? theme.primary 
                              : theme.surfacePrimary,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : Icons.circle,
                      size: 16,
                      color: isCompleted || isCurrentStep 
                          ? Colors.white 
                          : theme.textSecondary,
                    ),
                  ),
                  SizedBox(width: theme.spacing.sm),
                  Expanded(
                    child: Text(
                      _setupSteps[index],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isCurrentStep 
                            ? theme.textPrimary 
                            : theme.textSecondary,
                        fontWeight: isCurrentStep 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDetailedInstructions(AppThemeWrapper theme) {
    return Container(
      padding: EdgeInsets.all(theme.spacing.lg),
      decoration: BoxDecoration(
        color: theme.surfacePrimary,
        borderRadius: BorderRadius.circular(theme.borderRadius.lg),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.video_library_outlined,
                color: theme.primary,
                size: 24,
              ),
              SizedBox(width: theme.spacing.sm),
              Text(
                'Step-by-Step Setup Guide',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: theme.spacing.lg),
          
          // Step 1: Add Keyboard
          _buildInstructionStep(
            theme,
            1,
            'Add Keyboard to iOS',
            [
              'Open iPhone Settings app',
              'Tap "General"',
              'Tap "Keyboard"', 
              'Tap "Keyboards"',
              'Tap "Add New Keyboard..."',
              'Find and select "Unsaid" from the list',
            ],
            Icons.settings,
          ),
          
          SizedBox(height: theme.spacing.lg),
          
          // Step 2: Enable Full Access
          _buildInstructionStep(
            theme,
            2,
            'Enable Full Access (Important!)',
            [
              'In Keyboards list, tap "Unsaid"',
              'Toggle ON "Allow Full Access"',
              'Tap "Allow" when prompted',
              '✨ This enables AI tone analysis and suggestions',
            ],
            Icons.security,
            isImportant: true,
          ),
          
          SizedBox(height: theme.spacing.lg),
          
          // Step 3: Set as Primary
          _buildInstructionStep(
            theme,
            3,
            'Activate Unsaid Keyboard',
            [
              'Open any app with text input (Messages, Mail, etc.)',
              'Tap in a text field',
              'Press and hold the 🌐 globe icon',
              'Select "Unsaid" from the keyboard menu',
              'You should see tone indicators appear!',
            ],
            Icons.language,
          ),
          
          SizedBox(height: theme.spacing.md),
          
          // Important Note
          Container(
            padding: EdgeInsets.all(theme.spacing.md),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(theme.borderRadius.md),
              border: Border.all(color: theme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.primary,
                  size: 20,
                ),
                SizedBox(width: theme.spacing.sm),
                Expanded(
                  child: Text(
                    'Full Access is required for AI tone analysis. Your data stays private and secure.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(
    AppThemeWrapper theme,
    int stepNumber,
    String title,
    List<String> instructions,
    IconData icon, {
    bool isImportant = false,
  }) {
    return Container(
      padding: EdgeInsets.all(theme.spacing.md),
      decoration: BoxDecoration(
        color: isImportant 
            ? theme.primary.withOpacity(0.05)
            : theme.surfacePrimary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(theme.borderRadius.md),
        border: Border.all(
          color: isImportant 
              ? theme.primary.withOpacity(0.3)
              : theme.borderColor.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isImportant ? theme.primary : theme.textSecondary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    stepNumber.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: theme.spacing.sm),
              Icon(
                icon,
                color: isImportant ? theme.primary : theme.textSecondary,
                size: 20,
              ),
              SizedBox(width: theme.spacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: theme.spacing.sm),
          ...instructions.map((instruction) => Padding(
            padding: EdgeInsets.only(
              left: theme.spacing.xl,
              bottom: theme.spacing.xs,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textSecondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    instruction,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: instruction.startsWith('✨') 
                          ? theme.primary
                          : theme.textSecondary,
                      fontWeight: instruction.startsWith('✨') 
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPreviewSection(AppThemeWrapper theme) {
    return Container(
      padding: EdgeInsets.all(theme.spacing.lg),
      decoration: BoxDecoration(
        color: theme.surfacePrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(theme.borderRadius.lg),
        border: Border.all(
          color: theme.borderColor.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: theme.spacing.md),
          _buildMessagePreview(theme),
          SizedBox(height: theme.spacing.md),
          _buildToneAnalysis(theme),
        ],
      ),
    );
  }

  Widget _buildMessagePreview(AppThemeWrapper theme) {
    return Container(
      padding: EdgeInsets.all(theme.spacing.md),
      decoration: BoxDecoration(
        color: theme.surfacePrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(theme.borderRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type something to see tone analysis:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textSecondary,
            ),
          ),
          SizedBox(height: theme.spacing.sm),
          TextField(
            controller: _previewTextController,
            onChanged: (text) {
              // Trigger tone analysis
              _analyzeTonePreview(text);
            },
            decoration: InputDecoration(
              hintText: 'Type your message here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(theme.borderRadius.sm),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.backgroundPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToneAnalysis(AppThemeWrapper theme) {
    if (_detectedToneStatus == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(theme.spacing.md),
      decoration: BoxDecoration(
        color: theme.surfacePrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(theme.borderRadius.md),
      ),
      child: Row(
        children: [
          ToneIndicator(status: _detectedToneStatus!),
          SizedBox(width: theme.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detected Tone: ${_detectedToneStatus!.name}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_aiSuggestion != null) ...[
                  SizedBox(height: theme.spacing.xs),
                  Text(
                    _aiSuggestion!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(AppThemeWrapper theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _faqExpanded = !_faqExpanded;
            });
          },
          child: Container(
            padding: EdgeInsets.all(theme.spacing.md),
            decoration: BoxDecoration(
              color: theme.surfacePrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(theme.borderRadius.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Frequently Asked Questions',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  _faqExpanded ? Icons.expand_less : Icons.expand_more,
                  color: theme.textPrimary,
                ),
              ],
            ),
          ),
        ),
        if (_faqExpanded) ...[
          SizedBox(height: theme.spacing.md),
          _buildFAQItem(
            theme,
            'Why does Unsaid need "Full Access"?',
            'Full Access enables AI tone analysis and smart suggestions. Like Grammarly, this permission allows the keyboard to analyze your text and provide helpful recommendations. Your data stays private and secure.',
          ),
          _buildFAQItem(
            theme,
            'Is my data private and secure?',
            'Yes! All analysis happens locally on your device. No personal messages are sent to external servers. Full Access only enables the keyboard to function properly.',
          ),
          _buildFAQItem(
            theme,
            'How does the tone analysis work?',
            'The keyboard analyzes your typing patterns in real-time and provides color-coded tone indicators plus suggestions to help you communicate more effectively.',
          ),
          _buildFAQItem(
            theme,
            'Can I disable suggestions?',
            'Yes, you can customize or disable suggestions at any time in the keyboard settings within the app.',
          ),
          _buildFAQItem(
            theme,
            'What if I don\'t see the Unsaid keyboard?',
            'Make sure you\'ve added it in iPhone Settings > General > Keyboard > Keyboards. Then press and hold the globe icon when typing to switch keyboards.',
          ),
        ],
      ],
    );
  }

  Widget _buildFAQItem(AppThemeWrapper theme, String question, String answer) {
    return Container(
      margin: EdgeInsets.only(bottom: theme.spacing.sm),
      padding: EdgeInsets.all(theme.spacing.md),
      decoration: BoxDecoration(
        color: theme.surfacePrimary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(theme.borderRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: theme.spacing.xs),
          Text(
            answer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppThemeWrapper theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleInstallKeyboard,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: theme.spacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(theme.borderRadius.md),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Open iPhone Settings'),
          ),
        ),
        SizedBox(height: theme.spacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.textPrimary,
              side: BorderSide(color: theme.borderColor),
              padding: EdgeInsets.symmetric(vertical: theme.spacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(theme.borderRadius.md),
              ),
            ),
            child: const Text('Skip for Now'),
          ),
        ),
      ],
    );
  }

  void _analyzeTonePreview(String text) {
    if (text.isEmpty) {
      setState(() {
        _detectedToneStatus = null;
        _aiSuggestion = null;
      });
      return;
    }

    // Simple tone analysis for preview
    ToneStatus status = ToneStatus.neutral;
    String? suggestion;

    if (text.toLowerCase().contains('thanks') || 
        text.toLowerCase().contains('appreciate')) {
      status = ToneStatus.clear;
      suggestion = 'Great! This message conveys genuine appreciation.';
    } else if (text.toLowerCase().contains('sorry') || 
               text.toLowerCase().contains('apologize')) {
      status = ToneStatus.caution;
      suggestion = 'Consider being specific about what you\'re apologizing for.';
    } else if (text.toLowerCase().contains('urgent') || 
               text.toLowerCase().contains('asap')) {
      status = ToneStatus.alert;
      suggestion = 'Try adding context about why this is time-sensitive.';
    }

    setState(() {
      _detectedToneStatus = status;
      _aiSuggestion = suggestion;
    });
  }
}
