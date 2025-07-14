//
//  PersonalityDataManager.swift
//  Unsaid
//
//  Manages personality test data sharing between main app and keyboard extension
//
//  Created by John Gray on 7/11/25.
//

import Foundation

/// Manages personality test data and communication preferences
/// Bridges data between main app and keyboard extension via shared UserDefaults
class PersonalityDataManager {
    
    // MARK: - Properties
    
    /// Shared UserDefaults container for app group communication
    private let sharedUserDefaults = UserDefaults(suiteName: "group.com.unsaid.keyboard")
    
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
    }
    
    // MARK: - Initialization
    
    private init() {
        // Private initializer for singleton pattern
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
        
        print("✅ PersonalityDataManager: Stored personality test results")
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
        
        print("✅ PersonalityDataManager: Updated personality components")
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
        userDefaults.synchronize()
        
        print("✅ PersonalityDataManager: Cleared all personality data")
    }
    
    /// Debug: Print all stored personality data
    func debugPrintPersonalityData() {
        print("=== PersonalityDataManager Debug ===")
        print("Test Complete: \(isPersonalityTestComplete())")
        print("Attachment Style: \(getAttachmentStyle() ?? "nil")")
        print("Communication Style: \(getCommunicationStyle() ?? "nil")")
        print("Personality Type: \(getDominantPersonalityType() ?? "nil")")
        print("Type Label: \(getPersonalityTypeLabel() ?? "nil")")
        print("Last Update: \(getLastPersonalityUpdate()?.description ?? "nil")")
        
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
}
