//
//  KeyboardDataCollector.swift
//  KeyboardExtension
//
//  Data collection and analytics for keyboard interactions
//  Feeds into insights and relationship hub
//
//  Created by John Gray on 7/8/25.
//

import Foundation
// If needed for color extensions:
#if canImport(UIKit)
import UIKit
#endif

class KeyboardDataCollector {
    // MARK: - Data Models

    struct KeyboardInteraction {
        let timestamp: Date
        let originalText: String
        let toneStatus: ToneStatus
        let suggestions: [String]
        let userAcceptedSuggestion: Bool
        let attachmentStyleDetected: AttachmentStyle?
        let communicationPattern: CommunicationPattern?
        let relationshipContext: RelationshipContext?
        let appContext: String? // Which app they're typing in
        let wordCount: Int
        let characterCount: Int
        let sentimentScore: Float
    }

    struct CommunicationMetrics {
        let totalInteractions: Int
        let toneDistribution: [ToneStatus: Int]
        let suggestionAcceptanceRate: Float
        let averageResponseTime: TimeInterval
        let mostTriggeredPatterns: [String]
        let improvementTrend: Float
    }

    // MARK: - Data Storage

    private var interactions: [KeyboardInteraction] = []
    private let maxStoredInteractions = 1000
    private let userDefaults = UserDefaults(suiteName: "group.com.unsaid.shared") ?? UserDefaults.standard

    // MARK: - Collection Methods

    func recordInteraction(
        text: String,
        toneStatus: ToneStatus,
        suggestions: [String],
        userAcceptedSuggestion: Bool,
        attachmentStyle: AttachmentStyle?,
        communicationPattern: CommunicationPattern?,
        relationshipContext: RelationshipContext?
    ) {
        let interaction = KeyboardInteraction(
            timestamp: Date(),
            originalText: text,
            toneStatus: toneStatus,
            suggestions: suggestions,
            userAcceptedSuggestion: userAcceptedSuggestion,
            attachmentStyleDetected: attachmentStyle,
            communicationPattern: communicationPattern,
            relationshipContext: relationshipContext,
            appContext: getCurrentAppContext(),
            wordCount: text.components(separatedBy: .whitespacesAndNewlines).count,
            characterCount: text.count,
            sentimentScore: calculateSentimentScore(text)
        )

        // Store interaction
        interactions.append(interaction)

        // Maintain storage limit
        if interactions.count > maxStoredInteractions {
            interactions.removeFirst()
        }

        // Persist to UserDefaults (shared with main app)
        persistInteraction(interaction)

        // Update analytics
        updateAnalytics(interaction)
    }

    func recordToneChange(from oldTone: ToneStatus, to newTone: ToneStatus, text: String) {
        let event = [
            "type": "tone_change",
            "from": oldTone.rawValue,
            "to": newTone.rawValue,
            "text_length": text.count,
            "timestamp": Date().timeIntervalSince1970,
        ] as [String: Any]

        persistEvent(event)
    }

    func recordSuggestionAccepted(suggestion: String, originalText: String, improvedText: String) {
        let event = [
            "type": "suggestion_accepted",
            "suggestion": suggestion,
            "original_length": originalText.count,
            "improved_length": improvedText.count,
            "timestamp": Date().timeIntervalSince1970,
        ] as [String: Any]

        persistEvent(event)
    }

    // MARK: - Analytics Methods

    func generateInsightsData() -> [String: Any] {
        let metrics = calculateMetrics()

        return [
            "total_interactions": metrics.totalInteractions,
            "tone_distribution": metrics.toneDistribution.mapValues { $0 },
            "suggestion_acceptance_rate": metrics.suggestionAcceptanceRate,
            "average_response_time": metrics.averageResponseTime,
            "most_triggered_patterns": metrics.mostTriggeredPatterns,
            "improvement_trend": metrics.improvementTrend,
            "communication_patterns": getCommunicationPatterns(),
            "attachment_style_insights": getAttachmentStyleInsights(),
            "relationship_context_data": getRelationshipContextData(),
        ]
    }

    func getRecentInteractions(limit: Int = 50) -> [KeyboardInteraction] {
        return Array(interactions.suffix(limit))
    }

    func getToneFrequency() -> [ToneStatus: Int] {
        var frequency: [ToneStatus: Int] = [:]

        for interaction in interactions {
            frequency[interaction.toneStatus, default: 0] += 1
        }

        return frequency
    }

