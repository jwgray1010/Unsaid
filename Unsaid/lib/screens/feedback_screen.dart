import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/feedback_service.dart';

/// Feedback screen for beta users to submit feedback, bug reports, and feature requests
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stepsController = TextEditingController();
  final _expectedController = TextEditingController();
  final _actualController = TextEditingController();
  final _useCaseController = TextEditingController();

  // Form state
  String _category = 'general';
  String _severity = 'medium';
  String _priority = 'medium';
  int _rating = 5;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _stepsController.dispose();
    _expectedController.dispose();
    _actualController.dispose();
    _useCaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Bug Report'),
            Tab(text: 'Feature'),
            Tab(text: 'Rating'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralFeedback(),
          _buildBugReport(),
          _buildFeatureRequest(),
          _buildRating(),
        ],
      ),
    );
  }

  Widget _buildGeneralFeedback() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'General Feedback',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your thoughts about the app, suggestions, or any other feedback.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Category selection
            _buildCategorySelector(),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Brief summary of your feedback',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Detailed description of your feedback',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitGeneralFeedback,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Submit Feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBugReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bug Report',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us fix issues by providing detailed information about the bug.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Severity
          _buildSeveritySelector(),
          const SizedBox(height: 16),

          // Title
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Bug Title',
              hintText: 'Brief description of the issue',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'What happened?',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Steps to reproduce
          TextFormField(
            controller: _stepsController,
            decoration: const InputDecoration(
              labelText: 'Steps to Reproduce',
              hintText: '1. First step\n2. Second step\n3. Bug appears',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),

          // Expected behavior
          TextFormField(
            controller: _expectedController,
            decoration: const InputDecoration(
              labelText: 'Expected Behavior',
              hintText: 'What should have happened?',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Actual behavior
          TextFormField(
            controller: _actualController,
            decoration: const InputDecoration(
              labelText: 'Actual Behavior',
              hintText: 'What actually happened?',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitBugReport,
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Submit Bug Report'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRequest() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feature Request',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Suggest new features or improvements to make the app better.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Priority
          _buildPrioritySelector(),
          const SizedBox(height: 16),

          // Title
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Feature Title',
              hintText: 'Brief description of the feature',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Detailed description of the feature',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),

          // Use case
          TextFormField(
            controller: _useCaseController,
            decoration: const InputDecoration(
              labelText: 'Use Case',
              hintText: 'How would this feature be used?',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitFeatureRequest,
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Submit Feature Request'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRating() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate the App',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your rating helps us understand how we\'re doing.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),

          // Rating stars
          Center(
            child: Column(
              children: [
                Text(
                  'Overall Rating',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setState(() {
                          _rating = index + 1;
                        });
                        HapticFeedback.lightImpact();
                      },
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  _getRatingText(_rating),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Optional review
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Review (Optional)',
              hintText: 'Tell us more about your experience',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRating,
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Submit Rating'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildCategoryChip('general', 'General'),
            _buildCategoryChip('ui', 'User Interface'),
            _buildCategoryChip('performance', 'Performance'),
            _buildCategoryChip('accuracy', 'AI Accuracy'),
            _buildCategoryChip('feature', 'Features'),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    return FilterChip(
      label: Text(label),
      selected: _category == value,
      onSelected: (selected) {
        setState(() {
          _category = value;
        });
      },
    );
  }

  Widget _buildSeveritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Severity', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildSeverityChip('low', 'Low', Colors.green),
            _buildSeverityChip('medium', 'Medium', Colors.orange),
            _buildSeverityChip('high', 'High', Colors.red),
            _buildSeverityChip('critical', 'Critical', Colors.red.shade800),
          ],
        ),
      ],
    );
  }

  Widget _buildSeverityChip(String value, String label, Color color) {
    return FilterChip(
      label: Text(label),
      selected: _severity == value,
      onSelected: (selected) {
        setState(() {
          _severity = value;
        });
      },
      backgroundColor: color.withOpacity(0.1),
      selectedColor: color.withOpacity(0.3),
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Priority', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildPriorityChip('low', 'Low'),
            _buildPriorityChip('medium', 'Medium'),
            _buildPriorityChip('high', 'High'),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityChip(String value, String label) {
    return FilterChip(
      label: Text(label),
      selected: _priority == value,
      onSelected: (selected) {
        setState(() {
          _priority = value;
        });
      },
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Future<void> _submitGeneralFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await FeedbackService.instance.submitFeedback(
        type: 'general',
        title: _titleController.text,
        description: _descriptionController.text,
        category: _category,
      );

      if (success) {
        _showSuccessMessage('Feedback submitted successfully!');
        _clearForm();
      } else {
        _showErrorMessage('Failed to submit feedback. Please try again.');
      }
    } catch (e) {
      _showErrorMessage('An error occurred: ${e.toString()}');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _submitBugReport() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await FeedbackService.instance.submitBugReport(
        title: _titleController.text,
        description: _descriptionController.text,
        stepsToReproduce: _stepsController.text,
        expectedBehavior: _expectedController.text,
        actualBehavior: _actualController.text,
        severity: _severity,
      );

      if (success) {
        _showSuccessMessage('Bug report submitted successfully!');
        _clearForm();
      } else {
        _showErrorMessage('Failed to submit bug report. Please try again.');
      }
    } catch (e) {
      _showErrorMessage('An error occurred: ${e.toString()}');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _submitFeatureRequest() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await FeedbackService.instance.submitFeatureRequest(
        title: _titleController.text,
        description: _descriptionController.text,
        useCase: _useCaseController.text,
        priority: _priority,
      );

      if (success) {
        _showSuccessMessage('Feature request submitted successfully!');
        _clearForm();
      } else {
        _showErrorMessage(
          'Failed to submit feature request. Please try again.',
        );
      }
    } catch (e) {
      _showErrorMessage('An error occurred: ${e.toString()}');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _submitRating() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await FeedbackService.instance.submitRating(
        rating: _rating,
        review: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );

      if (success) {
        _showSuccessMessage('Rating submitted successfully!');
        _clearForm();
      } else {
        _showErrorMessage('Failed to submit rating. Please try again.');
      }
    } catch (e) {
      _showErrorMessage('An error occurred: ${e.toString()}');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _stepsController.clear();
    _expectedController.clear();
    _actualController.clear();
    _useCaseController.clear();
    setState(() {
      _category = 'general';
      _severity = 'medium';
      _priority = 'medium';
      _rating = 5;
    });
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
