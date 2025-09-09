import 'package:flutter/material.dart';
import '../services/trial_service.dart';
import '../services/unsaid_api_service.dart';

/// Widget to test the new trial system with daily limits
class TrialTestWidget extends StatefulWidget {
  const TrialTestWidget({super.key});

  @override
  State<TrialTestWidget> createState() => _TrialTestWidgetState();
}

class _TrialTestWidgetState extends State<TrialTestWidget> {
  final TrialService _trialService = TrialService();
  final UnsaidApiService _apiService = UnsaidApiService();
  TrialStatusResponse? _apiTrialStatus;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeTrialService();
  }

  Future<void> _initializeTrialService() async {
    await _trialService.initialize();
    await _fetchApiTrialStatus();
    setState(() {});
  }

  Future<void> _fetchApiTrialStatus() async {
    try {
      final response = await _apiService.getTrialStatus();
      setState(() {
        _apiTrialStatus = response;
        _statusMessage = 'API trial status fetched successfully';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error fetching API status: $e';
      });
    }
  }

  Future<void> _useSecureFix() async {
    final success = await _trialService.useSecureFix();
    setState(() {
      _statusMessage = success
          ? 'Secure fix used! ${_trialService.dailySecureFixesRemaining} remaining today'
          : 'Cannot use secure fix - daily limit reached or trial expired';
    });
  }

  Future<void> _startTrial() async {
    await _trialService.startTrial();
    await _fetchApiTrialStatus();
    setState(() {
      _statusMessage = 'Trial started!';
    });
  }

  Future<void> _resetTrial() async {
    await _trialService.resetTrial();
    await _fetchApiTrialStatus();
    setState(() {
      _statusMessage = 'Trial reset (debug mode)';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trial System Test'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Local trial status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local Trial Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('Trial Active: ${_trialService.isTrialActive}'),
                    Text('Days Remaining: ${_trialService.daysRemaining}'),
                    Text('Has Subscription: ${_trialService.hasSubscription}'),
                    Text('Admin Mode: ${_trialService.isAdminMode}'),
                    const Divider(),
                    Text(
                        'Daily Secure Fixes Used: ${_trialService.dailySecureFixesUsed}/10'),
                    Text(
                        'Remaining Today: ${_trialService.dailySecureFixesRemaining}'),
                    Text(
                        'Can Use Secure Fixes: ${_trialService.canUseSecureFixes}'),
                    Text(
                        'Has Therapy Advice: ${_trialService.hasTherapyAdviceAccess}'),
                    Text(
                        'Has Tone Analysis: ${_trialService.hasToneAnalysisAccess}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // API trial status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API Trial Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    if (_apiTrialStatus != null) ...[
                      Text('API Status: ${_apiTrialStatus!.trial.status}'),
                      Text(
                          'API Days Remaining: ${_apiTrialStatus!.trial.daysRemaining}'),
                      Text(
                          'API Features: ${_apiTrialStatus!.trial.features.keys.join(", ")}'),
                      if (_apiTrialStatus!.trial.dailyLimits != null) ...[
                        const Divider(),
                        const Text('API Daily Limits:'),
                        ..._apiTrialStatus!.trial.dailyLimits!.entries.map(
                          (entry) => Text(
                              '  ${entry.key}: ${entry.value.used}/${entry.value.total}'),
                        ),
                      ],
                      if (_apiTrialStatus!.trial.pricing != null) ...[
                        const Divider(),
                        Text(
                            'Monthly Price: \$${_apiTrialStatus!.trial.pricing!.monthlyPrice}'),
                        Text(
                            'Currency: ${_apiTrialStatus!.trial.pricing!.currency}'),
                      ],
                    ] else
                      const Text('Loading API status...'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _trialService.isTrialActive ? null : _startTrial,
                  child: const Text('Start Trial'),
                ),
                ElevatedButton(
                  onPressed:
                      _trialService.canUseSecureFixes ? _useSecureFix : null,
                  child: const Text('Use Secure Fix'),
                ),
                ElevatedButton(
                  onPressed: _fetchApiTrialStatus,
                  child: const Text('Refresh API Status'),
                ),
                ElevatedButton(
                  onPressed: _resetTrial,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Reset Trial (Debug)'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status message
            if (_statusMessage.isNotEmpty)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