    // MARK: - Data Persistence

    private func persistInteraction(_ interaction: KeyboardInteraction) {
        // Serialize interaction for main app consumption
        let interactionData = [
            "timestamp": interaction.timestamp.timeIntervalSince1970,
            "tone_status": interaction.toneStatus.rawValue,
            "suggestions_count": interaction.suggestions.count,
            "accepted_suggestion": interaction.userAcceptedSuggestion,
            "attachment_style": interaction.attachmentStyleDetected?.rawValue ?? "unknown",
            "communication_pattern": interaction.communicationPattern?.rawValue ?? "unknown",
            "relationship_context": interaction.relationshipContext?.rawValue ?? "unknown",
            "app_context": interaction.appContext ?? "unknown",
            "word_count": interaction.wordCount,
            "character_count": interaction.characterCount,
            "sentiment_score": interaction.sentimentScore,
        ] as [String: Any]

        // Add to array in shared UserDefaults
        var storedInteractions = userDefaults.array(forKey: "keyboard_interactions") as? [[String: Any]] ?? []
        storedInteractions.append(interactionData)

        // Keep only recent interactions
        if storedInteractions.count > maxStoredInteractions {
            storedInteractions.removeFirst()
        }

        userDefaults.set(storedInteractions, forKey: "keyboard_interactions")
    }

    private func persistEvent(_ event: [String: Any]) {
        var events = userDefaults.array(forKey: "keyboard_events") as? [[String: Any]] ?? []
        events.append(event)

        // Keep only recent events
        if events.count > 500 {
            events.removeFirst()
        }

        userDefaults.set(events, forKey: "keyboard_events")
    }

    // MARK: - Helper Methods

    private func getCurrentAppContext() -> String {
        // Try to detect which app the user is typing in
        // This is limited in keyboard extensions, but we can try
        return "unknown_app"
    }

    private func calculateSentimentScore(_ text: String) -> Float {
        // Simple sentiment analysis
        let positiveWords = ["good", "great", "excellent", "amazing", "wonderful", "fantastic", "love", "happy", "excited", "pleased"]
        let negativeWords = ["bad", "terrible", "awful", "horrible", "hate", "angry", "frustrated", "disappointed", "upset", "annoyed"]

        let lowercaseText = text.lowercased()
        var score: Float = 0.0

        for word in positiveWords {
            if lowercaseText.contains(word) {
                score += 1.0
            }
        }

        for word in negativeWords {
            if lowercaseText.contains(word) {
                score -= 1.0
            }
        }

        return score
    }

    private func calculateMetrics() -> CommunicationMetrics {
        let toneDistribution = getToneFrequency()
        let totalInteractions = interactions.count

        let acceptedSuggestions = interactions.filter { $0.userAcceptedSuggestion }.count
        let suggestionAcceptanceRate = totalInteractions > 0 ? Float(acceptedSuggestions) / Float(totalInteractions) : 0.0

        // Calculate improvement trend (simplified)
        let recentInteractions = Array(interactions.suffix(20))
        let olderInteractions = Array(interactions.prefix(20))

        let recentAlertRate = recentInteractions.filter { $0.toneStatus == .alert }.count
        let olderAlertRate = olderInteractions.filter { $0.toneStatus == .alert }.count

        let improvementTrend = Float(olderAlertRate) - Float(recentAlertRate)

        return CommunicationMetrics(
            totalInteractions: totalInteractions,
            toneDistribution: toneDistribution,
            suggestionAcceptanceRate: suggestionAcceptanceRate,
            averageResponseTime: 0.0, // TODO: Implement response time tracking
            mostTriggeredPatterns: getMostTriggeredPatterns(),
            improvementTrend: improvementTrend
        )
    }

    private func getMostTriggeredPatterns() -> [String] {
        let patterns = interactions.compactMap { $0.communicationPattern?.rawValue }
        let frequency = Dictionary(grouping: patterns, by: { $0 })

        return frequency.sorted { $0.value.count > $1.value.count }
            .prefix(5)
            .map { $0.key }
    }

    private func getCommunicationPatterns() -> [String: Int] {
        let patterns = interactions.compactMap { $0.communicationPattern?.rawValue }
        return Dictionary(grouping: patterns, by: { $0 }).mapValues { $0.count }
    }

