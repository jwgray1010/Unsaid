//
//  OpenAIService.swift
//  Unsaid
//
//  OpenAI integration service for AI-powered conversation analysis and suggestions
//  Generates personalized responses based on attachment styles and relationship context
//
//  Created on 7/11/25.
//

import Foundation


// MARK: - OpenAI Service

class OpenAIService {
    
    // MARK: - Properties
    
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let session = URLSession.shared
    
    // MARK: - Initialization
    
    init() {
        // Load API key from .env file in assets folder
        if let path = Bundle.main.path(forResource: ".env", ofType: nil),
           let contents = try? String(contentsOfFile: path, encoding: .utf8),
           let apiKeyLine = contents.components(separatedBy: .newlines)
               .first(where: { $0.hasPrefix("OPENAI_API_KEY=") }) {
            self.apiKey = String(apiKeyLine.dropFirst("OPENAI_API_KEY=".count)).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let assetsPath = Bundle.main.path(forResource: "assets/.env", ofType: nil),
                  let contents = try? String(contentsOfFile: assetsPath, encoding: .utf8),
                  let apiKeyLine = contents.components(separatedBy: .newlines)
                      .first(where: { $0.hasPrefix("OPENAI_API_KEY=") }) {
            self.apiKey = String(apiKeyLine.dropFirst("OPENAI_API_KEY=".count)).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            // Fallback - this should be configured in your app's environment
            self.apiKey = ""
            print("⚠️ OpenAI API Key not found. Please ensure .env file exists in your bundle with OPENAI_API_KEY=your_key")
        }
    }
    
    // MARK: - Configuration Validation
    
    /// Validates that the OpenAI API key is properly configured
    func isConfigured() -> Bool {
        return !apiKey.isEmpty && apiKey.hasPrefix("sk-")
    }
    
    /// Returns masked version of API key for debugging (shows only first 7 characters)
    func getAPIKeyStatus() -> String {
        if apiKey.isEmpty {
            return "❌ API Key not configured"
        } else if apiKey.count > 7 {
            return "✅ API Key configured: \(String(apiKey.prefix(7)))..."
        } else {
            return "⚠️ API Key configured but may be invalid"
        }
    }
    
    // MARK: - AI-Powered Suggestion Generation
    
    /// Generates AI-powered suggestions based on comprehensive personality data and relationship context
    func generatePersonalizedSuggestions(
        originalText: String,
        userAttachmentStyle: AttachmentStyle,
        partnerAttachmentStyle: AttachmentStyle,
        relationshipContext: RelationshipContext,
        toneStatus: ToneStatus,
        conversationHistory: [ConversationMessage] = [],
        personalityContext: [String: Any] = [:]
    ) async throws -> [AdvancedSuggestion] {
        
        let prompt = buildPersonalizedPrompt(
            originalText: originalText,
            userStyle: userAttachmentStyle,
            partnerStyle: partnerAttachmentStyle,
            context: relationshipContext,
            tone: toneStatus,
            history: conversationHistory,
            personalityContext: personalityContext
        )
        
        let response = try await callOpenAI(prompt: prompt)
        return parseAISuggestions(response: response, userStyle: userAttachmentStyle, context: relationshipContext)
    }
    
    /// Generates AI-powered repair scripts with comprehensive personality awareness
    func generatePersonalizedRepairScript(
        conflict: String,
        userAttachmentStyle: AttachmentStyle,
        partnerAttachmentStyle: AttachmentStyle,
        relationshipContext: RelationshipContext,
        personalityContext: [String: Any] = [:]
    ) async throws -> String {
        
        let prompt = buildRepairScriptPrompt(
            conflict: conflict,
            userStyle: userAttachmentStyle,
            partnerStyle: partnerAttachmentStyle,
            context: relationshipContext,
            personalityContext: personalityContext
        )
        
        let response = try await callOpenAI(prompt: prompt)
        return extractRepairScript(from: response)
    }
    
    /// Generates contextually appropriate message improvements with comprehensive personality data
    func generateMessageImprovement(
        originalText: String,
        targetTone: ToneStatus,
        userAttachmentStyle: AttachmentStyle,
        relationshipContext: RelationshipContext,
        personalityContext: [String: Any] = [:]
    ) async throws -> String {
        
        let prompt = buildImprovementPrompt(
            original: originalText,
            targetTone: targetTone,
            userStyle: userAttachmentStyle,
            context: relationshipContext,
            personalityContext: personalityContext
        )
        
        let response = try await callOpenAI(prompt: prompt)
        return extractImprovedMessage(from: response)
    }
    
    // MARK: - Prompt Engineering
    
    private func buildPersonalizedPrompt(
        originalText: String,
        userStyle: AttachmentStyle,
        partnerStyle: AttachmentStyle,
        context: RelationshipContext,
        tone: ToneStatus,
        history: [ConversationMessage],
        personalityContext: [String: Any] = [:]
    ) -> String {
        
        let userStyleDescription = getAttachmentStyleDescription(userStyle)
        let partnerStyleDescription = getAttachmentStyleDescription(partnerStyle)
        let contextDescription = getRelationshipContextDescription(context)
        let toneDescription = getToneStatusDescription(tone)
        
        var historyContext = ""
        if !history.isEmpty {
            let recentMessages = history.suffix(3).map { "\($0.sender.displayName): \($0.text)" }
            historyContext = "\n\nRecent conversation:\n\(recentMessages.joined(separator: "\n"))"
        }
        
        // Build comprehensive personality context
        var personalityDetails = ""
        if !personalityContext.isEmpty {
            personalityDetails = "\n\nCOMPREHENSIVE PERSONALITY PROFILE:"
            
            if let personalityType = personalityContext["personality_type"] as? String {
                personalityDetails += "\n- Personality Type: \(personalityType)"
            }
            
            if let communicationStyle = personalityContext["communication_style"] as? String {
                personalityDetails += "\n- Communication Style: \(communicationStyle)"
            }
            
            if let preferences = personalityContext["communication_preferences"] as? [String: Any] {
                personalityDetails += "\n- Communication Preferences: \(preferences)"
            }
            
            if let scores = personalityContext["personality_scores"] as? [String: Any] {
                personalityDetails += "\n- Personality Scores: \(scores)"
            }
        }
        
        return """
        You are an expert relationship counselor and communication coach specializing in attachment theory and personality-based communication.
        
        USER CONTEXT:
        - User's attachment style: \(userStyle.displayName) (\(userStyleDescription))
        - Partner's attachment style: \(partnerStyle.displayName) (\(partnerStyleDescription))
        - Relationship context: \(context.displayName) (\(contextDescription))
        - Current message tone: \(tone.displayName) (\(toneDescription))
        \(personalityDetails)
        \(historyContext)
        
        USER'S MESSAGE: "\(originalText)"
        
        Please provide 3-5 alternative ways to express this message that:
        1. Honor the user's \(userStyle.displayName) attachment style communication needs
        2. Are tailored to their specific personality type and communication style
        3. Are likely to be well-received by someone with \(partnerStyle.displayName) attachment style
        4. Improve the emotional tone while maintaining the core message
        5. Are appropriate for a \(context.displayName) relationship
        6. Help build secure attachment patterns
        7. Reflect their unique personality traits and communication preferences
        
        For each suggestion, provide:
        - The improved message
        - Brief explanation of why this works for their attachment dynamic and personality
        - Expected emotional outcome
        
        Format as JSON array with objects containing: "text", "reasoning", "expectedOutcome", "priority" (1-5).
        """
    }
    
    private func buildRepairScriptPrompt(
        conflict: String,
        userStyle: AttachmentStyle,
        partnerStyle: AttachmentStyle,
        context: RelationshipContext,
        personalityContext: [String: Any] = [:]
    ) -> String {
        
        // Build personality context for repair script
        var personalityDetails = ""
        if !personalityContext.isEmpty {
            personalityDetails = "\n\nUSER PERSONALITY PROFILE:"
            
            if let personalityType = personalityContext["personality_type"] as? String {
                personalityDetails += "\n- Personality Type: \(personalityType)"
            }
            
            if let communicationStyle = personalityContext["communication_style"] as? String {
                personalityDetails += "\n- Communication Style: \(communicationStyle)"
            }
            
            if let preferences = personalityContext["communication_preferences"] as? [String: Any] {
                personalityDetails += "\n- Communication Preferences: \(preferences)"
            }
        }
        
        return """
        You are a relationship repair specialist with expertise in attachment theory and personality-based communication. Create a step-by-step communication script for resolving this conflict:
        
        CONFLICT: "\(conflict)"
        USER ATTACHMENT STYLE: \(userStyle.displayName)
        PARTNER ATTACHMENT STYLE: \(partnerStyle.displayName)
        RELATIONSHIP TYPE: \(context.displayName)
        \(personalityDetails)
        
        Provide a 3-step repair script that:
        1. Acknowledges the issue in a way that feels safe for both attachment styles and honors the user's personality
        2. Takes appropriate responsibility without triggering defensive responses
        3. Offers a path forward that builds security and connection
        4. Is tailored to the user's specific personality type and communication style
        
        Make it specific to their attachment dynamic, personality profile, and relationship context.
        """
    }
    
    private func buildImprovementPrompt(
        original: String,
        targetTone: ToneStatus,
        userStyle: AttachmentStyle,
        context: RelationshipContext,
        personalityContext: [String: Any] = [:]
    ) -> String {
        
        // Build personality context for improvement
        var personalityDetails = ""
        if !personalityContext.isEmpty {
            personalityDetails = "\n\nUSER PERSONALITY PROFILE:"
            
            if let personalityType = personalityContext["personality_type"] as? String {
                personalityDetails += "\n- Personality Type: \(personalityType)"
            }
            
            if let communicationStyle = personalityContext["communication_style"] as? String {
                personalityDetails += "\n- Communication Style: \(communicationStyle)"
            }
            
            if let preferences = personalityContext["communication_preferences"] as? [String: Any] {
                personalityDetails += "\n- Communication Preferences: \(preferences)"
            }
        }
        
        return """
        Improve this message to achieve a \(targetTone.displayName) tone while honoring the sender's \(userStyle.displayName) attachment style and personality in a \(context.displayName) relationship:
        
        ORIGINAL: "\(original)"
        USER ATTACHMENT STYLE: \(userStyle.displayName)
        RELATIONSHIP TYPE: \(context.displayName)
        \(personalityDetails)
        
        Provide one improved version that maintains the core message but expresses it in a way that:
        - Achieves the target tone
        - Feels authentic to someone with \(userStyle.displayName) attachment style
        - Reflects their unique personality type and communication style
        - Is appropriate for \(context.displayName) relationship context
        - Promotes emotional safety and connection
        
        Return only the improved message.
        """
    }
    
    // MARK: - OpenAI API Integration
    
    private func callOpenAI(prompt: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw OpenAIError.noAPIKey
        }
        
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                [
                    "role": "system",
                    "content": "You are an expert relationship counselor specializing in attachment theory and therapeutic communication."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": 1000,
            "temperature": 0.7
        ]
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw OpenAIError.invalidRequest
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenAIError.requestFailed
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        return content
    }
    
