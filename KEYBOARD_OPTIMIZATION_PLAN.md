# Keyboard Extension Optimization Plan

## Current State Analysis
- **KeyboardController.swift**: 4051+ lines (too large)
- **ToneSuggestionCoordinator.swift**: Heavy networking and ML logic
- **EnhancedCommunicatorService.swift**: Complex API integration
- **SafeKeyboardDataStorage.swift**: Full analytics pipeline

## Optimization Strategy

### 1. Move to Main App (Runner)
```
UnsaidKeyboard/               →    Runner/
├── ToneSuggestionCoordinator ←    ├── Services/ToneAnalysisService
├── EnhancedCommunicatorService ←  ├── Services/CommunicatorService  
├── SafeKeyboardDataStorage ←      ├── Services/KeyboardAnalyticsService
└── Complex ML logic          ←    └── Services/PersonalityAnalysisService
```

### 2. Keep in Keyboard Extension (Minimal)
```
UnsaidKeyboard/ (Optimized)
├── KeyboardViewController.swift (50 lines)
├── KeyboardController.swift (800 lines - trimmed)
├── KeyboardBridge.swift (NEW - 200 lines)
├── LightweightSpellChecker.swift (keep)
└── Basic UI components only
```

### 3. New Bridge Pattern
```
App Group Shared Storage
├── analysis_requests/
├── analysis_results/ 
├── suggestion_requests/
├── suggestion_results/
└── analytics_buffer/
```

## Implementation Steps

### Phase 1: Create Services in Main App
1. Move ToneSuggestionCoordinator → ToneAnalysisService (Runner)
2. Move EnhancedCommunicatorService → CommunicatorService (Runner)  
3. Move SafeKeyboardDataStorage → KeyboardAnalyticsService (Runner)

### Phase 2: Create Lightweight Bridge
1. Create KeyboardBridge.swift for communication
2. Use App Group UserDefaults for fast IPC
3. Background queue processing in main app

### Phase 3: Optimize KeyboardController
1. Remove networking code (use bridge)
2. Remove complex analytics (use bridge)
3. Keep only essential UI and input handling
4. Reduce to ~800 lines from 4051 lines

## Expected Benefits
- **80% size reduction** in keyboard extension
- **Faster keyboard launch** (less code to load)
- **Better memory usage** (heavy processing in main app)
- **More reliable networking** (main app handles retries)
- **Better analytics** (main app processes in background)
