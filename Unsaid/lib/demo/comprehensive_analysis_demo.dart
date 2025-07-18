import 'package:flutter/material.dart';
import '../services/keyboard_manager.dart';

/// Demonstration of the comprehensive AI analysis integration
/// This shows how the Flutter app connects to the iOS AdvancedTextCommunicationAnalyzer
class ComprehensiveAnalysisDemo extends StatefulWidget {
  const ComprehensiveAnalysisDemo({super.key});

  @override
  State<ComprehensiveAnalysisDemo> createState() =>
      _ComprehensiveAnalysisDemoState();
}

class _ComprehensiveAnalysisDemoState extends State<ComprehensiveAnalysisDemo> {
  final TextEditingController _messageController = TextEditingController();
  final KeyboardManager _keyboardManager = KeyboardManager();
  Map<String, dynamic>? _analysisResults;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _keyboardManager.initialize();
  }

  Future<void> _runDemo() async {
    final demoMessages = [
      "I need to talk to you about our custody schedule. This isn't working for me.",
      "I understand you're stressed about the school situation. How can we work together to support our child?",
      "You always make these decisions without consulting me. It's not fair to our daughter.",
      "I appreciate you taking the time to discuss this. Let's focus on what's best for our son.",
    ];

    setState(() {
      _isAnalyzing = true;
    });

    for (final message in demoMessages) {
      print('\n=== ANALYZING MESSAGE: "$message" ===');

      final analysis = await _keyboardManager.performComprehensiveAnalysis(
        message,
        relationshipContext: 'Co-Parenting',
        attachmentStyle: 'Secure',
        communicationStyle: 'Secure Attachment',
        childAge: 8,
      );

      if (analysis.containsKey('error')) {
        print('ERROR: ${analysis['error']}');
        continue;
      }

      print('✅ ANALYSIS COMPLETE:');
      print('📊 Tone Analysis:');
      print(
        '   - Dominant Tone: ${analysis['tone_analysis']['dominant_tone']}',
      );
      print(
        '   - Empathy Score: ${(analysis['tone_analysis']['empathy_score'] * 100).toInt()}%',
      );
      print(
        '   - Clarity Score: ${(analysis['tone_analysis']['clarity_score'] * 100).toInt()}%',
      );

      print('👨‍👩‍👧‍👦 Co-Parenting Analysis:');
      print(
        '   - Child Focus Score: ${(analysis['coparenting_analysis']['child_focus_score'] * 100).toInt()}%',
      );
      print(
        '   - Conflict Risk: ${analysis['coparenting_analysis']['conflict_risk_level']}',
      );
      print(
        '   - Emotional Regulation: ${(analysis['coparenting_analysis']['emotional_regulation_score'] * 100).toInt()}%',
      );

      print('🧠 Emotional Intelligence:');
      print(
        '   - Primary Emotion: ${analysis['emotional_analysis']['primary_emotion']}',
      );
      print(
        '   - Intensity: ${(analysis['emotional_analysis']['emotional_intensity'] * 100).toInt()}%',
      );
      print(
        '   - Stability Risk: ${(analysis['emotional_analysis']['stability_risk'] * 100).toInt()}%',
      );

      print('💡 AI Suggestions:');
      final suggestions = analysis['integrated_suggestions'] as List<dynamic>;
      for (final suggestion in suggestions) {
        print('   - ${suggestion['title']}: ${suggestion['description']}');
      }

      print(
        '📱 SENT TO iOS KEYBOARD: Analysis data has been transmitted to AdvancedTextCommunicationAnalyzer',
      );

      // Small delay between messages
      await Future.delayed(const Duration(milliseconds: 500));
    }

    setState(() {
      _isAnalyzing = false;
      _analysisResults = {'demo': 'Complete - Check console for results'};
    });
  }

  Future<void> _analyzeCustomMessage() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message to analyze')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final analysis = await _keyboardManager.performComprehensiveAnalysis(
        _messageController.text.trim(),
        relationshipContext: 'Co-Parenting',
        attachmentStyle: 'Secure',
        communicationStyle: 'Secure Attachment',
        childAge: 8,
      );

      setState(() {
        _analysisResults = analysis;
      });

      if (!analysis.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Analysis complete! Data sent to iOS keyboard.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprehensive AI Analysis Demo'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'iOS AdvancedTextCommunicationAnalyzer Integration Demo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            const Text(
              'This demonstrates how the Flutter app connects to the iOS keyboard\'s advanced analyzer:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),

            const Text(
              '• Co-Parenting AI Analysis\n'
              '• Emotional Intelligence Coaching\n'
              '• Advanced Tone Analysis\n'
              '• Predictive AI Outcomes\n'
              '• Child Development Considerations',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Demo button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAnalyzing ? null : _runDemo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: _isAnalyzing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Running Demo Analysis...'),
                        ],
                      )
                    : const Text('Run Demo Analysis (Check Console)'),
              ),
            ),
            const SizedBox(height: 16),

            // Custom message input
            const Text('Or analyze your own message:'),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Enter a message to analyze...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAnalyzing ? null : _analyzeCustomMessage,
                child: const Text('Analyze & Send to iOS Keyboard'),
              ),
            ),
            const SizedBox(height: 16),

            // Results display
            if (_analysisResults != null)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Analysis Results',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        if (_analysisResults!.containsKey('demo'))
                          Text(_analysisResults!['demo'])
                        else
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_analysisResults!['tone_analysis'] !=
                                      null)
                                    _buildAnalysisSection(
                                      'Tone Analysis',
                                      _analysisResults!['tone_analysis'],
                                    ),

                                  if (_analysisResults!['coparenting_analysis'] !=
                                      null)
                                    _buildAnalysisSection(
                                      'Co-Parenting Analysis',
                                      _analysisResults!['coparenting_analysis'],
                                    ),

                                  if (_analysisResults!['emotional_analysis'] !=
                                      null)
                                    _buildAnalysisSection(
                                      'Emotional Analysis',
                                      _analysisResults!['emotional_analysis'],
                                    ),

                                  if (_analysisResults!['integrated_suggestions'] !=
                                      null)
                                    _buildSuggestionsSection(
                                      _analysisResults!['integrated_suggestions'],
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSection(String title, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...data.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      '${entry.key}: ',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Expanded(
                      child: Text(
                        entry.value.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection(List<dynamic> suggestions) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Suggestions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...suggestions.map((suggestion) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            suggestion['description'],
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
