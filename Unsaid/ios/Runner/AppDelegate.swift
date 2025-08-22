//
//  AppDelegate.swift
//  Unsaid
//
//  Host app AppDelegate with Flutter channels, no HostAppAIService dependency.
//  Uses App Group to read/write keyboard data and a handshake for enable/full-access.
//

import Flutter
import UIKit
import os.log

// MARK: - Shared App Group
enum AppGroup {
    static let id = "group.com.unsaid.shared" // <- use this EXACT ID in BOTH targets' entitlements
    static var defaults: UserDefaults {
        guard let ud = UserDefaults(suiteName: id) else {
            fatalError("App Group not configured: \(id)")
        }
        return ud
    }
}

// MARK: - Keyboard status handshake (what the keyboard writes)
struct KeyboardStatus {
    let enabled: Bool
    let fullAccess: Bool

    static func read() -> KeyboardStatus {
        let ud = AppGroup.defaults
        let lastSeen = ud.double(forKey: "kb_last_seen")
        let full = ud.bool(forKey: "kb_full_access_ok")
        let enabled = lastSeen > 0 && Date(timeIntervalSince1970: lastSeen)
            .timeIntervalSinceNow > -(7 * 24 * 60 * 60)
        return .init(enabled: enabled, fullAccess: full)
    }
}

// MARK: - Minimal helper for settings + keyboard bridge
enum UnsaidKeyboardHelper {
    static func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    /// Optional: write a payload for the keyboard to read, then ping via Darwin notify.
    static func sendDataToKeyboard(_ payload: [String: Any], key: String = "host_to_kb_payload") {
        let ud = AppGroup.defaults
        ud.set(payload, forKey: key)
        ud.set(Date().timeIntervalSince1970, forKey: "\(key)_ts")
        // ping (foreground-only optimization; won't wake a suspended extension)
        postDarwinNotify("com.unsaid.keyboard.hostping")
    }

    static func storeUserEmail(_ email: String) {
        AppGroup.defaults.set(email, forKey: "user_email")
        AppGroup.defaults.set(Date().timeIntervalSince1970, forKey: "user_email_ts")
    }
    static func clearUserEmail() {
        AppGroup.defaults.removeObject(forKey: "user_email")
        AppGroup.defaults.removeObject(forKey: "user_email_ts")
    }

    private static func postDarwinNotify(_ name: String) {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName(name as CFString), nil, nil, true)
    }
}

@main
@objc class AppDelegate: FlutterAppDelegate {

    // MARK: - Throttling / Cache for Insights
    private var lastInsightsCall: Date = .distantPast
    private let insightsThrottleInterval: TimeInterval = 5.0
    private var cachedInsights: [String: Any]?
    private var cacheTimestamp: Date = .distantPast
    private let cacheTimeout: TimeInterval = 30.0
    // MARK: - App lifecycle
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        GeneratedPluginRegistrant.register(with: self)

        // If you have a custom plugin:
        if let reg = registrar(forPlugin: "KeyboardDataSyncBridge") {
            KeyboardDataSyncBridge.register(with: reg)
        }

