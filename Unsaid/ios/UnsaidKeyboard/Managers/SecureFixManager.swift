//
//  SecureFixManager.swift
//  UnsaidKeyboard
//
//  Manages secure fix functionality and daily usage limits
//

import Foundation
import UIKit
import os.log

protocol SecureFixManagerDelegate: AnyObject {
    func getOpenAIAPIKey() -> String
    func getCurrentTextForAnalysis() -> String
    func replaceCurrentMessage(with newText: String)
    func buildUserProfileForSecureFix() -> [String: Any]
    func showUsageLimitAlert(message: String)
}

final class SecureFixManager {
    weak var delegate: SecureFixManagerDelegate?
    
    private let logger = Logger(subsystem: "com.example.unsaid.unsaid.UnsaidKeyboard", category: "SecureFixManager")
    
    // Daily Usage Tracking
    private let maxDailySecureFixUses = 10
    private let secureFixUsageKey = "SecureFixDailyUsage"
    private let secureFixDateKey = "SecureFixUsageDate"
    
    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: "group.com.example.unsaid")
    }
    
    init() {}
    
    // MARK: - Public Interface
    
    func canUseSecureFix() -> Bool {
        guard let defaults = sharedDefaults else { return false }
        
        let today = Calendar.current.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: today)
        
        let storedDateString = defaults.string(forKey: secureFixDateKey) ?? ""
        let currentUsageCount = defaults.integer(forKey: secureFixUsageKey)
        
        // If it's a new day, reset the counter
        if storedDateString != todayString {
            defaults.set(0, forKey: secureFixUsageKey)
            defaults.set(todayString, forKey: secureFixDateKey)
            return true
        }
        
        // Check if under daily limit
        return currentUsageCount < maxDailySecureFixUses
    }
    
    func getRemainingSecureFixUses() -> Int {
        guard let defaults = sharedDefaults else { return 0 }
        
        let today = Calendar.current.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: today)
        
        let storedDateString = defaults.string(forKey: secureFixDateKey) ?? ""
        let currentUsageCount = defaults.integer(forKey: secureFixUsageKey)
        
        // If it's a new day, reset and return max
        if storedDateString != todayString {
            defaults.set(0, forKey: secureFixUsageKey)
            defaults.set(todayString, forKey: secureFixDateKey)
            return maxDailySecureFixUses
        }
        
        return max(0, maxDailySecureFixUses - currentUsageCount)
    }
    
    func handleQuickFix() {
        // Check usage limits
        guard canUseSecureFix() else {
            let remaining = getRemainingSecureFixUses()
            let message = remaining > 0 
                ? "You have \(remaining) Secure Fix uses remaining today."
                : "You've reached your daily limit of \(maxDailySecureFixUses) Secure Fix uses. Try again tomorrow."
            delegate?.showUsageLimitAlert(message: message)
            return
        }
        
        // Get current text
        let currentText = delegate?.getCurrentTextForAnalysis() ?? ""
        guard !currentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            delegate?.showUsageLimitAlert(message: "Please type a message first to use Secure Fix.")
            return
        }
        
        // Increment usage and call OpenAI
        incrementSecureFixUsage()
        callOpenAI(text: currentText) { [weak self] result in
            DispatchQueue.main.async {
                if let improvedText = result {
                    self?.delegate?.replaceCurrentMessage(with: improvedText)
                } else {
                    self?.delegate?.showUsageLimitAlert(message: "Unable to improve message. Please try again.")
                }
            }
        }
    }
    
    // MARK: - Private Implementation
    
    private func incrementSecureFixUsage() {
        guard let defaults = sharedDefaults else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: today)
        
        let storedDateString = defaults.string(forKey: secureFixDateKey) ?? ""
        var currentUsageCount = defaults.integer(forKey: secureFixUsageKey)
        
        // If it's a new day, reset the counter
        if storedDateString != todayString {
            currentUsageCount = 0
            defaults.set(todayString, forKey: secureFixDateKey)
        }
        
        // Increment usage count
        currentUsageCount += 1
        defaults.set(currentUsageCount, forKey: secureFixUsageKey)
        
        logger.info("Secure Fix used: \(currentUsageCount)/\(maxDailySecureFixUses) for today")
    }
    
    private func callOpenAI(text: String, completion: @escaping (String?) -> Void) {
        guard let apiKey = delegate?.getOpenAIAPIKey(), !apiKey.isEmpty else {
            logger.error("OpenAI API key not found")
            completion(nil)
            return
        }
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let userProfile = delegate?.buildUserProfileForSecureFix() ?? [:]
        let profileContext = userProfile.isEmpty ? "" : "User profile: \(userProfile). "
        
        let payload: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                [
                    "role": "system",
                    "content": "\(profileContext)You are a helpful communication assistant. Improve the user's message to be more clear, kind, and effective while maintaining their intended meaning and tone. Return only the improved message, no explanations."
                ],
                [
                    "role": "user", 
                    "content": text
                ]
            ],
            "max_tokens": 200,
            "temperature": 0.3
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            logger.error("Failed to serialize request: \(error)")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                self?.logger.error("OpenAI request failed: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                self?.logger.error("No data received from OpenAI")
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
                } else {
                    self?.logger.error("Unexpected OpenAI response format")
                    completion(nil)
                }
            } catch {
                self?.logger.error("Failed to parse OpenAI response: \(error)")
                completion(nil)
            }
        }.resume()
    }
}
