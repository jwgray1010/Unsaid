//
//  AdvancedSuggestionsEngine.swift
//  UnsaidKeyboard
//
//  Advanced suggestion generation engine for Unsaid
//  Handles all types of suggestions: tone-based, attachment-aware, cross-style, contextual
//
//  Created by Modularization Refactor on 7/11/25.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Advanced Suggestions Engine
class AdvancedSuggestionsEngine {
    
    // MARK: - Dependencies
    private let toneAnalysisEngine: AdvancedToneAnalysisEngine
    private let aiPredictiveEngine: AIPredictiveEngine // ✨ NEW: AI integration
    
    // MARK: - Personality Data Integration
    private let personalityManager: PersonalityDataManager
    
    /// User attachment style from comprehensive personality data
    private var userAttachmentStyle: AttachmentStyle {
        get {
            if let attachmentStyleString = personalityManager.getAttachmentStyle() {
                return AttachmentStyle(rawValue: attachmentStyleString) ?? .unknown
            }
            return .unknown
        }
    }
    
    /// Partner attachment style (fallback to UserDefaults for now)
    private var partnerAttachmentStyle: AttachmentStyle {
        get {
            let userDefaults = UserDefaults(suiteName: "group.com.unsaid.shared")
            if let partnerStyleString = userDefaults?.string(forKey: "partner_attachment_style") {
                return AttachmentStyle(rawValue: partnerStyleString) ?? .unknown
            }
            return .unknown
        }
        set {
            let userDefaults = UserDefaults(suiteName: "group.com.unsaid.shared")
            userDefaults?.set(newValue.rawValue, forKey: "partner_attachment_style")
        }
    }
    
    /// Relationship context from comprehensive personality data
    private var storedRelationshipContext: RelationshipContext {
        get {
            let userDefaults = UserDefaults(suiteName: "group.com.unsaid.shared")
            if let contextString = userDefaults?.string(forKey: "relationship_context") {
                return RelationshipContext(rawValue: contextString) ?? .unknown
            }
            return .unknown
        }
        set {
            let userDefaults = UserDefaults(suiteName: "group.com.unsaid.shared")
            userDefaults?.set(newValue.rawValue, forKey: "relationship_context")
        }
    }
    
    // MARK: - Initialization
    init(toneAnalysisEngine: AdvancedToneAnalysisEngine) {
        self.toneAnalysisEngine = toneAnalysisEngine
        self.aiPredictiveEngine = AIPredictiveEngine() // ✨ NEW: Initialize AI engine
        self.personalityManager = PersonalityDataManager.shared // ✨ NEW: Initialize personality manager
    }
    
    // MARK: - Main Suggestion Generation
    func generateSuggestions(for text: String) -> [String] {
        let toneStatus = toneAnalysisEngine.analyzeTone(text)
        let attachmentStyle = toneAnalysisEngine.detectAttachmentStyle(text)
        let communicationPattern = toneAnalysisEngine.detectAdvancedCommunicationPattern(text)
        let relationshipContext = toneAnalysisEngine.detectRelationshipContext(text)

        var suggestions: [String] = []
        
        // Add suggestions from different analysis categories
        suggestions.append(contentsOf: generateToneSuggestions(for: toneStatus))
        suggestions.append(contentsOf: generateAttachmentStyleSuggestions(for: attachmentStyle, text: text))
        suggestions.append(contentsOf: generateCommunicationPatternSuggestions(for: communicationPattern))
        suggestions.append(contentsOf: generateRelationshipContextSuggestions(for: relationshipContext))
        suggestions.append(contentsOf: generateRepairStrategies(for: toneStatus, pattern: communicationPattern))

        return suggestions
    }
    
