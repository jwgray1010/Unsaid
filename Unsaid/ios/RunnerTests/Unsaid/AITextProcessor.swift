//
//  AITextProcessor.swift
//  KeyboardExtension
//
//  AI Text Processing for Unsaid Keyboard Extension
//
//  Created by John Gray on 7/8/25.
//

import Foundation
// If needed for color extensions:
#if canImport(UIKit)
import UIKit
#endif

class AITextProcessor {
    // MARK: - Simple Text Improvement

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

    // MARK: - Alert Tone Improvements

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
            let attachmentStyle = detectAttachmentStyle(improvedText)
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

    // MARK: - Caution Tone Improvements

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

    // MARK: - Comprehensive Attachment Style Detection

    private func detectAttachmentStyle(_ text: String) -> AttachmentStyle {
        let lowercaseText = text.lowercased()

        // Anxious attachment indicators
        let anxiousPatterns = [
            "are you mad", "did i do something", "you seem distant", "you don't love me",
            "abandoning me", "leaving me", "ignoring me", "rejecting me",
            "need reassurance", "worried about us", "scared you'll leave",
            "prove you love me", "show me you care", "why won't you",
            "always", "never", "everyone leaves", "nobody cares",
        ]

        // Avoidant attachment indicators
        let avoidantPatterns = [
            "need space", "feeling suffocated", "too clingy", "too needy",
            "overwhelming me", "can't breathe", "need independence",
            "don't need anyone", "fine on my own", "handle it myself",
            "emotions are", "feelings are", "drama", "being dramatic",
        ]

        // Disorganized attachment indicators
        let disorganizedPatterns = [
            "don't know what i want", "confused about", "mixed feelings",
            "love and hate", "close but far", "want you but",
            "scared of being hurt", "can't trust", "unpredictable",
            "chaos", "unstable", "don't understand myself",
        ]

        // Secure attachment indicators
        let securePatterns = [
            "i feel", "i need", "can we talk", "i understand",
            "respect your", "appreciate you", "grateful for",
            "work together", "find a solution", "both of us",
        ]

        var anxiousScore = 0
        var avoidantScore = 0
        var disorganizedScore = 0
        var secureScore = 0

        for pattern in anxiousPatterns {
            if lowercaseText.contains(pattern) { anxiousScore += 1 }
        }
        for pattern in avoidantPatterns {
            if lowercaseText.contains(pattern) { avoidantScore += 1 }
        }
        for pattern in disorganizedPatterns {
            if lowercaseText.contains(pattern) { disorganizedScore += 1 }
        }
        for pattern in securePatterns {
            if lowercaseText.contains(pattern) { secureScore += 1 }
        }

        let maxScore = max(anxiousScore, avoidantScore, disorganizedScore, secureScore)

        if maxScore == 0 { return .unknown }
        if secureScore == maxScore { return .secure }
        if anxiousScore == maxScore { return .anxious }
        if avoidantScore == maxScore { return .avoidant }
        if disorganizedScore == maxScore { return .disorganized }

        return .unknown
    }

    // MARK: - Advanced Communication Pattern Detection

    private func detectAdvancedCommunicationPattern(_ text: String) -> CommunicationPattern {
        let lowercaseText = text.lowercased()

        // Aggressive patterns
        let aggressivePatterns = ["you always", "you never", "your fault", "blame you", "you're wrong"]
        if aggressivePatterns.contains(where: lowercaseText.contains) {
            return .aggressive
        }

        // Passive-aggressive patterns
        let passiveAggressivePatterns = ["fine", "whatever", "sure", "if you say so", "don't worry about me"]
        if passiveAggressivePatterns.contains(where: lowercaseText.contains) {
            return .passiveAggressive
        }

        // Defensive patterns
        let defensivePatterns = ["not my fault", "you don't understand", "you're overreacting", "that's not what i meant"]
        if defensivePatterns.contains(where: lowercaseText.contains) {
            return .defensive
        }

        // Withdrawing patterns
        let withdrawingPatterns = ["need space", "can't deal", "leave me alone", "don't want to talk"]
        if withdrawingPatterns.contains(where: lowercaseText.contains) {
            return .withdrawing
        }

        // Pursuing patterns
        let pursuingPatterns = ["we need to talk", "why won't you", "talk to me", "answer me"]
        if pursuingPatterns.contains(where: lowercaseText.contains) {
            return .pursuing
        }

        // Assertive patterns
        let assertivePatterns = ["i feel", "i need", "i would like", "can we", "let's work together"]
        if assertivePatterns.contains(where: lowercaseText.contains) {
            return .assertive
        }

        return .neutral
    }

