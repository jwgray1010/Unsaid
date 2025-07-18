import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';

/// Screen shown when trial expires or user wants to subscribe
class SubscriptionScreen extends StatefulWidget {
  final bool isTrialExpired;
  final VoidCallback onSubscribe;

  const SubscriptionScreen({
    Key? key,
    required this.isTrialExpired,
    required this.onSubscribe,
  }) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF6C47FF),
              const Color(0xFF9C88FF),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lock icon
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.isTrialExpired ? Icons.lock_outline : Icons.star_outline,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  
                  SizedBox(height: AppTheme.spacing.xl),
                  
                  // Title
                  Text(
                    widget.isTrialExpired ? 'Trial Expired' : 'Upgrade to Premium',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: AppTheme.spacing.md),
                  
                  // Description
                  Text(
                    widget.isTrialExpired 
                      ? 'Your 7-day free trial has ended. Subscribe to continue using Unsaid and keep your relationship insights.'
                      : 'Unlock unlimited access to all Unsaid features and keep improving your relationships.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: AppTheme.spacing.xl),
                  
                  // Features included
                  _buildFeaturesList(),
                  
                  SizedBox(height: AppTheme.spacing.xl),
                  
                  // Pricing
                  Container(
                    padding: EdgeInsets.all(AppTheme.spacing.lg),
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
                        Text(
                          '\$9.99/month',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacing.xs),
                        Text(
                          'Auto-renewing subscription',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(height: AppTheme.spacing.xs),
                        Text(
                          'Cancel anytime in iPhone Settings',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: AppTheme.spacing.xl),
                  
                  // Subscribe button
                  GradientButton(
                    onPressed: _handleSubscribe,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.white.withOpacity(0.95),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radius.lg),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing.xl,
                      vertical: AppTheme.spacing.md,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        SizedBox(width: AppTheme.spacing.sm),
                        Text(
                          'Subscribe Now',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: AppTheme.spacing.md),
                  
                  // Restore purchases button
                  TextButton(
                    onPressed: _handleRestorePurchases,
                    child: Text(
                      'Restore Purchases',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  
                  // Bottom padding for safe area
                  SizedBox(height: AppTheme.spacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      'Unlimited relationship insights',
      'Advanced communication analysis',
      'Personalized coaching suggestions',
      'Priority support',
    ];

    return Column(
      children: features.map((feature) {
        return Container(
          margin: EdgeInsets.only(bottom: AppTheme.spacing.sm),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: AppTheme.spacing.sm),
              Expanded(
                child: Text(
                  feature,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _handleSubscribe() {
    HapticFeedback.mediumImpact();
    
    // TODO: Implement actual subscription purchase flow
    // This would typically involve:
    // 1. Showing Apple's subscription purchase flow
    // 2. Handling the purchase result
    // 3. Activating the subscription
    
    // For now, show a message that this would trigger the purchase flow
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Subscription Purchase'),
        content: Text('This would trigger the Apple subscription purchase flow. Once implemented, users would be charged automatically after the trial period.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
    
    // Simulate successful subscription for demo
    widget.onSubscribe();
  }

  void _handleRestorePurchases() {
    HapticFeedback.lightImpact();
    
    // TODO: Implement restore purchases flow
    // This would typically involve:
    // 1. Calling Apple's restore purchases API
    // 2. Checking for valid subscriptions
    // 3. Activating subscription if found
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Restore purchases functionality would be implemented here'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
