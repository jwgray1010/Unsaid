import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/usage_tracking_service.dart';
import 'services/personality_test_service.dart';
import 'services/new_user_experience_service.dart';
import 'services/partner_data_service.dart';
import 'services/trial_service.dart';
import 'services/onboarding_service.dart';
import 'widgets/keyboard_data_sync_widget.dart';
import 'firebase_options.dart';

import 'theme/app_theme.dart';
import 'screens/splash_screen_professional.dart';
import 'screens/onboarding_account_screen_professional.dart';
import 'screens/personality_test_disclaimer_screen_professional.dart';
import 'screens/personality_test_screen_professional_fixed_v2.dart';
import 'screens/modern_personality_test_screen.dart';
import 'screens/personality_results_screen_professional.dart';
import 'screens/modern_personality_results_screen.dart';
import 'screens/premium_screen_professional.dart';
import 'screens/keyboard_intro_screen_professional.dart';
import 'screens/emotional_state_screen.dart';
import 'screens/relationship_questionnaire_screen_professional.dart';
import 'screens/relationship_profile_screen_professional.dart';
// import 'screens/analyze_tone_screen_professional.dart';
// import 'screens/settings_screen_professional.dart';
// import 'screens/keyboard_setup_screen.dart';
// import 'screens/keyboard_detection_screen.dart';
// import 'screens/tone_indicator_demo_screen.dart';
// import 'screens/tone_indicator_test_screen.dart';
import 'screens/tone_indicator_tutorial_screen.dart';
// import 'screens/tutorial_demo_screen.dart';
// import 'screens/color_test_screen.dart';
import 'screens/main_shell.dart';
import 'data/randomized_personality_questions.dart';
import 'data/attachment_assessment.dart';
import 'data/assessment_integration.dart';
import 'screens/relationship_insights_dashboard.dart';
// import 'screens/smart_message_templates.dart';
import 'screens/predictive_ai_tab.dart';
// import 'screens/generate_invite_code_screen_professional.dart';
// import 'screens/code_generate_screen_professional.dart';
// import 'screens/interactive_coaching_practice.dart'; // REMOVED

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load(fileName: '.env');
    // Environment loaded successfully
  } catch (e) {
    // Warning: Could not load .env file
    // App will continue with default configuration
  }

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Firebase initialized successfully

    // Initialize authentication service
    await AuthService.instance.initialize();
    // Auth service initialized

    // For development: Auto sign-in anonymously if not authenticated
    if (!AuthService.instance.isAuthenticated) {
      try {
        await AuthService.instance.signInAnonymously();
        // Anonymous sign-in successful for development
      } catch (e) {
        // Anonymous sign-in failed, continue anyway
      }
    }

    // Initialize usage tracking service
    await UsageTrackingService.instance.initialize();
    // Usage tracking service initialized
  } catch (e) {
    // Error initializing services
    // Continue with app startup even if some services fail
  }

  // Set up enhanced global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Enhanced error logging with context
    // Flutter Error occurred with exception and stack trace
    // You could also send this to crash analytics service
  };

  runApp(const UnsaidApp());
}

