import Foundation
#if canImport(UIKit)
import UIKit
#endif
import os.log
import Network

// MARK: - Conversation History Models
private struct SharedConvItem: Codable {
    let sender: String
    let text: String
    let timestamp: TimeInterval
}

// MARK: - Delegate Protocol
protocol ToneSuggestionDelegate: AnyObject {
    func didUpdateSuggestions(_ suggestions: [String])
    func didUpdateToneStatus(_ status: String)
    func didUpdateSecureFixButtonState()
    #if canImport(UIKit)
    func getTextDocumentProxy() -> UITextDocumentProxy?
    #endif
}

// MARK: - ToneSuggestionCoordinator
/// Isolated coordinator for tone analysis and AI-powered suggestions
/// Performs lightweight client work; defers tone/suggestion logic to backend.
/// Safe for keyboard extensions (ephemeral networking, tight timeouts, minimal timers).
/// 
/// KeyboardController Integration Checklist:
/// - viewDidLoad: coordinator.delegate = self
/// - text change: coordinator.handleTextChange(currentText)
/// - tone button: coordinator.requestSuggestions()
/// - send/done: coordinator.analyzeFinalSentence(finalText) → coordinator.resetState()
/// - accept suggestion: insert text → coordinator.recordSuggestionAccepted(suggestion)
/// - reject suggestion: coordinator.recordSuggestionRejected(suggestion)
final class ToneSuggestionCoordinator {
    // MARK: Public
    weak var delegate: ToneSuggestionDelegate?

    // MARK: Configuration
    private var apiBaseURL: String {
        let extBundle = Bundle(for: ToneSuggestionCoordinator.self)
        let mainBundle = Bundle.main
        let fromExt = extBundle.object(forInfoDictionaryKey: "UNSAID_API_BASE_URL") as? String
        let fromMain = mainBundle.object(forInfoDictionaryKey: "UNSAID_API_BASE_URL") as? String
        let picked = (fromExt?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? fromMain?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty)
        return picked ?? ""
    }
    private var apiKey: String {
        let extBundle = Bundle(for: ToneSuggestionCoordinator.self)
        let mainBundle = Bundle.main
        let fromExt = extBundle.object(forInfoDictionaryKey: "UNSAID_API_KEY") as? String
        let fromMain = mainBundle.object(forInfoDictionaryKey: "UNSAID_API_KEY") as? String
        return (fromExt?.nilIfEmpty ?? fromMain?.nilIfEmpty) ?? ""
    }
    private var isAPIConfigured: Bool {
        let ok = !apiBaseURL.isEmpty && !apiKey.isEmpty
        // Respect auth backoff window to avoid hammering on auth failures
        if Date() < authBackoffUntil { return false }
        return ok
    }

