//
//  SharedTypes.swift
//  Unsaid
//
//  General shared types and enums used across both communication and keyboard modules
//
//  Created by John Gray on 7/11/25.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Core Shared Types

/// Represents different attachment styles based on psychology research
enum AttachmentStyle: String, CaseIterable, Codable {
    case secure = "secure"
    case anxious = "anxious"
    case avoidant = "avoidant"
    case disorganized = "disorganized"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .secure:
            return "Secure"
        case .anxious:
            return "Anxious"
        case .avoidant:
            return "Avoidant"
        case .disorganized:
            return "Disorganized"
        case .unknown:
            return "Unknown"
        }
    }
}

/// Represents different communication patterns
enum CommunicationPattern: String, CaseIterable, Codable {
    case aggressive
    case passiveAggressive
    case assertive
    case defensive
    case withdrawing
    case pursuing
    case neutral
    
    var displayName: String {
        switch self {
        case .aggressive:
            return "Aggressive"
        case .passiveAggressive:
            return "Passive Aggressive"
        case .assertive:
            return "Assertive"
        case .defensive:
            return "Defensive"
        case .withdrawing:
            return "Withdrawing"
        case .pursuing:
            return "Pursuing"
        case .neutral:
            return "Neutral"
        }
    }
    
    #if canImport(UIKit)
    var color: UIColor {
        switch self {
        case .aggressive:
            return UIColor.systemRed
        case .passiveAggressive:
            return UIColor.systemOrange
        case .assertive:
            return UIColor.systemGreen
        case .defensive:
            return UIColor.systemPurple
        case .withdrawing:
            return UIColor.systemBlue
        case .pursuing:
            return UIColor.systemYellow
        case .neutral:
            return UIColor.systemGray
        }
    }
    #endif
}

/// Represents different relationship contexts
enum RelationshipContext: String, CaseIterable, Codable {
    case unknown = "unknown"
    case romantic = "romantic"
    case family = "family"
    case friendship = "friendship"
    case professional = "professional"
    case acquaintance = "acquaintance"
    
    var displayName: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .romantic:
            return "Romantic"
        case .family:
            return "Family"
        case .friendship:
            return "Friendship"
        case .professional:
            return "Professional"
        case .acquaintance:
            return "Acquaintance"
        }
    }
    
    #if canImport(UIKit)
    var color: UIColor {
        switch self {
        case .unknown:
            return UIColor.systemGray
        case .romantic:
            return UIColor.systemPink
        case .family:
            return UIColor.systemBlue
        case .friendship:
            return UIColor.systemGreen
        case .professional:
            return UIColor.systemYellow
        case .acquaintance:
            return UIColor.systemTeal
        }
    }
    #endif
}

/// Represents different tone statuses
enum ToneStatus: String, CaseIterable, Codable {
    case clear = "clear"
    case caution = "caution"
    case alert = "alert"
    case neutral = "neutral"
    case analyzing = "analyzing"
    
    var displayName: String {
        switch self {
        case .clear:
            return "Clear"
        case .caution:
            return "Caution"
        case .alert:
            return "Alert"
        case .neutral:
            return "Neutral"
        case .analyzing:
            return "Analyzing"
        }
    }
    
    #if canImport(UIKit)
    var color: UIColor {
        switch self {
        case .clear:
            return UIColor.systemGreen
        case .caution:
            return UIColor.systemYellow
        case .alert:
            return UIColor.systemRed
        case .neutral:
            return UIColor.systemGray
        case .analyzing:
            return UIColor.systemBlue
        }
    }
    #endif
}

/// Represents different urgency levels
enum UrgencyLevel: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        case .critical:
            return "Critical"
        }
    }
    
    #if canImport(UIKit)
    var color: UIColor {
        switch self {
        case .low:
            return UIColor.systemGreen
        case .medium:
            return UIColor.systemYellow
        case .high:
            return UIColor.systemOrange
        case .critical:
            return UIColor.systemRed
        }
    }
    #endif
}

/// Represents different conversation types
enum ConversationType: String, CaseIterable, Codable {
    case romantic = "romantic"
    case professional = "professional"
    case social = "social"
    case casual = "casual"
    case family = "family"
    case formal = "formal"
    
