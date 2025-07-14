//
//  ConversationContextAnalyzer.swift
//  KeyboardExtension
//
//  Analyzes conversation history and context for better suggestions
//
//  Created by John Gray on 7/8/25.
//

import Foundation
// If needed for color extensions:
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Data Models

struct ConversationMessage {
    let text: String
    let timestamp: Date
    let isFromUser: Bool
    let toneStatus: ToneStatus
    let attachmentStyle: AttachmentStyle?
}

struct ConversationHistory {
    let messages: [ConversationMessage]
    let conversationId: String
    let participantCount: Int
    let relationship: RelationshipContext

    var lastMessage: ConversationMessage? {
        return messages.last
    }

    var recentMessages: [ConversationMessage] {
        return Array(messages.suffix(10)) // Last 10 messages
    }
}

struct ConversationAnalysis {
    let isEscalating: Bool
    let dominantTone: ToneStatus
    let turnTaking: TurnTakingPattern
    let emotionalTrajectory: EmotionalTrajectory
    let attachmentDynamics: AttachmentDynamics
    let conversationQuality: ConversationQuality
}

enum TurnTakingPattern {
    case balanced
    case userDominated
    case partnerDominated
    case rapidFire
    case slowResponse
}

enum EmotionalTrajectory {
    case improving
    case declining
    case stable
    case volatile
}

struct AttachmentDynamics {
    let userPattern: AttachmentStyle
    let partnerPattern: AttachmentStyle
    let dynamicType: AttachmentDynamicType
    let triggerWords: [String]
}

enum AttachmentDynamicType {
    case secure // Both communicating well
    case anxiousAvoidant // Classic protest-withdraw
    case anxiousAnxious // Both seeking reassurance
    case avoidantAvoidant // Both withdrawing
    case chaotic // Disorganized patterns
}

enum ConversationQuality {
    case healthy
    case strained
    case conflicted
    case disconnected
    case improving
}

// MARK: - Main Analyzer Class

class ConversationContextAnalyzer {
    // MARK: - Analysis Methods

    func analyzeConversationFlow(_ history: ConversationHistory) -> ConversationAnalysis {
        let recentMessages = history.recentMessages

        return ConversationAnalysis(
            isEscalating: detectEscalation(recentMessages),
            dominantTone: calculateDominantTone(recentMessages),
            turnTaking: analyzeTurnTaking(recentMessages),
            emotionalTrajectory: analyzeEmotionalTrajectory(recentMessages),
            attachmentDynamics: analyzeAttachmentDynamics(recentMessages),
            conversationQuality: assessConversationQuality(recentMessages)
        )
    }

    func extractConversationContext(fromTextProxy proxy: AnyObject) -> ConversationHistory? {
        // Try to extract conversation context from the text input
        // This is limited in keyboard extensions, but we can get some context

        var messages: [ConversationMessage] = []

        // Use reflection to safely get text context
        if let beforeText = (proxy as? NSObject)?.value(forKey: "documentContextBeforeInput") as? String {
            let conversationMessages = parseConversationFromText(beforeText)
            messages.append(contentsOf: conversationMessages)
        }

        if let afterText = (proxy as? NSObject)?.value(forKey: "documentContextAfterInput") as? String {
            let futureMessages = parseConversationFromText(afterText)
            messages.append(contentsOf: futureMessages)
        }

        guard !messages.isEmpty else { return nil }

        return ConversationHistory(
            messages: messages,
            conversationId: UUID().uuidString,
            participantCount: 2, // Assume 1:1 conversation
            relationship: .unknown // Would need to be set from user profile
        )
    }

    // MARK: - Private Analysis Methods

    private func detectEscalation(_ messages: [ConversationMessage]) -> Bool {
        guard messages.count >= 3 else { return false }

        // Check if tone is getting worse over time
        let recentTones = messages.suffix(3).map { $0.toneStatus }

        var alertCount = 0
        var cautionCount = 0

        for tone in recentTones {
            switch tone {
            case .alert:
                alertCount += 1
            case .caution:
                cautionCount += 1
            default:
                break
            }
        }

        // Escalating if we have multiple alert/caution messages recently
        return alertCount >= 2 || (alertCount + cautionCount) >= 3
    }