    // MARK: - Advanced Suggestion Generation
    func generateAdvancedSuggestions(
        for currentText: String,
        toneStatus: ToneStatus,
        conversationContext: String? = nil
    ) -> [AdvancedSuggestion] {
        var suggestions: [AdvancedSuggestion] = []

        // 1. Basic tone-based suggestions
        suggestions.append(contentsOf: generateAdvancedToneSuggestions(currentText, toneStatus))

        // 2. Attachment-style specific suggestions
        suggestions.append(contentsOf: generateAttachmentSpecificSuggestions(currentText))

        // 3. Cross-attachment style communication
        if userAttachmentStyle != .unknown && partnerAttachmentStyle != .unknown {
            suggestions.append(contentsOf: generateAdvancedCrossStyleSuggestions(currentText))
        }

        // 4. Conversation context-aware suggestions
        if let context = conversationContext {
            suggestions.append(contentsOf: generateContextAwareSuggestions(currentText, context, toneStatus))
        }

        // Sort by priority and return top suggestions
        return Array(suggestions.sorted { $0.priority.rawValue < $1.priority.rawValue }.prefix(5))
    }
    
    // MARK: - Tone-Based Suggestions
    private func generateToneSuggestions(for toneStatus: ToneStatus) -> [String] {
        switch toneStatus {
        case .alert:
            return [
                "This message might feel hurtful to the receiver",
                "Consider taking a pause before sending"
            ]
        case .caution:
            return [
                "This could come across as demanding",
                "Try softening with 'please' or 'when you can'"
            ]
        case .clear:
            return ["Great! This sounds supportive and clear"]
        
        case .analyzing:
            return ["Consider adding warmth to your message"]

        case .neutral:
            return []
        }
    }
    
    private func generateAdvancedToneSuggestions(_ text: String, _ status: ToneStatus) -> [AdvancedSuggestion] {
        var suggestions: [AdvancedSuggestion] = []

        switch status {
        case .alert:
            suggestions.append(AdvancedSuggestion(
                text: "This message might feel hurtful. Consider taking a pause before sending",
                type: .toneImprovement,
                priority: .critical,
                attachmentStyleSpecific: false,
                repairScript: "I'm feeling really upset right now. Can we talk about this when I'm calmer?",
                reasoning: "Alert tone detected with potential for escalation"
            ))

        case .caution:
            suggestions.append(AdvancedSuggestion(
                text: "This could come across as demanding. Try softening with 'please' or 'when you can'",
                type: .toneImprovement,
                priority: .high,
                attachmentStyleSpecific: false,
                repairScript: text.replacingOccurrences(of: "must", with: "could you please"),
                reasoning: "Caution tone detected - could be perceived as demanding"
            ))

        case .clear:
            suggestions.append(AdvancedSuggestion(
                text: "Great! This sounds supportive and clear 💚",
                type: .toneImprovement,
                priority: .low,
                attachmentStyleSpecific: false,
                repairScript: nil,
                reasoning: "Clear, positive tone detected"
            ))

        case .analyzing:
            suggestions.append(AdvancedSuggestion(
                text: "Consider adding warmth to your message",
                type: .toneImprovement,
                priority: .medium,
                attachmentStyleSpecific: false,
                repairScript: "I hope you're doing well. " + text,
                reasoning: "Message could benefit from more warmth"
            ))
            
        case .neutral:
            break
        }

        return suggestions
    }
    