    private func getAttachmentStyleInsights() -> [String: Any] {
        let styles = interactions.compactMap { $0.attachmentStyleDetected?.rawValue }
        let frequency = Dictionary(grouping: styles, by: { $0 }).mapValues { $0.count }

        return [
            "frequency": frequency,
            "dominant_style": frequency.max { $0.value < $1.value }?.key ?? "unknown",
        ]
    }

    private func getRelationshipContextData() -> [String: Int] {
        let contexts = interactions.compactMap { $0.relationshipContext?.rawValue }
        return Dictionary(grouping: contexts, by: { $0 }).mapValues { $0.count }
    }

    private func updateAnalytics(_ interaction: KeyboardInteraction) {
        // Update running analytics
        let currentStats = userDefaults.dictionary(forKey: "keyboard_analytics") ?? [:]

        var updatedStats = currentStats
        updatedStats["last_interaction"] = interaction.timestamp.timeIntervalSince1970
        updatedStats["total_interactions"] = (currentStats["total_interactions"] as? Int ?? 0) + 1

        userDefaults.set(updatedStats, forKey: "keyboard_analytics")
        
        // Push real-time insights to main app
        pushRealTimeInsights(interaction)
    }
    
    // MARK: - Real-time Data Sharing for Main App
    
    /// Push real-time insights to main app for immediate dashboard updates
    private func pushRealTimeInsights(_ interaction: KeyboardInteraction) {
        // Create real-time insight data
        let insightData = [
            "timestamp": interaction.timestamp.timeIntervalSince1970,
            "tone_status": interaction.toneStatus.rawValue,
            "attachment_style": interaction.attachmentStyleDetected?.rawValue ?? "unknown",
            "communication_pattern": interaction.communicationPattern?.rawValue ?? "unknown",
            "relationship_context": interaction.relationshipContext?.rawValue ?? "unknown",
            "suggestion_accepted": interaction.userAcceptedSuggestion,
            "sentiment_score": interaction.sentimentScore,
            "word_count": interaction.wordCount,
            "app_context": interaction.appContext ?? "unknown"
        ] as [String: Any]
        
        // Add to real-time insights queue
        var insights = userDefaults.array(forKey: "real_time_insights") as? [[String: Any]] ?? []
        insights.append(insightData)
        
        // Keep only recent insights (last 50)
        if insights.count > 50 {
            insights.removeFirst()
        }
        
        userDefaults.set(insights, forKey: "real_time_insights")
        
        // Update communication health score
        updateCommunicationHealthScore(interaction)
        
        // Update relationship-specific metrics
        updateRelationshipMetrics(interaction)
    }
    
    /// Update communication health score for main app dashboard
    private func updateCommunicationHealthScore(_ interaction: KeyboardInteraction) {
        var healthMetrics = userDefaults.dictionary(forKey: "communication_health") ?? [:]
        
        // Calculate health score based on recent interactions
        let recentInteractions = Array(interactions.suffix(20))
        let clearToneCount = recentInteractions.filter { $0.toneStatus == .clear }.count
        let alertToneCount = recentInteractions.filter { $0.toneStatus == .alert }.count
        let suggestionAcceptanceCount = recentInteractions.filter { $0.userAcceptedSuggestion }.count
        
        let healthScore = Float(clearToneCount * 2 + suggestionAcceptanceCount - alertToneCount * 2) / Float(max(recentInteractions.count, 1))
        let normalizedScore = max(0, min(100, (healthScore + 2) * 25)) // Normalize to 0-100
        
        healthMetrics["current_score"] = normalizedScore
        healthMetrics["clear_tone_rate"] = Float(clearToneCount) / Float(max(recentInteractions.count, 1))
        healthMetrics["alert_tone_rate"] = Float(alertToneCount) / Float(max(recentInteractions.count, 1))
        healthMetrics["suggestion_acceptance_rate"] = Float(suggestionAcceptanceCount) / Float(max(recentInteractions.count, 1))
        healthMetrics["last_update"] = Date().timeIntervalSince1970
        
        // Track improvement trend
        let previousScore = healthMetrics["current_score"] as? Float ?? 50.0
        let improvement = normalizedScore - previousScore
        healthMetrics["improvement_trend"] = improvement
        
        userDefaults.set(healthMetrics, forKey: "communication_health")
    }
    