    // MARK: - Relationship Context Detection

    private func detectRelationshipContext(_ text: String) -> RelationshipContext {
        let lowercaseText = text.lowercased()

        // Romantic relationship indicators
        let romanticPatterns = ["love", "relationship", "partner", "boyfriend", "girlfriend", "husband", "wife", "dating"]
        if romanticPatterns.contains(where: lowercaseText.contains) {
            return .romantic
        }

        // Family indicators
        let familyPatterns = ["mom", "dad", "mother", "father", "sister", "brother", "family", "parent"]
        if familyPatterns.contains(where: lowercaseText.contains) {
            return .family
        }

        // Professional indicators
        let professionalPatterns = ["boss", "colleague", "coworker", "manager", "team", "meeting", "project", "work"]
        if professionalPatterns.contains(where: lowercaseText.contains) {
            return .professional
        }

        // Friendship indicators
        let friendshipPatterns = ["friend", "buddy", "pal", "hang out", "catch up"]
        if friendshipPatterns.contains(where: lowercaseText.contains) {
            return .friendship
        }

        return .unknown
    }

    // MARK: - Enhanced Tone Analysis with Attachment Awareness

    private func analyzeTone(_ text: String) -> ToneStatus {
        let lowercaseText = text.lowercased()

        // Alert indicators (red) - enhanced with attachment patterns
        let alertWords = [
            // Basic harsh words
            "stupid", "ridiculous", "hate", "terrible", "awful", "worst", "pathetic", "useless",
            // Anxious attachment crisis words
            "abandoning", "rejecting", "ignoring", "leaving me", "don't love me",
            // Avoidant attachment harsh dismissals
            "clingy", "needy", "suffocating", "annoying", "dramatic",
            // Disorganized attachment chaos words
            "crazy", "insane", "unstable", "chaotic", "overwhelming",
        ]

        if alertWords.contains(where: lowercaseText.contains) {
            return .alert
        }

        // Caution indicators (yellow) - attachment-aware
        let cautionWords = [
            // Basic demanding words
            "should", "must", "need to", "have to", "immediately", "urgent", "wrong",
            // Anxious attachment demands
            "prove", "guarantee", "promise", "swear", "always", "never",
            // Avoidant attachment distancing
            "space", "break", "distance", "independence",
            // Control patterns
            "control", "force", "make you",
        ]

        if cautionWords.contains(where: lowercaseText.contains) {
            return .caution
        }

        // Positive indicators (green) - secure attachment patterns
        let positiveWords = [
            "thanks", "appreciate", "grateful", "please", "understand", "help", "support",
            "i feel", "i need", "can we", "work together", "respect", "value",
        ]

        if positiveWords.contains(where: lowercaseText.contains) {
            return .clear
        }

        return .analyzing
    }

    // MARK: - Comprehensive Suggestion Generation

    func generateSuggestions(for text: String) -> [String] {
        let ToneStatus = analyzeTone(text)
        let attachmentStyle = detectAttachmentStyle(text)
        let communicationPattern = detectAdvancedCommunicationPattern(text)
        let relationshipContext = detectRelationshipContext(text)

        var suggestions: [String] = []
        
        // Add suggestions from different analysis categories
        suggestions.append(contentsOf: generateToneSuggestions(for: ToneStatus))
        suggestions.append(contentsOf: generateAttachmentStyleSuggestions(for: attachmentStyle, text: text))
        suggestions.append(contentsOf: generateCommunicationPatternSuggestions(for: communicationPattern))
        suggestions.append(contentsOf: generateRelationshipContextSuggestions(for: relationshipContext))
        suggestions.append(contentsOf: generateRepairStrategies(for:ToneStatus, pattern: communicationPattern))

        return suggestions
    }
    
    // MARK: - Suggestion Generation Helpers
    
