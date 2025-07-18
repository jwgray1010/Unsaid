import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/trial_service.dart';
import '../theme/app_theme.dart';
import 'subscription_screen.dart';

class TrialGuard extends StatelessWidget {
  final Widget child;
  final bool showWarningWhenExpiring;

  const TrialGuard({
    super.key,
    required this.child,
    this.showWarningWhenExpiring = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TrialService>(
      builder: (context, trialService, _) {
        // If user has access (trial, subscription, or admin mode), show content
        if (trialService.hasAccess) {
          return Stack(
            children: [
              child,
              // Show warning banner when trial is expiring (but not in admin mode)
              if (showWarningWhenExpiring && 
                  !trialService.isAdminMode && 
                  trialService.shouldShowSubscriptionPrompt())
                _buildTrialWarningBanner(context, trialService),
              // Show admin mode controls in debug mode
              if (trialService.canAccessAdminMode)
                _buildAdminModeControls(context, trialService),
            ],
          );
        }

        // Trial expired and no subscription - show subscription screen
        return SubscriptionScreen(
          isTrialExpired: trialService.isTrialExpired,
          onSubscribe: () async {
            await trialService.activateSubscription();
          },
        );
      },
    );
  }

  Widget _buildTrialWarningBanner(BuildContext context, TrialService trialService) {
    final theme = Theme.of(context);
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: EdgeInsets.all(AppTheme.spacing.sm),
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacing.md,
            vertical: AppTheme.spacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade600,
                Colors.deepOrange.shade600,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.timer,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: AppTheme.spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trialService.getTimeRemainingString(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Subscribe to keep your insights',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SubscriptionScreen(
                        isTrialExpired: false,
                        onSubscribe: () async {
                          await trialService.activateSubscription();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing.sm,
                    vertical: AppTheme.spacing.xs,
                  ),
                ),
                child: Text(
                  'Subscribe',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminModeControls(BuildContext context, TrialService trialService) {
    final theme = Theme.of(context);
    
    return Positioned(
      bottom: 100,
      right: 16,
      child: SafeArea(
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: trialService.isAdminMode ? Colors.red : Colors.grey,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DEBUG',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            GestureDetector(
              onTap: () => trialService.toggleAdminMode(),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  trialService.isAdminMode ? 'ADMIN' : 'USER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 4),
            GestureDetector(
              onTap: () => trialService.resetTrial(),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'RESET',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