    /// Update relationship-specific metrics for main app insights
    private func updateRelationshipMetrics(_ interaction: KeyboardInteraction) {
        guard let relationshipContext = interaction.relationshipContext else { return }
        
        var relationshipMetrics = userDefaults.dictionary(forKey: "relationship_metrics") ?? [:]
        var contextMetrics = relationshipMetrics[relationshipContext.rawValue] as? [String: Any] ?? [:]
        
        // Update interaction counts
        let totalInteractions = (contextMetrics["total_interactions"] as? Int ?? 0) + 1
        contextMetrics["total_interactions"] = totalInteractions
        
        // Update tone distribution for this relationship context
        var toneDistribution = contextMetrics["tone_distribution"] as? [String: Int] ?? [:]
        toneDistribution[interaction.toneStatus.rawValue, default: 0] += 1
        contextMetrics["tone_distribution"] = toneDistribution
        
        // Update attachment style frequency
        if let attachmentStyle = interaction.attachmentStyleDetected {
            var attachmentFrequency = contextMetrics["attachment_frequency"] as? [String: Int] ?? [:]
            attachmentFrequency[attachmentStyle.rawValue, default: 0] += 1
            contextMetrics["attachment_frequency"] = attachmentFrequency
        }
        
        // Update communication pattern frequency
        if let communicationPattern = interaction.communicationPattern {
            var patternFrequency = contextMetrics["pattern_frequency"] as? [String: Int] ?? [:]
            patternFrequency[communicationPattern.rawValue, default: 0] += 1
            contextMetrics["pattern_frequency"] = patternFrequency
        }
        
        // Calculate relationship health score
        let clearCount = toneDistribution["clear"] ?? 0
        let alertCount = toneDistribution["alert"] ?? 0
        let relationshipHealth = Float(clearCount * 2 - alertCount) / Float(max(totalInteractions, 1))
        contextMetrics["relationship_health"] = max(0, min(100, (relationshipHealth + 1) * 50))
        
        contextMetrics["last_update"] = Date().timeIntervalSince1970
        
        relationshipMetrics[relationshipContext.rawValue] = contextMetrics
        userDefaults.set(relationshipMetrics, forKey: "relationship_metrics")
    }
    
    /// Push personalized coaching data to main app
    func pushPersonalizedCoachingData() {
        let recentInteractions = Array(interactions.suffix(30))
        
        var coachingData: [String: Any] = [:]
        
        // Analyze dominant patterns
        let dominantAttachmentStyle = getDominantAttachmentStyle(recentInteractions)
        let dominantCommunicationPattern = getDominantCommunicationPattern(recentInteractions)
        let problemAreas = identifyProblemAreas(recentInteractions)
        let strengths = identifyStrengths(recentInteractions)
        
        coachingData["dominant_attachment_style"] = dominantAttachmentStyle.rawValue
        coachingData["dominant_communication_pattern"] = dominantCommunicationPattern.rawValue
        coachingData["problem_areas"] = problemAreas
        coachingData["strengths"] = strengths
        coachingData["sample_size"] = recentInteractions.count
        coachingData["analysis_timestamp"] = Date().timeIntervalSince1970
        
        // Generate personalized recommendations
        let recommendations = generatePersonalizedRecommendations(
            attachmentStyle: dominantAttachmentStyle,
            communicationPattern: dominantCommunicationPattern,
            problemAreas: problemAreas
        )
        coachingData["personalized_recommendations"] = recommendations
        
        userDefaults.set(coachingData, forKey: "personalized_coaching_data")
    }
    
    /// Analyze dominant attachment style from recent interactions
    private func getDominantAttachmentStyle(_ interactions: [KeyboardInteraction]) -> AttachmentStyle {
        let styleCount = interactions.reduce(into: [AttachmentStyle: Int]()) { counts, interaction in
            if let style = interaction.attachmentStyleDetected {
                counts[style, default: 0] += 1
            }
        }
        
        return styleCount.max(by: { $0.value < $1.value })?.key ?? .unknown
    }
    
    /// Analyze dominant communication pattern from recent interactions
    private func getDominantCommunicationPattern(_ interactions: [KeyboardInteraction]) -> CommunicationPattern {
        let patternCount = interactions.reduce(into: [CommunicationPattern: Int]()) { counts, interaction in
            if let pattern = interaction.communicationPattern {
                counts[pattern, default: 0] += 1
            }
        }
        
        return patternCount.max(by: { $0.value < $1.value })?.key ?? .neutral
    }
    
