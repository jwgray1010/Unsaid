//
//  KeyboardInsightsService.swift
//  Unsaid - Advanced AI-Powered Keyboard Extension
//
//  Service for consuming keyboard extension data and providing insights
//  Real-time data sharing with keyboard extension for personalized AI coaching
//  Now properly placed in the keyboard extension folder with required enum definitions
//
//  Created by John Gray on 7/8/25.
//

import Foundation
// If needed for color extensions:
#if canImport(UIKit)
import UIKit
#endif

class KeyboardInsightsService {
    // MARK: - Properties
    
    static let shared = KeyboardInsightsService()
    private let userDefaults = UserDefaults(suiteName: "group.com.unsaid.shared") ?? UserDefaults.standard
    
    // MARK: - Data Models
    
    struct KeyboardMetrics {
        let totalInteractions: Int
        let toneDistribution: [ToneStatus: Int]
        let suggestionAcceptanceRate: Float
        let improvementTrend: Float
        let dominantAttachmentStyle: AttachmentStyle
        let communicationPatterns: [CommunicationPattern: Int]
        let relationshipContexts: [RelationshipContext: Int]
        let lastInteractionTime: Date?
    }
    
    struct UserInsights {
        let communicationStrengths: [String]
        let improvementAreas: [String]
        let personalizedSuggestions: [String]
        let progressOverTime: [String: Float]
        let relationshipSpecificInsights: [RelationshipContext: [String]]
    }
    
    // MARK: - Public Methods
    
    /// Get real-time keyboard metrics for insights dashboard
    func getKeyboardMetrics() -> KeyboardMetrics {
        let interactions = getRecentInteractions()
        let toneDistribution = calculateToneDistribution(interactions)
        let suggestionAcceptanceRate = calculateSuggestionAcceptanceRate(interactions)
        let improvementTrend = calculateImprovementTrend(interactions)
        let dominantAttachmentStyle = calculateDominantAttachmentStyle(interactions)
        let communicationPatterns = calculateCommunicationPatterns(interactions)
        let relationshipContexts = calculateRelationshipContexts(interactions)
        let lastInteractionTime = interactions.last?["timestamp"] as? TimeInterval
        
        return KeyboardMetrics(
            totalInteractions: interactions.count,
            toneDistribution: toneDistribution,
            suggestionAcceptanceRate: suggestionAcceptanceRate,
            improvementTrend: improvementTrend,
            dominantAttachmentStyle: dominantAttachmentStyle,
            communicationPatterns: communicationPatterns,
            relationshipContexts: relationshipContexts,
            lastInteractionTime: lastInteractionTime != nil ? Date(timeIntervalSince1970: lastInteractionTime!) : nil
        )
    }
    
    /// Generate personalized insights based on keyboard usage
    func generateUserInsights() -> UserInsights {
        let metrics = getKeyboardMetrics()
        let interactions = getRecentInteractions()
        
        let strengths = identifyStrengths(metrics: metrics)
        let improvementAreas = identifyImprovementAreas(metrics: metrics)
        let personalizedSuggestions = generatePersonalizedSuggestions(metrics: metrics)
        let progressOverTime = calculateProgressOverTime(interactions)
        let relationshipInsights = generateRelationshipSpecificInsights(interactions)
        
        return UserInsights(
            communicationStrengths: strengths,
            improvementAreas: improvementAreas,
            personalizedSuggestions: personalizedSuggestions,
            progressOverTime: progressOverTime,
            relationshipSpecificInsights: relationshipInsights
        )
    }
    
