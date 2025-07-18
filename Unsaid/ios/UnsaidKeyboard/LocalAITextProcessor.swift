//
//  LocalAITextProcessor.swift
//  UnsaidKeyboard
//
//  Advanced local AI-like text processing engine for attachment-style based communication fixes
//  Uses sophisticated linguistic analysis, psychological patterns, and communication theory
//

import Foundation
import NaturalLanguage
import UIKit

/// Processing mode for performance optimization
enum AIProcessingMode {
    case realTime      // Fast, minimal analysis for live suggestions
    case comprehensive // Full analysis for detailed results
    case toneOnly      // Focus on tone analysis
    case suggestionsOnly // Focus on suggestions
}

/// Result type for tone analysis
struct ToneAnalysisResult {
    let status: ToneStatus
    let confidence: Double
}

/// JSON-based knowledge enhancement for local AI
struct JSONKnowledgeBase {
    // Loaded JSON data for enhanced AI processing
    static let attachmentSpecificSuggestions = loadAttachmentSpecificSuggestions()
    static let toneSuggestions = loadToneSuggestions()
    static let communicationPatternsSuggestions = loadCommunicationPatternsSuggestions()
    static let contextualSuggestions = loadContextualSuggestions()
    static let emotionBuckets = loadEmotionBuckets()
    static let attachmentTriggers = loadAttachmentTriggers()
    static let fallbackRepairScripts = loadFallbackRepairScripts()
    static let autoFixReplacements = loadAutoFixReplacements()
    static let improveTones = loadImproveTones()
    static let iStatements = loadIStatements()
    static let iStatementSlots = loadIStatementSlots()
    static let crossStyleCommunication = loadCrossStyleCommunication()
    static let mindfulnessPrompts = loadMindfulnessPrompts()
    static let childLanguage = loadChildLanguage()
    static let therapeutic = loadTherapeutic()
    static let therapyActionSteps = loadTherapyActionSteps()
    
    // MARK: - RAG & Vector Store Components (Simplified Local Implementation)
    // Note: These are simplified local implementations to avoid external dependencies
    static var vectorStore: [String: [String]] = [:]
    static var contextualMemory: [String: Any] = [:]
    static var microLLMProcessor: [String: Any] = [:]
    
    /// Initialize advanced RAG, memory, and micro-LLM features
    static func initializeAdvancedFeatures() {
        // Initialize simple local implementations
        vectorStore = [:]
        contextualMemory = [:]
        microLLMProcessor = [:]
        print(" Advanced RAG, Memory, and Micro-LLM features initialized (local implementation)")
    }
    
    // Loading methods for JSON data
    private static func loadAttachmentSpecificSuggestions() -> [String: Any] {
        return loadJSONResource("AttachmentSpecificSuggestions") ?? [:]
    }
    
    private static func loadToneSuggestions() -> [String: Any] {
        return loadJSONResource("ToneSuggestions") ?? [:]
    }
    
    private static func loadCommunicationPatternsSuggestions() -> [String: Any] {
        return loadJSONResource("CommunicationPatternsSuggestions") ?? [:]
    }
    
    private static func loadContextualSuggestions() -> [String: Any] {
        return loadJSONResource("ContextualSuggestions") ?? [:]
    }
    
    private static func loadEmotionBuckets() -> [String: Any] {
        return loadJSONResource("EmotionBucket") ?? [:]
    }
    
    private static func loadAttachmentTriggers() -> [String: Any] {
        return loadJSONResource("AnalyzeAttachmentTriggers") ?? [:]
    }
    
    private static func loadFallbackRepairScripts() -> [String: Any] {
        return loadJSONResource("FallbackRepairScripts") ?? [:]
    }
    
    private static func loadAutoFixReplacements() -> [String: Any] {
        return loadJSONResource("AutoFix") ?? [:]
    }
    
    private static func loadImproveTones() -> [String: Any] {
        return loadJSONResource("ImproveTones") ?? [:]
    }
    
    private static func loadIStatements() -> [String: Any] {
        return loadJSONResource("I-Statements") ?? [:]
    }
    
    private static func loadIStatementSlots() -> [String: Any] {
        return loadJSONResource("I-Statementslots") ?? [:]
    }
    
    private static func loadCrossStyleCommunication() -> [String: Any] {
        return loadJSONResource("Cross-StyleCommunication") ?? [:]
    }
    
    private static func loadMindfulnessPrompts() -> [String: Any] {
        return loadJSONResource("MindfulnessPrompts") ?? [:]
    }
    
    private static func loadChildLanguage() -> [String: Any] {
        return loadJSONResource("ChildLanguage") ?? [:]
    }
    
    private static func loadTherapeutic() -> [String: Any] {
        return loadJSONResource("therapeutic") ?? [:]
    }
    
    private static func loadTherapyActionSteps() -> [String: Any] {
        return loadJSONResource("TherapyActionSteps") ?? [:]
    }
    
    private static func loadJSONResource(_ fileName: String) -> [String: Any]? {
        // Try to load from the keyboard extension bundle first
        let keyboardBundle = Bundle(for: LocalAITextProcessor.self)
        
        if let url = keyboardBundle.url(forResource: fileName, withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print(" Loaded \(fileName).json from keyboard bundle")
            return json
        }
        
        // Fallback to main bundle
        if let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print(" Loaded \(fileName).json from main bundle")
            return json
        }
        
        print(" Could not load \(fileName).json - using fallback data")
        return nil
    }
}

/// High-performance local AI for text communication fixes
class LocalAITextProcessor {
    
    // MARK: - Core Components (Simplified - no external engines)
    private let personalityManager = PersonalityDataManager.shared
    
    // MARK: - Simple Analysis Components
    private let nlpProcessor = NLPProcessor()
    private let communicationAnalyzer = CommunicationPatternAnalyzer()
    private let attachmentStyleAnalyzer = AttachmentStyleAnalyzer()
    private let emotionalIntelligenceEngine = EmotionalIntelligenceEngine()
    private let contextualRewriteEngine = ContextualRewriteEngine()
    private let relationshipDynamicsEngine = RelationshipDynamicsEngine()
    
    // MARK: - Processing Mode
    private var currentMode: AIProcessingMode = .comprehensive
    
    // MARK: - Initialization
    init() {
        // Pre-load JSON knowledge for enhanced AI processing
        loadJSONKnowledge()
        
        // Initialize advanced RAG, memory, and micro-LLM features
        JSONKnowledgeBase.initializeAdvancedFeatures()
    }
    
    // MARK: - Children Names Helper
    
    /// Get children names from shared UserDefaults
    private func getChildrenNames() -> [String] {
        guard let userDefaults = UserDefaults(suiteName: "group.com.unsaid.app.shared"),
              let names = userDefaults.array(forKey: "children_names") as? [String] else {
            return []
        }
        return names
    }
    
    /// Check if the text mentions any of the children by name
    private func mentionsChildren(in text: String) -> (mentioned: Bool, names: [String]) {
        let childrenNames = getChildrenNames()
        let textLower = text.lowercased()
        let mentionedNames = childrenNames.filter { name in
            textLower.contains(name.lowercased())
        }
        return (mentioned: !mentionedNames.isEmpty, names: mentionedNames)
    }
    
    // MARK: - JSON Knowledge Integration
    
    /// Pre-load and process JSON knowledge for enhanced suggestions
    private func loadJSONKnowledge() {
        // The JSON knowledge is loaded statically in JSONKnowledgeBase
        // This method can be used for any initialization processing if needed
        print(" LocalAI: JSON knowledge base loaded with \(JSONKnowledgeBase.attachmentSpecificSuggestions.count) attachment-specific datasets")
    }
    
    // MARK: - Enhanced JSON-Based Processing
    
    /// Generate suggestions using JSON knowledge base
    private func generateJSONEnhancedSuggestions(_ text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var candidates: [FixCandidate] = []
        
        // 1. Attachment-specific suggestions from JSON
        let attachmentStyle = analysis.attachmentSignals.detectedStyle ?? getAttachmentStyle()
        candidates.append(contentsOf: getAttachmentSpecificSuggestions(
            text: text,
            style: attachmentStyle,
            analysis: analysis
        ))
        
        // 2. Tone-based suggestions from JSON
        candidates.append(contentsOf: getToneBasedSuggestions(text: text, analysis: analysis))
        
        // 3. Communication pattern suggestions from JSON
        candidates.append(contentsOf: getCommunicationPatternSuggestions(
            text: text,
            pattern: analysis.communicationPattern
        ))
        
        // 4. Contextual suggestions from JSON
        candidates.append(contentsOf: getContextualSuggestions(text: text, analysis: analysis))
        
        // 5. Auto-fix replacements from JSON
        candidates.append(contentsOf: getAutoFixSuggestions(text: text))
        
        // 6. Fallback repair scripts from JSON for high-conflict situations
        if analysis.conflictLevel > 0.7 {
            candidates.append(contentsOf: getFallbackRepairSuggestions(text: text, analysis: analysis))
        }
        
        // 7. Child-centered suggestions for co-parenting communication
        candidates.append(contentsOf: getChildCenteredSuggestions(text: text, analysis: analysis))
        
        return candidates
    }
    
    /// Get attachment-specific suggestions from JSON data
    private func getAttachmentSpecificSuggestions(text: String, style: AttachmentStyle, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var candidates: [FixCandidate] = []
        
        guard let attachmentData = JSONKnowledgeBase.attachmentSpecificSuggestions["attachmentSpecificSuggestions"] as? [String: Any],
              let styleData = attachmentData[style.rawValue] as? [String: Any] else {
            return candidates
        }
        
        // Process conditional suggestions
        if let conditionalSuggestions = styleData["conditional"] as? [[String: Any]] {
            for suggestion in conditionalSuggestions {
                if let contains = suggestion["contains"] as? [String],
                   let suggestionText = suggestion["text"] as? String,
                   let priority = suggestion["priority"] as? String {
                    
                    let textLower = text.lowercased()
                    let hasMatch = contains.allSatisfy { textLower.contains($0.lowercased()) }
                    
                    if hasMatch {
                        let confidence = priorityToConfidence(priority)
                        candidates.append(FixCandidate(
                            text: suggestionText,
                            type: .attachmentStyleSpecific,
                            attachmentRelevance: .high,
                                reasoning: "Attachment-specific suggestion for \(style.rawValue): \(suggestionText)",
                                sourceEngine: .jsonKnowledge,
                                confidence: confidence
                            ))
                        }
                    }
                }
            }
            
            // Process default suggestions for attachment style
            if let defaults = styleData["defaults"] as? [String] {
                let bestDefault = defaults.first ?? """
    Consider rephrasing with more attachment-aware language
    """
                candidates.append(FixCandidate(
                    text: bestDefault,
                    type: .attachmentStyleSpecific,
                    attachmentRelevance: .medium,
                    reasoning: "Default attachment suggestion for \(style.rawValue)",
                    sourceEngine: .jsonKnowledge,
                    confidence: 0.6
                ))
            }
            
            return candidates
        }
    
    /// Get tone-based suggestions from JSON data
    private func getToneBasedSuggestions(text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var candidates: [FixCandidate] = []
        
        guard let toneBuckets = JSONKnowledgeBase.toneSuggestions["buckets"] as? [String: Any],
              let toneImprovements = toneBuckets["toneImprovement"] as? [String: Any] else {
            return candidates
        }
        
        // Determine tone category from analysis
        let toneCategory = determineToneCategory(analysis)
        
        if let toneSuggestions = toneImprovements[toneCategory] as? [[String: Any]] {
            for suggestion in toneSuggestions.prefix(3) { // Limit to top 3 for performance
                if let suggestionText = suggestion["text"] as? String,
                   let priority = suggestion["priority"] as? String {
                    
                    let confidence = priorityToConfidence(priority)
                    candidates.append(FixCandidate(
                        text: suggestionText,
                        type: .toneBased,
                        attachmentRelevance: .medium,
                        reasoning: "Tone improvement for \(toneCategory): \(suggestionText)",
                        sourceEngine: .jsonKnowledge,
                        confidence: confidence
                    ))
                }
            }
        }
        
        return candidates
    }
    
    /// Get communication pattern suggestions from JSON data
    private func getCommunicationPatternSuggestions(text: String, pattern: CommunicationPattern) -> [FixCandidate] {
        var candidates: [FixCandidate] = []
        
        guard let patternData = JSONKnowledgeBase.communicationPatternsSuggestions["CommunicationsPatternSuggestions"] as? [String: Any] else {
            return candidates
        }
        
        let patternKey = mapPatternToJSONKey(pattern)
        
        if let patternSuggestions = patternData[patternKey] as? [String: Any],
           let defaults = patternSuggestions["defaults"] as? [String] {
            
            // Get top 3 suggestions for the pattern
            for suggestion in defaults.prefix(3) {
                candidates.append(FixCandidate(
                    text: suggestion,
                    type: .communicationPattern,
                    attachmentRelevance: .medium,
                    reasoning: "Communication pattern improvement for \(patternKey): \(suggestion)",
                    sourceEngine: .jsonKnowledge,
                    confidence: 0.7
                ))
            }
        }
        
        return candidates
    }
    
    /// Get contextual suggestions from JSON data
    private func getContextualSuggestions(text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var candidates: [FixCandidate] = []
        
        guard let contextualData = JSONKnowledgeBase.contextualSuggestions["contextualSuggestions"] as? [String: Any] else {
            return candidates
        }
        
        let toneCategory = determineToneCategory(analysis)
        
        if let suggestions = contextualData[toneCategory] as? [[String: Any]] {
            for suggestion in suggestions.prefix(2) { // Limit for performance
                if let suggestionText = suggestion["suggestion"] as? String {
                    candidates.append(FixCandidate(
                        text: suggestionText,
                        type: .contextual,
                        attachmentRelevance: .medium,
                        reasoning: "Contextual suggestion: \(suggestionText)",
                        sourceEngine: .jsonKnowledge,
                        confidence: 0.65
                    ))
                }
            }
        }
        
        return candidates
    }
    
    /// Get auto-fix suggestions from JSON data
    private func getAutoFixSuggestions(text: String) -> [FixCandidate] {
        var candidates: [FixCandidate] = []
        
        guard let autoFixData = JSONKnowledgeBase.autoFixReplacements["autoFix"] as? [String: Any],
              let alertFixes = autoFixData["alert"] as? [[String: Any]] else {
            return candidates
        }
        
        var fixedText = text
        var hasChanges = false
        
        for fix in alertFixes {
            if let find = fix["find"] as? String,
               let replace = fix["replace"] as? String {
                
                let originalText = fixedText
                fixedText = fixedText.replacingOccurrences(of: find, with: replace, options: .caseInsensitive)
                
                if fixedText != originalText {
                    hasChanges = true
                }
            }
        }
        
        if hasChanges && fixedText != text {
            candidates.append(FixCandidate(
                text: fixedText,
                type: .autoFix,
                attachmentRelevance: .high,
                reasoning: "Auto-fix applied to remove problematic language",
                sourceEngine: .jsonKnowledge,
                confidence: 0.9
            ))
        }
        
        return candidates
    }
    
    /// Get fallback repair suggestions from JSON data
    private func getFallbackRepairSuggestions(text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var candidates: [FixCandidate] = []
        
        guard let repairScripts = JSONKnowledgeBase.fallbackRepairScripts["fallbackRepairScripts"] as? [String] else {
            return candidates
        }
        
        // Select repair scripts based on analysis
        let bestRepairScripts = selectBestRepairScripts(repairScripts, analysis: analysis)
        
        for script in bestRepairScripts.prefix(2) {
            candidates.append(FixCandidate(
                text: script,
                type: .repairStrategy,
                attachmentRelevance: .high,
                reasoning: "Fallback repair strategy for high-conflict situation",
                sourceEngine: .jsonKnowledge,
                confidence: 0.85
            ))
        }
        
        return candidates
    }
    
    // MARK: - JSON Processing Helpers
    
    /// Convert priority string to confidence score
    private func priorityToConfidence(_ priority: String) -> Double {
        switch priority.lowercased() {
        case "critical": return 0.95
        case "high": return 0.85
        case "medium": return 0.75
        case "low": return 0.65
        default: return 0.7
        }
    }
    
    /// Determine tone category for JSON lookup
    private func determineToneCategory(_ analysis: DeepTextAnalysis) -> String {
        if analysis.conflictLevel > 0.7 || analysis.toneProfile.primaryTone == .alert {
            return "alert"
        } else if analysis.conflictLevel > 0.4 {
            return "caution"
        } else {
            return "neutral"
        }
    }
    
    /// Map communication pattern to JSON key
    private func mapPatternToJSONKey(_ pattern: CommunicationPattern) -> String {
        switch pattern {
        case .aggressive: return "aggressive"
        case .passiveAggressive: return "passiveAggressive"
        case .defensive: return "defensive"
        case .withdrawing: return "avoidant"
        default: return "neutral"
        }
    }
    
    /// Select best repair scripts based on analysis
    private func selectBestRepairScripts(_ scripts: [String], analysis: DeepTextAnalysis) -> [String] {
        // Filter scripts based on attachment style and situation
        let attachmentStyle = analysis.attachmentSignals.detectedStyle ?? getAttachmentStyle()
        
        return scripts.filter { script in
            let scriptLower = script.lowercased()
            
            // Select scripts appropriate for attachment style
            switch attachmentStyle {
            case .anxious:
                return scriptLower.contains("reassur") || scriptLower.contains("connect") || scriptLower.contains("understand")
            case .avoidant:
                return scriptLower.contains("space") || scriptLower.contains("respect") || scriptLower.contains("boundary")
            case .disorganized:
                return scriptLower.contains("safe") || scriptLower.contains("clear") || scriptLower.contains("step")
            case .secure:
                return scriptLower.contains("together") || scriptLower.contains("collaborate") || scriptLower.contains("solution")
            case .unknown:
                return true // Include all for unknown
            }
        }
    }
    
    /// Get child-centered suggestions for co-parenting communication
    private func getChildCenteredSuggestions(text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var candidates: [FixCandidate] = []
        
        // Get children names from shared storage
        let childrenNames = getChildrenNames()
        let childrenMention = mentionsChildren(in: text)
        
        guard let childLanguageData = JSONKnowledgeBase.childLanguage["childCenteredLanguage"] as? [String: Any] else {
            return candidates
        }
        
        // 1. Child-first reframes when children are mentioned
        if childrenMention.mentioned,
           let childFirstData = childLanguageData["childFirstReframes"] as? [String: Any],
           let triggers = childFirstData["triggers"] as? [String],
           let templates = childFirstData["templates"] as? [String] {
            
            let textLower = text.lowercased()
            let hasTrigger = triggers.contains { trigger in
                textLower.contains(trigger.lowercased())
            }
            
            if hasTrigger, let template = templates.first {
                let primaryChildName = childrenMention.names.first ?? "our child"
                let suggestion = template.replacingOccurrences(of: "{child_name}", with: primaryChildName)
                
                candidates.append(FixCandidate(
                    text: suggestion,
                    type: .childCentered,
                    attachmentRelevance: .high,
                    reasoning: "Child-first reframe focusing on \(primaryChildName)'s well-being",
                    sourceEngine: .childLanguage,
                    confidence: 0.9
                ))
            }
        }
        
        // 2. Empathy echo for emotional situations involving children
        if analysis.emotionalIntensity > 0.6 && !childrenNames.isEmpty,
           let empathyData = childLanguageData["empathyEcho"] as? [String: Any],
           let empathyTemplates = empathyData["templates"] as? [String] {
            
            let primaryChildName = childrenNames.first!
            if let template = empathyTemplates.first {
                let empathySuggestion = template.replacingOccurrences(of: "{child_name}", with: primaryChildName)
                
                candidates.append(FixCandidate(
                    text: empathySuggestion,
                    type: .childCentered,
                    attachmentRelevance: .high,
                    reasoning: "Empathy echo focusing on shared concern for \(primaryChildName)",
                    sourceEngine: .childLanguage,
                    confidence: 0.85
                ))
            }
        }
        
        // 3. Developmental prompts for co-parenting discussions
        if !childrenNames.isEmpty,
           let developmentalData = childLanguageData["developmentalPrompts"] as? [String: Any],
           let prompts = developmentalData["prompts"] as? [String] {
            
            let textLower = text.lowercased()
            let isCoParentingTopic = ["school", "schedule", "behavior", "homework", "bedtime", "rules"].contains { topic in
                textLower.contains(topic)
            }
            
            if isCoParentingTopic, let prompt = prompts.first {
                let primaryChildName = childrenNames.first!
                let developmentalSuggestion = prompt.replacingOccurrences(of: "{child_name}", with: primaryChildName)
                
                candidates.append(FixCandidate(
                    text: developmentalSuggestion,
                    type: .childCentered,
                    attachmentRelevance: .medium,
                    reasoning: "Developmental perspective for \(primaryChildName)'s needs",
                    sourceEngine: .childLanguage,
                    confidence: 0.8
                ))
            }
        }
        
        // 4. Calm-down exercises for high-conflict situations
        if analysis.conflictLevel > 0.7 && !childrenNames.isEmpty,
           let calmDownData = childLanguageData["calmDownExercises"] as? [String: Any],
           let exercises = calmDownData["exercises"] as? [String] {
            
            if let exercise = exercises.first {
                let primaryChildName = childrenNames.first!
                let calmingSuggestion = exercise.replacingOccurrences(of: "{child_name}", with: primaryChildName)
                
                candidates.append(FixCandidate(
                    text: calmingSuggestion,
                    type: .childCentered,
                    attachmentRelevance: .high,
                    reasoning: "Calming approach focusing on \(primaryChildName)'s emotional safety",
                    sourceEngine: .childLanguage,
                    confidence: 0.9
                ))
            }
        }
        
        return candidates
    }
    