class UnsaidApp extends StatelessWidget {
  const UnsaidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService.instance,
        ),
        ChangeNotifierProvider<UsageTrackingService>(
          create: (_) => UsageTrackingService.instance,
        ),
        ChangeNotifierProvider<NewUserExperienceService>(
          create: (_) => NewUserExperienceService(),
        ),
        ChangeNotifierProvider<PartnerDataService>(
          create: (_) => PartnerDataService(),
        ),
        ChangeNotifierProvider<TrialService>(
          create: (_) => TrialService(),
        ),
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, child) {
          return KeyboardDataSyncWidget(
            onDataReceived: (data) {
              debugPrint('📱 Main App: Received keyboard data with ${data.totalItems} items');
              // Here you can integrate with your existing analytics or storage
            },
            onError: (error) {
              debugPrint('❌ Main App: Keyboard data sync error: $error');
            },
            child: Semantics(
              // This ensures the app is accessible at the root level.
              label: 'Unsaid communication and relationship app',
              child: MaterialApp(
              title: 'Unsaid',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              initialRoute: '/splash',  // Always start with splash screen
              navigatorObservers: [MyNavigatorObserver()],
              onGenerateRoute: (settings) {
                switch (settings.name) {
                  case '/splash':
                    return MaterialPageRoute(
                      builder: (context) => const SplashScreenProfessional(),
                    );
                  case '/onboarding':
                    return MaterialPageRoute(
                      builder: (context) => OnboardingAccountScreenProfessional(
                        onContinueAsGuest: () async {
                          try {
                            final result = await authService.signInAnonymously();
                            if (result != null && context.mounted) {
                              Navigator.pushReplacementNamed(
                                context,
                                '/personality_test_disclaimer',
                              );
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to sign in as guest. Please try again.'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                ),
                              );
                            }
                          }
                        },
                        onSignInWithApple: () async {
                          try {
                            final result = await authService.signInWithApple();
                            if (result != null && context.mounted) {
                              Navigator.pushReplacementNamed(
                                context,
                                '/personality_test_disclaimer',
                              );
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Apple sign-in was cancelled or failed.'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Apple sign-in error: $e'),
                                ),
                              );
                            }
                          }
                        },
                        onSignInWithGoogle: () async {
                          try {
                            final result = await authService.signInWithGoogle();
                            if (result != null && context.mounted) {
                              Navigator.pushReplacementNamed(
                                context,
                                '/personality_test_disclaimer',
                              );
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Google sign-in was cancelled or failed.'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Google sign-in error: $e'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    );
                  case '/personality_test_disclaimer':
                    return MaterialPageRoute(
                      builder: (context) => FutureBuilder<bool>(
                        future: PersonalityTestService.isTestCompleted(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Scaffold(
                              body: Center(child: CircularProgressIndicator()),
                            );
                          }
                          
                          if (snapshot.data == true) {
                            // Test already completed, check if full onboarding is complete
                            WidgetsBinding.instance.addPostFrameCallback((_) async {
                              final onboardingService = OnboardingService.instance;
                              final isOnboardingComplete = await onboardingService.isOnboardingComplete();
                              
                              if (isOnboardingComplete) {
                                // Returning user - go to main app
                                Navigator.pushReplacementNamed(context, '/main');
                              } else {
                                // New user who completed test but not full onboarding - go to premium
                                Navigator.pushReplacementNamed(context, '/premium');
                              }
                            });
                            return const Scaffold(
                              body: Center(child: CircularProgressIndicator()),
                            );
                          }
                          
                          // Test not completed, show disclaimer
                          return PersonalityTestDisclaimerScreenProfessional(
                            onAgree: () => Navigator.pushReplacementNamed(
                              context,
                              '/personality_test',
                            ),
                            onAgreeModern: () => Navigator.pushReplacementNamed(
                              context,
                              '/personality_test_modern',
                            ),
                          );
                        },
                      ),
                    );
                  case '/personality_test':
                    return MaterialPageRoute(
                      builder: (context) => FutureBuilder<bool>(
                        future: PersonalityTestService.isTestCompleted(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Scaffold(
                              body: Center(child: CircularProgressIndicator()),
                            );
                          }
                          
                          if (snapshot.data == true) {
                            // Test already completed, check if full onboarding is complete
                            WidgetsBinding.instance.addPostFrameCallback((_) async {
                              final onboardingService = OnboardingService.instance;
                              final isOnboardingComplete = await onboardingService.isOnboardingComplete();
                              
                              if (isOnboardingComplete) {
                                // Returning user - go to main app
                                Navigator.pushReplacementNamed(context, '/main');
                              } else {
                                // New user who completed test but not full onboarding - go to premium
                                Navigator.pushReplacementNamed(context, '/premium');
                              }
                            });
                            return const Scaffold(
                              body: Center(child: CircularProgressIndicator()),
                            );
                          }
                          
                          // Test not completed, show test
                          final randomizedQuestions =
                              RandomizedPersonalityTest.getRandomizedQuestions();
                          return PersonalityTestScreenProfessional(
                            currentIndex: 0,
                            answers: List<String?>.filled(
                              randomizedQuestions.length,
                              null,
                            ),
                            questions: randomizedQuestions
                                .map(
                                  (q) => {
                                    'question': q.question,
                                    'options': q.options,
                                  },
                                )
                                .toList(),
                            onComplete: (answers) async {
                              // Mark test as completed
                              await PersonalityTestService.markTestCompleted(answers);
                              // Navigate to premium screen with test answers
                              Navigator.pushReplacementNamed(
                                context, 
                                '/premium',
                                arguments: answers,
                              );
                            },
                          );
                        },
                      ),
                    );
                  case '/personality_results':
                    final args = settings.arguments as List<String>? ?? [];
                    return MaterialPageRoute(
                      builder: (context) =>
                          PersonalityResultsScreenProfessional(answers: args),
                    );
                  case '/personality_test_modern':
                    return MaterialPageRoute(
                      builder: (context) => ModernPersonalityTestScreen(
                        onComplete: (attachmentScores, goalRouting, mergedConfig) async {
                          // Navigate to modern results with complete assessment data
                          Navigator.pushReplacementNamed(
                            context,
                            '/personality_results_modern',
                            arguments: {
                              'attachmentScores': attachmentScores,
                              'goalRouting': goalRouting,
                              'mergedConfig': mergedConfig,
                            },
                          );
                        },
                      ),
                    );
                  case '/personality_results_modern':
                    final args = settings.arguments as Map<String, dynamic>? ?? {};
                    return MaterialPageRoute(
                      builder: (context) => ModernPersonalityResultsScreen(
                        attachmentScores: args['attachmentScores'] as AttachmentScores? ?? 
                            AttachmentScores(anxiety: 0, avoidance: 0, confidence: 'low'),
                        goalRouting: args['goalRouting'] as GoalRoutingResult? ?? 
                            GoalRoutingResult(primaryGoal: 'unknown', confidence: 'low', weightMultipliers: {}),
                        mergedConfig: args['mergedConfig'] as MergedConfig? ?? 
                            MergedConfig(weightModifiers: {}, attachmentOverrides: {}, guardrailsConfig: {}),
                      ),
                    );
                  case '/premium':
                    final args = settings.arguments as List<String>?;
                    return MaterialPageRoute(
                      builder: (context) => PremiumScreenProfessional(
                        personalityTestAnswers: args,
                      ),
                    );
                  case '/keyboard_intro':
                    return MaterialPageRoute(
                      builder: (context) => KeyboardIntroScreenProfessional(
                        onSkip: () =>
                            Navigator.pushReplacementNamed(context, '/emotional-state'),
                      ),
                    );
                  case '/home':
                    return MaterialPageRoute(
                      builder: (context) => const MainShell(),
                    );
                  case '/emotional-state':
                    return MaterialPageRoute(
                      builder: (context) => const EmotionalStateScreen(),
                    );
                  case '/main':
                    return MaterialPageRoute(
                      builder: (context) => const MainShell(),
                    );
                  case '/relationship_questionnaire':
                    return MaterialPageRoute(
                      builder: (context) =>
                          const RelationshipQuestionnaireScreenProfessional(),
                    );
                  case '/relationship_profile':
                    return MaterialPageRoute(
                      builder: (context) =>
                          const RelationshipProfileScreenProfessional(),
                    );
                  // case '/analyze_tone':
                  //   return MaterialPageRoute(builder: (context) => const AnalyzeToneScreenProfessional());
                  // case '/settings':
                  //   return MaterialPageRoute(
                  //     builder: (context) => SettingsScreenProfessional(
                  //       sensitivity: 0.5,
                  //       onSensitivityChanged: (value) {},
                  //       tone: 'Polite',
                  //       onToneChanged: (tone) {},
                  //     ),
                  //   );
                  // case '/keyboard_setup':
                  //   return MaterialPageRoute(
                  //     builder: (context) => const KeyboardSetupScreen(),
                  //   );
                  // case '/keyboard_detection':
                  //   return MaterialPageRoute(
                  //     builder: (context) => const KeyboardDetectionScreen(),
                  //   );
                  // case '/tone_demo':
                  //   return MaterialPageRoute(
                  //     builder: (context) => const ToneIndicatorDemoScreen(),
                  //   );
                  // case '/tone_test':
                  //   return MaterialPageRoute(
                  //     builder: (context) => const ToneIndicatorTestScreen(),
                  //   );
                  case '/tone_tutorial':
                    return MaterialPageRoute(
                      builder: (context) => ToneIndicatorTutorialScreen(
                        onComplete: () => Navigator.pushReplacementNamed(
                          context,
                          '/onboarding',
                        ),
                      ),
                    );
                  // case '/tutorial_demo':
                  //   return MaterialPageRoute(
                  //     builder: (context) => const TutorialDemoScreen(),
                  //   );
                  // case '/color_test':
                  //   return MaterialPageRoute(
                  //     builder: (context) => const ColorTestScreen(),
                  //   );
                  case '/relationship_insights':
                    return MaterialPageRoute(
                      builder: (context) => const RelationshipInsightsDashboard(
                        // Example: Pass attachment/communication style if needed
                        // attachmentStyle: ...,
                        // communicationStyle: ...,
                      ),
                    );
                  case '/communication_coach':
                    return MaterialPageRoute(
                      builder: (context) => const RealTimeCommunicationCoach(),
                    );
                  // case '/message_templates':
                  //   return MaterialPageRoute(
                  //     builder: (context) => const SmartMessageTemplates(),
                  //   );
                  case '/predictive_ai':
                    return MaterialPageRoute(
                      builder: (context) => const PredictiveAITab(),
                    );
                  case '/emotional_state':
                    return MaterialPageRoute(
                      builder: (context) => const EmotionalStateScreen(),
                    );
                  // REMOVED: interactive_coaching_practice route
                  case '/generate_invite_code':
                    return MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(title: const Text('Generate Invite Code')),
                        body: const Center(
                          child: Text('Invite code generation coming soon'),
                        ),
                      ),
                    );
                  case '/code_generate':
                    return MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(title: const Text('Code Generator')),
                        body: const Center(
                          child: Text('Code generation coming soon'),
                        ),
                      ),
                    );
                  default:
                    return MaterialPageRoute(
                      builder: (context) => Scaffold(
                        body: const Center(child: Text('404 - Page not found')),
                      ),
                    );
                }
              },
            ),
            ),
          );
        },
      ),
    );
  }
}

class RealTimeCommunicationCoach extends StatelessWidget {
  const RealTimeCommunicationCoach({super.key});

  @override
  Widget build(BuildContext context) {
    // Replace with your actual UI
    return Scaffold(
      appBar: AppBar(title: const Text('Real-Time Communication Coach')),
      body: const Center(child: Text('Real-Time Communication Coach Content')),
    );
  }
}

class MyNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    // Send analytics event here
    super.didPush(route, previousRoute);
  }
}