    var displayName: String {
        switch self {
        case .romantic:
            return "Romantic"
        case .professional:
            return "Professional"
        case .social:
            return "Social"
        case .casual:
            return "Casual"
        case .family:
            return "Family"
        case .formal:
            return "Formal"
        }
    }
    
    #if canImport(UIKit)
    var color: UIColor {
        switch self {
        case .romantic:
            return UIColor.systemPink
        case .professional:
            return UIColor.systemBlue
        case .social:
            return UIColor.systemGreen
        case .casual:
            return UIColor.systemTeal
        case .family:
            return UIColor.systemYellow
        case .formal:
            return UIColor.systemPurple
        }
    }
    #endif
}

/// Represents real-time tone status
enum RealTimeToneStatus: String, CaseIterable, Codable {
    case positive = "positive"
    case negative = "negative"
    case neutral = "neutral"
    case warning = "warning"
    case suggestion = "suggestion"
    
    var displayName: String {
        switch self {
        case .positive:
            return "Positive"
        case .negative:
            return "Negative"
        case .neutral:
            return "Neutral"
        case .warning:
            return "Warning"
        case .suggestion:
            return "Suggestion"
        }
    }
    
    #if canImport(UIKit)
    var color: UIColor {
        switch self {
        case .positive:
            return UIColor.systemGreen
        case .negative:
            return UIColor.systemRed
        case .neutral:
            return UIColor.systemGray
        case .warning:
            return UIColor.systemYellow
        case .suggestion:
            return UIColor.systemBlue
        }
    }
    #endif
}

// MARK: - Constants

/// Shared constants for the application
struct SharedConstants {
    static let appGroupIdentifier = "group.com.unsaid.keyboard"
    static let maxAnalysisLength = 500
    static let analysisTimeoutInterval: TimeInterval = 5.0
    static let suggestionDisplayDuration: TimeInterval = 3.0
    static let keyboardAnimationDuration: TimeInterval = 0.3
    static let toneIndicatorSize: CGSize = CGSize(width: 60, height: 60)
    static let suggestionBarHeight: CGFloat = 44
    static let keyboardCornerRadius: CGFloat = 8
    static let keyCornerRadius: CGFloat = 4
    static let standardKeySpacing: CGFloat = 6
    static let standardKeyHeight: CGFloat = 42
}

// MARK: - Performance Optimization Types

/// Represents different cognitive load levels for analysis
enum CognitiveLoad: String, CaseIterable, Codable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case overload = "overload"
    
    var displayName: String {
        switch self {
        case .low:
            return "Low Load"
        case .normal:
            return "Normal Load"
        case .high:
            return "High Load"
        case .overload:
            return "Cognitive Overload"
        }
    }
    
    #if canImport(UIKit)
    var color: UIColor {
        switch self {
        case .low:
            return UIColor.systemGreen
        case .normal:
            return UIColor.systemBlue
        case .high:
            return UIColor.systemOrange
        case .overload:
            return UIColor.systemRed
        }
    }
    #endif
}

/// Represents different emotion types for analysis
enum EmotionType: String, CaseIterable, Codable {
    case joy = "joy"
    case sadness = "sadness"
    case anger = "anger"
    case fear = "fear"
    case surprise = "surprise"
    case disgust = "disgust"
    case neutral = "neutral"
    case anxiety = "anxiety"
    case excitement = "excitement"
    case contentment = "contentment"
    
    var displayName: String {
        switch self {
        case .joy:
            return "Joy"
        case .sadness:
            return "Sadness"
        case .anger:
            return "Anger"
        case .fear:
            return "Fear"
        case .surprise:
            return "Surprise"
        case .disgust:
            return "Disgust"
        case .neutral:
            return "Neutral"
        case .anxiety:
            return "Anxiety"
        case .excitement:
            return "Excitement"
        case .contentment:
            return "Contentment"
        }
    }
    
