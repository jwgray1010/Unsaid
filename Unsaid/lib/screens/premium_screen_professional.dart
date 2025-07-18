import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/data_privacy_disclaimer.dart';
import '../services/onboarding_service.dart';
import '../services/trial_service.dart';

class PremiumScreenProfessional extends StatefulWidget {
  final VoidCallback? onContinue;
  final List<String>? personalityTestAnswers;

  const PremiumScreenProfessional({
    super.key, 
    this.onContinue,
    this.personalityTestAnswers,
  });

  @override
  State<PremiumScreenProfessional> createState() =>
      _PremiumScreenProfessionalState();
}

class _PremiumScreenProfessionalState extends State<PremiumScreenProfessional>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _sparkleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _sparkleAnimation;
  
  int _secretTapCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.bounceOut),
    );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _handleStartTrial() async {
    HapticFeedback.mediumImpact();
    
    // Start the trial
    await TrialService().startTrial();
    
    // Mark onboarding as complete
    await OnboardingService.instance.markOnboardingComplete();
    
    if (widget.onContinue != null) {
      widget.onContinue!();
    } else if (widget.personalityTestAnswers != null) {
      // Navigate to personality results with actual test answers
      Navigator.pushReplacementNamed(
        context,
        '/personality_results',
        arguments: widget.personalityTestAnswers,
      );
    } else {
      // This shouldn't happen in normal flow since user should have taken the test
      // But as fallback, navigate to personality test disclaimer
      Navigator.pushReplacementNamed(
        context,
        '/personality_test_disclaimer',
      );
    }
  }

  void _showDataPrivacyDisclaimer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DataPrivacyDisclaimer(
        onAccept: _handleStartTrial,
      ),
    );
  }

  void _handleSecretTap() {
    _secretTapCount++;
    
    if (_secretTapCount >= 7) {
      // Enable admin mode after 7 taps
      final trialService = Provider.of<TrialService>(context, listen: false);
      trialService.enableAdminMode();
      
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(' Admin mode activated'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      
      _secretTapCount = 0;
    } else if (_secretTapCount >= 5) {
      // Give hint after 5 taps
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Keep tapping... (${7 - _secretTapCount} more)'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _handleSecretTap,
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6C47FF),
                    const Color(0xFF9C88FF),
                    const Color(0xFFB39DDB),
                  ],
                ),
              ),
              child: SafeArea(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _fadeController,
                    _slideController,
                    _scaleController,
                    _sparkleController,
                  ]),
                  builder: (context, child) {
                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Header with animated logo
                        SliverToBoxAdapter(
                          child: Container(
                            padding: EdgeInsets.all(AppTheme.spacing.xl),
                            child: Column(
                              children: [
                                // Premium badge with sparkle effect
                                Stack(
                                  children: [
                                    ScaleTransition(
                                      scale: _scaleAnimation,
                                      child: GestureDetector(
                                        onTap: _handleSecretTap,
                                        child: Container(
                                          padding: EdgeInsets.all(AppTheme.spacing.lg),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.white.withOpacity(0.3),
                                                blurRadius: 20,
                                                spreadRadius: 5,
                                              ),
                                            ],
                                          ),
                                          child: Image.asset(
                                            'assets/logo_icon.png',
                                            width: 100,
                                            height: 100,
                                            semanticLabel: 'Unsaid app logo',
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Sparkle effects
                                    ...List.generate(6, (index) {
                                      final angle = (index * 60.0) * (3.14159 / 180);
                                      final radius = 80.0;
                                      return Positioned(
                                        left:
                                            75 +
                                            radius *
                                                math.cos(
                                                  angle +
                                                      _sparkleAnimation.value *
                                                          2 *
                                                          3.14159,
                                                ),
                                        top:
                                            75 +
                                            radius *
                                                math.sin(
                                                  angle +
                                                      _sparkleAnimation.value *
                                                          2 *
                                                          3.14159,
                                                ),
                                        child: FadeTransition(
                                          opacity: _sparkleAnimation,
                                          child: Image.asset(
                                            'assets/logo_icon.png',
                                            width: 16,
                                            height: 16,
                                            color: Colors.white.withOpacity(0.7),
                                            semanticLabel: 'Sparkle',
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),

                                SizedBox(height: AppTheme.spacing.lg),

                                // App title
                                FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Text(
                                    'Welcome to Unsaid',
                                    style: theme.textTheme.displayMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          offset: const Offset(0, 2),
                                          blurRadius: 4,
                                          color: Colors.black.withOpacity(0.3),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                                SizedBox(height: AppTheme.spacing.sm),

                                // Subtitle
                                FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Text(
                                    'Your AI-powered relationship communication assistant',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w400,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: AppTheme.spacing.xs),
                                // Research-backed badge
                                FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Container(
                                    margin: EdgeInsets.only(top: AppTheme.spacing.sm),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacing.md,
                                      vertical: AppTheme.spacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified, color: Colors.white, size: 18, semanticLabel: 'Research-backed'),
                                        SizedBox(width: 6),
                                        Text(
                                          'Research-backed insights',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Features list
                        SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing.lg,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              SlideTransition(
                                position: _slideAnimation,
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Container(
                                    padding: EdgeInsets.all(AppTheme.spacing.lg),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF6C47FF),
                                          Color(0xFF4A2FE7),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusLG,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 20,
                                          offset: Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'App Features',
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        SizedBox(height: AppTheme.spacing.lg),
                                        ..._buildFeaturesList(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: AppTheme.spacing.xl),

                              // Pricing section
                              SlideTransition(
                                position: _slideAnimation,
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: _buildPricingSection(),
                                ),
                              ),

                              SizedBox(height: AppTheme.spacing.xl),

                              // Action buttons
                              SlideTransition(
                                position: _slideAnimation,
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Column(
                                    children: [
                                      // Start trial button
                                      GradientButton(
                                        onPressed: _showDataPrivacyDisclaimer,
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white,
                                            Colors.white.withOpacity(0.95),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radius.lg,
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: AppTheme.spacing.xl,
                                          vertical: AppTheme.spacing.md,
                                        ),
                                        elevation: 12,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.play_arrow,
                                              color: theme.colorScheme.primary,
                                              size: 24,
                                              semanticLabel: 'Start Free Trial',
                                            ),
                                            SizedBox(width: AppTheme.spacing.sm),
                                            Text(
                                              'Start 7-Day Free Trial',
                                              style: theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                    color: theme.colorScheme.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      SizedBox(height: AppTheme.spacing.md),

                                      // Auto-billing disclaimer
                                      Container(
                                        padding: EdgeInsets.all(AppTheme.spacing.md),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(AppTheme.radius.md),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.info_outline,
                                                  color: Colors.white.withOpacity(0.8),
                                                  size: 18,
                                                ),
                                                SizedBox(width: AppTheme.spacing.xs),
                                                Text(
                                                  'Auto-billing after trial',
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    color: Colors.white.withOpacity(0.9),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: AppTheme.spacing.xs),
                                            Text(
                                              'Your subscription will automatically renew at \$9.99/month after the 7-day trial unless cancelled in your iPhone Settings.',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: Colors.white.withOpacity(0.8),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),

                                      SizedBox(height: AppTheme.spacing.sm),

                                      // Privacy notice
                                      TextButton(
                                        onPressed: _showDataPrivacyDisclaimer,
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: AppTheme.spacing.lg,
                                            vertical: AppTheme.spacing.sm,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.privacy_tip_outlined,
                                              color: Colors.white.withOpacity(0.8),
                                              size: 18,
                                            ),
                                            SizedBox(width: AppTheme.spacing.xs),
                                            Text(
                                              'Privacy & Data Usage',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    color: Colors.white.withOpacity(0.8),
                                                    decoration: TextDecoration.underline,
                                                    decorationColor: Colors.white.withOpacity(0.8),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      SizedBox(height: AppTheme.spacing.md),

                                      // No Thanks button
                                      TextButton(
                                        onPressed: () async {
                                          await OnboardingService.instance.markOnboardingComplete();
                                          Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: AppTheme.spacing.lg,
                                            vertical: AppTheme.spacing.sm,
                                          ),
                                        ),
                                        child: Text(
                                          'No Thanks',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: Colors.white.withOpacity(0.8),
                                            decoration: TextDecoration.underline,
                                            decorationColor: Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: AppTheme.spacing.md),

                                      // Continue button
                                      TextButton(
                                        onPressed: () async {
                                          await OnboardingService.instance.markOnboardingComplete();
                                          Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: AppTheme.spacing.lg,
                                            vertical: AppTheme.spacing.sm,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.arrow_forward,
                                              color: Colors.white.withOpacity(0.9),
                                              size: 22,
                                            ),
                                            SizedBox(width: AppTheme.spacing.xs),
                                            Text(
                                              'Continue to Home',
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                color: Colors.white.withOpacity(0.9),
                                                decoration: TextDecoration.underline,
                                                decorationColor: Colors.white.withOpacity(0.9),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Add bottom safe area padding to prevent overflow
                              SizedBox(height: AppTheme.spacing.xl),
                              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                            ]),
                          ),
                        ),
                        SliverFillRemaining(
                          hasScrollBody: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ...all your widgets from the features list, pricing, actions...
                              SizedBox(height: AppTheme.spacing.xl),
                              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            // Back button overlay (always on top)
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    tooltip: 'Back',
                    onPressed: () {
                      Navigator.of(context).pop();
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

  List<Widget> _buildFeaturesList() {
    final features = [
      {
        'icon': Icons.keyboard_outlined,
        'title': 'Smart Keyboard Extension',
        'description':
            'Real-time tone analysis and suggestions as you type',
        'semantic': 'Smart Keyboard Extension',
      },
      {
        'icon': Icons.psychology_outlined,
        'title': 'Relationship Insights',
        'description':
            'Deep AI analysis of communication patterns and compatibility',
        'semantic': 'Relationship Insights',
      },
      {
        'icon': Icons.favorite_outline,
        'title': 'Attachment Style Analysis',
        'description':
            'Understand your attachment style and improve relationships',
        'semantic': 'Attachment Style Analysis',
      },
      {
        'icon': Icons.trending_up_outlined,
        'title': 'Communication Progress',
        'description':
            'Track and improve your communication over time',
        'semantic': 'Communication Progress',
      },
      {
        'icon': Icons.lightbulb_outline,
        'title': 'AI-Powered Suggestions',
        'description':
            'Get personalized recommendations for better communication',
        'semantic': 'AI-Powered Suggestions',
      },
      {
        'icon': Icons.security_outlined,
        'title': 'Privacy-First Design',
        'description':
            'Your data stays secure with end-to-end encryption',
        'semantic': 'Privacy-First Design',
      },
    ];

    return features.asMap().entries.map<Widget>((entry) {
      final index = entry.key;
      final feature = entry.value;
      return TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 600 + (index * 100)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: Opacity(
              opacity: value,
              child: Container(
                margin: EdgeInsets.only(bottom: AppTheme.spacing.md),
                padding: EdgeInsets.all(AppTheme.spacing.md),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radius.md),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacing.sm),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radius.sm),
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        color: Colors.white,
                        size: 24,
                        semanticLabel: feature['semantic'] as String,
                      ),
                    ),
                    SizedBox(width: AppTheme.spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature['title'] as String,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacing.xs),
                          Text(
                            feature['description'] as String,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle, color: Colors.white, size: 20, semanticLabel: 'Included'),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildPricingSection() {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C47FF), Color(0xFF4A2FE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Subscription Details',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppTheme.spacing.lg),

          // Free trial highlight
          Container(
            padding: EdgeInsets.all(AppTheme.spacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radius.lg),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer, color: Colors.white, size: 24, semanticLabel: 'Free Trial'),
                    SizedBox(width: AppTheme.spacing.sm),
                    Text(
                      '7-Day Free Trial',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacing.sm),
                Text(
                  'Then \$9.99/month (auto-renewing)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppTheme.spacing.xs),
                Text(
                  'Cancel anytime in iPhone Settings → Subscriptions',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
