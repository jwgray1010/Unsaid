# Safe Keyboard Data Storage System

## Overview
This system provides crash-safe data collection from the keyboard extension and automatic retrieval by the main Flutter app.

## Architecture

### 🔄 Data Flow
1. **Keyboard Extension** collects data → **In-Memory Queues** (safe, 100 items max)
2. **Background Sync** → **App Group Shared Storage** (`group.com.example.unsaid.shared`)
3. **Main Flutter App** retrieves data → **Process & Clear** stored data

### 🛡️ Safety Features
- **No Real-Time Storage**: Prevents keyboard crashes
- **In-Memory Queuing**: Ultra-fast, non-blocking
- **Background Sync**: Lowest priority, won't affect keyboard performance
- **Automatic Cleanup**: Data cleared after successful processing

## Components

### Swift Components

#### 1. SafeKeyboardDataStorage.swift
```swift
// Usage in keyboard extension
SafeKeyboardDataStorage.shared.recordInteraction(interaction)
SafeKeyboardDataStorage.shared.recordToneAnalysis(text: text, tone: tone, confidence: confidence, analysisTime: time)
SafeKeyboardDataStorage.shared.recordSuggestionInteraction(suggestion: suggestion, accepted: true, context: "user_action")
```

#### 2. KeyboardDataSyncBridge.swift
Native iOS bridge connecting storage to Flutter via method channels.

### Flutter Components

#### 1. KeyboardDataService.dart
```dart
// Manual sync
final service = KeyboardDataService();
final data = await service.retrievePendingKeyboardData();
await service.processKeyboardData(data);
await service.clearPendingKeyboardData();

// Automatic sync
final success = await service.performDataSync();
```

#### 2. KeyboardDataSyncWidget.dart
```dart
// Wrap your app for automatic sync
KeyboardDataSyncWidget(
  onDataReceived: (data) {
    print('Received ${data.totalItems} items');
  },
  child: MaterialApp(...)
)
```

## Integration Status ✅

### Completed Integration
- [x] SafeKeyboardDataStorage implemented with in-memory queues
- [x] ToneSuggestionCoordinator migrated to use SafeKeyboardDataStorage
- [x] KeyboardDataSyncBridge created and registered in AppDelegate
- [x] KeyboardDataService Flutter service created
- [x] KeyboardDataSyncWidget integrated into main.dart
- [x] Automatic sync on app start and resume

### Current Setup
The main Flutter app (`main.dart`) is wrapped with `KeyboardDataSyncWidget` which:
- Automatically syncs data when app starts
- Syncs when app becomes active from background
- Handles errors gracefully
- Provides callbacks for data processing

## Usage Examples

### Manual Data Sync
```dart
import 'package:your_app/widgets/keyboard_data_sync_widget.dart';

// Check if there's pending data
bool hasPending = await KeyboardDataManualSync.hasPendingData();

// Get summary
String summary = await KeyboardDataManualSync.getPendingDataSummary();

// Manual sync
await KeyboardDataManualSync.manualSync();
```

### Custom Data Processing
Override the `processKeyboardData` method in `KeyboardDataService`:

```dart
@override
Future<void> processKeyboardData(KeyboardAnalyticsData data) async {
  // Custom processing logic
  for (final interaction in data.interactions) {
    // Process each interaction
  }
  
  for (final toneData in data.toneData) {
    // Process tone analysis data
  }
  
  // Call parent to handle default processing
  await super.processKeyboardData(data);
}
```

## Data Types Collected

### Interaction Data
- Interaction type (suggestion, analysis, etc.)
- Tone status and confidence
- Text length (no actual text for privacy)
- Suggestion acceptance
- Analysis timing
- App context

### Tone Analysis Data
- Tone classification
- Confidence score
- Analysis timing
- Text hash (for deduplication)

### Suggestion Data
- Suggestion acceptance/rejection
- Context information
- Suggestion length

### Analytics Data
- General event tracking
- Performance metrics
- Error reporting

## Privacy & Security
- **No Actual Text Storage**: Only metadata like text length and hash
- **Local Processing**: All data stays on device until synced
- **Automatic Cleanup**: Data cleared after processing
- **App Group Isolation**: Shared data isolated to app group

## Performance
- **Zero Keyboard Impact**: All operations are async and background
- **Memory Bounded**: Maximum 100 items per queue
- **Efficient Sync**: Only syncs when data is available
- **Graceful Degradation**: Continues working even if sync fails

## Monitoring

### Logs to Watch
```
🔄 Retrieving pending keyboard data...
📥 Retrieved keyboard data: Interactions: X, Tone: Y, Suggestions: Z
✅ Successfully processed all keyboard data
🗑️ Cleared all pending data
```

### Error Handling
All errors are logged with detailed context:
```
❌ Platform error retrieving keyboard data: [error]
⚠️ Failed to clear keyboard data after processing
```

## Testing

### Test Data Collection
1. Use keyboard extension to type and trigger suggestions
2. Check logs for data queuing: `✅ Safely queued interaction`
3. Open main app to trigger sync
4. Verify data processing logs

### Test Manual Sync
```dart
// In your app
await KeyboardDataManualSync.manualSync();
```

This system ensures that your keyboard extension will never crash due to data storage operations while still collecting valuable analytics for your main app!
