//
//  KeyboardSuggestionManager.swift
//  Unsaid - Advanced AI-Powered Keyboard Extension
//
//  Created by John Gray on 7/7/25.
//
import Foundation
// If needed for color extensions:
#if canImport(UIKit)
import UIKit
#endif

class KeyboardSuggestionManager {
    static let shared = KeyboardSuggestionManager()
    private let settingsManager = KeyboardSettingsManager.shared
    
    weak var viewController: KeyboardViewController?
    private var currentSuggestionText: String = ""
    private var currentSuggestionFix: String = ""
    
    private init() {}
    
    // MARK: - Real-time Analysis
    func performRealTimeAnalysis(_ text: String) {
        // Simulate AI analysis (replace with actual AI integration)
        DispatchQueue.global(qos: .userInteractive).async {
            let analysisResult = self.analyzeText(text)
            
            DispatchQueue.main.async {
                self.updateUI(with: analysisResult)
            }
        }
    }
    
    private func analyzeText(_ text: String) -> (tone: ToneStatus, suggestion: String?, fix: String?) {
        // Simulate tone analysis based on text content
        let lowerText = text.lowercased()
        
        var tone: ToneStatus = .analyzing
        var suggestion: String?
        var fix: String?
        
        // Simple tone detection (replace with actual AI)
        if lowerText.contains("fuck") || lowerText.contains("shit") || lowerText.contains("damn") {
            tone = .alert
            suggestion = "Consider using more professional language"
            fix = text.replacingOccurrences(of: "fuck", with: "really dislike")
                     .replacingOccurrences(of: "shit", with: "stuff")
                     .replacingOccurrences(of: "damn", with: "really")
        } else if lowerText.contains("awesome") || lowerText.contains("great") || lowerText.contains("love") {
            tone = .clear
        } else if lowerText.contains("maybe") || lowerText.contains("might") || lowerText.contains("perhaps") {
            tone = .caution
            suggestion = "Consider being more definitive"
            fix = text.replacingOccurrences(of: "maybe", with: "I think")
                     .replacingOccurrences(of: "might", with: "will")
                     .replacingOccurrences(of: "perhaps", with: "I believe")
        } else {
            tone = .clear
        }
        
        return (tone, suggestion, fix)
    }
    
    private func updateUI(with result: (tone: ToneStatus, suggestion: String?, fix: String?)) {
        guard let viewController = viewController else { return }
        
        // Update tone indicator using the UI setup manager
        viewController.uiSetupManager?.showToneIndicator(status: result.tone)
        
        // Show suggestion if available
        if let suggestion = result.suggestion, let fix = result.fix {
            currentSuggestionText = suggestion
            currentSuggestionFix = fix
            viewController.uiSetupManager?.showSuggestion(text: suggestion, suggestedFix: fix)
        } else {
            viewController.uiSetupManager?.hideSuggestion()
        }
    }
    
    // MARK: - Suggestion Management
    
    func clearSuggestions() {
        guard let viewController = viewController else { return }
        viewController.uiSetupManager?.hideSuggestion()
        viewController.uiSetupManager?.hideToneIndicator()
    }
    
    func applySuggestion(_ suggestion: String) {
        guard let viewController = viewController else { return }
        
        // Apply the suggestion to the text document proxy
        if let proxy = viewController.textDocumentProxy as? UITextDocumentProxy {
            // Clear current text and insert the suggestion
            if let beforeInput = proxy.documentContextBeforeInput {
                // Delete the current text
                for _ in 0..<beforeInput.count {
                    proxy.deleteBackward()
                }
            }
            
            // Insert the improved text
            proxy.insertText(suggestion)
        }
        
        // Hide the suggestion after applying
        viewController.uiSetupManager?.hideSuggestion()
    }
    
    // MARK: - Personalized Suggestions
    
