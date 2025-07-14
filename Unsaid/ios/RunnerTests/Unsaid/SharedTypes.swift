//
//  SharedTypes.swift
//  UnsaidShared Framework
//
//  Created by John Gray on 7/7/25.
//  Copyright © 2025 Unsaid. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Core Communication Types

/// Represents different attachment styles based on psychology research
public enum AttachmentStyle: String, CaseIterable, Codable {
    case secure = "secure"
    case anxious = "anxious"
    case avoidant = "avoidant"
    case disorganized = "disorganized"
    case unknown = "unknown"
    
    public var displayName: String {
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
public enum CommunicationPattern: String, CaseIterable, Codable {
    case aggressive
    case passiveAggressive
    case assertive
    case defensive
    case withdrawing
    case pursuing
    case neutral
    
    public var displayName: String {
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
    public var color: UIColor {
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
public enum RelationshipContext: String, CaseIterable, Codable {
    case unknown = "unknown"
    case romantic = "romantic"
    case family = "family"
    case friendship = "friendship"
    case professional = "professional"
    case acquaintance = "acquaintance"
    
    public var displayName: String {
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
    public var color: UIColor {
        switch self {
        case .unknown:
            return UIColor.systemGray
        case .romantic:
            return UIColor.systemPink
        case .family:
            return UIColor.systemBrown
        case .friendship:
            return UIColor.systemYellow
        case .professional:
            return UIColor.systemBlue
        case .acquaintance:
            return UIColor.systemGreen
        }
    }
    #endif
}

/// Represents the emotional tone status of a message
public enum ToneStatus: String, CaseIterable, Codable {
    case clear = "clear"         // Green - good tone (positive, friendly)
    case caution = "caution"     // Yellow - could be improved (urgent/demanding)
    case alert = "alert"         // Red - problematic tone (harsh, could hurt feelings)
    case neutral = "neutral"     // White - neutral tone
    case analyzing = "analyzing" // White - currently analyzing
    
    #if canImport(UIKit)
    public var color: UIColor {
        switch self {
        case .clear: return .systemGreen
        case .caution: return .systemYellow
        case .alert: return .systemRed
        case .neutral: return .systemGray
        case .analyzing: return .systemGray
        }
    }
    #endif
    
    public var displayName: String {
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
}

// MARK: - Data Structures

/// Represents tone analysis results
public struct ToneAnalysis: Codable {
    public let status: ToneStatus
    public let confidence: Double
    public let suggestions: [String]
    public let timestamp: Date
    
    public init(status: ToneStatus, confidence: Double, suggestions: [String], timestamp: Date) {
        self.status = status
        self.confidence = confidence
        self.suggestions = suggestions
        self.timestamp = timestamp
    }
}

/// Represents communication improvement suggestions
public struct CommunicationSuggestion: Codable {
    public let originalText: String
    public let improvedText: String
    public let explanation: String
    public let attachmentStyle: AttachmentStyle
    public let pattern: CommunicationPattern
    public let context: RelationshipContext
    
    public init(originalText: String, improvedText: String, explanation: String, attachmentStyle: AttachmentStyle, pattern: CommunicationPattern, context: RelationshipContext) {
        self.originalText = originalText
        self.improvedText = improvedText
        self.explanation = explanation
        self.attachmentStyle = attachmentStyle
        self.pattern = pattern
        self.context = context
    }
}

/// Represents user profile data
public struct UserProfile: Codable {
    public let attachmentStyle: AttachmentStyle
    public let dominantPattern: CommunicationPattern
    public let preferredContext: RelationshipContext
    public let lastUpdated: Date
    
    public init(attachmentStyle: AttachmentStyle, dominantPattern: CommunicationPattern, preferredContext: RelationshipContext, lastUpdated: Date) {
        self.attachmentStyle = attachmentStyle
        self.dominantPattern = dominantPattern
        self.preferredContext = preferredContext
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Constants

public struct SharedConstants {
    public static let maxAnalysisHistory = 100
    public static let minTextLengthForAnalysis = 5
    public static let defaultToneConfidence = 0.5
    public static let analysisTimeoutSeconds = 30.0
    public static let appGroupID = "group.com.unsaid.shared"
}

// MARK: - Helper Extensions

#if canImport(UIKit)
public extension UIColor {
    static let systemWhite = UIColor.white
}
#endif
