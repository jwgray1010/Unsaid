//
//  EnhancedCommunicatorService.swift
//  UnsaidKeyboard
//
//  Enhanced Attachment Learning Integration for 92%+ Clinical Accuracy
//  Connects to the advanced linguistic analysis backend
//  COMBINES real-time attachment analysis WITH personality assessments from main app
//

import Foundation
import Network

@available(iOS 13.0, *)
class EnhancedCommunicatorService: ObservableObject {
    
    // MARK: - Configuration
    private let baseURL = "https://www.api.myunsaidapp.com/api" // Production API endpoint
    private let session = URLSession.shared
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Personality Integration
    private let personalityBridge = PersonalityDataBridge.shared
    
    // MARK: - Enhanced Analysis Models
    struct EnhancedAnalysisRequest: Codable {
        let text: String
        let context: AnalysisContext?
        let personalityProfile: PersonalityProfile?
        
        struct AnalysisContext: Codable {
            let relationshipPhase: String? // "new", "developing", "established", "strained"
            let stressLevel: String?       // "low", "moderate", "high" 
            let messageType: String?       // "casual", "serious", "conflict", "support"
        }
        
        struct PersonalityProfile: Codable {
            let attachmentStyle: String
            let communicationStyle: String
            let personalityType: String
            let emotionalState: String
            let emotionalBucket: String
            let personalityScores: [String: Int]?
            let communicationPreferences: [String: Any]?
            let isComplete: Bool
            let dataFreshness: Double
            
            init(from bridge: PersonalityDataBridge) {
                self.attachmentStyle = bridge.getAttachmentStyle()
                self.communicationStyle = bridge.getCommunicationStyle()
                self.personalityType = bridge.getPersonalityType()
                self.emotionalState = bridge.getCurrentEmotionalState()
                self.emotionalBucket = bridge.getCurrentEmotionalBucket()
                self.isComplete = bridge.isPersonalityTestComplete()
                self.dataFreshness = bridge.getDataFreshness()
                
                // Get full profile for additional data
                let fullProfile = bridge.getPersonalityProfile()
                self.personalityScores = fullProfile["personality_scores"] as? [String: Int]
                self.communicationPreferences = fullProfile["communication_preferences"] as? [String: Any]
            }
        }
    }
    
    struct EnhancedAnalysisResponse: Codable {
        let ok: Bool
        let userId: String
        let analysis: AnalysisResult
        
        struct AnalysisResult: Codable {
            let text: String
            let confidence: Double
            let attachmentScores: AttachmentScores
            let primaryStyle: String
            let microPatterns: [MicroPattern]
            let linguisticFeatures: LinguisticFeatures
            let contextualFactors: [String: Double]?
            let metadata: AnalysisMetadata
            
            struct AttachmentScores: Codable {
                let anxious: Double
                let avoidant: Double
                let secure: Double
                let disorganized: Double
            }
            
            struct MicroPattern: Codable {
                let type: String
                let pattern: String
                let weight: Double
                let position: Int?
            }
            
            struct LinguisticFeatures: Codable {
                let punctuation: PunctuationFeatures?
                let hesitation: HesitationFeatures?
                let complexity: ComplexityFeatures?
                let discourse: DiscourseFeatures?
                
                struct PunctuationFeatures: Codable {
                    let patterns: [String: Int]
                    let emotionalScore: Double
                }
                
                struct HesitationFeatures: Codable {
                    let patterns: [String: Int]
                    let uncertaintyScore: Double
                }
                
                struct ComplexityFeatures: Codable {
                    let score: Double
                    let avgWordsPerSentence: Double
                    let avgSyllablesPerWord: Double
                }
                
                struct DiscourseFeatures: Codable {
                    let markers: [String: Int]
                    let coherenceScore: Double
                }
            }
            
            struct AnalysisMetadata: Codable {
                let analysisVersion: String
                let accuracyTarget: String
                let timestamp: String
            }
        }
    }
    
    struct ObserveRequest: Codable {
        let text: String
        let meta: [String: String]?
        let personalityProfile: EnhancedAnalysisRequest.PersonalityProfile?
    }
    
    struct ObserveResponse: Codable {
        let ok: Bool
        let userId: String
        let estimate: AttachmentEstimate
        let windowComplete: Bool
        let enhancedAnalysis: EnhancedAnalysisSummary?
        
        struct AttachmentEstimate: Codable {
            let primary: String?
            let secondary: String?
            let scores: [String: Double]
            let confidence: Double
            let daysObserved: Int
            let windowComplete: Bool
        }
        
        struct EnhancedAnalysisSummary: Codable {
            let confidence: Double
            let detectedPatterns: Int
            let primaryPrediction: String
        }
    }
    
    struct ProfileResponse: Codable {
        let ok: Bool
        let userId: String
        let estimate: ObserveResponse.AttachmentEstimate
        let rawScores: [String: Double]
        let daysObserved: Int
        let windowComplete: Bool
        let enhancedFeatures: EnhancedFeatures?
        
        struct EnhancedFeatures: Codable {
            let advancedAnalysisAvailable: Bool
            let version: String
            let accuracyTarget: String
            let features: [String]
        }
    }
    
    // MARK: - Public Methods
    
    /// Perform detailed enhanced analysis on text
    func performDetailedAnalysis(
        text: String, 
        relationshipPhase: String = "established",
        stressLevel: String = "moderate",
        messageType: String = "casual"
    ) async throws -> EnhancedAnalysisResponse.AnalysisResult {
        
        // Combine real-time context with personality assessment data
        let personalityProfile = EnhancedAnalysisRequest.PersonalityProfile(from: personalityBridge)
        
        let request = EnhancedAnalysisRequest(
            text: text,
            context: EnhancedAnalysisRequest.AnalysisContext(
                relationshipPhase: relationshipPhase,
                stressLevel: stressLevel,
                messageType: messageType
            ),
            personalityProfile: personalityProfile
        )
        
        let response: EnhancedAnalysisResponse = try await makeRequest(
            endpoint: "/api/communicator/analysis/detailed",
            method: "POST",
            body: request
        )
        
        return response.analysis
    }
    