    /// Generate personalized suggestions based on user profile and real-time analysis
    func generatePersonalizedSuggestions(
        for text: String,
        toneStatus: ToneStatus,
        attachmentStyle: AttachmentStyle,
        communicationPattern: CommunicationPattern,
        relationshipContext: RelationshipContext
    ) -> [String] {
        // Get user's preferences and goals from main app
        let userAttachmentStyle = settingsManager.getUserAttachmentStyle()
        let communicationGoals = settingsManager.getUserCommunicationGoals()
        let priorityAreas = settingsManager.getPriorityImprovementAreas()
        let coachingSensitivity = settingsManager.getCoachingSensitivity()
        
        var suggestions: [String] = []
        
        // Base suggestions on tone analysis
        suggestions.append(contentsOf: getBaseToneSuggestions(for: toneStatus, text: text))
        
        // Add attachment style specific suggestions
        suggestions.append(contentsOf: getAttachmentStyleSuggestions(
            userStyle: userAttachmentStyle,
            detectedPattern: communicationPattern,
            relationshipContext: relationshipContext
        ))
        
        // Add personalized suggestions based on user goals
        suggestions.append(contentsOf: getGoalBasedSuggestions(
            goals: communicationGoals,
            currentText: text,
            toneStatus: toneStatus
        ))
        
        // Add priority area focused suggestions
        suggestions.append(contentsOf: getPriorityAreaSuggestions(
            areas: priorityAreas,
            currentText: text,
            toneStatus: toneStatus
        ))
        
        // Filter based on coaching sensitivity
        suggestions = filterSuggestionsBySensitivity(suggestions, sensitivity: coachingSensitivity)
        
        // Limit to most relevant suggestions
        return Array(suggestions.prefix(3))
    }
    
    /// Get base tone improvement suggestions
    private func getBaseToneSuggestions(for toneStatus: ToneStatus, text: String) -> [String] {
        switch toneStatus {
        case .alert:
            return [
                "Consider softening this message to avoid misunderstandings",
                "Try rephrasing with more empathy",
                "This might come across as harsh - consider a gentler approach"
            ]
        case .caution:
            return [
                "This message could be misinterpreted - consider clarifying",
                "Try adding a warmer tone to this message",
                "Consider the recipient's feelings when reading this"
            ]
        case .clear:
            return [
                "Great tone! This message is clear and friendly",
                "Your message has a positive, constructive tone"
            ]
        case .neutral:
            return [
                "Consider adding warmth to connect better",
                "Your message is clear - you could enhance it with more positivity"
            ]
        case .analyzing:
            return []
        }
    }
    
    /// Get attachment style specific suggestions
    private func getAttachmentStyleSuggestions(
        userStyle: AttachmentStyle,
        detectedPattern: CommunicationPattern,
        relationshipContext: RelationshipContext
    ) -> [String] {
        var suggestions: [String] = []
        
        // Suggestions based on user's known attachment style
        switch userStyle {
        case .anxious:
            if detectedPattern == .aggressive || detectedPattern == .pursuing {
                suggestions.append("Take a breath before sending - this might come from anxiety")
                suggestions.append("Consider if this urgency is necessary")
            }
        case .avoidant:
            if detectedPattern == .withdrawing || detectedPattern == .defensive {
                suggestions.append("Try being more direct about your needs")
                suggestions.append("Consider sharing your feelings more openly")
            }
        case .secure:
            suggestions.append("Your secure communication style is helpful - keep it up!")
        case .disorganized:
            suggestions.append("Focus on one main point to keep your message clear")
        default:
            break
        }
        
        // Context-specific suggestions
        if relationshipContext == .romantic && detectedPattern == .aggressive {
            suggestions.append("In romantic relationships, gentle communication builds stronger bonds")
        } else if relationshipContext == .professional && detectedPattern == .passiveAggressive {
            suggestions.append("Professional settings benefit from direct, respectful communication")
        }
        
        return suggestions
    }
    