    // MARK: - Attachment Style Suggestions
    private func generateAttachmentStyleSuggestions(for attachmentStyle: AttachmentStyle, text: String) -> [String] {
        var suggestions: [String] = []
        
        switch attachmentStyle {
        case .anxious:
            suggestions.append("💭 Anxious pattern detected")
            if text.lowercased().contains("always") || text.lowercased().contains("never") {
                suggestions.append("Try: 'Sometimes I feel...' instead of 'You always/never...'")
            }
            if text.lowercased().contains("leaving") || text.lowercased().contains("abandon") {
                suggestions.append("Consider: 'I'm feeling insecure and need reassurance'")
            }
            suggestions.append("Remember: Express your need for connection clearly")

        case .avoidant:
            suggestions.append("🚶 Avoidant pattern detected")
            if text.lowercased().contains("space") || text.lowercased().contains("distance") {
                suggestions.append("Try: 'I need time to process, can we reconnect in [timeframe]?'")
            }
            if text.lowercased().contains("clingy") || text.lowercased().contains("needy") {
                suggestions.append("Consider: 'I'm feeling overwhelmed and need to recharge'")
            }
            suggestions.append("Remember: Your partner needs to understand your processing style")

        case .disorganized:
            suggestions.append("🌪️ Complex emotions detected")
            suggestions.append("Consider: Break down what you're feeling into smaller parts")
            suggestions.append("Try: 'I'm having mixed feelings about this'")
            suggestions.append("Remember: It's okay to feel confused - communicate that too")

        case .secure:
            suggestions.append("✅ Secure communication pattern!")
            suggestions.append("You're expressing yourself clearly and considerately")

        case .unknown:
            break
        }
        
        return suggestions
    }
    
    private func generateAttachmentSpecificSuggestions(_ text: String) -> [AdvancedSuggestion] {
        var suggestions: [AdvancedSuggestion] = []
        let detectedStyle = toneAnalysisEngine.detectAttachmentStyle(text)

        switch detectedStyle {
        case .anxious:
            if text.lowercased().contains("always") || text.lowercased().contains("never") {
                suggestions.append(AdvancedSuggestion(
                    text: "💭 Anxious pattern: Try 'sometimes' instead of 'always/never'",
                    type: .attachmentAware,
                    priority: .high,
                    attachmentStyleSpecific: true,
                    repairScript: text.replacingOccurrences(of: "always", with: "sometimes")
                        .replacingOccurrences(of: "never", with: "rarely"),
                    reasoning: "Anxious attachment pattern detected with absolute language"
                ))
            }

            if text.lowercased().contains("are you mad") {
                suggestions.append(AdvancedSuggestion(
                    text: "Instead of asking if they're mad, try expressing your feelings",
                    type: .attachmentAware,
                    priority: .critical,
                    attachmentStyleSpecific: true,
                    repairScript: "I'm sensing some distance and wondering if we can talk about it",
                    reasoning: "Anxious attachment seeking reassurance through indirect questioning"
                ))
            }

        case .avoidant:
            if text.lowercased().contains("need space") {
                suggestions.append(AdvancedSuggestion(
                    text: "🚶 Avoidant pattern: Let them know when you'll reconnect",
                    type: .attachmentAware,
                    priority: .high,
                    attachmentStyleSpecific: true,
                    repairScript: "I need some time to process this. Can we talk again in [specific timeframe]?",
                    reasoning: "Avoidant attachment requesting space without timeline"
                ))
            }

        case .disorganized:
            suggestions.append(AdvancedSuggestion(
                text: "🌪️ Complex emotions detected. Try breaking down your feelings",
                type: .emotionalRegulation,
                priority: .high,
                attachmentStyleSpecific: true,
                repairScript: "I'm having mixed feelings about this. Can we talk through this step by step?",
                reasoning: "Disorganized attachment with complex emotional state"
            ))

        case .secure:
            suggestions.append(AdvancedSuggestion(
                text: "✅ Secure communication! You're expressing yourself clearly",
                type: .attachmentAware,
                priority: .low,
                attachmentStyleSpecific: true,
                repairScript: nil,
                reasoning: "Secure attachment communication detected"
            ))

        case .unknown:
            break
        }

        return suggestions
    }
    