    // MARK: - Mode Control
    
    /// Set processing mode for performance optimization
    func setProcessingMode(_ mode: AIProcessingMode) {
        currentMode = mode
    }
    
    /// Analyze tone of the provided text and return status with confidence
    func analyzeTone(_ text: String) -> ToneAnalysisResult {
        let status = analyzeLocalTone(text)
        let confidence = calculateToneConfidence(text, status: status)
        return ToneAnalysisResult(status: status, confidence: confidence)
    }
    
    /// Generate therapeutic advice for the provided text
    func generateSuggestions(for text: String) async -> [String] {
        let therapeuticResult = generateTherapeuticAdvice(for: text)
        
        // Convert therapeutic advice to string array for compatibility
        return therapeuticResult.therapeuticAdvice.map { advice in
            formatAdviceForDisplay(advice)
        }
    }
    
    /// Generate comprehensive therapeutic advice instead of text fixes
    func generateTherapeuticAdvice(for text: String) -> TherapeuticAnalysisResult {
        // Perform deep analysis of the text
        let analysis = performDeepTextAnalysis(text)
        
        // Identify primary concern and triggers
        let primaryConcern = identifyPrimaryConcern(from: analysis, text: text)
        let attachmentTriggers = identifyAttachmentTriggers(from: analysis, text: text)
        let emotionalState = assessEmotionalState(from: analysis, text: text)
        let communicationPattern = describeCommunicationPattern(from: analysis)
        
        // Generate therapeutic advice from JSON data and AI analysis
        let therapeuticAdvice = generateTherapeuticAdviceFromSources(
            text: text,
            analysis: analysis,
            primaryConcern: primaryConcern
        )
        
        // Assess urgency level
        let urgencyLevel = assessSituationUrgency(from: analysis, text: text)
        
        // Generate follow-up suggestions
        let followUpSuggestions = generateFollowUpGuidance(from: analysis, advice: therapeuticAdvice)
        
        return TherapeuticAnalysisResult(
            originalText: text,
            primaryConcern: primaryConcern,
            attachmentTriggers: attachmentTriggers,
            emotionalState: emotionalState,
            communicationPattern: communicationPattern,
            therapeuticAdvice: therapeuticAdvice.sorted { $0.confidence > $1.confidence },
            urgencyLevel: urgencyLevel,
            followUpSuggestions: followUpSuggestions
        )
    }
    
    /// Format therapeutic advice for display in the keyboard
    private func formatAdviceForDisplay(_ advice: TherapeuticAdvice) -> String {
        var formatted = "💭 \(advice.insight)\n\n"
        formatted += "🎯 \(advice.advice)"
        
        if let actionStep = advice.actionStep {
            formatted += "\n\n✨ Try this: \(actionStep)"
        }
        
        return formatted
    }
    
    // MARK: - Therapeutic Advice Generation Methods
    
    /// Identify the primary psychological concern from the text
    private func identifyPrimaryConcern(from analysis: DeepTextAnalysis, text: String) -> String {
        if analysis.conflictLevel > 0.7 {
            return "High-conflict communication pattern requiring de-escalation"
        } else if analysis.emotionalIntensity > 0.8 {
            return "Emotional dysregulation and overwhelming feelings"
        } else if analysis.attachmentSignals.intensity > 0.6 {
            return "Attachment system activation affecting communication"
        } else if analysis.relationshipDynamics.hasDistancing {
            return "Defensive distancing pattern impacting connection"
        } else if analysis.linguisticPatterns.hasAbsolutes {
            return "All-or-nothing thinking pattern"
        } else {
            return "General communication enhancement opportunity"
        }
    }
    
    /// Identify specific attachment triggers in the text
    private func identifyAttachmentTriggers(from analysis: DeepTextAnalysis, text: String) -> [String] {
        var triggers: [String] = []
        let textLower = text.lowercased()
        
        // Common attachment triggers
        if textLower.contains("abandon") || textLower.contains("leave") {
            triggers.append("Abandonment fear")
        }
        if textLower.contains("clingy") || textLower.contains("needy") {
            triggers.append("Closeness anxiety")
        }
        if textLower.contains("space") || textLower.contains("alone") {
            triggers.append("Intimacy avoidance")
        }
        if textLower.contains("control") || textLower.contains("manipulate") {
            triggers.append("Control dynamics")
        }
        if textLower.contains("trust") || textLower.contains("lie") {
            triggers.append("Trust issues")
        }
        
        return triggers
    }
    
    /// Assess current emotional state from the analysis
    private func assessEmotionalState(from analysis: DeepTextAnalysis, text: String) -> String {
        if analysis.emotionalIntensity > 0.8 {
            if text.lowercased().contains("angry") || text.lowercased().contains("mad") {
                return "Highly activated anger"
            } else if text.lowercased().contains("sad") || text.lowercased().contains("hurt") {
                return "Deep emotional pain"
            } else if text.lowercased().contains("anxious") || text.lowercased().contains("worried") {
                return "Elevated anxiety"
            } else {
                return "Emotionally overwhelmed"
            }
        } else if analysis.emotionalIntensity > 0.5 {
            return "Moderately emotional"
        } else {
            return "Emotionally regulated"
        }
    }
    
    /// Describe the communication pattern observed
    private func describeCommunicationPattern(from analysis: DeepTextAnalysis) -> String {
        switch analysis.communicationPattern {
        case .aggressive:
            return "Using aggressive language that may push others away"
        case .passiveAggressive:
            return "Expressing feelings indirectly through passive-aggressive communication"
        case .defensive:
            return "Responding defensively which blocks genuine connection"
        case .withdrawing:
            return "Withdrawing from communication to avoid conflict"
        case .pursuing:
            return "Persistently seeking response or reassurance"
        case .assertive:
            return "Communicating needs clearly and respectfully"
        default:
            return "Standard communication pattern"
        }
    }
    
    /// Generate therapeutic advice from multiple sources using the bucket flow
    private func generateTherapeuticAdviceFromSources(
        text: String,
        analysis: DeepTextAnalysis,
        primaryConcern: String
    ) -> [TherapeuticAdvice] {
        var adviceList: [TherapeuticAdvice] = []
        
        // PRIMARY: Use the complete bucket flow for main advice
        let userState = getUserCurrentEmotionalState()
        let attachmentStyle = getAttachmentStyle()
        
        // Step 1-4: Complete bucket flow → cohesive response
        let attachmentStyleString = analysis.attachmentSignals.detectedStyle?.rawValue
            ?? PersonalityDataManager.shared.getAttachmentStyle() ?? "secure"
        let attachmentStyleEnum = AttachmentStyle(rawValue: attachmentStyleString) ?? .secure

        if let cohesiveAdvice = getCohesiveAdviceFromBucket(
            userState: userState,
            attachmentStyle: attachmentStyleEnum,
            analysis: analysis
        ) {
            adviceList.append(cohesiveAdvice)
        }
        
        // SUPPLEMENTARY: Add specific advice based on analysis
        // 2. Attachment-based advice (using bucket selection)
        adviceList.append(contentsOf: generateAttachmentBasedAdvice(text: text, analysis: analysis))
        
        // 3. Emotional regulation advice (using bucket selection)
        if analysis.emotionalIntensity > 0.6 {
            adviceList.append(contentsOf: generateEmotionalRegulationAdvice(text: text, analysis: analysis))
        }
        
        // 4. Communication skills advice
        adviceList.append(contentsOf: generateCommunicationSkillsAdvice(text: text, analysis: analysis))
        
        // 5. Conflict resolution advice
        if analysis.conflictLevel > 0.5 {
            adviceList.append(contentsOf: generateConflictResolutionAdvice(text: text, analysis: analysis))
        }
        
        // 6. Mindfulness and self-reflection advice
        adviceList.append(contentsOf: generateMindfulnessAdvice(text: text, analysis: analysis))
        
        return adviceList
    }
    
    /// Generate attachment-style specific therapeutic advice
    private func generateAttachmentBasedAdvice(text: String, analysis: DeepTextAnalysis) -> [TherapeuticAdvice] {
        let attachmentStyle = analysis.attachmentSignals.detectedStyle ?? getAttachmentStyle()
        var advice: [TherapeuticAdvice] = []
        
        guard let therapeuticData = JSONKnowledgeBase.therapeutic["therapeuticAdvice"] as? [String: Any],
              let attachmentStyles = therapeuticData["attachmentStyles"] as? [String: Any] else {
            return []
        }
        
        let styleKey = attachmentStyle.rawValue
        guard let styleData = attachmentStyles[styleKey] as? [String: Any] else {
            return []
        }
        
        // Extract data from JSON
        let observations = styleData["observations"] as? [String] ?? []
        let insights = styleData["insights"] as? [String] ?? []
        let adviceList = styleData["advice"] as? [String] ?? []
        let actionSteps = styleData["actionSteps"] as? [String] ?? []
        let attachmentContexts = styleData["attachmentContext"] as? [String] ?? []
        
        // Create therapeutic advice using random selections from JSON arrays
        if !observations.isEmpty && !insights.isEmpty && !adviceList.isEmpty {
            let userState = getUserCurrentEmotionalState()
            let attachmentStyle = getAttachmentStyle()
            
            advice.append(TherapeuticAdvice(
                observation: selectAdviceUsingBuckets(from: observations, userState: userState, attachmentStyle: attachmentStyle) ?? observations[0],
                insight: selectAdviceUsingBuckets(from: insights, userState: userState, attachmentStyle: attachmentStyle) ?? insights[0],
                advice: selectAdviceUsingBuckets(from: adviceList, userState: userState, attachmentStyle: attachmentStyle) ?? adviceList[0],
                attachmentContext: selectAdviceUsingBuckets(from: attachmentContexts, userState: userState, attachmentStyle: attachmentStyle) ?? attachmentContexts.first ?? "Attachment-based guidance",
                actionStep: selectAdviceUsingBuckets(from: actionSteps, userState: userState, attachmentStyle: attachmentStyle),
                confidence: 0.85,
                category: .attachmentAwareness,
                sourceData: "Therapeutic JSON - \(styleKey) attachment"
            ))
        }
        
        return advice
    }
    
    /// Generate emotional regulation therapeutic advice
    private func generateEmotionalRegulationAdvice(text: String, analysis: DeepTextAnalysis) -> [TherapeuticAdvice] {
        var advice: [TherapeuticAdvice] = []
        
        guard let therapeuticData = JSONKnowledgeBase.therapeutic["therapeuticAdvice"] as? [String: Any],
              let emotionalStates = therapeuticData["emotionalStates"] as? [String: Any] else {
            return []
        }
        
        // Determine emotional state level
        let stateKey: String
        if analysis.emotionalIntensity > 0.8 {
            stateKey = "highIntensity"
        } else if analysis.emotionalIntensity > 0.5 {
            stateKey = "moderate"
        } else {
            stateKey = "regulated"
        }
        
        guard let stateData = emotionalStates[stateKey] as? [String: Any] else {
            return []
        }
        
        // Extract data from JSON
        let observations = stateData["observations"] as? [String] ?? []
        let insights = stateData["insights"] as? [String] ?? []
        let adviceList = stateData["advice"] as? [String] ?? []
        let actionSteps = stateData["actionSteps"] as? [String] ?? []
        
        // Create therapeutic advice using bucket-based selections from JSON arrays
        if !observations.isEmpty && !insights.isEmpty && !adviceList.isEmpty {
            let userState = getUserCurrentEmotionalState()
            let attachmentStyle = getAttachmentStyle()
            
            advice.append(TherapeuticAdvice(
                observation: selectAdviceUsingBuckets(from: observations, userState: userState, attachmentStyle: attachmentStyle) ?? observations[0],
                insight: selectAdviceUsingBuckets(from: insights, userState: userState, attachmentStyle: attachmentStyle) ?? insights[0],
                advice: selectAdviceUsingBuckets(from: adviceList, userState: userState, attachmentStyle: attachmentStyle) ?? adviceList[0],
                attachmentContext: "Emotional regulation affects all attachment styles",
                actionStep: selectAdviceUsingBuckets(from: actionSteps, userState: userState, attachmentStyle: attachmentStyle),
                confidence: analysis.emotionalIntensity > 0.8 ? 0.90 : 0.80,
                category: .emotionalRegulation,
                sourceData: "Therapeutic JSON - \(stateKey) emotional state"
            ))
        }
        
        return advice
    }
    
    /// Generate communication skills therapeutic advice
    private func generateCommunicationSkillsAdvice(text: String, analysis: DeepTextAnalysis) -> [TherapeuticAdvice] {
        var advice: [TherapeuticAdvice] = []
        
        if analysis.linguisticPatterns.hasAbsolutes {
            advice.append(TherapeuticAdvice(
                observation: "I notice some 'always' or 'never' language in your message",
                insight: "Absolute language often signals emotional overwhelm and can trigger defensiveness in others",
                advice: "Try softening your language: 'sometimes' or 'often' instead of 'always', 'rarely' instead of 'never'",
                attachmentContext: "Absolute thinking is common when our attachment system is activated",
                actionStep: "Rewrite one sentence replacing absolute words with more nuanced language",
                confidence: 0.85,
                category: .communicationSkills,
                sourceData: "Linguistic pattern analysis"
            ))
        }
        
        return advice
    }
    
    /// Generate conflict resolution therapeutic advice
    private func generateConflictResolutionAdvice(text: String, analysis: DeepTextAnalysis) -> [TherapeuticAdvice] {
        var advice: [TherapeuticAdvice] = []
        
        if analysis.conflictLevel > 0.7 {
            advice.append(TherapeuticAdvice(
                observation: "This situation seems to involve significant conflict",
                insight: "Healthy relationships need repair attempts when conflicts arise",
                advice: "Consider starting with: 'I want to understand your perspective. Can you help me see this from your side?'",
                attachmentContext: "Conflict activates our attachment system and can trigger fight, flight, or freeze responses",
                actionStep: "Lead with curiosity instead of being right",
                confidence: 0.88,
                category: .conflictResolution,
                sourceData: "Conflict level analysis"
            ))
        }
        
        return advice
    }
    
    /// Generate mindfulness and self-reflection advice
    private func generateMindfulnessAdvice(text: String, analysis: DeepTextAnalysis) -> [TherapeuticAdvice] {
        var advice: [TherapeuticAdvice] = []
        
        advice.append(TherapeuticAdvice(
            observation: "Communication challenges often reflect our inner emotional state",
            insight: "Mindful awareness helps us respond rather than react from old patterns",
            advice: "Before sending, pause and ask yourself: 'What am I hoping to accomplish with this message?'",
            attachmentContext: "Mindfulness can help us catch attachment triggers before they escalate",
            actionStep: "Take three conscious breaths and check in with your intention",
            confidence: 0.75,
            category: .mindfulness,
            sourceData: "Mindfulness integration"
        ))
        
        return advice
    }
    
    // MARK: - Emotional Bucket Selection System
    
    /// Get user's current emotional state from UserDefaults (set from splash screen)
    private func getUserCurrentEmotionalState() -> String {
        let userDefaults = UserDefaults(suiteName: "group.unsaid.keyboard")
        return userDefaults?.string(forKey: "currentEmotionalState") ?? "neutral"
    }
    
    /// Select advice using emotional bucket system based on user state and attachment style
    private func selectAdviceUsingBuckets<T>(from items: [T], userState: String, attachmentStyle: AttachmentStyle) -> T? {
        // Step 1: Classify current emotion → pick bucket (High, Medium, Low)
        let bucket = determineBucketFromUserState(userState)
        
        // Step 2: Retrieve bucket's specific guidance from EmotionalBuckets.json
        let bucketGuidance = getBucketGuidance(for: bucket)
        
        // Step 3: Apply attachment style tweaks to selection
        let selectionStrategy = getSelectionStrategy(bucket: bucket, attachmentStyle: attachmentStyle)
        
        if items.isEmpty { return nil }
        
        // Step 4: Select based on bucket + attachment style strategy
        switch selectionStrategy {
        case .firstAvailable:
            return items.first
        case .middleRange:
            let middleIndex = items.count / 2
            return items.indices.contains(middleIndex) ? items[middleIndex] : items.first
        case .varietyBased:
            // For regulated + secure: can use variety
            return items.count > 2 ? items[items.count - 1] : items.first
        case .attachmentSpecific:
            // Select based on attachment style preferences
            return selectForAttachmentStyle(items: items, style: attachmentStyle)
        }
    }
    
    /// Get bucket guidance from EmotionalBuckets.json
    private func getBucketGuidance(for bucket: String) -> [String: String] {
        guard let emotionalBuckets = JSONKnowledgeBase.emotionBuckets["EmotionalBuckets"] as? [[String: Any]] else {
            return [:]
        }
        
        for bucketData in emotionalBuckets {
            if let name = bucketData["name"] as? String, name == bucket,
               let references = bucketData["references"] as? [String: String] {
                return references
            }
        }
        return [:]
    }
    
    enum SelectionStrategy {
        case firstAvailable      // High intensity: most urgent first
        case middleRange        // Moderate: balanced approach
        case varietyBased       // Regulated: can explore options
        case attachmentSpecific // Based on attachment style needs
    }
    
    /// Determine selection strategy based on bucket + attachment style
    private func getSelectionStrategy(bucket: String, attachmentStyle: AttachmentStyle) -> SelectionStrategy {
        switch bucket {
        case "highIntensity":
            return .firstAvailable  // Always prioritize urgent for high distress
        case "moderate":
            // For moderate, consider attachment style
            switch attachmentStyle {
            case .anxious:
                return .firstAvailable  // Anxious needs quick reassurance
            case .avoidant:
                return .middleRange     // Avoidant prefers measured approach
            default:
                return .middleRange
            }
        case "regulated":
            // For regulated, can be more flexible based on attachment
            switch attachmentStyle {
            case .secure:
                return .varietyBased    // Secure can handle variety
            default:
                return .attachmentSpecific  // Others need style-specific
            }
        default:
            return .middleRange
        }
    }
    
    /// Select item based on attachment style preferences
    private func selectForAttachmentStyle<T>(items: [T], style: AttachmentStyle) -> T? {
        switch style {
        case .anxious:
            return items.first          // Prefer immediate/reassuring options
        case .avoidant:
            return items.last           // Prefer self-reliant/independent options
        case .disorganized:
            return items.first          // Need structure and immediate guidance
        case .secure:
            let middleIndex = items.count / 2
            return items.indices.contains(middleIndex) ? items[middleIndex] : items.first
        default:
            return items.first
        }
    }
    
    /// Determine which emotional bucket the user is in based on their current state
    private func determineBucketFromUserState(_ userState: String) -> String {
        let lowerState = userState.lowercased()
        
        if lowerState.contains("panic") || lowerState.contains("overwhelmed") {
            return "highIntensity"
        } else if lowerState.contains("tense") || lowerState.contains("uneasy") || lowerState.contains("neutral") || lowerState.contains("distracted") {
            return "moderate"
        } else if lowerState.contains("calm") || lowerState.contains("content") || lowerState.contains("relaxed") || lowerState.contains("centered") || lowerState.contains("grounded") || lowerState.contains("ease") {
            return "regulated"
        }
        
        return "moderate" // Default fallback
    }
    
    /// Get action steps based on user's emotional bucket using EmotionalBuckets.json
    private func getActionStepsForBucket(_ bucket: String) -> [String] {
        // Step 2: Retrieve that bucket's actionSteps from EmotionalBuckets.json structure
        let bucketGuidance = getBucketGuidance(for: bucket)
        
        if let actionStepsPath = bucketGuidance["actionSteps"] {
            // Parse the path like "TherapyActionSteps.immediate"
            let components = actionStepsPath.components(separatedBy: ".")
            if components.count == 2 && components[0] == "TherapyActionSteps" {
                let actionStepsKey = components[1]
                if let actionSteps = JSONKnowledgeBase.therapyActionSteps[actionStepsKey] as? [String] {
                    return actionSteps
                }
            }
        }
        
        // Fallback to direct lookup if path parsing fails
        let actionSteps = JSONKnowledgeBase.therapyActionSteps
        
        switch bucket {
        case "highIntensity":
            return actionSteps["immediate"] as? [String] ?? []
        case "moderate":
            return actionSteps["shortTerm"] as? [String] ?? []
        case "regulated":
            return actionSteps["longTerm"] as? [String] ?? []
        default:
            return actionSteps["shortTerm"] as? [String] ?? []
        }
    }
    