    /// Update user profile based on keyboard insights for personalized coaching
    func updateUserProfile() {
        let insights = generateUserInsights()
        let metrics = getKeyboardMetrics()
        
        // Update user profile with latest insights
        var userProfile = userDefaults.dictionary(forKey: "user_profile") ?? [:]
        
        userProfile["dominant_attachment_style"] = metrics.dominantAttachmentStyle.rawValue
        userProfile["communication_strengths"] = insights.communicationStrengths
        userProfile["improvement_areas"] = insights.improvementAreas
        userProfile["last_analysis_date"] = Date().timeIntervalSince1970
        userProfile["total_interactions"] = metrics.totalInteractions
        userProfile["suggestion_acceptance_rate"] = metrics.suggestionAcceptanceRate
        userProfile["improvement_trend"] = metrics.improvementTrend
        
        userDefaults.set(userProfile, forKey: "user_profile")
        
        // Update personalized coaching settings for the keyboard extension
        updateKeyboardCoachingSettings(metrics: metrics, insights: insights)
    }
    
    /// Get recent interactions for analysis (last 100 interactions)
    func getRecentInteractions() -> [[String: Any]] {
        let allEvents = getAllEvents()
        return Array(allEvents.suffix(100))
    }
    
    /// Clear all keyboard data (for privacy/reset)
    func clearKeyboardData() {
        userDefaults.removeObject(forKey: "keyboard_events")
        userDefaults.removeObject(forKey: "user_profile")
        userDefaults.removeObject(forKey: "keyboard_coaching_settings")
    }
    
    // MARK: - Private Methods
    
    private func getAllEvents() -> [[String: Any]] {
        return userDefaults.array(forKey: "keyboard_events") as? [[String: Any]] ?? []
    }
    
    private func calculateToneDistribution(_ interactions: [[String: Any]]) -> [ToneStatus: Int] {
        var distribution: [ToneStatus: Int] = [:]
        
        for interaction in interactions {
            if let toneString = interaction["tone_status"] as? String,
               let tone = ToneStatus(rawValue: toneString) {
                distribution[tone, default: 0] += 1
            }
        }
        
        return distribution
    }
    
    private func calculateSuggestionAcceptanceRate(_ interactions: [[String: Any]]) -> Float {
        let acceptedCount = interactions.filter { $0["accepted_suggestion"] as? Bool == true }.count
        return interactions.count > 0 ? Float(acceptedCount) / Float(interactions.count) : 0.0
    }
    
    private func calculateImprovementTrend(_ interactions: [[String: Any]]) -> Float {
        let recentInteractions = Array(interactions.suffix(20))
        let olderInteractions = Array(interactions.prefix(20))
        
        let recentAlertRate = recentInteractions.filter { $0["tone_status"] as? String == "alert" }.count
        let olderAlertRate = olderInteractions.filter { $0["tone_status"] as? String == "alert" }.count
        
        return Float(olderAlertRate) - Float(recentAlertRate)
    }
    
    private func calculateDominantAttachmentStyle(_ interactions: [[String: Any]]) -> AttachmentStyle {
        var styleCount: [AttachmentStyle: Int] = [:]
        
        for interaction in interactions {
            if let styleString = interaction["attachment_style"] as? String,
               let style = AttachmentStyle(rawValue: styleString) {
                styleCount[style, default: 0] += 1
            }
        }
        
        return styleCount.max(by: { $0.value < $1.value })?.key ?? .unknown
    }
    
    private func calculateCommunicationPatterns(_ interactions: [[String: Any]]) -> [CommunicationPattern: Int] {
        var patterns: [CommunicationPattern: Int] = [:]
        
        for interaction in interactions {
            if let patternString = interaction["communication_pattern"] as? String,
               let pattern = CommunicationPattern(rawValue: patternString) {
                patterns[pattern, default: 0] += 1
            }
        }
        
        return patterns
    }
    
    private func calculateRelationshipContexts(_ interactions: [[String: Any]]) -> [RelationshipContext: Int] {
        var contexts: [RelationshipContext: Int] = [:]
        
        for interaction in interactions {
            if let contextString = interaction["relationship_context"] as? String,
               let context = RelationshipContext(rawValue: contextString) {
                contexts[context, default: 0] += 1
            }
        }
        
        return contexts
    }
    