    #if canImport(UIKit)
    var color: UIColor {
        switch self {
        case .joy:
            return UIColor.systemYellow
        case .sadness:
            return UIColor.systemBlue
        case .anger:
            return UIColor.systemRed
        case .fear:
            return UIColor.systemPurple
        case .surprise:
            return UIColor.systemOrange
        case .disgust:
            return UIColor.systemBrown
        case .neutral:
            return UIColor.systemGray
        case .anxiety:
            return UIColor.systemIndigo
        case .excitement:
            return UIColor.systemPink
        case .contentment:
            return UIColor.systemGreen
        }
    }
    #endif
}

/// Represents emotional regulation patterns
enum EmotionalRegulation: String, CaseIterable, Codable {
    case stable = "stable"
    case fluctuating = "fluctuating"
    case escalating = "escalating"
    case deescalating = "deescalating"
    case volatile = "volatile"
    case suppressed = "suppressed"
    
    var displayName: String {
        switch self {
        case .stable:
            return "Stable"
        case .fluctuating:
            return "Fluctuating"
        case .escalating:
            return "Escalating"
        case .deescalating:
            return "De-escalating"
        case .volatile:
            return "Volatile"
        case .suppressed:
            return "Suppressed"
        }
    }
    
    #if canImport(UIKit)
    var color: UIColor {
        switch self {
        case .stable:
            return UIColor.systemGreen
        case .fluctuating:
            return UIColor.systemYellow
        case .escalating:
            return UIColor.systemRed
        case .deescalating:
            return UIColor.systemBlue
        case .volatile:
            return UIColor.systemOrange
        case .suppressed:
            return UIColor.systemGray
        }
    }
    #endif
}

// MARK: - Analysis Data Structures

/// Represents a conversation turn in the analysis
struct ConversationTurn: Codable {
    let id: UUID
    let timestamp: Date
    let text: String
    let speaker: String
    let toneStatus: ToneStatus
    let emotionType: EmotionType
    let attachmentStyle: AttachmentStyle
    
    init(text: String, speaker: String, toneStatus: ToneStatus = .neutral, emotionType: EmotionType = .neutral, attachmentStyle: AttachmentStyle = .unknown) {
        self.id = UUID()
        self.timestamp = Date()
        self.text = text
        self.speaker = speaker
        self.toneStatus = toneStatus
        self.emotionType = emotionType
        self.attachmentStyle = attachmentStyle
    }
}

/// Context for analysis operations
struct AnalysisContext: Codable {
    let conversationHistory: [ConversationTurn]
    let relationshipContext: RelationshipContext
    let userAttachmentStyle: AttachmentStyle
    let partnerAttachmentStyle: AttachmentStyle
    let conversationType: ConversationType
    let urgencyLevel: UrgencyLevel
    let timestamp: Date
    
    init(
        conversationHistory: [ConversationTurn] = [],
        relationshipContext: RelationshipContext = .unknown,
        userAttachmentStyle: AttachmentStyle = .unknown,
        partnerAttachmentStyle: AttachmentStyle = .unknown,
        conversationType: ConversationType = .casual,
        urgencyLevel: UrgencyLevel = .low
    ) {
        self.conversationHistory = conversationHistory
        self.relationshipContext = relationshipContext
        self.userAttachmentStyle = userAttachmentStyle
        self.partnerAttachmentStyle = partnerAttachmentStyle
        self.conversationType = conversationType
        self.urgencyLevel = urgencyLevel
        self.timestamp = Date()
    }
}

/// Represents comprehensive tone analysis results
struct ComprehensiveToneAnalysis: Codable {
    let id: UUID
    let timestamp: Date
    let primaryTone: ToneClassification
    let toneConfidence: Float
    let emotionalProfile: EmotionalProfile
    let communicationIntent: CommunicationIntent
    let relationshipDynamics: RelationshipDynamics
    let attachmentAnalysis: AttachmentAnalysis
    let psychologicalState: PsychologicalState
    let effectivenessPrediction: EffectivenessPrediction
    let riskAssessment: RiskAssessment
    let interventionRecommendations: [InterventionRecommendation]
    let confidenceMetrics: ConfidenceMetrics
    