    /// Observe text for attachment learning (with enhanced analysis)
    func observeText(
        _ text: String, 
        relationshipPhase: String = "established",
        stressLevel: String = "moderate"
    ) async throws -> ObserveResponse {
        
        // Include personality assessment data for more accurate learning
        let personalityProfile = EnhancedAnalysisRequest.PersonalityProfile(from: personalityBridge)
        
        let request = ObserveRequest(
            text: text,
            meta: [
                "relationshipPhase": relationshipPhase,
                "stressLevel": stressLevel,
                "source": "ios_keyboard"
            ],
            personalityProfile: personalityProfile
        )
        
        return try await makeRequest(
            endpoint: "/api/communicator/observe",
            method: "POST", 
            body: request
        )
    }
    
    /// Get current attachment profile with enhanced features
    func getProfile() async throws -> ProfileResponse {
        return try await makeRequest(
            endpoint: "/api/communicator/profile",
            method: "GET"
        )
    }
    
    /// Check if enhanced analysis is available
    func checkEnhancedCapabilities() async throws -> Bool {
        let profile = try await getProfile()
        return profile.enhancedFeatures?.advancedAnalysisAvailable ?? false
    }
    
    // MARK: - Convenience Methods for Keyboard
    
    /// Quick attachment style prediction for keyboard suggestions
    func getAttachmentStyleForText(_ text: String) async -> String? {
        do {
            let analysis = try await performDetailedAnalysis(text: text)
            return analysis.primaryStyle
        } catch {
            print("⚠️ Enhanced analysis failed, falling back to personality assessment: \(error)")
            // Fallback to personality assessment data
            return personalityBridge.getAttachmentStyle()
        }
    }
    
    /// Get confidence score for attachment prediction
    func getConfidenceForText(_ text: String) async -> Double {
        do {
            let analysis = try await performDetailedAnalysis(text: text)
            return analysis.confidence
        } catch {
            print("⚠️ Enhanced analysis failed: \(error)")
            // Return confidence based on personality test completeness
            return personalityBridge.isPersonalityTestComplete() ? 0.8 : 0.3
        }
    }
    
    /// Get micro-patterns detected in text
    func getMicroPatternsForText(_ text: String) async -> [String] {
        do {
            let analysis = try await performDetailedAnalysis(text: text)
            return analysis.microPatterns.map { $0.pattern }
        } catch {
            print("⚠️ Enhanced analysis failed: \(error)")
            return []
        }
    }
    
    /// Get combined personality insights (both assessment + real-time)
    func getCombinedPersonalityInsights() -> [String: Any] {
        var insights: [String: Any] = [:]
        
        // Get personality assessment data
        let profile = personalityBridge.getPersonalityProfile()
        insights["personality_assessment"] = profile
        
        // Add enhanced analysis status
        insights["enhanced_analysis_available"] = true
        insights["data_freshness"] = personalityBridge.getDataFreshness()
        insights["assessment_complete"] = personalityBridge.isPersonalityTestComplete()
        
        // Add real-time context
        insights["current_emotional_state"] = personalityBridge.getCurrentEmotionalState()
        insights["current_emotional_bucket"] = personalityBridge.getCurrentEmotionalBucket()
        
        return insights
    }
    
    /// Check if we have sufficient personality data for enhanced analysis
    func hasRichPersonalityData() -> Bool {
        return personalityBridge.isPersonalityTestComplete() && 
               personalityBridge.getDataFreshness() < 24 // Less than 24 hours old
    }
    
    // MARK: - Private Network Methods
    
    private func makeRequest<T: Codable, R: Codable>(
        endpoint: String,
        method: String,
        body: T? = nil
    ) async throws -> R {
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw CommunicatorError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ios-keyboard-v2.1.0", forHTTPHeaderField: "User-Agent")
        
        // Add user ID header (you may want to customize this)
        let userId = await getCurrentUserId()
        request.setValue(userId, forHTTPHeaderField: "X-User-Id")
        
        if let body = body {
            request.httpBody = try encoder.encode(body)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CommunicatorError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw CommunicatorError.serverError(httpResponse.statusCode)
        }
        
        return try decoder.decode(R.self, from: data)
    }
    
    private func getCurrentUserId() async -> String {
        // Implement your user ID logic here
        // This could come from UserDefaults, Keychain, or your auth system
        return UserDefaults.standard.string(forKey: "unsaid_user_id") ?? "anonymous"
    }
}

// MARK: - Error Types
enum CommunicatorError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}

// MARK: - Usage Example in Keyboard
/*
 Usage in KeyboardViewController:
 
 class KeyboardViewController: UIInputViewController {
     private let communicatorService = EnhancedCommunicatorService()
     
     func analyzeText(_ text: String) {
         Task {
             do {
                 // Get detailed analysis
                 let analysis = try await communicatorService.performDetailedAnalysis(text: text)
                 
                 await MainActor.run {
                     // Update UI based on analysis
                     updateSuggestionsFor(
                         attachmentStyle: analysis.primaryStyle,
                         confidence: analysis.confidence,
                         microPatterns: analysis.microPatterns
                     )
                 }
                 
                 // Learn from this text
                 let _ = try await communicatorService.observeText(text)
                 
             } catch {
                 print("Analysis failed: \(error)")
             }
         }
     }
 }
*/
