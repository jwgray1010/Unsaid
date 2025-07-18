import 'package:flutter/material.dart';
import '../screens/emotional_state_screen.dart';

class AppRouter {
  /// Navigate to the main home screen
  static void navigateToHome(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/home');
  }
  
  /// Navigate to emotional state screen
  static void navigateToEmotionalState(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/emotional-state');
  }
  
  /// Navigate to personality test
  static void navigateToPersonalityTest(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/personality-test');
  }
  
  /// Get route configuration
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        // This would be your splash screen
        return MaterialPageRoute(
          builder: (_) => const EmotionalStateScreen(),
          settings: settings,
        );
      case '/emotional-state':
        return MaterialPageRoute(
          builder: (_) => const EmotionalStateScreen(),
          settings: settings,
        );
      case '/home':
        // Replace with your actual home screen
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Home Screen - Replace with your main app'),
            ),
          ),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Route not found'),
            ),
          ),
          settings: settings,
        );
    }
  }
}
