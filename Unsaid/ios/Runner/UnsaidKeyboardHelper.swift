import UIKit
import os.log

/// Helper class for detecting and managing keyboard extension status
class UnsaidKeyboardHelper {
    /// Bundle identifier for the Unsaid Keyboard extension
    static let keyboardBundleIdentifier = "com.example.unsaid.Unsaid"
    
    /// Shared UserDefaults for keyboard data sharing
    private static let sharedUserDefaults = UserDefaults(suiteName: "group.com.unsaid.keyboard")!

    /// Check if the Unsaid Keyboard is enabled in iOS Settings
    /// - Returns: True if the keyboard is enabled, false otherwise
    static func isKeyboardEnabled() -> Bool {
        // Check UserDefaults for AppleKeyboards
        guard let keyboards = UserDefaults.standard.array(forKey: "AppleKeyboards") as? [String] else {
            return false
        }

        // Look for our keyboard bundle identifier
        return keyboards.contains { keyboard in
            keyboard.contains(keyboardBundleIdentifier)
        }
    }

    /// Show alert with instructions to enable the keyboard
    /// - Parameter viewController: The view controller to present the alert from
    static func showEnableKeyboardInstructions(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Enable Unsaid Keyboard",
            message: """
            To get AI-powered communication coaching:

            1. Open Settings → General → Keyboard → Keyboards
            2. Tap 'Add New Keyboard…'
            3. Select 'Unsaid Keyboard'
            4. Enable 'Allow Full Access' for AI features
            """,
            preferredStyle: .alert
        )

        // Open Settings button
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            openKeyboardSettings()
        })

        viewController.present(alert, animated: true)
    }

    /// Open iOS Settings to the Keyboard section
    static func openKeyboardSettings() {
        // Try to open directly to Keyboard settings
        if let keyboardSettingsURL = URL(string: "App-Prefs:General&path=Keyboard/KEYBOARDS") {
            if UIApplication.shared.canOpenURL(keyboardSettingsURL) {
                UIApplication.shared.open(keyboardSettingsURL, options: [:], completionHandler: nil)
                return
            }
        }

        // Fallback to general settings
        if let generalSettingsURL = URL(string: "App-Prefs:General") {
            if UIApplication.shared.canOpenURL(generalSettingsURL) {
                UIApplication.shared.open(generalSettingsURL, options: [:], completionHandler: nil)
                return
            }
        }

        // Final fallback to main settings
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
    }

    /// Check keyboard status and show setup if needed
    /// - Parameter viewController: The view controller to present alerts from
    /// - Parameter completion: Callback with keyboard enabled status
    static func checkAndSetupKeyboard(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        let isEnabled = isKeyboardEnabled()

        if !isEnabled {
            showEnableKeyboardInstructions(from: viewController)
        }

        completion(isEnabled)
    }

    /// Request full access permissions for the keyboard
    static func requestFullAccess() {
        // Note: Full access can only be granted by user in Settings
        // This method serves as a placeholder for future permission requests
        openKeyboardSettings()
    }

    /// Log keyboard-related events for debugging
    /// - Parameters:
    ///   - event: The event name
    ///   - details: Additional event details
    static func logKeyboardEvent(_ event: String, details: [String: Any]? = nil) {
        #if DEBUG
            os_log("🎹 Keyboard Event: %@", log: .default, type: .debug, event)
            if let details = details {
                os_log("   Details: %@", log: .default, type: .debug, String(describing: details))
            }
        #endif
    }
}

/// Extension for keyboard status notifications
extension UnsaidKeyboardHelper {
    /// Notification name for keyboard status changes
    static let keyboardStatusChangedNotification = Notification.Name("UnsaidKeyboardStatusChanged")