    // MARK: - Response Parsing
    
    private func parseAISuggestions(response: String, userStyle: AttachmentStyle, context: RelationshipContext) -> [AdvancedSuggestion] {
        // Try to parse JSON response first
        if let data = response.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            return json.compactMap { dict in
                guard let text = dict["text"] as? String,
                      let reasoning = dict["reasoning"] as? String,
                      let expectedOutcome = dict["expectedOutcome"] as? String,
                      let priority = dict["priority"] as? Int else { return nil }
                
                return AdvancedSuggestion(
                    text: text,
                    type: .toneImprovement,
                    priority: SuggestionPriority(rawValue: priority - 1) ?? .medium,
                    interventionType: .enhancement,
                    attachmentStyleSpecific: true,
                    reasoning: reasoning,
                    expectedOutcome: expectedOutcome,
                    attachmentContext: userStyle,
                    relationshipContext: context
                )
            }
        }
        
        // Fallback: parse as plain text
        let suggestions = response.components(separatedBy: "\n\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .enumerated()
            .map { index, suggestion in
                AdvancedSuggestion(
                    text: suggestion.trimmingCharacters(in: .whitespacesAndNewlines),
                    type: .toneImprovement,
                    priority: index == 0 ? .high : .medium,
                    interventionType: .enhancement,
                    attachmentStyleSpecific: true,
                    reasoning: "AI-generated suggestion based on attachment style compatibility",
                    attachmentContext: userStyle,
                    relationshipContext: context
                )
            }
        
        return Array(suggestions.prefix(5)) // Limit to 5 suggestions
    }
    