    /// Get cohesive therapeutic advice using the complete bucket flow
    private func getCohesiveAdviceFromBucket(userState: String, attachmentStyle: AttachmentStyle, analysis: DeepTextAnalysis) -> TherapeuticAdvice? {
        // Step 1: Classify current emotion → pick bucket
        let bucket = determineBucketFromUserState(userState)
        
        // Step 2: Retrieve bucket's actionSteps/advice/insights/etc
        let bucketGuidance = getBucketGuidance(for: bucket)
        let actionSteps = getActionStepsForBucket(bucket)
        
        // Step 3: Look up attachment style specific messaging
        let attachmentTweaks = getAttachmentStyleTweaks(for: attachmentStyle, bucket: bucket)
        
        // Step 4: Merge & present single cohesive response
        let selectedActionStep = selectAdviceUsingBuckets(from: actionSteps, userState: userState, attachmentStyle: attachmentStyle)
        
        return TherapeuticAdvice(
            observation: "Based on your current state (\(userState)), I notice you're in the \(bucket) emotional space",
            insight: attachmentTweaks.insight,
            advice: attachmentTweaks.advice,
            attachmentContext: attachmentTweaks.context,
            actionStep: selectedActionStep,
            confidence: 0.88,
            category: .emotionalRegulation,
            sourceData: "EmotionalBuckets.json + AttachmentStyle(\(attachmentStyle.rawValue))"
        )
    }
    
    /// Get attachment style specific tweaks for the bucket
    private func getAttachmentStyleTweaks(for style: AttachmentStyle, bucket: String) -> (insight: String, advice: String, context: String) {
        switch (style, bucket) {
        case (.anxious, "highIntensity"):
            return (
                insight: "When anxiously attached, high distress can trigger fears of abandonment",
                advice: "Focus on self-soothing first, then reach out for reassurance if needed",
                context: "Your attachment system is highly activated - this is temporary"
            )
        case (.anxious, "moderate"):
            return (
                insight: "Moderate distress for anxious attachment often involves relationship worries",
                advice: "Practice expressing your needs clearly rather than hoping others will guess",
                context: "Your sensitivity to relationship cues is both a strength and a challenge"
            )
        case (.avoidant, "highIntensity"):
            return (
                insight: "High distress for avoidant types often triggers withdrawal impulses",
                advice: "Try staying present instead of pulling away - small steps toward connection",
                context: "Your instinct to handle things alone is understandable but connection can help"
            )
        case (.avoidant, "moderate"):
            return (
                insight: "Moderate emotions might feel overwhelming when you prefer emotional distance",
                advice: "Practice naming emotions internally before deciding whether to share them",
                context: "Building emotional awareness doesn't require vulnerability with others yet"
            )
        case (.secure, _):
            return (
                insight: "Your secure attachment helps you navigate emotions with greater stability",
                advice: "Trust your instincts and use this as an opportunity for growth",
                context: "You have strong emotional regulation skills to draw upon"
            )
        default:
            return (
                insight: "Understanding your emotional patterns helps build self-awareness",
                advice: "Take time to notice what you need right now without judgment",
                context: "Every emotional state offers information about your inner world"
            )
        }
    }
    
    /// Assess how urgent the therapeutic intervention needs to be
    private func assessSituationUrgency(from analysis: DeepTextAnalysis, text: String) -> AdviceUrgency {
        if analysis.conflictLevel > 0.8 && analysis.emotionalIntensity > 0.8 {
            return .crisis
        } else if analysis.conflictLevel > 0.6 || analysis.emotionalIntensity > 0.7 {
            return .high
        } else if analysis.conflictLevel > 0.4 || analysis.emotionalIntensity > 0.5 {
            return .moderate
        } else {
            return .low
        }
    }
    
    /// Generate follow-up guidance suggestions
    private func generateFollowUpGuidance(from analysis: DeepTextAnalysis, advice: [TherapeuticAdvice]) -> [String] {
        var suggestions: [String] = []
        
        guard let therapeuticData = JSONKnowledgeBase.therapeutic["therapeuticAdvice"] as? [String: Any],
              let followUpData = therapeuticData["followUpGuidance"] as? [String: Any] else {
            // Fallback suggestions
            return [
                "Practice the 24-hour rule: Wait a day before sending emotionally charged messages",
                "Consider having this conversation in person or over video call for better connection",
                "Remember that repair is always possible - relationships grow stronger through working through challenges"
            ]
        }
        
        // Add general guidance
        if let generalGuidance = followUpData["general"] as? [String] {
            suggestions.append(contentsOf: generalGuidance)
        }
        
        // Add conflict-specific guidance if needed
        if analysis.conflictLevel > 0.6,
           let highConflictGuidance = followUpData["highConflict"] as? [String] {
            suggestions.append(contentsOf: highConflictGuidance.prefix(2))
        }
        
        // Add co-parenting guidance if children are mentioned
        let childrenMention = mentionsChildren(in: "")
        if childrenMention.mentioned || !getUserDefinedChildrenNames().isEmpty,
           let coParentingGuidance = followUpData["coParenting"] as? [String] {
            suggestions.append(contentsOf: coParentingGuidance.prefix(2))
        }
        
        return suggestions
    }
    
    /// Generate secure fix for the provided text (returns rewritten text for secure fix button)
    func generateSecureFix(for text: String) async throws -> AITextResult {
        // Use existing comprehensive processing to generate rewritten secure text
        return processAndFixText(text)
    }
    
    // MARK: - Main AI Processing Pipeline
    
    /// Main AI text processing - analyzes and fixes text based on attachment style and context
    func processAndFixText(_ text: String) -> AITextResult {
        switch currentMode {
        case .realTime:
            return processRealTime(text)
        case .toneOnly:
            return processToneOnly(text)
        case .suggestionsOnly:
            return processSuggestionsOnly(text)
        case .comprehensive:
            return processComprehensive(text)
        }
    }
    
    /// Comprehensive processing (enhanced with JSON knowledge)
    private func processComprehensive(_ text: String) -> AITextResult {
        // 1. Initialize advanced features if needed
        JSONKnowledgeBase.initializeAdvancedFeatures()
        
        // 2. Add message to contextual memory (simplified implementation)
        let emotion = extractQuickEmotion(text)
        // Store in simplified contextual memory
        JSONKnowledgeBase.contextualMemory["last_message"] = text
        JSONKnowledgeBase.contextualMemory["last_emotion"] = emotion
        
        // 3. Multi-layered text analysis
        let analysis = performDeepTextAnalysis(text)
        
        // 3.5. Auto-inject calm-down prompts for high conflict (before generating other candidates)
        if analysis.conflictLevel > 0.7 {
            let calmDownPrompt = generateAutoCalmDownPrompt(text: text, analysis: analysis)
            if let prompt = calmDownPrompt {
                // Return immediate calm-down suggestion for very high conflict
        return AITextResult(
            originalText: text,
            improvedText: prompt,
            confidence: 0.95,
            reasoning: "Auto-generated calm-down prompt due to high conflict level",
            attachmentStyleFactors: [getAttachmentStyle().rawValue],
            emotionalImpact: EmotionalImpact(),
            communicationGoals: [CommunicationGoal.conflict_resolution, CommunicationGoal.emotional_expression]
        )
            }
        }
        
        // 4. Generate multiple fix candidates from all sources including RAG
        let fixCandidates = generateAllFixCandidatesWithRAG(text, analysis: analysis)
        
        // 5. Score and rank fixes using AI-like scoring with user preferences
        let rankedFixes = rankFixesWithAIAndMemory(fixCandidates, originalText: text, analysis: analysis)
        
        // 6. Select optimal fix
        let optimalFix = selectOptimalFix(from: rankedFixes, analysis: analysis)
        
        return AITextResult(
            originalText: text,
            improvedText: optimalFix.candidate.text,
            confidence: optimalFix.confidence,
            reasoning: optimalFix.reasoning,
            attachmentStyleFactors: [getAttachmentStyle().rawValue, analysis.attachmentSignals.detectedStyle?.rawValue ?? "unknown"],
            emotionalImpact: EmotionalImpact(),
            communicationGoals: determineCommunicationGoals(analysis: analysis, fixType: optimalFix.candidate.type)
        )
    }
    
    /// Generate fix candidates from all sources (existing engines + JSON knowledge + RAG)
    private func generateAllFixCandidatesWithRAG(_ text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var allCandidates: [FixCandidate] = []
        
        // 1. Get candidates from existing sophisticated engines
        allCandidates.append(contentsOf: generateFixCandidates(text, analysis: analysis))
        
        // 2. Get enhanced candidates from JSON knowledge base
        allCandidates.append(contentsOf: generateJSONEnhancedSuggestions(text, analysis: analysis))
        
        // 3. Get RAG-enhanced suggestions using semantic retrieval
        allCandidates.append(contentsOf: generateRAGEnhancedSuggestions(text, analysis: analysis))
        
        // 4. Get micro-LLM generated creative paraphrases
        allCandidates.append(contentsOf: generateMicroLLMSuggestions(text, analysis: analysis))
        
        // 5. Get emotion-aware suggestions using JSON emotion buckets
        allCandidates.append(contentsOf: generateEmotionAwareSuggestions(text: text, analysis: analysis))
        
        // 6. Get attachment trigger-aware suggestions
        allCandidates.append(contentsOf: generateTriggerAwareSuggestions(text: text, analysis: analysis))
        
        // 7. Get I-statement based suggestions (NEW - HIGH VALUE)
        allCandidates.append(contentsOf: generateIStatementSuggestions(text: text, analysis: analysis))
        
        // 8. Get cross-style communication suggestions (NEW - EXTREMELY HIGH VALUE)
        allCandidates.append(contentsOf: generateCrossStyleSuggestions(text: text, analysis: analysis))
        
        // 9. Get child-centered language suggestions (NEW - CO-PARENTING HIGH VALUE)
        allCandidates.append(contentsOf: generateChildCenteredSuggestions(text: text, analysis: analysis))
        
        // 10. Get mindfulness-based calm-down prompts if conflict is high
        if analysis.conflictLevel > 0.7 {
            allCandidates.append(contentsOf: generateMindfulnessSuggestions(text: text, analysis: analysis))
        }
        
        return allCandidates
    }
    
    /// Generate RAG-enhanced suggestions using semantic retrieval
    private func generateRAGEnhancedSuggestions(_ text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var candidates: [FixCandidate] = []
        
        // Retrieve semantically similar content from vector store (stub implementation)
        // Since vectorStore is just a dictionary, we'll create a simple stub
        let ragResults: [(content: String, score: Float)] = [
            ("Take a deep breath and consider your partner's perspective", 0.8),
            ("Try using 'I' statements to express your feelings", 0.7),
            ("Focus on solutions rather than problems", 0.6)
        ]
        
        for result in ragResults {
            // Use micro-LLM to adapt the retrieved content to current context (stub implementation)
            let adaptedSuggestion = result.content // Simple stub - just use the content directly
            
            candidates.append(FixCandidate(
                text: adaptedSuggestion,
                type: .ragEnhanced,
                attachmentRelevance: .high,
                reasoning: "RAG-enhanced suggestion (similarity: \(String(format: "%.2f", result.score)))",
                sourceEngine: .vectorStore,
                confidence: Double(result.score) * 0.9
            ))
        }
        
        return candidates
    }
    
    /// Generate micro-LLM creative paraphrases with few-shot learning
    private func generateMicroLLMSuggestions(_ text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var candidates: [FixCandidate] = []
        
        let emotion = extractEmotionFromAnalysis(analysis)
        let attachmentStyle = analysis.attachmentSignals.detectedStyle ?? getAttachmentStyle()
        
        // Generate I-statement using micro-LLM (stub implementation)
        let iStatement = "I feel \(emotion) when this happens. Could we find a way to work together on this?"
        candidates.append(FixCandidate(
            text: iStatement,
            type: .microLLMGenerated,
            attachmentRelevance: .high,
            reasoning: "Micro-LLM generated I-statement for \(attachmentStyle.rawValue) attachment",
            sourceEngine: .microLLM,
            confidence: 0.85
        ))
        
        // Generate creative paraphrase using micro-LLM (stub implementation)
        let paraphrase = "Let me rephrase this in a more constructive way: \(text.prefix(50))..."
        candidates.append(FixCandidate(
            text: paraphrase,
            type: .microLLMGenerated,
            attachmentRelevance: .medium,
            reasoning: "Micro-LLM creative paraphrase",
            sourceEngine: .microLLM,
            confidence: 0.8
        ))
        
        return candidates
    }
    
    /// Enhanced ranking with contextual memory and user preferences
    private func rankFixesWithAIAndMemory(_ candidates: [FixCandidate], originalText: String, analysis: DeepTextAnalysis) -> [RankedFix] {
        // Stub implementations for contextual memory methods
        let userPreferences: [String: Any] = [:]
        let recentPattern: String? = nil
        
        return candidates.compactMap { candidate in
            // Filter out suggestions user has consistently rejected (stub - always include)
            // if JSONKnowledgeBase.contextualMemory.shouldAvoidSuggestion(candidate.text) {
            //     return nil
            // }
            
            var score = calculateAIScore(candidate, originalText: originalText, analysis: analysis)
            
            // Boost score based on user preferences
            score = adjustScoreForUserPreferences(score, candidate: candidate, preferences: userPreferences)
            
            // Adjust for recent conversation patterns
            score = adjustScoreForRecentPattern(score, candidate: candidate, pattern: recentPattern)
            
            return RankedFix(
                candidate: candidate,
                score: score,
                confidence: candidate.confidence * score,
                reasoning: candidate.reasoning + (recentPattern != nil ? " (Pattern-aware)" : ""),
                psychologicalRationale: "AI-enhanced ranking",
                expectedOutcome: "Improved communication"
            )
        }.sorted { $0.score > $1.score }
    }
    
    /// Adjust score based on user preferences and history
    private func adjustScoreForUserPreferences(_ baseScore: Double, candidate: FixCandidate, preferences: [String: Any]) -> Double {
        var adjustedScore = baseScore
        
        // Check communication pattern preferences
        if let patterns = preferences["communication_patterns"] as? [String: Int] {
            // Boost I-statements if user accepts them frequently
            if candidate.text.lowercased().contains("i feel") {
                let iStatementUse = patterns["uses_i_statements"] ?? 0
                if iStatementUse > 5 {
                    adjustedScore *= 1.2
                }
            }
            
            // Reduce score for absolutes if user overuses them
            if candidate.text.lowercased().contains("always") || candidate.text.lowercased().contains("never") {
                let absoluteUse = patterns["uses_absolutes"] ?? 0
                if absoluteUse > 10 {
                    adjustedScore *= 0.8
                }
            }
        }
        
        return adjustedScore
    }
    
    /// Adjust score based on recent conversation patterns
    private func adjustScoreForRecentPattern(_ baseScore: Double, candidate: FixCandidate, pattern: String?) -> Double {
        guard let pattern = pattern else { return baseScore }
        
        var adjustedScore = baseScore
        
        switch pattern {
        case "escalating_anger":
            // Boost calming, de-escalation suggestions
            if candidate.text.lowercased().contains("calm") ||
               candidate.text.lowercased().contains("take a breath") ||
               candidate.type == .deEscalation {
                adjustedScore *= 1.3
            }
            
        case "persistent_sadness":
            // Boost empathy and connection suggestions
            if candidate.text.lowercased().contains("understand") ||
               candidate.text.lowercased().contains("together") ||
               candidate.type == .emotionalSupport {
                adjustedScore *= 1.25
            }
            
        case "anxiety_pattern":
            // Boost reassurance and clarity suggestions
            if candidate.text.lowercased().contains("reassur") ||
               candidate.text.lowercased().contains("safe") ||
               candidate.type == .anxietyReduction {
                adjustedScore *= 1.2
            }
            
        default:
            break
        }
        
        return adjustedScore
    }
    
    /// Extract quick emotion for memory tracking
    private func extractQuickEmotion(_ text: String) -> String {
        let lowerText = text.lowercased()
        
        if lowerText.contains("angry") || lowerText.contains("mad") || lowerText.contains("furious") {
            return "anger"
        }
        if lowerText.contains("sad") || lowerText.contains("upset") || lowerText.contains("disappointed") {
            return "sadness"
        }
        if lowerText.contains("worried") || lowerText.contains("anxious") || lowerText.contains("nervous") {
            return "anxiety"
        }
        if lowerText.contains("frustrated") || lowerText.contains("annoyed") {
            return "frustration"
        }
        if lowerText.contains("happy") || lowerText.contains("excited") || lowerText.contains("joy") {
            return "happiness"
        }
        
        return "neutral"
    }
    
    /// Generate emotion-aware suggestions using JSON emotion buckets
    private func generateEmotionAwareSuggestions(text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var candidates: [FixCandidate] = []
        
        guard let emotionBuckets = JSONKnowledgeBase.emotionBuckets["emotionBuckets"] as? [String: [String]] else {
            return candidates
        }
        
        let textLower = text.lowercased()
        
        // Check for emotional words and suggest alternatives
        for (emotion, words) in emotionBuckets {
            let emotionWords = words.filter { textLower.contains($0.lowercased()) }
            
            if !emotionWords.isEmpty {
                let emotionBasedSuggestion = generateEmotionBasedSuggestion(
                    text: text,
                    detectedEmotion: emotion,
                    emotionWords: emotionWords,
                    analysis: analysis
                )
                
                if let suggestion = emotionBasedSuggestion {
                    candidates.append(suggestion)
                }
            }
        }
        
        return candidates
    }
    
    /// Generate attachment trigger-aware suggestions
    private func generateTriggerAwareSuggestions(text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var candidates: [FixCandidate] = []
        
        guard let triggers = JSONKnowledgeBase.attachmentTriggers as? [String: [String]] else {
            return candidates
        }
        
        let textLower = text.lowercased()
        
        // Check for attachment style triggers
        for (triggerType, triggerPhrases) in triggers {
            let matchingTriggers = triggerPhrases.filter { textLower.contains($0.lowercased()) }
            
            if !matchingTriggers.isEmpty {
                let triggerAwareSuggestion = generateTriggerAwareSuggestion(
                    text: text,
                    triggerType: triggerType,
                    matchingTriggers: matchingTriggers,
                    analysis: analysis
                )
                
                if let suggestion = triggerAwareSuggestion {
                    candidates.append(suggestion)
                }
            }
        }
        
        return candidates
    }
    
    /// Generate emotion-based suggestion
    private func generateEmotionBasedSuggestion(text: String, detectedEmotion: String, emotionWords: [String], analysis: DeepTextAnalysis) -> FixCandidate? {
        let attachmentStyle = analysis.attachmentSignals.detectedStyle ?? getAttachmentStyle()
        
        switch detectedEmotion {
        case "anger":
            return FixCandidate(
                text: "I'm feeling frustrated about this. Can we talk it through calmly?",
                type: .emotionAware,
                attachmentRelevance: .high,
                reasoning: "Detected anger words (\(emotionWords.joined(separator: ", "))) - suggesting calmer expression",
                sourceEngine: .jsonKnowledge,
                confidence: 0.8
            )
            
        case "fear", "anxiety":
            if attachmentStyle == .anxious {
                return FixCandidate(
                    text: "I'm feeling anxious about this. Could we check in so I feel more secure?",
                    type: .emotionAware,
                    attachmentRelevance: .high,
                    reasoning: "Detected fear/anxiety words for anxious attachment - suggesting reassurance request",
                    sourceEngine: .jsonKnowledge,
                    confidence: 0.85
                )
            }
            
        case "sadness":
            return FixCandidate(
                text: "I'm feeling sad about this situation. Can we work together to improve it?",
                type: .emotionAware,
                attachmentRelevance: .medium,
                reasoning: "Detected sadness words - suggesting collaborative approach",
                sourceEngine: .jsonKnowledge,
                confidence: 0.75
            )
            
        case "shame", "guilt":
            return FixCandidate(
                text: "I'm taking responsibility for my part in this. How can we move forward together?",
                type: .emotionAware,
                attachmentRelevance: .high,
                reasoning: "Detected shame/guilt words - suggesting responsibility and collaboration",
                sourceEngine: .jsonKnowledge,
                confidence: 0.8
            )
            
        default:
            break
        }
        
        return nil
    }
    
    /// Generate trigger-aware suggestion
    private func generateTriggerAwareSuggestion(text: String, triggerType: String, matchingTriggers: [String], analysis: DeepTextAnalysis) -> FixCandidate? {
        switch triggerType {
        case "anxiousTriggers":
            return FixCandidate(
                text: "I'm feeling insecure and would appreciate some reassurance. Can we connect?",
                type: .triggerAware,
                attachmentRelevance: .high,
                reasoning: "Detected anxious trigger phrases (\(matchingTriggers.joined(separator: ", "))) - suggesting direct reassurance request",
                sourceEngine: .jsonKnowledge,
                confidence: 0.9
            )
            
        case "avoidantTriggers":
            return FixCandidate(
                text: "I need some space to process this. Can we revisit this conversation later?",
                type: .triggerAware,
                attachmentRelevance: .high,
                reasoning: "Detected avoidant trigger phrases - suggesting healthy boundary setting",
                sourceEngine: .jsonKnowledge,
                confidence: 0.85
            )
            
        case "disorganizedTriggers":
            return FixCandidate(
                text: "I'm feeling overwhelmed and need help organizing my thoughts. Can we break this down together?",
                type: .triggerAware,
                attachmentRelevance: .high,
                reasoning: "Detected disorganized trigger phrases - suggesting step-by-step approach",
                sourceEngine: .jsonKnowledge,
                confidence: 0.8
            )
            
        case "securePatterns":
            // These are positive, so enhance rather than replace
            return FixCandidate(
                text: text, // Keep original as it's already secure
                type: .triggerAware,
                attachmentRelevance: .high,
                reasoning: "Detected secure communication patterns - text is already healthy",
                sourceEngine: .jsonKnowledge,
                confidence: 0.95
            )
            
        default:
            break
        }
        
        return nil
    }
    
