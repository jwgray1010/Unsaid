//
//  UnsaidKeyboardHelper.swift
//  Unsaid
//
//  Simple helper that provides compatibility methods
//  Main implementation is now in AppDelegate.swift
//

import Foundation
import UIKit

class UnsaidKeyboardHelper {
    
    // MARK: - App Group Configuration
    static let appGroupID = "group.com.unsaid.shared"
    static let appGroupIdentifier = appGroupID // Legacy compatibility
    
    // MARK: - Keyboard Status Detection (App Group Handshake)
    static func isKeyboardEnabled() -> Bool {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return false }
        let lastSeen = defaults.double(forKey: "kb_last_seen")
        guard lastSeen > 0 else { return false }
        
        let lastSeenDate = Date(timeIntervalSince1970: lastSeen)
        let daysSinceLastSeen = Date().timeIntervalSince(lastSeenDate) / (24 * 60 * 60)
        return daysSinceLastSeen < 7 // Consider enabled if seen within 7 days
    }
    
    static func hasFullAccess() -> Bool {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return false }
        return defaults.bool(forKey: "kb_full_access_ok")
    }

    
    // MARK: - Settings Navigation
    static func openKeyboardSettings() {
        openAppSettings()
    }
    
    static func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Legacy Compatibility Methods
    static func showEnableKeyboardInstructions(from viewController: UIViewController) {
        let isEnabled = isKeyboardEnabled()
        let hasAccess = hasFullAccess()
        
        let title: String
        let message: String
        
        if !isEnabled {
            title = "Enable Unsaid Keyboard"
            message = """
            To get AI-powered communication coaching:

            1. Open Settings → General → Keyboard → Keyboards
            2. Tap 'Add New Keyboard…'
            3. Select 'Unsaid Keyboard'
            4. Enable 'Allow Full Access' for AI features
            """
        } else if !hasAccess {
            title = "Enable Full Access"
            message = """
            To unlock AI coaching features:

            1. Open Settings → General → Keyboard → Keyboards
            2. Tap 'Unsaid Keyboard'
            3. Enable 'Allow Full Access'
            
            This is required for personalized coaching and tone analysis.
            """
        } else {
            // Already enabled with full access
            return
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            openKeyboardSettings()
        })
        alert.addAction(UIAlertAction(title: "Later", style: .cancel))
        viewController.present(alert, animated: true)
    }
    
    static func checkAndSetupKeyboard(from viewController: UIViewController, completion: @escaping (Bool, Bool) -> Void) {
        let isEnabled = isKeyboardEnabled()
        let hasAccess = hasFullAccess()

        if !isEnabled || !hasAccess {
            showEnableKeyboardInstructions(from: viewController)
        }

        completion(isEnabled, hasAccess)
    }
    
    static func requestFullAccess() {
        openAppSettings()
    }
    
    // MARK: - Status Summary
    static func getKeyboardStatus() -> [String: Any] {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            return [
                "enabled": false,
                "fullAccess": false,
                "appGroupID": appGroupID,
                "error": "App Group not accessible"
            ]
        }
        
        let lastSeen = defaults.double(forKey: "kb_last_seen")
        
        return [
            "enabled": isKeyboardEnabled(),
            "fullAccess": hasFullAccess(),
            "appGroupID": appGroupID,
            "lastSeen": lastSeen,
            "lastSeenDate": lastSeen > 0 ? Date(timeIntervalSince1970: lastSeen) : "Never",
            "lastChecked": Date().timeIntervalSince1970
        ]
    }
}
