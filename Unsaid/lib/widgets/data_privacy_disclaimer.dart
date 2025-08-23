import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DataPrivacyDisclaimer extends StatefulWidget {
  final VoidCallback onAccept;

  const DataPrivacyDisclaimer({
    super.key,
    required this.onAccept,
  });

  @override
  State<DataPrivacyDisclaimer> createState() => _DataPrivacyDisclaimerState();
}

class _DataPrivacyDisclaimerState extends State<DataPrivacyDisclaimer>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _hasReadToEnd = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _slideController.forward();
    
    // Listen for scroll to detect if user has read to the end
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      setState(() {
        _hasReadToEnd = true;
      });
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: screenHeight * 0.85,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  SizedBox(width: AppTheme.spacing.sm),
                  Expanded(
                    child: Text(
                      'Privacy & Data Security',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      icon: Icons.lock_outline,
                      title: 'Your Privacy is Our Priority',
                      content:
                          'Unsaid is designed with privacy-first principles. We understand that communication data is deeply personal, and we\'ve built our system to protect your information at every level.',
                    ),

                    _buildSection(
                      icon: Icons.data_usage_outlined,
                      title: 'What Data We Collect',
                      content: '''
• Message analysis patterns (tone, sentiment, communication style)
• Keyboard usage statistics (typing patterns, frequency)
• Relationship insights and compatibility metrics
• App usage analytics (features used, session duration)
• Personality test results and attachment style assessments

We DO NOT collect:
• The actual content of your messages
• Personal conversations or text
• Contact information from your device
• Location data beyond general region for service optimization''',
                    ),

                    _buildSection(
                      icon: Icons.shield_outlined,
                      title: 'How We Protect Your Data',
                      content: '''
• End-to-end encryption for all sensitive data
• Local processing of message analysis when possible
• Anonymized data aggregation for insights
• Regular security audits and penetration testing
• GDPR and CCPA compliant data handling
• Secure cloud infrastructure with enterprise-grade protection''',
                    ),

                    _buildSection(
                      icon: Icons.psychology_outlined,
                      title: 'AI Processing & Analysis',
                      content: '''
• AI models process communication patterns, not content
• Analysis happens in secure, isolated environments
• Data is anonymized before any cloud processing
• Personal insights are generated without exposing raw data
• Machine learning improves general patterns, not individual profiles''',
                    ),

                    _buildSection(
                      icon: Icons.share_outlined,
                      title: 'Data Sharing & Partnerships',
                      content: '''
We NEVER sell your personal data to third parties.

Limited sharing only occurs for:
• Essential service providers (with strict data protection agreements)
• Legal compliance when required by law
• Anonymous research to improve relationship communication (opt-in only)

You always maintain control over your data and can opt out at any time.''',
                    ),

                    _buildSection(
                      icon: Icons.settings_outlined,
                      title: 'Your Rights & Controls',
                      content: '''
• View all data we've collected about you
• Download your data in a portable format
• Delete your account and all associated data
• Opt out of analytics and research programs
• Control which features can access your data
• Regular data retention review and cleanup''',
                    ),

                    _buildSection(
                      icon: Icons.update_outlined,
                      title: 'Trial Period & Subscription',
                      content: '''
• 7-day free trial with full feature access
• After trial: \$9.99/month for continued access
• Cancel anytime through app settings
• Data deletion options available upon cancellation
• No long-term commitments or hidden fees''',
                    ),

                    SizedBox(height: AppTheme.spacing.xl),

                    // Contact information
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Questions About Privacy?',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacing.xs),
                          Text(
                            'Contact our privacy team: privacy@unsaidapp.com\nView full privacy policy: unsaidapp.com/privacy',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppTheme.spacing.xl),
                  ],
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                  ),
                ),
              ),
              child: Column(
                children: [
                  if (!_hasReadToEnd)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.md,
                        vertical: AppTheme.spacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.secondary,
                            size: 20,
                          ),
                          SizedBox(width: AppTheme.spacing.sm),
                          Expanded(
                            child: Text(
                              'Please scroll to read the complete privacy information',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (!_hasReadToEnd) SizedBox(height: AppTheme.spacing.md),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _hasReadToEnd ? () {
                        Navigator.pop(context);
                        widget.onAccept();
                      } : null,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Accept & Start Free Trial',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: AppTheme.spacing.sm),
                  
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: AppTheme.spacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacing.sm),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
