//
//  KeyboardSettingsManager.swift
//  Unsaid - Advanced AI-Powered Keyboard Extension
//
//  Created by John Gray on 7/7/25.
//

import Foundation
// If needed for color extensions:
#if canImport(UIKit)
import UIKit
#endif

// Note: Uses SharedTypes.swift for centralized type definitions

class KeyboardSettingsManager {
    static let shared = KeyboardSettingsManager()
    
    private init() {}
    
    private(set) var userAttachmentStyle: AttachmentStyle = .secure
    private(set) var currentRelationshipContext: RelationshipContext = .unknown
    
    func loadUserSettings() {
        // Load user attachment style and preferences from shared UserDefaults
        let userDefaults = UserDefaults(suiteName: "group.com.unsaid.shared")
        
        if let styleString = userDefaults?.string(forKey: "user_attachment_style") {
            userAttachmentStyle = AttachmentStyle(rawValue: styleString) ?? .secure
        }
        
        if let contextString = userDefaults?.string(forKey: "relationship_context") {
            currentRelationshipContext = RelationshipContext(rawValue: contextString) ?? .unknown
        }
    }
    
    func saveUserSettings() {
        let userDefaults = UserDefaults(suiteName: "group.com.unsaid.shared")
        userDefaults?.set(userAttachmentStyle.rawValue, forKey: "user_attachment_style")
        userDefaults?.set(currentRelationshipContext.rawValue, forKey: "relationship_context")
    }
    
    func updateAttachmentStyle(_ style: AttachmentStyle) {
        userAttachmentStyle = style
        saveUserSettings()
    }
    
    func updateRelationshipContext(_ context: RelationshipContext) {
        currentRelationshipContext = context
        saveUserSettings()
    }
    
    // MARK: - User Preferences (from main app)
    
    /// Get user's attachment style from main app
    func getUserAttachmentStyle() -> AttachmentStyle {
        let userDefaults = UserDefaults(suiteName: "group.com.unsaid.shared")
        if let preferences = userDefaults?.dictionary(forKey: "user_preferences"),
           let styleString = preferences["attachment_style"] as? String,
           let style = AttachmentStyle(rawValue: styleString) {
            return style
        }
        return .unknown
    }
    
    /// Get user's communication goals from main app
    func getUserCommunicationGoals() -> [String] {
        let userDefaults = UserDefaults(suiteName: "group.com.unsaid.shared")
        if let preferences = userDefaults?.dictionary(forKey: "user_preferences"),
           let goals = preferences["communication_goals"] as? [String] {
            return goals
        }
        return []
    }
    
    /// Get coaching settings from main app
    func getCoachingSettings() -> [String: Any] {
        let userDefaults = UserDefaults(suiteName: "group.com.unsaid.shared")
        return userDefaults?.dictionary(forKey: "keyboard_coaching_settings") ?? [:]
    }
    
    /// Get coaching sensitivity level
    func getCoachingSensitivity() -> String {
        let settings = getCoachingSettings()
        return settings["sensitivity"] as? String ?? "medium"
    }
    
    /// Check if real-time coaching is enabled
    func isRealTimeCoachingEnabled() -> Bool {
        let settings = getCoachingSettings()
        return settings["real_time_coaching"] as? Bool ?? true
    }
    
    /// Get personalized suggestions from main app analysis
    func getPersonalizedSuggestions() -> [String] {
        let settings = getCoachingSettings()
        return settings["personalized_suggestions"] as? [String] ?? []
    }
    
    /// Get priority improvement areas from main app analysis
    func getPriorityImprovementAreas() -> [String] {
        let settings = getCoachingSettings()
        return settings["priority_improvement_areas"] as? [String] ?? []
    }
}