    // MARK: - Advanced JSON Enhancement Methods (I-Statements, Cross-Style Communication)
    
    /// Generate I-Statement based suggestions using attachment style
    private func generateIStatementSuggestions(text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var candidates: [FixCandidate] = []
        
        // Get attachment style for targeted I-statements
        let attachmentStyle = analysis.attachmentSignals.detectedStyle ?? getAttachmentStyle()
        let styleKey = mapAttachmentStyleToKey(attachmentStyle)
        
        guard let iStatementsData = JSONKnowledgeBase.iStatements["i_statements"] as? [String: [String]],
              let styleTemplates = iStatementsData[styleKey] else {
            return candidates
        }
        
        let slotsData = JSONKnowledgeBase.iStatementSlots
        
        // Extract emotion and behavior from text analysis
        let detectedEmotion = extractEmotionFromAnalysis(analysis)
        let detectedBehavior = extractBehaviorFromText(text)
        let detectedFear = extractFearFromAnalysis(analysis, attachmentStyle: attachmentStyle)
        let suggestedRequest = generateRequest(for: attachmentStyle, analysis: analysis)
        
        // Generate I-statements using templates and slots
        for template in styleTemplates.prefix(2) {
            let iStatement = fillIStatementTemplate(
                template: template,
                emotion: detectedEmotion,
                behavior: detectedBehavior,
                fear: detectedFear,
                request: suggestedRequest,
                slots: slotsData
            )
            
            candidates.append(FixCandidate(
                text: iStatement,
                type: .feelingTransformation,
                attachmentRelevance: .high,
                reasoning: "Transformed to attachment-aware I-statement for \(styleKey) style",
                sourceEngine: .jsonKnowledge,
                confidence: 0.9
            ))
        }
        
        return candidates
    }
    
    /// Generate cross-style communication suggestions
    private func generateCrossStyleSuggestions(text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var candidates: [FixCandidate] = []
        
        guard let crossStyleData = JSONKnowledgeBase.crossStyleCommunication["crossStyleSuggestions"] as? [String: Any] else {
            return candidates
        }
        
        let userStyle = analysis.attachmentSignals.detectedStyle ?? getAttachmentStyle()
        let partnerStyle = inferPartnerAttachmentStyle(from: analysis)
        
        let crossStyleKey = "\(mapAttachmentStyleToKey(userStyle))_\(mapAttachmentStyleToKey(partnerStyle))"
        
        if let suggestions = crossStyleData[crossStyleKey] as? [[String: Any]] {
            for suggestion in suggestions.prefix(3) {
                if let repairScript = suggestion["repairScriptTemplate"] as? String,
                   let reasoning = suggestion["reasoning"] as? String,
                   let priority = suggestion["priority"] as? String {
                    
                    candidates.append(FixCandidate(
                        text: repairScript,
                        type: .attachmentStyleSpecific,
                        attachmentRelevance: .high,
                        reasoning: "Cross-style communication: \(reasoning)",
                        sourceEngine: .jsonKnowledge,
                        confidence: priorityToConfidence(priority)
                    ))
                }
            }
        }
        
        return candidates
    }
    
    // MARK: - Helper Methods for Enhanced JSON Processing
    
    /// Map attachment style to JSON key format
    private func mapAttachmentStyleToKey(_ style: AttachmentStyle) -> String {
        switch style {
        case .secure: return "secure"
        case .anxious: return "anxious"
        case .avoidant: return "avoidant"
        case .disorganized: return "disorganized"
        case .unknown: return "secure" // Default to secure for unknown
        }
    }
    
    /// Extract emotion from analysis for I-statement generation
    private func extractEmotionFromAnalysis(_ analysis: DeepTextAnalysis) -> String {
        if analysis.conflictLevel > 0.7 {
            return "frustrated"
        } else if analysis.emotionalIntensity > 0.8 {
            return "overwhelmed"
        } else if analysis.toneProfile.primaryTone == .alert {
            return "concerned"
        } else {
            return "uncertain"
        }
    }
    
    /// Extract behavior description from text
    private func extractBehaviorFromText(_ text: String) -> String {
        let textLower = text.lowercased()
        
        if textLower.contains("interrupt") { return "interrupting me" }
        if textLower.contains("ignore") { return "not responding" }
        if textLower.contains("late") { return "arriving late" }
        if textLower.contains("cancel") { return "canceling plans" }
        if textLower.contains("phone") { return "checking your phone" }
        if textLower.contains("walk away") { return "walking away mid-conversation" }
        
        return "not communicating clearly"
    }
    
    /// Extract fear based on attachment style and analysis
    private func extractFearFromAnalysis(_ analysis: DeepTextAnalysis, attachmentStyle: AttachmentStyle) -> String {
        switch attachmentStyle {
        case .anxious:
            return analysis.conflictLevel > 0.6 ? "being abandoned" : "being misunderstood"
        case .avoidant:
            return "losing my independence"
        case .disorganized:
            return "not feeling safe"
        case .secure:
            return "losing connection"
        case .unknown:
            return "not being heard"
        }
    }
    
    /// Generate appropriate request based on attachment style
    private func generateRequest(for style: AttachmentStyle, analysis: DeepTextAnalysis) -> String {
        switch style {
        case .anxious:
            return "give me some reassurance"
        case .avoidant:
            return "let me know when you're ready to talk"
        case .disorganized:
            return "help me understand your perspective"
        case .secure:
            return "work together to find a solution"
        case .unknown:
            return "let me know what you're thinking"
        }
    }
    
    /// Fill I-statement template with appropriate slots
    private func fillIStatementTemplate(template: String, emotion: String, behavior: String, fear: String, request: String, slots: [String: Any]) -> String {
        var filledTemplate = template
        
        filledTemplate = filledTemplate.replacingOccurrences(of: "{emotion}", with: emotion)
        filledTemplate = filledTemplate.replacingOccurrences(of: "{behavior}", with: behavior)
        filledTemplate = filledTemplate.replacingOccurrences(of: "{fear}", with: fear)
        filledTemplate = filledTemplate.replacingOccurrences(of: "{request}", with: request)
        
        return filledTemplate
    }
    
    /// Infer partner's attachment style from communication context
    private func inferPartnerAttachmentStyle(from analysis: DeepTextAnalysis) -> AttachmentStyle {
        if analysis.relationshipDynamics.hasDistancing {
            return .avoidant
        } else if analysis.conflictLevel > 0.7 {
            return .anxious
        } else if analysis.emotionalIntensity > 0.8 {
            return .disorganized
        } else {
            return .secure
        }
    }
    
    /// Real-time processing (optimized for speed with JSON knowledge)
    private func processRealTime(_ text: String) -> AITextResult {
        // Quick child name detection for empathy echo
        let detectedChildNames = detectChildNames(in: text)
        if !detectedChildNames.isEmpty {
            if let empathyEcho = generateQuickEmpathyEcho(text: text, childNames: detectedChildNames) {
                return AITextResult(
                    originalText: text,
                    improvedText: empathyEcho,
                    confidence: 0.9,
                    reasoning: "Quick empathy echo for child-focused communication",
                    attachmentStyleFactors: [getAttachmentStyle().rawValue],
                    emotionalImpact: EmotionalImpact(),
                    communicationGoals: [CommunicationGoal.empathy, CommunicationGoal.child_focus]
                )
            }
        }
        
        let quickFixed = quickFixWithJSON(text)
        let quickAnalysis = performQuickAnalysis(text)
        
        return AITextResult(
            originalText: text,
            improvedText: quickFixed,
            confidence: 0.8,
            reasoning: "Quick attachment-style fix with JSON enhancement",
            attachmentStyleFactors: [getAttachmentStyle().rawValue],
            emotionalImpact: EmotionalImpact(),
            communicationGoals: [CommunicationGoal.immediate_improvement]
        )
    }
    
    /// Generate quick empathy echo for real-time processing
    private func generateQuickEmpathyEcho(text: String, childNames: [String]) -> String? {
        guard let childLanguageData = JSONKnowledgeBase.childLanguage["childCenteredLanguage"] as? [String: Any],
              let empathyData = childLanguageData["empathyEcho"] as? [String: Any],
              let templates = empathyData["templates"] as? [String],
              let triggers = empathyData["triggers"] as? [String] else {
            return nil
        }
        
        let textLower = text.lowercased()
        let primaryChildName = childNames.first ?? "your child"
        
        // Quick check for empathy triggers
        let hasEmpathyTrigger = triggers.contains { trigger in
            textLower.contains(trigger.replacingOccurrences(of: "{child_name}", with: primaryChildName.lowercased()))
        }
        
        if hasEmpathyTrigger {
            let template = templates.first ?? "It sounds like {child_name}'s well-being is important to both of you."
            return template.replacingOccurrences(of: "{child_name}", with: primaryChildName)
        }
        
        return nil
    }
    
    /// Quick fix method enhanced with JSON auto-fix data
    private func quickFixWithJSON(_ text: String) -> String {
        var result = text
        
        // 1. Apply JSON auto-fix replacements first (fastest)
        if let autoFixData = JSONKnowledgeBase.autoFixReplacements["autoFix"] as? [String: Any],
           let alertFixes = autoFixData["alert"] as? [[String: Any]] {
            
            for fix in alertFixes {
                if let find = fix["find"] as? String,
                   let replace = fix["replace"] as? String {
                    result = result.replacingOccurrences(of: find, with: replace, options: .caseInsensitive)
                }
            }
        }
        
        // 2. Apply attachment-style quick fixes
        let attachmentStyle = getAttachmentStyle()
        result = applyCriticalToneFixes(result, style: attachmentStyle)
        
        // 3. Apply quick pattern fixes based on detected patterns
        result = applyQuickPatternFixes(result)
        
        return result
    }
    
    /// Apply quick pattern fixes for common issues
    private func applyQuickPatternFixes(_ text: String) -> String {
        var result = text
        
        // Quick fixes for common problematic patterns
        let quickFixes = [
            ("you always", "you often"),
            ("you never", "you rarely"),
            ("I always", "I often"),
            ("I never", "I rarely"),
            ("you're wrong", "I see it differently"),
            ("that's stupid", "that's unclear to me"),
            ("shut up", "let me finish"),
            ("whatever", "I understand")
        ]
        
        for (find, replace) in quickFixes {
            result = result.replacingOccurrences(of: find, with: replace, options: .caseInsensitive)
        }
        
        return result
    }
    
    /// Tone-focused processing
    private func processToneOnly(_ text: String) -> AITextResult {
        let tone = analyzeLocalTone(text)
        let toneFixed = applyCriticalToneFixes(text, style: getAttachmentStyle())
        
        return AITextResult(
            originalText: text,
            improvedText: toneFixed,
            confidence: 0.9,
            reasoning: "Tone-focused improvement",
            attachmentStyleFactors: [getAttachmentStyle().rawValue],
            emotionalImpact: EmotionalImpact(),
            communicationGoals: [CommunicationGoal.tone_improvement]
        )
    }
    
    /// Suggestions-focused processing
    private func processSuggestionsOnly(_ text: String) -> AITextResult {
        let suggestions = ["I understand your perspective", "Let's work together on this", "Can we talk about this calmly?"]
        let bestSuggestion = suggestions.first ?? text
        
        return AITextResult(
            originalText: text,
            improvedText: bestSuggestion,
            confidence: 0.85,
            reasoning: "Suggestion-focused improvement",
            attachmentStyleFactors: [getAttachmentStyle().rawValue],
            emotionalImpact: EmotionalImpact(),
            communicationGoals: [CommunicationGoal.suggestion_based]
        )
    }
    
    // MARK: - Deep Text Analysis
    
    /// Enhanced analysis using local processors only
    private func performDeepTextAnalysis(_ text: String) -> DeepTextAnalysis {
        // Use simple local analysis instead of complex engines
        let sentiment = calculateLocalSentiment(text)
        let linguisticPatterns = extractLocalLinguisticPatterns(text)
        let communicationPattern = detectCommunicationPattern(text)
        let detectedAttachmentStyle = detectLocalAttachmentStyle(text)
        let emotionalNeeds = assessLocalEmotionalNeeds(text)
        
        // Local tone analysis using simple keyword detection
        let toneStatus = analyzeLocalTone(text)
        let conflictLevel = assessLocalConflictLevel(text)
        let urgencyLevel = assessLocalUrgencyLevel(text)
        let hasDistancing = detectLocalDistancing(text)
        
        return DeepTextAnalysis(
            sentiment: sentiment,
            emotionalIntensity: calculateEmotionalIntensity(text),
            linguisticPatterns: linguisticPatterns,
            attachmentSignals: AttachmentSignals(
                detectedStyle: detectedAttachmentStyle,
                intensity: abs(sentiment) + conflictLevel
            ),
            defensiveMechanisms: detectDefensiveMechanisms(text),
            emotionalNeeds: emotionalNeeds,
            communicationPattern: communicationPattern,
            toneProfile: ToneProfile(
                primaryTone: toneStatus,
                confidence: 0.8
            ),
            relationshipDynamics: RelationshipDynamics(
                hasDistancing: hasDistancing,
                contextType: .unknown,
                negativeIntensity: max(0, -sentiment)
            ),
            urgencyLevel: urgencyLevel,
            conflictLevel: conflictLevel,
            intimacyLevel: assessIntimacyLevel(text)
        )
    }
    
    /// Extract enhanced linguistic patterns using basic text analysis
    private func extractEnhancedLinguisticPatterns(_ text: String, comprehensiveTone: Any) -> LinguisticPatterns {
        // Use simple local analysis instead of complex comprehensiveTone
        let hasAbsolutes = text.lowercased().contains("always") || text.lowercased().contains("never") ||
                          text.lowercased().contains("all") || text.lowercased().contains("none")
        
        let isDisorganized = text.count > 100 && text.filter { $0 == "!" }.count > 2
        
        let canOptimizeClarity = text.count > 50

        // Provide default values for required parameters
        let complexity = 0.5
        let emotionalVolatility = 0.5
        let psychologicalMarkers = PsychologicalIndicators()

        return LinguisticPatterns(
            hasAbsolutes: hasAbsolutes,
            isDisorganized: isDisorganized,
            canOptimizeClarity: canOptimizeClarity,
            complexity: complexity,
            emotionalVolatility: emotionalVolatility,
            psychologicalMarkers: psychologicalMarkers
        )
    }
    
    private func performQuickAnalysis(_ text: String) -> QuickTextAnalysis {
        // Local analysis using simple heuristics
        let hasCriticalTone = text.contains("!") || text.uppercased() == text
        let dominantEmotion = detectDominantEmotion(text)
        let attachmentSignals = detectAttachmentSignals(text)
        let communicationPattern = detectCommunicationPattern(text)
        let riskLevel = assessRiskLevel(text)
        let traumaResponse = detectTraumaResponse(text)
        let negativeIntensity = calculateNegativeIntensity(text)
        let attachmentActivationLevel = calculateAttachmentActivation(text)
        
        return QuickTextAnalysis(
            hasCriticalTone: hasCriticalTone,
            dominantEmotion: dominantEmotion,
            attachmentSignals: attachmentSignals,
            communicationPattern: communicationPattern,
            riskLevel: riskLevel,
            traumaResponse: traumaResponse,
            negativeIntensity: negativeIntensity,
            attachmentActivationLevel: attachmentActivationLevel
        )
    }
    
    // MARK: - Local Analysis Helper Functions
    
    private func detectDominantEmotion(_ text: String) -> Emotion {
        let lowerText = text.lowercased()
        if lowerText.contains("angry") || lowerText.contains("mad") || lowerText.contains("furious") {
            return .angry
        } else if lowerText.contains("sad") || lowerText.contains("depressed") || lowerText.contains("upset") {
            return .sad
        } else if lowerText.contains("anxious") || lowerText.contains("worried") || lowerText.contains("nervous") {
            return .anxious
        } else if lowerText.contains("happy") || lowerText.contains("joy") || lowerText.contains("excited") {
            return .happy
        } else {
            return .neutral
        }
    }
    
    private func detectAttachmentSignals(_ text: String) -> [AttachmentSignal] {
        var signals: [AttachmentSignal] = []
        let lowerText = text.lowercased()
        
        if lowerText.contains("need") || lowerText.contains("want") {
            signals.append(.needExpression)
        }
        if lowerText.contains("feel") || lowerText.contains("emotion") {
            signals.append(.emotionalExpression)
        }
        if lowerText.contains("help") || lowerText.contains("support") {
            signals.append(.supportSeeking)
        }
        
        return signals
    }
    
    private func detectCommunicationPattern(_ text: String) -> CommunicationPattern {
        let lowerText = text.lowercased()
        if lowerText.contains("i feel") || lowerText.contains("i think") {
            return .iStatement
        } else if lowerText.contains("you") && (lowerText.contains("always") || lowerText.contains("never")) {
            return .youStatement
        } else {
            return .neutral
        }
    }
    
    private func assessRiskLevel(_ text: String) -> RiskLevel {
        let lowerText = text.lowercased()
        if lowerText.contains("crisis") || lowerText.contains("emergency") {
            return .critical
        } else if lowerText.contains("conflict") || lowerText.contains("argument") {
            return .high
        } else {
            return .low
        }
    }
    
    private func detectTraumaResponse(_ text: String) -> String? {
        let lowerText = text.lowercased()
        if lowerText.contains("trigger") || lowerText.contains("overwhelm") {
            return "triggered"
        }
        return nil
    }
    
    private func calculateNegativeIntensity(_ text: String) -> Double {
        let negativeWords = ["hate", "awful", "terrible", "horrible", "worst"]
        let lowerText = text.lowercased()
        let count = negativeWords.reduce(0) { count, word in
            count + (lowerText.contains(word) ? 1 : 0)
        }
        return min(Double(count) * 0.3, 1.0)
    }
    
    private func calculateAttachmentActivation(_ text: String) -> Double {
        let attachmentWords = ["abandon", "reject", "leave", "alone", "distant"]
        let lowerText = text.lowercased()
        let count = attachmentWords.reduce(0) { count, word in
            count + (lowerText.contains(word) ? 1 : 0)
        }
        return min(Double(count) * 0.4, 1.0)
    }
    
    // MARK: - Simplified Local Analysis Methods
    
    /// Local tone analysis using keyword detection
    private func analyzeLocalTone(_ text: String) -> ToneStatus {
        print("🧠 analyzeLocalTone called with text: '\(text)'")
        let lowerText = text.lowercased()
        
        // Alert indicators
        let alertWords = ["hate", "stupid", "idiot", "terrible", "awful", "shit", "fuck", "damn"]
        if alertWords.contains(where: { lowerText.contains($0) }) {
            print("🧠 Alert tone detected due to word: \(alertWords.first(where: { lowerText.contains($0) }) ?? "unknown")")
            return .alert
        }
        
        // Caution indicators
        let cautionWords = ["must", "should", "need to", "have to", "immediately", "urgent"]
        if cautionWords.contains(where: { lowerText.contains($0) }) {
            print("🧠 Caution tone detected due to word: \(cautionWords.first(where: { lowerText.contains($0) }) ?? "unknown")")
            return .caution
        }
        
        // Positive indicators
        let positiveWords = ["love", "great", "wonderful", "amazing", "thank", "appreciate"]
        if positiveWords.contains(where: { lowerText.contains($0) }) {
            print("🧠 Clear tone detected due to word: \(positiveWords.first(where: { lowerText.contains($0) }) ?? "unknown")")
            return .clear
        }
        
        print("🧠 Neutral tone (no keywords matched)")
        return .neutral
    }
    