    // MARK: - Communication Pattern Suggestions
    private func generateCommunicationPatternSuggestions(for communicationPattern: CommunicationPattern) -> [String] {
        switch communicationPattern {
        case .aggressive:
            return [
                "⚠️ Aggressive tone detected",
                "Focus on the behavior, not attacking the person",
                "Try: 'When [behavior], I feel [emotion] because [reason]'"
            ]
        case .passiveAggressive:
            return [
                "😤 Passive-aggressive tone detected",
                "Consider being direct about what you need",
                "Try: 'I feel frustrated when...' instead of 'Fine, whatever'"
            ]
        case .defensive:
            return [
                "🛡️ Defensive response detected",
                "Try acknowledging their perspective first",
                "Consider: 'I can see why you'd feel that way...'"
            ]
        case .withdrawing:
            return [
                "🚶 Withdrawing pattern detected",
                "Let them know when you'll be ready to reconnect",
                "Try: 'I need [time] to process, then let's talk'"
            ]
        case .pursuing:
            return [
                "🏃 Pursuing pattern detected",
                "Give them space to respond in their own time",
                "Consider: One message and then wait for their response"
            ]
        case .assertive:
            return ["✅ Assertive communication - well done!"]
        case .neutral:
            return []
        }
    }
    
    // MARK: - Relationship Context Suggestions
    private func generateRelationshipContextSuggestions(for relationshipContext: RelationshipContext) -> [String] {
        switch relationshipContext {
        case .romantic:
            return ["💕 In romantic relationships: vulnerability builds intimacy"]
        case .family:
            return ["👨‍👩‍👧‍👦 Family dynamics: respect boundaries while staying connected"]
        case .professional:
            return ["💼 Professional context: maintain boundaries and clarity"]
        case .friendship:
            return ["👫 Friendships thrive on mutual support and understanding"]
        case .acquaintance:
            return ["🤝 Keep communication respectful and clear"]
        case .unknown:
            return []
        }
    }
    
    // MARK: - Repair Strategies
    private func generateRepairStrategies(for toneStatus: ToneStatus, pattern: CommunicationPattern) -> [String] {
        if toneStatus == .alert || pattern == .aggressive {
            return ["🔧 Repair strategy: 'I'm sorry, let me try that again...'"]
        }
        return []
    }
    
    // MARK: - Cross-Style Communication Suggestions
    private func generateAdvancedCrossStyleSuggestions(_ text: String) -> [AdvancedSuggestion] {
        let suggestion: String

        switch (userAttachmentStyle, partnerAttachmentStyle) {
        case (.anxious, .avoidant):
            suggestion = "Your partner is avoidant - give them space while expressing your needs clearly"

        case (.avoidant, .anxious):
            suggestion = "Your partner is anxious - reassure them you're not pulling away permanently"

        case (.anxious, .anxious):
            suggestion = "You're both anxious - take turns expressing needs without overwhelming each other"

        case (.avoidant, .avoidant):
            suggestion = "You're both avoidant - one of you needs to reach out first"

        default:
            suggestion = "Focus on expressing your needs clearly while acknowledging their perspective"
        }

        return [AdvancedSuggestion(
            text: suggestion,
            type: .crossStyleCommunication,
            priority: .high,
            attachmentStyleSpecific: true,
            repairScript: nil,
            reasoning: "Cross-attachment style communication guidance"
        )]
    }
    
    func generateCrossStyleSuggestion(senderStyle: AttachmentStyle, receiverStyle: AttachmentStyle) -> String {
        switch (senderStyle, receiverStyle) {
        case (.anxious, .avoidant):
            return "Try: 'I understand you need space. Could you let me know when you'll be ready to talk? That would help me feel more secure.'"

        case (.avoidant, .anxious):
            return "Try: 'I need some time to process this, but I want you to know I'm not pulling away from you. Can we reconnect in [timeframe]?'"

        case (.anxious, .anxious):
            return "Try: 'We're both feeling triggered. Let's take a moment to breathe and then share what we each need right now.'"

        case (.avoidant, .avoidant):
            return "Try: 'I think we're both retreating. One of us needs to reach out first - I'll start. How are you feeling about this?'"

        case (.disorganized, _):
            return "Try: 'I'm feeling overwhelmed by my emotions right now. Can you help me slow down and talk through this step by step?'"

        case (_, .disorganized):
            return "Try: 'I can see this is bringing up a lot for you. Let's take it slow and focus on one feeling at a time.'"

        default:
            return "Focus on expressing your needs clearly while acknowledging their perspective."
        }
    }
    