    private func calculateDominantTone(_ messages: [ConversationMessage]) -> ToneStatus {
        let toneCount = messages.reduce(into: [ToneStatus: Int]()) { counts, message in
            counts[message.toneStatus, default: 0] += 1
        }

        return toneCount.max { $0.value < $1.value }?.key ?? .neutral
    }

    private func analyzeTurnTaking(_ messages: [ConversationMessage]) -> TurnTakingPattern {
        guard messages.count >= 4 else { return .balanced }

        let userMessages = messages.filter { $0.isFromUser }.count
        let totalMessages = messages.count
        let userRatio = Double(userMessages) / Double(totalMessages)

        if userRatio > 0.7 {
            return .userDominated
        } else if userRatio < 0.3 {
            return .partnerDominated
        } else {
            // Check timing patterns
            let timeBetweenMessages = calculateAverageResponseTime(messages)
            if timeBetweenMessages < 10 { // Less than 10 seconds
                return .rapidFire
            } else if timeBetweenMessages > 300 { // More than 5 minutes
                return .slowResponse
            }
            return .balanced
        }
    }

    private func analyzeEmotionalTrajectory(_ messages: [ConversationMessage]) -> EmotionalTrajectory {
        guard messages.count >= 3 else { return .stable }

        // Convert tones to numerical values for trend analysis
        let toneValues = messages.map { toneToValue($0.toneStatus) }

        let firstHalf = Array(toneValues.prefix(toneValues.count / 2))
        let secondHalf = Array(toneValues.suffix(toneValues.count / 2))

        let firstAverage = Double(firstHalf.reduce(0, +)) / Double(firstHalf.count)
        let secondAverage = Double(secondHalf.reduce(0, +)) / Double(secondHalf.count)

        let change = secondAverage - firstAverage

        if abs(change) < 0.5 {
            return .stable
        } else if change > 0.5 {
            return .improving
        } else if change < -0.5 {
            return .declining
        } else {
            // Check for volatility
            let variance = calculateVariance(toneValues)
            return variance > 1.0 ? .volatile : .stable
        }
    }

    private func analyzeAttachmentDynamics(_ messages: [ConversationMessage]) -> AttachmentDynamics {
        // Detect attachment patterns from message content
        var anxiousPatterns = 0
        var avoidantPatterns = 0
        var securePatterns = 0
        var disorganizedPatterns = 0

        var triggerWords: [String] = []

        for message in messages {
            let text = message.text.lowercased()

            // Anxious patterns
            if text.contains("are you mad") || text.contains("did i do something") ||
                text.contains("always") || text.contains("never")
            {
                anxiousPatterns += 1
                triggerWords.append("anxious-trigger")
            }

            // Avoidant patterns
            if text.contains("need space") || text.contains("overwhelming") ||
                text.contains("too much")
            {
                avoidantPatterns += 1
                triggerWords.append("avoidant-trigger")
            }

            // Secure patterns
            if text.contains("i feel") || text.contains("can we") ||
                text.contains("understand")
            {
                securePatterns += 1
            }

            // Disorganized patterns
            if text.contains("confused") || text.contains("mixed feelings") {
                disorganizedPatterns += 1
            }
        }

        let userPattern: AttachmentStyle
        let partnerPattern: AttachmentStyle
        let dynamicType: AttachmentDynamicType

        // Determine dominant patterns
        let maxCount = max(anxiousPatterns, avoidantPatterns, securePatterns, disorganizedPatterns)

        if securePatterns == maxCount {
            userPattern = .secure
            partnerPattern = .secure
            dynamicType = .secure
        } else if anxiousPatterns == maxCount && avoidantPatterns > 0 {
            userPattern = .anxious
            partnerPattern = .avoidant
            dynamicType = .anxiousAvoidant
        } else if anxiousPatterns == maxCount {
            userPattern = .anxious
            partnerPattern = .anxious
            dynamicType = .anxiousAnxious
        } else if avoidantPatterns == maxCount {
            userPattern = .avoidant
            partnerPattern = .avoidant
            dynamicType = .avoidantAvoidant
        } else {
            userPattern = .disorganized
            partnerPattern = .unknown
            dynamicType = .chaotic
        }

        return AttachmentDynamics(
            userPattern: userPattern,
            partnerPattern: partnerPattern,
            dynamicType: dynamicType,
            triggerWords: triggerWords
        )
    }