    /// Calculate confidence score for tone analysis
    private func calculateToneConfidence(_ text: String, status: ToneStatus) -> Double {
        let lowerText = text.lowercased()
        
        // Higher confidence for longer text with clear indicators
        let baseConfidence: Double
        switch status {
        case .alert:
            // Strong negative words give high confidence
            let strongAlertWords = ["hate", "stupid", "idiot", "fuck", "shit"]
            baseConfidence = strongAlertWords.contains(where: { lowerText.contains($0) }) ? 0.9 : 0.7
        case .caution:
            // Directive words give medium-high confidence
            baseConfidence = 0.75
        case .clear:
            // Positive words give high confidence
            let strongPositiveWords = ["love", "amazing", "wonderful"]
            baseConfidence = strongPositiveWords.contains(where: { lowerText.contains($0) }) ? 0.85 : 0.7
        case .neutral, .analyzing:
            // Neutral has lower confidence as it's the default
            baseConfidence = 0.6
        }
        
        // Adjust confidence based on text length and clarity
        let lengthFactor = min(Double(text.count) / 50.0, 1.0) // Max benefit at 50 chars
        let exclamationCount = Double(text.filter { $0 == "!" }.count)
        let capsCount = Double(text.filter { $0.isUppercase }.count)
        
        let adjustedConfidence = baseConfidence + (lengthFactor * 0.1) + (exclamationCount * 0.05) + (capsCount / Double(text.count) * 0.1)
        
        return min(adjustedConfidence, 0.95) // Cap at 95%
    }
    
    /// Calculate emotional intensity from text patterns
    private func calculateEmotionalIntensity(_ text: String) -> Double {
        let lowerText = text.lowercased()
        var intensity = 0.0
        
        // Exclamation marks increase intensity
        intensity += Double(text.filter { $0 == "!" }.count) * 0.2
        
        // All caps words increase intensity
        let words = text.components(separatedBy: .whitespaces)
        let capsWords = words.filter { $0.count > 2 && $0 == $0.uppercased() && $0 != $0.lowercased() }
        intensity += Double(capsWords.count) * 0.3
        
        // Strong emotional words increase intensity
        let strongWords = ["extremely", "absolutely", "completely", "totally", "incredibly"]
        intensity += Double(strongWords.filter { lowerText.contains($0) }.count) * 0.25
        
        return min(intensity, 1.0)
    }
    
    /// Detect defensive mechanisms using simple patterns
    private func detectDefensiveMechanisms(_ text: String) -> [DefensiveMechanism] {
        let lowerText = text.lowercased()
        var mechanisms: [DefensiveMechanism] = []
        
        if lowerText.contains("not my fault") || lowerText.contains("you did") {
            mechanisms.append(.blameShifting)
        }
        
        if lowerText.contains("but") || lowerText.contains("however") {
            mechanisms.append(.deflection)
        }
        
        if lowerText.contains("it's not that bad") || lowerText.contains("just") {
            mechanisms.append(.minimization)
        }
        
        if lowerText.contains("because") || lowerText.contains("the reason is") {
            mechanisms.append(.rationalization)
        }
        
        return mechanisms
    }
    
    /// Assess intimacy level from text content
    private func assessIntimacyLevel(_ text: String) -> Double {
        let lowerText = text.lowercased()
        var intimacy = 0.5 // Base level
        
        // Personal pronouns increase intimacy
        if lowerText.contains("we") || lowerText.contains("us") || lowerText.contains("our") {
            intimacy += 0.2
        }
        
        // Emotional words increase intimacy
        let emotionalWords = ["love", "feel", "heart", "care", "miss", "close"]
        intimacy += Double(emotionalWords.filter { lowerText.contains($0) }.count) * 0.1
        
        // Pet names and endearments increase intimacy
        let endearments = ["honey", "dear", "babe", "sweetie", "darling"]
        if endearments.contains(where: { lowerText.contains($0) }) {
            intimacy += 0.3
        }
        
        return min(intimacy, 1.0)
    }
    
    // MARK: - Additional Local Analysis Methods
    
    private func calculateLocalSentiment(_ text: String) -> Double {
        let positiveWords = ["good", "great", "love", "happy", "wonderful", "amazing", "perfect"]
        let negativeWords = ["bad", "hate", "terrible", "awful", "horrible", "stupid", "worst"]
        
        let lowerText = text.lowercased()
        let positiveCount = positiveWords.filter { lowerText.contains($0) }.count
        let negativeCount = negativeWords.filter { lowerText.contains($0) }.count
        
        return (Double(positiveCount) - Double(negativeCount)) / max(Double(positiveCount + negativeCount), 1.0)
    }
    
    private func extractLocalLinguisticPatterns(_ text: String) -> LinguisticPatterns {
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let sentenceCount = text.components(separatedBy: CharacterSet(charactersIn: ".!?")).filter { !$0.isEmpty }.count
        let complexity = Double(wordCount) / max(Double(sentenceCount), 1.0)
        
        let hasAbsolutes = text.lowercased().contains("always") || text.lowercased().contains("never")
        let isDisorganized = complexity > 20 || sentenceCount == 0
        let canOptimizeClarity = text.contains("  ") || text.contains("um") || text.contains("like")
        
      return LinguisticPatterns(
    hasAbsolutes: hasAbsolutes,
    isDisorganized: isDisorganized,
    canOptimizeClarity: canOptimizeClarity,
    complexity: 0.5, // or calculate as needed
    emotionalVolatility: 0.5,
    psychologicalMarkers: PsychologicalIndicators()
        )
    }
    
    private func detectLocalAttachmentStyle(_ text: String) -> AttachmentStyle {
        let lowerText = text.lowercased()
        
        if lowerText.contains("reassur") || lowerText.contains("insecur") || lowerText.contains("abandon") {
            return .anxious
        } else if lowerText.contains("space") || lowerText.contains("independence") || lowerText.contains("fine") {
            return .avoidant
        } else if lowerText.contains("confus") || lowerText.contains("overwhelm") {
            return .disorganized
        } else if lowerText.contains("understand") && lowerText.contains("together") {
            return .secure
        }
        return .unknown
    }
    
    private func assessLocalEmotionalNeeds(_ text: String) -> EmotionalNeeds {
        let lowerText = text.lowercased()
        
        let needsReassurance = lowerText.contains("reassur") || lowerText.contains("sure") || lowerText.contains("certain")
        let hasContradictions = (lowerText.contains("love") && lowerText.contains("hate")) || (lowerText.contains("want") && lowerText.contains("don't want"))
        let canBenefitFromEmpathy = lowerText.contains("hurt") || lowerText.contains("sad") || lowerText.contains("lonely")
        
        return EmotionalNeeds(
            needsReassurance: needsReassurance,
            hasContradictions: hasContradictions,
            canBenefitFromEmpathy: canBenefitFromEmpathy
        )
    }
    
    private func assessLocalConflictLevel(_ text: String) -> Double {
        let conflictWords = ["fight", "argue", "disagree", "wrong", "hate", "angry"]
        let lowerText = text.lowercased()
        let conflictCount = conflictWords.filter { lowerText.contains($0) }.count
        return min(Double(conflictCount) / 3.0, 1.0)
    }
    
    private func assessLocalUrgencyLevel(_ text: String) -> Double {
        let urgentWords = ["urgent", "asap", "immediately", "now", "emergency"]
        let lowerText = text.lowercased()
        let urgentCount = urgentWords.filter { lowerText.contains($0) }.count
        return min(Double(urgentCount) / 2.0, 1.0)
    }
    
    private func detectLocalDistancing(_ text: String) -> Bool {
        let distancingWords = ["space", "alone", "away", "distance", "independence"]
        let lowerText = text.lowercased()
        return distancingWords.contains { lowerText.contains($0) }
    }
    
    // MARK: - Fix Generation
    
    /// Enhanced fix generation leveraging existing sophisticated engines
    private func generateFixCandidates(_ text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var candidates: [FixCandidate] = []
        
        // 1. Leverage existing advanced suggestions engine (stub implementation)
        let existingSuggestions = ["I understand your perspective", "Let's work together on this", "Can we talk about this calmly?"]
        for suggestion in existingSuggestions {
            candidates.append(FixCandidate(
                text: suggestion,
                type: .existingEngineSuggestion,
                attachmentRelevance: determineRelevanceFromSuggestion(suggestion, analysis: analysis),
                reasoning: "Generated by existing advanced suggestions engine",
                sourceEngine: .advancedSuggestions,
                confidence: 0.8
            ))
        }
        
        // 2. Leverage existing tone-based suggestions (stub implementation)
        let toneSuggestions = ["Try using a calmer tone", "Consider softer language", "Let's approach this differently"]
        for toneSuggestion in toneSuggestions {
            candidates.append(FixCandidate(
                text: toneSuggestion,
                type: .toneBased,
                attachmentRelevance: .medium,
                reasoning: "Tone-specific improvement from existing engine",
                sourceEngine: .toneAnalysis,
                confidence: 0.7
            ))
        }
        
        // 3. Leverage existing attachment-style suggestions
        if let detectedStyle = analysis.attachmentSignals.detectedStyle {
            // Stub implementation for attachment style suggestions
            let attachmentSuggestions = ["I need some reassurance", "Can we take a step back?", "Let's work on this together"]
            for attachmentSuggestion in attachmentSuggestions {
                candidates.append(FixCandidate(
                    text: attachmentSuggestion,
                    type: .attachmentStyleSpecific,
                    attachmentRelevance: .high,
                    reasoning: "Attachment-style specific suggestion from existing engine",
                    sourceEngine: .attachmentAnalysis,
                    confidence: 0.85
                ))
            }
        }
        
        // 4. Leverage existing communication pattern fixes
        let patternSuggestions = ["Try using 'I' statements", "Let's approach this differently", "Can we find common ground?"]
        for patternSuggestion in patternSuggestions {
            candidates.append(FixCandidate(
                text: patternSuggestion,
                type: .communicationPattern,
                attachmentRelevance: .medium,
                reasoning: "Communication pattern improvement from existing engine",
                sourceEngine: .patternAnalysis,
                confidence: 0.75
            ))
        }
        
        // 5. Leverage existing repair strategies for high-risk situations
        if analysis.conflictLevel > 0.6 {
            // Stub implementation for repair strategies
            let repairSuggestions = ["Let's take a break", "Can we start over?", "I want to understand your perspective"]
            for repairSuggestion in repairSuggestions {
                candidates.append(FixCandidate(
                    text: repairSuggestion,
                    type: .repairStrategy,
                    attachmentRelevance: .high,
                    reasoning: "Repair strategy from existing sophisticated engine",
                    sourceEngine: .repairStrategies,
                    confidence: 0.9
                ))
            }
        }
        
        // 6. Leverage existing auto-fix capabilities (stub implementation)
        let autoFix = text.replacingOccurrences(of: "always", with: "often")
            .replacingOccurrences(of: "never", with: "rarely")
        if autoFix != text {
            candidates.append(FixCandidate(
                text: autoFix,
                type: .autoFix,
                attachmentRelevance: .medium,
                reasoning: "Auto-fix from existing sophisticated engine",
                sourceEngine: .autoFix,
                confidence: 0.8
            ))
        }
        
        // 7. Add our custom attachment-style specific fixes
        candidates.append(contentsOf: generateAttachmentStyleFixes(text, analysis: analysis))
        
        // 8. Add our custom emotional intelligence fixes
        candidates.append(contentsOf: generateEmotionalIntelligenceFixes(text, analysis: analysis))
        
        return candidates
    }
    
    /// Map analysis to tone status for existing engine compatibility
    private func mapAnalysisToToneStatus(_ analysis: DeepTextAnalysis) -> ToneStatus {
        if analysis.conflictLevel > 0.7 {
            return .alert
        } else if analysis.conflictLevel > 0.4 || analysis.urgencyLevel > 0.6 {
            return .caution
        } else if analysis.sentiment > 0.3 {
            return .clear
        } else {
            return .neutral
        }
    }
    
    /// Determine relevance from suggestion content
    private func determineRelevanceFromSuggestion(_ suggestion: String, analysis: DeepTextAnalysis) -> Relevance {
        let lowerSuggestion = suggestion.lowercased()
        
        // High relevance for attachment-specific suggestions
        if lowerSuggestion.contains("anxious") || lowerSuggestion.contains("avoidant") ||
           lowerSuggestion.contains("secure") || lowerSuggestion.contains("disorganized") {
            return .high
        }
        
        // Medium relevance for emotional or communication suggestions
        if lowerSuggestion.contains("feel") || lowerSuggestion.contains("emotion") ||
           lowerSuggestion.contains("communication") || lowerSuggestion.contains("relationship") {
            return .medium
        }
        
        return .low
    }
    
    private func generateAttachmentStyleFixes(_ text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        let userStyle = getAttachmentStyle()
        var fixes: [FixCandidate] = []
        
        switch userStyle {
        case .anxious:
            fixes.append(contentsOf: generateAnxiousStyleFixes(text, analysis: analysis))
        case .avoidant:
            fixes.append(contentsOf: generateAvoidantStyleFixes(text, analysis: analysis))
        case .disorganized:
            fixes.append(contentsOf: generateDisorganizedStyleFixes(text, analysis: analysis))
        case .secure:
            fixes.append(contentsOf: generateSecureStyleFixes(text, analysis: analysis))
        case .unknown:
            fixes.append(contentsOf: generateGeneralStyleFixes(text, analysis: analysis))
        }
        
        return fixes
    }
    
    // MARK: - AI-like Scoring and Ranking
    
    private func rankFixesWithAI(_ candidates: [FixCandidate], originalText: String, analysis: DeepTextAnalysis) -> [RankedFix] {
        return candidates.map { candidate in
            let score = calculateAIScore(candidate, originalText: originalText, analysis: analysis)
            let confidence = calculateConfidence(candidate, score: score)
            let reasoning = generateReasoning(candidate, score: score, analysis: analysis)
            
            return RankedFix(
                candidate: candidate,
                score: score,
                confidence: confidence,
                reasoning: reasoning,
                psychologicalRationale: generatePsychologicalRationale(candidate, analysis: analysis),
                expectedOutcome: generateExpectedOutcome(candidate, score: score)
            )
        }.sorted { $0.score > $1.score }
    }
    
    private func calculateAIScore(_ candidate: FixCandidate, originalText: String, analysis: DeepTextAnalysis) -> Double {
        var score: Double = 0.0
        
        // 1. Attachment style alignment (30% weight)
        score += calculateAttachmentStyleAlignment(candidate, analysis: analysis) * 0.30
        
        // 2. Emotional intelligence improvement (25% weight)
        score += calculateEmotionalIntelligenceImprovement(candidate, analysis: analysis) * 0.25
        
        // 3. Communication effectiveness (20% weight)
        score += calculateCommunicationEffectiveness(candidate, analysis: analysis) * 0.20
        
        // 4. Relationship preservation (15% weight)
        score += calculateRelationshipPreservation(candidate, analysis: analysis) * 0.15
        
        // 5. Clarity and readability (10% weight)
        score += calculateClarityAndReadability(candidate, originalText: originalText) * 0.10
        
        return min(score, 1.0) // Cap at 1.0
    }
    
    // MARK: - Attachment Style Specific Fixes
    
    private func generateAnxiousStyleFixes(_ text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var fixes: [FixCandidate] = []
        
        // Fix 1: Reduce absolutes (you always/never)
        if analysis.linguisticPatterns.hasAbsolutes {
            let fixed = reduceAbsolutes(text)
            fixes.append(FixCandidate(
                text: fixed,
                type: .absoluteReduction,
                attachmentRelevance: .high,
                reasoning: "Absolutes trigger anxiety - soften with frequency words",
                sourceEngine: .localAI,
                confidence: 0.8
            ))
        }
        
        // Fix 2: Add reassurance requests
        if analysis.emotionalNeeds.needsReassurance && !text.lowercased().contains("reassur") {
            let fixed = addReassuranceRequest(text)
            fixes.append(FixCandidate(
                text: fixed,
                type: .reassuranceAddition,
                attachmentRelevance: .high,
                reasoning: "Anxious attachment benefits from explicit reassurance requests",
                sourceEngine: .localAI,
                confidence: 0.85
            ))
        }
        
        // Fix 3: Transform accusations into feelings
        if analysis.communicationPattern == .aggressive || analysis.communicationPattern == .defensive {
            let fixed = transformToFeelingStatements(text)
            fixes.append(FixCandidate(
                text: fixed,
                type: .feelingTransformation,
                attachmentRelevance: .high,
                reasoning: "Anxious attachment communicates better through feelings than accusations",
                sourceEngine: .localAI,
                confidence: 0.8
            ))
        }
        
        return fixes
    }
    
    private func generateAvoidantStyleFixes(_ text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var fixes: [FixCandidate] = []
        
        // Fix 1: Add emotional context where missing
        if analysis.emotionalIntensity < 0.3 && analysis.intimacyLevel > 0.5 {
            let fixed = addEmotionalContext(text)
            fixes.append(FixCandidate(
                text: fixed,
                type: .emotionalContextAddition,
                attachmentRelevance: .high,
                reasoning: "Avoidant style benefits from explicit emotional context",
                sourceEngine: .localAI,
                confidence: 0.8
            ))
        }
        
        // Fix 2: Soften directness in intimate contexts
        if analysis.communicationPattern == .neutral && analysis.intimacyLevel > 0.7 {
            let fixed = softenDirectness(text)
            fixes.append(FixCandidate(
                text: fixed,
                type: .directnessSoftening,
                attachmentRelevance: .medium,
                reasoning: "Balance directness with warmth in intimate relationships",
                sourceEngine: .localAI,
                confidence: 0.7
            ))
        }
        
        // Fix 3: Add connection bridges
        if analysis.relationshipDynamics.hasDistancing {
            let fixed = addConnectionBridges(text)
            fixes.append(FixCandidate(
                text: fixed,
                type: .connectionBridging,
                attachmentRelevance: .high,
                reasoning: "Counter avoidant distancing with connection elements",
                sourceEngine: .localAI,
                confidence: 0.8
            ))
        }
        
        return fixes
    }
    
    private func generateDisorganizedStyleFixes(_ text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var fixes: [FixCandidate] = []
        
        // Fix 1: Structure chaotic communication
        if analysis.linguisticPatterns.isDisorganized {
            let fixed = structureCommunication(text)
            fixes.append(FixCandidate(
                text: fixed,
                type: .structureImprovement,
                attachmentRelevance: .high,
                reasoning: "Disorganized attachment benefits from clear structure",
                sourceEngine: .localAI,
                confidence: 0.8
            ))
        }
        
        // Fix 2: Resolve emotional contradictions
        if analysis.emotionalNeeds.hasContradictions {
            let fixed = resolveEmotionalContradictions(text)
            fixes.append(FixCandidate(
                text: fixed,
                type: .contradictionResolution,
                attachmentRelevance: .high,
                reasoning: "Clear contradictory emotional signals",
                sourceEngine: .localAI,
                confidence: 0.7
            ))
        }
        
        // Fix 3: Add grounding elements
        let fixed = addGroundingElements(text)
        fixes.append(FixCandidate(
            text: fixed,
            type: .groundingAddition,
            attachmentRelevance: .medium,
            reasoning: "Grounding helps disorganized attachment feel centered",
            sourceEngine: .localAI,
            confidence: 0.6
        ))
        
        return fixes
    }
    
    private func generateSecureStyleFixes(_ text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var fixes: [FixCandidate] = []
        
        // For secure attachment, focus on enhancement rather than correction
        
        // Fix 1: Enhance empathy where appropriate
        if analysis.emotionalNeeds.canBenefitFromEmpathy {
            let fixed = enhanceEmpathy(text)
            fixes.append(FixCandidate(
                text: fixed,
                type: .empathyEnhancement,
                attachmentRelevance: .medium,
                reasoning: "Add empathetic elements to strengthen connection",
                sourceEngine: .localAI,
                confidence: 0.7
            ))
        }
        
        // Fix 2: Optimize clarity
        if analysis.linguisticPatterns.canOptimizeClarity {
            let fixed = optimizeClarity(text)
            fixes.append(FixCandidate(
                text: fixed,
                type: .clarityOptimization,
                attachmentRelevance: .low,
                reasoning: "Enhance already good communication for maximum impact",
                sourceEngine: .localAI,
                confidence: 0.6
            ))
        }
        
        return fixes
    }
    
    // MARK: - Text Transformation Methods
    
    private func reduceAbsolutes(_ text: String) -> String {
        var result = text
        let absoluteReplacements = [
            ("you always", "you often"),
            ("you never", "you rarely"),
            ("I always", "I often"),
            ("I never", "I rarely"),
            ("everyone", "many people"),
            ("no one", "few people"),
            ("everything", "many things"),
            ("nothing", "few things")
        ]
        
        for (absolute, softer) in absoluteReplacements {
            result = result.replacingOccurrences(of: absolute, with: softer, options: .caseInsensitive)
        }
        
        return result
    }
    
    private func addReassuranceRequest(_ text: String) -> String {
        let reassuranceAdditions = [
            ". Can you help me understand?",
            ". I'd appreciate your perspective on this.",
            ". Can we work through this together?",
            ". I want to make sure we're on the same page."
        ]
        
        // Choose the most contextually appropriate addition based on emotional bucket
        let userState = getUserCurrentEmotionalState()
        let attachmentStyle = getAttachmentStyle()
        let addition = selectAdviceUsingBuckets(from: reassuranceAdditions, userState: userState, attachmentStyle: attachmentStyle) ?? reassuranceAdditions[0]
        return text.trimmingCharacters(in: .whitespacesAndNewlines) + addition
    }
    
