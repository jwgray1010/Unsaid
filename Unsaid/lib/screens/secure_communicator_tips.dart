import 'package:flutter/material.dart';

class SecureCommunicatorTips extends StatefulWidget {
  final String? currentPersonalityType;
  final String? currentCommunicationStyle;

  const SecureCommunicatorTips({
    super.key,
    this.currentPersonalityType,
    this.currentCommunicationStyle,
  });

  @override
  State<SecureCommunicatorTips> createState() => _SecureCommunicatorTipsState();
}

class _SecureCommunicatorTipsState extends State<SecureCommunicatorTips>
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
        title: const Text('Secure Attachment Tips'),
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
              _buildCurrentStatusCard(),
              const SizedBox(height: 24),
              _buildSecureTraitsSection(),
              const SizedBox(height: 24),
              _buildPersonalizedTipsSection(),
              const SizedBox(height: 24),
              _buildPracticeExercisesSection(),
              const SizedBox(height: 24),
              _buildProgressTrackingSection(),
              const SizedBox(height: 24),
              _buildDailyPracticesSection(),
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
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
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
              Icon(Icons.security, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Secure Attachment',
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
            'The gold standard of healthy communication',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Learn how to develop secure communication patterns that build trust, intimacy, and emotional safety in your relationships.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    final personalityLabels = {
      'A': 'Anxious Attachment',
      'B': 'Secure Attachment',
      'C': 'Dismissive Avoidant',
      'D': 'Disorganized/Fearful Avoidant',
    };

    final currentPersonality =
        personalityLabels[widget.currentPersonalityType] ?? 'Unknown';
    final isSecure = widget.currentPersonalityType == 'B';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSecure ? Icons.check_circle : Icons.trending_up,
                  color: isSecure ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Your Current Communication Style',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSecure
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                currentPersonality,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSecure ? Colors.green : Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isSecure
                  ? 'Congratulations! You already have secure communication patterns. These tips will help you maintain and strengthen your secure style.'
                  : 'These personalized tips will help you develop more secure communication patterns based on your current style.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecureTraitsSection() {
    final secureTraits = [
      {
        'title': 'Emotional Regulation',
        'description': 'Can manage emotions effectively during conflicts',
        'icon': Icons.favorite,
        'color': Colors.pink,
      },
      {
        'title': 'Direct Communication',
        'description': 'Express needs and feelings clearly and honestly',
        'icon': Icons.chat_bubble,
        'color': Colors.blue,
      },
      {
        'title': 'Empathy & Understanding',
        'description': 'Show genuine care for others\' perspectives',
        'icon': Icons.psychology,
        'color': Colors.purple,
      },
      {
        'title': 'Conflict Resolution',
        'description': 'Address disagreements constructively',
        'icon': Icons.handshake,
        'color': Colors.green,
      },
      {
        'title': 'Boundaries',
        'description': 'Maintain healthy personal boundaries',
        'icon': Icons.shield,
        'color': Colors.orange,
      },
      {
        'title': 'Trust Building',
        'description': 'Create safety and reliability in relationships',
        'icon': Icons.verified_user,
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
              'Key Traits of Secure Attachment',
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

  Widget _buildPersonalizedTipsSection() {
    final tips = _getPersonalizedTips();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personalized Tips for Your Style',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...tips.map((tip) => _buildTipItem(tip)),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getPersonalizedTips() {
    switch (widget.currentPersonalityType) {
      case 'A': // Anxious
        return [
          {
            'title': 'Self-Soothing First',
            'description':
                'Practice calming techniques before important conversations',
            'icon': Icons.spa,
            'color': Colors.green,
          },
          {
            'title': 'Express Needs Directly',
            'description':
                'Instead of hoping others will guess, state your needs clearly',
            'icon': Icons.record_voice_over,
            'color': Colors.blue,
          },
          {
            'title': 'Challenge Negative Assumptions',
            'description': 'Question your first instinct to assume the worst',
            'icon': Icons.psychology,
            'color': Colors.purple,
          },
          {
            'title': 'Build Self-Confidence',
            'description':
                'Remember your worth doesn\'t depend on others\' approval',
            'icon': Icons.star,
            'color': Colors.orange,
          },
        ];
      case 'C': // Avoidant
        return [
          {
            'title': 'Practice Emotional Expression',
            'description':
                'Share your feelings even when it feels uncomfortable',
            'icon': Icons.favorite,
            'color': Colors.pink,
          },
          {
            'title': 'Stay Present in Difficult Conversations',
            'description': 'Resist the urge to withdraw or shut down',
            'icon': Icons.accessibility_new,
            'color': Colors.blue,
          },
          {
            'title': 'Show Empathy Actively',
            'description':
                'Make an effort to understand others\' emotional experiences',
            'icon': Icons.handshake,
            'color': Colors.green,
          },
          {
            'title': 'Initiate Connection',
            'description': 'Take the first step in reaching out to others',
            'icon': Icons.connect_without_contact,
            'color': Colors.purple,
          },
        ];
      case 'D': // Disorganized
        return [
          {
            'title': 'Develop Consistent Patterns',
            'description': 'Create predictable communication routines',
            'icon': Icons.schedule,
            'color': Colors.blue,
          },
          {
            'title': 'Practice Self-Awareness',
            'description': 'Notice when your communication style shifts',
            'icon': Icons.visibility,
            'color': Colors.orange,
          },
          {
            'title': 'Ground Yourself',
            'description': 'Use grounding techniques when feeling overwhelmed',
            'icon': Icons.nature,
            'color': Colors.green,
          },
          {
            'title': 'Seek Clarity',
            'description': 'Ask for clarification when confused about messages',
            'icon': Icons.help,
            'color': Colors.purple,
          },
        ];
      default: // Secure or Unknown
        return [
          {
            'title': 'Model Secure Behavior',
            'description':
                'Help others feel safe by being consistent and reliable',
            'icon': Icons.security,
            'color': Colors.green,
          },
          {
            'title': 'Practice Patience',
            'description':
                'Allow others time to develop their communication skills',
            'icon': Icons.timer,
            'color': Colors.blue,
          },
          {
            'title': 'Maintain Your Boundaries',
            'description': 'Stay true to your values while being supportive',
            'icon': Icons.shield,
            'color': Colors.orange,
          },
          {
            'title': 'Continue Growing',
            'description': 'Even secure attachment types can always improve',
            'icon': Icons.trending_up,
            'color': Colors.purple,
          },
        ];
    }
  }

  Widget _buildTipItem(Map<String, dynamic> tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (tip['color'] as Color).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (tip['color'] as Color).withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              tip['icon'] as IconData,
              color: tip['color'] as Color,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip['title'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip['description'] as String,
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

  Widget _buildPracticeExercisesSection() {
    final exercises = [
      {
        'title': 'Daily Check-ins',
        'description':
            'Ask yourself: "How am I feeling right now?" and express it',
        'duration': '5 minutes',
        'icon': Icons.chat,
      },
      {
        'title': 'Conflict Practice',
        'description':
            'Role-play difficult conversations with a trusted friend',
        'duration': '15 minutes',
        'icon': Icons.group,
      },
      {
        'title': 'Boundary Setting',
        'description':
            'Practice saying "no" to requests that don\'t align with your values',
        'duration': '10 minutes',
        'icon': Icons.shield,
      },
      {
        'title': 'Empathy Building',
        'description':
            'Try to understand someone\'s perspective before responding',
        'duration': 'Ongoing',
        'icon': Icons.psychology,
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Practice Exercises',
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
            Icon(exercise['icon'] as IconData, color: Colors.blue, size: 24),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                exercise['duration'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTrackingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Track Your Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Monitor these areas as you develop secure communication:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _buildProgressItem(
              'Emotional Awareness',
              'How well do you recognize your emotions?',
            ),
            _buildProgressItem(
              'Direct Expression',
              'How clearly do you communicate your needs?',
            ),
            _buildProgressItem(
              'Conflict Comfort',
              'How comfortable are you with disagreements?',
            ),
            _buildProgressItem(
              'Empathy Response',
              'How well do you understand others\' feelings?',
            ),
            _buildProgressItem(
              'Boundary Maintenance',
              'How effectively do you maintain your boundaries?',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.radio_button_unchecked, color: Colors.grey[400], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyPracticesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Secure Communication Practices',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDailyPractice(
              'Morning',
              'Set intention for authentic communication',
            ),
            _buildDailyPractice(
              'Midday',
              'Check in with your emotions and needs',
            ),
            _buildDailyPractice(
              'Evening',
              'Reflect on interactions and celebrate growth',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.green, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Remember: Developing secure communication is a journey, not a destination. Be patient and compassionate with yourself.',
                      style: TextStyle(fontSize: 14, color: Colors.green),
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

  Widget _buildDailyPractice(String time, String practice) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(practice, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
