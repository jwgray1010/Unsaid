//
//  AttachmentBasedSuggestionEngine.swift
//  KeyboardExtension
//
//  Advanced suggestion engine using attachment styles and conversation context
//
//  Created by John Gray on 7/8/25.
//

import Foundation
// If needed for color extensions:
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Suggestion Engine

class AttachmentBasedSuggestionEngine {
    // MARK: - User Profile

    private var userAttachmentStyle: AttachmentStyle = .unknown
    private var partnerAttachmentStyle: AttachmentStyle = .unknown
    private var relationshipContext: RelationshipContext = .unknown

    // MARK: - Suggestion Types

    enum SuggestionType {
        case toneImprovement
        case attachmentAware
        case conversationRepair
        case crossStyleCommunication
        case emotionalRegulation
        case conflictDeescalation
    }

    struct Suggestion {
        let text: String
        let type: SuggestionType
        let priority: Int
        let attachmentStyleSpecific: Bool
        let repairScript: String?
    }

    // MARK: - Initialization

    func loadUserProfile() {
        // Load from shared UserDefaults (set by main app)
        let userDefaults = UserDefaults(suiteName: "group.com.unsaid.shared")

        if let userStyleString = userDefaults?.string(forKey: "user_attachment_style") {
            userAttachmentStyle = AttachmentStyle(rawValue: userStyleString) ?? .unknown
        }

        if let partnerStyleString = userDefaults?.string(forKey: "partner_attachment_style") {
            partnerAttachmentStyle = AttachmentStyle(rawValue: partnerStyleString) ?? .unknown
        }

        if let contextString = userDefaults?.string(forKey: "relationship_context") {
            relationshipContext = RelationshipContext(rawValue: contextString) ?? .unknown
        }
    }

    // MARK: - Main Suggestion Generation

    func generateAdvancedSuggestions(
        for currentText: String,
        ToneStatus: ToneStatus,
        conversationContext: String? = nil
    ) -> [Suggestion] {
        var suggestions: [Suggestion] = []

        // 1. Basic tone-based suggestions
        suggestions.append(contentsOf: generateToneSuggestions(currentText, ToneStatus))

        // 2. Attachment-style specific suggestions
        suggestions.append(contentsOf: generateAttachmentSpecificSuggestions(currentText))

        // 3. Cross-attachment style communication
        if userAttachmentStyle != .unknown, partnerAttachmentStyle != .unknown {
            suggestions.append(contentsOf: generateCrossStyleSuggestions(currentText))
        }

        // 4. Conversation context-aware suggestions
        if let context = conversationContext {
            suggestions.append(contentsOf: generateContextAwareSuggestions(currentText, context, ToneStatus))
        }

        // Sort by priority and return top suggestions
        return Array(suggestions.sorted { $0.priority < $1.priority }.prefix(5))
    }

    // MARK: - Tone-Based Suggestions

    private func generateToneSuggestions(_ text: String, _ status: ToneStatus) -> [Suggestion] {
        var suggestions: [Suggestion] = []

        switch status {
        case .alert:
            suggestions.append(Suggestion(
                text: "This message might feel hurtful. Consider taking a pause before sending",
                type: .toneImprovement,
                priority: 0,
                attachmentStyleSpecific: false,
                repairScript: "I'm feeling really upset right now. Can we talk about this when I'm calmer?"
            ))

        case .caution:
            suggestions.append(Suggestion(
                text: "This could come across as demanding. Try softening with 'please' or 'when you can'",
                type: .toneImprovement,
                priority: 1,
                attachmentStyleSpecific: false,
                repairScript: text.replacingOccurrences(of: "must", with: "could you please")
            ))

        case .clear:
            suggestions.append(Suggestion(
                text: "Great! This sounds supportive and clear 💚",
                type: .toneImprovement,
                priority: 3,
                attachmentStyleSpecific: false,
                repairScript: nil
            ))

        case .analyzing:
            // This case is for when the text is still being analyzed:
            suggestions.append(Suggestion(
                text: "Consider adding warmth to your message",
                type: .toneImprovement,
                priority: 2,
                attachmentStyleSpecific: false,
                repairScript: "I hope you're doing well. " + text
            ))
        case .neutral: break

}

        return suggestions
    }

    // MARK: - Attachment-Specific Suggestions