    // MARK: - Context-Aware Suggestions
    private func generateContextAwareSuggestions(_ text: String, _ context: String, _ status: ToneStatus) -> [AdvancedSuggestion] {
        var suggestions: [AdvancedSuggestion] = []

        // Analyze context for previous messages
        let contextLower = context.lowercased()

        // If previous message seemed upset
        if contextLower.contains("upset") || contextLower.contains("angry") || contextLower.contains("frustrated") {
            suggestions.append(AdvancedSuggestion(
                text: "They seem upset. Consider acknowledging their feelings first",
                type: .conversationRepair,
                priority: .critical,
                attachmentStyleSpecific: false,
                repairScript: "I can see this is really affecting you. Help me understand what you need.",
                reasoning: "Partner appears emotionally distressed based on context"
            ))
        }

        // If they asked for space
        if contextLower.contains("space") || contextLower.contains("time") {
            suggestions.append(AdvancedSuggestion(
                text: "They asked for space. Respect that and check in later",
                type: .conversationRepair,
                priority: .critical,
                attachmentStyleSpecific: false,
                repairScript: "I respect that you need space. I'll check in with you later.",
                reasoning: "Partner has explicitly requested space or time"
            ))
        }

        // If conversation is escalating
        if status == .alert && (contextLower.contains("wrong") || contextLower.contains("fault")) {
            suggestions.append(AdvancedSuggestion(
                text: "Conversation is escalating. Consider taking a pause",
                type: .conflictDeescalation,
                priority: .critical,
                attachmentStyleSpecific: false,
                repairScript: "I can feel this getting heated. Can we take a pause and come back to this when we're calmer?",
                reasoning: "Escalation detected with blame language present"
            ))
        }

        return suggestions
    }
    
    // MARK: - Repair Scripts
    func generateRepairScript(for attachmentStyle: AttachmentStyle, context: String = "") -> String {
        switch attachmentStyle {
        case .anxious:
            return "I'm feeling insecure right now and I need some reassurance. Can you help me understand where we stand?"

        case .avoidant:
            return "I'm feeling a bit overwhelmed and need some time to process. Can we reconnect in [specific timeframe] to talk about this?"

        case .disorganized:
            return "I'm having some conflicting feelings right now and I'm not sure how to express them. Can you be patient with me while I figure this out?"

        case .secure:
            return "I feel [emotion] when [situation]. I need [specific need]. How can we work together on this?"

        case .unknown:
            return "I'd like to talk about this when we're both calm and can really listen to each other."
        }
    }
    
    // MARK: - De-escalation Suggestions
    func generateDeescalationSuggestion(_ text: String) -> String? {
        let toneStatus = toneAnalysisEngine.analyzeTone(text)
        let attachmentStyle = toneAnalysisEngine.detectAttachmentStyle(text)

        if toneStatus == .alert || toneStatus == .caution {
            switch attachmentStyle {
            case .anxious:
                return "Try: 'I'm feeling overwhelmed. Can we take a breath together and start over?'"
            case .avoidant:
                return "Try: 'I need a moment to collect my thoughts. Can we pause and come back to this?'"
            case .disorganized:
                return "Try: 'This is bringing up a lot for me. Can we slow down and talk about one thing at a time?'"
            case .secure:
                return "Try: 'I can feel this getting heated. Let's both take a step back and try again.'"
            case .unknown:
                return "Try: 'I think we both care about this. Can we approach it from a place of love?'"
            }
        }

        return nil
    }
    
