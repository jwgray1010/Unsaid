import Foundation
import os.log

/// Safe background analytics storage that prevents keyboard crashes
/// Stores data locally and syncs to main app only when safe
class SafeKeyboardDataStorage {
    
    // MARK: - Singleton
    static let shared = SafeKeyboardDataStorage()
    private init() {}
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.example.unsaid.unsaid.UnsaidKeyboard", category: "SafeDataStorage")
    private let appGroupIdentifier = "group.com.example.unsaid"
    private let maxQueueSize = 100  // Prevent memory issues
    private let maxRetries = 3
    
    // MARK: - Storage Keys
    private struct StorageKeys {
        static let pendingInteractions = "pending_keyboard_interactions"
        static let pendingAnalytics = "pending_keyboard_analytics"
        static let pendingToneData = "pending_tone_analysis_data"
        static let pendingSuggestions = "pending_suggestion_data"
        static let storageMetadata = "keyboard_storage_metadata"
        static let lastSyncTimestamp = "last_sync_timestamp"
    }
    
    // MARK: - In-Memory Queues (Safe)
    private var interactionQueue: [[String: Any]] = []
    private var analyticsQueue: [[String: Any]] = []
    private var toneQueue: [[String: Any]] = []
    private var suggestionQueue: [[String: Any]] = []
    
    // MARK: - Thread Safety
    private let dataQueue = DispatchQueue(label: "com.unsaid.safe.storage", qos: .utility)
    private var isProcessing = false
    