    /// Get suggestions based on user's communication goals
    private func getGoalBasedSuggestions(
        goals: [String],
        currentText: String,
        toneStatus: ToneStatus
    ) -> [String] {
        var suggestions: [String] = []
        
        for goal in goals {
            switch goal.lowercased() {
            case "reduce anxiety":
                if toneStatus == .alert || toneStatus == .caution {
                    suggestions.append("This message might increase anxiety - consider a calmer approach")
                }
            case "improve empathy":
                if toneStatus != .clear {
                    suggestions.append("Try putting yourself in their shoes - how would you feel receiving this?")
                }
            case "be more direct":
                if currentText.count > 100 {
                    suggestions.append("Your goal is directness - try being more concise")
                }
            case "reduce conflict":
                if toneStatus == .alert {
                    suggestions.append("This might create conflict - consider a more collaborative tone")
                }
            default:
                break // Unknown goal, skip
            }
        }
        
        return suggestions
    }
    
    /// Get suggestions based on priority improvement areas
    private func getPriorityAreaSuggestions(
        areas: [String],
        currentText: String,
        toneStatus: ToneStatus
    ) -> [String] {
        var suggestions: [String] = []
        
        for area in areas {
            switch area.lowercased() {
            case "reduce harsh language":
                if toneStatus == .alert {
                    suggestions.append("🎯 Priority: Soften harsh language for better relationships")
                }
            case "improve emotional expression":
                if toneStatus == .neutral {
                    suggestions.append("🎯 Priority: Try expressing your emotions more openly")
                }
            case "reduce defensiveness":
                if currentText.lowercased().contains("but") || currentText.lowercased().contains("however") {
                    suggestions.append("🎯 Priority: Notice if you're being defensive - try validating first")
                }
            default:
                break // Unknown focus area, skip
            }
        }
        
        return suggestions
    }
    
    /// Filter suggestions based on coaching sensitivity
    private func filterSuggestionsBySensitivity(_ suggestions: [String], sensitivity: String) -> [String] {
        switch sensitivity {
        case "low":
            // Only show critical suggestions
            return suggestions.filter { $0.contains("harsh") || $0.contains("conflict") || $0.contains("🎯") }
        case "high":
            // Show all suggestions
            return suggestions
        default: // "medium"
            // Show most suggestions, filter out minor ones
            return suggestions.filter { !$0.contains("Great tone") && !$0.contains("keep it up") }
        }
    }
    
    // MARK: - Analysis Results
    
    struct PersonalizedSuggestion {
        let text: String
        let fix: String
        let toneStatus: ToneStatus
        let priority: Int
    }
    
    /// Perform personalized real-time analysis
    func performPersonalizedAnalysis(_ text: String) -> [PersonalizedSuggestion] {
        // Analyze tone and communication patterns
        let toneStatus = analyzeTone(text)
        let attachmentStyle = analyzeAttachmentStyle(text)
        let communicationPattern = analyzeCommunicationPattern(text)
        let relationshipContext = analyzeRelationshipContext(text)
        
        // Generate personalized suggestions
        let suggestions = generatePersonalizedSuggestions(
            for: text,
            toneStatus: toneStatus,
            attachmentStyle: attachmentStyle,
            communicationPattern: communicationPattern,
            relationshipContext: relationshipContext
        )
        
        // Convert to PersonalizedSuggestion objects with fixes
        return suggestions.enumerated().map { index, suggestion in
            PersonalizedSuggestion(
                text: suggestion,
                fix: generateFix(for: text, suggestion: suggestion, toneStatus: toneStatus),
                toneStatus: toneStatus,
                priority: index
            )
        }
    }
    
    /// Generate a fix for the current text based on the suggestion
    private func generateFix(for text: String, suggestion: String, toneStatus: ToneStatus) -> String {
        // Simple fix generation - in a real app, this would be more sophisticated
        switch toneStatus {
        case .alert:
            return softenHarshLanguage(text)
        case .caution:
            return addWarmth(text)
        case .neutral:
            return addPositivity(text)
        case .clear:
            return text // Already good
        case .analyzing:
            return text
        }
    }
    
