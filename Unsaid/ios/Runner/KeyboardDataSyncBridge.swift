import UIKit
import Flutter

/// Native iOS bridge connecting SafeKeyboardDataStorage to Flutter app
/// Handles method channel communication for safe keyboard data retrieval
@objc class KeyboardDataSyncBridge: NSObject, FlutterPlugin {
    
    // MARK: - Flutter Plugin Registration
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.unsaid/keyboard_data_sync",
            binaryMessenger: registrar.messenger()
        )
        let instance = KeyboardDataSyncBridge()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    // MARK: - Method Channel Handler
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getAllPendingKeyboardData":
            getAllPendingKeyboardData(result: result)
            
        case "getKeyboardStorageMetadata":
            getKeyboardStorageMetadata(result: result)
            
        case "clearAllPendingKeyboardData":
            clearAllPendingKeyboardData(result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Data Retrieval Methods
    
    /// Get all pending keyboard data from SafeKeyboardDataStorage
    private func getAllPendingKeyboardData(result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Get all data from SafeKeyboardDataStorage using correct method
            let allPendingData = SafeKeyboardDataStorage.shared.getAllPendingData()
            
            // Build comprehensive response with metadata
            let responseData: [String: Any] = [
                "interactions": allPendingData["interactions"] ?? [],
                "tone_data": allPendingData["tone_data"] ?? [],
                "suggestions": allPendingData["suggestions"] ?? [],
                "analytics": allPendingData["analytics"] ?? [],
                "metadata": [
                    "sync_timestamp": Date().timeIntervalSince1970,
                    "total_interactions": (allPendingData["interactions"] as? [[String: Any]])?.count ?? 0,
                    "total_tone_data": (allPendingData["tone_data"] as? [[String: Any]])?.count ?? 0,
                    "total_suggestions": (allPendingData["suggestions"] as? [[String: Any]])?.count ?? 0,
                    "total_analytics": (allPendingData["analytics"] as? [[String: Any]])?.count ?? 0,
                    "app_group_id": "group.com.example.unsaid.shared",
                    "source": "SafeKeyboardDataStorage"
                ]
            ]
            
            DispatchQueue.main.async {
                let interactions = allPendingData["interactions"] as? [[String: Any]] ?? []
                let toneData = allPendingData["tone_data"] as? [[String: Any]] ?? []
                let suggestions = allPendingData["suggestions"] as? [[String: Any]] ?? []
                let analytics = allPendingData["analytics"] as? [[String: Any]] ?? []
                
                if !interactions.isEmpty || !toneData.isEmpty || !suggestions.isEmpty || !analytics.isEmpty {
                    result(responseData)
                } else {
                    result(nil) // No data available
                }
            }
        }
    }
    
    /// Get metadata about keyboard storage without retrieving data
    private func getKeyboardStorageMetadata(result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .utility).async {
            let metadata = SafeKeyboardDataStorage.shared.getStorageMetadata()
            
            DispatchQueue.main.async {
                result(metadata)
            }
        }
    }
    
    /// Clear all pending keyboard data after successful sync
    private func clearAllPendingKeyboardData(result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .utility).async {
            SafeKeyboardDataStorage.shared.clearAllPendingData()
            
            DispatchQueue.main.async {
                result(true)
            }
        }
    }
}

/// Extension removed - using existing SafeKeyboardDataStorage methods