    /// Identify problem areas from recent interactions
    private func identifyProblemAreas(_ interactions: [KeyboardInteraction]) -> [String] {
        var problemAreas: [String] = []
        
        let alertRate = Float(interactions.filter { $0.toneStatus == .alert }.count) / Float(max(interactions.count, 1))
        let acceptanceRate = Float(interactions.filter { $0.userAcceptedSuggestion }.count) / Float(max(interactions.count, 1))
        
        if alertRate > 0.3 {
            problemAreas.append("Frequent harsh or problematic tone")
        }
        
        if acceptanceRate < 0.2 {
            problemAreas.append("Low acceptance of AI suggestions")
        }
        
        let aggressiveCount = interactions.filter { $0.communicationPattern == .aggressive }.count
        if aggressiveCount > interactions.count / 4 {
            problemAreas.append("Aggressive communication pattern")
        }
        
        return problemAreas
    }
    
    /// Identify strengths from recent interactions
    private func identifyStrengths(_ interactions: [KeyboardInteraction]) -> [String] {
        var strengths: [String] = []
        
        let clearRate = Float(interactions.filter { $0.toneStatus == .clear }.count) / Float(max(interactions.count, 1))
        let acceptanceRate = Float(interactions.filter { $0.userAcceptedSuggestion }.count) / Float(max(interactions.count, 1))
        
        if clearRate > 0.6 {
            strengths.append("Consistently positive communication tone")
        }
        
        if acceptanceRate > 0.7 {
            strengths.append("Highly receptive to improvement suggestions")
        }
        
        let assertiveCount = interactions.filter { $0.communicationPattern == .assertive }.count
        if assertiveCount > interactions.count / 3 {
            strengths.append("Healthy assertive communication")
        }
        
        return strengths
    }
    
    /// Generate personalized recommendations for main app
    private func generatePersonalizedRecommendations(
        attachmentStyle: AttachmentStyle,
        communicationPattern: CommunicationPattern,
        problemAreas: [String]
    ) -> [String] {
        var recommendations: [String] = []
        
        // Attachment style specific recommendations
        switch attachmentStyle {
        case .anxious:
            recommendations.append("Practice pausing before responding to reduce anxiety-driven reactions")
            recommendations.append("Focus on expressing needs clearly rather than through emotional intensity")
        case .avoidant:
            recommendations.append("Work on expressing emotions more openly in conversations")
            recommendations.append("Try using 'I' statements to share your perspective")
        case .disorganized:
            recommendations.append("Take time to organize thoughts before responding")
            recommendations.append("Focus on one main point per message")
        case .secure:
            recommendations.append("Continue modeling healthy communication patterns")
        case .unknown:
            recommendations.append("Continue using the keyboard to identify your communication style")
        }
        
        // Communication pattern specific recommendations
        switch communicationPattern {
        case .aggressive:
            recommendations.append("Practice softening language to avoid escalation")
        case .passiveAggressive:
            recommendations.append("Try expressing concerns more directly")
        case .defensive:
            recommendations.append("Practice validating others' perspectives before responding")
        case .withdrawing:
            recommendations.append("Work on staying engaged in difficult conversations")
        default:
            break
        }
        
        // Problem area specific recommendations
        for problem in problemAreas {
            if problem.contains("harsh") {
                recommendations.append("Consider the emotional impact of your words on others")
            }
            if problem.contains("acceptance") {
                recommendations.append("Try being more open to AI coaching suggestions")
            }
        }
        
        return recommendations
    }
    
    /// Update main app with current keyboard session status
    func updateKeyboardSessionStatus(isActive: Bool) {
        var sessionStatus = userDefaults.dictionary(forKey: "keyboard_session_status") ?? [:]
        
        sessionStatus["is_active"] = isActive
        sessionStatus["last_update"] = Date().timeIntervalSince1970
        
        if isActive {
            sessionStatus["session_start"] = Date().timeIntervalSince1970
        } else {
            if let sessionStart = sessionStatus["session_start"] as? TimeInterval {
                let sessionDuration = Date().timeIntervalSince1970 - sessionStart
                sessionStatus["last_session_duration"] = sessionDuration
            }
        }
        
        userDefaults.set(sessionStatus, forKey: "keyboard_session_status")
    }
}