    // MARK: - Mindfulness Prompts
    func generateMindfulnessPrompt(_ text: String) -> String {
        let emotions = toneAnalysisEngine.detectEmotionalState(text)

        if emotions.contains("anger") {
            return "Take 3 deep breaths. What's underneath this anger? What do you really need right now?"
        } else if emotions.contains("fear") {
            return "Notice your body. What would help you feel safer in this conversation?"
        } else if emotions.contains("sadness") {
            return "What would compassion look like in this moment - for both you and them?"
        } else {
            return "Pause. What outcome do you really want from this conversation?"
        }
    }
    
    // MARK: - Auto-Fix Generation
    func generateAutoFix(for text: String, toneStatus: ToneStatus) -> String {
        var improvedText = text

        // Basic improvements
        switch toneStatus {
        case .alert:
            // Replace harsh words
            improvedText = improvedText.replacingOccurrences(of: "stupid", with: "unclear")
            improvedText = improvedText.replacingOccurrences(of: "hate", with: "don't like")
            improvedText = improvedText.replacingOccurrences(of: "terrible", with: "challenging")

        case .caution:
            // Soften demanding words
            improvedText = improvedText.replacingOccurrences(of: "must", with: "could you please")
            improvedText = improvedText.replacingOccurrences(of: "should", with: "it might be good to")
            improvedText = improvedText.replacingOccurrences(of: "need to", with: "would you mind")

        default:
            break
        }

        // Attachment-aware improvements
        if userAttachmentStyle != .unknown {
            improvedText = applyAttachmentAwareImprovements(improvedText)
        }

        return improvedText
    }

    private func applyAttachmentAwareImprovements(_ text: String) -> String {
        var improved = text

        switch userAttachmentStyle {
        case .anxious:
            // Replace absolute terms
            improved = improved.replacingOccurrences(of: "always", with: "often")
            improved = improved.replacingOccurrences(of: "never", with: "rarely")

            // Add "I feel" framing if not present
            if !improved.lowercased().contains("i feel") {
                improved = "I feel like " + improved
            }

        case .avoidant:
            // Add timeline for space requests
            if improved.lowercased().contains("need space") {
                improved = improved.replacingOccurrences(
                    of: "need space",
                    with: "need some time to process. Can we reconnect in [timeframe]?"
                )
            }

        case .disorganized:
            // Add structure to complex emotions
            if !improved.lowercased().contains("i'm having") {
                improved = "I'm having mixed feelings about this. " + improved
            }

        default:
            break
        }

        return improved
    }
    
    // MARK: - Text Improvements
    func generateSimpleImprovement(for text: String, status: ToneStatus) -> String {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else { return text }

        switch status {
        case .alert:
            return improveAlertTone(text: trimmedText)
        case .caution:
            return improveCautionTone(text: trimmedText)
        case .clear:
            return text // No improvement needed
        case .analyzing:
            return text // No improvement for analyzing status
        case .neutral:
            return text // No improvement for neutral status
        }
    }

    private func improveAlertTone(text: String) -> String {
        var improvedText = text

        // Enhanced harsh words with attachment-style awareness
        let harshWords = [
            // Basic harsh words
            "stupid": "unclear",
            "ridiculous": "unusual",
            "hate": "don't like",
            "terrible": "challenging",
            "awful": "difficult",
            "worst": "least preferred",
            "pathetic": "concerning",
            "useless": "not helpful",

            // Anxious attachment triggers
            "always": "often",
            "never": "rarely",
            "abandon": "leave",
            "reject": "not choose",
            "ignore": "not respond to",

            // Avoidant attachment triggers
            "clingy": "affectionate",
            "needy": "seeking connection",
            "demanding": "requesting",
            "suffocating": "close",

            // Disorganized attachment triggers
            "crazy": "confusing",
            "unstable": "unpredictable",
            "chaotic": "complex",
            "overwhelming": "intense",
        ]

        for (harsh, soft) in harshWords {
            improvedText = improvedText.replacingOccurrences(
                of: harsh,
                with: soft,
                options: .caseInsensitive
            )
        }

        // Add softening phrases with attachment awareness
        if !improvedText.contains("I feel") && !improvedText.contains("I think") && !improvedText.contains("I notice") {
            let attachmentStyle = toneAnalysisEngine.detectAttachmentStyle(improvedText)
            switch attachmentStyle {
            case .anxious:
                improvedText = "I'm feeling " + improvedText
            case .avoidant:
                improvedText = "I think " + improvedText
            case .disorganized:
                improvedText = "I notice " + improvedText
            default:
                improvedText = "I feel like " + improvedText
            }
        }

        return improvedText
    }

