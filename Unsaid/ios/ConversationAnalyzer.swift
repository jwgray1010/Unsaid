//
//  ConversationAnalyzer.swift
//  UnsaidKeyboard
//
//  Modular conversation analysis orchestrator for Unsaid
//  Coordinates between AdvancedToneAnalysisEngine, AdvancedSuggestionsEngine, and AIPredictiveEngine
//
//  Refactored by Modularization on 1/23/25.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// Import shared types for communication analysis
// Note: In the same module, types are automatically available

// MARK: - Main Conversation Analyzer Class
class ConversationAnalyzer {
    
    // MARK: - Modular Engine Dependencies
    private let toneAnalysisEngine: AdvancedToneAnalysisEngine
    private let suggestionsEngine: AdvancedSuggestionsEngine
    private let predictiveEngine: AIPredictiveEngine
    
    // MARK: - Initialization
    init() {
        self.toneAnalysisEngine = AdvancedToneAnalysisEngine()
        self.suggestionsEngine = AdvancedSuggestionsEngine(toneAnalysisEngine: self.toneAnalysisEngine)
        self.predictiveEngine = AIPredictiveEngine()
    }
    
    // MARK: - Main Analysis Methods (Orchestration)
    
    /// Generates simple text improvement based on tone status and attachment awareness
    func generateSimpleImprovement(for text: String, status: ToneStatus) -> String {
        return suggestionsEngine.generateSimpleImprovement(for: text, status: status)
    }

    
    // MARK: - Tone Analysis (Delegated to AdvancedToneAnalysisEngine)
    
    /// Main tone analysis method - delegates to advanced tone analysis engine
    func analyzeTone(_ text: String) -> ToneStatus {
        return toneAnalysisEngine.analyzeTone(text)
    }
    
    /// Attachment style detection - delegates to advanced tone analysis engine
    func detectAttachmentStyle(_ text: String) -> AttachmentStyle {
        return toneAnalysisEngine.detectAttachmentStyle(text)
    }
    
    /// Advanced communication pattern detection - delegates to advanced tone analysis engine
    func detectAdvancedCommunicationPattern(_ text: String) -> CommunicationPattern {
        return toneAnalysisEngine.detectAdvancedCommunicationPattern(text)
    }
    
    /// Relationship context detection - delegates to advanced tone analysis engine
    func detectRelationshipContext(_ text: String) -> RelationshipContext {
        return toneAnalysisEngine.detectRelationshipContext(text)
    }
    
    /// Emotional state detection - delegates to advanced tone analysis engine
    func detectEmotionalState(_ text: String) -> [String] {
        return toneAnalysisEngine.detectEmotionalState(text)
    }
    
    // MARK: - Suggestion Generation (Delegated to AdvancedSuggestionsEngine)
    
    /// Main suggestion generation method - delegates to advanced suggestions engine
    func generateSuggestions(for text: String) -> [String] {
        return suggestionsEngine.generateSuggestions(for: text)
    }
    
    /// Advanced suggestion generation - delegates to advanced suggestions engine
    func generateAdvancedSuggestions(
        for currentText: String,
        toneStatus: ToneStatus,
        conversationContext: String? = nil
    ) -> [AdvancedSuggestion] {
        return suggestionsEngine.generateAdvancedSuggestions(
            for: currentText,
            toneStatus: toneStatus,
            conversationContext: conversationContext
        )
    }
    
    /// Cross-style communication suggestion generation - delegates to advanced suggestions engine
    func generateCrossStyleSuggestion(senderStyle: AttachmentStyle, receiverStyle: AttachmentStyle) -> String {
        return suggestionsEngine.generateCrossStyleSuggestion(senderStyle: senderStyle, receiverStyle: receiverStyle)
    }
    
    /// Repair script generation - delegates to advanced suggestions engine
    func generateRepairScript(for attachmentStyle: AttachmentStyle, context: String = "") -> String {
        return suggestionsEngine.generateRepairScript(for: attachmentStyle, context: context)
    }
    
    /// De-escalation suggestion generation - delegates to advanced suggestions engine
    func generateDeescalationSuggestion(_ text: String) -> String? {
        return suggestionsEngine.generateDeescalationSuggestion(text)
    }
    