    /// Soften harsh language in text
    private func softenHarshLanguage(_ text: String) -> String {
        var softened = text
        
        // Replace harsh words with gentler alternatives
        let harshReplacements = [
            "stupid": "confusing",
            "ridiculous": "surprising",
            "awful": "challenging",
            "terrible": "difficult",
            "hate": "dislike",
            "never": "rarely",
            "always": "often",
            "you're wrong": "I see it differently",
            "that's not right": "I have a different perspective"
        ]
        
        for (harsh, gentle) in harshReplacements {
            softened = softened.replacingOccurrences(of: harsh, with: gentle, options: .caseInsensitive)
        }
        
        return softened
    }
    
    /// Add warmth to neutral text
    private func addWarmth(_ text: String) -> String {
        if text.hasSuffix(".") {
            return text.replacingOccurrences(of: ".", with: " 😊")
        }
        return text + " 😊"
    }
    
    /// Add positivity to text
    private func addPositivity(_ text: String) -> String {
        if text.isEmpty { return text }
        
        let positiveStarters = ["I appreciate", "Thank you for", "I'm glad", "It's great that"]
        let randomStarter = positiveStarters.randomElement() ?? "I appreciate"
        
        return "\(randomStarter) your message. \(text)"
    }
    
    // MARK: - Analysis Methods
    
    /// Analyze tone of text
    private func analyzeTone(_ text: String) -> ToneStatus {
        let lowercaseText = text.lowercased()
        
        // Check for harsh language
        let harshWords = ["stupid", "ridiculous", "awful", "terrible", "hate", "never", "always"]
        if harshWords.contains(where: lowercaseText.contains) {
            return .alert
        }
        
        // Check for potentially problematic language
        let cautionWords = ["urgent", "immediately", "now", "asap", "quickly"]
        if cautionWords.contains(where: lowercaseText.contains) {
            return .caution
        }
        
        // Check for positive language
        let positiveWords = ["please", "thank", "appreciate", "great", "wonderful", "love"]
        if positiveWords.contains(where: lowercaseText.contains) {
            return .clear
        }
        
        return .neutral
    }
    
    /// Analyze attachment style patterns in text
    private func analyzeAttachmentStyle(_ text: String) -> AttachmentStyle {
        let lowercaseText = text.lowercased()
        
        // Anxious patterns
        if lowercaseText.contains("urgent") || lowercaseText.contains("immediately") || lowercaseText.contains("need to talk") {
            return .anxious
        }
        
        // Avoidant patterns
        if lowercaseText.contains("fine") || lowercaseText.contains("whatever") || lowercaseText.contains("don't care") {
            return .avoidant
        }
        
        // Secure patterns
        if lowercaseText.contains("understand") || lowercaseText.contains("feel") || lowercaseText.contains("appreciate") {
            return .secure
        }
        
        return .unknown
    }
    
    /// Analyze communication pattern
    private func analyzeCommunicationPattern(_ text: String) -> CommunicationPattern {
        let lowercaseText = text.lowercased()
        
        // Aggressive patterns
        if lowercaseText.contains("you always") || lowercaseText.contains("you never") {
            return .aggressive
        }
        
        // Passive aggressive patterns
        if lowercaseText.contains("fine") || lowercaseText.contains("whatever") {
            return .passiveAggressive
        }
        
        // Assertive patterns
        if lowercaseText.contains("I feel") || lowercaseText.contains("I need") {
            return .assertive
        }
        
        // Defensive patterns
        if lowercaseText.contains("but") || lowercaseText.contains("however") {
            return .defensive
        }
        
        return .neutral
    }
    
