/// App delegate for Unsaid app with keyboard analytics and personality data integration
import Flutter
import UIKit

// Add reference to HostAppAIService (assuming it's in the same bundle)
// If in a separate framework, import the appropriate module

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        
        // Start monitoring for keyboard AI requests
        HostAppAIService.shared.startMonitoring()
        
        // Setup keyboard analytics channel
        let keyboardChannel = FlutterMethodChannel(name: "com.unsaid/keyboard_analytics", binaryMessenger: controller.binaryMessenger)
        keyboardChannel.setMethodCallHandler { (call, result) in
            if call.method == "getKeyboardAnalytics" {
                let userDefaults = UserDefaults(suiteName: "group.com.unsaid.app.shared")
                let analytics = userDefaults?.dictionary(forKey: "keyboard_analytics") ?? [:]
                result(analytics)
            } else if call.method == "getKeyboardInteractions" {
                let userDefaults = UserDefaults(suiteName: "group.com.unsaid.app.shared")
                let interactions = userDefaults?.array(forKey: "keyboard_interactions") ?? []
                result(interactions)
            } else if call.method == "syncChildrenNames" {
                if let arguments = call.arguments as? [String: Any],
                   let names = arguments["names"] as? [String] {
                    let userDefaults = UserDefaults(suiteName: "group.com.unsaid.app.shared")
                    userDefaults?.set(names, forKey: "children_names")
                    userDefaults?.set(arguments["timestamp"], forKey: "children_names_timestamp")
                    print("✅ Children names synced to shared UserDefaults: \(names)")
                    result(true)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid children names data", details: nil))
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        
        // Setup personality data channel
        let personalityChannel = FlutterMethodChannel(name: "com.unsaid/personality_data", binaryMessenger: controller.binaryMessenger)
        personalityChannel.setMethodCallHandler { (call, result) in
            let personalityManager = PersonalityDataManager.shared
            
            switch call.method {
            case "storePersonalityData":
                if let data = call.arguments as? [String: Any] {
                    personalityManager.storePersonalityDataFromFlutter(data)
                    result(true)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid personality data format", details: nil))
                }
                
            case "getPersonalityData":
                let personalityData = personalityManager.getPersonalityDataForFlutter()
                result(personalityData)
                
            case "isPersonalityTestComplete":
                let isComplete = personalityManager.isPersonalityTestComplete()
                result(isComplete)
                
            case "clearPersonalityData":
                personalityManager.clearPersonalityData()
                result(true)
                
            case "debugPersonalityData":
                personalityManager.debugPrintPersonalityData()
                result(true)
                
            case "addTestPersonalityData":
                UnsaidKeyboardHelper.addTestPersonalityData()
                result(true)
                
            // MARK: - Emotional State Methods (for AI Bucket System)
            case "setUserEmotionalState":
                if let arguments = call.arguments as? [String: Any],
                   let state = arguments["state"] as? String,
                   let bucket = arguments["bucket"] as? String,
                   let label = arguments["label"] as? String {
                    personalityManager.setUserEmotionalState(state: state, bucket: bucket, label: label)
                    result(true)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid emotional state data", details: nil))
                }
                
            case "getUserEmotionalState":
                let state = personalityManager.getUserEmotionalState()
                result(state)
                
            case "getUserEmotionalBucket":
                let bucket = personalityManager.getUserEmotionalBucket()
                result(bucket)
                
            case "getUserEmotionalStateLabel":
                let label = personalityManager.getUserEmotionalStateLabel()
                result(label)
                
            case "isEmotionalStateFresh":
                let isFresh = personalityManager.isEmotionalStateFresh()
                result(isFresh)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
