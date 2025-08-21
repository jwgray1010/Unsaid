//
//  PersonalityDataBridge.swift
//  UnsaidKeyboard
//
//  Bridges personality data between main app and keyboard extension
//  Handles data synchronization and real-time updates
//
//  Created by John Gray on 8/19/25.
//

import Foundation
import os.log

/// Bridge for sharing personality data between main app and keyboard extension
/// Uses app group shared UserDefaults for cross-process communication
class PersonalityDataBridge {
    
    // MARK: - Properties
    
    /// Shared instance for keyboard extension access
    static let shared = PersonalityDataBridge()
    
    /// App group identifier for shared data storage
    private let appGroupIdentifier = "group.com.example.unsaid.shared"
    
    /// Shared UserDefaults container for cross-process communication
    private let sharedDefaults: UserDefaults?
    
    /// Logger for debugging
    private let logger = Logger(subsystem: "com.example.unsaid.keyboard", category: "PersonalityDataBridge")
    
    // MARK: - Data Keys
    
    private struct SharedKeys {
        // Core personality data
        static let personalityData = "personality_data_v2"
        static let attachmentStyle = "attachment_style"
        static let communicationStyle = "communication_style"
        static let personalityType = "personality_type"
        static let dominantTypeLabel = "dominant_type_label"
        static let personalityScores = "personality_scores"
        static let communicationPreferences = "communication_preferences"
        
        // Emotional state data
        static let currentEmotionalState = "currentEmotionalState"
        static let currentEmotionalStateBucket = "currentEmotionalStateBucket"
        static let emotionalStateLabel = "emotionalStateLabel"
        static let emotionalStateTimestamp = "emotionalStateTimestamp"
        
        // Relationship context
        static let partnerAttachmentStyle = "partner_attachment_style"
        static let relationshipContext = "relationship_context"
        
        // Metadata
        static let dataVersion = "personality_data_version"
        static let lastUpdate = "personality_last_update"
        static let isComplete = "personality_test_complete"
        
        // Sync status
        static let syncStatus = "personality_sync_status"
        static let lastSyncTimestamp = "last_sync_timestamp"
    }
    
    // MARK: - Initialization
    
    private init() {
        self.sharedDefaults = UserDefaults(suiteName: appGroupIdentifier)
        
        if sharedDefaults == nil {
            logger.error("Failed to initialize shared UserDefaults with app group: \(self.appGroupIdentifier)")
        } else {
            logger.info("PersonalityDataBridge initialized with app group: \(self.appGroupIdentifier)")
        }
    }
    
    // MARK: - Data Retrieval for Keyboard Extension
    
    /// Get user's attachment style for AI processing
    /// - Returns: Attachment style string or default "secure"
    func getAttachmentStyle() -> String {
        let style = sharedDefaults?.string(forKey: SharedKeys.attachmentStyle) ?? "secure"
        logger.debug("Retrieved attachment style: \(style)")
        return style
    }
    
    /// Get user's communication style
    /// - Returns: Communication style string or default "direct"
    func getCommunicationStyle() -> String {
        let style = sharedDefaults?.string(forKey: SharedKeys.communicationStyle) ?? "direct"
        logger.debug("Retrieved communication style: \(style)")
        return style
    }
    
    /// Get user's personality type
    /// - Returns: Personality type string or default "analytical"
    func getPersonalityType() -> String {
        let type = sharedDefaults?.string(forKey: SharedKeys.personalityType) ?? "analytical"
        logger.debug("Retrieved personality type: \(type)")
        return type
    }
    
    /// Get user's emotional state for AI bucket processing
    /// - Returns: Emotional state string or default "neutral"
    func getCurrentEmotionalState() -> String {
        let state = sharedDefaults?.string(forKey: SharedKeys.currentEmotionalState) ?? "neutral"
        logger.debug("Retrieved emotional state: \(state)")
        return state
    }
    