    /// Start monitoring keyboard status changes
    static func startMonitoringKeyboardStatus() {
        // Monitor for app returning from background (when user might have changed settings)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            let isEnabled = isKeyboardEnabled()
            logKeyboardEvent("Status Check", details: ["enabled": isEnabled])

            // Post notification about status change
            NotificationCenter.default.post(
                name: keyboardStatusChangedNotification,
                object: nil,
                userInfo: ["enabled": isEnabled]
            )
        }
    }

    /// Stop monitoring keyboard status changes
    static func stopMonitoringKeyboardStatus() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    /// Push user preferences to keyboard extension for personalized coaching
    /// - Parameters:
    ///   - attachmentStyle: User's dominant attachment style
    ///   - communicationGoals: User's communication improvement goals
    ///   - coachingPreferences: Coaching sensitivity and frequency preferences
    static func updateKeyboardUserPreferences(
        attachmentStyle: String,
        communicationGoals: [String],
        coachingPreferences: [String: Any]
    ) {
        var userPreferences = sharedUserDefaults.dictionary(forKey: "user_preferences") ?? [:]
        
        userPreferences["attachment_style"] = attachmentStyle
        userPreferences["communication_goals"] = communicationGoals
        userPreferences["coaching_preferences"] = coachingPreferences
        userPreferences["last_update"] = Date().timeIntervalSince1970
        
        sharedUserDefaults.set(userPreferences, forKey: "user_preferences")
        
        logKeyboardEvent("User Preferences Updated", details: [
            "attachment_style": attachmentStyle,
            "goals_count": communicationGoals.count
        ])
    }
    
    /// Get keyboard usage statistics for insights dashboard
    /// - Returns: Dictionary with keyboard usage metrics
    static func getKeyboardUsageStats() -> [String: Any] {
        let interactions = sharedUserDefaults.array(forKey: "keyboard_interactions") as? [[String: Any]] ?? []
        let analytics = sharedUserDefaults.dictionary(forKey: "keyboard_analytics") ?? [:]
        
        let totalInteractions = interactions.count
        let lastInteraction = interactions.last?["timestamp"] as? TimeInterval
        let recentInteractions = interactions.filter { interaction in
            if let timestamp = interaction["timestamp"] as? TimeInterval {
                return Date(timeIntervalSince1970: timestamp).timeIntervalSinceNow > -86400 // Last 24 hours
            }
            return false
        }
        
        return [
            "total_interactions": totalInteractions,
            "recent_interactions": recentInteractions.count,
            "last_interaction": lastInteraction ?? 0,
            "is_actively_used": !recentInteractions.isEmpty,
            "analytics": analytics
        ]
    }
    
    /// Push coaching settings to keyboard extension
    /// - Parameters:
    ///   - sensitivity: Coaching sensitivity level (low, medium, high)
    ///   - focusAreas: Areas to focus coaching on
    ///   - enableRealTimeCoaching: Whether to enable real-time coaching
    static func updateCoachingSettings(
        sensitivity: String,
        focusAreas: [String],
        enableRealTimeCoaching: Bool
    ) {
        var coachingSettings = sharedUserDefaults.dictionary(forKey: "keyboard_coaching_settings") ?? [:]
        
        coachingSettings["sensitivity"] = sensitivity
        coachingSettings["focus_areas"] = focusAreas
        coachingSettings["real_time_coaching"] = enableRealTimeCoaching
        coachingSettings["last_update"] = Date().timeIntervalSince1970
        
        sharedUserDefaults.set(coachingSettings, forKey: "keyboard_coaching_settings")
        
        logKeyboardEvent("Coaching Settings Updated", details: [
            "sensitivity": sensitivity,
            "real_time": enableRealTimeCoaching
        ])
    }
    
    /// Check if keyboard extension has recent data
    /// - Returns: True if keyboard has been used recently
    static func hasRecentKeyboardActivity() -> Bool {
        let analytics = sharedUserDefaults.dictionary(forKey: "keyboard_analytics") ?? [:]
        
        if let lastInteraction = analytics["last_interaction"] as? TimeInterval {
            let timeSinceLastUse = Date().timeIntervalSince1970 - lastInteraction
            return timeSinceLastUse < 3600 // Within last hour
        }
        
        return false
    }
    
    /// Clear keyboard data (for privacy/reset)
    static func clearKeyboardData() {
        sharedUserDefaults.removeObject(forKey: "keyboard_interactions")
        sharedUserDefaults.removeObject(forKey: "keyboard_events")
        sharedUserDefaults.removeObject(forKey: "keyboard_analytics")
        
        logKeyboardEvent("Keyboard Data Cleared")
    }
    
    /// Update personality data for keyboard extension access
    /// - Parameters:
    ///   - attachmentStyle: User's attachment style
    ///   - communicationStyle: User's communication style
    ///   - personalityType: User's personality type
    ///   - testResults: Full test results dictionary
    static func updatePersonalityData(
        attachmentStyle: String,
        communicationStyle: String,
        personalityType: String,
        testResults: [String: Any]
    ) {
        // Write in extension format
        let extensionData = [
            "attachment_style": attachmentStyle,
            "communication_style": communicationStyle,
            "personality_type": personalityType,
            "dominant_type_label": "\(attachmentStyle.capitalized) \(communicationStyle.capitalized)",
            "last_update": Date().timeIntervalSince1970,
            "test_results": testResults
        ] as [String: Any]
        
        sharedUserDefaults.set(extensionData, forKey: "personality_data")
        
        // Also write in legacy format for backward compatibility
        sharedUserDefaults.set(attachmentStyle, forKey: "user_attachment_style")
        sharedUserDefaults.set(communicationStyle, forKey: "user_communication_style")
        sharedUserDefaults.set(personalityType, forKey: "user_personality_type")
        
        // Write test results
        sharedUserDefaults.set(testResults, forKey: "personality_test_results")
        
        logKeyboardEvent("Personality Data Updated", details: [
            "attachment_style": attachmentStyle,
            "communication_style": communicationStyle,
            "personality_type": personalityType
        ])
    }
    
    /// Add test personality data for keyboard extension testing
    /// This should be called from the main app after personality test completion
    static func addTestPersonalityData() {
        // Sample personality data for testing
        let testData = [
            "attachment_style": "secure",
            "communication_style": "direct",
            "personality_type": "analytical",
            "dominant_type_label": "Secure Communicator",
            "communication_preferences": [
                "prefers_direct": true,
                "needs_context": false,
                "responds_to_emotion": true
            ]
        ] as [String: Any]
        
        // Store in both formats for compatibility
        updatePersonalityData(
            attachmentStyle: "secure",
            communicationStyle: "direct",
            personalityType: "analytical",
            testResults: testData
        )
        
        print("✅ Added test personality data for keyboard extension")
    }
}