    /// Mindfulness prompt generation - delegates to advanced suggestions engine
    func generateMindfulnessPrompt(_ text: String) -> String {
        return suggestionsEngine.generateMindfulnessPrompt(text)
    }
    
    /// Auto-fix generation - delegates to advanced suggestions engine
    func generateAutoFix(for text: String, toneStatus: ToneStatus) -> String {
        return suggestionsEngine.generateAutoFix(for: text, toneStatus: toneStatus)
    }
    
    // MARK: - Predictive AI (Delegated to AIPredictiveEngine)
    
    /// Message prediction - delegates to AI predictive engine
    func predictMessage(
        conversationHistory: [ConversationMessage],
        userProfile: UserProfile,
        partnerProfile: PartnerProfile,
        childProfile: ChildProfile? = nil
    ) -> MessagePrediction {
        return predictiveEngine.predictMessage(
            conversationHistory: conversationHistory,
            userProfile: userProfile,
            partnerProfile: partnerProfile,
            childProfile: childProfile
        )
    }
    
    /// Conversation trajectory prediction - delegates to AI predictive engine
    func predictConversationTrajectory(
        conversationHistory: [ConversationMessage],
        userProfile: UserProfile,
        partnerProfile: PartnerProfile,
        childProfile: ChildProfile? = nil
    ) -> ConversationTrajectory {
        return predictiveEngine.predictConversationTrajectory(
            conversationHistory: conversationHistory,
            userProfile: userProfile,
            partnerProfile: partnerProfile,
            childProfile: childProfile
        )
    }
    
    /// Relationship health prediction - delegates to AI predictive engine
    func predictRelationshipHealth(
        conversationHistory: [ConversationMessage],
        userProfile: UserProfile,
        partnerProfile: PartnerProfile,
        childProfile: ChildProfile? = nil
    ) -> RelationshipHealthPrediction {
        return predictiveEngine.predictRelationshipHealth(
            conversationHistory: conversationHistory,
            userProfile: userProfile,
            partnerProfile: partnerProfile,
            childProfile: childProfile
        )
    }
    
    /// Crisis prevention prediction - delegates to AI predictive engine
    func predictCrisisPrevention(
        conversationHistory: [ConversationMessage],
        userProfile: UserProfile,
        partnerProfile: PartnerProfile,
        childProfile: ChildProfile? = nil
    ) -> CrisisPreventionPrediction {
        return predictiveEngine.predictCrisisPrevention(
            conversationHistory: conversationHistory,
            userProfile: userProfile,
            partnerProfile: partnerProfile,
            childProfile: childProfile
        )
    }
    
    /// Child impact prediction - delegates to AI predictive engine
    func predictChildImpact(
        conversationHistory: [ConversationMessage],
        userProfile: UserProfile,
        partnerProfile: PartnerProfile,
        childProfile: ChildProfile
    ) -> ChildImpactPrediction {
        return predictiveEngine.predictChildImpact(
            conversationHistory: conversationHistory,
            userProfile: userProfile,
            partnerProfile: partnerProfile,
            childProfile: childProfile
        )
    }
    
    /// Emotional intelligence prediction - delegates to AI predictive engine
    func predictEmotionalIntelligence(
        conversationHistory: [ConversationMessage],
        userProfile: UserProfile,
        partnerProfile: PartnerProfile,
        childProfile: ChildProfile? = nil
    ) -> EmotionalIntelligencePrediction {
        return predictiveEngine.predictEmotionalIntelligence(
            conversationHistory: conversationHistory,
            userProfile: userProfile,
            partnerProfile: partnerProfile,
            childProfile: childProfile
        )
    }
    
    /// Optimal timing prediction - delegates to AI predictive engine
    func predictOptimalTiming(
        conversationHistory: [ConversationMessage],
        userProfile: UserProfile,
        partnerProfile: PartnerProfile,
        childProfile: ChildProfile? = nil
    ) -> OptimalTimingPrediction {
        return predictiveEngine.predictOptimalTiming(
            conversationHistory: conversationHistory,
            userProfile: userProfile,
            partnerProfile: partnerProfile,
            childProfile: childProfile
        )
    }
    
    // MARK: - User Profile Management (Delegated to AdvancedSuggestionsEngine)
    