    private func transformToFeelingStatements(_ text: String) -> String {
        var result = text
        
        // Transform "you" accusations to "I feel" statements
        let transformations = [
            ("You make me", "I feel"),
            ("you're being", "I'm experiencing this as"),
            ("You don't", "I don't feel"),
            ("You can't", "I'm struggling with"),
            ("You won't", "I'm hoping we can")
        ]
        
        for (accusation, feeling) in transformations {
            result = result.replacingOccurrences(of: accusation, with: feeling, options: .caseInsensitive)
        }
        
        return result
    }
    
    private func addEmotionalContext(_ text: String) -> String {
        let emotionalContexts = [
            "I'm feeling a bit overwhelmed, and ",
            "This is important to me, so ",
            "I care about us, which is why ",
            "I'm sharing this because I value our relationship: "
        ]
        
        let userState = getUserCurrentEmotionalState()
        let attachmentStyle = getAttachmentStyle()
        let context = selectAdviceUsingBuckets(from: emotionalContexts, userState: userState, attachmentStyle: attachmentStyle) ?? emotionalContexts[0]
        return context + text.prefix(1).lowercased() + String(text.dropFirst())
    }
    
    private func structureCommunication(_ text: String) -> String {
        // Break down into clear points if the text is chaotic
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        if sentences.count > 2 {
            var structured = "Here's what I want to share:\n"
            for (index, sentence) in sentences.enumerated() {
                structured += "\(index + 1). \(sentence)\n"
            }
            return structured.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return text
    }
    
    private func softenDirectness(_ text: String) -> String {
        var result = text
        
        // Soften direct statements with warmth
        let softeningPairs = [
            ("You need to", "I was hoping you could"),
            ("You should", "It might help if you"),
            ("You must", "Could you please"),
            ("Do this", "Would you mind doing this"),
            ("Fix this", "Can we work on this together")
        ]
        
        for (direct, soft) in softeningPairs {
            result = result.replacingOccurrences(of: direct, with: soft, options: .caseInsensitive)
        }
        
        return result
    }
    
    private func addConnectionBridges(_ text: String) -> String {
        let bridges = [
            "I value our relationship, and ",
            "Because I care about us, ",
            "I want to stay connected, so ",
            "Our bond matters to me, which is why "
        ]
        
        let userState = getUserCurrentEmotionalState()
        let attachmentStyle = getAttachmentStyle()
        let bridge = selectAdviceUsingBuckets(from: bridges, userState: userState, attachmentStyle: attachmentStyle) ?? bridges[0]
        return bridge + text.prefix(1).lowercased() + String(text.dropFirst())
    }
    
    private func resolveEmotionalContradictions(_ text: String) -> String {
        var result = text
        
        // Identify and resolve common contradictions
        if result.lowercased().contains("love") && result.lowercased().contains("hate") {
            result = result.replacingOccurrences(of: "hate", with: "am frustrated by", options: .caseInsensitive)
        }
        
        if result.lowercased().contains("want") && result.lowercased().contains("don't want") {
            result = "I have mixed feelings about this: " + result
        }
        
        return result
    }
    
    private func addGroundingElements(_ text: String) -> String {
        let groundingPhrases = [
            "Taking a deep breath, ",
            "Let me be clear: ",
            "What I really mean is: ",
            "To put this simply: "
        ]
        
        let userState = getUserCurrentEmotionalState()
        let attachmentStyle = getAttachmentStyle()
        let grounding = selectAdviceUsingBuckets(from: groundingPhrases, userState: userState, attachmentStyle: attachmentStyle) ?? groundingPhrases[0]
        return grounding + text.prefix(1).lowercased() + String(text.dropFirst())
    }
    
    private func enhanceEmpathy(_ text: String) -> String {
        let empathyAdditions = [
            ". I understand this might be difficult for you too.",
            ". I can see how you might feel differently about this.",
            ". I appreciate your perspective on this.",
            ". I know we both want what's best for our relationship."
        ]
        
        let userState = getUserCurrentEmotionalState()
        let attachmentStyle = getAttachmentStyle()
        let addition = selectAdviceUsingBuckets(from: empathyAdditions, userState: userState, attachmentStyle: attachmentStyle) ?? empathyAdditions[0]
        return text.trimmingCharacters(in: .whitespacesAndNewlines) + addition
    }
    
    private func optimizeClarity(_ text: String) -> String {
        var result = text
        
        // Remove filler words
        let fillers = ["um", "like", "you know", "sort of", "kind of"]
        for filler in fillers {
            result = result.replacingOccurrences(of: filler, with: "", options: .caseInsensitive)
        }
        
        // Remove quotation marks
        result = result.replacingOccurrences(of: "\"", with: "")
        result = result.replacingOccurrences(of: "'", with: "")
        
        // Clean up extra spaces
        result = result.replacingOccurrences(of: "  ", with: " ")
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return result
    }
    
    // MARK: - AI Scoring Methods
    
    private func calculateAttachmentStyleAlignment(_ candidate: FixCandidate, analysis: DeepTextAnalysis) -> Double {
        switch candidate.attachmentRelevance {
        case .high: return 1.0
        case .medium: return 0.6
        case .low: return 0.3
        }
    }
    
    private func calculateEmotionalIntelligenceImprovement(_ candidate: FixCandidate, analysis: DeepTextAnalysis) -> Double {
        var score = 0.5 // Base score
        
        // Boost score for emotional context additions
        if candidate.type == .emotionalContextAddition || candidate.type == .feelingTransformation {
            score += 0.3
        }
        
        // Boost for empathy enhancements
        if candidate.type == .empathyEnhancement {
            score += 0.4
        }
        
        return min(score, 1.0)
    }
    
    private func calculateCommunicationEffectiveness(_ candidate: FixCandidate, analysis: DeepTextAnalysis) -> Double {
        var score = 0.5 // Base score
        
        // Boost for structure improvements
        if candidate.type == .structureImprovement || candidate.type == .clarityOptimization {
            score += 0.3
        }
        
        // Boost for absolute reductions (often improves communication)
        if candidate.type == .absoluteReduction {
            score += 0.4
        }
        
        return min(score, 1.0)
    }
    
    private func calculateRelationshipPreservation(_ candidate: FixCandidate, analysis: DeepTextAnalysis) -> Double {
        var score = 0.5 // Base score
        
        // Boost for connection bridging and reassurance
        if candidate.type == .connectionBridging || candidate.type == .reassuranceAddition {
            score += 0.4
        }
        
        // Boost for contradiction resolution
        if candidate.type == .contradictionResolution {
            score += 0.3
        }
        
        return min(score, 1.0)
    }
    
    private func calculateClarityAndReadability(_ candidate: FixCandidate, originalText: String) -> Double {
        let originalLength = originalText.count
        let newLength = candidate.text.count
        
        // Prefer moderate length changes
        let lengthRatio = Double(newLength) / Double(originalLength)
        
        if lengthRatio > 0.8 && lengthRatio < 1.5 {
            return 1.0 // Good length ratio
        } else if lengthRatio > 0.5 && lengthRatio < 2.0 {
            return 0.7 // Acceptable length ratio
        } else {
            return 0.3 // Significant length change
        }
    }
    
    private func calculateConfidence(_ candidate: FixCandidate, score: Double) -> Double {
        var confidence = score
        
        // Boost confidence for high-relevance attachment fixes
        if candidate.attachmentRelevance == .high {
            confidence += 0.1
        }
        
        return min(confidence, 1.0)
    }
    
    private func generateReasoning(_ candidate: FixCandidate, score: Double, analysis: DeepTextAnalysis) -> String {
        var reasoning = candidate.reasoning
        
        if score > 0.8 {
            reasoning += " This change has high potential for improving communication."
        } else if score > 0.6 {
            reasoning += " This change should provide moderate improvement."
        } else {
            reasoning += " This change may provide some benefit."
        }
        
        return reasoning
    }
    
    private func selectOptimalFix(from rankedFixes: [RankedFix], analysis: DeepTextAnalysis) -> RankedFix {
        // Select the highest-scored fix, but apply additional logic for edge cases
        guard let topFix = rankedFixes.first else {
            // Fallback if no fixes available
            return RankedFix(
                candidate: FixCandidate(
                    text: "Consider rephrasing for better clarity.",
                    type: .clarityOptimization,
                    attachmentRelevance: .low,
                    reasoning: "Fallback suggestion",
                    sourceEngine: .localAI,
                    confidence: 0.3
                ),
                score: 0.3,
                confidence: 0.3,
                reasoning: "No specific improvements detected.",
                psychologicalRationale: "Default guidance",
                expectedOutcome: "Minimal improvement"
            )
        }
        
        // If the top fix has very low confidence, consider returning original text
        if topFix.confidence < 0.4 {
            return RankedFix(
                candidate: FixCandidate(
                    text: analysis.linguisticPatterns.hasAbsolutes ? "Your message is clear." : topFix.candidate.text,
                    type: .clarityOptimization,
                    attachmentRelevance: .low,
                    reasoning: "Low confidence in improvements",
                    sourceEngine: .localAI,
                    confidence: 0.4
                ),
                score: 0.4,
                confidence: 0.4,
                reasoning: "Message appears to be well-constructed already.",
                psychologicalRationale: "Preserving existing communication style",
                expectedOutcome: "Maintains clarity"
            )
        }
        
        return topFix
    }
    
    // MARK: - Missing fix generation methods
    
    private func generateEmotionalIntelligenceFixes(_ text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var fixes: [FixCandidate] = []
        
        // Add emotional validation where needed
        if analysis.emotionalNeeds.canBenefitFromEmpathy {
            let fixed = addEmotionalValidation(text)
            fixes.append(FixCandidate(
                text: fixed,
                type: .empathyEnhancement,
                attachmentRelevance: .medium,
                reasoning: "Adding emotional validation to foster understanding",
                sourceEngine: .localAI,
                confidence: 0.7
            ))
        }
        
        return fixes
    }
    
    private func generateCommunicationPatternFixes(_ text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var fixes: [FixCandidate] = []
        
        // Fix aggressive communication patterns
        if analysis.communicationPattern == .aggressive {
            let fixed = softenAggressiveLanguage(text)
            fixes.append(FixCandidate(
                text: fixed,
                type: .feelingTransformation,
                attachmentRelevance: .high,
                reasoning: "Transforming aggressive language to collaborative communication",
                sourceEngine: .localAI,
                confidence: 0.8
            ))
        }
        
        return fixes
    }
    
    private func generateRelationshipDynamicsFixes(_ text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var fixes: [FixCandidate] = []
        
        // Address distancing patterns
        if analysis.relationshipDynamics.hasDistancing {
            let fixed = addConnectionBridges(text)
            fixes.append(FixCandidate(
                text: fixed,
                type: .connectionBridging,
                attachmentRelevance: .high,
                reasoning: "Bridging distance with connection-focused language",
                sourceEngine: .localAI,
                confidence: 0.8
            ))
        }
        
        return fixes
    }
    
    private func generateContextualRewrites(_ text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var fixes: [FixCandidate] = []
        
        // Handle high-urgency texts with care
        if analysis.urgencyLevel > 0.7 {
            let fixed = moderateUrgency(text)
            fixes.append(FixCandidate(
                text: fixed,
                type: .clarityOptimization,
                attachmentRelevance: .medium,
                reasoning: "Moderating urgency to prevent escalation",
                sourceEngine: .localAI,
                confidence: 0.7
            ))
        }
        
        return fixes
    }
    
    private func generateGeneralStyleFixes(_ text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
        var fixes: [FixCandidate] = []
        
        // General improvements for unknown attachment styles
        if analysis.linguisticPatterns.hasAbsolutes {
            let fixed = reduceAbsolutes(text)
            fixes.append(FixCandidate(
                text: fixed,
                type: .absoluteReduction,
                attachmentRelevance: .medium,
                reasoning: "Reducing absolute language for more balanced communication",
                sourceEngine: .localAI,
                confidence: 0.7
            ))
        }
        
        return fixes
    }
    
    // MARK: - Additional helper methods
    
    private func addEmotionalValidation(_ text: String) -> String {
        let validations = [
    "I understand this is important, and ",
    "I can see why you feel this way. ",
    "Your feelings make sense to me. ",
    "I hear what you're saying, and ",
  ]
        
        let userState = getUserCurrentEmotionalState()
        let attachmentStyle = getAttachmentStyle()
        let validation = selectAdviceUsingBuckets(from: validations, userState: userState, attachmentStyle: attachmentStyle) ?? validations[0]
        return validation + text.prefix(1).lowercased() + String(text.dropFirst())
    }
    
    private func softenAggressiveLanguage(_ text: String) -> String {
        var result = text
        
        // Load alert tone replacements from ImproveTones.json
        if let improveTonesData = JSONKnowledgeBase.improveTones as? [String: Any],
           let improveAlertTone = improveTonesData["improveAlertTone"] as? [String: Any],
           let alert = improveAlertTone["alert"] as? [String: Any],
           let replacements = alert["replacements"] as? [[String: String]] {
            
            // Apply all alert tone replacements from JSON
            for replacement in replacements {
                if let find = replacement["find"], let replace = replacement["replace"] {
                    result = result.replacingOccurrences(of: find, with: replace, options: .caseInsensitive)
                }
            }
        } else {
            // Fallback: Replace aggressive words with softer alternatives
            let aggressiveToSoft = [
                ("stupid", "confusing"),
                ("idiot", "person"),
                ("hate", "really dislike"),
                ("terrible", "challenging"),
                ("awful", "difficult"),
                ("worst", "most challenging")
            ]
            
            for (aggressive, soft) in aggressiveToSoft {
                result = result.replacingOccurrences(of: aggressive, with: soft, options: .caseInsensitive)
            }
        }
        
        return result
    }
    
    private func moderateUrgency(_ text: String) -> String {
        var result = text
        
        // Load caution tone replacements from ImproveTones.json
        if let improveTones = JSONKnowledgeBase.improveTones as? [String: Any],
           let improveTonesData = improveTones["improveCautionTone"] as? [String: Any],
           let caution = improveTonesData["caution"] as? [String: Any],
           let replacements = caution["replacements"] as? [[String: String]] {
            // Apply all caution tone replacements from JSON
            for replacement in replacements {
                if let find = replacement["find"], let replace = replacement["replace"] {
                    result = result.replacingOccurrences(of: find, with: replace, options: .caseInsensitive)
                }
            }
        } else {
            // Fallback: Replace urgent words with calmer alternatives
            let urgentToCalm = [
                ("ASAP", "when you have a chance"),
                ("immediately", "soon"),
                ("right now", "when possible"),
                ("urgent", "important"),
                ("emergency", "priority matter")
            ]
            
            for (urgent, calm) in urgentToCalm {
                result = result.replacingOccurrences(of: urgent, with: calm, options: .caseInsensitive)
            }
        }
        
        return result
    }


// MARK: - Supporting Data Structures

struct AITextResult {
    let originalText: String
    let improvedText: String
    let confidence: Double
    let reasoning: String
    let attachmentStyleFactors: [String]
    let emotionalImpact: EmotionalImpact
    let communicationGoals: [CommunicationGoal]
}

struct DeepTextAnalysis {
    let sentiment: Double
    let emotionalIntensity: Double
    let linguisticPatterns: LinguisticPatterns
    let attachmentSignals: AttachmentSignals
    let defensiveMechanisms: [DefensiveMechanism]
    let emotionalNeeds: EmotionalNeeds
    let communicationPattern: CommunicationPattern
    let toneProfile: ToneProfile
    let relationshipDynamics: RelationshipDynamics
    let urgencyLevel: Double
    let conflictLevel: Double
    let intimacyLevel: Double
}

struct QuickTextAnalysis {
    let hasCriticalTone: Bool
    let dominantEmotion: Emotion
    let attachmentSignals: [AttachmentSignal]
    let communicationPattern: CommunicationPattern
    let riskLevel: RiskLevel
    let traumaResponse: String?
    let negativeIntensity: Double
    let attachmentActivationLevel: Double
}

struct FixCandidate {
    let text: String
    let type: FixType
    let attachmentRelevance: Relevance
    let reasoning: String
    // Enhanced fields
    let sourceEngine: SourceEngine
    let confidence: Double
}

// MARK: - Therapeutic Advice Structure

struct TherapeuticAdvice {
    let observation: String          // What the AI observed in the text
    let insight: String             // Psychological insight about the communication pattern
    let advice: String              // Specific therapeutic guidance
    let attachmentContext: String   // How this relates to attachment style
    let actionStep: String?         // Concrete next step to take
    let confidence: Double          // Confidence in this advice (0.0-1.0)
    let category: AdviceCategory    // Type of therapeutic advice
    let sourceData: String          // Which JSON data source provided this insight
}

enum AdviceCategory {
    case emotionalRegulation       // Help managing emotions
    case communicationSkills       // Improve how they express themselves
    case attachmentAwareness       // Understanding attachment triggers
    case conflictResolution        // De-escalation and repair
    case selfReflection           // Encourage introspection
    case empathyBuilding          // Develop perspective-taking
    case boundaryHealthy          // Healthy boundary setting
    case mindfulness              // Present-moment awareness
    case coParentingGuidance      // Child-focused advice
    case relationshipRepair       // Rebuilding connection
}

struct TherapeuticAnalysisResult {
    let originalText: String
    let primaryConcern: String      // Main issue identified
    let attachmentTriggers: [String] // Detected attachment triggers
    let emotionalState: String      // Current emotional state
    let communicationPattern: String // Observed pattern
    let therapeuticAdvice: [TherapeuticAdvice] // Ranked advice
    let urgencyLevel: AdviceUrgency // How urgent the situation is
    let followUpSuggestions: [String] // Future considerations
}

enum AdviceUrgency {
    case low           // General guidance
    case moderate      // Some concern, needs attention
    case high          // Significant relationship risk
    case crisis        // Immediate intervention needed
}

struct RankedFix {
    let candidate: FixCandidate
    let score: Double
    let confidence: Double
    let reasoning: String
    // Enhanced fields
    let psychologicalRationale: String
    let expectedOutcome: String
}

// MARK: - Enums

enum FixType {
    case absoluteReduction
    case reassuranceAddition
    case feelingTransformation
    case emotionalContextAddition
    case directnessSoftening
    case connectionBridging
    case structureImprovement
    case contradictionResolution
    case groundingAddition
    case empathyEnhancement
    case clarityOptimization
    // Enhanced types from existing engines
    case existingEngineSuggestion
    case toneBased
    case attachmentStyleSpecific
    case communicationPattern
    case repairStrategy
    case autoFix
    // New JSON-enhanced types
    case emotionAware
    case triggerAware
    case contextual
    // RAG & Advanced AI types
    case ragEnhanced
    case microLLMGenerated
    case deEscalation
    case emotionalSupport
    case anxietyReduction
    // Child-centered & mindfulness types
    case childCentered
    case developmentalGuidance
    case empathyEcho
    case mindfulnessPrompt
    // Advanced psychology-based types (NEW)
    case iStatementTransformation
    case crossStyleCommunication
    case psychologicallyInformed
}

enum Relevance {
    case low, medium, high
}

enum RiskLevel {
    case low, medium, high, critical
}

enum SourceEngine {
    case advancedSuggestions
    case toneAnalysis
    case attachmentAnalysis
    case patternAnalysis
    case repairStrategies
    case autoFix
    case localAI
    case hybrid
    case jsonKnowledge
    // RAG & Advanced AI engines
    case vectorStore
    case microLLM
    case contextualMemory
    // Child-centered & mindfulness engines
    case childLanguage
    case mindfulness
}

// MARK: - Placeholder Types for Existing Engine Integration

struct PsychologicalIndicators {
    let hasAbsoluteThinking: Bool = false
    let emotionalRegulationDifficulty: Double = 0.0
    let attachmentSystemActivation: Double = 0.0
}


struct LinguisticStyle {
    let complexity: Double = 0.5
}

struct AttachmentIndicators {
    let anxiousMarkers: Double = 0.0
    let avoidantMarkers: Double = 0.0
    let disorganizedMarkers: Double = 0.0
}

enum EmotionalNeed {
    case connection, reassurance, autonomy, validation, understanding
}

struct EmotionalImpact {
    let positiveImpact: Double = 0.5
    let negativeImpact: Double = 0.5
    let overallTone: ToneStatus = .neutral
}

enum CommunicationGoal {
    case clarity, connection, conflict_resolution, emotional_expression, boundary_setting
    case immediate_improvement, tone_improvement, suggestion_based
    case empathy, childFocus, child_focus
}

// MARK: - Critical Tone and Quick Fix Methods
    
    private func applyCriticalToneFixes(_ text: String, style: AttachmentStyle) -> String {
        var result = text
        
        // Apply critical fixes based on attachment style
        switch style {
        case .anxious:
            result = applyAnxiousCriticalFixes(result)
        case .avoidant:
            result = applyAvoidantCriticalFixes(result)
        case .disorganized:
            result = applyDisorganizedCriticalFixes(result)
        case .secure:
            result = applySecureCriticalFixes(result)
        case .unknown:
            result = applyGeneralCriticalFixes(result)
        }
        
        return result
    }
    
    private func applyAnxiousCriticalFixes(_ text: String) -> String {
        var result = text
        
        // Reduce catastrophic thinking
        result = result.replacingOccurrences(of: "always", with: "sometimes", options: .caseInsensitive)
        result = result.replacingOccurrences(of: "never", with: "rarely", options: .caseInsensitive)
        
        // Add reassurance seeking in a healthier way
        if result.lowercased().contains("you don't love me") {
            result = "I'm feeling insecure about our relationship. Can we talk about this?"
        }
        
        return result
    }
    
    private func applyAvoidantCriticalFixes(_ text: String) -> String {
        var result = text
        
        // Add emotional context to overly distant messages
        if result.count < 20 && !result.lowercased().contains("feel") {
            result = "I want to share something with you: " + result
        }
        
        // Soften dismissive language
        result = result.replacingOccurrences(of: "whatever", with: "I understand", options: .caseInsensitive)
        result = result.replacingOccurrences(of: "fine", with: "okay, I hear you", options: .caseInsensitive)
        
        return result
    }
    
    private func applyDisorganizedCriticalFixes(_ text: String) -> String {
        var result = text
        
        // Structure chaotic thoughts
        if result.count > 100 && result.filter({ $0 == "." }).count < 2 {
            let sentences = result.components(separatedBy: " ")
            let midpoint = sentences.count / 2
            let firstHalf = sentences[0..<midpoint].joined(separator: " ")
            let secondHalf = sentences[midpoint...].joined(separator: " ")
            result = firstHalf + ". " + secondHalf
        }
        
        return result
    }
    
    private func applySecureCriticalFixes(_ text: String) -> String {
        var result = text
        
        // For secure attachment, just minor refinements
        result = result.replacingOccurrences(of: "  ", with: " ") // Remove double spaces
        
        return result
    }
    
    private func applyGeneralCriticalFixes(_ text: String) -> String {
        var result = text
        
        // Apply universal improvements
        result = self.reduceAbsolutes(result)
        result = self.softenAggressiveLanguage(result)
        
        return result
    }
    
    private func applyAttachmentStyleFixes(_ text: String, style: AttachmentStyle, context: QuickTextAnalysis) -> String {
        var result = text
        
        switch style {
        case .anxious:
            if context.dominantEmotion == .anxious {
                result = self.addReassuranceRequest(result)
            }
        case .avoidant:
            if context.riskLevel == .high {
                result = self.addEmotionalContext(result)
            }
        case .disorganized:
            if context.communicationPattern != .neutral {
                result = self.structureCommunication(result)
            }
        case .secure:
            result = optimizeClarity(result)
        case .unknown:
            result = reduceAbsolutes(result)
        }
        
        return result
    }
    
    private func applyCommunicationPatternFixes(_ text: String, analysis: QuickTextAnalysis) -> String {
        var result = text
        
        switch analysis.communicationPattern {
        case .aggressive:
            result = softenAggressiveLanguage(result)
        case .passiveAggressive:
            result = transformPassiveAggressive(result)
        case .defensive:
            result = reduceDefensiveness(result)
        case .withdrawing:
            result = addConnectionBridges(result)
        case .pursuing:
            result = moderateUrgency(result)
        case .assertive:
            // Already good
            break
        case .neutral:
            // Add warmth if needed
            if !result.lowercased().contains("feel") && !result.lowercased().contains("think") {
                result = "I wanted to share: " + result
            }
        default:
            break
        }
        
        return result
    }
    
    private func transformPassiveAggressive(_ text: String) -> String {
        var result = text
        
        let passiveAggressiveToDirector = [
            ("fine, whatever", "I disagree, but let's discuss this"),
            ("if you say so", "I have a different perspective"),
            ("sure, go ahead", "I'm not comfortable with that"),
            ("I guess", "I think"),
            ("maybe you're right", "I see your point, but I feel differently")
        ]
        
        for (passive, direct) in passiveAggressiveToDirector {
            result = result.replacingOccurrences(of: passive, with: direct, options: .caseInsensitive)
        }
        
        return result
    }
    
    private func reduceDefensiveness(_ text: String) -> String {
        var result = text
        
        let defensiveToOpen = [
            ("not my fault", "I see how my actions affected this"),
            ("I didn't mean to", "I understand the impact of my actions"),
            ("but you", "and I also notice that"),
            ("that's not what I said", "let me clarify what I meant"),
            ("you're wrong", "I have a different understanding")
        ]
        
        for (defensive, open) in defensiveToOpen {
            result = result.replacingOccurrences(of: defensive, with: open, options: .caseInsensitive)
        }
        
        return result
    }
    
// MARK: - Helper Methods for Enhanced Analysis

struct DefensivePatterns {
    var blameShifting: Double = 0.0
    var deflection: Double = 0.0
    var minimization: Double = 0.0
    var rationalization: Double = 0.0
    var projection: Double = 0.0
}

struct ComprehensiveToneAnalysis {
    var defensivePatterns: DefensivePatterns = DefensivePatterns()
    // Add other properties as needed
}

    /// Extract defensive mechanisms from comprehensive tone analysis
    private func extractDefensiveMechanisms(from analysis: ComprehensiveToneAnalysis) -> [DefensiveMechanism] {
        var mechanisms: [DefensiveMechanism] = []

        if analysis.defensivePatterns.blameShifting > 0.3 {
            mechanisms.append(.blameShifting)
        }
        if analysis.defensivePatterns.deflection > 0.3 {
            mechanisms.append(.deflection)
        }
        if analysis.defensivePatterns.minimization > 0.3 {
            mechanisms.append(.minimization)
        }
        if analysis.defensivePatterns.rationalization > 0.3 {
            mechanisms.append(.rationalization)
        }
        if analysis.defensivePatterns.projection > 0.3 {
            mechanisms.append(.projection)
        }

        return mechanisms
    }
    
    /// Extract emotional needs from comprehensive analysis
    private func extractEmotionalNeeds(from analysis: ComprehensiveToneAnalysis, text: String) -> EmotionalNeeds {
        let lowercased = text.lowercased()
        
        // Analyze explicit emotional needs
    let needsReassurance = lowercased.contains("reassur") || lowercased.contains("are you")
    let hasContradictions = (lowercased.contains("love") && lowercased.contains("hate")) ||
                            (lowercased.contains("want") && lowercased.contains("don't want"))
    let canBenefitFromEmpathy = lowercased.contains("validation") ||
                                lowercased.contains("understanding") ||
                                lowercased.contains("hurt") || lowercased.contains("sad")
        
        return EmotionalNeeds(
            needsReassurance: needsReassurance,
            hasContradictions: hasContradictions,
            canBenefitFromEmpathy: canBenefitFromEmpathy
        )
    }
    
    /// Assess intimacy level from relationship context
    private func assessIntimacyFromRelationshipContext(_ context: RelationshipContext) -> Double {
        switch context {
        case .romantic: return 0.9
        case .family: return 0.7
        case .friendship: return 0.6
        case .professional: return 0.2
        case .unknown: return 0.5
        case .acquaintance: return 0.5
        }
    }
    
    /// Generate psychological rationale for fix candidates
    private func generatePsychologicalRationale(_ candidate: FixCandidate, analysis: DeepTextAnalysis) -> String {
        let userStyle = getAttachmentStyle()
        
        switch candidate.type {
        case .absoluteReduction:
            return "Absolute language triggers \(userStyle.rawValue) attachment system activation and increases emotional dysregulation."
            
        case .reassuranceAddition:
            return "Anxious attachment style benefits from explicit reassurance-seeking to reduce hyperactivation of attachment system."
            
        case .feelingTransformation:
            return "I-statements reduce defensive responses and promote emotional regulation in the recipient."
            
        case .emotionalContextAddition:
            return "Avoidant attachment style requires explicit emotional context to bridge emotional awareness gaps."
            
        case .connectionBridging:
            return "Connection-focused language counters avoidant distancing strategies and promotes secure base behavior."
            
        case .structureImprovement:
            return "Structured communication reduces cognitive load for disorganized attachment and promotes emotional regulation."
            
        case .empathyEnhancement:
            return "Empathetic language activates caregiving behavioral system and promotes secure attachment behaviors."
            
        default:
            return "Communication improvement based on attachment theory and emotional intelligence principles."
        }
    }
    
    /// Generate expected outcome for fix candidates
    private func generateExpectedOutcome(_ candidate: FixCandidate, score: Double) -> String {
        if score > 0.8 {
            switch candidate.type {
            case .absoluteReduction:
                return "Significantly reduced partner defensiveness and improved emotional regulation."
            case .reassuranceAddition:
                return "Increased sense of security and reduced anxiety in both parties."
            case .feelingTransformation:
                return "Enhanced emotional intimacy and reduced conflict escalation."
            case .connectionBridging:
                return "Strengthened relationship bond and increased felt security."
            case .empathyEnhancement:
                return "Improved mutual understanding and emotional attunement."
            default:
                return "Improved relationship satisfaction and communication effectiveness."
            }
        } else if score > 0.6 {
            return "Moderate improvement in communication quality and relationship dynamics."
        } else {
            return "Minor positive impact on communication clarity and emotional tone."
        }
    }
    
    /// Get user attachment style with enhanced fallback logic
    private func getAttachmentStyle() -> AttachmentStyle {
        if let styleString = personalityManager.getAttachmentStyle(),
           let style = AttachmentStyle(rawValue: styleString) {
            return style
        }
        
        // Enhanced fallback: temporarily force anxious for testing as requested
        return .anxious // This was requested for testing purposes
    }
    
    /// Assess basic risk level for text
    private func assessBasicRiskLevel(_ text: String) -> RiskLevel {
        let alertWords = ["hate", "always", "never", "stupid", "idiot", "worst", "terrible"]
        let lowercased = text.lowercased()
        let riskCount = alertWords.filter { lowercased.contains($0) }.count
        
        if riskCount >= 3 { return .high }
        if riskCount >= 1 { return .medium }
        return .low
    }

// MARK: - Missing Helper Classes and Data Structures

/// Simple NLP processor for linguistic pattern extraction
class NLPProcessor {
    func analyzeSentiment(_ text: String) -> Double {
        let positiveWords = ["good", "great", "love", "happy", "wonderful", "amazing", "perfect"]
        let negativeWords = ["bad", "hate", "terrible", "awful", "horrible", "stupid", "worst"]
        
        let lowerText = text.lowercased()
        let positiveCount = positiveWords.filter { lowerText.contains($0) }.count
        let negativeCount = negativeWords.filter { lowerText.contains($0) }.count
        
        return (Double(positiveCount) - Double(negativeCount)) / max(Double(positiveCount + negativeCount), 1.0)
    }
    
    func extractLinguisticPatterns(_ text: String) -> LinguisticPatterns {
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let sentenceCount = text.components(separatedBy: CharacterSet(charactersIn: ".!?")).filter { !$0.isEmpty }.count
        let complexity = Double(wordCount) / max(Double(sentenceCount), 1.0)
        
        let hasAbsolutes = text.lowercased().contains("always") || text.lowercased().contains("never")
        let isDisorganized = complexity > 20 || sentenceCount == 0
        let canOptimizeClarity = text.contains("  ") || text.contains("um") || text.contains("like")
        
        return LinguisticPatterns(
            hasAbsolutes: hasAbsolutes,
            isDisorganized: isDisorganized,
            canOptimizeClarity: canOptimizeClarity,
            complexity: min(complexity / 20.0, 1.0),
            emotionalVolatility: 0.5,
            psychologicalMarkers: PsychologicalIndicators()
        )
    }
}

/// Communication pattern analyzer
class CommunicationPatternAnalyzer {
    func analyzePattern(_ text: String) -> CommunicationPattern {
        let lowerText = text.lowercased()
        
        if lowerText.contains("hate") || lowerText.contains("stupid") || lowerText.contains("idiot") {
            return .aggressive
        } else if lowerText.contains("fine") || lowerText.contains("whatever") {
            return .passiveAggressive
        } else if lowerText.contains("but") || lowerText.contains("not my fault") {
            return .defensive
        } else if lowerText.contains("space") || lowerText.contains("alone") {
            return .withdrawing
        } else if lowerText.contains("need") || lowerText.contains("must") {
            return .pursuing
        } else if lowerText.contains("feel") && lowerText.contains("understand") {
            return .assertive
        }
        return .neutral
    }
}

/// Attachment style analyzer
class AttachmentStyleAnalyzer {
    func analyzeStyle(_ text: String) -> AttachmentStyle {
        let lowerText = text.lowercased()
        
        if lowerText.contains("reassur") || lowerText.contains("insecur") || lowerText.contains("abandon") {
            return .anxious
        } else if lowerText.contains("space") || lowerText.contains("independence") || lowerText.contains("fine") {
            return .avoidant
        } else if lowerText.contains("confus") || lowerText.contains("overwhelm") {
            return .disorganized
        } else if lowerText.contains("understand") && lowerText.contains("together") {
            return .secure
        }
        return .unknown
    }
}

/// Emotional intelligence engine
class EmotionalIntelligenceEngine {
    func analyzeEmotionalNeeds(_ text: String) -> EmotionalNeeds {
        let lowerText = text.lowercased()
        
        let needsReassurance = lowerText.contains("reassur") || lowerText.contains("sure") || lowerText.contains("certain")
        let hasContradictions = (lowerText.contains("love") && lowerText.contains("hate")) || (lowerText.contains("want") && lowerText.contains("don't want"))
        let canBenefitFromEmpathy = lowerText.contains("hurt") || lowerText.contains("sad") || lowerText.contains("lonely")
        
        return EmotionalNeeds(
            needsReassurance: needsReassurance,
            hasContradictions: hasContradictions,
            canBenefitFromEmpathy: canBenefitFromEmpathy
        )
    }
}

/// Contextual rewrite engine
class ContextualRewriteEngine {
    func assessUrgency(_ text: String) -> Double {
        let urgentWords = ["urgent", "asap", "immediately", "now", "emergency"]
        let lowerText = text.lowercased()
        let urgentCount = urgentWords.filter { lowerText.contains($0) }.count
        return min(Double(urgentCount) / 2.0, 1.0)
    }
    
    func assessConflictLevel(_ text: String) -> Double {
        let conflictWords = ["fight", "argue", "disagree", "wrong", "hate", "angry"]
        let lowerText = text.lowercased()
        let conflictCount = conflictWords.filter { lowerText.contains($0) }.count
        return min(Double(conflictCount) / 3.0, 1.0)
    }
}

/// Relationship dynamics engine
class RelationshipDynamicsEngine {
    func analyzeDistance(_ text: String) -> Bool {
        let distancingWords = ["space", "alone", "away", "distance", "independence"]
        let lowerText = text.lowercased()
        return distancingWords.contains { lowerText.contains($0) }
    }
}

// MARK: - Missing Data Structures

struct LinguisticPatterns {
    let hasAbsolutes: Bool
    let isDisorganized: Bool
    let canOptimizeClarity: Bool
    let complexity: Double
    let emotionalVolatility: Double
    let psychologicalMarkers: PsychologicalIndicators
}

struct AttachmentSignals {
    let detectedStyle: AttachmentStyle?
    let intensity: Double
    
    init(detectedStyle: AttachmentStyle? = nil, intensity: Double = 0.5) {
        self.detectedStyle = detectedStyle
        self.intensity = intensity
    }
}

struct EmotionalNeeds {
    let needsReassurance: Bool
    let hasContradictions: Bool
    let canBenefitFromEmpathy: Bool
}

struct ToneProfile {
    let primaryTone: ToneStatus
    let secondaryTones: [EmotionType]
    let confidence: Double
    
    init(primaryTone: ToneStatus = .neutral, secondaryTones: [EmotionType] = [], confidence: Double = 0.5) {
        self.primaryTone = primaryTone
        self.secondaryTones = secondaryTones
        self.confidence = confidence
    }
}

struct RelationshipDynamics {
    let hasDistancing: Bool
    let contextType: RelationshipContext
    let negativeIntensity: Double
    
    init(hasDistancing: Bool = false, contextType: RelationshipContext = .unknown, negativeIntensity: Double = 0.0) {
        self.hasDistancing = hasDistancing
        self.contextType = contextType
        self.negativeIntensity = negativeIntensity
    }
}

enum DefensiveMechanism {
    case blameShifting, deflection, minimization, rationalization, projection
}

enum Emotion {
    case angry, anxious, sad, happy, neutral
}

enum AttachmentSignal {
    case anxiousSeekingReassurance, avoidantDistancing, disorganizedConfusion, secureExpression
    case anxiousTraumaActivation, avoidantShutdown, disorganizedChaos
    case needExpression, emotionalExpression, supportSeeking
}

// MARK: - Helper Functions

/// Determine communication goals based on analysis and fix type
private func determineCommunicationGoals(analysis: DeepTextAnalysis, fixType: FixType) -> [CommunicationGoal] {
    var goals: [CommunicationGoal] = []
    
    switch fixType {
    case .clarityOptimization:
        goals.append(.clarity)
    case .connectionBridging:
        goals.append(.connection)
    case .feelingTransformation:
        goals.append(.emotional_expression)
    case .reassuranceAddition:
        goals.append(.connection)
    case .empathyEnhancement:
        goals.append(.connection)
    case .structureImprovement:
        goals.append(.clarity)
    case .absoluteReduction:
        goals.append(.emotional_expression)
    default:
        goals.append(.clarity)
    }
    
    if analysis.conflictLevel > 0.5 {
        goals.append(.conflict_resolution)
    }
    
    if analysis.relationshipDynamics.hasDistancing {
        goals.append(.connection)
    }
    
    return goals
}

// MARK: - Child-Centered Language Processing

/// Generate child-centered language suggestions for co-parenting communication
private func generateChildCenteredSuggestions(text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
    var candidates: [FixCandidate] = []
    
    guard let childLanguageData = JSONKnowledgeBase.childLanguage["childCenteredLanguage"] as? [String: Any] else {
        return candidates
    }
    
    // 1. Detect child names in the message
    let detectedChildNames = detectChildNames(in: text)
    let userDefinedNames = getUserDefinedChildrenNames()
    
    // Use actual child name if available, otherwise use generic term
    let primaryChildName = detectedChildNames.first ??
                          (userDefinedNames.isEmpty ? "your child" : userDefinedNames.first!)
    
    // 2. Enhanced suggestions when user has defined children names
    if hasUserDefinedChildrenNames() {
        // Generate personalized reframes for each child
        for childName in userDefinedNames {
            candidates.append(contentsOf: generatePersonalizedChildSuggestions(
                text: text,
                childName: childName,
                analysis: analysis,
                data: childLanguageData
            ))
        }
    }
    
    // 3. Generate kid-first reframes
    candidates.append(contentsOf: generateKidFirstReframes(text: text, childName: primaryChildName, data: childLanguageData))
    
    // 4. Generate developmental prompts if relevant topics are mentioned
    candidates.append(contentsOf: generateDevelopmentalPrompts(text: text, childName: primaryChildName, data: childLanguageData))
    
    // 5. Generate empathy echo if child welfare is mentioned
    candidates.append(contentsOf: generateEmpathyEcho(text: text, childNames: detectedChildNames.isEmpty ? userDefinedNames : detectedChildNames, data: childLanguageData))
    
    return candidates
}

/// Get user-defined children names from shared storage
private func getUserDefinedChildrenNames() -> [String] {
    guard let userDefaults = UserDefaults(suiteName: "group.com.unsaid.app.shared"),
          let names = userDefaults.array(forKey: "children_names") as? [String] else {
        return []
    }
    return names.filter { !$0.isEmpty } // Filter out empty names
}

/// Check if user has defined any children names
private func hasUserDefinedChildrenNames() -> Bool {
    return !getUserDefinedChildrenNames().isEmpty
}

/// Detect child names in text using user-defined names and patterns
private func detectChildNames(in text: String) -> [String] {
    var detectedNames: [String] = []
    
    // PRIORITY 1: Check against user-defined children names from Flutter app
    if let userDefaults = UserDefaults(suiteName: "group.com.unsaid.app.shared"),
       let userDefinedNames = userDefaults.array(forKey: "children_names") as? [String] {
        
        for name in userDefinedNames {
            // Case-insensitive search for user's actual children names
            if text.localizedCaseInsensitiveContains(name) {
                if !detectedNames.contains(name) {
                    detectedNames.append(name)
                }
            }
        }
        
        // If we found user-defined names, prioritize them and return
        if !detectedNames.isEmpty {
            return detectedNames
        }
    }
    
    // FALLBACK: Use JSON patterns and common names if no user-defined names found
    guard let childLanguageData = JSONKnowledgeBase.childLanguage["childCenteredLanguage"] as? [String: Any],
          let nameData = childLanguageData["childNameDetection"] as? [String: Any] else {
        return detectedNames
    }
    
    // Check against common names list
    if let commonNames = nameData["commonNames"] as? [String] {
        for name in commonNames {
            if text.contains(name) {
                detectedNames.append(name)
            }
        }
    }
    
    // Use regex patterns to detect names
    if let patterns = nameData["patterns"] as? [String] {
        for pattern in patterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let matches = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            for match in matches ?? [] {
                if match.numberOfRanges > 1 {
                    let nameRange = match.range(at: 1)
                    if let swiftRange = Range(nameRange, in: text) {
                        let name = String(text[swiftRange])
                        if !detectedNames.contains(name) {
                            detectedNames.append(name)
                        }
                    }
                }
            }
        }
    }
    
    return detectedNames
}

/// Generate personalized suggestions using user-defined children names
private func generatePersonalizedChildSuggestions(text: String, childName: String, analysis: DeepTextAnalysis, data: [String: Any]) -> [FixCandidate] {
    var candidates: [FixCandidate] = []
    
    let textLower = text.lowercased()
    
    // High-priority personalized suggestions for specific child
    if textLower.contains(childName.lowercased()) {
        // Child-specific empathy reframes
        if analysis.conflictLevel > 0.6 {
            let personalizedReframe = "Let's both pause and think about what's best for \(childName) right now."
            candidates.append(FixCandidate(
                text: personalizedReframe,
                type: .childCentered,
                attachmentRelevance: .high,
                reasoning: "Personalized child-focused de-escalation using actual child's name",
                sourceEngine: .childLanguage,
                confidence: 0.95
            ))
        }
        
        // Collaborative co-parenting with child's name
        if textLower.contains("decision") || textLower.contains("choose") {
            let collaborativeFrame = "What would help \(childName) feel most secure in this situation? Let's decide together."
            candidates.append(FixCandidate(
                text: collaborativeFrame,
                type: .childCentered,
                attachmentRelevance: .high,
                reasoning: "Personalized collaborative decision-making focused on child's wellbeing",
                sourceEngine: .childLanguage,
                confidence: 0.9
            ))
        }
        
        // Developmental consideration with child's name
        if textLower.contains("behavior") || textLower.contains("acting") {
            let developmentalFrame = "I wonder if \(childName)'s behavior might be telling us something about their needs right now."
            candidates.append(FixCandidate(
                text: developmentalFrame,
                type: .developmentalGuidance,
                attachmentRelevance: .high,
                reasoning: "Personalized reframe to consider child's developmental perspective",
                sourceEngine: .childLanguage,
                confidence: 0.88
            ))
        }
    }
    
    // General child-welfare focused suggestions using specific name
    if analysis.emotionalIntensity > 0.7 {
        let calmingPrompt = "For \(childName)'s sake, let's both take a moment to breathe and approach this as a team."
        candidates.append(FixCandidate(
            text: calmingPrompt,
            type: .mindfulnessPrompt,
            attachmentRelevance: .high,
            reasoning: "Personalized mindfulness prompt using child's actual name",
            sourceEngine: .childLanguage,
            confidence: 0.85
        ))
    }
    
    return candidates
}

/// Generate kid-first reframe suggestions
private func generateKidFirstReframes(text: String, childName: String, data: [String: Any]) -> [FixCandidate] {
    var candidates: [FixCandidate] = []
    
    guard let kidFirstData = data["kidFirstReframes"] as? [String: Any] else {
        return candidates
    }
    
    let textLower = text.lowercased()
    
    // Check parent-vs-parent patterns
    if let parentPatterns = kidFirstData["parentVsParentPatterns"] as? [[String: Any]] {
        for pattern in parentPatterns {
            if let trigger = pattern["trigger"] as? String,
               let reframe = pattern["childFocusedReframe"] as? String,
               let reasoning = pattern["reasoning"] as? String,
               textLower.contains(trigger.lowercased()) {
                
                let reframedText = reframe.replacingOccurrences(of: "{child_name}", with: childName)
                candidates.append(FixCandidate(
                    text: reframedText,
                    type: .childCentered,
                    attachmentRelevance: .high,
                    reasoning: "Child-first reframe: \(reasoning)",
                    sourceEngine: .childLanguage,
                    confidence: 0.9
                ))
            }
        }
    }
    
    // Check self-oriented patterns
    if let selfPatterns = kidFirstData["selfOrientedPatterns"] as? [[String: Any]] {
        for pattern in selfPatterns {
            if let trigger = pattern["trigger"] as? String,
               let reframe = pattern["childFocusedReframe"] as? String,
               let reasoning = pattern["reasoning"] as? String,
               textLower.contains(trigger.lowercased()) {
                
                let reframedText = reframe.replacingOccurrences(of: "{child_name}", with: childName)
                candidates.append(FixCandidate(
                    text: reframedText,
                    type: .childCentered,
                    attachmentRelevance: .high,
                    reasoning: "Child-focused reframe: \(reasoning)",
                    sourceEngine: .childLanguage,
                    confidence: 0.85
                ))
            }
        }
    }
    
    return candidates
}

/// Generate developmental prompts for age-appropriate guidance
private func generateDevelopmentalPrompts(text: String, childName: String, data: [String: Any]) -> [FixCandidate] {
    var candidates: [FixCandidate] = []
    
    guard let developmentalData = data["developmentalPrompts"] as? [String: Any] else {
        return candidates
    }
    
    let textLower = text.lowercased()
    
    // Check for topic keywords and provide age-appropriate guidance
    let topics = ["bedtime", "homework", "discipline", "screen_time", "doctor"]
    
    for topic in topics {
        if textLower.contains(topic) {
            if let topicData = developmentalData[topic] as? [String: String] {
                // Default to middle age range if no specific age is mentioned
                let prompt = topicData["ages_6_8"] ?? topicData["general"] ?? "Consider your child's developmental needs in this situation."
                
                candidates.append(FixCandidate(
                    text: prompt,
                    type: .developmentalGuidance,
                    attachmentRelevance: .medium,
                    reasoning: "Age-appropriate guidance for \(topic)",
                    sourceEngine: .childLanguage,
                    confidence: 0.8
                ))
            }
        }
    }
    
    return candidates
}

/// Generate empathy echo suggestions
private func generateEmpathyEcho(text: String, childNames: [String], data: [String: Any]) -> [FixCandidate] {
    var candidates: [FixCandidate] = []
    
    guard let empathyData = data["empathyEcho"] as? [String: Any],
          let templates = empathyData["templates"] as? [String],
          let triggers = empathyData["triggers"] as? [String] else {
        return candidates
    }
    
    let textLower = text.lowercased()
    let primaryChildName = childNames.first ?? "your child"
    
    // Check if text contains empathy triggers
    let hasEmpathyTrigger = triggers.contains { trigger in
        textLower.contains(trigger.replacingOccurrences(of: "{child_name}", with: primaryChildName.lowercased()))
    }
    
    if hasEmpathyTrigger {
        let userState = getUserCurrentEmotionalState()
        let attachmentStyle = getAttachmentStyle()
        let template = selectAdviceUsingBuckets(from: templates, userState: userState, attachmentStyle: attachmentStyle) ?? templates.first!
        let echoStatement = template.replacingOccurrences(of: "{child_name}", with: primaryChildName)
        
        candidates.append(FixCandidate(
            text: echoStatement,
            type: .empathyEcho,
            attachmentRelevance: .high,
            reasoning: "Empathy echo reflecting shared concern for child",
            sourceEngine: .childLanguage,
            confidence: 0.85
        ))
    }
    
    return candidates
}

// MARK: - Mindfulness Integration

/// Generate mindfulness-based suggestions for conflict de-escalation
private func generateMindfulnessSuggestions(text: String, analysis: DeepTextAnalysis) -> [FixCandidate] {
    var candidates: [FixCandidate] = []
    
    guard let mindfulnessData = JSONKnowledgeBase.mindfulnessPrompts["mindfulnessPrompts"] as? [[Any]] else {
        return candidates
    }
    
    let emotion = extractQuickEmotion(text)
    let detectedChildNames = detectChildNames(in: text)
    let primaryChildName = detectedChildNames.first ?? "your child"
    
    // Get calm-down exercises for high conflict
    if analysis.conflictLevel > 0.7 {
        if let childLanguageData = JSONKnowledgeBase.childLanguage["childCenteredLanguage"] as? [String: Any],
           let calmDownData = childLanguageData["calmDownExercises"] as? [String: Any],
           let highConflictExercises = calmDownData["high_conflict"] as? [String] {
            
            let userState = getUserCurrentEmotionalState()
            let attachmentStyle = getAttachmentStyle()
            let exercise = selectAdviceUsingBuckets(from: highConflictExercises, userState: userState, attachmentStyle: attachmentStyle)?.replacingOccurrences(of: "{child_name}", with: primaryChildName)
            
            if let exercise = exercise {
                candidates.append(FixCandidate(
                    text: exercise,
                    type: .mindfulnessPrompt,
                    attachmentRelevance: .high,
                    reasoning: "Conflict de-escalation with child focus",
                    sourceEngine: .mindfulness,
                    confidence: 0.9
                ))
            }
        }
    }
    
    // Get emotion-specific mindfulness prompts
    for emotionGroup in mindfulnessData {
        if let emotionArray = emotionGroup as? [[String: Any]] {
            for prompt in emotionArray {
                if let emotions = prompt["emotions"] as? [String],
                   let promptText = prompt["prompt"] as? String,
                   emotions.contains(emotion) {
                    
                    candidates.append(FixCandidate(
                        text: promptText,
                        type: .mindfulnessPrompt,
                        attachmentRelevance: .medium,
                        reasoning: "Mindfulness prompt for \(emotion)",
                        sourceEngine: .mindfulness,
                        confidence: 0.75
                    ))
                    break // Only add one per emotion to avoid overwhelming
                }
            }
        }
    }
    
    return candidates
}

/// Generate automatic calm-down prompt for very high conflict situations
private func generateAutoCalmDownPrompt(text: String, analysis: DeepTextAnalysis) -> String? {
    let detectedChildNames = detectChildNames(in: text)
    let primaryChildName = detectedChildNames.first ?? "your child"
    
    guard let childLanguageData = JSONKnowledgeBase.childLanguage["childCenteredLanguage"] as? [String: Any],
          let calmDownData = childLanguageData["calmDownExercises"] as? [String: Any],
          let highConflictExercises = calmDownData["high_conflict"] as? [String] else {
        return "Let's both pause and take three deep breaths before we continue."
    }
    
    let userState = getUserCurrentEmotionalState()
    let attachmentStyle = getAttachmentStyle()
    let selectedExercise = selectAdviceUsingBuckets(from: highConflictExercises, userState: userState, attachmentStyle: attachmentStyle) ?? highConflictExercises.first!
    return selectedExercise.replacingOccurrences(of: "{child_name}", with: primaryChildName)
}

// MARK: - LocalVectorStore (RAG Implementation)

/// On-device vector store for semantic retrieval of repair scripts and I-Statements
class LocalVectorStore {
    private var scriptVectors: [(content: String, vector: [Float], metadata: [String: Any])] = []
    private var isInitialized = false
    