    private func calculateProgressOverTime(_ interactions: [[String: Any]]) -> [String: Float] {
        var progress: [String: Float] = [:]
        
        let thirtyDaysAgo = Date().timeIntervalSince1970 - (30 * 24 * 60 * 60)
        let recentInteractions = interactions.filter { interaction in
            guard let timestamp = interaction["timestamp"] as? TimeInterval else { return false }
            return timestamp > thirtyDaysAgo
        }
        
        // Calculate weekly progress
        for weekOffset in 0..<4 {
            let weekStart = thirtyDaysAgo + TimeInterval(weekOffset * 7 * 24 * 60 * 60)
            let weekEnd = weekStart + TimeInterval(7 * 24 * 60 * 60)
            
            let weekInteractions = recentInteractions.filter { interaction in
                guard let timestamp = interaction["timestamp"] as? TimeInterval else { return false }
                return timestamp >= weekStart && timestamp < weekEnd
            }
            
            let alertCount = weekInteractions.filter { $0["tone_status"] as? String == "alert" }.count
            let alertRate = weekInteractions.count > 0 ? Float(alertCount) / Float(weekInteractions.count) : 0.0
            
            progress["week_\(weekOffset + 1)"] = 1.0 - alertRate // Higher score = less alerts
        }
        
        return progress
    }
    
    private func identifyStrengths(metrics: KeyboardMetrics) -> [String] {
        var strengths: [String] = []
        
        // High suggestion acceptance rate
        if metrics.suggestionAcceptanceRate > 0.7 {
            strengths.append("Receptive to feedback and suggestions")
        }
        
        // Good tone distribution
        let clearRate = Float(metrics.toneDistribution[.clear] ?? 0) / Float(metrics.totalInteractions)
        if clearRate > 0.6 {
            strengths.append("Generally positive and clear communication")
        }
        
        // Secure attachment style
        if metrics.dominantAttachmentStyle == .secure {
            strengths.append("Secure communication style")
        }
        
        // Assertive communication pattern
        if (metrics.communicationPatterns[.assertive] ?? 0) > metrics.totalInteractions / 3 {
            strengths.append("Assertive communication approach")
        }
        
        // Improvement trend
        if metrics.improvementTrend > 0.5 {
            strengths.append("Showing improvement in tone over time")
        }
        
        return strengths
    }
    
    private func identifyImprovementAreas(metrics: KeyboardMetrics) -> [String] {
        var areas: [String] = []
        
        // High alert rate
        let alertRate = Float(metrics.toneDistribution[.alert] ?? 0) / Float(metrics.totalInteractions)
        if alertRate > 0.2 {
            areas.append("Reducing harsh or potentially hurtful language")
        }
        
        // Low suggestion acceptance
        if metrics.suggestionAcceptanceRate < 0.3 {
            areas.append("Being more open to tone suggestions")
        }
        
        // Anxious attachment style
        if metrics.dominantAttachmentStyle == .anxious {
            areas.append("Managing anxiety in communication")
        } else if metrics.dominantAttachmentStyle == .avoidant {
            areas.append("Increasing emotional openness")
        }
        
        // Defensive communication
        if (metrics.communicationPatterns[.defensive] ?? 0) > metrics.totalInteractions / 4 {
            areas.append("Reducing defensive responses")
        }
        
        // Passive-aggressive communication
        if (metrics.communicationPatterns[.passiveAggressive] ?? 0) > metrics.totalInteractions / 5 {
            areas.append("Expressing concerns more directly")
        }
        
        return areas
    }
    