    private func assessConversationQuality(_ messages: [ConversationMessage]) -> ConversationQuality {
        let alertCount = messages.filter { $0.toneStatus == .alert }.count
        let clearCount = messages.filter { $0.toneStatus == .clear }.count
        let totalCount = messages.count

        let alertRatio = Double(alertCount) / Double(totalCount)
        let clearRatio = Double(clearCount) / Double(totalCount)

        if alertRatio > 0.5 {
            return .conflicted
        } else if alertRatio > 0.3 {
            return .strained
        } else if clearRatio > 0.5 {
            return .healthy
        } else if alertRatio == 0 && clearRatio > 0.2 {
            return .improving
        } else {
            return .disconnected
        }
    }

    // MARK: - Helper Methods

    private func parseConversationFromText(_ text: String) -> [ConversationMessage] {
        // Simple parsing - in a real implementation this would be more sophisticated
        let lines = text.components(separatedBy: .newlines)
        var messages: [ConversationMessage] = []

        for (index, line) in lines.enumerated() {
            if !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let isFromUser = index % 2 == 0 // Alternate between user and partner
                let tone = analyzeToneSimple(line)

                messages.append(ConversationMessage(
                    text: line,
                    timestamp: Date().addingTimeInterval(-Double(lines.count - index) * 60),
                    isFromUser: isFromUser,
                    toneStatus: tone,
                    attachmentStyle: nil
                ))
            }
        }

        return messages
    }

    private func analyzeToneSimple(_ text: String) -> ToneStatus {
        let lowercaseText = text.lowercased()

        // Quick tone analysis
        if lowercaseText.contains("hate") || lowercaseText.contains("stupid") || lowercaseText.contains("terrible") {
            return .alert
        } else if lowercaseText.contains("must") || lowercaseText.contains("should") || lowercaseText.contains("wrong") {
            return .caution
        } else if lowercaseText.contains("thanks") || lowercaseText.contains("appreciate") || lowercaseText.contains("love") {
            return .clear
        } else {
            return .neutral
        }
    }

    private func toneToValue(_ tone: ToneStatus) -> Int {
        switch tone {
        case .clear: return 2
        case .neutral: return 1
        case .caution: return 0
        case .alert: return -1
        default: return 1
        }
    }

    private func calculateAverageResponseTime(_ messages: [ConversationMessage]) -> TimeInterval {
        guard messages.count >= 2 else { return 0 }

        var totalTime: TimeInterval = 0
        for i in 1 ..< messages.count {
            totalTime += messages[i].timestamp.timeIntervalSince(messages[i - 1].timestamp)
        }

        return totalTime / Double(messages.count - 1)
    }

    private func calculateVariance(_ values: [Int]) -> Double {
        guard values.count > 1 else { return 0 }

        let mean = Double(values.reduce(0, +)) / Double(values.count)
        let squaredDifferences = values.map { pow(Double($0) - mean, 2) }
        return squaredDifferences.reduce(0, +) / Double(values.count - 1)
    }
}

// MARK: - Advanced Conversation Context Extraction

extension ConversationContextAnalyzer {
    // MARK: - Previous Message Reading

    func extractPreviousMessages(beforeText: String, afterText: String) -> [ConversationMessage] {
        // Combine full context
        let fullContext = beforeText + afterText

        // Parse messages from different communication apps
        let messages = parseMessagesFromContext(fullContext)

        return messages
    }

    private func parseMessagesFromContext(_ context: String) -> [ConversationMessage] {
        var messages: [ConversationMessage] = []

        // Try different parsing strategies based on app context
        if context.contains("You said:") || context.contains("They said:") {
            messages.append(contentsOf: parseStructuredMessages(context))
        } else if context.contains("\n\n") {
            messages.append(contentsOf: parseNewlineDelimitedMessages(context))
        } else {
            messages.append(contentsOf: parseContextualMessages(context))
        }

        return messages
    }

