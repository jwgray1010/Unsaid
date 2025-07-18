import Foundation
import UserNotifications

class HostAppAIService {
    static let shared = HostAppAIService()
    private let appGroupIdentifier = "group.com.unsaid.shared"
    private let requestKey = "ai_processing_request"
    private let responseKey = "ai_processing_response"
    
    private var isMonitoring = false
    private var monitoringTimer: Timer?
    
    private init() {}
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        // Check for requests every 100ms
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkForRequests()
        }
        
        print("🔍 HostAppAIService: Started monitoring for keyboard requests")
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        print("🛑 HostAppAIService: Stopped monitoring")
    }
    
    private func checkForRequests() {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return
        }
        
        guard let request = userDefaults.object(forKey: requestKey) as? [String: Any],
              let text = request["text"] as? String,
              let emotionalState = request["emotionalState"] as? String,
              let timestamp = request["timestamp"] as? TimeInterval else {
            return
        }
        
        // Check if this is a new request (not older than 5 seconds)
        let requestAge = Date().timeIntervalSince1970 - timestamp
        guard requestAge < 5.0 else {
            return
        }
        
        // Process the request
        processAIRequest(text: text, emotionalState: emotionalState, timestamp: timestamp)
        
        // Clear the request
        userDefaults.removeObject(forKey: requestKey)
    }
    
    private func processAIRequest(text: String, emotionalState: String, timestamp: TimeInterval) {
        print("🧠 HostAppAIService: Processing request for text: '\(text)' with state: '\(emotionalState)'")
        
        // Simulate AI processing (replace with your actual AI logic)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let suggestion = self?.generateSuggestion(text: text, emotionalState: emotionalState)
            
            DispatchQueue.main.async {
                self?.sendResponse(suggestion: suggestion ?? "Keep it simple and clear.", timestamp: timestamp)
            }
        }
    }
    
    private func generateSuggestion(text: String, emotionalState: String) -> String {
        // Replace this with your actual AI processing logic
        // For now, return context-aware suggestions based on emotional state
        
        let lowercasedText = text.lowercased()
        
        switch emotionalState {
        case "overwhelmed", "stressed":
            if lowercasedText.contains("sorry") {
                return "I'm feeling overwhelmed right now"
            } else if lowercasedText.contains("can't") {
                return "This is challenging for me at the moment"
            } else {
                return "Let me take a moment to process this"
            }
            
        case "calm", "content":
            if lowercasedText.contains("thanks") {
                return "I really appreciate that"
            } else if lowercasedText.contains("good") {
                return "That sounds wonderful"
            } else {
                return "I'm feeling good about this"
            }
            
        case "tense", "anxious":
            if lowercasedText.contains("worried") {
                return "I have some concerns about this"
            } else if lowercasedText.contains("not sure") {
                return "I'd like to think about this more"
            } else {
                return "Can we talk about this when I'm feeling more settled?"
            }
            
        default:
            return "That makes sense to me"
        }
    }
    
    private func sendResponse(suggestion: String, timestamp: TimeInterval) {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return
        }
        
        let response = [
            "suggestion": suggestion,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        userDefaults.set(response, forKey: responseKey)
        userDefaults.synchronize()
        
        print("✅ HostAppAIService: Sent response: '\(suggestion)'")
    }
}
