//
//  PersonalityDataManager.swift
//  Unsaid
//
//  Manages personality test data sharing between main app and keyboard extension
//
//  Created by John Gray on 7/11/25.
//

import Foundation
import NaturalLanguage
import UIKit

/// Manages personality test data and communication preferences
/// Bridges data between main app and keyboard extension via shared UserDefaults
class PersonalityDataManager {
    
    // MARK: - Properties
    
    /// App group identifier for sharing data with keyboard extension
    private let appGroupIdentifier = "group.com.unsaid.shared"
    
    /// Shared UserDefaults container for app group communication
    private let sharedUserDefaults: UserDefaults?
    
    /// Fallback to standard UserDefaults if shared container is not available
    private var userDefaults: UserDefaults {
        return sharedUserDefaults ?? UserDefaults.standard
    }
    
    /// Shared instance for easy access
    static let shared = PersonalityDataManager()
    
    // MARK: - Keys
    
    private struct Keys {
        static let personalityTestResults = "personality_test_results"
        static let attachmentStyle = "attachment_style"
        static let communicationStyle = "communication_style"
        static let dominantPersonalityType = "dominant_personality_type"
        static let personalityTypeLabel = "personality_type_label"
        static let communicationPreferences = "communication_preferences"
        static let personalityScores = "personality_scores"
        static let isPersonalityTestComplete = "is_personality_test_complete"
        static let lastPersonalityUpdate = "last_personality_update"
        static let partnerAttachmentStyle = "partner_attachment_style"
        static let relationshipContext = "relationship_context"
        static let suggestionUsage = "suggestion_usage"
        
        // Emotional State Keys (for bucket system)
        static let currentEmotionalState = "currentEmotionalState"
        static let currentEmotionalStateBucket = "currentEmotionalStateBucket"
        static let emotionalStateLabel = "emotionalStateLabel"
        static let emotionalStateTimestamp = "emotionalStateTimestamp"
    }
    
    // MARK: - Initialization
    
    private init() {
        // Initialize shared UserDefaults with app group
        self.sharedUserDefaults = UserDefaults(suiteName: appGroupIdentifier)
        
        if sharedUserDefaults == nil {
            print("⚠️ PersonalityDataManager: Failed to initialize app group UserDefaults. Using standard UserDefaults as fallback.")
        } else {
            print("✅ PersonalityDataManager: Initialized with app group: \(appGroupIdentifier)")
        }
    }
    
    // MARK: - Store Personality Data
    
    /// Store complete personality test results
    /// - Parameter results: Dictionary containing personality test results from Flutter
    func storePersonalityTestResults(_ results: [String: Any]) {
        userDefaults.set(results, forKey: Keys.personalityTestResults)
        userDefaults.set(Date(), forKey: Keys.lastPersonalityUpdate)
        userDefaults.set(true, forKey: Keys.isPersonalityTestComplete)
        
        // Extract and store individual components for easy access
        if let counts = results["counts"] as? [String: Int] {
            userDefaults.set(counts, forKey: Keys.personalityScores)
            
            // Find dominant personality type
            let dominantType = counts.max { $0.value < $1.value }?.key ?? "Unknown"
            userDefaults.set(dominantType, forKey: Keys.dominantPersonalityType)
        }
        
        if let typeLabel = results["dominant_type_label"] as? String {
            userDefaults.set(typeLabel, forKey: Keys.personalityTypeLabel)
        }
        
        if let attachmentStyle = results["attachment_style"] as? String {
            userDefaults.set(attachmentStyle, forKey: Keys.attachmentStyle)
        }
        
        if let communicationStyle = results["communication_style"] as? String {
            userDefaults.set(communicationStyle, forKey: Keys.communicationStyle)
        }
        
        if let preferences = results["communication_preferences"] as? [String: Any] {
            userDefaults.set(preferences, forKey: Keys.communicationPreferences)
        }
        
        // Synchronize to ensure data is immediately available
        userDefaults.synchronize()
        
        // ✅ NEW: Sync data to keyboard extension via shared bridge
        syncToKeyboardExtension(results)
        
        print("✅ PersonalityDataManager: Stored personality test results and synced to keyboard extension")
    }
    