    private func parseStructuredMessages(_ context: String) -> [ConversationMessage] {
        var messages: [ConversationMessage] = []

        // Parse "You said:" and "They said:" patterns
        let patterns = [
            ("You said:", true),
            ("They said:", false),
            ("You:", true),
            ("Them:", false),
        ]

        for (pattern, isFromUser) in patterns {
            let components = context.components(separatedBy: pattern)
            for (index, component) in components.enumerated() {
                if index > 0 { // Skip first empty component
                    let messageText = component.trimmingCharacters(in: .whitespacesAndNewlines)
                        .components(separatedBy: .newlines).first ?? ""

                    if !messageText.isEmpty {
                        let message = ConversationMessage(
                            text: messageText,
                            timestamp: Date().addingTimeInterval(-Double(messages.count * 60)), // Estimate timestamps
                            isFromUser: isFromUser,
                            toneStatus: quickToneAnalysis(messageText),
                            attachmentStyle: nil
                        )
                        messages.append(message)
                    }
                }
            }
        }

        return messages.sorted { $0.timestamp < $1.timestamp }
    }

    private func parseNewlineDelimitedMessages(_ context: String) -> [ConversationMessage] {
        var messages: [ConversationMessage] = []

        // Split by double newlines (common in many messaging apps)
        let messageBlocks = context.components(separatedBy: "\n\n")

        for (index, block) in messageBlocks.enumerated() {
            let trimmedBlock = block.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedBlock.isEmpty, trimmedBlock.count > 2 {
                // Alternate between user and partner messages
                let isFromUser = index % 2 == 0

                let message = ConversationMessage(
                    text: trimmedBlock,
                    timestamp: Date().addingTimeInterval(-Double((messageBlocks.count - index) * 60)),
                    isFromUser: isFromUser,
                    toneStatus: quickToneAnalysis(trimmedBlock),
                    attachmentStyle: detectAttachmentStyle(trimmedBlock)
                )
                messages.append(message)
            }
        }

        return messages
    }

    private func parseContextualMessages(_ context: String) -> [ConversationMessage] {
        var messages: [ConversationMessage] = []

        // Parse single block of text into logical messages
        let sentences = context.components(separatedBy: CharacterSet(charactersIn: ".!?"))

        for (index, sentence) in sentences.enumerated() {
            let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedSentence.isEmpty, trimmedSentence.count > 10 {
                // Try to detect if it's a question or statement to determine speaker
                let isQuestion = trimmedSentence.contains("?") ||
                    trimmedSentence.lowercased().starts(with: "what") ||
                    trimmedSentence.lowercased().starts(with: "how") ||
                    trimmedSentence.lowercased().starts(with: "why") ||
                    trimmedSentence.lowercased().starts(with: "when") ||
                    trimmedSentence.lowercased().starts(with: "where")

                let message = ConversationMessage(
                    text: trimmedSentence,
                    timestamp: Date().addingTimeInterval(-Double((sentences.count - index) * 30)),
                    isFromUser: !isQuestion, // Questions more likely from partner
                    toneStatus: quickToneAnalysis(trimmedSentence),
                    attachmentStyle: detectAttachmentStyle(trimmedSentence)
                )
                messages.append(message)
            }
        }

        return messages
    }

    private func quickToneAnalysis(_ text: String) -> ToneStatus {
        let lowerText = text.lowercased()

        // Negative indicators
        if lowerText.contains("angry") || lowerText.contains("hate") ||
            lowerText.contains("stupid") || lowerText.contains("never") ||
            lowerText.contains("always") || lowerText.contains("!!")
        {
            return .alert
        }

        // Caution indicators
        if lowerText.contains("but") || lowerText.contains("however") ||
            lowerText.contains("frustrated") || lowerText.contains("upset") ||
            lowerText.contains("disappointed")
        {
            return .caution
        }

        // Positive indicators
        if lowerText.contains("thank") || lowerText.contains("love") ||
            lowerText.contains("appreciate") || lowerText.contains("great") ||
            lowerText.contains("amazing") || lowerText.contains("wonderful")
        {
            return .clear
        }

        return .neutral
    }

