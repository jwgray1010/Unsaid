import Foundation
import CoreML

class LightweightAIService {
    private var model: MLModel?
    private var lastUsed: Date = Date()
    private let memoryTimeout: TimeInterval = 30.0 // Release after 30 seconds
    
    func getSuggestion(text: String, emotionalState: String) -> String? {
        // Lazy load the model
        if model == nil {
            loadModel()
        }
        
        guard let model = model else { return nil }
        
        // Perform inference in autorelease pool
        var result: String?
        autoreleasepool {
            // Your inference logic here
            result = performInference(model: model, text: text, state: emotionalState)
        }
        
        lastUsed = Date()
        
        // Schedule cleanup
        scheduleCleanup()
        
        return result
    }
    
    private func loadModel() {
        do {
            // Load quantized/compressed model
            guard let modelURL = Bundle.main.url(forResource: "UnsaidModel_Quantized", withExtension: "mlmodelc") else {
                return
            }
            
            let config = MLModelConfiguration()
            config.computeUnits = .cpuOnly // Use CPU to save memory
            
            model = try MLModel(contentsOf: modelURL, configuration: config)
        } catch {
            print("Failed to load model: \(error)")
        }
    }
    
    private func performInference(model: MLModel, text: String, state: String) -> String? {
        // Your existing inference logic here
        // Return suggestion string
        return "Suggested text based on \(state)"
    }
    
    private func scheduleCleanup() {
        DispatchQueue.main.asyncAfter(deadline: .now() + memoryTimeout) { [weak self] in
            guard let self = self else { return }
            
            if Date().timeIntervalSince(self.lastUsed) >= self.memoryTimeout {
                self.model = nil
                print("Model released due to inactivity")
            }
        }
    }
    
    deinit {
        model = nil
    }
}
