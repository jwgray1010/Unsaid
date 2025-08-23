import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/personality_data_manager.dart';
import '../navigation/app_router.dart';

class EmotionalStateScreen extends StatefulWidget {
  const EmotionalStateScreen({super.key});

  @override
  State<EmotionalStateScreen> createState() => _EmotionalStateScreenState();
}

class _EmotionalStateScreenState extends State<EmotionalStateScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String? selectedEmotionalState;
  bool isSubmitting = false;

  // The 7 emotional state options that map to our bucket system
  final List<EmotionalStateOption> emotionalStates = [
    const EmotionalStateOption(
      id: "completely_overwhelmed",
      label: "Completely overwhelmed",
      description: "Feeling like everything is too much right now",
      icon: Icons.waves,
      color: Color(0xFFE57373), // Red
      bucket: "highIntensity"
    ),
    const EmotionalStateOption(
      id: "tense_on_edge", 
      label: "Tense / on edge",
      description: "Feeling wound up and restless",
      icon: Icons.bolt,
      color: Color(0xFFFFB74D), // Orange
      bucket: "moderate"
    ),
    const EmotionalStateOption(
      id: "uneasy_unsettled",
      label: "Uneasy / unsettled", 
      description: "Something feels off but can't pinpoint what",
      icon: Icons.psychology,
      color: Color(0xFFFFD54F), // Yellow
      bucket: "moderate"
    ),
    const EmotionalStateOption(
      id: "neutral_distracted",
      label: "Neutral / distracted",
      description: "Not particularly up or down, just scattered",
      icon: Icons.radio_button_unchecked,
      color: Color(0xFF90A4AE), // Blue Grey
      bucket: "moderate"
    ),
    const EmotionalStateOption(
      id: "calm_centered",
      label: "Calm / centered",
      description: "Feeling balanced and present",
      icon: Icons.spa,
      color: Color(0xFF81C784), // Light Green
      bucket: "regulated"
    ),
    const EmotionalStateOption(
      id: "content_grounded",
      label: "Content / grounded",
      description: "Feeling stable and satisfied",
      icon: Icons.self_improvement,
      color: Color(0xFF64B5F6), // Blue
      bucket: "regulated"
    ),
    const EmotionalStateOption(
      id: "relaxed_at_ease",
      label: "Relaxed / at ease",
      description: "Feeling peaceful and comfortable",
      icon: Icons.airline_seat_flat,
      color: Color(0xFFBA68C8), // Purple
      bucket: "regulated"
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Store the emotional state in both local storage and shared UserDefaults
  /// This bridges the data to the iOS keyboard extension
  Future<void> _saveEmotionalState(EmotionalStateOption option) async {
    setState(() {
      isSubmitting = true;
    });

    try {
      // Store in SharedPreferences for Flutter app
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentEmotionalState', option.id);
      await prefs.setString('currentEmotionalStateBucket', option.bucket);
      await prefs.setInt('emotionalStateTimestamp', DateTime.now().millisecondsSinceEpoch);

      // Store in App Group UserDefaults for iOS keyboard extension access
      await _bridgeToKeyboardExtension(option);

      // Log for debugging
      print('🎯 Emotional state saved: ${option.label} (${option.bucket} bucket)');
      
      // Navigate to main app
      if (mounted) {
        AppRouter.navigateToHome(context);
      }
      
    } catch (e) {
      print('❌ Error saving emotional state: $e');
      // Still navigate even if save fails
      if (mounted) {
        AppRouter.navigateToHome(context);
      }
    }
  }

  /// Bridge emotional state data to iOS keyboard extension via shared UserDefaults
  Future<void> _bridgeToKeyboardExtension(EmotionalStateOption option) async {
    try {
      // Use the PersonalityDataManager bridge to store emotional state
      await PersonalityDataManager.shared.setUserEmotionalState(
        state: option.id,
        bucket: option.bucket,
        label: option.label,
      );
      
      print('✅ Emotional state bridged to keyboard extension');
    } catch (e) {
      print('⚠️ Warning: Could not bridge to keyboard extension: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const SizedBox(height: 20),
                Text(
                  'How are you feeling today?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This helps us provide more personalized guidance',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF718096),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Emotional state options
                Expanded(
                  child: ListView.separated(
                    itemCount: emotionalStates.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final option = emotionalStates[index];
                      final isSelected = selectedEmotionalState == option.id;
                      
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: Material(
                          borderRadius: BorderRadius.circular(16),
                          color: isSelected 
                            ? option.color.withOpacity(0.15)
                            : Colors.white,
                          elevation: isSelected ? 4 : 1,
                          shadowColor: option.color.withOpacity(0.3),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: isSubmitting ? null : () {
                              setState(() {
                                selectedEmotionalState = option.id;
                              });
                              
                              // Auto-submit after selection with slight delay for visual feedback
                              Future.delayed(const Duration(milliseconds: 300), () {
                                _saveEmotionalState(option);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected 
                                  ? Border.all(color: option.color, width: 2)
                                  : Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  // Icon
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: option.color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      option.icon,
                                      color: option.color,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Text content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          option.label,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF2D3748),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          option.description,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: const Color(0xFF718096),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Selection indicator / loading
                                  if (isSubmitting && isSelected)
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(option.color),
                                      ),
                                    )
                                  else if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: option.color,
                                      size: 24,
                                    )
                                  else
                                    Icon(
                                      Icons.radio_button_unchecked,
                                      color: Colors.grey.shade400,
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Bottom hint
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Tap any option to continue',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Data model for emotional state options
class EmotionalStateOption {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final String bucket; // Maps to our bucket system: "highIntensity", "moderate", "regulated"

  const EmotionalStateOption({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.bucket,
  });
}
