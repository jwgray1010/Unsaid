import 'package:flutter/material.dart';
import '../navigation/bottom_navigation_bar_professional.dart';
import '../widgets/trial_guard.dart';
import 'home_screen_fixed.dart';
import 'insights_dashboard_enhanced.dart';
import 'settings_screen_professional.dart';
import 'relationship_insights_dashboard.dart';
// import 'interactive_coaching_practice.dart'; // REMOVED

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    const HomeScreen(key: PageStorageKey('HomeScreen')),
    const InsightsDashboardEnhanced(key: PageStorageKey('InsightsDashboard')),
    const RelationshipInsightsDashboard(
      key: PageStorageKey('RelationshipInsightsDashboard'),
    ),
    SettingsScreenProfessional(
      key: const PageStorageKey('SettingsScreen'),
      sensitivity: 0.5,
      onSensitivityChanged: (double value) {
        // Handle sensitivity change
      },
      tone: 'Polite',
      onToneChanged: (String value) {
        // Handle tone change
      },
    ),
  ];

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TrialGuard(
      child: Scaffold(
        body: SafeArea(child: _screens[_currentIndex]),
        bottomNavigationBar: CustomBottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}