    /// Analyze relationship context
    private func analyzeRelationshipContext(_ text: String) -> RelationshipContext {
        let lowercaseText = text.lowercased()
        
        // Professional context
        if lowercaseText.contains("meeting") || lowercaseText.contains("project") || lowercaseText.contains("deadline") {
            return .professional
        }
        
        // Romantic context
        if lowercaseText.contains("love") || lowercaseText.contains("miss") || lowercaseText.contains("honey") {
            return .romantic
        }
        
        // Family context
        if lowercaseText.contains("mom") || lowercaseText.contains("dad") || lowercaseText.contains("family") {
            return .family
        }
        
        return .unknown
    }
    
    // MARK: - Real-time Data Sharing
    
    /// Record user interaction with personalized suggestions for main app analytics
    func recordSuggestionInteraction(
        originalText: String,
        suggestion: String,
        wasAccepted: Bool,
        toneStatus: ToneStatus,
        attachmentStyle: AttachmentStyle,
        communicationPattern: CommunicationPattern,
        relationshipContext: RelationshipContext
    ) {
        let userDefaults = UserDefaults(suiteName: "group.com.unsaid.shared")
        
        let interaction = [
            "timestamp": Date().timeIntervalSince1970,
            "original_text_length": originalText.count,
            "suggestion": suggestion,
            "was_accepted": wasAccepted,
            "tone_status": toneStatus.rawValue,
            "attachment_style": attachmentStyle.rawValue,
            "communication_pattern": communicationPattern.rawValue,
            "relationship_context": relationshipContext.rawValue,
            "user_response_time": getCurrentResponseTime()
        ] as [String: Any]
        
        // Add to suggestion interactions array
        var interactions = userDefaults?.array(forKey: "suggestion_interactions") as? [[String: Any]] ?? []
        interactions.append(interaction)
        
        // Keep only recent interactions
        if interactions.count > 500 {
            interactions.removeFirst()
        }
        
        userDefaults?.set(interactions, forKey: "suggestion_interactions")
        
        // Update real-time analytics
        updateRealTimeAnalytics(wasAccepted: wasAccepted, toneStatus: toneStatus)
    }
    
    /// Update real-time analytics for main app dashboard
    private func updateRealTimeAnalytics(wasAccepted: Bool, toneStatus: ToneStatus) {
        let userDefaults = UserDefaults(suiteName: "group.com.unsaid.shared")
        var analytics = userDefaults?.dictionary(forKey: "real_time_analytics") ?? [:]
        
        // Update acceptance rate
        let totalSuggestions = (analytics["total_suggestions"] as? Int ?? 0) + 1
        let acceptedSuggestions = (analytics["accepted_suggestions"] as? Int ?? 0) + (wasAccepted ? 1 : 0)
        let acceptanceRate = Float(acceptedSuggestions) / Float(totalSuggestions)
        
        analytics["total_suggestions"] = totalSuggestions
        analytics["accepted_suggestions"] = acceptedSuggestions
        analytics["acceptance_rate"] = acceptanceRate
        analytics["last_update"] = Date().timeIntervalSince1970
        
        // Update tone distribution
        var toneDistribution = analytics["tone_distribution"] as? [String: Int] ?? [:]
        toneDistribution[toneStatus.rawValue, default: 0] += 1
        analytics["tone_distribution"] = toneDistribution
        
        // Calculate improvement trend
        let recentAlerts = toneDistribution["alert"] ?? 0
        let recentClears = toneDistribution["clear"] ?? 0
        let improvementScore = Float(recentClears) / Float(max(recentAlerts + recentClears, 1))
        analytics["improvement_score"] = improvementScore
        
        userDefaults?.set(analytics, forKey: "real_time_analytics")
    }
    
    /// Get current response time for analytics
    private func getCurrentResponseTime() -> TimeInterval {
        // This would track how long it took user to respond to suggestion
        // For now, return a placeholder
        return 0.0
    }
    