    private func generateToneSuggestions(for ToneStatus: ToneStatus) -> [String] {
        switch ToneStatus {
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
    
    private func generateAttachmentStyleSuggestions(for attachmentStyle: AttachmentStyle, text: String) -> [String] {
        var suggestions: [String] = []
        
        switch attachmentStyle {
        case .anxious:
            suggestions.append("🧡 Anxious pattern detected")
            if text.lowercased().contains("always") || text.lowercased().contains("never") {
                suggestions.append("Try: 'Sometimes I feel...' instead of 'You always/never...'")
            }
            if text.lowercased().contains("leaving") || text.lowercased().contains("abandon") {
                suggestions.append("Consider: 'I'm feeling insecure and need reassurance'")
            }
            suggestions.append("Remember: Express your need for connection clearly")

        case .avoidant:
            suggestions.append("💙 Avoidant pattern detected")
            if text.lowercased().contains("space") || text.lowercased().contains("distance") {
                suggestions.append("Try: 'I need time to process, can we reconnect in [timeframe]?'")
            }
            if text.lowercased().contains("clingy") || text.lowercased().contains("needy") {
                suggestions.append("Consider: 'I'm feeling overwhelmed and need to recharge'")
            }
            suggestions.append("Remember: Your partner needs to understand your processing style")

        case .disorganized:
            suggestions.append("💜 Complex emotions detected")
            suggestions.append("Consider: Break down what you're feeling into smaller parts")
            suggestions.append("Try: 'I'm having mixed feelings about this'")
            suggestions.append("Remember: It's okay to feel confused - communicate that too")

        case .secure:
            suggestions.append("💚 Secure communication pattern!")
            suggestions.append("You're expressing yourself clearly and considerately")

        case .unknown:
            break
        }
        
        return suggestions
    }
    
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
                "😔 Passive-aggressive tone detected",
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
    
    private func generateRepairStrategies(for ToneStatus: ToneStatus, pattern: CommunicationPattern) -> [String] {
        if ToneStatus == .alert || pattern == .aggressive {
            return ["💡 Repair strategy: 'I'm sorry, let me try that again...'"]
        }
        return []
    }

    // MARK: - Attachment Style Repair Scripts

    func generateRepairScript(for attachmentStyle: AttachmentStyle, context _: String = "") -> String {
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

    // MARK: - Cross-Attachment Style Communication

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

    // MARK: - Legacy Compatibility (maintaining existing interface)

    func detectCommunicationStyle(_ text: String) -> String {
        let pattern = detectAdvancedCommunicationPattern(text)
        switch pattern {
        case .aggressive: return "aggressive"
        case .passiveAggressive: return "passive-aggressive"
        case .assertive: return "assertive"
        case .defensive: return "defensive"
        case .withdrawing: return "withdrawing"
        case .pursuing: return "pursuing"
        case .neutral: return "neutral"
        }
    }

    // MARK: - Advanced Emotional Intelligence Features

    func detectEmotionalState(_ text: String) -> [String] {
        let lowercaseText = text.lowercased()
        var emotions: [String] = []

        // Fear-based emotions
        if lowercaseText.contains("scared") || lowercaseText.contains("afraid") || lowercaseText.contains("worried") {
            emotions.append("fear")
        }

        // Anger-based emotions
        if lowercaseText.contains("angry") || lowercaseText.contains("frustrated") || lowercaseText.contains("mad") {
            emotions.append("anger")
        }

        // Sadness-based emotions
        if lowercaseText.contains("sad") || lowercaseText.contains("hurt") || lowercaseText.contains("disappointed") {
            emotions.append("sadness")
        }

        // Joy-based emotions
        if lowercaseText.contains("happy") || lowercaseText.contains("excited") || lowercaseText.contains("grateful") {
            emotions.append("joy")
        }

        return emotions
    }

    // MARK: - Trauma-Informed Communication Analysis

    func detectTraumaResponse(_ text: String) -> String? {
        let lowercaseText = text.lowercased()

        // Fight response
        if lowercaseText.contains("attack") || lowercaseText.contains("defend") || lowercaseText.contains("fight") {
            return "fight"
        }

        // Flight response
        if lowercaseText.contains("escape") || lowercaseText.contains("run away") || lowercaseText.contains("leave") {
            return "flight"
        }

        // Freeze response
        if lowercaseText.contains("can't move") || lowercaseText.contains("paralyzed") || lowercaseText.contains("stuck") {
            return "freeze"
        }

        // Fawn response
        if lowercaseText.contains("please don't") || lowercaseText.contains("sorry") && lowercaseText.contains("my fault") {
            return "fawn"
        }

        return nil
    }

    // MARK: - Conflict De-escalation Suggestions

    func generateDeescalationSuggestion(_ text: String) -> String? {
        let ToneStatus = analyzeTone(text)
        let attachmentStyle = detectAttachmentStyle(text)

        if ToneStatus == .alert || ToneStatus == .caution {
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

    // MARK: - Mindful Communication Prompts

    func generateMindfulnessPrompt(_ text: String) -> String {
        let emotions = detectEmotionalState(text)

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
}