    init() {
        self.id = UUID()
        self.timestamp = Date()
        self.primaryTone = ToneClassification(tone: .neutral, confidence: 0.0, alternativeTones: [])
        self.toneConfidence = 0.0
        self.emotionalProfile = EmotionalProfile()
        self.communicationIntent = CommunicationIntent()
        self.relationshipDynamics = RelationshipDynamics()
        self.attachmentAnalysis = AttachmentAnalysis()
        self.psychologicalState = PsychologicalState()
        self.effectivenessPrediction = EffectivenessPrediction()
        self.riskAssessment = RiskAssessment()
        self.interventionRecommendations = []
        self.confidenceMetrics = ConfidenceMetrics()
    }
}

/// Tone classification with confidence and alternatives
struct ToneClassification: Codable {
    let tone: ToneStatus
    let confidence: Float
    let alternativeTones: [ToneStatus]
    
    var isHighConfidence: Bool {
        return confidence > 0.7
    }
    
    var isLowConfidence: Bool {
        return confidence < 0.3
    }
}

/// Emotional profile analysis
struct EmotionalProfile: Codable {
    let dominantEmotion: EmotionType
    let secondaryEmotions: [EmotionType]
    let emotionalIntensity: Float
    let emotionalStability: EmotionalRegulation
    let negativeEmotions: [Float]
    let positiveEmotions: [Float]
    let emotionalComplexity: Float
    
    init() {
        self.dominantEmotion = .neutral
        self.secondaryEmotions = []
        self.emotionalIntensity = 0.0
        self.emotionalStability = .stable
        self.negativeEmotions = []
        self.positiveEmotions = []
        self.emotionalComplexity = 0.0
    }
}

/// Communication intent analysis
struct CommunicationIntent: Codable {
    let primaryIntent: String
    let secondaryIntents: [String]
    let intentConfidence: Float
    let intentClarity: Float
    let underlyingNeeds: [String]
    
    init() {
        self.primaryIntent = "unknown"
        self.secondaryIntents = []
        self.intentConfidence = 0.0
        self.intentClarity = 0.0
        self.underlyingNeeds = []
    }
}

/// Relationship dynamics analysis
struct RelationshipDynamics: Codable {
    let powerBalance: Float
    let intimacyLevel: Float
    let conflictLevel: Float
    let trustLevel: Float
    let communicationQuality: Float
    let attachmentActivation: Float
    
    init() {
        self.powerBalance = 0.0
        self.intimacyLevel = 0.0
        self.conflictLevel = 0.0
        self.trustLevel = 0.0
        self.communicationQuality = 0.0
        self.attachmentActivation = 0.0
    }
}

/// Attachment system analysis
struct AttachmentAnalysis: Codable {
    let primaryAttachmentStyle: AttachmentStyle
    let attachmentActivation: Float
    let attachmentSecurity: Float
    let attachmentBehaviors: [String]
    let attachmentTriggers: [String]
    
    init() {
        self.primaryAttachmentStyle = .unknown
        self.attachmentActivation = 0.0
        self.attachmentSecurity = 0.0
        self.attachmentBehaviors = []
        self.attachmentTriggers = []
    }
}

/// Psychological state analysis
struct PsychologicalState: Codable {
    let distressLevel: Float
    let cognitiveLoad: CognitiveLoad
    let emotionalRegulation: EmotionalRegulation
    let mentalClarity: Float
    let stressIndicators: [String]
    let copingStrategies: [String]
    
    init() {
        self.distressLevel = 0.0
        self.cognitiveLoad = .normal
        self.emotionalRegulation = .stable
        self.mentalClarity = 0.0
        self.stressIndicators = []
        self.copingStrategies = []
    }
}

/// Communication effectiveness prediction
struct EffectivenessPrediction: Codable {
    let effectivenessScore: Float
    let clarityScore: Float
    let empathyScore: Float
    let assertivenessScore: Float
    let likelyOutcomes: [String]
    let improvementSuggestions: [String]
    
    init() {
        self.effectivenessScore = 0.0
        self.clarityScore = 0.0
        self.empathyScore = 0.0
        self.assertivenessScore = 0.0
        self.likelyOutcomes = []
        self.improvementSuggestions = []
    }
}