    private func extractRepairScript(from response: String) -> String {
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractImprovedMessage(from response: String) -> String {
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Helper Methods
    
    private func getAttachmentStyleDescription(_ style: AttachmentStyle) -> String {
        switch style {
        case .secure:
            return "Comfortable with intimacy and autonomy, communicates directly and empathetically"
        case .anxious:
            return "Seeks reassurance and connection, may become preoccupied with relationship security"
        case .avoidant:
            return "Values independence, may struggle with emotional expression and intimacy"
        case .disorganized:
            return "Inconsistent patterns, may struggle with emotional regulation and communication"
        case .unknown:
            return "Attachment style not yet determined"
        }
    }
    
    private func getRelationshipContextDescription(_ context: RelationshipContext) -> String {
        switch context {
        case .romantic:
            return "Intimate partnership requiring emotional attunement and vulnerability"
        case .family:
            return "Family relationship with established dynamics and shared history"
        case .friendship:
            return "Close personal relationship based on mutual support and understanding"
        case .professional:
            return "Work-related interaction requiring professionalism and respect"
        case .acquaintance:
            return "Casual relationship with social boundaries and politeness"
        case .unknown:
            return "Relationship context not specified"
        }
    }
    
    private func getToneStatusDescription(_ status: ToneStatus) -> String {
        switch status {
        case .clear:
            return "Positive, constructive communication"
        case .caution:
            return "Potentially problematic tone that may cause misunderstanding"
        case .alert:
            return "High-risk communication likely to cause conflict or hurt"
        case .neutral:
            return "Balanced, neither particularly positive nor negative"
        case .analyzing:
            return "Tone analysis in progress"
        }
    }
}

// MARK: - OpenAI Error Types

enum OpenAIError: Error, LocalizedError {
    case noAPIKey
    case invalidRequest
    case requestFailed
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "OpenAI API key not configured"
        case .invalidRequest:
            return "Invalid request format"
        case .requestFailed:
            return "OpenAI API request failed"
        case .invalidResponse:
            return "Invalid response from OpenAI"
        }
    }
}