    /// Update user attachment style - delegates to advanced suggestions engine
    func updateUserAttachmentStyle(_ style: AttachmentStyle) {
        suggestionsEngine.updateUserAttachmentStyle(style)
    }
    
    /// Update partner attachment style - delegates to advanced suggestions engine
    func updatePartnerAttachmentStyle(_ style: AttachmentStyle) {
        suggestionsEngine.updatePartnerAttachmentStyle(style)
    }
    
    /// Update relationship context - delegates to advanced suggestions engine
    func updateRelationshipContext(_ context: RelationshipContext) {
        suggestionsEngine.updateRelationshipContext(context)
    }
    
    // MARK: - Analytics and Data Collection (Delegated to AdvancedSuggestionsEngine)
    
    /// Record suggestion usage - delegates to advanced suggestions engine
    func recordSuggestionUsage(_ suggestion: AdvancedSuggestion, accepted: Bool) {
        suggestionsEngine.recordSuggestionUsage(suggestion, accepted: accepted)
    }
    
    /// Get suggestion usage analytics - delegates to advanced suggestions engine
    func getSuggestionUsageAnalytics() -> [String: Any] {
        return suggestionsEngine.getSuggestionUsageAnalytics()
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

    // MARK: - Trauma-Informed Communication Analysis (Delegated to AdvancedToneAnalysisEngine)
    
    /// Trauma response detection - delegates to advanced tone analysis engine
    func detectTraumaResponse(_ text: String) -> String? {
        return toneAnalysisEngine.detectTraumaResponse(text)
    }
}

// MARK: - Conversation Context Analysis (Delegated to AdvancedSuggestionsEngine)

extension ConversationAnalyzer {
    
    // MARK: - Main Context Analysis Methods
    
    /// Analyze conversation flow - delegates to advanced suggestions engine
    func analyzeConversationFlow(_ history: ConversationHistory) -> ConversationAnalysis {
        return suggestionsEngine.analyzeConversationFlow(history)
    }

    /// Extract conversation context - delegates to advanced suggestions engine
    func extractConversationContext(fromTextProxy proxy: AnyObject) -> ConversationHistory? {
        return suggestionsEngine.extractConversationContext(fromTextProxy: proxy)
    }

    /// Extract previous messages - delegates to advanced suggestions engine
    func extractPreviousMessages(beforeText: String, afterText: String) -> [ConversationMessage] {
        return suggestionsEngine.extractPreviousMessages(beforeText: beforeText, afterText: afterText)
    }

    /// Analyze conversation flow with messages - delegates to advanced suggestions engine
    func analyzeConversationFlow(messages: [ConversationMessage]) -> ConversationFlowAnalysis {
        return suggestionsEngine.analyzeConversationFlow(messages: messages)
    }

    /// Generate contextual suggestions - delegates to advanced suggestions engine
    func generateContextualSuggestions(
        currentText: String,
        previousMessages: [ConversationMessage],
        userAttachmentStyle: AttachmentStyle,
        partnerAttachmentStyle: AttachmentStyle
    ) -> [ContextualSuggestion] {
        return suggestionsEngine.generateContextualSuggestions(
            currentText: currentText,
            previousMessages: previousMessages,
            userAttachmentStyle: userAttachmentStyle,
            partnerAttachmentStyle: partnerAttachmentStyle
        )
    }
}

// MARK: - AI-Powered Features (NEW)

extension ConversationAnalyzer {
    
    /// Generates AI-enhanced suggestions using OpenAI based on personality types
    func generateAIEnhancedSuggestions(
        for text: String,
        toneStatus: ToneStatus? = nil,
        conversationHistory: [ConversationMessage] = []
    ) async -> [AdvancedSuggestion] {
        return await suggestionsEngine.generateAIEnhancedSuggestions(
            for: text,
            toneStatus: toneStatus,
            conversationHistory: conversationHistory
        )
    }
    
    /// Generates AI-powered message improvement
    func generateAIMessageImprovement(
        for text: String,
        targetTone: ToneStatus = .clear
    ) async -> String {
        return await suggestionsEngine.generateAIMessageImprovement(
            for: text,
            targetTone: targetTone
        )
    }
    
    /// Generates AI-powered repair script for relationship conflicts
    func generateAIRepairScript(for conflict: String) async -> String {
        return await suggestionsEngine.generateAIRepairScript(for: conflict)
    }
}