    /// Push user behavior patterns to main app for personalized coaching
    func pushBehaviorPatterns() {
        let userDefaults = UserDefaults(suiteName: "group.com.unsaid.shared")
        
        // Analyze recent interactions to identify patterns
        let interactions = userDefaults?.array(forKey: "suggestion_interactions") as? [[String: Any]] ?? []
        let recentInteractions = Array(interactions.suffix(50))
        
        var behaviorPatterns: [String: Any] = [:]
        
        // Analyze acceptance patterns
        let acceptedCount = recentInteractions.filter { $0["was_accepted"] as? Bool == true }.count
        let acceptanceRate = Float(acceptedCount) / Float(max(recentInteractions.count, 1))
        behaviorPatterns["recent_acceptance_rate"] = acceptanceRate
        
        // Analyze tone patterns
        let toneFrequency = recentInteractions.reduce(into: [String: Int]()) { counts, interaction in
            if let tone = interaction["tone_status"] as? String {
                counts[tone, default: 0] += 1
            }
        }
        behaviorPatterns["tone_frequency"] = toneFrequency
        
        // Analyze attachment style patterns
        let attachmentFrequency = recentInteractions.reduce(into: [String: Int]()) { counts, interaction in
            if let style = interaction["attachment_style"] as? String {
                counts[style, default: 0] += 1
            }
        }
        behaviorPatterns["attachment_frequency"] = attachmentFrequency
        
        // Analyze communication patterns
        let communicationFrequency = recentInteractions.reduce(into: [String: Int]()) { counts, interaction in
            if let pattern = interaction["communication_pattern"] as? String {
                counts[pattern, default: 0] += 1
            }
        }
        behaviorPatterns["communication_frequency"] = communicationFrequency
        
        // Analyze relationship context patterns
        let contextFrequency = recentInteractions.reduce(into: [String: Int]()) { counts, interaction in
            if let context = interaction["relationship_context"] as? String {
                counts[context, default: 0] += 1
            }
        }
        behaviorPatterns["context_frequency"] = contextFrequency
        
        behaviorPatterns["analysis_timestamp"] = Date().timeIntervalSince1970
        behaviorPatterns["sample_size"] = recentInteractions.count
        
        userDefaults?.set(behaviorPatterns, forKey: "user_behavior_patterns")
    }
    
    /// Get personalized coaching recommendations from main app
    func getPersonalizedCoachingRecommendations() -> [String] {
        let userDefaults = UserDefaults(suiteName: "group.com.unsaid.shared")
        
        if let recommendations = userDefaults?.array(forKey: "personalized_coaching_recommendations") as? [String] {
            return recommendations
        }
        
        return []
    }
    
    /// Update main app with current keyboard session data
    func updateSessionData() {
        let userDefaults = UserDefaults(suiteName: "group.com.unsaid.shared")
        
        var sessionData = userDefaults?.dictionary(forKey: "current_keyboard_session") ?? [:]
        
        sessionData["last_active"] = Date().timeIntervalSince1970
        sessionData["suggestions_shown"] = (sessionData["suggestions_shown"] as? Int ?? 0) + 1
        sessionData["is_active"] = true
        
        userDefaults?.set(sessionData, forKey: "current_keyboard_session")
    }
    
    /// Notify main app of keyboard usage for real-time dashboard updates
    func notifyMainAppOfActivity() {
        let userDefaults = UserDefaults(suiteName: "group.com.unsaid.shared")
        
        let activityData = [
            "timestamp": Date().timeIntervalSince1970,
            "activity_type": "keyboard_usage",
            "suggestions_count": currentSuggestionText.isEmpty ? 0 : 1
        ] as [String: Any]
        
        var activities = userDefaults?.array(forKey: "keyboard_activities") as? [[String: Any]] ?? []
        activities.append(activityData)
        
        // Keep only recent activities
        if activities.count > 100 {
            activities.removeFirst()
        }
        
        userDefaults?.set(activities, forKey: "keyboard_activities")
    }
}
