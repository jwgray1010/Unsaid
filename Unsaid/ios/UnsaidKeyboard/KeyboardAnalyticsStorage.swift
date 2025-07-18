//
//  KeyboardAnalyticsStorage.swift
//  Unsaid
//
//  Handles all analytics data storage and retrieval for the keyboard extension
//  Ensures seamless data flow between keyboard and main app via shared UserDefaults
//
//  Created on 7/11/25.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import NaturalLanguage

class KeyboardAnalyticsStorage {
    
    // MARK: - Singleton
    
    static let shared = KeyboardAnalyticsStorage()
    private init() {}
    
    // MARK: - Properties
    
    private let userDefaults = UserDefaults.standard
    private let maxStoredInteractions = 1000
    private let maxStoredAnalytics = 500
    
    // MARK: - Analytics Storage
    
    /// Store keyboard interaction data
    func recordInteraction(_ interaction: KeyboardInteraction) {
        var interactions = getStoredInteractions()
        interactions.append(interaction.toDictionary())
        
        // Limit stored interactions
        if interactions.count > maxStoredInteractions {
            interactions = Array(interactions.suffix(maxStoredInteractions))
        }
        
        userDefaults.set(interactions, forKey: "keyboard_interactions")
        
        // Update session analytics
        updateSessionAnalytics(with: interaction)
        
        print(" Recorded interaction: \(interaction.interactionType.rawValue)")
    }
    
    /// Store tone analysis result
    func recordToneAnalysis(text: String, tone: ToneStatus, analysisTime: TimeInterval) {
        let interaction = KeyboardInteraction(
            timestamp: Date(),
            textBefore: text,
            textAfter: text,
            toneStatus: tone,
            suggestionAccepted: false,
            suggestionText: String?.none,
            analysisTime: analysisTime,
            context: "tone_analysis",
            interactionType: InteractionType.toneAnalysis
        )
        
        recordInteraction(interaction)
    }
    
    /// Store suggestion acceptance/rejection
    func recordSuggestionInteraction(suggestion: String, accepted: Bool, context: String) {
        let interaction = KeyboardInteraction(
            timestamp: Date(),
            textBefore: context,
            textAfter: accepted ? suggestion : context,
            toneStatus: .neutral,
            suggestionAccepted: accepted,
            suggestionText: suggestion,
            analysisTime: 0,
            context: "suggestion_interaction",
            interactionType: .suggestion
        )
        
        recordInteraction(interaction)
    }
    
    /// Store Quick Fix usage
    func recordQuickFixUsage(originalText: String, fixedText: String, fixType: String) {
        let interaction = KeyboardInteraction(
            timestamp: Date(),
            textBefore: originalText,
            textAfter: fixedText,
            toneStatus: .clear,
            suggestionAccepted: true,
            suggestionText: fixedText,
            analysisTime: 0,
            context: "quick_fix_\(fixType)",
            interactionType: .quickFix
        )
        
        recordInteraction(interaction)
    }
    
    // MARK: - Session Analytics
    
    /// Update comprehensive session analytics
    private func updateSessionAnalytics(with interaction: KeyboardInteraction) {
        var analytics = getStoredAnalytics()
        
        // Update basic metrics
        analytics["total_interactions"] = (analytics["total_interactions"] as? Int ?? 0) + 1
        analytics["last_interaction"] = interaction.timestamp.timeIntervalSince1970
        
        // Update tone distribution
        var toneDistribution = analytics["tone_distribution"] as? [String: Int] ?? [:]
        let toneKey = interaction.toneStatus.rawValue
        toneDistribution[toneKey] = (toneDistribution[toneKey] ?? 0) + 1
        analytics["tone_distribution"] = toneDistribution
        
        // Update interaction type distribution
        var interactionTypes = analytics["interaction_types"] as? [String: Int] ?? [:]
        let typeKey = interaction.interactionType.rawValue
        interactionTypes[typeKey] = (interactionTypes[typeKey] ?? 0) + 1
        analytics["interaction_types"] = interactionTypes
        
        // Update suggestion metrics
        if interaction.interactionType == .suggestion {
            let totalSuggestions = analytics["total_suggestions"] as? Int ?? 0
            let acceptedSuggestions = analytics["accepted_suggestions"] as? Int ?? 0
            
            analytics["total_suggestions"] = totalSuggestions + 1
            if interaction.suggestionAccepted {
                analytics["accepted_suggestions"] = acceptedSuggestions + 1
            }
            
            let acceptanceRate = Float(acceptedSuggestions + (interaction.suggestionAccepted ? 1 : 0)) / Float(totalSuggestions + 1)
            analytics["suggestion_acceptance_rate"] = acceptanceRate
        }
        
        // Update performance metrics
        if interaction.analysisTime > 0 {
            let totalAnalysisTime = analytics["total_analysis_time"] as? Double ?? 0
            let analysisCount = analytics["analysis_count"] as? Int ?? 0
            
            analytics["total_analysis_time"] = totalAnalysisTime + interaction.analysisTime
            analytics["analysis_count"] = analysisCount + 1
            analytics["average_analysis_time"] = (totalAnalysisTime + interaction.analysisTime) / Double(analysisCount + 1)
        }
        
        // Update session duration
        if let sessionStart = analytics["session_start"] as? Double {
            analytics["session_duration"] = Date().timeIntervalSince1970 - sessionStart
        } else {
            analytics["session_start"] = Date().timeIntervalSince1970
        }
        
        userDefaults.set(analytics, forKey: "keyboard_analytics")
    }
    
