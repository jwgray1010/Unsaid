import 'package:flutter/material.dart';

class SecureCoupleTips extends StatefulWidget {
  final String? userPersonalityType;
  final String? userCommunicationStyle;
  final String? partnerPersonalityType;
  final String? partnerCommunicationStyle;

  const SecureCoupleTips({
    super.key,
    this.userPersonalityType,
    this.userCommunicationStyle,
    this.partnerPersonalityType,
    this.partnerCommunicationStyle,
  });

  @override
  State<SecureCoupleTips> createState() => _SecureCoupleTipsState();
}

class _SecureCoupleTipsState extends State<SecureCoupleTips>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Secure Couple Tips'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildCoupleStatusCard(),
              const SizedBox(height: 24),
              _buildSecureCoupleTraitsSection(),
              const SizedBox(height: 24),
              _buildPersonalizedCoupleStrategiesSection(),
              const SizedBox(height: 24),
              _buildCoupleExercisesSection(),
              const SizedBox(height: 24),
              _buildConflictResolutionSection(),
              const SizedBox(height: 24),
              _buildDailyCoupleRitualsSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Secure Couple',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Building a relationship of trust, safety, and growth',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Learn how to create a secure partnership where both individuals feel safe, valued, and supported in their growth.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoupleStatusCard() {
    final compatibility = _calculateCompatibility();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCompatibilityIcon(compatibility['level']),
                  color: _getCompatibilityColor(compatibility['level']),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Your Couple Compatibility',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getCompatibilityColor(
                      compatibility['level'],
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${compatibility['score']}% Compatible',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _getCompatibilityColor(compatibility['level']),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    compatibility['level'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              compatibility['description'],
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateCompatibility() {
    // Simple compatibility calculation based on personality types
    final userType = widget.userPersonalityType;
    final partnerType = widget.partnerPersonalityType;

    if (userType == null || partnerType == null) {
      return {
        'score': 75,
        'level': 'Good Match',
        'description':
            'Complete your personality assessments for a more detailed compatibility analysis.',
      };
    }

    final compatibilityMatrix = {
      'A-A': {'score': 60, 'level': 'Moderate Challenge'},
      'A-B': {'score': 90, 'level': 'Excellent Match'},
      'A-C': {'score': 40, 'level': 'High Challenge'},
      'A-D': {'score': 50, 'level': 'Moderate Challenge'},
      'B-B': {'score': 85, 'level': 'Excellent Match'},
      'B-C': {'score': 70, 'level': 'Good Match'},
      'B-D': {'score': 80, 'level': 'Good Match'},
      'C-C': {'score': 55, 'level': 'Moderate Challenge'},
      'C-D': {'score': 45, 'level': 'High Challenge'},
      'D-D': {'score': 35, 'level': 'High Challenge'},
    };

    final key = '$userType-$partnerType';
    final reverseKey = '$partnerType-$userType';
    final result =
        compatibilityMatrix[key] ??
        compatibilityMatrix[reverseKey] ??
        {'score': 75, 'level': 'Good Match'};

    return {
      'score': result['score'],
      'level': result['level'],
      'description': _getCompatibilityDescription(result['level'].toString()),
    };
  }

  String _getCompatibilityDescription(String level) {
    switch (level) {
      case 'Excellent Match':
        return 'You have natural compatibility! Focus on maintaining and deepening your secure patterns.';
      case 'Good Match':
        return 'You have solid compatibility with room for growth. These tips will help strengthen your bond.';
      case 'Moderate Challenge':
        return 'Your differences can be strengths with conscious effort. Focus on understanding and bridging gaps.';
      case 'High Challenge':
        return 'Your partnership requires dedicated work, but growth is possible with commitment and understanding.';
      default:
        return 'Every couple can build security with patience, understanding, and consistent effort.';
    }
  }

  IconData _getCompatibilityIcon(String level) {
    switch (level) {
      case 'Excellent Match':
        return Icons.favorite;
      case 'Good Match':
        return Icons.thumb_up;
      case 'Moderate Challenge':
        return Icons.trending_up;
      case 'High Challenge':
        return Icons.build;
      default:
        return Icons.favorite_border;
    }
  }

  Color _getCompatibilityColor(String level) {
    switch (level) {
      case 'Excellent Match':
        return Colors.green;
      case 'Good Match':
        return Colors.blue;
      case 'Moderate Challenge':
        return Colors.orange;
      case 'High Challenge':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSecureCoupleTraitsSection() {
    final secureTraits = [
      {
        'title': 'Emotional Safety',
        'description': 'Both partners feel safe to express vulnerability',
        'icon': Icons.security,
        'color': Colors.green,
      },
      {
        'title': 'Open Communication',
        'description': 'Honest, direct, and respectful dialogue',
        'icon': Icons.chat_bubble_outline,
        'color': Colors.blue,
      },
      {
        'title': 'Mutual Support',
        'description': 'Encouraging each other\'s growth and dreams',
        'icon': Icons.handshake,
        'color': Colors.purple,
      },
      {
        'title': 'Healthy Boundaries',
        'description': 'Respecting individual needs and space',
        'icon': Icons.account_balance,
        'color': Colors.orange,
      },
      {
        'title': 'Conflict Resolution',
        'description': 'Working through disagreements constructively',
        'icon': Icons.psychology,
        'color': Colors.pink,
      },
      {
        'title': 'Shared Growth',
        'description': 'Evolving together while maintaining individuality',
        'icon': Icons.trending_up,
        'color': Colors.teal,
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Characteristics of Secure Couples',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...secureTraits.map((trait) => _buildTraitItem(trait)),
          ],
        ),
      ),
    );
  }

  Widget _buildTraitItem(Map<String, dynamic> trait) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (trait['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              trait['icon'] as IconData,
              color: trait['color'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trait['title'] as String,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trait['description'] as String,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedCoupleStrategiesSection() {
    final strategies = _getPersonalizedStrategies();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personalized Strategies for Your Partnership',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...strategies.map((strategy) => _buildStrategyItem(strategy)),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getPersonalizedStrategies() {
    final userType = widget.userPersonalityType;
    final partnerType = widget.partnerPersonalityType;

    if (userType == null || partnerType == null) {
      return _getGeneralStrategies();
    }

    // Strategies based on personality combination
    final key = '$userType-$partnerType';
    final reverseKey = '$partnerType-$userType';

    final strategies = _getCombinationStrategies();
    return strategies[key] ?? strategies[reverseKey] ?? _getGeneralStrategies();
  }

  Map<String, List<Map<String, dynamic>>> _getCombinationStrategies() {
    return {
      'A-A': [
        {
          'title': 'Create Reassurance Rituals',
          'description':
              'Establish daily check-ins to provide mutual comfort and security',
          'icon': Icons.favorite,
          'color': Colors.pink,
        },
        {
          'title': 'Practice Calming Together',
          'description':
              'Learn anxiety management techniques you can use as a couple',
          'icon': Icons.spa,
          'color': Colors.green,
        },
        {
          'title': 'Challenge Assumptions Together',
          'description': 'Help each other question negative interpretations',
          'icon': Icons.psychology,
          'color': Colors.purple,
        },
      ],
      'A-B': [
        {
          'title': 'Patience with Anxiety',
          'description':
              'Secure partner provides consistent reassurance without enabling',
          'icon': Icons.timer,
          'color': Colors.blue,
        },
        {
          'title': 'Model Security',
          'description':
              'Secure partner demonstrates calm, consistent responses',
          'icon': Icons.star,
          'color': Colors.amber,
        },
        {
          'title': 'Gradual Independence',
          'description': 'Anxious partner practices self-soothing with support',
          'icon': Icons.trending_up,
          'color': Colors.green,
        },
      ],
      'A-C': [
        {
          'title': 'Bridge Emotional Gaps',
          'description': 'Create structured ways to share feelings regularly',
          'icon': Icons.connecting_airports,
          'color': Colors.blue,
        },
        {
          'title': 'Respect Different Paces',
          'description':
              'Anxious partner slows down, avoidant partner speeds up gradually',
          'icon': Icons.speed,
          'color': Colors.orange,
        },
        {
          'title': 'Break Pursuit-Withdrawal Cycle',
          'description': 'Recognize and interrupt this common pattern',
          'icon': Icons.sync_disabled,
          'color': Colors.red,
        },
      ],
      'B-B': [
        {
          'title': 'Maintain Growth Mindset',
          'description': 'Continue challenging each other to grow and improve',
          'icon': Icons.psychology,
          'color': Colors.purple,
        },
        {
          'title': 'Support Others\' Security',
          'description': 'Use your stability to help friends and family',
          'icon': Icons.group,
          'color': Colors.blue,
        },
        {
          'title': 'Deepen Intimacy',
          'description':
              'Explore new levels of emotional and physical connection',
          'icon': Icons.favorite,
          'color': Colors.pink,
        },
      ],
      'B-C': [
        {
          'title': 'Patient Connection Building',
          'description':
              'Secure partner creates safe space for emotional expression',
          'icon': Icons.handshake,
          'color': Colors.green,
        },
        {
          'title': 'Respect Independence',
          'description': 'Secure partner doesn\'t push too hard for connection',
          'icon': Icons.account_balance,
          'color': Colors.blue,
        },
        {
          'title': 'Gradual Vulnerability',
          'description': 'Avoidant partner practices small steps of openness',
          'icon': Icons.stairs,
          'color': Colors.orange,
        },
      ],
      'C-C': [
        {
          'title': 'Schedule Emotional Check-ins',
          'description': 'Create structure for sharing feelings and needs',
          'icon': Icons.schedule,
          'color': Colors.blue,
        },
        {
          'title': 'Practice Emotional Expression',
          'description': 'Take turns sharing something vulnerable each day',
          'icon': Icons.record_voice_over,
          'color': Colors.purple,
        },
        {
          'title': 'Celebrate Small Steps',
          'description': 'Acknowledge and appreciate efforts to connect',
          'icon': Icons.celebration,
          'color': Colors.orange,
        },
      ],
    };
  }

  List<Map<String, dynamic>> _getGeneralStrategies() {
    return [
      {
        'title': 'Daily Connection Rituals',
        'description': 'Establish regular times for meaningful conversation',
        'icon': Icons.schedule,
        'color': Colors.blue,
      },
      {
        'title': 'Practice Active Listening',
        'description':
            'Focus fully on understanding your partner\'s perspective',
        'icon': Icons.hearing,
        'color': Colors.purple,
      },
      {
        'title': 'Express Appreciation',
        'description': 'Regularly acknowledge what you value about each other',
        'icon': Icons.favorite,
        'color': Colors.pink,
      },
      {
        'title': 'Maintain Individual Growth',
        'description':
            'Support each other\'s personal development and interests',
        'icon': Icons.trending_up,
        'color': Colors.green,
      },
    ];
  }

  Widget _buildStrategyItem(Map<String, dynamic> strategy) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (strategy['color'] as Color).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (strategy['color'] as Color).withOpacity(0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              strategy['icon'] as IconData,
              color: strategy['color'] as Color,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strategy['title'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strategy['description'] as String,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoupleExercisesSection() {
    final exercises = [
      {
        'title': 'Daily Gratitude Exchange',
        'description':
            'Share three things you appreciate about your partner each day',
        'duration': '10 minutes',
        'icon': Icons.favorite,
        'frequency': 'Daily',
      },
      {
        'title': 'Weekly Relationship Check-in',
        'description':
            'Discuss how you\'re feeling about the relationship and areas for growth',
        'duration': '30 minutes',
        'icon': Icons.chat,
        'frequency': 'Weekly',
      },
      {
        'title': 'Conflict Resolution Practice',
        'description':
            'Role-play how to handle common disagreements constructively',
        'duration': '20 minutes',
        'icon': Icons.handshake,
        'frequency': 'Bi-weekly',
      },
      {
        'title': 'Dream Sharing Session',
        'description': 'Share your individual and couple goals and dreams',
        'duration': '45 minutes',
        'icon': Icons.star,
        'frequency': 'Monthly',
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Couple Bonding Exercises',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...exercises.map((exercise) => _buildExerciseItem(exercise)),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseItem(Map<String, dynamic> exercise) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(exercise['icon'] as IconData, color: Colors.purple, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise['title'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exercise['description'] as String,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    exercise['frequency'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.purple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exercise['duration'] as String,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictResolutionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Secure Conflict Resolution Framework',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildConflictStep(
              '1',
              'Pause & Breathe',
              'Take a moment to calm down before responding',
            ),
            _buildConflictStep(
              '2',
              'Listen First',
              'Understand your partner\'s perspective completely',
            ),
            _buildConflictStep(
              '3',
              'Express Clearly',
              'Share your feelings using "I" statements',
            ),
            _buildConflictStep(
              '4',
              'Find Common Ground',
              'Identify shared values and goals',
            ),
            _buildConflictStep(
              '5',
              'Collaborate',
              'Work together to find mutually beneficial solutions',
            ),
            _buildConflictStep(
              '6',
              'Follow Up',
              'Check in later to ensure resolution feels complete',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyCoupleRitualsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Secure Couple Rituals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRitualItem(
              'Morning Connection',
              'Start each day with a meaningful hug and positive intention',
            ),
            _buildRitualItem(
              'Midday Check-in',
              'Send a loving message or call during the day',
            ),
            _buildRitualItem(
              'Evening Reflection',
              'Share highlights and challenges from your day',
            ),
            _buildRitualItem(
              'Before Sleep',
              'Express gratitude and affection before bed',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.purple, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Consistency matters more than perfection. Even small, regular acts of love and attention build security over time.',
                      style: TextStyle(fontSize: 14, color: Colors.purple),
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

  Widget _buildRitualItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.favorite, color: Colors.pink, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