    /// Store individual personality components
    /// - Parameters:
    ///   - attachmentStyle: User's attachment style (e.g., "secure", "anxious", "avoidant")
    ///   - communicationStyle: User's communication style (e.g., "direct", "supportive", "analytical")
    ///   - personalityType: Dominant personality type
    ///   - preferences: Communication preferences dictionary
    func storePersonalityComponents(
        attachmentStyle: String? = nil,
        communicationStyle: String? = nil,
        personalityType: String? = nil,
        preferences: [String: Any]? = nil
    ) {
        if let attachmentStyle = attachmentStyle {
            userDefaults.set(attachmentStyle, forKey: Keys.attachmentStyle)
        }
        
        if let communicationStyle = communicationStyle {
            userDefaults.set(communicationStyle, forKey: Keys.communicationStyle)
        }
        
        if let personalityType = personalityType {
            userDefaults.set(personalityType, forKey: Keys.dominantPersonalityType)
        }
        
        if let preferences = preferences {
            userDefaults.set(preferences, forKey: Keys.communicationPreferences)
        }
        
        userDefaults.set(Date(), forKey: Keys.lastPersonalityUpdate)
        userDefaults.synchronize()
        
        // ✅ NEW: Sync updated components to keyboard extension
        syncComponentsToKeyboardExtension()
        
        print("✅ PersonalityDataManager: Updated personality components and synced to keyboard extension")
    }
    
    // MARK: - Retrieve Personality Data
    
    /// Get complete personality test results
    /// - Returns: Dictionary containing all personality test results, or nil if not available
    func getPersonalityTestResults() -> [String: Any]? {
        return userDefaults.dictionary(forKey: Keys.personalityTestResults)
    }
    
    /// Get user's attachment style
    /// - Returns: Attachment style string, or nil if not set
    func getAttachmentStyle() -> String? {
        return userDefaults.string(forKey: Keys.attachmentStyle)
    }
    
    /// Get user's communication style
    /// - Returns: Communication style string, or nil if not set
    func getCommunicationStyle() -> String? {
        return userDefaults.string(forKey: Keys.communicationStyle)
    }
    
    /// Get dominant personality type
    /// - Returns: Personality type string, or nil if not set
    func getDominantPersonalityType() -> String? {
        return userDefaults.string(forKey: Keys.dominantPersonalityType)
    }
    
    /// Get personality type label
    /// - Returns: Human-readable personality type label, or nil if not set
    func getPersonalityTypeLabel() -> String? {
        return userDefaults.string(forKey: Keys.personalityTypeLabel)
    }
    
    /// Get communication preferences
    /// - Returns: Dictionary of communication preferences, or nil if not set
    func getCommunicationPreferences() -> [String: Any]? {
        return userDefaults.dictionary(forKey: Keys.communicationPreferences)
    }
    
    /// Get personality scores
    /// - Returns: Dictionary of personality type scores, or nil if not set
    func getPersonalityScores() -> [String: Int]? {
        return userDefaults.dictionary(forKey: Keys.personalityScores) as? [String: Int]
    }
    
    /// Check if personality test is complete
    /// - Returns: Boolean indicating if personality test has been completed
    func isPersonalityTestComplete() -> Bool {
        return userDefaults.bool(forKey: Keys.isPersonalityTestComplete)
    }
    
    /// Get last personality data update time
    /// - Returns: Date of last update, or nil if never updated
    func getLastPersonalityUpdate() -> Date? {
        return userDefaults.object(forKey: Keys.lastPersonalityUpdate) as? Date
    }
    
    /// Get partner's attachment style
    /// - Returns: Partner's attachment style string, or nil if not set
    func getPartnerAttachmentStyle() -> String? {
        return userDefaults.string(forKey: Keys.partnerAttachmentStyle)
    }
    
    /// Set partner's attachment style
    /// - Parameter style: Partner's attachment style
    func setPartnerAttachmentStyle(_ style: String) {
        userDefaults.set(style, forKey: Keys.partnerAttachmentStyle)
        userDefaults.set(Date(), forKey: Keys.lastPersonalityUpdate)
        userDefaults.synchronize()
        
        // ✅ NEW: Sync relationship data to keyboard extension
        syncRelationshipDataToKeyboardExtension()
    }
    
    /// Get relationship context
    /// - Returns: Relationship context string, or nil if not set
    func getRelationshipContext() -> String? {
        return userDefaults.string(forKey: Keys.relationshipContext)
    }
    
    /// Set relationship context
    /// - Parameter context: Relationship context
    func setRelationshipContext(_ context: String) {
        userDefaults.set(context, forKey: Keys.relationshipContext)
        userDefaults.set(Date(), forKey: Keys.lastPersonalityUpdate)
        userDefaults.synchronize()
        
        // ✅ NEW: Sync relationship data to keyboard extension
        syncRelationshipDataToKeyboardExtension()
    }
    