    /// Get user's emotional bucket for AI intensity processing
    /// - Returns: Emotional bucket string ("highIntensity", "moderate", "regulated")
    func getCurrentEmotionalBucket() -> String {
        let bucket = sharedDefaults?.string(forKey: SharedKeys.currentEmotionalStateBucket) ?? "moderate"
        logger.debug("Retrieved emotional bucket: \(bucket)")
        return bucket
    }
    
    /// Get complete personality profile as dictionary for API calls
    /// - Returns: Dictionary containing all available personality data
    func getPersonalityProfile() -> [String: Any] {
        var profile: [String: Any] = [:]
        
        profile["attachment_style"] = getAttachmentStyle()
        profile["communication_style"] = getCommunicationStyle()
        profile["personality_type"] = getPersonalityType()
        profile["emotional_state"] = getCurrentEmotionalState()
        profile["emotional_bucket"] = getCurrentEmotionalBucket()
        
        // Add additional data if available
        if let scores = sharedDefaults?.dictionary(forKey: SharedKeys.personalityScores) {
            profile["personality_scores"] = scores
        }
        
        if let preferences = sharedDefaults?.dictionary(forKey: SharedKeys.communicationPreferences) {
            profile["communication_preferences"] = preferences
        }
        
        if let partnerStyle = sharedDefaults?.string(forKey: SharedKeys.partnerAttachmentStyle) {
            profile["partner_attachment_style"] = partnerStyle
        }
        
        if let relationshipContext = sharedDefaults?.string(forKey: SharedKeys.relationshipContext) {
            profile["relationship_context"] = relationshipContext
        }
        
        profile["is_complete"] = isPersonalityTestComplete()
        profile["data_freshness"] = getDataFreshness()
        
        logger.debug("Generated personality profile with \(profile.keys.count) components")
        return profile
    }
    
    /// Check if personality test has been completed
    /// - Returns: Boolean indicating completion status
    func isPersonalityTestComplete() -> Bool {
        let complete = sharedDefaults?.bool(forKey: SharedKeys.isComplete) ?? false
        logger.debug("Personality test complete: \(complete)")
        return complete
    }
    
    /// Get data freshness indicator
    /// - Returns: Time since last update in hours, or -1 if never updated
    func getDataFreshness() -> Double {
        guard let lastUpdate = sharedDefaults?.object(forKey: SharedKeys.lastUpdate) as? Date else {
            return -1
        }
        
        let hoursAgo = Date().timeIntervalSince(lastUpdate) / 3600
        logger.debug("Data freshness: \(hoursAgo) hours ago")
        return hoursAgo
    }
    
    // MARK: - Data Storage (for main app integration)
    
    /// Store complete personality data from main app
    /// - Parameter data: Dictionary containing personality test results
    func storePersonalityData(_ data: [String: Any]) {
        guard let sharedDefaults = sharedDefaults else {
            logger.error("Cannot store personality data - shared defaults not available")
            return
        }
        
        // Store core personality data
        if let attachmentStyle = data["attachment_style"] as? String {
            sharedDefaults.set(attachmentStyle, forKey: SharedKeys.attachmentStyle)
        }
        
        if let communicationStyle = data["communication_style"] as? String {
            sharedDefaults.set(communicationStyle, forKey: SharedKeys.communicationStyle)
        }
        
        if let personalityType = data["personality_type"] as? String ?? data["dominant_type"] as? String {
            sharedDefaults.set(personalityType, forKey: SharedKeys.personalityType)
        }
        
        if let typeLabel = data["dominant_type_label"] as? String {
            sharedDefaults.set(typeLabel, forKey: SharedKeys.dominantTypeLabel)
        }
        
        if let scores = data["counts"] as? [String: Int] ?? data["personality_scores"] as? [String: Int] {
            sharedDefaults.set(scores, forKey: SharedKeys.personalityScores)
        }
        
        if let preferences = data["communication_preferences"] as? [String: Any] {
            sharedDefaults.set(preferences, forKey: SharedKeys.communicationPreferences)
        }
        
        // Store complete data structure
        sharedDefaults.set(data, forKey: SharedKeys.personalityData)
        
        // Update metadata
        sharedDefaults.set(Date(), forKey: SharedKeys.lastUpdate)
        sharedDefaults.set(true, forKey: SharedKeys.isComplete)
        sharedDefaults.set("v2.0", forKey: SharedKeys.dataVersion)
        sharedDefaults.set(Date().timeIntervalSince1970, forKey: SharedKeys.lastSyncTimestamp)
        sharedDefaults.set("synced", forKey: SharedKeys.syncStatus)
        
        // Force synchronization
        sharedDefaults.synchronize()
        
        logger.info("Stored complete personality data with \(data.keys.count) keys")
    }
    