    private func improveCautionTone(text: String) -> String {
        var improvedText = text

        // Enhanced demanding words with attachment-style considerations
        let demandingWords = [
            // Basic demanding words
            "must": "could you please",
            "need to": "would you mind",
            "have to": "it would help if you could",
            "should": "it might be good to",
            "immediately": "when you have a chance",
            "urgent": "important",

            // Anxious attachment demands
            "prove": "show",
            "guarantee": "help me feel confident that",
            "promise": "commit to",
            "swear": "assure me",

            // Avoidant attachment pushes
            "space": "some time",
            "break": "pause",
            "distance": "time to process",

            // Control patterns
            "control": "influence",
            "force": "encourage",
            "make you": "help you see why",
        ]

        for (demanding, polite) in demandingWords {
            improvedText = improvedText.replacingOccurrences(
                of: demanding,
                with: polite,
                options: .caseInsensitive
            )
        }

        // Add politeness with attachment awareness
        if !improvedText.contains("please") && !improvedText.contains("thank") {
            improvedText += " please"
        }

        return improvedText
    }
    
    // MARK: - User Profile Management
    func updateUserAttachmentStyle(_ style: AttachmentStyle) {
        userAttachmentStyle = style
    }
    
    func updatePartnerAttachmentStyle(_ style: AttachmentStyle) {
        partnerAttachmentStyle = style
    }
    
    func updateRelationshipContext(_ context: RelationshipContext) {
        storedRelationshipContext = context
    }

    // MARK: - Data Collection and Analytics
    func recordSuggestionUsage(_ suggestion: AdvancedSuggestion, accepted: Bool) {
        // Store suggestion usage data for insights
        let userDefaults = UserDefaults(suiteName: "group.com.unsaid.shared")

        var suggestionData = userDefaults?.array(forKey: "suggestion_usage") as? [[String: Any]] ?? []

        suggestionData.append([
            "text": suggestion.text,
            "type": suggestion.type.rawValue,
            "accepted": accepted,
            "timestamp": Date().timeIntervalSince1970,
            "attachment_specific": suggestion.attachmentStyleSpecific,
        ])

        // Keep only recent data
        if suggestionData.count > 100 {
            suggestionData.removeFirst()
        }

        userDefaults?.set(suggestionData, forKey: "suggestion_usage")
    }
    
    func getSuggestionUsageAnalytics() -> [String: Any] {
        let userDefaults = UserDefaults(suiteName: "group.com.unsaid.shared")
        let suggestionData = userDefaults?.array(forKey: "suggestion_usage") as? [[String: Any]] ?? []
        
        let totalSuggestions = suggestionData.count
        let acceptedSuggestions = suggestionData.filter { ($0["accepted"] as? Bool) == true }.count
        let acceptanceRate = totalSuggestions > 0 ? Double(acceptedSuggestions) / Double(totalSuggestions) : 0.0
        
        return [
            "total_suggestions": totalSuggestions,
            "accepted_suggestions": acceptedSuggestions,
            "acceptance_rate": acceptanceRate,
            "user_attachment_style": userAttachmentStyle.rawValue,
            "partner_attachment_style": partnerAttachmentStyle.rawValue,
            "relationship_context": storedRelationshipContext.rawValue
        ]
    }
    
    // MARK: - AI-Powered Suggestion Generation (NEW)
    