    private func detectAttachmentStyle(_ text: String) -> AttachmentStyle? {
        let lowerText = text.lowercased()

        // Anxious patterns
        if lowerText.contains("are you okay") || lowerText.contains("did i do something") ||
            lowerText.contains("please respond") || lowerText.contains("are we okay") ||
            lowerText.contains("i'm sorry")
        {
            return .anxious
        }

        // Avoidant patterns
        if lowerText.contains("fine") || lowerText.contains("whatever") ||
            lowerText.contains("doesn't matter") || lowerText.contains("busy") ||
            lowerText.contains("talk later")
        {
            return .avoidant
        }

        // Secure patterns
        if lowerText.contains("i understand") || lowerText.contains("let's talk") ||
            lowerText.contains("i feel") || lowerText.contains("can we") ||
            lowerText.contains("i appreciate")
        {
            return .secure
        }

        // Disorganized patterns
        if lowerText.contains("i don't know") || lowerText.contains("confused") ||
            lowerText.contains("mixed feelings") || lowerText.contains("complicated")
        {
            return .disorganized
        }

        return nil
    }

    // MARK: - Advanced Context Analysis

    func analyzeConversationFlow(messages: [ConversationMessage]) -> ConversationFlowAnalysis {
        let userMessages = messages.filter { $0.isFromUser }
        let partnerMessages = messages.filter { !$0.isFromUser }

        let responsePattern = analyzeResponsePattern(messages)
        let emotionalProgression = analyzeEmotionalProgression(messages)
        let communicationHealth = analyzeCommunicationHealth(messages)

        return ConversationFlowAnalysis(
            responsePattern: responsePattern,
            emotionalProgression: emotionalProgression,
            communicationHealth: communicationHealth,
            userToPartnerRatio: Double(userMessages.count) / Double(max(partnerMessages.count, 1)),
            averageResponseTime: calculateAverageResponseTime(messages),
            escalationRisk: calculateEscalationRisk(messages)
        )
    }

    private func analyzeResponsePattern(_ messages: [ConversationMessage]) -> ResponsePattern {
        guard messages.count > 1 else { return .insufficient }

        let responseTimes = calculateResponseTimes(messages)
        let avgResponseTime = responseTimes.reduce(0, +) / Double(responseTimes.count)

        if avgResponseTime < 30 { // Less than 30 seconds
            return .rapid
        } else if avgResponseTime < 300 { // Less than 5 minutes
            return .normal
        } else {
            return .slow
        }
    }

    private func analyzeEmotionalProgression(_ messages: [ConversationMessage]) -> EmotionalProgression {
        guard messages.count > 2 else { return .stable }

        let recentTones = messages.suffix(3).map { $0.toneStatus }

        if recentTones.contains(.alert) {
            return .deteriorating
        } else if recentTones.allSatisfy({ $0 == .clear }) {
            return .improving
        } else {
            return .stable
        }
    }

    private func analyzeCommunicationHealth(_ messages: [ConversationMessage]) -> CommunicationHealth {
        let toneDistribution = messages.reduce(into: [ToneStatus: Int]()) { counts, message in
            counts[message.toneStatus, default: 0] += 1
        }

        let negativeCount = (toneDistribution[.alert] ?? 0) + (toneDistribution[.caution] ?? 0)
        let positiveCount = toneDistribution[.clear] ?? 0

        let healthScore = Double(positiveCount) / Double(max(negativeCount + positiveCount, 1))

        if healthScore > 0.7 {
            return .healthy
        } else if healthScore > 0.3 {
            return .concerning
        } else {
            return .poor
        }
    }

    private func calculateResponseTimes(_ messages: [ConversationMessage]) -> [Double] {
        guard messages.count > 1 else { return [] }

        var responseTimes: [Double] = []
        for i in 1 ..< messages.count {
            let timeDiff = messages[i].timestamp.timeIntervalSince(messages[i - 1].timestamp)
            responseTimes.append(timeDiff)
        }

        return responseTimes
    }

    private func calculateEscalationRisk(_ messages: [ConversationMessage]) -> Double {
        guard messages.count > 1 else { return 0 }

        let recentMessages = messages.suffix(3)
        let alertCount = recentMessages.filter { $0.toneStatus == .alert }.count
        let cautionCount = recentMessages.filter { $0.toneStatus == .caution }.count

        return Double(alertCount * 2 + cautionCount) / Double(recentMessages.count * 2)
    }

    // MARK: - Context-Aware Suggestions