/// Risk assessment for communication
struct RiskAssessment: Codable {
    let escalationRisk: Float
    let misunderstandingRisk: Float
    let relationshipRisk: Float
    let emotionalRisk: Float
    let riskFactors: [String]
    let mitigationStrategies: [String]
    
    init() {
        self.escalationRisk = 0.0
        self.misunderstandingRisk = 0.0
        self.relationshipRisk = 0.0
        self.emotionalRisk = 0.0
        self.riskFactors = []
        self.mitigationStrategies = []
    }
}

/// Intervention recommendations
struct InterventionRecommendation: Codable {
    let id: UUID
    let type: InterventionType
    let priority: UrgencyLevel
    let description: String
    let expectedOutcome: String
    let timeframe: String
    
    init(type: InterventionType, priority: UrgencyLevel, description: String, expectedOutcome: String, timeframe: String) {
        self.id = UUID()
        self.type = type
        self.priority = priority
        self.description = description
        self.expectedOutcome = expectedOutcome
        self.timeframe = timeframe
    }
}

/// Types of interventions
enum InterventionType: String, CaseIterable, Codable {
    case pauseAndReflect = "pause_and_reflect"
    case reframe = "reframe"
    case empathize = "empathize"
    case clarify = "clarify"
    case deescalate = "deescalate"
    case assertiveResponse = "assertive_response"
    case emotionalRegulation = "emotional_regulation"
    case boundarySet = "boundary_set"
    
    var displayName: String {
        switch self {
        case .pauseAndReflect:
            return "Pause and Reflect"
        case .reframe:
            return "Reframe"
        case .empathize:
            return "Empathize"
        case .clarify:
            return "Clarify"
        case .deescalate:
            return "De-escalate"
        case .assertiveResponse:
            return "Assertive Response"
        case .emotionalRegulation:
            return "Emotional Regulation"
        case .boundarySet:
            return "Set Boundaries"
        }
    }
}

/// Confidence metrics for analysis
struct ConfidenceMetrics: Codable {
    let overallConfidence: Float
    let toneConfidence: Float
    let emotionConfidence: Float
    let intentConfidence: Float
    let attachmentConfidence: Float
    let predictionConfidence: Float
    let dataQuality: Float
    
    init() {
        self.overallConfidence = 0.0
        self.toneConfidence = 0.0
        self.emotionConfidence = 0.0
        self.intentConfidence = 0.0
        self.attachmentConfidence = 0.0
        self.predictionConfidence = 0.0
        self.dataQuality = 0.0
    }
}

// MARK: - Performance Constants

/// Performance-related constants for optimization
struct PerformanceConstants {
    static let analysisDebounceInterval: TimeInterval = 0.3
    static let toneUpdateInterval: TimeInterval = 0.1
    static let cacheTimeout: TimeInterval = 30.0
    static let maxCacheSize: Int = 100
    static let minTextLengthForAnalysis: Int = 3
    static let maxTextLengthForRealtime: Int = 500
    static let batchAnalysisSize: Int = 10
    static let maxHistorySize: Int = 50
    static let confidenceThreshold: Float = 0.5
}

// MARK: - Analytics and Data Collection

/// Keyboard interaction data for analytics
struct KeyboardInteraction {
    let timestamp: Date
    let textBefore: String
    let textAfter: String
    let toneStatus: ToneStatus
    let suggestionAccepted: Bool
    let suggestionText: String?
    let analysisTime: TimeInterval
    let context: String
    let interactionType: InteractionType
    
    enum InteractionType {
        case keyPress
        case suggestion
        case toneAnalysis
        case quickFix
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "timestamp": timestamp.timeIntervalSince1970,
            "text_before": textBefore,
            "text_after": textAfter,
            "tone_status": toneStatus.rawValue,
            "suggestion_accepted": suggestionAccepted,
            "suggestion_text": suggestionText ?? "",
            "analysis_time": analysisTime,
            "context": context,
            "interaction_type": interactionType.rawValue
        ]
    }
}

extension KeyboardInteraction.InteractionType {
    var rawValue: String {
        switch self {
        case .keyPress: return "key_press"
        case .suggestion: return "suggestion"
        case .toneAnalysis: return "tone_analysis"
        case .quickFix: return "quick_fix"
        }
    }
}