    /// Get suggestion usage data
    /// - Returns: Array of suggestion usage dictionaries, or empty array if not set
    func getSuggestionUsage() -> [[String: Any]] {
        return userDefaults.array(forKey: Keys.suggestionUsage) as? [[String: Any]] ?? []
    }
    
    /// Set suggestion usage data
    /// - Parameter usage: Array of suggestion usage dictionaries
    func setSuggestionUsage(_ usage: [[String: Any]]) {
        userDefaults.set(usage, forKey: Keys.suggestionUsage)
        userDefaults.synchronize()
    }
    
    /// Add suggestion usage entry
    /// - Parameter usage: Single suggestion usage dictionary
    func addSuggestionUsage(_ usage: [String: Any]) {
        var currentUsage = getSuggestionUsage()
        currentUsage.append(usage)
        setSuggestionUsage(currentUsage)
    }

    // MARK: - Data Synchronization
    
    /// Sync personality data from main app to keyboard extension
    /// This method reads data written by the main app and stores it in the extension format
    func syncFromMainApp() {
        print(" PersonalityDataManager: Syncing data from main app...")
        
        // Try to read data in the new extension format first
        if let personalityData = userDefaults.dictionary(forKey: "personality_data") {
            print(" Found personality data in extension format")
            
            // Extract data from the extension format
            if let attachmentStyle = personalityData["attachment_style"] as? String {
                userDefaults.set(attachmentStyle, forKey: Keys.attachmentStyle)
            }
            
            if let communicationStyle = personalityData["communication_style"] as? String {
                userDefaults.set(communicationStyle, forKey: Keys.communicationStyle)
            }
            
            if let personalityType = personalityData["personality_type"] as? String {
                userDefaults.set(personalityType, forKey: Keys.dominantPersonalityType)
            }
            
            if let dominantTypeLabel = personalityData["dominant_type_label"] as? String {
                userDefaults.set(dominantTypeLabel, forKey: Keys.personalityTypeLabel)
            }
            
            if let testResults = personalityData["test_results"] as? [String: Any] {
                userDefaults.set(testResults, forKey: Keys.personalityTestResults)
            }
            
            userDefaults.set(true, forKey: Keys.isPersonalityTestComplete)
            userDefaults.set(Date(), forKey: Keys.lastPersonalityUpdate)
            
        } else {
            print("ℹ No extension format data found, trying legacy format...")
            
            // Fall back to legacy format
            if let attachmentStyle = userDefaults.string(forKey: "user_attachment_style") {
                userDefaults.set(attachmentStyle, forKey: Keys.attachmentStyle)
                print(" Synced attachment style from legacy format: \(attachmentStyle)")
            }
            
            if let communicationStyle = userDefaults.string(forKey: "user_communication_style") {
                userDefaults.set(communicationStyle, forKey: Keys.communicationStyle)
                print(" Synced communication style from legacy format: \(communicationStyle)")
            }
            
            if let personalityType = userDefaults.string(forKey: "user_personality_type") {
                userDefaults.set(personalityType, forKey: Keys.dominantPersonalityType)
                print(" Synced personality type from legacy format: \(personalityType)")
            }
            
            if let testResults = userDefaults.dictionary(forKey: "personality_test_results") {
                userDefaults.set(testResults, forKey: Keys.personalityTestResults)
                print(" Synced test results from legacy format")
            }
            
            // Set completion status if we found any data
            let hasData = userDefaults.string(forKey: Keys.attachmentStyle) != nil ||
                         userDefaults.string(forKey: Keys.communicationStyle) != nil ||
                         userDefaults.string(forKey: Keys.dominantPersonalityType) != nil
            
            if hasData {
                userDefaults.set(true, forKey: Keys.isPersonalityTestComplete)
                userDefaults.set(Date(), forKey: Keys.lastPersonalityUpdate)
            }
        }
        
        userDefaults.synchronize()
        
        // Debug: Print what we have after sync
        print(" Post-sync data:")
        print("   - Attachment style: \(getAttachmentStyle() ?? "nil")")
        print("   - Communication style: \(getCommunicationStyle() ?? "nil")")
        print("   - Personality type: \(getDominantPersonalityType() ?? "nil")")
        print("   - Test complete: \(isPersonalityTestComplete())")
    }

    // MARK: - AI Context Generation
    
