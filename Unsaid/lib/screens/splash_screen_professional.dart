import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';
import '../services/trial_service.dart';

class SplashScreenProfessional extends StatefulWidget {
  const SplashScreenProfessional({super.key});

  @override
  State<SplashScreenProfessional> createState() =>
      _SplashScreenProfessionalState();
}

class _SplashScreenProfessionalState extends State<SplashScreenProfessional>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _backgroundController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _backgroundGradient;

  @override
  void initState() {
    super.initState();

    print('=== SPLASH SCREEN LOADED ==='); // Debug print

    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Logo animations
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Text animations
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    // Background gradient animation
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _backgroundGradient = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    // Start animations sequence
    _startAnimations();
  }

  void _startAnimations() async {
    try {
      // Start background animation immediately
      _backgroundController.forward();

      // Start logo animation after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      _logoController.forward();

      // Start text animation after logo
      await Future.delayed(const Duration(milliseconds: 800));
      _textController.forward();

      // Navigate after all animations - check auth and onboarding state
      await Future.delayed(
        const Duration(milliseconds: 3000),
      );
      
      if (mounted) {
        print('=== SPLASH SCREEN ABOUT TO NAVIGATE ===');
        await _navigateBasedOnState();
      }
    } catch (e) {
      print('Splash screen animation error: $e');
      // Fallback navigation to onboarding
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    }
  }

  /// Navigate based on authentication and onboarding state
  Future<void> _navigateBasedOnState() async {
    try {
      final authService = AuthService.instance;
      final onboardingService = OnboardingService.instance;

      // Check authentication state
      final isAuthenticated = authService.isAuthenticated;
      final isOnboardingComplete = await onboardingService.isOnboardingComplete();

      print('=== NAVIGATION STATE CHECK ===');
      print('Authenticated: $isAuthenticated');
      print('Onboarding Complete: $isOnboardingComplete');
      print('User: ${authService.user?.uid}');

      if (isAuthenticated && isOnboardingComplete) {
        // Returning user - enable admin mode to bypass trial restrictions, then go to emotional state
        print('→ Navigating to emotional state screen (returning user)');
        
        // Enable admin mode for returning users to bypass trial restrictions
        final trialService = Provider.of<TrialService>(context, listen: false);
        await trialService.enableAdminModeForReturningUser();
        
        // Always route to emotional state screen first
        Navigator.pushReplacementNamed(context, '/emotional-state');
      } else {
        // New user or incomplete onboarding - go to onboarding flow
        print('→ Navigating to onboarding flow (new user)');
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    } catch (e) {
      print('Navigation state check error: $e');
      // Fallback to onboarding
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _logoController,
          _textController,
          _backgroundController,
        ]),
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF6C47FF),
                    const Color(0xFF4A2FE7),
                    _backgroundGradient.value,
                  )!,
                  Color.lerp(
                    const Color(0xFF4A2FE7),
                    const Color(0xFF00D2FF),
                    _backgroundGradient.value,
                  )!,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top spacer
                  const Spacer(flex: 2),

                  // Logo section
                  FadeTransition(
                    opacity: _logoOpacity,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: SizedBox(
                        width: 200, // Increased size from 120
                        height: 200, // Increased size from 120
                        child: Center(
                          child: Image.asset(
                            'assets/logo_icon.png',
                            width: 180, // Increased from 80
                            height: 180, // Increased from 80
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 180, // Increased from 80
                                height: 180, // Increased from 80
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD700),
                                      Color(0xFFB8860B),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    20,
                                  ), // Rounded square instead of circle
                                ),
                                child: const Center(
                                  child: Text(
                                    'U',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 80, // Increased from 40
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.space2XL),

                  // App name and tagline
                  FadeTransition(
                    opacity: _textOpacity,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Column(
                        children: [
                          Text(
                            'Unsaid',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.0,
                                ),
                          ),
                          const SizedBox(height: AppTheme.spaceMD),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spaceLG,
                            ),
                            child: Text(
                              'AI-Powered Communication\nMade Meaningful',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w300,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom section with loading indicator
                  const Spacer(flex: 2),

                  FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        // Premium loading indicator
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        ),

                        const SizedBox(height: AppTheme.spaceLG),

                        Text(
                          'Loading Experience...',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w300,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.space3XL),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