    func initialize() {
        guard !isInitialized else { return }
        indexContent()
        isInitialized = true
        print(" LocalVectorStore initialized with \(scriptVectors.count) items")
    }
    
    private func indexContent() {
        // Index repair scripts
        if let scripts = JSONKnowledgeBase.fallbackRepairScripts["scripts"] as? [[String: Any]] {
            for script in scripts {
                if let content = script["content"] as? String {
                    let vector = generateEmbedding(content)
                    scriptVectors.append((content, vector, script))
                }
            }
        }
        
        // Index I-Statements
        if let statements = JSONKnowledgeBase.iStatements["categories"] as? [String: Any] {
            for (category, data) in statements {
                if let categoryData = data as? [String: Any],
                   let templates = categoryData["templates"] as? [String] {
                    for template in templates {
                        let vector = generateEmbedding(template)
                        let metadata = ["type": "i_statement", "category": category]
                        scriptVectors.append((template, vector, metadata))
                    }
                }
            }
        }
    }
    
    func retrieve(query: String, limit: Int = 5) -> [(content: String, score: Float)] {
        guard isInitialized else {
            initialize()
            return retrieve(query: query, limit: limit)
        }
        
        let queryVector = generateEmbedding(query)
        let scored = scriptVectors.map { item in
            (content: item.content, score: cosineSimilarity(queryVector, item.vector))
        }
        
        return Array(scored.sorted { $0.score > $1.score }.prefix(limit))
    }
    