    /// Generate personality context for AI suggestions
    /// - Returns: Formatted string containing personality context for AI prompts
    func generatePersonalityContext() -> String {
        var context = ""
        
        if let attachmentStyle = getAttachmentStyle() {
            context += "Attachment Style: \(attachmentStyle)\n"
        }
        
        if let communicationStyle = getCommunicationStyle() {
            context += "Communication Style: \(communicationStyle)\n"
        }
        
        if let personalityType = getDominantPersonalityType() {
            context += "Personality Type: \(personalityType)\n"
        }
        
        if let preferences = getCommunicationPreferences() {
            context += "Communication Preferences: \(preferences)\n"
        }
        
        if let scores = getPersonalityScores() {
            context += "Personality Scores: \(scores)\n"
        }
        
        return context.isEmpty ? "No personality data available" : context
    }
    
    /// Generate personality context dictionary for AI services
    /// - Returns: Dictionary containing personality data for AI context
    func generatePersonalityContextDictionary() -> [String: Any] {
        var context: [String: Any] = [:]
        
        if let attachmentStyle = getAttachmentStyle() {
            context["attachment_style"] = attachmentStyle
        }
        
        if let communicationStyle = getCommunicationStyle() {
            context["communication_style"] = communicationStyle
        }
        
        if let personalityType = getDominantPersonalityType() {
            context["personality_type"] = personalityType
        }
        
        if let preferences = getCommunicationPreferences() {
            context["communication_preferences"] = preferences
        }
        
        if let scores = getPersonalityScores() {
            context["personality_scores"] = scores
        }
        
        context["is_complete"] = isPersonalityTestComplete()
        
        if let lastUpdate = getLastPersonalityUpdate() {
            context["last_update"] = lastUpdate.timeIntervalSince1970
        }
        
        return context
    }
    
    // MARK: - Utility Methods
    
    /// Clear all personality data
    func clearPersonalityData() {
        userDefaults.removeObject(forKey: Keys.personalityTestResults)
        userDefaults.removeObject(forKey: Keys.attachmentStyle)
        userDefaults.removeObject(forKey: Keys.communicationStyle)
        userDefaults.removeObject(forKey: Keys.dominantPersonalityType)
        userDefaults.removeObject(forKey: Keys.personalityTypeLabel)
        userDefaults.removeObject(forKey: Keys.communicationPreferences)
        userDefaults.removeObject(forKey: Keys.personalityScores)
        userDefaults.removeObject(forKey: Keys.isPersonalityTestComplete)
        userDefaults.removeObject(forKey: Keys.lastPersonalityUpdate)
        userDefaults.removeObject(forKey: Keys.partnerAttachmentStyle)
        userDefaults.removeObject(forKey: Keys.relationshipContext)
        userDefaults.removeObject(forKey: Keys.suggestionUsage)
        userDefaults.synchronize()
        
        print(" PersonalityDataManager: Cleared all personality data")
    }
    
    /// Debug: Print all stored personality data
    func debugPrintPersonalityData() {
        print("=== PersonalityDataManager Debug ===")
        print("Test Complete: \(isPersonalityTestComplete())")
        print("Attachment Style: \(getAttachmentStyle() ?? "nil")")
        print("Communication Style: \(getCommunicationStyle() ?? "nil")")
        print("Personality Type: \(getDominantPersonalityType() ?? "nil")")
        print("Type Label: \(getPersonalityTypeLabel() ?? "nil")")
        print("Partner Attachment Style: \(getPartnerAttachmentStyle() ?? "nil")")
        print("Relationship Context: \(getRelationshipContext() ?? "nil")")
        print("Last Update: \(getLastPersonalityUpdate()?.description ?? "nil")")
        print("Suggestion Usage Count: \(getSuggestionUsage().count)")
        
        if let scores = getPersonalityScores() {
            print("Scores: \(scores)")
        }
        
        if let preferences = getCommunicationPreferences() {
            print("Preferences: \(preferences)")
        }
        
        if let fullResults = getPersonalityTestResults() {
            print("Full Results Keys: \(fullResults.keys)")
        }
        print("===============================")
    }
    
    /// Test method: Set sample personality data for testing
    func setTestPersonalityData() {
        let testData: [String: Any] = [
            "attachment_style": "secure",
            "communication_style": "direct",
            "dominant_type": "Supportive",
            "dominant_type_label": "The Supportive Partner",
            "counts": [
                "supportive": 8,
                "analytical": 5,
                "emotional": 6,
                "direct": 7
            ],
            "communication_preferences": [
                "prefers_direct_communication": true,
                "values_emotional_expression": true,
                "needs_reassurance": false
            ]
        ]
        
        storePersonalityTestResults(testData)
        print(" 🧪 PersonalityDataManager: Test data set - attachment style: secure")
    }
}