    private func generateAttachmentSpecificSuggestions(_ text: String) -> [Suggestion] {
        var suggestions: [Suggestion] = []
        let detectedStyle = detectAttachmentStyle(text)

        switch detectedStyle {
        case .anxious:
            if text.lowercased().contains("always") || text.lowercased().contains("never") {
                suggestions.append(Suggestion(
                    text: "🧡 Anxious pattern: Try 'sometimes' instead of 'always/never'",
                    type: .attachmentAware,
                    priority: 1,
                    attachmentStyleSpecific: true,
                    repairScript: text.replacingOccurrences(of: "always", with: "sometimes")
                        .replacingOccurrences(of: "never", with: "rarely")
                ))
            }

            if text.lowercased().contains("are you mad") {
                suggestions.append(Suggestion(
                    text: "Instead of asking if they're mad, try expressing your feelings",
                    type: .attachmentAware,
                    priority: 0,
                    attachmentStyleSpecific: true,
                    repairScript: "I'm sensing some distance and wondering if we can talk about it"
                ))
            }

        case .avoidant:
            if text.lowercased().contains("need space") {
                suggestions.append(Suggestion(
                    text: "💙 Avoidant pattern: Let them know when you'll reconnect",
                    type: .attachmentAware,
                    priority: 1,
                    attachmentStyleSpecific: true,
                    repairScript: "I need some time to process this. Can we talk again in [specific timeframe]?"
                ))
            }

        case .disorganized:
            suggestions.append(Suggestion(
                text: "💜 Complex emotions detected. Try breaking down your feelings",
                type: .emotionalRegulation,
                priority: 1,
                attachmentStyleSpecific: true,
                repairScript: "I'm having mixed feelings about this. Can we talk through this step by step?"
            ))

        case .secure:
            suggestions.append(Suggestion(
                text: "💚 Secure communication! You're expressing yourself clearly",
                type: .attachmentAware,
                priority: 3,
                attachmentStyleSpecific: true,
                repairScript: nil
            ))

        case .unknown:
            break
        }

        return suggestions
    }

    // MARK: - Cross-Style Suggestions

    private func generateCrossStyleSuggestions(_: String) -> [Suggestion] {
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

        return [Suggestion(
            text: suggestion,
            type: .crossStyleCommunication,
            priority: 1,
            attachmentStyleSpecific: true,
            repairScript: nil
        )]
    }

    // MARK: - Context-Aware Suggestions

    private func generateContextAwareSuggestions(_: String, _ context: String, _ status: ToneStatus) -> [Suggestion] {
        var suggestions: [Suggestion] = []

        // Analyze context for previous messages
        let contextLower = context.lowercased()

        // If previous message seemed upset
        if contextLower.contains("upset") || contextLower.contains("angry") || contextLower.contains("frustrated") {
            suggestions.append(Suggestion(
                text: "They seem upset. Consider acknowledging their feelings first",
                type: .conversationRepair,
                priority: 0,
                attachmentStyleSpecific: false,
                repairScript: "I can see this is really affecting you. Help me understand what you need."
            ))
        }

        // If they asked for space
        if contextLower.contains("space") || contextLower.contains("time") {
            suggestions.append(Suggestion(
                text: "They asked for space. Respect that and check in later",
                type: .conversationRepair,
                priority: 0,
                attachmentStyleSpecific: false,
                repairScript: "I respect that you need space. I'll check in with you later."
            ))
        }

        // If conversation is escalating
        if status == .alert, contextLower.contains("wrong") || contextLower.contains("fault") {
            suggestions.append(Suggestion(
                text: "Conversation is escalating. Consider taking a pause",
                type: .conflictDeescalation,
                priority: 0,
                attachmentStyleSpecific: false,
                repairScript: "I can feel this getting heated. Can we take a pause and come back to this when we're calmer?"
            ))
        }

        return suggestions
    }

    // MARK: - Auto-Fix Generation

    func generateAutoFix(for text: String, ToneStatus: ToneStatus) -> String {
        var improvedText = text

        // Basic improvements
        switch ToneStatus {
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

    // MARK: - Helper Methods

    private func detectAttachmentStyle(_ text: String) -> AttachmentStyle {
        let lowercaseText = text.lowercased()

        // Anxious patterns
        if lowercaseText.contains("are you mad") || lowercaseText.contains("always") ||
            lowercaseText.contains("never") || lowercaseText.contains("abandoning")
        {
            return .anxious
        }

        // Avoidant patterns
        if lowercaseText.contains("need space") || lowercaseText.contains("overwhelming") ||
            lowercaseText.contains("too much")
        {
            return .avoidant
        }

        // Disorganized patterns
        if lowercaseText.contains("confused") || lowercaseText.contains("mixed feelings") ||
            lowercaseText.contains("don't know")
        {
            return .disorganized
        }

        // Secure patterns
        if lowercaseText.contains("i feel") || lowercaseText.contains("can we") ||
            lowercaseText.contains("understand")
        {
            return .secure
        }

        return .unknown
    }

    // MARK: - Data Collection Integration

    func recordSuggestionUsage(_ suggestion: Suggestion, accepted: Bool) {
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
}

// MARK: - Extensions

extension AttachmentBasedSuggestionEngine.SuggestionType {
    var rawValue: String {
        switch self {
        case .toneImprovement: return "tone_improvement"
        case .attachmentAware: return "attachment_aware"
        case .conversationRepair: return "conversation_repair"
        case .crossStyleCommunication: return "cross_style_communication"
        case .emotionalRegulation: return "emotional_regulation"
        case .conflictDeescalation: return "conflict_deescalation"
        }
    }
}