    func generateContextualSuggestions(
        currentText: String,
        previousMessages: [ConversationMessage],
        userAttachmentStyle: AttachmentStyle,
        partnerAttachmentStyle: AttachmentStyle
    ) -> [ContextualSuggestion] {
        var suggestions: [ContextualSuggestion] = []

        // Analyze conversation flow
        let flowAnalysis = analyzeConversationFlow(messages: previousMessages)

        // Generate suggestions based on context
        if flowAnalysis.escalationRisk > 0.7 {
            suggestions.append(contentsOf: generateDeEscalationSuggestions(currentText: currentText))
        }

        if flowAnalysis.communicationHealth == .poor {
            suggestions.append(contentsOf: generateRepairSuggestions(currentText: currentText))
        }

        if let lastMessage = previousMessages.last, !lastMessage.isFromUser {
            suggestions.append(contentsOf: generateResponseSuggestions(
                currentText: currentText,
                lastMessage: lastMessage,
                userStyle: userAttachmentStyle,
                partnerStyle: partnerAttachmentStyle
            ))
        }

        return suggestions
    }

    private func generateDeEscalationSuggestions(currentText _: String) -> [ContextualSuggestion] {
        return [
            ContextualSuggestion(
                text: "I can see this is important to you, and I want to understand your perspective.",
                confidence: 0.9,
                rationale: "De-escalation through validation and curiosity",
                suggestedAction: .replace
            ),
            ContextualSuggestion(
                text: "Let's take a step back. I care about resolving this together.",
                confidence: 0.8,
                rationale: "Refocus on collaborative problem-solving",
                suggestedAction: .replace
            ),
        ]
    }

    private func generateRepairSuggestions(currentText _: String) -> [ContextualSuggestion] {
        return [
            ContextualSuggestion(
                text: "I realize we might have gotten off track. Can we start fresh?",
                confidence: 0.85,
                rationale: "Communication repair and reset",
                suggestedAction: .replace
            ),
            ContextualSuggestion(
                text: "I want to make sure I'm hearing you correctly. Can you help me understand?",
                confidence: 0.8,
                rationale: "Active listening and clarification",
                suggestedAction: .replace
            ),
        ]
    }

    private func generateResponseSuggestions(
        currentText _: String,
        lastMessage _: ConversationMessage,
        userStyle: AttachmentStyle,
        partnerStyle: AttachmentStyle
    ) -> [ContextualSuggestion] {
        var suggestions: [ContextualSuggestion] = []

        // Tailor suggestions based on attachment style combination
        switch (userStyle, partnerStyle) {
        case (.anxious, .avoidant):
            suggestions.append(ContextualSuggestion(
                text: "I hear you. Take your time, and let me know when you're ready to talk.",
                confidence: 0.9,
                rationale: "Respects avoidant partner's need for space while maintaining connection",
                suggestedAction: .replace
            ))

        case (.secure, .anxious):
            suggestions.append(ContextualSuggestion(
                text: "I'm here and we're okay. Let's work through this together.",
                confidence: 0.95,
                rationale: "Provides reassurance for anxious partner",
                suggestedAction: .replace
            ))

        case (.avoidant, .secure):
            suggestions.append(ContextualSuggestion(
                text: "I appreciate your patience. I need a moment to process this.",
                confidence: 0.8,
                rationale: "Honest communication about processing needs",
                suggestedAction: .replace
            ))

        default:
            suggestions.append(ContextualSuggestion(
                text: "I understand. How can we move forward together?",
                confidence: 0.7,
                rationale: "General collaborative response",
                suggestedAction: .replace
            ))
        }

        return suggestions
    }
}

// MARK: - Extended Data Models

struct ConversationFlowAnalysis {
    let responsePattern: ResponsePattern
    let emotionalProgression: EmotionalProgression
    let communicationHealth: CommunicationHealth
    let userToPartnerRatio: Double
    let averageResponseTime: Double
    let escalationRisk: Double
}

struct ContextualSuggestion {
    let text: String
    let confidence: Double
    let rationale: String
    let suggestedAction: SuggestedAction
}

enum ResponsePattern {
    case rapid, normal, slow, insufficient
}

enum EmotionalProgression {
    case improving, stable, deteriorating
}

enum CommunicationHealth {
    case healthy, concerning, poor
}

enum SuggestedAction {
    case replace, append, rephrase
}
