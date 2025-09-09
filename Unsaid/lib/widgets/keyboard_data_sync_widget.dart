import 'package:flutter/material.dart';
import '../services/keyboard_data_service.dart';

/// Widget that automatically syncs keyboard data when the app becomes active
/// Place this in your app's main widget tree to enable automatic data sync
class KeyboardDataSyncWidget extends StatefulWidget {
  final Widget child;
  final Function(KeyboardAnalyticsData)? onDataReceived;
  final Function(String)? onError;
  final bool enableAutoSync;
  final Duration syncInterval;

  const KeyboardDataSyncWidget({
    super.key,
    required this.child,
    this.onDataReceived,
    this.onError,
    this.enableAutoSync = true,
    this.syncInterval = const Duration(minutes: 5),
  });

  @override
  State<KeyboardDataSyncWidget> createState() => _KeyboardDataSyncWidgetState();
}

class _KeyboardDataSyncWidgetState extends State<KeyboardDataSyncWidget>
    with WidgetsBindingObserver {
  final KeyboardDataService _keyboardDataService = KeyboardDataService();
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Perform initial sync when widget is created
    if (widget.enableAutoSync) {
      _performInitialSync();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Sync data when app becomes active
    if (state == AppLifecycleState.resumed && widget.enableAutoSync) {
      _performDataSync();
    }
  }

  /// Perform initial data sync when app starts
  Future<void> _performInitialSync() async {
    // Small delay to let the app fully initialize
    await Future.delayed(const Duration(milliseconds: 500));
    await _performDataSync();
  }

  /// Perform keyboard data sync
  Future<void> _performDataSync() async {
    if (_isSyncing) return; // Prevent concurrent syncs

    setState(() {
      _isSyncing = true;
    });

    try {
      debugPrint('🔄 KeyboardDataSyncWidget: Starting data sync...');

      // Check for pending data first
      final metadata = await _keyboardDataService.getKeyboardStorageMetadata();
      final hasPendingData = metadata?['has_pending_data'] == true;

      if (!hasPendingData) {
        debugPrint('✅ KeyboardDataSyncWidget: No pending data to sync');
        return;
      }

      // Retrieve keyboard data
      final keyboardData =
          await _keyboardDataService.retrievePendingKeyboardData();

      if (keyboardData != null && keyboardData.hasData) {
        debugPrint(
            '📥 KeyboardDataSyncWidget: Retrieved ${keyboardData.totalItems} items');

        // Process the data
        await _keyboardDataService.processKeyboardData(keyboardData);

        // Notify callback if provided
        widget.onDataReceived?.call(keyboardData);

        // Clear the data
        final cleared = await _keyboardDataService.clearPendingKeyboardData();

        if (cleared) {
          debugPrint(
              '✅ KeyboardDataSyncWidget: Data sync completed successfully');
        } else {
          debugPrint(
              '⚠️ KeyboardDataSyncWidget: Warning - data not cleared after sync');
        }
      } else {
        debugPrint('ℹ️ KeyboardDataSyncWidget: No keyboard data to process');
      }
    } catch (e) {
      debugPrint('❌ KeyboardDataSyncWidget: Data sync error: $e');
      widget.onError?.call(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Extension to add keyboard data sync to any app
/// Usage: Wrap your MaterialApp with this widget
class KeyboardDataSyncApp extends StatelessWidget {
  final Widget app;
  final Function(KeyboardAnalyticsData)? onDataReceived;
  final Function(String)? onError;

  const KeyboardDataSyncApp({
    super.key,
    required this.app,
    this.onDataReceived,
    this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return KeyboardDataSyncWidget(
      onDataReceived: onDataReceived,
      onError: onError,
      child: app,
    );
  }
}

/// Service extension for manual data sync operations
extension KeyboardDataManualSync on KeyboardDataService {
  /// Manually trigger a data sync (useful for testing)
  static Future<void> manualSync() async {
    final service = KeyboardDataService();
    final success = await service.performDataSync();

    if (success) {
      debugPrint('✅ Manual keyboard data sync completed');
    } else {
      debugPrint('❌ Manual keyboard data sync failed');
    }
  }

  /// Check if there's pending keyboard data
  static Future<bool> hasPendingData() async {
    final service = KeyboardDataService();
    final metadata = await service.getKeyboardStorageMetadata();
    return metadata?['has_pending_data'] == true;
  }

  /// Get summary of pending data
  static Future<String> getPendingDataSummary() async {
    final service = KeyboardDataService();
    final metadata = await service.getKeyboardStorageMetadata();

    if (metadata == null) return 'No metadata available';

    final interactions = metadata['total_interactions'] ?? 0;
    final toneData = metadata['total_tone_data'] ?? 0;
    final suggestions = metadata['total_suggestions'] ?? 0;
    final analytics = metadata['total_analytics'] ?? 0;

    return 'Pending: $interactions interactions, $toneData tone analyses, $suggestions suggestions, $analytics analytics';
  }
}
