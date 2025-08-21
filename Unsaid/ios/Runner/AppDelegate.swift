//
//  AppDelegate.swift
//  Unsaid
//
//  Simplified App delegate for Unsaid app with web API integration
//  Removed local trial management, access control, and subscription management
//  All user authentication and feature gating now handled by web API
//

import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    // MARK: - Constants
    private let appGroupId = "group.com.example.unsaid.shared"
    
    // MARK: - Throttling Properties
    private var lastInsightsCall: Date = Date.distantPast
    private let insightsThrottleInterval: TimeInterval = 5.0 // Only allow insights calls every 5 seconds
    private var cachedInsights: [String: Any]?
    private var cacheTimestamp: Date = Date.distantPast
    private let cacheTimeout: TimeInterval = 30.0 // Cache for 30 seconds
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        GeneratedPluginRegistrant.register(with: self)
        
        // Register KeyboardDataSyncBridge for safe data retrieval
        KeyboardDataSyncBridge.register(with: registrar(forPlugin: "KeyboardDataSyncBridge")!)
        
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }
        
        // Setup admin credentials for keyboard extension (DEBUG only)
        #if DEBUG
        UnsaidKeyboardHelper.setupAdminCredentialsForKeyboard()
        
        // Test API integration (development only)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            HostAppAIService.shared.debugTestAPIConnectivity()
        }
        #endif
        
        // Setup Flutter channels
        setupKeyboardAnalyticsChannel(controller: controller)
        setupWebAPIChannel(controller: controller)
        setupKeyboardExtensionChannel(controller: controller)
        setupPersonalityDataChannel(controller: controller)
        setupUserEmailChannel(controller: controller)
        
        // Read keyboard extension data once when app opens (no constant polling)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            let keyboardData = HostAppAIService.shared.readKeyboardDataOnDemand()
            if !keyboardData.isEmpty {
                HostAppAIService.shared.sendInsightsToFlutter()
            }
        }
        
        #if DEBUG
        // Test keyboard data bridge connectivity (DEBUG only)
        testKeyboardDataBridge()
        #endif
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: - Channel Setup Methods
    private func setupKeyboardAnalyticsChannel(controller: FlutterViewController) {
        let keyboardChannel = FlutterMethodChannel(
            name: "com.unsaid/keyboard_analytics",
            binaryMessenger: controller.binaryMessenger
        )
        
        keyboardChannel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            let userDefaults = UserDefaults(suiteName: self.appGroupId)
            
            switch call.method {
            case "getKeyboardAnalytics":
                if let data = userDefaults?.data(forKey: "keyboard_analytics"),
                   let analytics = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    result(analytics)
                } else {
                    let defaultAnalytics: [String: Any] = [
                        "totalKeystrokes": 0,
                        "totalSessions": 0,
                        "averageSessionLength": 0.0,
                        "suggestionAcceptanceRate": 0.0,
                        "quickFixUsageCount": 0,
                        "toneChanges": 0,
                        "lastUpdated": Date().timeIntervalSince1970
                    ]
                    result(defaultAnalytics)
                }
                
            case "getKeyboardInteractions":
                if let data = userDefaults?.data(forKey: "keyboard_interactions"),
                   let interactions = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    result(interactions)
                } else {
                    result([])
                }
                
            case "getKeyboardInsights":
                DispatchQueue.main.async {
                    let now = Date()
                    if now.timeIntervalSince(self.lastInsightsCall) < self.insightsThrottleInterval {
                        if let cached = self.cachedInsights,
                           now.timeIntervalSince(self.cacheTimestamp) < self.cacheTimeout {
                            result(cached)
                            return
                        }
                    }
                    
                    self.lastInsightsCall = now
                    
                    if let data = userDefaults?.data(forKey: "keyboard_insights"),
                       let insights = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        self.cachedInsights = insights
                        self.cacheTimestamp = now
                        result(insights)
                    } else {
                        let defaultInsights: [String: Any] = [
                            "dominantTone": "neutral",
                            "toneTrend": "stable",
                            "improvementScore": 0.0,
                            "mostActiveHours": [9, 14, 18],
                            "averageSessionLength": 0.0,
                            "quickFixUsage": 0.0,
                            "typingEfficiency": 0.0,
                            "suggestionHelpfulness": 0.0,
                            "communicationStyle": "balanced",
                            "relationshipContextUsage": [:]
                        ]
                        self.cachedInsights = defaultInsights
                        self.cacheTimestamp = now
                        result(defaultInsights)
                    }
                }
                
            case "generateKeyboardInsights":
                userDefaults?.set(true, forKey: "should_generate_insights")
                userDefaults?.set(Date().timeIntervalSince1970, forKey: "insights_generation_requested")
                result(true)
                
            case "syncChildrenNames":
                if let arguments = call.arguments as? [String: Any],
                   let names = arguments["names"] as? [String] {
                    userDefaults?.set(names, forKey: "children_names")
                    userDefaults?.set(arguments["timestamp"], forKey: "children_names_timestamp")
                    result(true)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid children names data", details: nil))
                }
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    private func setupWebAPIChannel(controller: FlutterViewController) {
        let apiChannel = FlutterMethodChannel(
            name: "com.unsaid/web_api",
            binaryMessenger: controller.binaryMessenger
        )
        
        apiChannel.setMethodCallHandler { (call, result) in
            #if DEBUG
            switch call.method {
            case "checkTrialStatus":
                let testTrialData: [String: Any] = [
                    "success": true,
                    "userId": "test-admin-user",
                    "trial": [
                        "status": "admin_access",
                        "inTrial": true,
                        "isAdmin": true,
                        "availableFeatures": ["tone-analysis", "spell-check", "suggestions"]
                    ]
                ]
                result(testTrialData)
                
            case "startTrial", "checkFeatureAccess", "upgradeToPremium":
                result(true)
                
            case "getAPIStatus":
                let status = HostAppAIService.shared.getAPIStatus()
                result(status)
                
            default:
                result(FlutterMethodNotImplemented)
            }
            #else
            result(FlutterError(code: "UNIMPLEMENTED", message: "Not available in production yet", details: nil))
            #endif
        }
    }
    
    private func setupKeyboardExtensionChannel(controller: FlutterViewController) {
        let keyboardExtensionChannel = FlutterMethodChannel(
            name: "com.unsaid/keyboard_extension",
            binaryMessenger: controller.binaryMessenger
        )
        
        keyboardExtensionChannel.setMethodCallHandler { (call, result) in
            switch call.method {
            case "isKeyboardEnabled":
                let isEnabled = UnsaidKeyboardHelper.appearsKeyboardEnabled()
                result(isEnabled)
                
            case "openKeyboardSettings":
                UnsaidKeyboardHelper.openKeyboardSettings()
                result(true)
                
            case "sendToneAnalysis", "sendRealtimeToneAnalysis":
                if let payload = call.arguments as? [String: Any] {
                    UnsaidKeyboardHelper.sendDataToKeyboard(payload)
                    result(true)
                } else {
                    result(false)
                }
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        // Additional channel for bulk keyboard data
        let keyboardDataChannel = FlutterMethodChannel(
            name: "com.unsaid/keyboard_data",
            binaryMessenger: controller.binaryMessenger
        )
        
        keyboardDataChannel.setMethodCallHandler { (call, result) in
            switch call.method {
            case "getKeyboardEvents":
                result(HostAppAIService.shared.getKeyboardEvents())
                
            case "getUserProfile":
                result(HostAppAIService.shared.getUserProfile())
                
            case "getCurrentAnalysis":
                result(HostAppAIService.shared.getCurrentAnalysis())
                
            case "getSessionAnalytics":
                result(HostAppAIService.shared.getSessionAnalytics())
                
            case "getSuggestionAcceptanceAnalytics":
                result(HostAppAIService.shared.getSuggestionAcceptanceAnalytics())
                
            case "getKeyboardCoachingSettings":
                result(HostAppAIService.shared.getKeyboardCoachingSettings())
                
            case "getSuggestionResponse":
                result(HostAppAIService.shared.getSuggestionResponse())
                
            case "getConversationHistory":
                result(HostAppAIService.shared.getConversationHistory())
                
            case "getComprehensiveKeyboardData":
                let comprehensiveData: [String: Any] = [
                    "keyboard_events": HostAppAIService.shared.getKeyboardEvents(),
                    "user_profile": HostAppAIService.shared.getUserProfile(),
                    "current_analysis": HostAppAIService.shared.getCurrentAnalysis(),
                    "session_analytics": HostAppAIService.shared.getSessionAnalytics(),
                    "suggestion_acceptance_analytics": HostAppAIService.shared.getSuggestionAcceptanceAnalytics(),
                    "keyboard_coaching_settings": HostAppAIService.shared.getKeyboardCoachingSettings(),
                    "suggestion_response": HostAppAIService.shared.getSuggestionResponse(),
                    "conversation_history": HostAppAIService.shared.getConversationHistory(),
                    "last_updated": Date().timeIntervalSince1970
                ]
                result(comprehensiveData)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    private func setupPersonalityDataChannel(controller: FlutterViewController) {
        let personalityChannel = FlutterMethodChannel(
            name: "com.unsaid/personality_data",
            binaryMessenger: controller.binaryMessenger
        )
        
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
                
            case "storePersonalityTestResults":
                if let data = call.arguments as? [String: Any] {
                    personalityManager.storePersonalityTestResults(data)
                    result(true)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid personality test results format", details: nil))
                }
                
            case "storePersonalityComponents":
                if let arguments = call.arguments as? [String: Any],
                   let attachmentStyle = arguments["attachmentStyle"] as? String,
                   let communicationPattern = arguments["communicationPattern"] as? String,
                   let conflictResolution = arguments["conflictResolution"] as? String,
                   let primaryPersonalityType = arguments["primaryPersonalityType"] as? String,
                   let typeLabel = arguments["typeLabel"] as? String,
                   let scores = arguments["scores"] as? [String: Int] {
                    personalityManager.storePersonalityComponents(
                        attachmentStyle: attachmentStyle,
                        communicationPattern: communicationPattern,
                        conflictResolution: conflictResolution,
                        primaryPersonalityType: primaryPersonalityType,
                        typeLabel: typeLabel,
                        scores: scores
                    )
                    result(true)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid personality components data", details: nil))
                }
                
            case "getPersonalityData":
                result(personalityManager.getPersonalityDataForFlutter())
                
            case "getPersonalityTestResults":
                result(personalityManager.getPersonalityTestResults())
                
            case "getDominantPersonalityType":
                result(personalityManager.getDominantPersonalityType())
                
            case "getPersonalityTypeLabel":
                result(personalityManager.getPersonalityTypeLabel())
                
            case "getPersonalityScores":
                result(personalityManager.getPersonalityScores())
                
            case "isPersonalityTestComplete":
                result(personalityManager.isPersonalityTestComplete())
                
            case "generatePersonalityContext":
                result(personalityManager.generatePersonalityContext())
                
            case "generatePersonalityContextDictionary":
                result(personalityManager.generatePersonalityContextDictionary())
                
            case "clearPersonalityData":
                personalityManager.clearPersonalityData()
                result(true)
                
            case "debugPrintPersonalityData":
                personalityManager.debugPrintPersonalityData()
                result(true)
                
            case "setTestPersonalityData":
                personalityManager.setTestPersonalityData()
                result(true)
                
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
                result(personalityManager.getUserEmotionalState())
                
            case "getUserEmotionalBucket":
                result(personalityManager.getUserEmotionalBucket())
                
            case "getUserEmotionalStateLabel":
                result(personalityManager.getUserEmotionalStateLabel())
                
            case "isEmotionalStateFresh":
                result(personalityManager.isEmotionalStateFresh())
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    private func setupUserEmailChannel(controller: FlutterViewController) {
        let userEmailChannel = FlutterMethodChannel(
            name: "com.unsaid/user_email",
            binaryMessenger: controller.binaryMessenger
        )
        
        userEmailChannel.setMethodCallHandler { (call, result) in
            switch call.method {
            case "storeUserEmail":
                if let arguments = call.arguments as? [String: Any],
                   let email = arguments["email"] as? String {
                    UnsaidKeyboardHelper.storeUserEmail(email)
                    result(true)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid email data", details: nil))
                }
                
            case "clearUserEmail":
                UnsaidKeyboardHelper.clearUserEmail()
                result(true)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    // MARK: - Debug Methods
    private func testKeyboardDataBridge() {
        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }
            if let controller = self.window?.rootViewController as? FlutterViewController {
                let testChannel = FlutterMethodChannel(
                    name: "com.unsaid/keyboard_data",
                    binaryMessenger: controller.binaryMessenger
                )
                testChannel.invokeMethod("getKeyboardEvents") { result in
                    if let events = result as? [[String: Any]] {
                        print("✅ Keyboard data bridge test successful: \(events.count) events")
                    } else {
                        print("❌ Keyboard data bridge test failed: \(String(describing: result))")
                    }
                }
            }
        }
        #endif
    }
}