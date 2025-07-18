import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/usage_tracking_service.dart';
import '../services/onboarding_service.dart';
import '../services/admin_service.dart';

/// Onboarding screen for new users
/// Handles beta user signup and introduction to the app
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [              // Progress indicator
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: LinearProgressIndicator(
                  value: (_currentPage + 1) / 5, // Updated to 5 steps
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildFeaturePage(),
                  _buildBetaPage(),
                  _buildSignupPage(),
                  _buildKeyboardSetupPage(),
                ],
              ),
            ),
            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App logo
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite,
              size: 60,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 32),

          // Welcome text
          Text(
            'Welcome to Unsaid',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Text(
            'AI-powered communication coaching for healthier relationships',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Key benefits
          _buildBenefitItem(
            Icons.psychology,
            'Smart Analysis',
            'Real-time tone and communication insights',
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            Icons.favorite_border,
            'Relationship Health',
            'Track and improve your relationship dynamics',
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(
            Icons.child_care,
            'Child-Focused',
            'Specialized guidance for co-parenting',
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Powerful Features',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          _buildFeatureCard(
            Icons.keyboard,
            'Smart Keyboard',
            'Get real-time suggestions as you type',
            Colors.blue,
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            Icons.analytics,
            'Insights Dashboard',
            'Track your communication patterns and growth',
            Colors.green,
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            Icons.psychology,
            'AI Coaching',
            'Personalized guidance for difficult conversations',
            Colors.purple,
          ),
          const SizedBox(height: 16),

          _buildFeatureCard(
            Icons.security,
            'Privacy First',
            'Your data stays private and secure',
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildBetaPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.science, size: 64, color: Colors.orange),
          ),
          const SizedBox(height: 24),

          Text(
            'Beta Version',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Text(
            'You\'re accessing an early version of Unsaid. Help us improve by sharing your feedback!',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          _buildBetaInfoItem(
            Icons.speed,
            'Limited Usage',
            'Daily usage limits to ensure fair access',
          ),
          const SizedBox(height: 16),

          _buildBetaInfoItem(
            Icons.feedback,
            'Feedback Welcome',
            'Your input helps us build a better product',
          ),
          const SizedBox(height: 16),

          _buildBetaInfoItem(
            Icons.update,
            'Regular Updates',
            'New features and improvements coming soon',
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'By continuing, you agree to help us test and improve Unsaid.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.blue[700]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Get Started',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Text(
            'Choose how you\'d like to access Unsaid',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Anonymous access (quick start)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _signInAnonymously,
              icon: Icon(Icons.flash_on),
              label: Text('Quick Start (Anonymous)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Perfect for trying out the app',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Email signup (coming soon)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: null, // Disabled for now
              icon: Icon(Icons.email),
              label: Text('Email Signup (Coming Soon)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            'Save your progress and preferences',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),

          if (_isLoading) ...[
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              'Setting up your account...',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          if (_currentPage > 0)
            TextButton(onPressed: _previousPage, child: Text('Previous'))
          else
            const SizedBox(),

          // Next/Skip button
          if (_currentPage < 4) // Updated to 4 since we have 5 pages (0-4)
            Row(
              children: [
                if (_currentPage < 3) // Only show skip on first 3 pages
                  TextButton(onPressed: _skipToSignup, child: Text('Skip'))
                else if (_currentPage == 4) // On keyboard setup page
                  TextButton(onPressed: () => Navigator.of(context).pushReplacementNamed('/keyboard_detection'), child: Text('Setup Keyboard')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _currentPage == 4 ? () => Navigator.of(context).pushReplacementNamed('/keyboard_detection') : _nextPage, 
                  child: Text(_currentPage == 4 ? 'Continue' : 'Next')
                ),
              ],
            )
          else
            const SizedBox(),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBetaInfoItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _nextPage() {
    if (_currentPage < 4) { // Updated to 4 since we have 5 pages (0-4)
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToSignup() {
    _pageController.animateToPage(
      3, // Go to signup page (index 3)
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _signInAnonymously() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Sign in anonymously
      final result = await AuthService.instance.signInAnonymously();

      if (result != null) {
        // Initialize usage tracking
        await UsageTrackingService.instance.initialize();

        // Track onboarding completion
        await UsageTrackingService.instance.trackUsage(
          'onboarding_complete',
          metadata: {'signup_method': 'anonymous'},
        );

        // Mark onboarding as complete
        await OnboardingService.instance.markOnboardingComplete();

        // Show success feedback
        HapticFeedback.mediumImpact();

        // Navigate to keyboard detection screen
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/keyboard_detection');
        }
      } else {
        // Show error
        _showErrorDialog('Failed to create account. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardSetupPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Keyboard icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.keyboard,
              size: 60,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Enable Smart Keyboard',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Text(
            'Get real-time AI coaching while you type in any app. Enable the Unsaid Keyboard to unlock powerful communication features.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Features list
          _buildKeyboardFeature(
            Icons.psychology,
            'AI Suggestions',
            'Get smart suggestions as you type',
          ),
          const SizedBox(height: 16),
          _buildKeyboardFeature(
            Icons.favorite,
            'Tone Analysis',
            'Real-time feedback on your message tone',
          ),
          const SizedBox(height: 16),
          _buildKeyboardFeature(
            Icons.security,
            'Privacy Protected',
            'Your messages stay private and secure',
          ),
          const SizedBox(height: 48),

          Text(
            'You can enable this later in Settings if you prefer.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardFeature(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