    /// Store emotional state data
    /// - Parameters:
    ///   - state: Emotional state ID
    ///   - bucket: Emotional intensity bucket
    ///   - label: Human-readable label
    func storeEmotionalState(state: String, bucket: String, label: String) {
        guard let sharedDefaults = sharedDefaults else {
            logger.error("Cannot store emotional state - shared defaults not available")
            return
        }
        
        sharedDefaults.set(state, forKey: SharedKeys.currentEmotionalState)
        sharedDefaults.set(bucket, forKey: SharedKeys.currentEmotionalStateBucket)
        sharedDefaults.set(label, forKey: SharedKeys.emotionalStateLabel)
        sharedDefaults.set(Date().timeIntervalSince1970, forKey: SharedKeys.emotionalStateTimestamp)
        sharedDefaults.set(Date(), forKey: SharedKeys.lastUpdate)
        
        sharedDefaults.synchronize()
        
        logger.info("Stored emotional state: \(label) (\(bucket) bucket)")
    }
    
    /// Store relationship context data
    /// - Parameters:
    ///   - partnerStyle: Partner's attachment style
    ///   - context: Relationship context
    func storeRelationshipContext(partnerStyle: String? = nil, context: String? = nil) {
        guard let sharedDefaults = sharedDefaults else {
            logger.error("Cannot store relationship context - shared defaults not available")
            return
        }
        
        if let partnerStyle = partnerStyle {
            sharedDefaults.set(partnerStyle, forKey: SharedKeys.partnerAttachmentStyle)
        }
        
        if let context = context {
            sharedDefaults.set(context, forKey: SharedKeys.relationshipContext)
        }
        
        sharedDefaults.set(Date(), forKey: SharedKeys.lastUpdate)
        sharedDefaults.synchronize()
        
        logger.info("Updated relationship context")
    }
    
    // MARK: - Sync Status Management
    
    /// Check if data needs to be synced from main app
    /// - Returns: Boolean indicating if sync is needed
    func needsSync() -> Bool {
        guard let sharedDefaults = sharedDefaults else { return false }
        
        let syncStatus = sharedDefaults.string(forKey: SharedKeys.syncStatus) ?? "never"
        let lastSync = sharedDefaults.double(forKey: SharedKeys.lastSyncTimestamp)
        let now = Date().timeIntervalSince1970
        
        // Sync if never synced or if data is older than 5 minutes
        let needsSync = syncStatus != "synced" || (now - lastSync) > 300
        
        if needsSync {
            logger.debug("Sync needed - status: \(syncStatus), last sync: \(lastSync)")
        }
        
        return needsSync
    }
    
    /// Mark sync as pending (called when main app updates data)
    func markSyncPending() {
        sharedDefaults?.set("pending", forKey: SharedKeys.syncStatus)
        sharedDefaults?.synchronize()
        logger.debug("Marked sync as pending")
    }
    