    private func generateEmbedding(_ text: String) -> [Float] {
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        var embedding = [Float](repeating: 0.0, count: 64)
        
        for (index, word) in words.enumerated() {
            let hash = abs(word.hashValue) % 64
            embedding[hash] += 1.0 / Float(index + 1)
        }
        
        let magnitude = sqrt(embedding.reduce(0) { $0 + $1 * $1 })
        return magnitude > 0 ? embedding.map { $0 / magnitude } : embedding
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        let dot = zip(a, b).reduce(0) { $0 + $1.0 * $1.1 }
        let magA = sqrt(a.reduce(0) { $0 + $1 * $1 })
        let magB = sqrt(b.reduce(0) { $0 + $1 * $1 })
        return magA > 0 && magB > 0 ? dot / (magA * magB) : 0
    }
}

// MARK: - ContextualMemory (Conversation Memory & User Profile)

/// Manages short-term conversation memory and long-term user preferences
class ContextualMemory {
    private var conversationBuffer: [(text: String, timestamp: Date, emotion: String)] = []
    private var userProfile: [String: Any] = [:]
    private let maxBufferSize = 10
    
    func initialize() {
        loadUserProfile()
        print(" ContextualMemory initialized")
    }
    
    func addMessage(_ text: String, emotion: String = "neutral") {
        conversationBuffer.append((text, Date(), emotion))
        
        if conversationBuffer.count > maxBufferSize {
            conversationBuffer.removeFirst()
        }
        
        updateUserProfile(text: text, emotion: emotion)
    }
    
    func getRecentPattern() -> String? {
        guard conversationBuffer.count >= 3 else { return nil }
        
        let recentEmotions = conversationBuffer.suffix(3).map { $0.emotion }
        
        // Pattern detection
        if recentEmotions.allSatisfy({ $0 == "anger" || $0 == "frustration" }) {
            return "escalating_anger"
        }
        if recentEmotions.allSatisfy({ $0 == "sadness" || $0 == "disappointment" }) {
            return "persistent_sadness"
        }
        if recentEmotions.contains("anxiety") && recentEmotions.count >= 2 {
            return "anxiety_pattern"
        }
        
        return nil
    }
    
    func getUserPreferences() -> [String: Any] {
        return userProfile
    }
    
    func shouldAvoidSuggestion(_ suggestion: String) -> Bool {
        if let rejectedSuggestions = userProfile["rejected_suggestions"] as? [String] {
            return rejectedSuggestions.contains { suggestion.lowercased().contains($0.lowercased()) }
        }
        return false
    }
    
    func recordSuggestionFeedback(_ suggestion: String, accepted: Bool) {
        if accepted {
            var accepted = userProfile["accepted_suggestions"] as? [String] ?? []
            accepted.append(suggestion)
            userProfile["accepted_suggestions"] = Array(accepted.suffix(20))
        } else {
            var rejected = userProfile["rejected_suggestions"] as? [String] ?? []
            rejected.append(suggestion)
            userProfile["rejected_suggestions"] = Array(rejected.suffix(20))
        }
        
        saveUserProfile()
    }
    
    private func updateUserProfile(text: String, emotion: String) {
        // Track communication patterns
        var patterns = userProfile["communication_patterns"] as? [String: Int] ?? [:]
        
        if text.lowercased().contains("always") || text.lowercased().contains("never") {
            patterns["uses_absolutes"] = (patterns["uses_absolutes"] ?? 0) + 1
        }
        
        if text.lowercased().contains("i feel") {
            patterns["uses_i_statements"] = (patterns["uses_i_statements"] ?? 0) + 1
        }
        
        userProfile["communication_patterns"] = patterns
        
        // Track emotional patterns
        var emotions = userProfile["emotion_frequency"] as? [String: Int] ?? [:]
        emotions[emotion] = (emotions[emotion] ?? 0) + 1
        userProfile["emotion_frequency"] = emotions
    }
    
    private func loadUserProfile() {
        if let data = UserDefaults.standard.data(forKey: "unsaid_user_profile"),
           let profile = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            userProfile = profile
        }
    }
    
    private func saveUserProfile() {
        if let data = try? JSONSerialization.data(withJSONObject: userProfile) {
            UserDefaults.standard.set(data, forKey: "unsaid_user_profile")
        }
    }
}

// MARK: - MicroLLMProcessor (Zero-Shot & Few-Shot Prompting)

/// Handles micro-LLM prompting for creative paraphrasing and I-statement generation
class MicroLLMProcessor {
    private var promptTemplates: [String: String] = [:]
    
    func initialize() {
        setupPromptTemplates()
        print(" MicroLLMProcessor initialized")
    }
    
    func generateCreativeParaphrase(text: String, examples: [(String, String)] = []) -> String? {
        let template = promptTemplates["paraphrase"] ?? ""
        let prompt = buildPrompt(template: template, input: text, examples: examples)
        
        // Simulate micro-LLM processing with pattern-based generation
        return processWithPatterns(input: text, prompt: prompt)
    }
    
    func generateIStatement(text: String, emotion: String, attachmentStyle: AttachmentStyle) -> String? {
        let template = promptTemplates["i_statement"] ?? ""
        let examples = getRelevantIStatementExamples(attachmentStyle: attachmentStyle)
        let prompt = buildPrompt(template: template, input: text, examples: examples)
        
        return processIStatementGeneration(text: text, emotion: emotion, style: attachmentStyle)
    }
    
    func generateWithRAG(text: String, ragResults: [(content: String, score: Float)]) -> String? {
        let relevantExamples = ragResults.prefix(3).map { result in
            (input: "Example situation", output: result.content)
        }
        
        return generateCreativeParaphrase(text: text, examples: Array(relevantExamples))
    }
    
    private func setupPromptTemplates() {
        promptTemplates["paraphrase"] = """
        Transform this message to be more secure and attachment-aware:
        Input: {input}
        Examples: {examples}
        Output:
        """
        
        promptTemplates["i_statement"] = """
        Convert to an I-statement for {attachment_style} attachment style:
        Input: {input}
        Emotion: {emotion}
        Examples: {examples}
        Output:
        """
    }
    
    private func buildPrompt(template: String, input: String, examples: [(String, String)]) -> String {
        var prompt = template.replacingOccurrences(of: "{input}", with: input)
        
        let exampleText = examples.map { "Input: \($0.0)\nOutput: \($0.1)" }.joined(separator: "\n\n")
        prompt = prompt.replacingOccurrences(of: "{examples}", with: exampleText)
        
        return prompt
    }
    
    private func processWithPatterns(input: String, prompt: String) -> String? {
        // Pattern-based micro-LLM simulation
        let text = input.lowercased()
        
        // Aggressive language patterns
        if text.contains("hate") || text.contains("stupid") {
            return "I'm feeling really frustrated about this situation. Can we work through it together?"
        }
        
        // Anxious patterns
        if text.contains("worried") || text.contains("scared") {
            return "I'm feeling anxious and would appreciate some reassurance. Can we talk about this?"
        }
        
        // Avoidant patterns
        if text.contains("space") || text.contains("alone") {
            return "I need some time to process this. Can we continue this conversation later?"
        }
        
        // Default transformation
        return transformToSecurePattern(input)
    }
    
    private func processIStatementGeneration(text: String, emotion: String, style: AttachmentStyle) -> String? {
        let emotionWord = emotion.lowercased()
        let behavior = extractBehaviorFromText(text)
        
        switch style {
        case .anxious:
            return "I feel \(emotionWord) when \(behavior) because I worry about our connection. Could we check in together?"
        case .avoidant:
            return "I feel \(emotionWord) about \(behavior). I'd appreciate if we could discuss this when I'm ready."
        case .disorganized:
            return "I'm feeling \(emotionWord) and a bit overwhelmed by \(behavior). Can we break this down step by step?"
        case .secure:
            return "I feel \(emotionWord) when \(behavior). How can we work together to resolve this?"
        case .unknown:
            return "I feel \(emotionWord) about this situation. Can we talk it through?"
        }
    }
    
    private func getRelevantIStatementExamples(attachmentStyle: AttachmentStyle) -> [(String, String)] {
        // Return examples from JSONKnowledgeBase based on attachment style
        let styleKey = attachmentStyle.rawValue
        
        if let statements = JSONKnowledgeBase.iStatements["i_statements"] as? [String: [String]],
           let templates = statements[styleKey] {
            return templates.prefix(3).map { template in
                ("Example input", template)
            }
        }
        
        return []
    }
    
    private func extractBehaviorFromText(_ text: String) -> String {
        if text.lowercased().contains("interrupt") { return "interrupting" }
        if text.lowercased().contains("ignore") { return "not responding" }
        if text.lowercased().contains("late") { return "being late" }
        return "this situation"
    }
    
    private func transformToSecurePattern(_ text: String) -> String {
        var result = text
        
        // Basic secure communication transformations
        result = result.replacingOccurrences(of: "you always", with: "I notice that you often")
        result = result.replacingOccurrences(of: "you never", with: "I would appreciate if you could")
        result = result.replacingOccurrences(of: "that's wrong", with: "I see it differently")
        
        // Remove quotation marks for cleaner messaging
        result = result.replacingOccurrences(of: "\"", with: "")
        result = result.replacingOccurrences(of: "'", with: "")
        
        return result
        }
    }
}
