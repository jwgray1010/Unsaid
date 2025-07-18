import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'relationship_couple_goals.dart';
import '../services/keyboard_manager.dart';
import '../services/relationship_insights_service.dart';
import '../services/personality_driven_analyzer.dart';
import '../services/secure_communication_progress_service.dart';
import '../services/secure_storage_service.dart';
import '../services/unified_analytics_service.dart';
import '../services/new_user_experience_service.dart';
import '../services/partner_data_service.dart';
import 'secure_couple_tips.dart';

class RelationshipInsightsDashboard extends StatefulWidget {
  const RelationshipInsightsDashboard({
    super.key,
    this.userPersonalityType,
    this.userCommunicationStyle,
    this.partnerPersonalityType,
    this.partnerCommunicationStyle,
  });

  final String? userPersonalityType;
  final String? userCommunicationStyle;
  final String? partnerPersonalityType;
  final String? partnerCommunicationStyle;

  @override
  State<RelationshipInsightsDashboard> createState() =>
      _RelationshipInsightsDashboardState();
}

class _RelationshipInsightsDashboardState
    extends State<RelationshipInsightsDashboard>
    with TickerProviderStateMixin {
  
  // Controllers
  TabController? _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Services
  final RelationshipInsightsService _insightsService = RelationshipInsightsService();
  final KeyboardManager _keyboardManager = KeyboardManager();
  final PersonalityDrivenAnalyzer _personalityAnalyzer = PersonalityDrivenAnalyzer();
  final SecureCommunicationProgressService _progressService = SecureCommunicationProgressService();
  final SecureStorageService _storageService = SecureStorageService();
  final UnifiedAnalyticsService _analyticsService = UnifiedAnalyticsService();

  // Data storage
  Map<String, dynamic> _insights = {};
  Map<String, dynamic> _coupleExperience = {};
  Map<String, dynamic> _progressData = {};
  Map<String, dynamic>? _personalityResults;
  Map<String, dynamic>? _partnerPersonalityResults;
  List<Map<String, dynamic>> _communicationPatterns = [];
  List<Map<String, dynamic>> _relationshipGoals = [];
  
  // Loading states
  bool _isLoading = true;
  bool _isLoadingCoupleData = true;
  bool _isLoadingProgress = true;
  bool _isLoadingPersonality = true;
  String? _error;

  // Relationship type (couples or co-parents)
  String _relationshipType = 'couples'; // 'couples' or 'co-parents'
  
  // Time filtering
  String _selectedTimeframe = 'Last 7 Days';
  final List<String> _timeframeOptions = [
    'Last 24 Hours',
    'Last 7 Days', 
    'Last 30 Days',
    'Last 3 Months',
    'All Time'
  ];

  // Chart data
  List<FlSpot> _relationshipProgressData = [];
  List<PieChartSectionData> _communicationBalanceData = [];
  List<BarChartGroupData> _goalsProgressData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Load all data in parallel for better performance
    _initializeData();
  }

  /// Initialize all data sources
  Future<void> _initializeData() async {
    if (!mounted) return;
    
    try {
      // Load data in parallel
      await Future.wait([
        _loadRelationshipType(),
        _loadPersonalityResults(),
        _loadInsightsData(),
        _loadCoupleExperience(),
        _loadProgressData(),
      ]);

      // Start animations after data is loaded
      if (mounted) {
        _animationController.forward();
      }
    } catch (e) {
      debugPrint('Error initializing relationship dashboard: $e');
    }
  }

  /// Refresh all insights data
  Future<void> _refreshInsights() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _initializeData();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to refresh insights: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Load personality test results for both partners
  Future<void> _loadPersonalityResults() async {
    if (!mounted) return;
    
    setState(() => _isLoadingPersonality = true);
    
    try {
      // Load user personality results
      final userResults = await _storageService.getPersonalityTestResults();
      // Load partner personality results (if available)
      final partnerResults = await _storageService.getPartnerPersonalityTestResults();
      
      if (mounted) {
        setState(() {
          _personalityResults = userResults;
          _partnerPersonalityResults = partnerResults;
          _isLoadingPersonality = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading personality results: $e');
      if (mounted) {
        setState(() {
          _personalityResults = null;
          _partnerPersonalityResults = null;
          _isLoadingPersonality = false;
        });
      }
    }
  }

  // Load relationship type preference
  Future<void> _loadRelationshipType() async {
    try {
      final type = await _storageService.getRelationshipType();
      if (mounted) {
        setState(() {
          _relationshipType = type ?? 'couples';
        });
      }
    } catch (e) {
      debugPrint('Error loading relationship type: $e');
    }
  }

  // Save relationship type preference
  Future<void> _saveRelationshipType(String type) async {
    try {
      await _storageService.saveRelationshipType(type);
      setState(() {
        _relationshipType = type;
      });
      // Refresh insights based on new type
      _loadInsightsData();
    } catch (e) {
      debugPrint('Error saving relationship type: $e');
    }
  }

  /// Load relationship insights from real analysis data
  Future<void> _loadInsightsData() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get real keyboard data first
      final realKeyboardData = await _keyboardManager.getComprehensiveRealData();
      final relationshipInsights = await _insightsService.generateRelationshipInsights();
      final analyticsData = await _analyticsService.getRelationshipAnalytics();

      if (mounted) {
        setState(() {
          // Check if user has real data
          if (realKeyboardData['real_data'] == true && (realKeyboardData['total_interactions'] ?? 0) > 0) {
            // User has real data - use it
            _insights = relationshipInsights;
          } else {
            // NEW USER - use encouraging fallback
            _insights = _generateFallbackInsights();
          }
          _isLoading = false;
        });
        
        // Generate charts with combined data
        _generateChartData();
        
        // Start animations if not already started
        if (!_animationController.isAnimating) {
          _animationController.forward();
        }
      }
    } catch (e) {
      debugPrint('Error loading relationship insights: $e');
      if (mounted) {
        setState(() {
          _error = null; // Don't show error to new users - show encouragement instead
          _isLoading = false;
          // Always provide encouraging fallback for new users
          _insights = _generateFallbackInsights();
        });
        _generateChartData();
      }
    }
  }

  /// Enhanced fallback insights for new users with encouraging messaging
  Map<String, dynamic> _generateFallbackInsights() {
    return {
      'isNewUser': true,
      'compatibility_score': 0.0,
      'communication_trend': 'ready_to_start',
      'weekly_messages': 0,
      'positive_sentiment': 0.0,
      'growth_areas': ['Building Communication Patterns', 'Discovering Your Style'],
      'relationship_strengths': ['Starting Fresh', 'Ready to Grow'],
      'recent_improvements': [],
      'communication_health': 0,
      'emotional_support': 0,
      'intimacy_cooperation': 0,
      'overall_health': 0,
      'newUserMessages': {
        'welcome': '💕 Building Your Relationship Insights',
        'subtitle': 'Your personalized relationship dashboard will develop as you use Unsaid',
        'encouragement': 'Start conversations with the Unsaid keyboard to unlock insights about your communication patterns',
        'nextSteps': [
          '1. Enable the Unsaid keyboard in Settings',
          '2. Start messaging with your partner',
          '3. Watch your insights grow over time'
        ]
      },
    };
  }

  /// Load couple-specific experience based on both personalities
  Future<void> _loadCoupleExperience() async {
    if (!mounted) return;
    
    if (widget.userPersonalityType == null ||
        widget.userCommunicationStyle == null ||
        widget.partnerPersonalityType == null ||
        widget.partnerCommunicationStyle == null) {
      setState(() {
        _isLoadingCoupleData = false;
      });
      return;
    }

    try {
      final experience = await _personalityAnalyzer.generatePersonalizedExperience(
        personalityType: widget.userPersonalityType!,
        communicationStyle: widget.userCommunicationStyle!,
        partnerPersonalityType: widget.partnerPersonalityType,
        partnerCommunicationStyle: widget.partnerCommunicationStyle,
      );

      if (mounted) {
        setState(() {
          _coupleExperience = experience['couple_experience'] ?? {};
          _isLoadingCoupleData = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading couple experience: $e');
      if (mounted) {
        setState(() {
          _isLoadingCoupleData = false;
        });
      }
    }
  }

  /// Load secure communication progress data
  Future<void> _loadProgressData() async {
    if (!mounted) return;
    
    try {
      final progress = await _progressService.getSecureCommunicationProgress(
        userPersonalityType: widget.userPersonalityType,
        userCommunicationStyle: widget.userCommunicationStyle,
        partnerPersonalityType: widget.partnerPersonalityType,
        partnerCommunicationStyle: widget.partnerCommunicationStyle,
      );

      if (mounted) {
        setState(() {
          _progressData = progress;
          _isLoadingProgress = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading progress data: $e');
      if (mounted) {
        setState(() {
          _isLoadingProgress = false;
        });
      }
    }
  }

  // Generate chart data for relationship analytics
  void _generateChartData() {
    _generateRelationshipProgressData();
    _generateCommunicationBalanceData();
    _generateGoalsProgressData();
  }

  // Generate relationship progress line chart data
  void _generateRelationshipProgressData() {
    _relationshipProgressData.clear();
    
    final analysisHistory = _keyboardManager.analysisHistory;
    if (analysisHistory.isEmpty) {
      // Default data for new relationships
      _relationshipProgressData = [
        const FlSpot(0, 0.6),
        const FlSpot(1, 0.6),
        const FlSpot(2, 0.6),
      ];
      return;
    }
    
    // Filter by timeframe and calculate relationship health score
    final filteredData = _filterDataByTimeframe(analysisHistory);
    
    for (int i = 0; i < filteredData.length; i++) {
      final confidence = (filteredData[i]['confidence'] as double?) ?? 0.6;
      final emotion = filteredData[i]['emotion']?.toString().toLowerCase() ?? '';
      
      // Calculate relationship health score based on positive communication
      double healthScore = confidence;
      if (['happy', 'supportive', 'loving', 'understanding'].contains(emotion)) {
        healthScore = (healthScore + 0.2).clamp(0.0, 1.0);
      } else if (['angry', 'frustrated', 'dismissive'].contains(emotion)) {
        healthScore = (healthScore - 0.2).clamp(0.0, 1.0);
      }
      
      _relationshipProgressData.add(FlSpot(i.toDouble(), healthScore));
    }
  }

  // Generate communication balance pie chart data
  void _generateCommunicationBalanceData() {
    _communicationBalanceData.clear();
    
    final partnerService = Provider.of<PartnerDataService>(context, listen: false);
    final analysisHistory = _keyboardManager.analysisHistory;
    
    if (analysisHistory.isEmpty && !partnerService.hasPartner) {
      // Default balance for new relationships
      _communicationBalanceData = [
        PieChartSectionData(
          color: Colors.blue.withOpacity(0.8),
          value: 50,
          title: 'You\n50%',
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          radius: 80,
        ),
        PieChartSectionData(
          color: Colors.green.withOpacity(0.8),
          value: 50,
          title: 'Partner\n50%',
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          radius: 80,
        ),
      ];
      return;
    }
    
    // Get actual message counts from partner service
    final messageCounts = partnerService.getMessageCounts();
    final userMessages = messageCounts['user'] ?? 0;
    final partnerMessages = messageCounts['partner'] ?? 0;
    final total = messageCounts['total'] ?? 0;
    
    if (total > 0) {
      _communicationBalanceData = [
        PieChartSectionData(
          color: Colors.blue.withOpacity(0.8),
          value: (userMessages / total * 100),
          title: 'You\n${(userMessages / total * 100).round()}%',
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          radius: 80,
        ),
        PieChartSectionData(
          color: Colors.green.withOpacity(0.8),
          value: (partnerMessages / total * 100),
          title: '${partnerService.partnerName ?? 'Partner'}\n${(partnerMessages / total * 100).round()}%',
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          radius: 80,
        ),
      ];
    } else {
      // Fallback for when no data exists
      _communicationBalanceData = [
        PieChartSectionData(
          color: Colors.blue.withOpacity(0.8),
          value: 50,
          title: 'You\n50%',
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          radius: 80,
        ),
        PieChartSectionData(
          color: Colors.green.withOpacity(0.8),
          value: 50,
          title: '${partnerService.partnerName ?? 'Partner'}\n50%',
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          radius: 80,
        ),
      ];
    }
  }

  // Generate relationship goals progress bar chart data
  void _generateGoalsProgressData() {
    _goalsProgressData.clear();
    
    // Sample goals progress - in real app this would come from actual goal tracking
    final goals = [
      {'name': 'Active Listening', 'progress': 0.7},
      {'name': 'Emotional Support', 'progress': 0.8},
      {'name': 'Conflict Resolution', 'progress': 0.6},
      {'name': 'Quality Time', 'progress': 0.9},
    ];
    
    for (int i = 0; i < goals.length; i++) {
      final progress = goals[i]['progress'] as double;
      _goalsProgressData.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: progress,
              color: _getProgressColor(progress),
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }
  }

  // Get color based on progress
  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.6) return Colors.orange;
    return Colors.red;
  }

  // Filter data by selected timeframe
  List<Map<String, dynamic>> _filterDataByTimeframe(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return data;
    
    try {
      final now = DateTime.now();
      DateTime cutoff;
      
      switch (_selectedTimeframe) {
        case 'Last 24 Hours':
          cutoff = now.subtract(const Duration(hours: 24));
          break;
        case 'Last 7 Days':
          cutoff = now.subtract(const Duration(days: 7));
          break;
        case 'Last 30 Days':
          cutoff = now.subtract(const Duration(days: 30));
          break;
        case 'Last 3 Months':
          cutoff = now.subtract(const Duration(days: 90));
          break;
        case 'All Time':
        default:
          return data;
      }
      
      return data.where((item) {
        final timestamp = item['timestamp'] as String?;
        if (timestamp == null || timestamp.isEmpty) return false;
        
        try {
          final date = DateTime.parse(timestamp);
          return date.isAfter(cutoff);
        } catch (e) {
          debugPrint('Error parsing timestamp: $timestamp');
          return false;
        }
      }).toList();
    } catch (e) {
      debugPrint('Error filtering data by timeframe: $e');
      return data;
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer2<NewUserExperienceService, PartnerDataService>(
      builder: (context, newUserService, partnerService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_relationshipType == 'couples' ? 'Couple Insights' : 'Co-Parent Insights'),
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              // Relationship type toggle
              PopupMenuButton<String>(
                icon: Icon(
                  _relationshipType == 'couples' ? Icons.favorite : Icons.family_restroom,
                  color: theme.colorScheme.primary,
                ),
                onSelected: _saveRelationshipType,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'couples',
                    child: Row(
                      children: [
                        Icon(Icons.favorite, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('Couple'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'co-parents',
                    child: Row(
                      children: [
                        Icon(Icons.family_restroom, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('Co-Parents'),
                      ],
                    ),
                  ),
                ],
              ),
              // Partner status indicator
              if (partnerService.hasPartner)
                IconButton(
                  icon: Icon(
                    Icons.people,
                    color: Colors.green,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Connected to ${partnerService.partnerName}'),
                      ),
                    );
                  },
                ),
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshInsights,
              ),
            ],
            bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Analytics'),
            Tab(text: 'Goals'),
          ],
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState(theme)
          : _error != null
              ? _buildErrorState(theme)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(theme, partnerService, newUserService),
                    _buildAnalyticsTab(theme, partnerService, newUserService),
                    _buildGoalsTab(theme, partnerService, newUserService),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to secure communication tips
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SecureCoupleTips(
                userPersonalityType: widget.userPersonalityType,
                partnerPersonalityType: widget.partnerPersonalityType,
              ),
            ),
          );
        },
        label: Text(_relationshipType == 'couples' ? 'Couple Tips' : 'Co-Parent Tips'),
        icon: const Icon(Icons.lightbulb),
        backgroundColor: theme.colorScheme.primary,
      ),
        );
      },
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Building your relationship insights...',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('Unable to load insights', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            _error ?? 'An unexpected error occurred',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _refreshInsights,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ThemeData theme, PartnerDataService partnerService, NewUserExperienceService newUserService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show partner connection status if not connected
          if (!partnerService.hasPartner) 
            _buildPartnerInviteCard(theme, partnerService),
          if (!partnerService.hasPartner) 
            const SizedBox(height: 24),
          
          _buildRelationshipHealthSummary(theme, partnerService),
          const SizedBox(height: 24),
          _buildRecentActivity(theme, partnerService),
          const SizedBox(height: 24),
          _buildQuickActions(theme),
          const SizedBox(height: 24),
          _buildChildrenNamesWidget(theme),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(ThemeData theme, PartnerDataService partnerService, NewUserExperienceService newUserService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time range filter
          _buildTimeRangeFilter(theme),
          const SizedBox(height: 24),
          
          // Relationship progress chart
          _buildRelationshipProgressChart(theme, partnerService),
          const SizedBox(height: 24),
          
          // Communication balance chart
          _buildCommunicationBalanceChart(theme, partnerService),
          const SizedBox(height: 24),
          
          // Secure communication insights
          _buildSecureCommunicationInsights(theme, partnerService),
        ],
      ),
    );
  }

  Widget _buildGoalsTab(ThemeData theme, PartnerDataService partnerService, NewUserExperienceService newUserService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGoalsProgress(theme, partnerService),
          const SizedBox(height: 24),
          _buildRelationshipGoals(theme, partnerService),
          const SizedBox(height: 24),
          _buildSecureCommunicationTips(theme, partnerService),
        ],
      ),
    );
  }
  Widget _buildRelationshipHealthSummary(ThemeData theme, PartnerDataService partnerService) {
    final healthScore = _calculateRelationshipHealthScore(partnerService);
    final healthLabel = _getHealthLabel(healthScore);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _relationshipType == 'couples' ? 'Relationship Health' : 'Co-Parenting Health',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (partnerService.hasPartner)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Combined Data',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric(
                    theme,
                    'Overall Health',
                    '${(healthScore * 100).round()}%',
                    Icons.favorite,
                    _getScoreColor(healthScore),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildHealthMetric(
                    theme,
                    'Communication',
                    _getCommunicationScore(),
                    Icons.chat,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildHealthMetric(
                    theme,
                    'Emotional Support',
                    _getEmotionalSupportScore(),
                    Icons.support,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildHealthMetric(
                    theme,
                    _relationshipType == 'couples' ? 'Intimacy' : 'Cooperation',
                    _getConnectionScore(),
                    _relationshipType == 'couples' ? Icons.favorite_border : Icons.handshake,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetric(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentActivity(ThemeData theme, PartnerDataService partnerService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._generateRecentActivityItems(theme, partnerService),
          ],
        ),
      ),
    );
  }

  List<Widget> _generateRecentActivityItems(ThemeData theme, PartnerDataService partnerService) {
    final combinedHistory = partnerService.hasPartner 
        ? partnerService.getCombinedAnalysisHistory()
        : _keyboardManager.analysisHistory;
    final List<Widget> items = [];
    
    if (combinedHistory.isEmpty) {
      // Default activities for new users
      items.addAll([
        _buildActivityItem(
          theme,
          'Welcome to ${_relationshipType == 'couples' ? 'Couple' : 'Co-Parent'} Insights',
          'Start messaging to see insights',
          Icons.favorite,
          theme.colorScheme.primary,
        ),
        _buildActivityItem(
          theme,
          'Set up your first relationship goal',
          'Tap Goals tab to get started',
          Icons.flag,
          Colors.blue,
        ),
        _buildActivityItem(
          theme,
          'Explore secure communication tips',
          'Available in the tips section',
          Icons.lightbulb,
          Colors.orange,
        ),
      ]);
    } else {
      // Generate activities based on combined data
      final recentAnalyses = combinedHistory.take(10).toList();
      
      // Show partner connection activity
      if (partnerService.hasPartner) {
        items.add(_buildActivityItem(
          theme,
          'Connected to ${partnerService.partnerName}',
          'Now showing combined insights',
          Icons.people,
          Colors.green,
        ));
      }
      
      // Communication trend
      final positiveCount = recentAnalyses.where((a) => 
        ['happy', 'loving', 'supportive', 'grateful'].contains(a['emotional_tone'])
      ).length;
      
      if (positiveCount > recentAnalyses.length * 0.6) {
        items.add(_buildActivityItem(
          theme,
          'Positive communication increased',
          'Last 7 days across both partners',
          Icons.trending_up,
          Colors.green,
        ));
      }
      
      // Message frequency
      final messageCounts = partnerService.getMessageCounts();
      final totalMessages = messageCounts['total'] ?? 0;
      if (totalMessages > 0) {
        items.add(_buildActivityItem(
          theme,
          'Messages analyzed: $totalMessages',
          partnerService.hasPartner ? 'Combined from both partners' : 'This week',
          Icons.message,
          Colors.blue,
        ));
      }
      
      // Compatibility score if partner exists
      if (partnerService.hasPartner) {
        final compatibilityScore = partnerService.getCompatibilityScore();
        items.add(_buildActivityItem(
          theme,
          'Compatibility Score: ${(compatibilityScore * 100).round()}%',
          'Based on communication patterns',
          Icons.favorite,
          Colors.red,
        ));
      }
      
      // Growth areas
      final growthAreas = _insights['growth_areas'] as List<dynamic>? ?? [];
      if (growthAreas.isNotEmpty) {
        items.add(_buildActivityItem(
          theme,
          'Focus area: ${growthAreas.first}',
          'Continue improving together',
          Icons.psychology,
          Colors.orange,
        ));
      }
    }
    
    return items.take(4).toList(); // Show maximum 4 items
  }

  Widget _buildActivityItem(ThemeData theme, String title, String subtitle, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    theme,
                    'Analytics',
                    Icons.analytics,
                    () => _tabController?.animateTo(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    theme,
                    'Goals',
                    Icons.flag,
                    () => _tabController?.animateTo(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    theme,
                    'Tips',
                    Icons.lightbulb,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SecureCoupleTips(
                            userPersonalityType: widget.userPersonalityType,
                            partnerPersonalityType: widget.partnerPersonalityType,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    theme,
                    'Progress',
                    Icons.trending_up,
                    () => _tabController?.animateTo(1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme, String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget for managing children's names for co-parenting
  Widget _buildChildrenNamesWidget(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.child_care,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _relationshipType == 'co-parents' ? 'Children Names' : 'Family Names',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddChildDialog(theme),
                  tooltip: 'Add child name',
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<String>>(
              future: _loadChildrenNames(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                final childrenNames = snapshot.data ?? [];
                
                if (childrenNames.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.child_friendly,
                          size: 48,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _relationshipType == 'co-parents' 
                            ? 'Add your children\'s names to get personalized communication suggestions'
                            : 'Add family member names for better conversation insights',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showAddChildDialog(theme),
                          icon: const Icon(Icons.add),
                          label: Text(_relationshipType == 'co-parents' ? 'Add Child' : 'Add Name'),
                        ),
                      ],
                    ),
                  );
                }
                
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: childrenNames.map((name) => _buildChildNameChip(theme, name)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual child name chip with delete option
  Widget _buildChildNameChip(ThemeData theme, String name) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      label: Text(name),
      deleteIcon: Icon(
        Icons.close,
        size: 18,
        color: theme.colorScheme.onSurface.withOpacity(0.6),
      ),
      onDeleted: () => _removeChildName(name),
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
    );
  }

  /// Show dialog to add a new child's name
  void _showAddChildDialog(ThemeData theme) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_relationshipType == 'co-parents' ? 'Add Child\'s Name' : 'Add Family Name'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: _relationshipType == 'co-parents' ? 'Enter child\'s name' : 'Enter family member\'s name',
                  prefixIcon: const Icon(Icons.person),
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  if (value.trim().length > 20) {
                    return 'Name must be less than 20 characters';
                  }
                  return null;
                },
                onFieldSubmitted: (_) {
                  if (formKey.currentState?.validate() ?? false) {
                    _addChildName(nameController.text.trim());
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: 12),
              Text(
                _relationshipType == 'co-parents' 
                  ? 'Adding your children\'s names helps the Unsaid keyboard provide personalized co-parenting communication suggestions.'
                  : 'Adding family names helps personalize your communication suggestions.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                _addChildName(nameController.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Load children names from secure storage
  Future<List<String>> _loadChildrenNames() async {
    try {
      return await _storageService.getChildrenNames();
    } catch (e) {
      debugPrint('Error loading children names: $e');
      return [];
    }
  }

  /// Add a new child's name
  Future<void> _addChildName(String name) async {
    try {
      final currentNames = await _loadChildrenNames();
      
      // Check for duplicates (case insensitive)
      if (currentNames.any((existing) => existing.toLowerCase() == name.toLowerCase())) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name is already in the list'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }
      
      final updatedNames = [...currentNames, name];
      await _storageService.saveChildrenNames(updatedNames);
      
      // Sync with keyboard extension
      await _keyboardManager.syncChildrenNames(updatedNames);
      
      if (mounted) {
        setState(() {}); // Refresh the widget
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding child name: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add $name'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Remove a child's name
  Future<void> _removeChildName(String name) async {
    try {
      final currentNames = await _loadChildrenNames();
      final updatedNames = currentNames.where((n) => n != name).toList();
      
      await _storageService.saveChildrenNames(updatedNames);
      
      // Sync with keyboard extension
      await _keyboardManager.syncChildrenNames(updatedNames);
      
      if (mounted) {
        setState(() {}); // Refresh the widget
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name removed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error removing child name: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove $name'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Helper methods for calculating scores
  double _calculateRelationshipHealthScore(PartnerDataService partnerService) {
    final combinedHistory = partnerService.hasPartner 
        ? partnerService.getCombinedAnalysisHistory()
        : _keyboardManager.analysisHistory;
    
    if (combinedHistory.isEmpty) {
      return (_insights['overall_health'] ?? 80) / 100.0;
    }

    double totalScore = 0.0;
    int validAnalyses = 0;

    for (final analysis in combinedHistory.take(30)) { // Last 30 analyses
      if (analysis['confidence'] != null) {
        final confidence = analysis['confidence'] as double;
        final emotionalTone = analysis['emotional_tone'] as String? ?? 'neutral';
        
        double analysisScore = confidence;
        
        // Boost score for positive emotions
        if (['happy', 'excited', 'grateful', 'loving', 'supportive'].contains(emotionalTone)) {
          analysisScore = (analysisScore + 0.2).clamp(0.0, 1.0);
        }
        // Reduce score for negative emotions
        else if (['angry', 'frustrated', 'dismissive', 'sad'].contains(emotionalTone)) {
          analysisScore = (analysisScore - 0.15).clamp(0.0, 1.0);
        }
        
        totalScore += analysisScore;
        validAnalyses++;
      }
    }

    final baseScore = validAnalyses > 0 
        ? (totalScore / validAnalyses).clamp(0.0, 1.0)
        : 0.80;

    // Boost score if partner is connected (shows commitment)
    if (partnerService.hasPartner) {
      final compatibilityScore = partnerService.getCompatibilityScore();
      return ((baseScore + compatibilityScore) / 2.0).clamp(0.0, 1.0);
    }

    return baseScore;
  }

  String _getCommunicationScore() {
    final analysisHistory = _keyboardManager.analysisHistory;
    
    if (analysisHistory.isEmpty) {
      return '${_insights['communication_health'] ?? 85}%';
    }

    final recentMessages = analysisHistory.take(20).toList();
    final positiveMessages = recentMessages.where((msg) => 
      ['happy', 'supportive', 'loving', 'understanding', 'grateful', 'excited'].contains(
        msg['emotional_tone']?.toString().toLowerCase()
      )
    ).length;
    
    final score = recentMessages.isNotEmpty 
        ? (positiveMessages / recentMessages.length * 100).round()
        : 85;
    
    return '${score}%';
  }

  String _getEmotionalSupportScore() {
    final analysisHistory = _keyboardManager.analysisHistory;
    
    if (analysisHistory.isEmpty) {
      return '${_insights['emotional_support'] ?? 80}%';
    }

    // Calculate based on supportive language patterns
    final supportiveKeywords = ['support', 'understand', 'help', 'care', 'love', 'comfort'];
    int supportiveCount = 0;
    int totalMessages = 0;

    for (final analysis in analysisHistory.take(50)) {
      if (analysis['original_message'] != null) {
        final message = analysis['original_message'].toString().toLowerCase();
        totalMessages++;
        
        for (final keyword in supportiveKeywords) {
          if (message.contains(keyword)) {
            supportiveCount++;
            break;
          }
        }
      }
    }

    final score = totalMessages > 0 
        ? (supportiveCount / totalMessages * 100).round()
        : 80;
    
    return '${score}%';
  }

  String _getConnectionScore() {
    final analysisHistory = _keyboardManager.analysisHistory;
    
    if (analysisHistory.isEmpty) {
      return '${_insights['intimacy_cooperation'] ?? 75}%';
    }

    // Calculate based on connection indicators
    final connectionKeywords = _relationshipType == 'couples' 
        ? ['love', 'miss', 'together', 'us', 'we', 'our']
        : ['team', 'together', 'cooperate', 'work', 'support', 'family'];
    
    int connectionCount = 0;
    int totalMessages = 0;

    for (final analysis in analysisHistory.take(50)) {
      if (analysis['original_message'] != null) {
        final message = analysis['original_message'].toString().toLowerCase();
        totalMessages++;
        
        for (final keyword in connectionKeywords) {
          if (message.contains(keyword)) {
            connectionCount++;
            break;
          }
        }
      }
    }

    final score = totalMessages > 0 
        ? (connectionCount / totalMessages * 100).round()
        : 75;
    
    return '${score}%';
  }

  String _getHealthLabel(double score) {
    if (score >= 0.9) return 'Excellent';
    if (score >= 0.8) return 'Very Good';
    if (score >= 0.7) return 'Good';
    if (score >= 0.6) return 'Fair';
    return 'Needs Attention';
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildTimeRangeFilter(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.date_range, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(
              'Time Range:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButton<String>(
                value: _selectedTimeframe,
                isExpanded: true,
                underline: Container(),
                items: _timeframeOptions.map((String timeframe) {
                  return DropdownMenuItem<String>(
                    value: timeframe,
                    child: Text(timeframe),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedTimeframe = newValue;
                      _generateChartData();
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelationshipProgressChart(ThemeData theme, PartnerDataService partnerService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  _relationshipType == 'couples' ? 'Relationship Progress' : 'Co-Parenting Progress',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              partnerService.hasPartner 
                  ? 'Track your relationship health over time (combined data)'
                  : 'Track your relationship health over time',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: _relationshipProgressData.isNotEmpty
                  ? LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${(value * 100).round()}%',
                                  style: theme.textTheme.bodySmall,
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.round()}',
                                  style: theme.textTheme.bodySmall,
                                );
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _relationshipProgressData,
                            isCurved: true,
                            color: theme.colorScheme.primary,
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: theme.colorScheme.primary.withOpacity(0.1),
                            ),
                          ),
                        ],
                        minY: 0,
                        maxY: 1,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start Communicating',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use the keyboard extension to track your relationship progress',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunicationBalanceChart(ThemeData theme, PartnerDataService partnerService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.balance, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Communication Balance',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              partnerService.hasPartner 
                  ? 'Balance of communication between you and ${partnerService.partnerName}'
                  : 'Balance of communication between partners',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 100, // Reduced by 50% from 200 to 100
              child: PieChart(
                PieChartData(
                  sections: _communicationBalanceData,
                  centerSpaceRadius: 30, // Also reduced center radius
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      // Add touch interaction if needed
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

  Widget _buildSecureCommunicationInsights(ThemeData theme, PartnerDataService partnerService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure Communication',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Insights',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._generateSecureCommunicationInsights(theme, partnerService),
          ],
        ),
      ),
    );
  }

  List<Widget> _generateSecureCommunicationInsights(ThemeData theme, PartnerDataService partnerService) {
    final combinedHistory = partnerService.hasPartner 
        ? partnerService.getCombinedAnalysisHistory()
        : _keyboardManager.analysisHistory;
    final List<Widget> insights = [];
    
    if (combinedHistory.isEmpty) {
      // Default insights for new users
      insights.addAll([
        _buildInsightTile(
          theme,
          'Start Your Journey',
          'Begin messaging to unlock personalized insights',
          Icons.play_arrow,
          theme.colorScheme.primary,
        ),
        _buildInsightTile(
          theme,
          'Secure Communication',
          'Learn to express yourself safely and effectively',
          Icons.security,
          Colors.green,
        ),
        _buildInsightTile(
          theme,
          'Build Trust',
          'Develop patterns that strengthen your relationship',
          Icons.favorite,
          Colors.red,
        ),
      ]);
    } else {
      // Generate insights based on combined data
      final recentAnalyses = combinedHistory.take(50).toList();
      
      // Emotional regulation insight
      final emotionalMessages = recentAnalyses.where((a) => 
        ['happy', 'grateful', 'calm', 'understanding'].contains(a['emotional_tone'])
      ).length;
      final emotionalPercentage = ((emotionalMessages / recentAnalyses.length) * 100).round();
      
      insights.add(_buildInsightTile(
        theme,
        'Emotional Regulation',
        emotionalPercentage > 60 
            ? 'Great emotional balance in your messages ($emotionalPercentage%)'
            : 'Focus on emotional awareness ($emotionalPercentage% positive)',
        Icons.mood,
        emotionalPercentage > 60 ? Colors.green : Colors.orange,
      ));
      
      // Communication clarity
      final clarityScore = recentAnalyses.fold<double>(0, (sum, a) => 
        sum + (a['confidence'] as double? ?? 0.5)
      ) / recentAnalyses.length;
      
      insights.add(_buildInsightTile(
        theme,
        'Communication Clarity',
        clarityScore > 0.7 
            ? 'Your messages are clear and well-structured'
            : 'Consider being more specific in your communication',
        Icons.lightbulb_outline,
        clarityScore > 0.7 ? Colors.green : Colors.orange,
      ));
      
      // Partner-specific insights
      if (partnerService.hasPartner) {
        final compatibilityScore = partnerService.getCompatibilityScore();
        insights.add(_buildInsightTile(
          theme,
          'Partner Compatibility',
          compatibilityScore > 0.8 
              ? 'Excellent communication compatibility with ${partnerService.partnerName}'
              : 'Working on building better communication patterns together',
          Icons.people,
          compatibilityScore > 0.8 ? Colors.green : Colors.orange,
        ));
      } else {
        // Relationship-specific insight
        final relationshipInsight = _relationshipType == 'couples'
            ? _buildCoupleSpecificInsight(theme, recentAnalyses)
            : _buildCoParentSpecificInsight(theme, recentAnalyses);
        
        insights.add(relationshipInsight);
      }
    }
    
    return insights;
  }

  Widget _buildCoupleSpecificInsight(ThemeData theme, List<Map<String, dynamic>> analyses) {
    final romanticKeywords = ['love', 'miss', 'beautiful', 'special', 'together'];
    final romanticCount = analyses.where((a) {
      final message = a['original_message']?.toString().toLowerCase() ?? '';
      return romanticKeywords.any((keyword) => message.contains(keyword));
    }).length;
    
    return _buildInsightTile(
      theme,
      'Romantic Connection',
      romanticCount > 0
          ? 'You\'re expressing love and affection regularly'
          : 'Consider sharing more appreciation with your partner',
      Icons.favorite,
      romanticCount > 0 ? Colors.red : Colors.orange,
    );
  }

  Widget _buildCoParentSpecificInsight(ThemeData theme, List<Map<String, dynamic>> analyses) {
    final cooperativeKeywords = ['team', 'together', 'help', 'support', 'family'];
    final cooperativeCount = analyses.where((a) {
      final message = a['original_message']?.toString().toLowerCase() ?? '';
      return cooperativeKeywords.any((keyword) => message.contains(keyword));
    }).length;
    
    return _buildInsightTile(
      theme,
      'Co-Parenting Teamwork',
      cooperativeCount > 0
          ? 'Strong teamwork focus in your communication'
          : 'Consider emphasizing collaboration and support',
      Icons.family_restroom,
      cooperativeCount > 0 ? Colors.blue : Colors.orange,
    );
  }

  Widget _buildInsightTile(ThemeData theme, String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsProgress(ThemeData theme, PartnerDataService partnerService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _relationshipType == 'couples' ? 'Relationship Goals' : 'Co-Parenting Goals',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Progress',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: _goalsProgressData,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${(value * 100).round()}%',
                            style: theme.textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final goals = ['Listening', 'Support', 'Conflict', 'Quality'];
                          if (value.toInt() < goals.length) {
                            return Text(
                              goals[value.toInt()],
                              style: theme.textTheme.bodySmall,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  gridData: FlGridData(show: true),
                  maxY: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelationshipGoals(ThemeData theme, PartnerDataService partnerService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  _relationshipType == 'couples' ? 'Couple Goals' : 'Co-Parenting Goals',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: RelationshipCoupleGoals(
                yourAttachment: _insights['your_style'] ?? 'Secure',
                partnerAttachment: _insights['partner_style'] ?? 'Secure',
                yourComm: _insights['your_comm'] ?? 'Assertive',
                partnerComm: _insights['partner_comm'] ?? 'Assertive',
                context: _relationshipType == 'couples' ? 'marriage' : 'co-parenting',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecureCommunicationTips(ThemeData theme, PartnerDataService partnerService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure Communication',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tips',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._getPersonalizedSecureCommunicationTips().map((tip) => 
              _buildTipTile(theme, tip),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SecureCoupleTips(
                        userPersonalityType: widget.userPersonalityType,
                        partnerPersonalityType: widget.partnerPersonalityType,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: Text('View All ${_relationshipType == 'couples' ? 'Couple' : 'Co-Parent'} Tips'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getPersonalizedSecureCommunicationTips() {
    final analysisHistory = _keyboardManager.analysisHistory;
    final baseTips = _getBaseTips();
    
    if (analysisHistory.isEmpty) {
      return baseTips.take(3).toList();
    }
    
    // Personalize tips based on analysis history
    final recentAnalyses = analysisHistory.take(30).toList();
    final emotionalTones = recentAnalyses.map((a) => a['emotional_tone']).toSet();
    
    List<Map<String, dynamic>> personalizedTips = [];
    
    // Add tips based on emotional patterns
    if (emotionalTones.contains('angry') || emotionalTones.contains('frustrated')) {
      personalizedTips.add({
        'title': 'Emotional Regulation',
        'description': 'Take deep breaths before responding when feeling intense emotions',
        'icon': Icons.self_improvement,
        'color': Colors.orange,
      });
    }
    
    if (emotionalTones.contains('sad') || emotionalTones.contains('hurt')) {
      personalizedTips.add({
        'title': 'Express Vulnerability',
        'description': 'Share your feelings openly while asking for support',
        'icon': Icons.favorite_border,
        'color': Colors.pink,
      });
    }
    
    // Add relationship-specific tips
    personalizedTips.addAll(baseTips);
    
    return personalizedTips.take(3).toList();
  }

  List<Map<String, dynamic>> _getBaseTips() {
    if (_relationshipType == 'couples') {
      return [
        {
          'title': 'Express Needs Clearly',
          'description': 'Use "I" statements to express your needs without blame',
          'icon': Icons.record_voice_over,
          'color': Colors.blue,
        },
        {
          'title': 'Practice Active Listening',
          'description': 'Focus on understanding your partner\'s perspective',
          'icon': Icons.hearing,
          'color': Colors.green,
        },
        {
          'title': 'Validate Emotions',
          'description': 'Acknowledge your partner\'s feelings before problem-solving',
          'icon': Icons.favorite,
          'color': Colors.red,
        },
        {
          'title': 'Take Breaks During Conflict',
          'description': 'Pause heated discussions to regulate emotions',
          'icon': Icons.pause_circle,
          'color': Colors.orange,
        },
      ];
    } else {
      return [
        {
          'title': 'Focus on the Children',
          'description': 'Keep discussions centered on your children\'s wellbeing',
          'icon': Icons.child_care,
          'color': Colors.purple,
        },
        {
          'title': 'Stay Business-Like',
          'description': 'Keep communication professional and solution-focused',
          'icon': Icons.business,
          'color': Colors.blue,
        },
        {
          'title': 'Use Shared Calendars',
          'description': 'Coordinate schedules transparently to avoid conflicts',
          'icon': Icons.calendar_today,
          'color': Colors.green,
        },
        {
          'title': 'Respect Boundaries',
          'description': 'Maintain appropriate boundaries in your co-parenting relationship',
          'icon': Icons.shield,
          'color': Colors.orange,
        },
      ];
    }
  }

  Widget _buildTipTile(ThemeData theme, Map<String, dynamic> tip) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (tip['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (tip['color'] as Color).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (tip['color'] as Color).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              tip['icon'] as IconData,
              color: tip['color'] as Color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip['title'] as String,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip['description'] as String,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build partner invite card for users who haven't connected with their partner
  Widget _buildPartnerInviteCard(ThemeData theme, PartnerDataService partnerService) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people_alt,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Unlock Full Relationship Insights',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Invite your ${_relationshipType == 'couples' ? 'partner' : 'co-parent'} to get deeper insights by combining both of your communication patterns.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showInvitePartnerDialog(partnerService),
                    icon: const Icon(Icons.send),
                    label: const Text('Send Invite'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showJoinPartnerDialog(partnerService),
                    icon: const Icon(Icons.login),
                    label: const Text('Join Partner'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show dialog to invite partner
  void _showInvitePartnerDialog(PartnerDataService partnerService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Your Partner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generate an invite code to share with your partner:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FutureBuilder<String>(
              future: partnerService.generateInviteCode(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            snapshot.data!,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // Copy to clipboard
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copied to clipboard')),
                            );
                          },
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show dialog to join partner using invite code
  void _showJoinPartnerDialog(PartnerDataService partnerService) {
    final codeController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Partner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Partner\'s Invite Code',
                hintText: 'Enter 8-digit code',
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Partner\'s Name',
                hintText: 'Enter your partner\'s name',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isNotEmpty && nameController.text.isNotEmpty) {
                final success = await partnerService.acceptInviteCode(
                  codeController.text.toUpperCase(),
                  nameController.text,
                );
                
                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Connected to ${nameController.text}!')),
                  );
                  _refreshInsights(); // Refresh to show combined data
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid invite code')),
                  );
                }
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}
