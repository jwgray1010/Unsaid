import Foundation

class SmartInferenceManager {
    private var debounceTimer: Timer?
    private let debounceInterval: TimeInterval = 0.3 // 300ms
    private var lastText: String = ""
    private var lastSuggestion: String = ""
    
    private let aiService = AIProcessingService()
    private let fallbackService = LightweightAIService()
    
    func requestSuggestion(text: String, emotionalState: String, completion: @escaping (String?) -> Void) {
        // Cancel previous timer
        debounceTimer?.invalidate()
        
        // Check if text changed significantly
        if shouldSkipInference(newText: text) {
            completion(lastSuggestion)
            return
        }
        
        // Debounce the inference
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            self?.performInference(text: text, emotionalState: emotionalState, completion: completion)
        }
    }
    
    private func shouldSkipInference(newText: String) -> Bool {
        // Skip if text is too similar to last processed text
        let similarity = calculateSimilarity(lastText, newText)
        return similarity > 0.9 && !lastSuggestion.isEmpty
    }
    
    private func performInference(text: String, emotionalState: String, completion: @escaping (String?) -> Void) {
        // Try host app IPC first
        if let suggestion = aiService.requestAISuggestion(text: text, emotionalState: emotionalState) {
            lastText = text
            lastSuggestion = suggestion
            completion(suggestion)
            return
        }
        
        // Fallback to local inference
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let suggestion = self?.fallbackService.getSuggestion(text: text, emotionalState: emotionalState)
            
            DispatchQueue.main.async {
                self?.lastText = text
                self?.lastSuggestion = suggestion ?? ""
                completion(suggestion)
            }
        }
    }
    
    private func calculateSimilarity(_ str1: String, _ str2: String) -> Double {
        // Simple similarity check - can be improved
        let common = Set(str1.components(separatedBy: " ")).intersection(Set(str2.components(separatedBy: " ")))
        let total = Set(str1.components(separatedBy: " ")).union(Set(str2.components(separatedBy: " ")))
        
        return total.isEmpty ? 0.0 : Double(common.count) / Double(total.count)
    }
}
