import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'relationship_insights_dashboard.dart';
import '../services/auth_service.dart';
import '../services/secure_communication_progress_service.dart';
import '../services/secure_storage_service.dart';
import '../services/unified_analytics_service.dart';
import '../services/keyboard_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool loading = false;
  String message = '';
  String analysis = '';
  bool loadingAnalysis = false;
  double sensitivity = 0.5;
  String selectedTone = 'neutral';
  List<Map<String, dynamic>> savedProfiles = [];
  final SecureCommunicationProgressService _progressService = SecureCommunicationProgressService();
  final SecureStorageService _storageService = SecureStorageService();
  final UnifiedAnalyticsService _analyticsService = UnifiedAnalyticsService();
  final KeyboardManager _keyboardManager = KeyboardManager();
  Map<String, dynamic>? _progressData;
  Map<String, dynamic>? _personalityData;
  Map<String, dynamic>? _analyticsData;
  Map<String, dynamic>? _realKeyboardData;
  String _relationshipType = 'couples';

  String get userName {
    final authService = AuthService.instance;
    if (authService.user?.displayName != null && authService.user!.displayName!.isNotEmpty) {
      return authService.user!.displayName!.split(' ').first; // Get first name only
    } else if (authService.user?.email != null) {
      // Fallback to email prefix if no display name
      return authService.user!.email!.split('@').first;
    }
    return 'User'; // Final fallback
  }
  // Real personality data from user's test results
  Map<String, int> get personalityData {
    if (_personalityData != null && _personalityData!['counts'] != null) {
      return Map<String, int>.from(_personalityData!['counts']);
    }
    // Fallback to balanced default if no test results
    return {
      'A': 3, // Anxious Attachment
      'B': 7, // Secure Attachment (dominant)
      'C': 2, // Dismissive Avoidant
      'D': 3, // Disorganized/Fearful Avoidant
    };
  }

  String get dominantPersonalityType {
    String dominant = 'B';
    int maxCount = 0;
    personalityData.forEach((key, value) {
      if (value > maxCount) {
        dominant = key;
        maxCount = value;
      }
    });
    return dominant;
  }

  String get personalityTypeLabel {
    if (_personalityData != null && _personalityData!['dominant_type_label'] != null) {
      return _personalityData!['dominant_type_label'];
    }
    const typeLabels = {
      'A': "Anxious Attachment",
      'B': "Secure Attachment",
      'C': "Dismissive Avoidant",
      'D': "Disorganized/Fearful Avoidant",
    };
    return typeLabels[dominantPersonalityType] ?? "Unknown";
  }

  List<Map<String, dynamic>> toneOptions = [
    {'name': 'gentle', 'color': Colors.green, 'icon': Icons.favorite},
    {'name': 'direct', 'color': Colors.blue, 'icon': Icons.message},
    {'name': 'neutral', 'color': Colors.grey, 'icon': Icons.balance},
  ];

  // Partner profile state
  Map<String, dynamic>? partnerProfile;
  bool hasPartner =
      false; // This would be determined by checking if partner exists in database

  @override
  void initState() {
    super.initState();
    _loadPartnerProfile();
    _loadProgressData();
    _loadPersonalityData();
    _loadAnalyticsData();
    _loadRealKeyboardData();
  }

  void _loadPersonalityData() async {
    try {
      final results = await _storageService.getPersonalityTestResults();
      setState(() {
        _personalityData = results;
      });
      print(' Personality data loaded: ${results != null ? 'Found' : 'Not found'}');
    } catch (e) {
      print(' Error loading personality data: $e');
    }
  }

  void _loadAnalyticsData() async {
    try {
      final analytics = await _analyticsService.getIndividualAnalytics();
      setState(() {
        _analyticsData = analytics;
      });
      print(' Analytics data loaded');
    } catch (e) {
      print(' Error loading analytics data: $e');
    }
  }

  void _loadProgressData() async {
    try {
      final progress = await _progressService.getSecureCommunicationProgress(
        userPersonalityType: personalityTypeLabel,
        userCommunicationStyle: _personalityData?['communication_style_label'] ?? 'Assertive',
      );
      setState(() {
        _progressData = progress;
      });
    } catch (e) {
      print('Error loading progress data: $e');
    }
  }

  void _loadPartnerProfile() async {
    // Load real partner data from storage service
    try {
      final partnerData = await _storageService.getPartnerProfile();
      setState(() {
        if (partnerData != null && partnerData.isNotEmpty) {
          hasPartner = true;
          partnerProfile = partnerData;
        } else {
          hasPartner = false; // Show invite card when no partner data
          partnerProfile = {
            'name': 'No Partner Connected',
            'email': '',
            'phone': '',
            'personality_type': '',
            'personality_label': 'Invite your partner to get started',
            'relationship_duration': '',
            'communication_style': '',
            'last_analysis': null,
            'profile_image': null,
            'test_completed': false,
            'joined_date': null,
          };
        }
      });
    } catch (e) {
      print('Error loading partner profile: $e');
      setState(() {
        hasPartner = false;
        partnerProfile = {
          'name': 'Error Loading Partner',
          'email': '',
          'phone': '',
          'personality_type': '',
          'personality_label': 'Please try again',
          'relationship_duration': '',
          'communication_style': '',
          'last_analysis': null,
          'profile_image': null,
          'test_completed': false,
          'joined_date': null,
        };
      });
    }
  }
  }

  void _invitePartner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInvitePartnerSheet(),
    );
  }

  void handleEdit(String id) {
    // Edit implementation
  }

  void handleDelete(String id) {
    // Delete implementation
  }

  /// Load real keyboard data from Swift extension with new user fallbacks
  void _loadRealKeyboardData() async {
    try {
      final realData = await _keyboardManager.getComprehensiveRealData();
      setState(() {
        if (realData['real_data'] == true && (realData['total_interactions'] ?? 0) > 0) {
          // User has real data
          _realKeyboardData = realData;
        } else {
          // NEW USER: Create encouraging fallback data
          _realKeyboardData = {
            'real_data': false,
            'total_interactions': 0,
            'isNewUser': true,
            'welcomeMessage': '🎉 Welcome to Unsaid!',
            'subtitle': 'Your personalized insights will appear here as you start using the keyboard',
            'actionPrompt': 'Enable the Unsaid keyboard to begin your communication journey',
            'tone_distribution': {'positive': 0, 'neutral': 0, 'negative': 0},
            'attachment_style': 'discovering',
            'suggestion_acceptance_rate': 0,
            'current_tone_status': 'ready',
          };
        }
      });
      print(' Real keyboard data loaded: ${realData['real_data']} (${realData['total_interactions'] ?? 0} interactions)');
    } catch (e) {
      print(' Error loading real keyboard data: $e');
      // ERROR FALLBACK: Still provide a good experience
      setState(() {
        _realKeyboardData = {
          'real_data': false,
          'isNewUser': true,
          'error': true,
          'welcomeMessage': ' Welcome to Unsaid!',
          'subtitle': 'Setting up your personalized experience...',
          'actionPrompt': 'Make sure the Unsaid keyboard is enabled in Settings',
          'tone_distribution': {'positive': 0, 'neutral': 0, 'negative': 0},
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
        ),
      );
    }

    var children = [
      // Header
      Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF7B61FF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.favorite,
              size: 24,
              color: Color(0xFF7B61FF),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $userName',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your relationship insights',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          // Premium Button
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/premium');
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF7B61FF),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      const SizedBox(height: 32),

      // Progress Bar Section
      _buildProgressSection(),

      const SizedBox(height: 32),

      // Partner Profile Section
      _buildPartnerProfileSection(),

      const SizedBox(height: 32),

      // Personality Results Section
      _buildPersonalityResultsSection(),

      const SizedBox(height: 32),

      // Insights Dashboard Summary
      _buildInsightsSummaryCard(),

      const SizedBox(height: 32),

      // Relationship Hub Summary  
      _buildRelationshipHubSummaryCard(),

      const SizedBox(height: 32),

      // Quick Tips Section
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Communication Tips',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildHorizontalTipCard(
                    'Emotionally stable',
                    'Practice maintaining calm during difficult conversations',
                    Icons.favorite,
                    Colors.pink,
                  ),
                  const SizedBox(width: 12),
                  _buildHorizontalTipCard(
                    'Active listening',
                    'Focus on understanding your partner\'s perspective',
                    Icons.hearing,
                    Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _buildHorizontalTipCard(
                    'Acknowledge feelings',
                    'Validate your partner\'s emotions before responding',
                    Icons.psychology,
                    Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _buildHorizontalTipCard(
                    'Gentle tone',
                    'Use a soft, caring tone even in disagreements',
                    Icons.volume_down,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(children: children),
        ),
      ),
    );
  }

  // Partner Profile Section Builder
  Widget _buildPartnerProfileSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: const Color(0xFF7B61FF), size: 24),
              const SizedBox(width: 12),
              Text(
                'Relationship Partner',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (!hasPartner)
            _buildInvitePartnerCard()
          else
            _buildPartnerProfileCard(),
        ],
      ),
    );
  }

  Widget _buildInvitePartnerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF7B61FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF7B61FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.person_add, color: const Color(0xFF7B61FF), size: 48),
          const SizedBox(height: 16),
          Text(
            'Invite Your Partner',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with your partner to get personalized communication insights based on both your personalities.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _invitePartner,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Send Invitation',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerProfileCard() {
    if (partnerProfile == null) return const SizedBox();

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/relationshipPartner');
      },
      child: Container(
        padding: const EdgeInsets.all(16), // Reduced from 20
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7B61FF), Color(0xFF9C27B0)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B61FF).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Partner avatar
                Container(
                  width: 48, // Reduced from 56
                  height: 48, // Reduced from 56
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24), // Reduced from 28
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 24, // Reduced from 28
                  ),
                ),
                const SizedBox(width: 12), // Reduced from 16
                // Partner info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partnerProfile!['name'],
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Personality label
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Color dot for attachment style
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: _getAttachmentColor(
                                      partnerProfile!['personality_type'],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(
                                  partnerProfile!['personality_label'],
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11,
                                      ),
                                ),
                              ],
                            ),
                          ),

                          // Communication style
                          if (partnerProfile!['communication_style'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                _mapCommunicationStyle(
                                  partnerProfile!['communication_style'],
                                ),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.white.withOpacity(0.8),
                                      fontStyle: FontStyle.italic,
                                      fontSize: 10,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status indicator
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.link, color: Colors.white, size: 20),
                ),
              ],
            ),

            const SizedBox(height: 16), // Reduced from 20
            // Relationship Link/Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const RelationshipInsightsDashboard(),
                    ),
                  );
                },
                icon: Icon(Icons.link, color: Colors.white, size: 16),
                label: Flexible(
                  child: Text(
                    'Open Relationship Dashboard',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.15),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
              ),
            ),

            const SizedBox(height: 8), // Reduced from 12
            // Quick stats
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${partnerProfile!['relationship_duration']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Together',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '87%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Compatibility',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitePartnerSheet() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        minHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                24 +
                    MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Invite Your Partner',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send an invitation to your partner so they can take the personality test and you can get personalized communication insights.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Invite Options
                  _buildInviteOption(
                    icon: Icons.sms,
                    title: 'Send via Text Message',
                    subtitle: 'Send invitation link through SMS',
                    onTap: () => _sendInviteViaSMS(),
                  ),

                  const SizedBox(height: 16),

                  _buildInviteOption(
                    icon: Icons.email,
                    title: 'Send via Email',
                    subtitle: 'Send invitation link through email',
                    onTap: () => _sendInviteViaEmail(),
                  ),

                  const SizedBox(height: 16),

                  _buildInviteOption(
                    icon: Icons.share,
                    title: 'Share Link',
                    subtitle: 'Copy invitation link to share anywhere',
                    onTap: () => _shareInviteLink(),
                  ),

                  const SizedBox(height: 32),

                  // Preview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preview Message:',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hi! I\'ve been using Unsaid to improve our communication. Join me by taking a quick personality test so we can understand each other better: [invitation-link]',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.black.withOpacity(0.8),
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF7B61FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: const Color(0xFF7B61FF), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _sendInviteViaSMS() async {
    Navigator.pop(context);
    
    const inviteMessage = "Hi! I've been using Unsaid to improve our communication. Join me by taking a quick personality test so we can understand each other better: https://unsaid.app/invite";
    
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: '', // Empty path opens SMS app without pre-filled number
      queryParameters: {
        'body': inviteMessage,
      },
    );
    
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        _showErrorSnackBar('Could not open SMS app');
      }
    } catch (e) {
      _showErrorSnackBar('Error opening SMS app: $e');
    }
  }

  void _sendInviteViaEmail() async {
    Navigator.pop(context);
    
    const subject = 'Join me on Unsaid - Communication Personality Test';
    const body = "Hi!\n\nI've been using Unsaid to improve our communication. Join me by taking a quick personality test so we can understand each other better.\n\nClick here to get started: https://unsaid.app/invite\n\nBest regards!";
    
    final Uri emailUri = Uri(
      scheme: 'mailto',
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        _showErrorSnackBar('Could not open email app');
      }
    } catch (e) {
      _showErrorSnackBar('Error opening email app: $e');
    }
  }

  void _shareInviteLink() async {
    Navigator.pop(context);
    
    const inviteMessage = "Join me on Unsaid! Take a quick personality test so we can understand each other better: https://unsaid.app/invite";
    
    try {
      final Uri shareUri = Uri(
        scheme: 'https',
        host: 'unsaid.app',
        path: '/invite',
      );
      
      // Use the share functionality
      await launchUrl(
        Uri.parse('https://unsaid.app/invite'),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      // Fallback: copy to clipboard
      _showErrorSnackBar('Link copied to clipboard');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildToneIndicatorCard() {
    return _buildProfessionalCard(
      title: 'Tone Indicator',
      subtitle: 'Live feedback',
      icon: Icons.psychology_outlined,
      iconColor: const Color(0xFF4CAF50),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE8F5E8), Color(0xFFF1F8E9)],
      ),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildToneColorDot(const Color(0xFF00E676), 'Good', true),
          const SizedBox(width: 8),
          _buildToneColorDot(const Color(0xFFFFD600), 'Caution', false),
          const SizedBox(width: 8),
          _buildToneColorDot(const Color(0xFFFF1744), 'Alert', false),
        ],
      ),
      onTap: () => Navigator.pushNamed(context, '/tone_test'),
    );
  }

  Widget _buildToneColorDot(Color color, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        isActive
            ? TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeInOut,
                tween: Tween(begin: 0.8, end: 1.2),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
                onEnd: () {
                  // Create a repeating animation
                  if (mounted) {
                    setState(() {}); // Trigger rebuild to restart animation
                  }
                },
              )
            : Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? color : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalityCard() {
    return _buildProfessionalCard(
      title: 'Personality',
      subtitle: personalityTypeLabel.split(' ').first,
      icon: Icons.account_circle_outlined,
      iconColor: const Color(0xFFFF6B6B),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF5F5), Color(0xFFFEF7F7)],
      ),
      content: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200, width: 2),
        ),
        child: CustomPaint(painter: MiniPieChartPainter(personalityData)),
      ),
      onTap: () async {
        // Use real personality data from storage
        try {
          final results = await _storageService.getPersonalityTestResults();
          if (results != null && results.isNotEmpty) {
            // Navigate with real test results
            Navigator.pushNamed(
              context,
              '/personality_results',
              arguments: results['answers'] ?? [],
            );
          } else {
            // Navigate to test if no results exist
            Navigator.pushNamed(context, '/personality_test_modern');
          }
        } catch (e) {
          print('Error accessing personality results: $e');
          // Fallback to test screen
          Navigator.pushNamed(context, '/personality_test_modern');
        }
      },
    );
  }

  Widget _buildProfessionalCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required LinearGradient gradient,
    required Widget content,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: iconColor),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),

              const SizedBox(height: 25),
              SizedBox(height: 70, child: Center(child: content)),

              const SizedBox(height: 25),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper for quick tips
  Widget _buildQuickTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.circle, color: Color(0xFF7B61FF), size: 8),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for horizontal tip cards
  Widget _buildHorizontalTipCard(String title, String description, IconData icon, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getAttachmentColor(String? type) {
    switch (type) {
      case 'A':
        return const Color(0xFFFF6B6B); // Red for Anxious Attachment
      case 'B':
        return const Color(0xFF4CAF50); // Green for Secure Attachment
      case 'C':
        return const Color(0xFF2196F3); // Blue for Dismissive Avoidant
      case 'D':
        return const Color(0xFFFF9800); // Orange for Disorganized/Fearful Avoidant
      default:
        return Colors.grey;
    }
  }

  String _mapCommunicationStyle(String? style) {
    if (style == null) return '';
    final s = style.toLowerCase();
    if (s.contains('assertive')) return 'Assertive';
    if (s.contains('passive-aggressive')) return 'Passive-Aggressive';
    if (s.contains('aggressive')) return 'Aggressive';
    if (s.contains('passive')) return 'Passive';
    // Fallback for legacy/custom labels
    if (s.contains('thoughtful') || s.contains('caring')) return 'Passive';
    if (s.contains('direct')) return 'Assertive';
    return style;
  }

  // Secure Communication Progress Section Builder
  Widget _buildProgressSection() {
    final attachmentStyle = _personalityData?['attachment_style'] ?? 'Secure';
    final communicationStyle = _personalityData?['communication_style'] ?? 'Assertive';
    
    // Calculate different aspects of secure communication progress
    final progressData = _calculateSecureCommunicationProgressAspects(attachmentStyle, communicationStyle);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: const Color(0xFF7B61FF), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Secure Communication Progress',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Multiple Progress Lines (Vertical Layout)
          Column(
            children: progressData.map((aspect) => _buildProgressLine(
              aspect['title'] as String,
              aspect['progress'] as double,
              aspect['color'] as Color,
            )).toList(),
          ),
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7B61FF).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Focus',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF7B61FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getSecureCommunicationTip(attachmentStyle),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build individual progress line
  Widget _buildProgressLine(String title, double progress, Color color) {
    final progressPercentage = (progress * 100).round();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '$progressPercentage%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  // Calculate secure communication progress aspects (multiple dimensions)
  List<Map<String, dynamic>> _calculateSecureCommunicationProgressAspects(String attachmentStyle, String communicationStyle) {
    // Check if user is new (no personality test taken)
    bool isNewUser = _personalityData == null;
    
    // For new users, start all progress at 0%
    if (isNewUser) {
      return [
        {
          'title': 'Emotional Regulation',
          'progress': 0.0,
          'color': const Color(0xFF7B61FF),
        },
        {
          'title': 'Active Listening',
          'progress': 0.0,
          'color': const Color(0xFF4ECDC4),
        },
        {
          'title': 'Conflict Resolution',
          'progress': 0.0,
          'color': const Color(0xFFFF6B6B),
        },
        {
          'title': 'Empathy Expression',
          'progress': 0.0,
          'color': const Color(0xFF4ECDC4),
        },
        {
          'title': 'Boundary Setting',
          'progress': 0.0,
          'color': const Color(0xFF95E1D3),
        },
      ];
    }
    
    // Add some variability based on usage (simulate progress over time)
    final daysSinceStart = DateTime.now().difference(DateTime(2024, 1, 1)).inDays;
    final usageBonus = math.min(0.15, daysSinceStart * 0.001); // Up to 15% bonus over 150 days
    
    // Base progress values for different aspects
    Map<String, double> baseProgress = {};
    
    switch (attachmentStyle.toLowerCase()) {
      case 'secure':
        baseProgress = {
          'emotional_regulation': 0.85,
          'active_listening': 0.80,
          'conflict_resolution': 0.75,
          'empathy_expression': 0.82,
          'boundary_setting': 0.78,
        };
        break;
      case 'anxious':
      case 'anxious-preoccupied':
        baseProgress = {
          'emotional_regulation': 0.40,
          'active_listening': 0.65,
          'conflict_resolution': 0.45,
          'empathy_expression': 0.70,
          'boundary_setting': 0.35,
        };
        break;
      case 'avoidant':
      case 'dismissive-avoidant':
        baseProgress = {
          'emotional_regulation': 0.60,
          'active_listening': 0.50,
          'conflict_resolution': 0.40,
          'empathy_expression': 0.35,
          'boundary_setting': 0.70,
        };
        break;
      case 'disorganized':
      case 'fearful-avoidant':
        baseProgress = {
          'emotional_regulation': 0.30,
          'active_listening': 0.45,
          'conflict_resolution': 0.25,
          'empathy_expression': 0.40,
          'boundary_setting': 0.30,
        };
        break;
      default:
        baseProgress = {
          'emotional_regulation': 0.50,
          'active_listening': 0.55,
          'conflict_resolution': 0.45,
          'empathy_expression': 0.50,
          'boundary_setting': 0.50,
        };
    }
    
    // Adjust based on communication style
    Map<String, double> communicationAdjustments = {};
    switch (communicationStyle.toLowerCase()) {
      case 'assertive':
        communicationAdjustments = {
          'emotional_regulation': 0.1,
          'active_listening': 0.1,
          'conflict_resolution': 0.15,
          'empathy_expression': 0.05,
          'boundary_setting': 0.15,
        };
        break;
      case 'passive':
        communicationAdjustments = {
          'emotional_regulation': -0.05,
          'active_listening': 0.05,
          'conflict_resolution': -0.15,
          'empathy_expression': 0.0,
          'boundary_setting': -0.20,
        };
        break;
      case 'aggressive':
        communicationAdjustments = {
          'emotional_regulation': -0.15,
          'active_listening': -0.20,
          'conflict_resolution': -0.10,
          'empathy_expression': -0.15,
          'boundary_setting': 0.05,
        };
        break;
      case 'passive-aggressive':
        communicationAdjustments = {
          'emotional_regulation': -0.10,
          'active_listening': -0.05,
          'conflict_resolution': -0.15,
          'empathy_expression': -0.10,
          'boundary_setting': -0.05,
        };
        break;
      default:
        communicationAdjustments = {
          'emotional_regulation': 0.0,
          'active_listening': 0.0,
          'conflict_resolution': 0.0,
          'empathy_expression': 0.0,
          'boundary_setting': 0.0,
        };
    }
    
    // Calculate final progress and create aspect data
    return [
      {
        'title': 'Emotional Regulation',
        'progress': math.min(1.0, baseProgress['emotional_regulation']! + communicationAdjustments['emotional_regulation']! + usageBonus),
        'color': const Color(0xFF7B61FF),
      },
      {
        'title': 'Active Listening',
        'progress': math.min(1.0, baseProgress['active_listening']! + communicationAdjustments['active_listening']! + usageBonus),
        'color': const Color(0xFF4ECDC4),
      },
      {
        'title': 'Conflict Resolution',
        'progress': math.min(1.0, baseProgress['conflict_resolution']! + communicationAdjustments['conflict_resolution']! + usageBonus),
        'color': const Color(0xFFFF6B6B),
      },
      {
        'title': 'Empathy Expression',
        'progress': math.min(1.0, baseProgress['empathy_expression']! + communicationAdjustments['empathy_expression']! + usageBonus),
        'color': const Color(0xFF45B7D1),
      },
      {
        'title': 'Healthy Boundaries',
        'progress': math.min(1.0, baseProgress['boundary_setting']! + communicationAdjustments['boundary_setting']! + usageBonus),
        'color': const Color(0xFF96CEB4),
      },
    ];
  }

  // Get secure communication tip based on attachment style
  String _getSecureCommunicationTip(String attachmentStyle) {
    // For new users, show a welcome message
    if (_personalityData == null) {
      return "Welcome to your secure communication journey! Take the personality test to get personalized insights and start building healthier communication patterns.";
    }
    
    switch (attachmentStyle.toLowerCase()) {
      case 'secure':
        return "You're already a secure communicator! Keep practicing empathy and clear expression to maintain your progress.";
      case 'anxious':
      case 'anxious-preoccupied':
        return "Focus on self-soothing techniques and expressing needs directly rather than seeking constant reassurance.";
      case 'avoidant':
      case 'dismissive-avoidant':
        return "Practice sharing your feelings and staying present in emotional conversations rather than withdrawing.";
      case 'disorganized':
      case 'fearful-avoidant':
        return "Work on identifying your emotions and creating safe spaces for communication when you feel triggered.";
      default:
        return "Practice mindful communication by listening actively and expressing yourself clearly and kindly.";
    }
  }

  /// Build comprehensive personality results section
  Widget _buildPersonalityResultsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: const Color(0xFF7B61FF), size: 24),
              const SizedBox(width: 12),
              Text(
                'Personality Insights',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          if (_personalityData != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () async {
                  // Use real personality data from storage
                  try {
                    final results = await _storageService.getPersonalityTestResults();
                    if (results != null && results.isNotEmpty) {
                      // Navigate with real test results
                      Navigator.pushNamed(
                        context,
                        '/personality_results',
                        arguments: results['answers'] ?? [],
                      );
                    } else {
                      // Navigate to test if no results exist
                      Navigator.pushNamed(context, '/personality_test_modern');
                    }
                  } catch (e) {
                    print('Error accessing personality results: $e');
                    // Fallback to test screen
                    Navigator.pushNamed(context, '/personality_test_modern');
                  }
                },
                child: Text(
                  'View Full Report',
                  style: TextStyle(
                    color: const Color(0xFF7B61FF),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),

          if (_personalityData == null)
            Column(
              children: [
                Icon(Icons.psychology_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'Take Personality Test',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Discover your attachment style to improve communication',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/personality_test'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B61FF),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Start Test',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Attachment Style',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            personalityTypeLabel,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        // Use real personality data from storage  
                        try {
                          final results = await _storageService.getPersonalityTestResults();
                          if (results != null && results.isNotEmpty) {
                            // Navigate with real test results
                            Navigator.pushNamed(
                              context,
                              '/personality_results',
                              arguments: results['answers'] ?? [],
                            );
                          } else {
                            // Navigate to test if no results exist
                            Navigator.pushNamed(context, '/personality_test_modern');
                          }
                        } catch (e) {
                          print('Error accessing personality results: $e');
                          // Fallback to test screen
                          Navigator.pushNamed(context, '/personality_test_modern');
                        }
                      },
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200, width: 2),
                        ),
                        child: CustomPaint(painter: MiniPieChartPainter(personalityData)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Partner personality section
                _buildPartnerPersonalitySection(),
              ],
            ),
        ],
      ),
    );
  }

  /// Build partner personality section
  Widget _buildPartnerPersonalitySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.people, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partner\'s Attachment Style',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasPartner ? (partnerProfile?['personality_label'] ?? 'Unknown') : 'Not Available',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasPartner ? Colors.black : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          if (!hasPartner)
            GestureDetector(
              onTap: _invitePartner,
              child: Text(
                'Invite Partner',
                style: TextStyle(
                  color: const Color(0xFF7B61FF),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build insights dashboard summary card
  Widget _buildInsightsSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: const Color(0xFF2196F3), size: 24),
              const SizedBox(width: 12),
              Text(
                'Communication Insights',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {
                // Navigate to insights dashboard (index 1 in main shell)
                Navigator.pushNamed(context, '/main_shell').then((_) {
                  // This would ideally set the tab index to 1
                });
              },
              child: Text(
                'View Details',
                style: TextStyle(
                  color: const Color(0xFF2196F3),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          if (_analyticsData == null)
            _buildDataLoadingState('Start using the keyboard to see insights')
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Messages Analyzed',
                        '${_analyticsData?['total_messages'] ?? 0}',
                        Icons.message,
                        const Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        'Communication Score',
                        '${(_analyticsData?['communication_score'] ?? 0.0).toStringAsFixed(0)}%',
                        Icons.trending_up,
                        const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Emotional Tone',
                        _analyticsData?['dominant_tone'] ?? 'Neutral',
                        Icons.mood,
                        const Color(0xFFFF9800),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        'Growth Progress',
                        '${(_progressData?['overall_score'] ?? 0.0).toStringAsFixed(0)}%',
                        Icons.psychology,
                        const Color(0xFF9C27B0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Build relationship hub summary card
  Widget _buildRelationshipHubSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: const Color(0xFFE91E63), size: 24),
              const SizedBox(width: 12),
              Text(
                'Relationship Hub',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RelationshipInsightsDashboard(),
                  ),
                );
              },
              child: Text(
                'Open Hub',
                style: TextStyle(
                  color: const Color(0xFFE91E63),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          if (!hasPartner)
            _buildDataLoadingState('Invite your partner to unlock relationship insights')
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Relationship Type',
                        _relationshipType == 'couples' ? 'Couple' : 'Co-Parent',
                        Icons.people,
                        const Color(0xFFE91E63),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        'Communication Health',
                        '85%', // This would come from relationship analytics
                        Icons.health_and_safety,
                        const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Shared Goals',
                        '3 Active', // This would come from relationship goals
                        Icons.flag,
                        const Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        'Last Activity',
                        '2h ago',
                        Icons.access_time,
                        const Color(0xFF9C27B0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildKeyboardActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build data loading state
  Widget _buildDataLoadingState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.hourglass_empty, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
/// Custom painter for mini pie chart
class MiniPieChartPainter extends CustomPainter {
  final Map<String, int> data;
  MiniPieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold(0, (a, b) => a + b);
    if (total == 0) return;
    final paint = Paint()..style = PaintingStyle.fill;
    double startRadian = -math.pi / 2;
    final colors = [
      const Color(0xFFFF6B6B), // A
      const Color(0xFF4CAF50), // B
      const Color(0xFF2196F3), // C
      const Color(0xFFFF9800), // D
    ];
    int i = 0;
    for (var entry in data.entries) {
      final sweep = (entry.value / total) * 2 * math.pi;
      paint.color = colors[i % colors.length];
      canvas.drawArc(
        Rect.fromLTWH(0, 0, size.width, size.height),
        startRadian,
        sweep,
        true,
        paint,
      );
      startRadian += sweep;
      i++;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