// MARK: - Extension for Flutter Integration

extension PersonalityDataManager {
    
    /// Store personality data from Flutter via method channel
    /// - Parameter data: Dictionary containing personality data from Flutter
    func storePersonalityDataFromFlutter(_ data: [String: Any]) {
        // Handle the data format that comes from Flutter
        storePersonalityTestResults(data)
    }
    
    /// Get personality data for Flutter via method channel
    /// - Returns: Dictionary formatted for Flutter consumption
    func getPersonalityDataForFlutter() -> [String: Any] {
        return generatePersonalityContextDictionary()
    }
    
    // MARK: - Emotional State Management (for AI Bucket System)
    
    /// Store user's current emotional state from splash screen selection
    /// - Parameters:
    ///   - state: The emotional state ID (e.g., "completely_overwhelmed")
    ///   - bucket: The bucket category ("highIntensity", "moderate", "regulated")
    ///   - label: Human-readable label (e.g., "Completely overwhelmed")
    func setUserEmotionalState(state: String, bucket: String, label: String) {
        userDefaults.set(state, forKey: Keys.currentEmotionalState)
        userDefaults.set(bucket, forKey: Keys.currentEmotionalStateBucket)
        userDefaults.set(label, forKey: Keys.emotionalStateLabel)
        userDefaults.set(Date().timeIntervalSince1970, forKey: Keys.emotionalStateTimestamp)
        userDefaults.synchronize()
        
        // ✅ NEW: Sync emotional state to keyboard extension
        syncEmotionalStateToKeyboardExtension(state: state, bucket: bucket, label: label)
        
        print("✅ PersonalityDataManager: Stored emotional state - \(label) (\(bucket) bucket) and synced to keyboard extension")
    }
    
    /// Get user's current emotional state ID
    /// - Returns: The emotional state ID or "neutral" as fallback
    func getUserEmotionalState() -> String {
        return userDefaults.string(forKey: Keys.currentEmotionalState) ?? "neutral_distracted"
    }
    
    /// Get user's current emotional bucket for AI processing
    /// - Returns: The bucket category ("highIntensity", "moderate", "regulated")
    func getUserEmotionalBucket() -> String {
        return userDefaults.string(forKey: Keys.currentEmotionalStateBucket) ?? "moderate"
    }
    
    /// Get user's emotional state label for display
    /// - Returns: Human-readable emotional state label
    func getUserEmotionalStateLabel() -> String {
        return userDefaults.string(forKey: Keys.emotionalStateLabel) ?? "Neutral / distracted"
    }
    
    /// Get timestamp of when emotional state was last set
    /// - Returns: Time interval since 1970, or 0 if never set
    func getEmotionalStateTimestamp() -> TimeInterval {
        return userDefaults.double(forKey: Keys.emotionalStateTimestamp)
    }
    
    /// Check if emotional state data is fresh (within 24 hours)
    /// - Returns: True if emotional state was set within last 24 hours
    func isEmotionalStateFresh() -> Bool {
        let timestamp = getEmotionalStateTimestamp()
        let now = Date().timeIntervalSince1970
        let twentyFourHours: TimeInterval = 24 * 60 * 60
        
        return (now - timestamp) < twentyFourHours
    }
    
    // MARK: - Keyboard Extension Bridge Integration
    
    /// Sync complete personality data to keyboard extension via shared UserDefaults
    /// - Parameter personalityData: Complete personality test results
    private func syncToKeyboardExtension(_ personalityData: [String: Any]) {
        guard let sharedDefaults = sharedUserDefaults else {
            print("⚠️ PersonalityDataManager: Cannot sync to keyboard extension - app group not available")
            return
        }
        
        // Create bridge-compatible data structure
        var bridgeData: [String: Any] = personalityData
        
        // Ensure all required keys are present
        if let attachmentStyle = getAttachmentStyle() {
            bridgeData["attachment_style"] = attachmentStyle
        }
        
        if let communicationStyle = getCommunicationStyle() {
            bridgeData["communication_style"] = communicationStyle
        }
        
        if let personalityType = getDominantPersonalityType() {
            bridgeData["personality_type"] = personalityType
        }
        
        if let scores = getPersonalityScores() {
            bridgeData["personality_scores"] = scores
            bridgeData["counts"] = scores // for compatibility
        }
        
        if let preferences = getCommunicationPreferences() {
            bridgeData["communication_preferences"] = preferences
        }
        
        // Store data in bridge format
        sharedDefaults.set(bridgeData, forKey: "personality_data_v2")
        sharedDefaults.set(getAttachmentStyle(), forKey: "attachment_style")
        sharedDefaults.set(getCommunicationStyle(), forKey: "communication_style")
        sharedDefaults.set(getDominantPersonalityType(), forKey: "personality_type")
        sharedDefaults.set(getPersonalityScores(), forKey: "personality_scores")
        sharedDefaults.set(getCommunicationPreferences(), forKey: "communication_preferences")
        
        // Set metadata
        sharedDefaults.set(Date(), forKey: "personality_last_update")
        sharedDefaults.set(true, forKey: "personality_test_complete")
        sharedDefaults.set("v2.0", forKey: "personality_data_version")
        sharedDefaults.set("pending", forKey: "personality_sync_status")
        
        sharedDefaults.synchronize()
        
        print("✅ Synced personality data to keyboard extension via app group")
    }
    
