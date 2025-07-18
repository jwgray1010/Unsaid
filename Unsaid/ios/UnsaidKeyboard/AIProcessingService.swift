import Foundation

class AIProcessingService {
    private let appGroupIdentifier = "group.com.unsaid.shared"
    private let requestKey = "ai_processing_request"
    private let responseKey = "ai_processing_response"
    
    func requestAISuggestion(text: String, emotionalState: String) -> String? {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return nil
        }
        
        // Create request payload
        let request = [
            "text": text,
            "emotionalState": emotionalState,
            "timestamp": Date().timeIntervalSince1970
        ] as [String: Any]
        
        // Store request
        userDefaults.set(request, forKey: requestKey)
        userDefaults.synchronize()
        
        // Wait for response (with timeout)
        let timeout: TimeInterval = 2.0
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            if let response = userDefaults.object(forKey: responseKey) as? [String: Any],
               let responseText = response["suggestion"] as? String,
               let responseTimestamp = response["timestamp"] as? TimeInterval,
               responseTimestamp > (request["timestamp"] as? TimeInterval ?? 0) {
                
                // Clear the response
                userDefaults.removeObject(forKey: responseKey)
                return responseText
            }
            
            // Small delay to prevent busy waiting
            usleep(50000) // 50ms
        }
        
        return nil
    }
}
