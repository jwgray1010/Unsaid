import 'package:flutter/material.dart';

class IndividualGoals extends StatefulWidget {
  final String attachmentStyle;
  final String communicationStyle;

  const IndividualGoals({
    super.key,
    required this.attachmentStyle,
    required this.communicationStyle,
  });

  @override
  State<IndividualGoals> createState() => _IndividualGoalsState();
}

class _IndividualGoalsState extends State<IndividualGoals> {
  final List<String> _goals = [];
  late List<String> aiSuggestions;
  bool loadingAI = false;

  @override
  void initState() {
    super.initState();
    _fetchAISuggestions();
  }

  Future<void> _fetchAISuggestions() async {
    setState(() => loadingAI = true);
    aiSuggestions = await IndividualAIService.suggestGoals(
      attachmentStyle: widget.attachmentStyle,
      communicationStyle: widget.communicationStyle,
    );
    setState(() => loadingAI = false);
  }

  void _addGoal(String goal) {
    setState(() {
      _goals.add(goal);
    });
  }

  void _removeGoal(int index) {
    setState(() {
      _goals.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Your Personal Goals
        if (_goals.isNotEmpty) ...[
          Text(
            'Your Personal Goals',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _goals.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.flag,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(_goals[index]),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red[300]),
                    onPressed: () => _removeGoal(index),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],

        // AI Suggested Goals
        Text(
          'Recommended Goals for ${widget.attachmentStyle} Style',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 12),
        
        if (loadingAI)
          const Center(
            child: CircularProgressIndicator(),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: aiSuggestions.length,
            itemBuilder: (context, index) {
              final suggestion = aiSuggestions[index];
              final isAdded = _goals.contains(suggestion);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.lightbulb_outline,
                    color: theme.colorScheme.secondary,
                  ),
                  title: Text(suggestion),
                  trailing: isAdded
                      ? Icon(Icons.check, color: Colors.green)
                      : IconButton(
                          icon: Icon(Icons.add, color: theme.colorScheme.primary),
                          onPressed: () => _addGoal(suggestion),
                        ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class IndividualAIService {
  static Future<List<String>> suggestGoals({
    required String attachmentStyle,
    required String communicationStyle,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Return SMART goals based on attachment style
    switch (attachmentStyle.toLowerCase()) {
      case 'secure':
        return [
          "Express appreciation to important people weekly",
          "Practice active listening for 10 minutes daily",
          "Share one personal feeling each day with a close friend",
          "Set healthy boundaries in one relationship this month",
        ];
      
      case 'anxious':
      case 'anxious-preoccupied':
        return [
          "Practice self-soothing techniques when feeling overwhelmed",
          "Write in a journal for 10 minutes before bed",
          "Take 3 deep breaths before responding in difficult conversations",
          "Schedule weekly self-care activities without seeking validation",
          "Practice expressing needs directly rather than indirectly",
        ];
      
      case 'avoidant':
      case 'dismissive-avoidant':
        return [
          "Share one personal experience with a trusted friend weekly",
          "Practice saying 'I feel...' statements daily",
          "Reach out to one person when feeling stressed",
          "Schedule regular check-ins with close relationships",
          "Express gratitude to someone important each week",
        ];
      
      case 'disorganized':
      case 'fearful-avoidant':
        return [
          "Practice grounding techniques when feeling triggered",
          "Identify and name emotions as they arise",
          "Create a safe space routine for difficult conversations",
          "Set small, achievable daily connection goals",
          "Practice self-compassion when making mistakes",
        ];
      
      default:
        // Fallback for new users or unrecognized styles
        return [
          "Practice mindful communication daily",
          "Express gratitude to someone important each week",
          "Take time for self-reflection each evening",
          "Set healthy boundaries in relationships",
          "Practice active listening in conversations",
        ];
    }
  }
}