    /// Sync individual personality components to keyboard extension
    private func syncComponentsToKeyboardExtension() {
        guard let sharedDefaults = sharedUserDefaults else { return }
        
        // Update individual components
        if let attachmentStyle = getAttachmentStyle() {
            sharedDefaults.set(attachmentStyle, forKey: "attachment_style")
        }
        
        if let communicationStyle = getCommunicationStyle() {
            sharedDefaults.set(communicationStyle, forKey: "communication_style")
        }
        
        if let personalityType = getDominantPersonalityType() {
            sharedDefaults.set(personalityType, forKey: "personality_type")
        }
        
        sharedDefaults.set(Date(), forKey: "personality_last_update")
        sharedDefaults.set("pending", forKey: "personality_sync_status")
        sharedDefaults.synchronize()
        
        print("✅ Synced personality components to keyboard extension")
    }
    
    /// Sync emotional state data to keyboard extension
    /// - Parameters:
    ///   - state: Emotional state ID
    ///   - bucket: Emotional bucket category
    ///   - label: Human-readable label
    private func syncEmotionalStateToKeyboardExtension(state: String, bucket: String, label: String) {
        guard let sharedDefaults = sharedUserDefaults else { return }
        
        sharedDefaults.set(state, forKey: "currentEmotionalState")
        sharedDefaults.set(bucket, forKey: "currentEmotionalStateBucket")
        sharedDefaults.set(label, forKey: "emotionalStateLabel")
        sharedDefaults.set(Date().timeIntervalSince1970, forKey: "emotionalStateTimestamp")
        sharedDefaults.set(Date(), forKey: "personality_last_update")
        sharedDefaults.set("pending", forKey: "personality_sync_status")
        
        sharedDefaults.synchronize()
        
        print("✅ Synced emotional state to keyboard extension")
    }
    
    /// Sync relationship data to keyboard extension
    private func syncRelationshipDataToKeyboardExtension() {
        guard let sharedDefaults = sharedUserDefaults else { return }
        
        if let partnerStyle = getPartnerAttachmentStyle() {
            sharedDefaults.set(partnerStyle, forKey: "partner_attachment_style")
        }
        
        if let context = getRelationshipContext() {
            sharedDefaults.set(context, forKey: "relationship_context")
        }
        
        sharedDefaults.set(Date(), forKey: "personality_last_update")
        sharedDefaults.set("pending", forKey: "personality_sync_status")
        sharedDefaults.synchronize()
        
        print("✅ Synced relationship data to keyboard extension")
    }
    
    /// Force a complete sync of all personality data to keyboard extension
    func forceSyncToKeyboardExtension() {
        guard let personalityData = getPersonalityTestResults() else {
            print("⚠️ No personality data to sync")
            return
        }
        
        syncToKeyboardExtension(personalityData)
        
        // Also sync emotional state if available
        let emotionalState = getUserEmotionalState()
        let emotionalBucket = getUserEmotionalBucket()
        let emotionalLabel = getUserEmotionalStateLabel()
        
        if emotionalState != "neutral_distracted" { // Not default value
            syncEmotionalStateToKeyboardExtension(
                state: emotionalState,
                bucket: emotionalBucket,
                label: emotionalLabel
            )
        }
        
        // Sync relationship data if available
        if getPartnerAttachmentStyle() != nil || getRelationshipContext() != nil {
            syncRelationshipDataToKeyboardExtension()
        }
        
        print("✅ Forced complete sync to keyboard extension")
    }
}