    // MARK: Networking
    private lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.waitsForConnectivity = false
        cfg.allowsCellularAccess = true
        cfg.allowsConstrainedNetworkAccess = true
        cfg.allowsExpensiveNetworkAccess = true
        cfg.httpShouldUsePipelining = true
        cfg.httpMaximumConnectionsPerHost = 2
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        cfg.timeoutIntervalForRequest = 5.0
        cfg.timeoutIntervalForResource = 15.0
        cfg.httpCookieAcceptPolicy = .never
        cfg.httpCookieStorage = nil
        return URLSession(configuration: cfg)
    }()

    // MARK: - Queues / Debounce
    private let analysisQueue = DispatchQueue(label: "com.unsaid.toneAnalysis", qos: .utility)
    private let suggestionQueue = DispatchQueue(label: "com.unsaid.suggestions", qos: .utility)
    private var pendingAnalysisWorkItem: DispatchWorkItem?
    private var pendingSuggestionWorkItem: DispatchWorkItem?
    private let analysisDebounce: TimeInterval = 0.1

    // MARK: - Network Monitoring
    private var networkMonitor: NWPathMonitor?
    private let networkQueue = DispatchQueue(label: "com.unsaid.network", qos: .utility)
    private(set) var isNetworkAvailable: Bool = true
    private var didStartMonitoring = false

    // MARK: - State
    private var currentText: String = ""
    private var lastAnalyzedText: String = ""
    private var lastAnalysisTime: Date = .distantPast
    private var consecutiveFailures: Int = 0
    private var currentToneStatus: String = "neutral"
    private var suggestions: [String] = []
    private var lastEscalationAt: Date = .distantPast
    private var suggestionSnapshot: String?
    private var enhancedAnalysisResults: [String: Any]?
    
    // MARK: - Request Management
    private var latestRequestID = UUID()
    private var authBackoffUntil: Date = .distantPast

    // MARK: - Shared Defaults (App Group)
    private let personalityBridge = PersonalityDataBridge.shared
    private let sharedUserDefaults: UserDefaults? = {
        UserDefaults(suiteName: "group.com.example.unsaid")
    }()

    // MARK: - Logging
    private let logger = Logger(subsystem: "com.example.unsaid.unsaid.UnsaidKeyboard", category: "ToneSuggestionCoordinator")
    private var logThrottle: [String: Date] = [:]
    private let logThrottleInterval: TimeInterval = 1.0

    // MARK: - Init / Deinit
    init() {
        // Delay network initialization to prevent startup crashes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startNetworkMonitoringSafely()
        }
        #if DEBUG
        // Debug personality data connection (safe)
        debugPrint("🧠 Personality Data Bridge Status:")
        debugPrint(" - Attachment Style: '\(getAttachmentStyle())'")
        debugPrint(" - Communication Style: '\(personalityBridge.getCommunicationStyle())'")
        debugPrint(" - Personality Type: '\(personalityBridge.getPersonalityType())'")
        debugPrint(" - Emotional State: '\(getEmotionalState())'")
        debugPrint(" - Test Complete: \(personalityBridge.isPersonalityTestComplete())")
        debugPrint(" - Data Freshness: \(personalityBridge.getDataFreshness()) hours")
        #endif
    }

    deinit {
        pendingAnalysisWorkItem?.cancel()
        pendingSuggestionWorkItem?.cancel()
        stopNetworkMonitoring()
    }

    // MARK: - Conversation History Helpers
    private func loadSharedConversationHistory() -> [[String: Any]] {
        guard let d = sharedUserDefaults?.data(forKey: "conversation_history_buffer"),
              let items = try? JSONDecoder().decode([SharedConvItem].self, from: d) else { return [] }
        return items.map { ["sender": $0.sender, "text": $0.text, "timestamp": $0.timestamp] }
    }

    private func exportConversationHistoryForAPI(withCurrentText overrideText: String? = nil) -> [[String: Any]] {
        var history = loadSharedConversationHistory()
        let now = Date().timeIntervalSince1970
        let current = (overrideText ?? currentText).trimmingCharacters(in: .whitespacesAndNewlines)
        if !current.isEmpty {
            history.append(["sender": "user", "text": current, "timestamp": now])
        }
        if history.count > 20 {
            history = Array(history.suffix(20))
        }
        return history
    }

    // MARK: - Public API (called by KeyboardController)
    func analyzeFinalSentence(_ sentence: String) {
        handleTextChange(sentence)
    }

    func handleTextChange(_ text: String) {
        updateCurrentText(text)
        guard shouldEnqueueAnalysis() else {
            throttledLog("skip enqueue (timing / unchanged / short)", category: "analysis")
            return
        }
        pendingAnalysisWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.performTextUpdate()
        }
        pendingAnalysisWorkItem = work
        let delay: TimeInterval = currentText.count > 20 ? 0.05 : analysisDebounce
        analysisQueue.asyncAfter(deadline: .now() + delay, execute: work)
        throttledLog("scheduled analysis in \(delay)s", category: "analysis")
    }

    func requestSuggestions() {
        pendingSuggestionWorkItem?.cancel()
        let snapshot = currentText
        suggestionSnapshot = snapshot
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            guard !snapshot.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.didUpdateSuggestions([])
                    self?.delegate?.didUpdateSecureFixButtonState()
                }
                return
            }
            self.generatePerfectSuggestion(from: snapshot)
        }
        pendingSuggestionWorkItem = work
        suggestionQueue.async(execute: work)
    }

    func resetState() {
        pendingAnalysisWorkItem?.cancel()
        pendingSuggestionWorkItem?.cancel()
        currentText = ""
        lastAnalyzedText = ""
        currentToneStatus = "neutral"
        suggestions = []
        consecutiveFailures = 0
        lastEscalationAt = .distantPast
        suggestionSnapshot = nil
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.delegate?.didUpdateToneStatus("neutral")
            self.delegate?.didUpdateSuggestions([])
        }
        throttledLog("state reset", category: "coordinator")
    }

    func getCurrentToneStatus() -> String {
        return currentToneStatus
    }

    func recordUserMessageSent(_ text: String) {
        // Host app manages the conversation history buffer
    }

    func recordOtherMessage(_ text: String, at timestampMs: Int64? = nil) {
        // Host app manages the conversation history buffer
    }

    // MARK: - Internal: Text Handling
    private func normalized(_ s: String) -> String {
        s.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func updateCurrentText(_ text: String) {
        let maxLen = 1000
        let trimmed = text.count > maxLen ? String(text.suffix(maxLen)) : text
        guard trimmed != currentText else { return }
        currentText = trimmed
    }

    private func shouldEnqueueAnalysis() -> Bool {
        let now = Date()
        let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count < 5, !trimmed.isEmpty { return false }
        if trimmed.isEmpty, !lastAnalyzedText.isEmpty { return true }
        if normalized(trimmed) == normalized(lastAnalyzedText) { return false }
        if now.timeIntervalSince(lastAnalysisTime) < 0.08 { return false }
        return true
    }

    // MARK: - Perform Text Update (Tone)
    private func performTextUpdate() {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            lastAnalyzedText = currentText
            lastAnalysisTime = Date()
            suggestions.removeAll()
            currentToneStatus = "neutral"
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didUpdateSuggestions([])
                self?.delegate?.didUpdateToneStatus("neutral")
            }
            return
        }
        if text.count > 1000 {
            currentText = String(text.suffix(1000))
        }
        
        // Use suggestions API for tone analysis since tone-analysis endpoint is removed
        var context: [String: Any] = [
            "text": currentText,
            "userId": getUserId(),
            "userEmail": getUserEmail() ?? NSNull(),
            "toneAnalysisResult": [:] // Empty since we're doing full analysis
        ]
        context.merge(personalityPayload()) { _, new in new }
        
        callSuggestionsAPI(context: context, usingSnapshot: currentText) { [weak self] suggestion in
            guard let self else { return }
            self.lastAnalysisTime = Date()
            self.lastAnalyzedText = self.currentText
            self.consecutiveFailures = 0
            
            // Note: Tone status updates are now handled within callSuggestionsAPI
            // This provides more accurate ML-driven tone analysis
        }
    }

    // MARK: - Suggestion flow
    private func generatePerfectSuggestion(from snapshot: String = "") {
        var textToAnalyze = snapshot.isEmpty ? currentText : snapshot
        
        // CAP: Limit text length for consistency
        if textToAnalyze.count > 1000 { 
            textToAnalyze = String(textToAnalyze.suffix(1000)) 
        }
        
        // Direct call to suggestions API (no separate tone analysis needed)
        var context: [String: Any] = [
            "text": textToAnalyze,
            "userId": getUserId(),
            "userEmail": getUserEmail() ?? NSNull(),
            "toneAnalysisResult": [:] // Empty - suggestions API will do full analysis
        ]
        context.merge(personalityPayload()) { _, new in new }
        
        callSuggestionsAPI(context: context, usingSnapshot: textToAnalyze) { [weak self] suggestion in
            guard let self else { return }
            DispatchQueue.main.async {
                if let s = suggestion, !s.isEmpty {
                    self.suggestions = [s]
                    self.delegate?.didUpdateSuggestions(self.suggestions)
                    self.delegate?.didUpdateSecureFixButtonState()
                    self.storeSuggestionGenerated(suggestion: s)
                } else {
                    // FALLBACK: Try local suggestions if network fails
                    if let fallback = self.fallbackSuggestion(for: textToAnalyze), !fallback.isEmpty {
                        self.suggestions = [fallback]
                        self.delegate?.didUpdateSuggestions(self.suggestions)
                        self.delegate?.didUpdateSecureFixButtonState()
                    } else {
                        self.suggestions = []
                        self.delegate?.didUpdateSuggestions([])
                        self.delegate?.didUpdateSecureFixButtonState()
                    }
                }
            }
        }
    }

    // MARK: - Storage / Analytics
    private func storeToneAnalysisResult(data: [String: Any], status: ToneStatus, confidence: Double) {
        // Store using the SafeKeyboardDataStorage for crash prevention
        SafeKeyboardDataStorage.shared.recordToneAnalysis(
            text: currentText,
            tone: status,
            confidence: confidence,
            analysisTime: 0.0
        )
        
        // Also record as a general interaction
        let interaction = KeyboardInteraction(
            timestamp: Date(),
            textBefore: currentText,
            textAfter: currentText,
            toneStatus: status,
            suggestionAccepted: false,
            suggestionText: nil,
            analysisTime: 0.0,
            context: "ml_tone_analysis",
            interactionType: .toneAnalysis,
            userAcceptedSuggestion: false,
            communicationPattern: .neutral,
            attachmentStyleDetected: .unknown,
            relationshipContext: .unknown,
            sentimentScore: 0.0,
            wordCount: currentText.split(separator: " ").count,
            appContext: "keyboard_extension"
        )
        SafeKeyboardDataStorage.shared.recordInteraction(interaction)
    }

    private func storeSuggestionGenerated(suggestion: String) {
        // Store using the available recordSuggestionInteraction method
        SafeKeyboardDataStorage.shared.recordSuggestionInteraction(
            suggestion: suggestion,
            accepted: false,
            context: "ml_suggestion_generated"
        )
        
        // Also record as a general interaction
        let interaction = KeyboardInteraction(
            timestamp: Date(),
            textBefore: currentText,
            textAfter: currentText,
            toneStatus: ToneStatus(rawValue: currentToneStatus) ?? .neutral,
            suggestionAccepted: false,
            suggestionText: suggestion,
            analysisTime: 0.0,
            context: "ml_suggestion_generated",
            interactionType: .suggestion,
            wordCount: currentText.split(separator: " ").count,
            appContext: "keyboard_extension"
        )
        SafeKeyboardDataStorage.shared.recordInteraction(interaction)
    }
    
    // MARK: - Suggestion Analytics Hooks
    func recordSuggestionAccepted(_ suggestion: String) {
        SafeKeyboardDataStorage.shared.recordSuggestionInteraction(
            suggestion: suggestion, 
            accepted: true, 
            context: "ml_suggestion_accepted"
        )
    }
    
    func recordSuggestionRejected(_ suggestion: String) {
        SafeKeyboardDataStorage.shared.recordSuggestionInteraction(
            suggestion: suggestion, 
            accepted: false, 
            context: "ml_suggestion_rejected"
        )
    }

    // MARK: - Decisioning
    private func shouldUpdateToneStatus(from current: String, to new: String, improvementDetected: Bool? = nil, improvementScore: Double? = nil) -> Bool {
        if new == current { return false }
        func severity(_ s: String) -> Int {
            switch s {
            case "neutral": return 0
            case "caution": return 1
            case "alert": return 2
            case "clear": return 0
            case "analyzing": return 0
            default: return 0
            }
        }
        let cur = severity(current)
        let nxt = severity(new)
        if nxt > cur {
            lastEscalationAt = Date()
            return true
        }
        let dwell: TimeInterval = 3.0
        if current == "alert" || current == "caution" {
            let sticky = Date().timeIntervalSince(lastEscalationAt) < dwell
            if sticky { return false }
        }
        if let imp = improvementDetected, imp, (improvementScore ?? 0) > 0.3 {
            return true
        }
        if currentText.count + 3 < lastAnalyzedText.count {
            return true
        }
        return false
    }

    // MARK: - Personality / Shared Data
    private func getAttachmentStyle() -> String {
        return personalityBridge.getAttachmentStyle()
    }
    
    private func getUserId() -> String {
        return sharedUserDefaults?.string(forKey: "user_id") ?? sharedUserDefaults?.string(forKey: "userId") ?? "keyboard_user"
    }
    
    private func getUserEmail() -> String? {
        return sharedUserDefaults?.string(forKey: "user_email") ?? sharedUserDefaults?.string(forKey: "userEmail")
    }
    
    private func getEmotionalState() -> String {
        return personalityBridge.getCurrentEmotionalState()
    }
    
    private func getUserProfile() -> [String: Any] {
        return personalityBridge.getPersonalityProfile()
    }
    
    private func personalityPayload() -> [String: Any] {
        let profile = personalityBridge.getPersonalityProfile()
        return [
            "emotional_state": profile["emotional_state"] ?? "neutral",
            "attachment_style": profile["attachment_style"] ?? "secure",
            "user_profile": profile,
            "communication_style": profile["communication_style"] ?? "direct",
            "emotional_bucket": profile["emotional_bucket"] ?? "moderate"
        ]
    }

    // MARK: - SPAcy bridge
    func checkForSpacyResults() {
        guard let shared = sharedUserDefaults else { return }
        if let analysisData = shared.dictionary(forKey: "spacy_analysis_result"),
           let timestamp = analysisData["timestamp"] as? TimeInterval {
            let lastProcessed = UserDefaults.standard.double(forKey: "last_spacy_result_timestamp")
            if timestamp > lastProcessed {
                enhancedAnalysisResults = analysisData
                UserDefaults.standard.set(timestamp, forKey: "last_spacy_result_timestamp")
                throttledLog("spacy analysis received", category: "spacy")
                DispatchQueue.main.async { [weak self] in
                    self?.applyEnhancedSpacyAnalysis()
                }
            }
        }
    }

    func requestSpacyAnalysis(text: String, context: String = "typing") {
        guard let shared = sharedUserDefaults else { return }
        let req: [String: Any] = [
            "text": text,
            "context": context,
            "timestamp": Date().timeIntervalSince1970,
            "requestId": UUID().uuidString
        ]
        shared.set(req, forKey: "spacy_analysis_request")
        shared.synchronize()
        throttledLog("spacy request queued", category: "spacy")
    }

    private func applyEnhancedSpacyAnalysis() {
        guard let analysis = enhancedAnalysisResults else { return }
        let emotions = analysis["emotions"] as? [String] ?? []
        let spacySuggestions = analysis["suggestions"] as? [String] ?? []
        if !spacySuggestions.isEmpty {
            var merged = suggestions
            for s in spacySuggestions.reversed() where !merged.contains(s) {
                merged.insert(s, at: 0)
            }
            suggestions = Array(merged.prefix(5))
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didUpdateSuggestions(self?.suggestions ?? [])
            }
        }
        if !emotions.isEmpty {
            if !currentText.isEmpty {
                // Use suggestions API for enhanced analysis
                var context: [String: Any] = [
                    "text": currentText,
                    "emotions": emotions,
                    "enhanced_analysis": true
                ]
                context.merge(personalityPayload()) { _, new in new }
                callSuggestionsAPI(context: context) { _ in }
            }
        }
    }

    func updateToneFromAnalysis(_ analysis: [String: Any]) {
        if let toneStr = (analysis["tone_status"] as? String) ?? (analysis["tone"] as? String),
           let status = ToneStatus(rawValue: toneStr) {
            currentToneStatus = toneStr
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didUpdateToneStatus(toneStr)
            }
        }
    }

    // MARK: - API Calls
    private func callSuggestionsAPI(context: [String: Any], usingSnapshot snapshot: String? = nil, completion: @escaping (String?) -> Void) {
        guard isNetworkAvailable, isAPIConfigured else { completion(nil); return }
        
        // GUARD: Generate request ID to prevent stale responses
        let requestID = UUID()
        latestRequestID = requestID
        
        var payload = context
        payload["requestId"] = requestID.uuidString
        payload["userId"] = getUserId()
        payload["userEmail"] = getUserEmail()
        payload.merge(personalityPayload()) { _, new in new }
        payload["conversationHistory"] = exportConversationHistoryForAPI(withCurrentText: snapshot)
        
        callEndpoint(path: "suggestions", payload: payload) { [weak self] data in
            guard let self else { return }
            
            // GUARD: Ignore stale results
            guard requestID == self.latestRequestID else { completion(nil); return }
            
            let d = data ?? [:]
            
            // Store comprehensive ML analysis results for later use
            if !d.isEmpty {
                self.enhancedAnalysisResults = d
            }
            
            // Process tone analysis results from ML system
            if let toneStatus = d["toneStatus"] as? String ?? d["primaryTone"] as? String {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    let shouldUpdate = self.shouldUpdateToneStatus(
                        from: self.currentToneStatus, 
                        to: toneStatus,
                        improvementDetected: d["improvementDetected"] as? Bool,
                        improvementScore: d["confidence"] as? Double
                    )
                    if shouldUpdate {
                        self.currentToneStatus = toneStatus
                        self.delegate?.didUpdateToneStatus(toneStatus)
                        
                        // Store the tone analysis for analytics
                        if let confidence = d["confidence"] as? Double {
                            let status = ToneStatus(rawValue: toneStatus) ?? .neutral
                            self.storeToneAnalysisResult(data: d, status: status, confidence: confidence)
                        }
                    }
                }
            }
            
            // Extract suggestion text
            var suggestion: String?
            if let arr = d["suggestions"] as? [[String: Any]], 
               let first = arr.first,
               let text = first["text"] as? String {
                suggestion = text
            } else if let s = d["general_suggestion"] as? String {
                suggestion = s
            } else if let s = d["suggestion"] as? String {
                suggestion = s
            } else if let dataField = d["data"] as? String {
                suggestion = dataField
            }
            completion(suggestion)
        }
    }

    private func callEndpoint(path: String, payload: [String: Any], completion: @escaping ([String: Any]?) -> Void) {
        guard isAPIConfigured else {
            throttledLog("API not configured; skipping \(path)", category: "api")
            completion(nil)
            return
        }
        let normalized = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let base = apiBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: base.hasSuffix("/") ? base + normalized : base + "/" + normalized) else {
            throttledLog("invalid URL for \(normalized)", category: "api")
            completion(nil)
            return
        }
        var req = URLRequest(url: url, timeoutInterval: 5.0)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            throttledLog("payload serialization failed: \(error.localizedDescription)", category: "api")
            completion(nil)
            return
        }
        let task = session.dataTask(with: req) { data, response, error in
            if let error = error {
                self.handleNetworkError(error, url: url)
                completion(nil)
                return
            }
            guard let http = response as? HTTPURLResponse else {
                self.throttledLog("no HTTPURLResponse for \(normalized)", category: "api")
                completion(nil)
                return
            }
            guard (200..<300).contains(http.statusCode), let data = data else {
                // HANDLE: Auth failures with backoff
                if http.statusCode == 401 || http.statusCode == 403 {
                    self.authBackoffUntil = Date().addingTimeInterval(60) // 1 min backoff
                }
                #if DEBUG
                self.throttledLog("HTTP \(http.statusCode) \(normalized)", category: "api")
                if let d = data, let s = String(data: d, encoding: .utf8) {
                    print("[\(normalized)] body: \(s)")
                }
                #endif
                completion(nil)
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let dict = json as? [String: Any] {
                    completion(dict)
                } else {
                    completion(nil)
                }
            } catch {
                self.throttledLog("JSON parse failed: \(error.localizedDescription)", category: "api")
                completion(nil)
            }
        }
        task.resume()
    }

    private func handleNetworkError(_ error: Error, url: URL) {
        let ns = error as NSError
        #if DEBUG
        switch ns.code {
        case NSURLErrorNotConnectedToInternet:
            print("🔌 offline: \(url)")
        case NSURLErrorTimedOut:
            print("⏱️ timeout: \(url)")
        case NSURLErrorCannotFindHost:
            print("🌐 cannot find host: \(url)")
        case NSURLErrorCannotConnectToHost:
            print("🔌 cannot connect: \(url)")
        default:
            print("❌ network error \(ns.code): \(error.localizedDescription)")
        }
        #endif
        throttledLog("network error \(ns.code)", category: "api")
    }

    // MARK: - Network Monitoring
    private func startNetworkMonitoring() {
        guard !didStartMonitoring else { return }
        didStartMonitoring = true
        let monitor = NWPathMonitor()
        networkMonitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let available = (path.status != .unsatisfied)
            if available != self.isNetworkAvailable {
                self.isNetworkAvailable = available
                self.throttledLog("network \(available ? "available" : "unavailable")", category: "network")
            }
        }
        monitor.start(queue: networkQueue)
    }

    private func startNetworkMonitoringSafely() {
        do {
            startNetworkMonitoring()
        } catch {
            #if DEBUG
            debugPrint("❌ Failed to start network monitoring: \(error)")
            #endif
            // Fall back to assuming network is available
            isNetworkAvailable = true
        }
    }

    func stopNetworkMonitoring() {
        networkMonitor?.cancel()
        networkMonitor = nil
        didStartMonitoring = false
    }
    
    // MARK: - Offline Fallback
    private func fallbackSuggestion(for text: String) -> String? {
        return LightweightSpellChecker.shared.getCapitalizationAndPunctuationSuggestions(for: text).first
    }

    // MARK: - Logging
    private func throttledLog(_ message: String, category: String = "general") {
        #if DEBUG
        let key = "\(category):\(message)"
        let now = Date()
        if let last = logThrottle[key], now.timeIntervalSince(last) < logThrottleInterval {
            return
        }
        logThrottle[key] = now
        logger.debug("[\(category)] \(message)")
        #endif
    }
}

// MARK: - Small Helpers
private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}