        guard let controller = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }

        // Channels
        setupKeyboardAnalyticsChannel(controller: controller)
        setupWebAPIChannel(controller: controller)
        setupKeyboardExtensionChannel(controller: controller)
        setupPersonalityDataChannel(controller: controller)
        setupUserEmailChannel(controller: controller)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: - Channels

    private func setupKeyboardAnalyticsChannel(controller: FlutterViewController) {
        let ch = FlutterMethodChannel(name: "com.unsaid/keyboard_analytics",
                                      binaryMessenger: controller.binaryMessenger)

        ch.setMethodCallHandler { [weak self] (call, result) in
            guard let self else { return }
            let ud = AppGroup.defaults

            switch call.method {
            case "getKeyboardAnalytics":
                if let data = ud.data(forKey: "keyboard_analytics"),
                   let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    result(obj)
                } else {
                    result([
                        "totalKeystrokes": 0,
                        "totalSessions": 0,
                        "averageSessionLength": 0.0,
                        "suggestionAcceptanceRate": 0.0,
                        "quickFixUsageCount": 0,
                        "toneChanges": 0,
                        "lastUpdated": Date().timeIntervalSince1970
                    ])
                }

            case "getKeyboardInteractions":
                if let data = ud.data(forKey: "keyboard_interactions"),
                   let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    result(arr)
                } else {
                    result([])
                }

            case "getKeyboardInsights":
                DispatchQueue.main.async {
                    let now = Date()
                    // throttle
                    if now.timeIntervalSince(self.lastInsightsCall) < self.insightsThrottleInterval,
                       let cached = self.cachedInsights,
                       now.timeIntervalSince(self.cacheTimestamp) < self.cacheTimeout {
                        result(cached)
                        return
                    }
                    self.lastInsightsCall = now

                    if let data = ud.data(forKey: "keyboard_insights"),
                       let insights = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        self.cachedInsights = insights
                        self.cacheTimestamp = now
                        result(insights)
                    } else {
                        let defaults: [String: Any] = [
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
                        self.cachedInsights = defaults
                        self.cacheTimestamp = now
                        result(defaults)
                    }
                }

            case "generateKeyboardInsights":
                ud.set(true, forKey: "should_generate_insights")
                ud.set(Date().timeIntervalSince1970, forKey: "insights_generation_requested")
                result(true)

            case "syncChildrenNames":
                if let args = call.arguments as? [String: Any],
                   let names = args["names"] as? [String] {
                    ud.set(names, forKey: "children_names")
                    ud.set(args["timestamp"], forKey: "children_names_timestamp")
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
        let ch = FlutterMethodChannel(name: "com.unsaid/web_api",
                                      binaryMessenger: controller.binaryMessenger)

        ch.setMethodCallHandler { (call, result) in
            #if DEBUG
            switch call.method {
            case "checkTrialStatus":
                result([
                    "success": true,
                    "userId": "test-admin-user",
                    "trial": [
                        "status": "admin_access",
                        "inTrial": true,
                        "isAdmin": true,
                        "availableFeatures": ["tone-analysis", "spell-check", "suggestions"]
                    ]
                ])

            case "startTrial", "checkFeatureAccess", "upgradeToPremium":
                result(true)

            case "getAPIStatus":
                // Simple stub since HostAppAIService was removed
                result([
                    "reachable": true,
                    "env": "debug",
                    "timestamp": Date().timeIntervalSince1970
                ])

            default:
                result(FlutterMethodNotImplemented)
            }
            #else
            result(FlutterError(code: "UNIMPLEMENTED", message: "Not available in production yet", details: nil))
            #endif
        }
    }
    
    private func setupKeyboardExtensionChannel(controller: FlutterViewController) {
        let ch = FlutterMethodChannel(name: "com.unsaid/keyboard_extension",
                                      binaryMessenger: controller.binaryMessenger)

        ch.setMethodCallHandler { (call, result) in
            switch call.method {
            case "isKeyboardEnabled":
                let s = KeyboardStatus.read()
                result(s.enabled)

            case "openKeyboardSettings":
                UnsaidKeyboardHelper.openAppSettings()
                result(true)

            case "sendToneAnalysis", "sendRealtimeToneAnalysis":
                if let payload = call.arguments as? [String: Any] {
                    UnsaidKeyboardHelper.sendDataToKeyboard(payload, key: "tone_payload")
                    result(true)
                } else {
                    result(false)
                }

            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // Bulk keyboard data channel (reads straight from App Group)
        let dataCh = FlutterMethodChannel(name: "com.unsaid/keyboard_data",
                                          binaryMessenger: controller.binaryMessenger)

        dataCh.setMethodCallHandler { (call, result) in
            let ud = AppGroup.defaults
            func readDict(_ key: String) -> [String: Any] {
                if let data = ud.data(forKey: key),
                   let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    return obj
                }
                return [:]
            }
            func readArray(_ key: String) -> [[String: Any]] {
                if let data = ud.data(forKey: key),
                   let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    return arr
                }
                return []
            }

            switch call.method {
            case "getKeyboardEvents":                result(readArray("keyboard_events"))
            case "getUserProfile":                   result(readDict("user_profile"))
            case "getCurrentAnalysis":               result(readDict("current_analysis"))
            case "getSessionAnalytics":              result(readDict("session_analytics"))
            case "getSuggestionAcceptanceAnalytics": result(readDict("suggestion_acceptance_analytics"))
            case "getKeyboardCoachingSettings":      result(readDict("keyboard_coaching_settings"))
            case "getSuggestionResponse":            result(readDict("suggestion_response"))
            case "getConversationHistory":           result(readArray("conversation_history"))
            case "getComprehensiveKeyboardData":
                let bundle: [String: Any] = [
                    "keyboard_events": readArray("keyboard_events"),
                    "user_profile": readDict("user_profile"),
                    "current_analysis": readDict("current_analysis"),
                    "session_analytics": readDict("session_analytics"),
                    "suggestion_acceptance_analytics": readDict("suggestion_acceptance_analytics"),
                    "keyboard_coaching_settings": readDict("keyboard_coaching_settings"),
                    "suggestion_response": readDict("suggestion_response"),
                    "conversation_history": readArray("conversation_history"),
                    "last_updated": Date().timeIntervalSince1970
                ]
                result(bundle)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    private func setupPersonalityDataChannel(controller: FlutterViewController) {
        let ch = FlutterMethodChannel(name: "com.unsaid/personality_data",
                                      binaryMessenger: controller.binaryMessenger)

        ch.setMethodCallHandler { (call, result) in
            let m = PersonalityDataManager.shared
            switch call.method {
            case "storePersonalityData":
                if let data = call.arguments as? [String: Any] {
                    m.storePersonalityDataFromFlutter(data); result(true)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid personality data format", details: nil))
                }

            case "storePersonalityTestResults":
                if let data = call.arguments as? [String: Any] {
                    m.storePersonalityTestResults(data); result(true)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid personality test results format", details: nil))
                }

            case "storePersonalityComponents":
                if let args = call.arguments as? [String: Any],
                   let attachmentStyle = args["attachmentStyle"] as? String,
                   let communicationPattern = args["communicationPattern"] as? String,
                   let conflictResolution = args["conflictResolution"] as? String,
                   let primaryPersonalityType = args["primaryPersonalityType"] as? String,
                   let typeLabel = args["typeLabel"] as? String,
                   let scores = args["scores"] as? [String: Int] {
                    m.storePersonalityComponents(
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

            case "getPersonalityData":            result(m.getPersonalityDataForFlutter())
            case "getPersonalityTestResults":     result(m.getPersonalityTestResults())
            case "getDominantPersonalityType":    result(m.getDominantPersonalityType())
            case "getPersonalityTypeLabel":       result(m.getPersonalityTypeLabel())
            case "getPersonalityScores":          result(m.getPersonalityScores())
            case "isPersonalityTestComplete":     result(m.isPersonalityTestComplete())
            case "generatePersonalityContext":    result(m.generatePersonalityContext())
            case "generatePersonalityContextDictionary": result(m.generatePersonalityContextDictionary())
            case "clearPersonalityData":          m.clearPersonalityData(); result(true)
            case "debugPrintPersonalityData":     m.debugPrintPersonalityData(); result(true)
            case "setTestPersonalityData":        m.setTestPersonalityData(); result(true)
            case "setUserEmotionalState":
                if let args = call.arguments as? [String: Any],
                   let state = args["state"] as? String,
                   let bucket = args["bucket"] as? String,
                   let label = args["label"] as? String {
                    m.setUserEmotionalState(state: state, bucket: bucket, label: label)
                    result(true)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid emotional state data", details: nil))
                }
            case "getUserEmotionalState":         result(m.getUserEmotionalState())
            case "getUserEmotionalBucket":        result(m.getUserEmotionalBucket())
            case "getUserEmotionalStateLabel":    result(m.getUserEmotionalStateLabel())
            case "isEmotionalStateFresh":         result(m.isEmotionalStateFresh())

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    private func setupUserEmailChannel(controller: FlutterViewController) {
        let ch = FlutterMethodChannel(name: "com.unsaid/user_email",
                                      binaryMessenger: controller.binaryMessenger)

        ch.setMethodCallHandler { (call, result) in
            switch call.method {
            case "storeUserEmail":
                if let args = call.arguments as? [String: Any],
                   let email = args["email"] as? String {
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
}