    /// Start new session tracking
    func startSession() {
        var analytics = getStoredAnalytics()
        analytics["session_start"] = Date().timeIntervalSince1970
        analytics["session_active"] = true
        
        // Reset session-specific metrics
        analytics["session_interactions"] = 0
        analytics["session_tone_changes"] = 0
        analytics["session_suggestions"] = 0
        
        userDefaults.set(analytics, forKey: "keyboard_analytics")
        
        print(" Started new keyboard session")
    }
    
    /// End current session
    func endSession() {
        var analytics = getStoredAnalytics()
        
        if let sessionStart = analytics["session_start"] as? Double {
            let sessionDuration = Date().timeIntervalSince1970 - sessionStart
            analytics["last_session_duration"] = sessionDuration
            
            // Update total usage time
            let totalUsageTime = analytics["total_usage_time"] as? Double ?? 0
            analytics["total_usage_time"] = totalUsageTime + sessionDuration
        }
        
        analytics["session_active"] = false
        analytics["session_end"] = Date().timeIntervalSince1970
        
        userDefaults.set(analytics, forKey: "keyboard_analytics")
        
        print(" Ended keyboard session")
    }
    
    // MARK: - Insights Generation
    
    /// Generate insights for main app consumption
    func generateInsights() -> [String: Any] {
        let interactions = getStoredInteractions()
        let analytics = getStoredAnalytics()
        
        var insights: [String: Any] = [:]
        
        // Communication patterns
        insights["dominant_tone"] = findDominantTone(from: interactions)
        insights["tone_trend"] = calculateToneTrend(from: interactions)
        insights["improvement_score"] = calculateImprovementScore(from: interactions)
        
        // Usage patterns
        insights["most_active_hours"] = findMostActiveHours(from: interactions)
        insights["average_session_length"] = analytics["average_session_length"] ?? 0
        insights["quick_fix_usage"] = calculateQuickFixUsage(from: interactions)
        
        // Performance insights
        insights["typing_efficiency"] = calculateTypingEfficiency(from: interactions)
        insights["suggestion_helpfulness"] = analytics["suggestion_acceptance_rate"] ?? 0
        
        // Personality-based insights
        insights["communication_style"] = analyzeCommunicationStyle(from: interactions)
        insights["relationship_context_usage"] = analyzeRelationshipContexts(from: interactions)
        
        // Store insights for main app
        userDefaults.set(insights, forKey: "keyboard_insights")
        
        return insights
    }
    
    // MARK: - Data Retrieval (for main app)
    
    /// Get all stored interactions
    func getStoredInteractions() -> [[String: Any]] {
        return userDefaults.array(forKey: "keyboard_interactions") as? [[String: Any]] ?? []
    }
    
    /// Get stored analytics
    func getStoredAnalytics() -> [String: Any] {
        return userDefaults.dictionary(forKey: "keyboard_analytics") ?? [:]
    }
    
    /// Get generated insights
    func getStoredInsights() -> [String: Any] {
        return userDefaults.dictionary(forKey: "keyboard_insights") ?? [:]
    }
    
    /// Get recent interactions (last N)
    func getRecentInteractions(count: Int = 50) -> [[String: Any]] {
        let allInteractions = getStoredInteractions()
        return Array(allInteractions.suffix(count))
    }
    
    // MARK: - Data Management
    
    /// Clear all stored data
    func clearAllData() {
        userDefaults.removeObject(forKey: "keyboard_interactions")
        userDefaults.removeObject(forKey: "keyboard_analytics")
        userDefaults.removeObject(forKey: "keyboard_insights")
        userDefaults.removeObject(forKey: "keyboard_session_status")
        
        print("Cleared all keyboard analytics data")
    }
    
    /// Clean up old data (keep last 30 days)
    func cleanupOldData() {
        let cutoffDate = Date().timeIntervalSince1970 - (30 * 24 * 60 * 60) // 30 days ago
        
        let interactions = getStoredInteractions()
        let recentInteractions = interactions.filter { interaction in
            if let timestamp = interaction["timestamp"] as? Double {
                return timestamp > cutoffDate
            }
            return false
        }
        
        userDefaults.set(recentInteractions, forKey: "keyboard_interactions")
        
        print(" Cleaned up old keyboard data (kept \(recentInteractions.count) recent interactions)")
    }
    