    private func generatePersonalizedSuggestions(metrics: KeyboardMetrics) -> [String] {
        var suggestions: [String] = []
        
        // Based on attachment style
        switch metrics.dominantAttachmentStyle {
        case .secure:
            suggestions.append("Continue using your natural communication strengths")
        case .anxious:
            suggestions.append("Try pausing before sending emotionally charged messages")
            suggestions.append("Consider using 'I' statements to express feelings")
        case .avoidant:
            suggestions.append("Practice expressing your emotions more openly")
            suggestions.append("Try acknowledging others' feelings in your responses")
        case .disorganized:
            suggestions.append("Work on consistent communication patterns")
            suggestions.append("Consider taking breaks during intense conversations")
        case .unknown:
            suggestions.append("Continue using the keyboard to learn your communication style")
        }
        
        // Based on tone distribution
        let alertRate = Float(metrics.toneDistribution[.alert] ?? 0) / Float(metrics.totalInteractions)
        if alertRate > 0.15 {
            suggestions.append("Consider reviewing messages before sending when feeling frustrated")
        }
        
        // Based on communication patterns
        if (metrics.communicationPatterns[.aggressive] ?? 0) > metrics.totalInteractions / 6 {
            suggestions.append("Try softening your language with phrases like 'I feel...' or 'Could we...'")
        }
        
        return suggestions
    }
    
    private func generateRelationshipSpecificInsights(_ interactions: [[String: Any]]) -> [RelationshipContext: [String]] {
        var insights: [RelationshipContext: [String]] = [:]
        
        for context in RelationshipContext.allCases {
            let contextInteractions = interactions.filter { $0["relationship_context"] as? String == context.rawValue }
            
            if contextInteractions.count > 5 {
                var contextInsights: [String] = []
                
                let alertCount = contextInteractions.filter { $0["tone_status"] as? String == "alert" }.count
                let alertRate = Float(alertCount) / Float(contextInteractions.count)
                
                if alertRate > 0.2 {
                    contextInsights.append("Higher tendency for harsh language in \(context.displayName.lowercased()) conversations")
                } else if alertRate < 0.1 {
                    contextInsights.append("Generally positive tone in \(context.displayName.lowercased()) conversations")
                }
                
                insights[context] = contextInsights
            }
        }
        
        return insights
    }
    
    private func updateKeyboardCoachingSettings(metrics: KeyboardMetrics, insights: UserInsights) {
        // Push personalized coaching settings to keyboard extension
        var coachingSettings = userDefaults.dictionary(forKey: "keyboard_coaching_settings") ?? [:]
        
        coachingSettings["dominant_attachment_style"] = metrics.dominantAttachmentStyle.rawValue
        coachingSettings["priority_improvement_areas"] = insights.improvementAreas
        coachingSettings["personalized_suggestions"] = insights.personalizedSuggestions
        coachingSettings["suggestion_sensitivity"] = metrics.suggestionAcceptanceRate > 0.5 ? "high" : "medium"
        coachingSettings["last_update"] = Date().timeIntervalSince1970
        
        userDefaults.set(coachingSettings, forKey: "keyboard_coaching_settings")
    }
}

// MARK: - Notification Extension
extension KeyboardInsightsService {
    /// Notification names for real-time updates
    static let keyboardDataUpdatedNotification = Notification.Name("KeyboardDataUpdated")
    static let userInsightsUpdatedNotification = Notification.Name("UserInsightsUpdated")
    
    /// Start monitoring keyboard data changes
    func startMonitoringKeyboardData() {
        // Monitor for keyboard data updates
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: userDefaults,
            queue: .main
        ) { [weak self] _ in
            self?.handleKeyboardDataUpdate()
        }
    }
    
    private func handleKeyboardDataUpdate() {
        // Update user profile when new keyboard data arrives
        updateUserProfile()
        
        // Notify app components about data update
        NotificationCenter.default.post(
            name: Self.keyboardDataUpdatedNotification,
            object: nil
        )
        
        // Generate fresh insights
        let insights = generateUserInsights()
        NotificationCenter.default.post(
            name: Self.userInsightsUpdatedNotification,
            object: insights
        )
    }
}