    // MARK: - Safe UserDefaults Access
    private var safeUserDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }
    
    // MARK: - Public API - Safe Data Recording
    
    /// Safely record keyboard interaction without blocking keyboard
    func recordInteraction(_ interaction: KeyboardInteraction) {
        dataQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Convert to safe dictionary format
            let interactionData = self.safeInteractionDictionary(from: interaction)
            
            // Add to in-memory queue
            self.interactionQueue.append(interactionData)
            
            // Limit queue size to prevent memory issues
            if self.interactionQueue.count > self.maxQueueSize {
                self.interactionQueue.removeFirst()
            }
            
            // Try background sync if safe
            self.tryBackgroundSync()
            
            self.logger.debug("✅ Safely queued interaction: \(interaction.interactionType.rawValue)")
        }
    }
    
    /// Safely record tone analysis without blocking keyboard
    func recordToneAnalysis(text: String, tone: ToneStatus, confidence: Double, analysisTime: TimeInterval) {
        dataQueue.async { [weak self] in
            guard let self = self else { return }
            
            let toneData: [String: Any] = [
                "id": UUID().uuidString,
                "timestamp": Date().timeIntervalSince1970,
                "text_length": text.count,  // Don't store actual text for privacy
                "text_hash": text.hash,     // Store hash for deduplication
                "tone": tone.rawValue,
                "confidence": confidence,
                "analysis_time": analysisTime,
                "source": "keyboard_extension"
            ]
            
            self.toneQueue.append(toneData)
            
            if self.toneQueue.count > self.maxQueueSize {
                self.toneQueue.removeFirst()
            }
            
            self.tryBackgroundSync()
            
            self.logger.debug("✅ Safely queued tone analysis: \(tone.rawValue)")
        }
    }
    
    /// Safely record suggestion interaction
    func recordSuggestionInteraction(suggestion: String, accepted: Bool, context: String) {
        dataQueue.async { [weak self] in
            guard let self = self else { return }
            
            let suggestionData: [String: Any] = [
                "id": UUID().uuidString,
                "timestamp": Date().timeIntervalSince1970,
                "suggestion_length": suggestion.count,
                "accepted": accepted,
                "context": context,
                "source": "keyboard_extension"
            ]
            
            self.suggestionQueue.append(suggestionData)
            
            if self.suggestionQueue.count > self.maxQueueSize {
                self.suggestionQueue.removeFirst()
            }
            
            self.tryBackgroundSync()
            
            self.logger.debug("✅ Safely queued suggestion: accepted=\(accepted)")
        }
    }
    
    /// Safely record general analytics data
    func recordAnalytics(event: String, data: [String: Any]) {
        dataQueue.async { [weak self] in
            guard let self = self else { return }
            
            var analyticsData = data
            analyticsData["id"] = UUID().uuidString
            analyticsData["timestamp"] = Date().timeIntervalSince1970
            analyticsData["event"] = event
            analyticsData["source"] = "keyboard_extension"
            
            self.analyticsQueue.append(analyticsData)
            
            if self.analyticsQueue.count > self.maxQueueSize {
                self.analyticsQueue.removeFirst()
            }
            
            self.tryBackgroundSync()
            
            self.logger.debug("✅ Safely queued analytics: \(event)")
        }
    }
    
    // MARK: - Background Sync (Non-Blocking)
    
    /// Try to sync data to shared storage without blocking keyboard
    private func tryBackgroundSync() {
        guard !isProcessing else { return }
        guard hasQueuedData() else { return }
        
        dataQueue.async { [weak self] in
            guard let self = self else { return }
            guard !self.isProcessing else { return } // Double-check after async dispatch
            
            self.isProcessing = true
            
            // Use lowest priority to not interfere with keyboard
            DispatchQueue.global(qos: .background).async { [weak self] in
                defer {
                    self?.dataQueue.async {
                        self?.isProcessing = false
                    }
                }
                
                guard let self = self else { return }
                
                do {
                    try self.performSafeSync()
                    self.logger.debug("🔄 Background sync completed successfully")
                } catch {
                    self.logger.error("⚠️ Background sync failed: \(error.localizedDescription)")
                    // Don't retry immediately to avoid performance impact
                }
            }
        }
    }
    
    /// Perform actual sync to shared storage
    private func performSafeSync() throws {
        guard let sharedDefaults = safeUserDefaults else {
            throw SafeStorageError.sharedDefaultsUnavailable
        }
        
        // Create snapshots of current queues to avoid race conditions
        let interactionsSnapshot = self.interactionQueue
        let analyticsSnapshot = self.analyticsQueue
        let toneSnapshot = self.toneQueue
        let suggestionsSnapshot = self.suggestionQueue
        
        // Sync each queue separately with size limits
        try syncQueue("interactions", queue: interactionsSnapshot, to: sharedDefaults, key: StorageKeys.pendingInteractions)
        try syncQueue("analytics", queue: analyticsSnapshot, to: sharedDefaults, key: StorageKeys.pendingAnalytics)
        try syncQueue("tone", queue: toneSnapshot, to: sharedDefaults, key: StorageKeys.pendingToneData)
        try syncQueue("suggestions", queue: suggestionsSnapshot, to: sharedDefaults, key: StorageKeys.pendingSuggestions)
        
        // Update sync metadata
        let metadata: [String: Any] = [
            "last_sync": Date().timeIntervalSince1970,
            "interactions_count": interactionsSnapshot.count,
            "analytics_count": analyticsSnapshot.count,
            "tone_count": toneSnapshot.count,
            "suggestions_count": suggestionsSnapshot.count,
            "keyboard_version": "2.0.0",
            "sync_source": "keyboard_extension"
        ]
        
        sharedDefaults.set(metadata, forKey: StorageKeys.storageMetadata)
        
        // Clear queues after successful sync (back on dataQueue)
        dataQueue.async { [weak self] in
            self?.clearQueues()
        }
    }
    
    /// Sync a specific queue to shared storage
    private func syncQueue(_ name: String, queue: [[String: Any]], to defaults: UserDefaults, key: String) throws {
        guard !queue.isEmpty else { return }
        
        // Validate data before storing
        let validatedQueue = queue.compactMap { item -> [String: Any]? in
            // Ensure all required keys are present and valid
            guard item["id"] != nil,
                  item["timestamp"] != nil else {
                return nil
            }
            return item
        }
        
        guard !validatedQueue.isEmpty else {
            logger.warning("⚠️ No valid items to sync for \(name)")
            return
        }
        
        // Get existing data
        var existingData = defaults.array(forKey: key) as? [[String: Any]] ?? []
        
        // Append new data
        existingData.append(contentsOf: validatedQueue)
        
        // Limit total stored data to prevent app crashes
        if existingData.count > maxQueueSize * 2 {
            existingData = Array(existingData.suffix(maxQueueSize * 2))
            logger.warning("⚠️ Truncated \(name) data to prevent memory issues")
        }
        
        // Store safely with error handling
        do {
            defaults.set(existingData, forKey: key)
            defaults.synchronize() // Force write to disk
            logger.debug("📦 Synced \(validatedQueue.count) \(name) items")
        } catch {
            throw SafeStorageError.syncFailed("Failed to store \(name): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Queue Management
    
    private func hasQueuedData() -> Bool {
        return !interactionQueue.isEmpty || 
               !analyticsQueue.isEmpty || 
               !toneQueue.isEmpty || 
               !suggestionQueue.isEmpty
    }
    
    private func clearQueues() {
        interactionQueue.removeAll()
        analyticsQueue.removeAll()
        toneQueue.removeAll()
        suggestionQueue.removeAll()
    }
    
    // MARK: - Safe Data Conversion
    
    /// Convert KeyboardInteraction to safe dictionary (no large strings)
    private func safeInteractionDictionary(from interaction: KeyboardInteraction) -> [String: Any] {
        return [
            "id": UUID().uuidString,
            "timestamp": interaction.timestamp.timeIntervalSince1970,
            "text_before_length": interaction.textBefore.count,
            "text_after_length": interaction.textAfter.count,
            "tone_status": interaction.toneStatus.rawValue,
            "suggestion_accepted": interaction.suggestionAccepted,
            "user_accepted_suggestion": interaction.userAcceptedSuggestion,
            "suggestion_length": interaction.suggestionText?.count ?? 0,
            "analysis_time": interaction.analysisTime,
            "context": interaction.context,
            "interaction_type": interaction.interactionType.rawValue,
            "communication_pattern": interaction.communicationPattern.rawValue,
            "attachment_style": interaction.attachmentStyleDetected.rawValue,
            "relationship_context": interaction.relationshipContext.rawValue,
            "sentiment_score": interaction.sentimentScore,
            "word_count": interaction.wordCount,
            "app_context": interaction.appContext
        ]
    }
    
    // MARK: - Public API for Main App Data Retrieval
    
    /// Get all pending data for main app consumption (call from main app only)
    func getAllPendingData() -> [String: [[String: Any]]] {
        guard let sharedDefaults = safeUserDefaults else {
            logger.error("❌ Shared defaults unavailable for data retrieval")
            return [:]
        }
        
        let interactions = sharedDefaults.array(forKey: StorageKeys.pendingInteractions) as? [[String: Any]] ?? []
        let analytics = sharedDefaults.array(forKey: StorageKeys.pendingAnalytics) as? [[String: Any]] ?? []
        let toneData = sharedDefaults.array(forKey: StorageKeys.pendingToneData) as? [[String: Any]] ?? []
        let suggestions = sharedDefaults.array(forKey: StorageKeys.pendingSuggestions) as? [[String: Any]] ?? []
        
        logger.info("📥 Retrieved pending data - Interactions: \(interactions.count), Analytics: \(analytics.count), Tone: \(toneData.count), Suggestions: \(suggestions.count)")
        
        return [
            "interactions": interactions,
            "analytics": analytics,
            "tone_data": toneData,
            "suggestions": suggestions
        ]
    }
    
    /// Clear all pending data after main app has processed it
    func clearAllPendingData() {
        guard let sharedDefaults = safeUserDefaults else {
            logger.error("❌ Shared defaults unavailable for clearing data")
            return
        }
        
        // Clear data atomically
        sharedDefaults.removeObject(forKey: StorageKeys.pendingInteractions)
        sharedDefaults.removeObject(forKey: StorageKeys.pendingAnalytics)
        sharedDefaults.removeObject(forKey: StorageKeys.pendingToneData)
        sharedDefaults.removeObject(forKey: StorageKeys.pendingSuggestions)
        
        // Update metadata
        let metadata: [String: Any] = [
            "last_clear": Date().timeIntervalSince1970,
            "cleared_by": "main_app",
            "clear_timestamp": Date().description
        ]
        
        sharedDefaults.set(metadata, forKey: StorageKeys.storageMetadata)
        sharedDefaults.synchronize() // Force write to disk
        
        logger.info("🗑️ Cleared all pending data")
    }
    
    /// Get storage metadata
    func getStorageMetadata() -> [String: Any] {
        guard let sharedDefaults = safeUserDefaults else {
            logger.error("❌ Shared defaults unavailable for metadata retrieval")
            return [:]
        }
        return sharedDefaults.dictionary(forKey: StorageKeys.storageMetadata) ?? [:]
    }
    
    /// Get current queue sizes (for debugging/monitoring)
    func getCurrentQueueSizes() -> [String: Int] {
        var sizes: [String: Int] = [:]
        dataQueue.sync {
            sizes = [
                "interactions": self.interactionQueue.count,
                "analytics": self.analyticsQueue.count,
                "tone": self.toneQueue.count,
                "suggestions": self.suggestionQueue.count,
                "total": self.interactionQueue.count + self.analyticsQueue.count + self.toneQueue.count + self.suggestionQueue.count
            ]
        }
        return sizes
    }
}

// MARK: - Errors

enum SafeStorageError: Error {
    case sharedDefaultsUnavailable
    case queueFull
    case syncFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .sharedDefaultsUnavailable:
            return "Shared UserDefaults not available"
        case .queueFull:
            return "Storage queue is full"
        case .syncFailed(let reason):
            return "Sync failed: \(reason)"
        }
    }
}