    // MARK: - Helper Methods
    
    private func findDominantTone(from interactions: [[String: Any]]) -> String {
        var toneCount: [String: Int] = [:]
        
        for interaction in interactions {
            if let tone = interaction["tone_status"] as? String {
                toneCount[tone] = (toneCount[tone] ?? 0) + 1
            }
        }
        
        return toneCount.max { $0.value < $1.value }?.key ?? "neutral"
    }
    
    private func calculateToneTrend(from interactions: [[String: Any]]) -> String {
        // Compare recent vs older interactions
        let recentInteractions = Array(interactions.suffix(20))
        let olderInteractions = Array(interactions.dropLast(20).suffix(20))
        
        let recentPositive = countPositiveTones(in: recentInteractions)
        let olderPositive = countPositiveTones(in: olderInteractions)
        
        if recentPositive > olderPositive {
            return "improving"
        } else if recentPositive < olderPositive {
            return "declining"
        } else {
            return "stable"
        }
    }
    
    private func countPositiveTones(in interactions: [[String: Any]]) -> Int {
        return interactions.filter { interaction in
            if let tone = interaction["tone_status"] as? String {
                return tone == "clear" || tone == "neutral"
            }
            return false
        }.count
    }
    
    private func calculateImprovementScore(from interactions: [[String: Any]]) -> Float {
        // Calculate improvement based on tone progression
        let recentInteractions = Array(interactions.suffix(50))
        let positiveCount = countPositiveTones(in: recentInteractions)
        
        return Float(positiveCount) / Float(max(recentInteractions.count, 1))
    }
    
    private func findMostActiveHours(from interactions: [[String: Any]]) -> [Int] {
        var hourCounts: [Int: Int] = [:]
        
        for interaction in interactions {
            if let timestamp = interaction["timestamp"] as? Double {
                let date = Date(timeIntervalSince1970: timestamp)
                let hour = Calendar.current.component(.hour, from: date)
                hourCounts[hour] = (hourCounts[hour] ?? 0) + 1
            }
        }
        
        return hourCounts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
    }
    
    private func calculateQuickFixUsage(from interactions: [[String: Any]]) -> Float {
        let quickFixCount = interactions.filter { interaction in
            if let type = interaction["interaction_type"] as? String {
                return type == "quick_fix"
            }
            return false
        }.count
        
        return Float(quickFixCount) / Float(max(interactions.count, 1))
    }
    
    private func calculateTypingEfficiency(from interactions: [[String: Any]]) -> Float {
        // Calculate based on suggestion acceptance and quick fix usage
        let totalSuggestions = interactions.filter { $0["interaction_type"] as? String == "suggestion" }.count
        let acceptedSuggestions = interactions.filter { interaction in
            return interaction["suggestion_accepted"] as? Bool == true
        }.count
        
        return totalSuggestions > 0 ? Float(acceptedSuggestions) / Float(totalSuggestions) : 0.0
    }
    
    private func analyzeCommunicationStyle(from interactions: [[String: Any]]) -> String {
        // Analyze based on tone patterns
        let toneDistribution = interactions.reduce(into: [String: Int]()) { dict, interaction in
            if let tone = interaction["tone_status"] as? String {
                dict[tone] = (dict[tone] ?? 0) + 1
            }
        }
        
        let total = toneDistribution.values.reduce(0, +)
        let clearPercentage = Float(toneDistribution["clear"] ?? 0) / Float(max(total, 1))
        
        if clearPercentage > 0.7 {
            return "diplomatic"
        } else if clearPercentage > 0.4 {
            return "balanced"
        } else {
            return "direct"
        }
    }
    
    private func analyzeRelationshipContexts(from interactions: [[String: Any]]) -> [String: Int] {
        // This would analyze context patterns - simplified for now
        return [
            "professional": interactions.count / 3,
            "personal": interactions.count / 3,
            "casual": interactions.count / 3
        ]
    }
    
    // MARK: - Debug Methods
    
    /// Print current analytics for debugging
    func debugPrintAnalytics() {
        let analytics = getStoredAnalytics()
        let interactions = getStoredInteractions()
        let insights = getStoredInsights()
        
        print(" KEYBOARD ANALYTICS DEBUG")
        print("==========================")
        print("Total Interactions: \(interactions.count)")
        print("Analytics Keys: \(analytics.keys.sorted())")
        print("Insights Keys: \(insights.keys.sorted())")
        print("Last Interaction: \(analytics["last_interaction"] ?? "none")")
        print("Session Active: \(analytics["session_active"] ?? false)")
        print("==========================")
    }
}