    /// Generates AI-powered suggestions using OpenAI based on comprehensive personality data
    func generateAIEnhancedSuggestions(
        for text: String,
        toneStatus: ToneStatus? = nil,
        conversationHistory: [ConversationMessage] = []
    ) async -> [AdvancedSuggestion] {
        
        let detectedTone = toneStatus ?? toneAnalysisEngine.analyzeTone(text)
        
        // Only use AI for problematic tones or when specifically requested
        guard detectedTone == .alert || detectedTone == .caution || !conversationHistory.isEmpty else {
            return generateAdvancedSuggestions(for: text, toneStatus: detectedTone)
        }
        
        // Get comprehensive personality context
        let personalityContext = getPersonalityContext()
        
        return await aiPredictiveEngine.generateAIPersonalizedSuggestions(
            originalText: text,
            userAttachmentStyle: userAttachmentStyle,
            partnerAttachmentStyle: partnerAttachmentStyle,
            relationshipContext: relationshipContext,
            toneStatus: detectedTone,
            conversationHistory: conversationHistory,
            personalityContext: personalityContext
        )
    }
    
    /// Generates AI-powered message improvement with comprehensive personality consideration
    func generateAIMessageImprovement(
        for text: String,
        targetTone: ToneStatus = .clear
    ) async -> String {
        
        // Get comprehensive personality context
        let personalityContext = getPersonalityContext()
        
        return await aiPredictiveEngine.generateAIMessageImprovement(
            originalText: text,
            targetTone: targetTone,
            userAttachmentStyle: userAttachmentStyle,
            relationshipContext: relationshipContext,
            personalityContext: personalityContext
        )
    }
    
    /// Generates AI-powered repair script for conflicts with full personality awareness
    func generateAIRepairScript(
        for conflict: String
    ) async -> String {
        
        // Get comprehensive personality context
        let personalityContext = getPersonalityContext()
        
        return await aiPredictiveEngine.generateAIRepairScript(
            conflict: conflict,
            userAttachmentStyle: userAttachmentStyle,
            partnerAttachmentStyle: partnerAttachmentStyle,
            relationshipContext: relationshipContext,
            personalityContext: personalityContext
        )
    }
    
    // MARK: - Personality Context for AI
    
    /// Gets comprehensive personality context for AI suggestions
    private func getPersonalityContext() -> [String: Any] {
        var context = personalityManager.generatePersonalityContextDictionary()
        
        // Add partner and relationship context from shared defaults
        let userDefaults = UserDefaults(suiteName: "group.com.unsaid.shared")
        if let partnerStyle = userDefaults?.string(forKey: "partner_attachment_style") {
            context["partner_attachment_style"] = partnerStyle
        }
        if let relationshipContext = userDefaults?.string(forKey: "relationship_context") {
            context["relationship_context"] = relationshipContext
        }
        
        return context
    }
    
    /// Gets personality context as a string for AI prompts
    private func getPersonalityContextString() -> String {
        let context = getPersonalityContext()
        var contextString = ""
        
        if let attachmentStyle = context["attachment_style"] as? String {
            contextString += "User Attachment Style: \(attachmentStyle)\n"
        }
        
        if let communicationStyle = context["communication_style"] as? String {
            contextString += "Communication Style: \(communicationStyle)\n"
        }
        
        if let personalityType = context["personality_type"] as? String {
            contextString += "Personality Type: \(personalityType)\n"
        }
        
        if let partnerStyle = context["partner_attachment_style"] as? String {
            contextString += "Partner Attachment Style: \(partnerStyle)\n"
        }
        
        if let relationshipContext = context["relationship_context"] as? String {
            contextString += "Relationship Context: \(relationshipContext)\n"
        }
        
        return contextString.isEmpty ? "No personality data available" : contextString
    }
}

        }
    }
}

extension AnalysisSuggestionType {
    static func fromString(_ string: String) -> AnalysisSuggestionType {