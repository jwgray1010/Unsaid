import Flutter
import UIKit
import Foundation

@objc public class KeyboardDataSyncBridge: NSObject, FlutterPlugin {
    
    // MARK: - Constants
    private static let channelName = "com.unsaid/keyboard_data_sync"
    private static let appGroupID = "group.com.example.unsaid"
    
    // MARK: - Plugin Registration
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let instance = KeyboardDataSyncBridge()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    // MARK: - Method Channel Handler
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("🔄 KeyboardDataSyncBridge: Handling method '\(call.method)'")
        
        switch call.method {
        case "getAllPendingKeyboardData":
            getAllPendingKeyboardData(result: result)
            
        case "getKeyboardStorageMetadata":
            getKeyboardStorageMetadata(result: result)
            
        case "clearAllPendingKeyboardData":
            clearAllPendingKeyboardData(result: result)
            
        case "getUserData":
            getUserData(result: result)
            
        case "getAPIData":
            getAPIData(result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Shared UserDefaults Access
    private var sharedUserDefaults: UserDefaults? {
        return UserDefaults(suiteName: Self.appGroupID)
    }
    
    // MARK: - Get All Pending Keyboard Data
    private func getAllPendingKeyboardData(result: @escaping FlutterResult) {
        guard let shared = sharedUserDefaults else {
            print("❌ KeyboardDataSyncBridge: Unable to access shared UserDefaults")
            result(FlutterError(code: "SHARED_STORAGE_ERROR", 
                              message: "Unable to access shared storage", 
                              details: nil))
            return
        }
        
        var allData: [String: Any] = [:]
        var totalItems = 0
        
        // Get interaction data
        if let interactionData = shared.array(forKey: "interaction_queue") as? [[String: Any]] {
            allData["interactions"] = interactionData
            totalItems += interactionData.count
            print("📥 Found \(interactionData.count) interactions")
        } else {
            allData["interactions"] = []
        }
        
        // Get tone data
        if let toneData = shared.array(forKey: "tone_queue") as? [[String: Any]] {
            allData["tone_data"] = toneData
            totalItems += toneData.count
            print("📥 Found \(toneData.count) tone analyses")
        } else {
            allData["tone_data"] = []
        }
        
        // Get suggestion data
        if let suggestionData = shared.array(forKey: "suggestion_queue") as? [[String: Any]] {
            allData["suggestions"] = suggestionData
            totalItems += suggestionData.count
            print("📥 Found \(suggestionData.count) suggestions")
        } else {
            allData["suggestions"] = []
        }
        
        // Get analytics data
        if let analyticsData = shared.array(forKey: "analytics_queue") as? [[String: Any]] {
            allData["analytics"] = analyticsData
            totalItems += analyticsData.count
            print("📥 Found \(analyticsData.count) analytics items")
        } else {
            allData["analytics"] = []
        }
        
        // Get API response data (from our Vercel APIs)
        if let apiSuggestionsData = shared.array(forKey: "api_suggestions_queue") as? [[String: Any]] {
            allData["api_suggestions"] = apiSuggestionsData
            totalItems += apiSuggestionsData.count
            print("📥 Found \(apiSuggestionsData.count) API suggestions")
        } else {
            allData["api_suggestions"] = []
        }
        
        if let apiTrialData = shared.array(forKey: "api_trial_status_queue") as? [[String: Any]] {
            allData["api_trial_status"] = apiTrialData
            totalItems += apiTrialData.count
            print("📥 Found \(apiTrialData.count) API trial status items")
        } else {
            allData["api_trial_status"] = []
        }
        
        // Add metadata
        let metadata: [String: Any] = [
            "total_items": totalItems,
            "sync_timestamp": Date().timeIntervalSince1970,
            "app_group_id": Self.appGroupID,
            "has_pending_data": totalItems > 0
        ]
        allData["metadata"] = metadata
        
        print("✅ KeyboardDataSyncBridge: Retrieved \(totalItems) total items")
        result(totalItems > 0 ? allData : nil)
    }
    
    // MARK: - Get Storage Metadata
    private func getKeyboardStorageMetadata(result: @escaping FlutterResult) {
        guard let shared = sharedUserDefaults else {
            result(FlutterError(code: "SHARED_STORAGE_ERROR", 
                              message: "Unable to access shared storage", 
                              details: nil))
            return
        }
        
        let interactionCount = (shared.array(forKey: "interaction_queue") as? [[String: Any]])?.count ?? 0
        let toneCount = (shared.array(forKey: "tone_queue") as? [[String: Any]])?.count ?? 0
        let suggestionCount = (shared.array(forKey: "suggestion_queue") as? [[String: Any]])?.count ?? 0
        let analyticsCount = (shared.array(forKey: "analytics_queue") as? [[String: Any]])?.count ?? 0
        let apiSuggestionsCount = (shared.array(forKey: "api_suggestions_queue") as? [[String: Any]])?.count ?? 0
        let apiTrialCount = (shared.array(forKey: "api_trial_status_queue") as? [[String: Any]])?.count ?? 0
        
        let totalItems = interactionCount + toneCount + suggestionCount + analyticsCount + apiSuggestionsCount + apiTrialCount
        
        let metadata: [String: Any] = [
            "interaction_count": interactionCount,
            "tone_count": toneCount,
            "suggestion_count": suggestionCount,
            "analytics_count": analyticsCount,
            "api_suggestions_count": apiSuggestionsCount,
            "api_trial_count": apiTrialCount,
            "total_items": totalItems,
            "has_pending_data": totalItems > 0,
            "last_checked": Date().timeIntervalSince1970
        ]
        
        result(metadata)
    }
    
    // MARK: - Clear All Pending Data
    private func clearAllPendingKeyboardData(result: @escaping FlutterResult) {
        guard let shared = sharedUserDefaults else {
            result(FlutterError(code: "SHARED_STORAGE_ERROR", 
                              message: "Unable to access shared storage", 
                              details: nil))
            return
        }
        
        // Clear all queues
        shared.removeObject(forKey: "interaction_queue")
        shared.removeObject(forKey: "tone_queue")
        shared.removeObject(forKey: "suggestion_queue")
        shared.removeObject(forKey: "analytics_queue")
        shared.removeObject(forKey: "api_suggestions_queue")
        shared.removeObject(forKey: "api_trial_status_queue")
        
        // Synchronize changes
        shared.synchronize()
        
        print("✅ KeyboardDataSyncBridge: Cleared all pending keyboard data")
        result(true)
    }
    
    // MARK: - Get User Data
    private func getUserData(result: @escaping FlutterResult) {
        guard let shared = sharedUserDefaults else {
            result(FlutterError(code: "SHARED_STORAGE_ERROR", 
                              message: "Unable to access shared storage", 
                              details: nil))
            return
        }
        
        let userData: [String: Any?] = [
            "user_id": shared.string(forKey: "user_id") ?? shared.string(forKey: "userId"),
            "user_email": shared.string(forKey: "user_email") ?? shared.string(forKey: "userEmail"),
            "attachment_style": shared.string(forKey: "attachment_style"),
            "personality_data": shared.dictionary(forKey: "personality_data")
        ]
        
        result(userData)
    }
    
    // MARK: - Get API Data (Direct Access to API Results)
    private func getAPIData(result: @escaping FlutterResult) {
        guard let shared = sharedUserDefaults else {
            result(FlutterError(code: "SHARED_STORAGE_ERROR", 
                              message: "Unable to access shared storage", 
                              details: nil))
            return
        }
        
        var apiData: [String: Any] = [:]
        
        // Get the latest API suggestion result
        if let latestSuggestion = shared.dictionary(forKey: "latest_api_suggestion") {
            apiData["latest_suggestion"] = latestSuggestion
        }
        
        // Get the latest trial status result
        if let latestTrialStatus = shared.dictionary(forKey: "latest_trial_status") {
            apiData["latest_trial_status"] = latestTrialStatus
        }
        
        // Get API response history
        if let suggestionHistory = shared.array(forKey: "api_suggestion_history") as? [[String: Any]] {
            apiData["suggestion_history"] = suggestionHistory
        }
        
        result(apiData.isEmpty ? nil : apiData)
    }
}