    /// Mark sync as complete
    func markSyncComplete() {
        sharedDefaults?.set("synced", forKey: SharedKeys.syncStatus)
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: SharedKeys.lastSyncTimestamp)
        sharedDefaults?.synchronize()
        logger.debug("Marked sync as complete")
    }
    
    // MARK: - Utilities
    
    /// Clear all personality data (for testing/reset)
    func clearAllData() {
        guard let sharedDefaults = sharedDefaults else { return }
        
        let allKeys = [
            SharedKeys.personalityData,
            SharedKeys.attachmentStyle,
            SharedKeys.communicationStyle,
            SharedKeys.personalityType,
            SharedKeys.dominantTypeLabel,
            SharedKeys.personalityScores,
            SharedKeys.communicationPreferences,
            SharedKeys.currentEmotionalState,
            SharedKeys.currentEmotionalStateBucket,
            SharedKeys.emotionalStateLabel,
            SharedKeys.emotionalStateTimestamp,
            SharedKeys.partnerAttachmentStyle,
            SharedKeys.relationshipContext,
            SharedKeys.dataVersion,
            SharedKeys.lastUpdate,
            SharedKeys.isComplete,
            SharedKeys.syncStatus,
            SharedKeys.lastSyncTimestamp
        ]
        
        for key in allKeys {
            sharedDefaults.removeObject(forKey: key)
        }
        
        sharedDefaults.synchronize()
        logger.info("Cleared all personality data")
    }
    
    /// Debug: Print all stored data
    func debugPrintData() {
        logger.debug("=== PersonalityDataBridge Debug ===")
        logger.debug("App Group: \(self.appGroupIdentifier)")
        logger.debug("Shared Defaults Available: \(self.sharedDefaults != nil)")
        logger.debug("Attachment Style: \(self.getAttachmentStyle())")
        logger.debug("Communication Style: \(self.getCommunicationStyle())")
        logger.debug("Personality Type: \(self.getPersonalityType())")
        logger.debug("Emotional State: \(self.getCurrentEmotionalState())")
        logger.debug("Emotional Bucket: \(self.getCurrentEmotionalBucket())")
        logger.debug("Test Complete: \(self.isPersonalityTestComplete())")
        logger.debug("Data Freshness: \(self.getDataFreshness()) hours")
        logger.debug("Needs Sync: \(self.needsSync())")
        logger.debug("===============================")
    }
    
    /// Set test data for development/testing
    func setTestData() {
        let testData: [String: Any] = [
            "attachment_style": "secure",
            "communication_style": "direct",
            "personality_type": "analytical",
            "dominant_type_label": "The Analytical Partner",
            "counts": [
                "analytical": 8,
                "supportive": 6,
                "emotional": 4,
                "direct": 7
            ],
            "communication_preferences": [
                "prefers_direct_communication": true,
                "values_logic": true,
                "needs_detailed_explanations": true
            ]
        ]
        
        storePersonalityData(testData)
        storeEmotionalState(state: "neutral_focused", bucket: "moderate", label: "Neutral / focused")
        
        logger.info("🧪 Test personality data set")
    }
}

// MARK: - Integration with ToneSuggestionCoordinator

extension PersonalityDataBridge {
    
    /// Generate payload for API calls (used by ToneSuggestionCoordinator)
    /// - Returns: Dictionary formatted for API consumption
    func generateAPIPayload() -> [String: Any] {
        let profile = getPersonalityProfile()
        
        // Format for ML system compatibility
        var payload: [String: Any] = [:]
        
        payload["attachment_style"] = profile["attachment_style"] ?? "secure"
        payload["communication_style"] = profile["communication_style"] ?? "direct"
        payload["personality_type"] = profile["personality_type"] ?? "analytical"
        payload["emotional_state"] = profile["emotional_state"] ?? "neutral"
        payload["emotional_bucket"] = profile["emotional_bucket"] ?? "moderate"
        
        // Add comprehensive user profile
        payload["user_profile"] = profile
        
        // Add metadata
        payload["personality_data_freshness"] = getDataFreshness()
        payload["personality_complete"] = isPersonalityTestComplete()
        
        return payload
    }
}
