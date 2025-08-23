
//
//  KeyboardController.swift
//

import Foundation
import os.log
import AudioToolbox
import UIKit

// MARK: - UIColor Extensions
private extension UIColor {
    static var keyboardBackground: UIColor { .systemGray6 }
    static var keyboardRose: UIColor { .systemPink }
    static var keyBorder: UIColor { .systemGray3 }
    static var keyShadow: UIColor { .systemGray2 }
}


// MARK: - UndoManagerLite for autocorrect undo
final class UndoManagerLite {
    static let shared = UndoManagerLite()
    private var last: (original: String, corrected: String, chars: Int)?
    
    func record(original: String, corrected: String) { 
        last = (original, corrected, corrected.count) 
    }
    
    func tryUndo(in proxy: UITextDocumentProxy) -> Bool {
        guard let l = last else { return false }
        for _ in 0..<l.chars { proxy.deleteBackward() }
        proxy.insertText(l.original)
        last = nil
        return true
    }
}

// MARK: - Analysis Result for switch-in analysis
struct AnalysisResult {
    let topSuggestion: String?
    let rewrite: String?
    let confidence: Double
}

// MARK: - Switch-in Analyzer
final class SwitchInAnalyzer {
    static let shared = SwitchInAnalyzer()
    
    // LRU-ish in-memory cache: hash(text) -> result
    private var cache: [String: AnalysisResult] = [:]
    private var order: [String] = []
    private let maxEntries = 64
    private let workQ = DispatchQueue(label: "switchin.analyzer", qos: .userInitiated)
    
    private init() {}
    
    func prewarm() {
        // Build regexes, load small dictionaries, prime NL models, etc.
        _ = Self.hash("warm")
        // If you have heavy resources, load them here once.
    }
    
    static func hash(_ s: String) -> String {
        // fast non-crypto hash is fine here
        var h: UInt64 = 1469598103934665603
        for b in s.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        return String(h, radix: 16)
    }
    
    func analyze(text: String, completion: @escaping (AnalysisResult) -> Void) {
        let key = Self.hash(text)
        
        // Cache hit
        if let hit = cache[key] {
            completion(hit)
            return
        }
        
        workQ.async { [weak self] in
            guard let self = self else { return }
            // ---------- FAST PASS (<= 25–40ms target) ----------
            // 1) cheap heuristics (toxicity / caps / profanity)
            let lower = text.lowercased()
            
            let isShouty = Self.hasShouting(text)
            let hasDirectVulgar = Self.directVulgarRegex.firstMatch(in: lower, options: [], range: NSRange(location: 0, length: lower.utf16.count)) != nil
            
            // 2) quick rewrite & suggestion synthesis
            let suggestion: String?
            let rewrite: String?
            
            if hasDirectVulgar {
                suggestion = "Lowering the heat raises the chance they'll hear you."
                rewrite = Self.softenInsult(text)
            } else if isShouty {
                suggestion = "Want to keep this strong but easier to hear?"
                rewrite = Self.downcaseIfAllCaps(text)
            } else {
                suggestion = nil
                rewrite = nil
            }
            
            let result = AnalysisResult(topSuggestion: suggestion, rewrite: rewrite, confidence: hasDirectVulgar ? 0.9 : (isShouty ? 0.7 : 0.4))
            
            // cache (simple LRU)
            self.cache[key] = result
            self.order.append(key)
            if self.order.count > self.maxEntries {
                let drop = self.order.removeFirst()
                self.cache.removeValue(forKey: drop)
            }
            
            DispatchQueue.main.async { completion(result) }
        }
    }
    
    // MARK: - Tiny helpers (keep fast)
    private static let directVulgarRegex: NSRegularExpression = {
        let pattern = #"(?xi) \b f \W* u \W* c \W* k \W* (you|u|ya)\b | \b(shut\W*up|idiot|moron|stupid|dumb|loser)\b | \byou('re| are)?\s+(an?\s+)?(idiot|moron|loser|pathetic|disgusting)\b"#
        return try! NSRegularExpression(pattern: pattern)
    }()
    
    private static func hasShouting(_ s: String) -> Bool {
        let letters = s.filter { $0.isLetter }
        guard letters.count >= 6 else { return false }
        let upper = letters.filter { $0.isUppercase }.count
        return Double(upper) / Double(letters.count) > 0.7
    }
    
    private static func downcaseIfAllCaps(_ s: String) -> String? {
        // If most letters are caps, suggest a sentence‑case rewrite
        let letters = s.filter { $0.isLetter }
        guard !letters.isEmpty else { return nil }
        let upper = letters.filter { $0.isUppercase }.count
        guard Double(upper) / Double(letters.count) > 0.7 else { return nil }
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.prefix(1).uppercased() + trimmed.dropFirst().lowercased()
    }
    
    private static func softenInsult(_ s: String) -> String? {
        // Tiny demo: strip common slurs & keep the complaint
        let lowered = s.replacingOccurrences(of: #"(?i)\b(f\W*u\W*c\W*k\W*\b|idiot|moron|stupid|dumb)\b"#,
                                             with: "", options: .regularExpression)
        let cleaned = lowered.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
        guard cleaned.count >= 3 else { return nil }
        // Add a calmer stem
        return "I'm upset about this—" + cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Simple Apple-like candidate strip
final class SpellCandidatesStrip: UIView {
    private let stack = UIStackView()
    private var onTap: ((String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.systemGray6.withAlphaComponent(0.8)
        layer.cornerRadius = 8
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setSuggestions(_ suggestions: [String], onTap: @escaping (String) -> Void) {
        self.onTap = onTap
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if suggestions.isEmpty {
            // Don't show any placeholder when empty - just leave it clean
            return
        }
        for s in suggestions.prefix(3) { stack.addArrangedSubview(pill(s)) }
    }
    
    // Convenience method for compatibility
    func updateCandidates(_ suggestions: [String]) {
        setSuggestions(suggestions) { _ in }
    }

    private func pill(_ title: String) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.setTitleColor(.label, for: .normal)                 // better contrast
        b.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        b.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        b.backgroundColor = UIColor.systemGray6               // clearer on light bars
        b.layer.cornerRadius = 8
        b.layer.borderWidth = 0.5
        b.layer.borderColor = UIColor.separator.cgColor
        b.addAction(UIAction { [weak self] _ in
            guard let word = b.title(for: .normal)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !word.isEmpty else { return }
            self?.onTap?(word)
        }, for: .touchUpInside)
        return b
    }
}

// MARK: - Key Preview Balloon
final class KeyPreview: UIView {
    private let label = UILabel()
    init(text: String) {
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowRadius = 6
        layer.shadowOffset = .init(width: 0, height: 2)
        label.text = text
        label.font = .systemFont(ofSize: 28, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 52).isActive = true
        heightAnchor.constraint(equalToConstant: 60).isActive = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Polished Single-Suggestion Chip (fixed)
final class SuggestionChipView: UIControl {
    // MARK: - Public API
    var onTap: (() -> Void)?
    var onDismiss: (() -> Void)?
    var onCTATap: (() -> Void)?
    var onSwipeToNext: (() -> Void)?
    var onSwipeToPrevious: (() -> Void)?
    
    // MARK: - Analytics hooks
    var onSurfaced: (() -> Void)?
    var onExpanded: (() -> Void)?
    var onApplied: (() -> Void)?
    var onDismissed: (() -> Void)?
    var onTimeout: (() -> Void)?

    enum Tone { case neutral, alert, caution, clear }

    // MARK: - UI Components
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let chevronButton = UIButton(type: .system)
    private let ctaButton = UIButton(type: .system)
    private let pagerView = UIView()
    private var pagerDots: [UIView] = []

    private let content = UIView()
    private let impact = UIImpactFeedbackGenerator(style: .light)
    
    private var isExpanded = false
    private var expandedConstraints: [NSLayoutConstraint] = []
    private var compactConstraints: [NSLayoutConstraint] = []
    
    // MARK: - Multi-suggestion support
    private var suggestions: [String] = []
    private var currentIndex: Int = 0
    private var autoHideTimer: Timer?
    private var lastInteractionTime: Date = Date()
    
    // MARK: - Text hash for stickiness
    private var associatedTextHash: String = ""

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAccessibility()
        setupUI()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupAccessibility()
        setupUI()
        setupGestures()
    }
    
    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits.insert(.button)
        accessibilityHint = "Double-tap to apply; swipe up to dismiss; tap chevron to expand."
    }
    
    private func setupGestures() {
        // Swipe left/right for multiple suggestions
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        swipeLeft.direction = .left
        addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        swipeRight.direction = .right
        addGestureRecognizer(swipeRight)
        
        // Swipe up to dismiss
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeUp))
        swipeUp.direction = .up
        addGestureRecognizer(swipeUp)
    }
    
    @objc private func handleSwipeLeft() {
        guard suggestions.count > 1 else { return }
        impact.impactOccurred()
        nextSuggestion()
        onSwipeToNext?()
        updateLastInteraction()
    }
    
    @objc private func handleSwipeRight() {
        guard suggestions.count > 1 else { return }
        impact.impactOccurred()
        previousSuggestion()
        onSwipeToPrevious?()
        updateLastInteraction()
    }
    
    @objc private func handleSwipeUp() {
        impact.impactOccurred()
        onDismissed?()
        dismiss(animated: true)
        updateLastInteraction()
    }
    
    private func updateLastInteraction() {
        lastInteractionTime = Date()
        resetAutoHideTimer()
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false

        // Capsule container (solid color, no blur)
        content.translatesAutoresizingMaskIntoConstraints = false
        content.layer.cornerCurve = .continuous
        content.layer.cornerRadius = 18
        content.layer.masksToBounds = false
        content.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)

        // Soft shadow
        content.layer.shadowColor = UIColor.black.withAlphaComponent(0.18).cgColor
        content.layer.shadowOpacity = 1
        content.layer.shadowOffset = CGSize(width: 0, height: 2)
        content.layer.shadowRadius = 6

        addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: topAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor),
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])

        // Icon
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = .init(pointSize: 14, weight: .bold)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Title with better compression resistance
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Pager dots container
        pagerView.translatesAutoresizingMaskIntoConstraints = false
        pagerView.isHidden = true

        // Chevron/expand button
        chevronButton.translatesAutoresizingMaskIntoConstraints = false
        chevronButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        chevronButton.accessibilityLabel = "Expand suggestion"
        chevronButton.addAction(UIAction { [weak self] _ in
            self?.toggleExpanded()
        }, for: .touchUpInside)
        chevronButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        // CTA button (initially hidden) - will hide automatically when space is tight
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.setTitle("Apply", for: .normal)
        ctaButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        ctaButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        ctaButton.layer.cornerRadius = 12
        ctaButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        ctaButton.accessibilityLabel = "Apply suggestion"
        ctaButton.addAction(UIAction { [weak self] _ in
            self?.onApplied?()
            self?.onCTATap?()
        }, for: .touchUpInside)
        ctaButton.alpha = 0
        ctaButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        // Close
        var xConfig = UIButton.Configuration.plain()
        xConfig.contentInsets = .init(top: 6, leading: 6, bottom: 6, trailing: 6)
        closeButton.configuration = xConfig
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.accessibilityLabel = "Dismiss suggestion"
        closeButton.addAction(UIAction { [weak self] _ in
            self?.onDismissed?()
            self?.dismiss(animated: true)
        }, for: .touchUpInside)
        closeButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Main content stack
        let mainStack = UIStackView(arrangedSubviews: [iconView, titleLabel])
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.axis = .horizontal
        mainStack.alignment = .center
        mainStack.spacing = 10

        // Control stack (pager, chevron, close)
        let controlStack = UIStackView(arrangedSubviews: [pagerView, chevronButton, closeButton])
        controlStack.translatesAutoresizingMaskIntoConstraints = false
        controlStack.axis = .horizontal
        controlStack.alignment = .center
        controlStack.spacing = 8

        // Compact layout (default)
        let compactStack = UIStackView(arrangedSubviews: [mainStack, controlStack])
        compactStack.translatesAutoresizingMaskIntoConstraints = false
        compactStack.axis = .horizontal
        compactStack.alignment = .center
        compactStack.spacing = 10
        content.addSubview(compactStack)
        content.addSubview(ctaButton)

        // Store constraint references for layout switching
        compactConstraints = [
            compactStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 12),
            compactStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -6),
            compactStack.topAnchor.constraint(equalTo: content.topAnchor, constant: 6),
            compactStack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -6),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),
            pagerView.widthAnchor.constraint(lessThanOrEqualToConstant: 40)
        ]

        expandedConstraints = [
            compactStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 12),
            compactStack.trailingAnchor.constraint(equalTo: ctaButton.leadingAnchor, constant: -8),
            compactStack.topAnchor.constraint(equalTo: content.topAnchor, constant: 6),
            compactStack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -6),
            ctaButton.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            ctaButton.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            ctaButton.heightAnchor.constraint(equalToConstant: 24),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),
            pagerView.widthAnchor.constraint(lessThanOrEqualToConstant: 40)
        ]

        // Start with compact layout
        NSLayoutConstraint.activate(compactConstraints)

        // Tap behavior
        addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.impact.impactOccurred()
            self.animateTap()
            self.updateLastInteraction()
            self.onTap?()
        }, for: .touchUpInside)
        
        // Start auto-hide timer
        startAutoHideTimer()
    }

    private func toggleExpanded() {
        isExpanded.toggle()
        impact.impactOccurred()
        updateLastInteraction()
        
        if isExpanded {
            onExpanded?()
        }
        
        // Update chevron rotation immediately for better UX
        UIView.animate(withDuration: 0.2) { [weak self] in
            if self?.isExpanded == true {
                self?.chevronButton.transform = CGAffineTransform(rotationAngle: .pi / 2)
            } else {
                self?.chevronButton.transform = .identity
            }
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) { [weak self] in
            if self?.isExpanded == true {
                // Deactivate compact constraints first
                NSLayoutConstraint.deactivate(self?.compactConstraints ?? [])
                
                // Allow line wrapping in expanded mode - up to 4 lines when space permits
                self?.titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
                self?.titleLabel.numberOfLines = 4
                
                // Show CTA button
                self?.ctaButton.alpha = 1.0
                
                // Activate expanded constraints
                NSLayoutConstraint.activate(self?.expandedConstraints ?? [])
            } else {
                // Deactivate expanded constraints first
                NSLayoutConstraint.deactivate(self?.expandedConstraints ?? [])
                
                // Return to normal size
                self?.titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
                self?.titleLabel.numberOfLines = 2
                self?.ctaButton.alpha = 0.0
                
                // Activate compact constraints
                NSLayoutConstraint.activate(self?.compactConstraints ?? [])
            }
            
            // Force layout update on both the chip and its superview
            self?.layoutIfNeeded()
            self?.superview?.layoutIfNeeded()
        }
        
        // Update accessibility
        chevronButton.accessibilityLabel = isExpanded ? "Collapse suggestion" : "Expand suggestion"
    }

    // MARK: - Multi-suggestion support
    func configureSuggestions(_ suggestions: [String], tone: Tone, textHash: String = "") {
        self.suggestions = suggestions
        self.currentIndex = 0
        self.associatedTextHash = textHash
        
        updatePagerDots()
        updateCurrentSuggestion()
        applyTone(tone, animated: false)
        
        // Analytics
        onSurfaced?()
    }
    
    func updateSuggestions(_ suggestions: [String], tone: Tone, textHash: String = "") {
        let previousTextHash = self.associatedTextHash
        self.suggestions = suggestions
        self.associatedTextHash = textHash
        
        // Smart stickiness: only keep current index if text context is similar
        if previousTextHash != textHash {
            self.currentIndex = 0
        } else {
            // Keep current index if valid, otherwise reset
            if currentIndex >= suggestions.count {
                currentIndex = 0
            }
        }
        
        updatePagerDots()
        updateCurrentSuggestion()
        applyTone(tone, animated: true)
    }
    
    private func updatePagerDots() {
        // Remove existing dots
        pagerDots.forEach { $0.removeFromSuperview() }
        pagerDots.removeAll()
        
        guard suggestions.count > 1 else {
            pagerView.isHidden = true
            return
        }
        
        pagerView.isHidden = false
        
        // Create dots for each suggestion (max 5 dots to avoid overcrowding)
        let maxDots = min(suggestions.count, 5)
        for i in 0..<maxDots {
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.backgroundColor = UIColor.white.withAlphaComponent(i == currentIndex ? 0.8 : 0.3)
            dot.layer.cornerRadius = 2
            dot.widthAnchor.constraint(equalToConstant: 4).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 4).isActive = true
            pagerDots.append(dot)
        }
        
        let stackView = UIStackView(arrangedSubviews: pagerDots)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.alignment = .center
        
        pagerView.subviews.forEach { $0.removeFromSuperview() }
        pagerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: pagerView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: pagerView.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: pagerView.leadingAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: pagerView.trailingAnchor)
        ])
    }
    
    private func updateCurrentSuggestion() {
        guard currentIndex < suggestions.count else { return }
        titleLabel.text = suggestions[currentIndex]
        accessibilityLabel = suggestions[currentIndex]
        
        // Update pager dots opacity
        for (i, dot) in pagerDots.enumerated() {
            dot.backgroundColor = UIColor.white.withAlphaComponent(i == currentIndex ? 0.8 : 0.3)
        }
    }
    
    private func nextSuggestion() {
        guard suggestions.count > 1 else { return }
        currentIndex = (currentIndex + 1) % suggestions.count
        updateCurrentSuggestion()
    }
    
    private func previousSuggestion() {
        guard suggestions.count > 1 else { return }
        currentIndex = (currentIndex - 1 + suggestions.count) % suggestions.count
        updateCurrentSuggestion()
    }
    
    // MARK: - Auto-hide timer management
    private func startAutoHideTimer() {
        resetAutoHideTimer()
    }
    
    private func resetAutoHideTimer() {
        autoHideTimer?.invalidate()
        // Only auto-hide if not expanded - user interaction shows intent
        guard !isExpanded else { return }
        
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: 18.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            // Check if user has been inactive
            let timeSinceLastInteraction = Date().timeIntervalSince(self.lastInteractionTime)
            if timeSinceLastInteraction >= 15.0 {
                self.onTimeout?()
                self.dismiss(animated: true)
            }
        }
    }
    
    // MARK: - Text relevance checking
    func isRelevantToText(_ textHash: String) -> Bool {
        return associatedTextHash == textHash && !associatedTextHash.isEmpty
    }

    func configure(text: String, tone: Tone) {
        configureSuggestions([text], tone: tone)
    }

    func updateTone(_ tone: Tone) {
        applyTone(tone, animated: true)
    }
    
    func getCurrentSuggestion() -> String? {
        guard currentIndex < suggestions.count else { return nil }
        return suggestions[currentIndex]
    }

    private func applyTone(_ tone: Tone, animated: Bool) {
        let (bg, icon, textColor, iconColor) = toneColors(tone)
        let apply = { [weak self] in
            self?.content.backgroundColor = bg
            self?.iconView.image = UIImage(systemName: icon)
            self?.iconView.tintColor = iconColor
            self?.titleLabel.textColor = textColor
            self?.closeButton.tintColor = iconColor.withAlphaComponent(0.9)
            self?.chevronButton.tintColor = iconColor.withAlphaComponent(0.8)
            self?.ctaButton.setTitleColor(textColor, for: .normal)
            
            // Update pager dots color
            for dot in self?.pagerDots ?? [] {
                dot.backgroundColor = iconColor.withAlphaComponent(
                    dot.backgroundColor?.cgColor.alpha == 0.8 ? 0.8 : 0.3
                )
            }
        }
        if animated {
            UIView.transition(with: content, duration: 0.15, options: [.transitionCrossDissolve], animations: apply)
        } else {
            apply()
        }
    }

    /// (bg, icon, titleColor, iconColor)
    private func toneColors(_ tone: Tone) -> (UIColor, String, UIColor, UIColor) {
        switch tone {
        case .neutral: return (UIColor.systemBlue.withAlphaComponent(0.90), "sparkles", .white, .white)
        case .alert:   return (UIColor.systemRed.withAlphaComponent(0.95), "exclamationmark.triangle.fill", .white, .white)
        case .caution: return (UIColor.systemYellow.withAlphaComponent(0.95), "exclamationmark.triangle.fill", .black, .black)
        case .clear:   return (UIColor.systemGreen.withAlphaComponent(0.92), "checkmark.seal.fill", .white, .white)
        }
    }

    private func animateTap() {
        UIView.animate(withDuration: 0.08, animations: { [weak self] in
            self?.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }) { [weak self] _ in
            UIView.animate(withDuration: 0.18,
                           delay: 0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 0) {
                self?.transform = .identity
            }
        }
    }

    func present(in container: UIView, from startAlpha: CGFloat = 0) {
        if superview == nil { container.addSubview(self) }
        alpha = startAlpha
        transform = CGAffineTransform(translationX: 0, y: 6)
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut]) { [weak self] in
            self?.alpha = 1
            self?.transform = .identity
        }
        startAutoHideTimer()
    }

    func dismiss(animated: Bool) {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
        
        let work = { [weak self] in
            self?.alpha = 0
            self?.transform = CGAffineTransform(translationX: 0, y: 6)
        }
        let done: (Bool) -> Void = { [weak self] _ in
            self?.removeFromSuperview()
            self?.onDismiss?()
        }
        if animated {
            UIView.animate(withDuration: 0.18,
                           delay: 0,
                           options: [.curveEaseIn],
                           animations: work,
                           completion: done)
        } else {
            work()
            done(true)
        }
    }
    
    deinit {
        autoHideTimer?.invalidate()
    }
}

// MARK: - Keyboard Controller
final class KeyboardController: UIInputView, ToneSuggestionDelegate, UIInputViewAudioFeedback, UIGestureRecognizerDelegate {

    // MARK: - Services
    private let logger = Logger(subsystem: "com.example.unsaid.unsaid.UnsaidKeyboard", category: "KeyboardController")
    private var coordinator: ToneSuggestionCoordinator?
    
    // MARK: - OpenAI Configuration
    private var openAIAPIKey: String {
        let extBundle = Bundle(for: KeyboardController.self)
        let mainBundle = Bundle.main
        let fromExt = extBundle.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String
        let fromMain = mainBundle.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String
        return (fromExt?.trimmingCharacters(in: .whitespacesAndNewlines) ?? fromMain?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
    }
    
    // MARK: - OpenAI Integration
    private func callOpenAI(text: String, completion: @escaping (String?) -> Void) {
        let apiKey = openAIAPIKey
        guard !apiKey.isEmpty else {
            logger.error("OpenAI API key not found")
            completion(nil)
            return
        }
        
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
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
            logger.error("Failed to serialize OpenAI request: \(error)")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                self.logger.error("OpenAI request failed: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                self.logger.error("No data received from OpenAI")
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
                    self.logger.error("Failed to parse OpenAI response")
                    completion(nil)
                }
            } catch {
                self.logger.error("Failed to parse OpenAI response: \(error)")
                completion(nil)
            }
        }.resume()
    }

    // MARK: - Native feedback
    private let impact = UIImpactFeedbackGenerator(style: .light)
    var enableInputClicksWhenVisible: Bool { true }

    // MARK: - Spell checking (local only)
    private let spellChecker = LightweightSpellChecker.shared
    private let spellStrip = SpellCandidatesStrip()

    // ✅ Polished suggestion chip (modern replacement)
    private var suggestionChip: SuggestionChipView?

    // Suggestion stickiness / hysteresis
    private var suggestionStickyUntil: TimeInterval = 0
    private let minSuggestionShowTime: TimeInterval = 8.0 // Smart stickiness - reduced from 10s
    private var lastSuggestionText: String?
    private var lastTextHash: String = ""
    
    // MARK: - Analytics tracking
    private var analyticsCounters: [String: Int] = [
        "suggestions_surfaced": 0,
        "suggestions_expanded": 0,
        "suggestions_applied": 0,
        "suggestions_dismissed": 0,
        "suggestions_timeout": 0,
        "suggestions_swiped": 0
    ]

    // MARK: - Parent VC
    private weak var parentInputVC: UIInputViewController?

    // MARK: - UI
    private var suggestionBar: UIView?
    private var toneIndicator: UIButton?
    private var logoImageView: UIImageView?
    private var keyboardStackView: UIStackView?
    private var undoButtonRef: UIButton?

    // Control buttons
    private var spaceButton: UIButton?
    private var quickFixButton: UIButton?
    private var globeButton: UIButton?
    private var modeButton: UIButton?
    private var symbolsButton: UIButton?
    private var returnButton: UIButton?
    private var deleteButton: UIButton?
    private var shiftButton: UIButton?

    // State
    private var currentMode: KeyboardMode = .letters
    private var isShifted = true
    private var isCapsLocked = false
    private var lastShiftTapAt: TimeInterval = 0
    private var lastShiftUpdateTime: Date = .distantPast

    // Delete repeat
    private var deleteTimer: Timer?
    private var deleteInterval: TimeInterval = 0.12
    private var deletePressBeganAt: CFTimeInterval = 0
    private var deleteDidRepeat = false
    private var deleteInitialTimer: Timer?

    // Key preview management
    private let keyPreviewTable = NSMapTable<UIButton, KeyPreview>(keyOptions: .weakMemory, valueOptions: .strongMemory)
    private var keyPreviewAutoDismissTimers = [UIButton: Timer]()

    // Suggestions
    private var suggestions: [String] = []
    private var isSuggestionBarVisible = true  // Default to true so suggestions show
    private var lastDisplayedSuggestions: [String] = []

    // Text cache
    private var currentText: String = ""

    // FAT-FINGER
    private let fatFinger = FatFingerEngine()
    private var fatFingerPan: UIPanGestureRecognizer?

    // Canonical key vocabulary for the engine (matches your UI labels)
    private enum KeyID: String {
        case character         // dynamic letters/numbers, use payload
        case space     = "SPACE"
        case returnKey = "RETURN"
        case backspace = "BACKSPACE"
        case shift     = "SHIFT"
        case mode      = "MODE"     // "123" / "ABC"
        case symbols   = "SYMBOLS"  // "#+=" / "123" depending on mode
        case globe     = "GLOBE"
        case quickFix  = "QUICKFIX" // "Secure"
    }

    // MARK: - FatFingerEngine
    private class FatFingerEngine {
        struct KeyFrame {
            let id: String
            let frame: CGRect
        }
        
        enum Event {
            case highlight(String)
            case unhighlight(String)
            case commit(String)
            case cancel(String)
        }
        
        func configure(keys: [KeyFrame]) {
            // Fat finger configuration logic
        }
        
        func handleTouch(at point: CGPoint) -> Event? {
            // Fat finger touch handling
            return nil
        }
    }

    // Fat-finger tracking properties
    private var keyButtons: [UIButton] = []
    private var keyHitRects: [UIButton: CGRect] = [:]
    private var fatFingerActive = false
    private var fatFingerCurrentButton: UIButton?
    private var fatFingerInitialButton: UIButton?
    private var fatFingerHoverScale: CGFloat = 0.96
    
    // Fat-finger config constants
    private let ffBiasTowardInitialKey: CGFloat = 0.22
    private let ffNeighborInset: CGFloat = 6.0
    private let ffCommitOnRelease: Bool = true

    // Layout constants
    private let verticalSpacing: CGFloat = 8
    private let horizontalSpacing: CGFloat = 6
    private let sideMargins: CGFloat = 8
    private let touchTargetHeight: CGFloat = 50
    private let minKeyWidth: CGFloat = 44
    private let keyCornerRadius: CGFloat = 6

    // Rows
    private let topRowKeys = ["q","w","e","r","t","y","u","i","o","p"]
    private let midRowKeys = ["a","s","d","f","g","h","j","k","l"]
    private let botRowKeys = ["z","x","c","v","b","n","m"]
    private let topRowNumbers = ["1","2","3","4","5","6","7","8","9","0"]
    private let midRowNumbers = ["-","/",":",";","(",")","$","&","@","\""]
    private let botRowNumbers = [".",",","?","!","'"]
    private let topRowSymbols = ["[","]","{","}","#","%","^","*","+","="]
    private let midRowSymbols = ["_","\\","|","~","<",">","€","£","¥","•"]
    private let botRowSymbols = [".",",","?","!","'"]

    // Run autocorrect only on commit boundaries
    private let correctionBoundaries = Set<Character>([" ", "\n", ".", ",", "!", "?", ":", ";"])

    // MARK: - Analysis gating config
    private let analyzeOnSentenceBoundaryOnly = false  // Allow analysis without punctuation
    private let minCharsForAnalysis: Int = 8  // Reduced from 12
    private let minWordsForAnalysis: Int = 2  // Reduced from 3
    private let boundaryDebounce: TimeInterval = 0.22
    private let idleDebounceNoPunct: TimeInterval = 1.4  // Reduced from 1.6

    // Switch-in analysis properties
    private let analyzeQueue = DispatchQueue(label: "analysis.queue", qos: .userInitiated)
    private var pendingToken: UUID?
    private var lastAnalyzedHash: String?
    private var lastResult: AnalysisResult?
    private let analyzer = SwitchInAnalyzer.shared

// State
    private var analysisTimer: Timer?
    private var lastAnalyzedSentence: String = ""
    private var lastInputAt: TimeInterval = 0

    // MARK: - Context refresh properties
    private var beforeContext: String = ""
    private var afterContext: String = ""

    private func refreshContext() {
        guard let proxy = textDocumentProxy else { return }
        // Host app may truncate; secure fields often return nil
        beforeContext = proxy.documentContextBeforeInput ?? ""
        afterContext  = proxy.documentContextAfterInput  ?? ""

        // Optional: clamp for your own perf
        beforeContext = String(beforeContext.suffix(600))  // keep last 600 chars
        afterContext  = String(afterContext.prefix(200))   // keep next 200 chars

        // Now pass this to your tone engine / spell system
        // ToneEngine.shared.updateContext(before: beforeContext, after: afterContext)
    }

    // MARK: - Public lifecycle
    override var intrinsicContentSize: CGSize {
        // DYNAMIC: Return parent's height if available to avoid layout conflicts
        if let superView = superview, superView.bounds.height > 0 {
            return CGSize(width: UIView.noIntrinsicMetric, height: superView.bounds.height)
        }
        // FALLBACK: Use reasonable default for initial layout
        return CGSize(width: UIView.noIntrinsicMetric, height: 396)
    }

    override init(frame: CGRect, inputViewStyle: UIInputView.Style) {
        super.init(frame: frame, inputViewStyle: inputViewStyle)
        commonInit()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

// Call this on every text change
    func handleTextChanged(_ text: String) {
    lastInputAt = CACurrentMediaTime()
    analysisTimer?.invalidate()

    let sentence = lastSentence(in: text)
    let hasBoundary = isBoundaryEnded(text)

    // Basic minimums
    guard sentence.count >= minCharsForAnalysis,
          wordCount(in: sentence) >= minWordsForAnalysis else { return }

    // Don’t re-analyze the same sentence
    if sentence == lastAnalyzedSentence { return }

    // Decide debounce interval
    let delay: TimeInterval
    if analyzeOnSentenceBoundaryOnly {
        delay = hasBoundary ? boundaryDebounce : idleDebounceNoPunct
    } else {
        delay = hasBoundary ? boundaryDebounce : boundaryDebounce // quick feedback even without punct
    }

    analysisTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
        guard let self = self else { return }

        // Optional: idle check for “no punctuation” path
        if analyzeOnSentenceBoundaryOnly && !hasBoundary {
            let idle = CACurrentMediaTime() - self.lastInputAt
            if idle < self.idleDebounceNoPunct { return } // user resumed typing
        }

        self.runAnalysis(on: sentence)
        self.lastAnalyzedSentence = sentence
    }
    RunLoop.current.add(analysisTimer!, forMode: .common)
    }

    func cancelAnalysis() {
        analysisTimer?.invalidate()
        analysisTimer = nil
    }

// MARK: - Helpers

    private func runAnalysis(on sentence: String) {
        // Debug logging
        logger.debug("Running analysis on sentence: '\(sentence)'")
        
        // Your analysis call here
        coordinator?.analyzeFinalSentence(sentence)
        
        logger.debug("Analysis request sent to coordinator")
    }


    private func isBoundaryEnded(_ text: String) -> Bool {
        guard let last = text.trimmingCharacters(in: .whitespacesAndNewlines).last else { return false }
        return [".", "!", "?", "…"].contains(last)
}

    private func lastSentence(in text: String) -> String {
    // Lightweight splitter: split on . ! ? … keeping last chunk
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }
    // Split on common sentence enders
        let parts = trimmed.split(whereSeparator: { ".!?…".contains($0) })
        let candidate = parts.last.map(String.init) ?? trimmed
        return candidate.trimmingCharacters(in: .whitespacesAndNewlines)
}

    private func wordCount(in s: String) -> Int {
        s.split { $0.isWhitespace || $0.isNewline }.count
}

    // Trackpad gesture
    private var spacePan: UIPanGestureRecognizer?
    private var cursorAccumulator: CGFloat = 0

    // MARK: - Convenience
    private var textDocumentProxy: UITextDocumentProxy? {
        return parentInputVC?.textDocumentProxy
    }

    func configure(with inputVC: UIInputViewController) {
        parentInputVC = inputVC
        if let lang = UserDefaults(suiteName: "group.com.example.unsaid")?.string(forKey: "keyboard_language") {
            spellChecker.setPreferredLanguage(lang)
        }
        coordinator = ToneSuggestionCoordinator()
        coordinator?.delegate = self
        
        // Debug: Log coordinator initialization
        logger.debug("ToneSuggestionCoordinator initialized: \(self.coordinator != nil)")
    }

    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.keyboardBackground
        impact.prepare()
        setupSuggestionBar()
        setupKeyboardLayout()
        updateSecureFixButtonState()
        
        // Fat-finger: install pan recognizer on the whole keyboard surface
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleFatFingerPan(_:)))
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        pan.cancelsTouchesInView = false   // keep normal taps working
        addGestureRecognizer(pan)
        fatFingerPan = pan
    }
    
    // MARK: - Lifecycle Methods
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            // About to be removed from superview - clean up previews
            dismissAllKeyPreviews()
        }
    }
    
    override func removeFromSuperview() {
        dismissAllKeyPreviews()
        super.removeFromSuperview()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dismissAllKeyPreviews()
        refreshKeyHitRects()

    }
// MARK: - FAT FINGER: atlas
private func refreshKeyHitRects() {
    guard let stack = keyboardStackView else { return }
    keyHitRects.removeAll()
    for b in keyButtons {
        // Convert button frame into self’s coordinate space
        let frameInSelf = b.convert(b.bounds, to: self)
        // Expand the rect slightly to create gentle “neighbor” capture
        let expanded = frameInSelf.insetBy(dx: -ffNeighborInset, dy: -ffNeighborInset)
        keyHitRects[b] = expanded
    }
}
private func keyIdentifier(for button: UIButton) -> (id: KeyID, payload: String?) {
    let raw = button.accessibilityValue ?? button.title(for: .normal) ?? ""
    switch raw {
    case "SPACE":           return (.space, nil)
    case "return":          return (.returnKey, nil)
    case "⌫":               return (.backspace, nil)
    case "⇧":               return (.shift, nil)
    case "123", "ABC":      return (.mode, nil)
    case "#+=":             return (.symbols, nil)
    case "🌐":              return (.globe, nil)
    case "Secure":          return (.quickFix, nil)
    default:
        if raw.count == 1 { return (.character, raw) }
        return (.character, raw) // fallback; covers punctuation & long labels
    }
}
private func applyHover(to button: UIButton?) {
    // Remove old hover
    if let prev = fatFingerCurrentButton, prev !== button {
        UIView.animate(withDuration: 0.06) {
            prev.backgroundColor = .systemGray6
            prev.transform = .identity
        }
    }
    guard let button else { return }
    // Apply hover to new
    UIView.animate(withDuration: 0.06) {
        button.backgroundColor = .systemGray4
        button.transform = CGAffineTransform(scaleX: self.fatFingerHoverScale, y: self.fatFingerHoverScale)
    }
    fatFingerCurrentButton = button
}

private func bestButton(at point: CGPoint) -> UIButton? {
    // 1) Prefer buttons whose expanded rect contains the point
    var containing: [UIButton] = []
    for (b, rect) in keyHitRects where rect.contains(point) {
        containing.append(b)
    }
    // 2) If multiple contain, bias toward initial button
    if !containing.isEmpty {
        if let initial = fatFingerInitialButton, containing.contains(initial) {
            // Weighted pick favoring the initial
            if CGFloat.random(in: 0...1) < ffBiasTowardInitialKey { return initial }
        }
        // Otherwise closest center
        return containing.min { a, b in
            let ca = a.convert(a.bounds.center, to: self)
            let cb = b.convert(b.bounds.center, to: self)
            return ca.distance(to: point) < cb.distance(to: point)
        }
    }
    // 3) If none contain, pick globally closest center (keeps selection stable near edges)
    return keyButtons.min { a, b in
        let ca = a.convert(a.bounds.center, to: self)
        let cb = b.convert(b.bounds.center, to: self)
        return ca.distance(to: point) < cb.distance(to: point)
    }
}

@objc private func handleFatFingerPan(_ gr: UIPanGestureRecognizer) {
    let p = gr.location(in: self)

    switch gr.state {
    case .began:
        fatFingerActive = true
        refreshKeyHitRects() // in case layout just changed
        let btn = bestButton(at: p)
        fatFingerInitialButton = btn
        applyHover(to: btn)

    case .changed:
        guard fatFingerActive else { return }
        let btn = bestButton(at: p)
        if btn !== fatFingerCurrentButton {
            applyHover(to: btn)
            UIDevice.current.playInputClick()
        }

    case .ended, .cancelled, .failed:
        defer {
            // Cleanup hover
            applyHover(to: nil)
            fatFingerActive = false
            fatFingerInitialButton = nil
        }
        guard fatFingerActive else { return }
        guard let btn = bestButton(at: p) else { return }

        // Commit on release if enabled
        if ffCommitOnRelease {
            commit(button: btn)
        }

    default: break
    }
}

// MARK: - FAT FINGER: commit routing
private func commit(button: UIButton) {
    // Prefer sending .touchUpInside; this triggers your keyTapped(_:), special handlers, etc.
    // We also simulate the visual press for consistency.
    specialButtonTouchDown(button)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak self, weak button] in
        guard let self, let button else { return }
        self.specialButtonTouchUp(button)
        // Route to correct handler – mirrors a normal tap
        if self.keyButtons.contains(button) {
            self.keyTapped(button)
        } else {
            // Fallback: send actions to whatever is wired (e.g., control row)
            button.sendActions(for: .touchUpInside)
        }
    }
}

    // MARK: - FAT FINGER: Helper Methods
    
    private func registerFatFingerKeyFrames() {
        guard let root = keyboardStackView else { return }
        var frames: [FatFingerEngine.KeyFrame] = []

        for case let b as UIButton in allButtons(in: root) {
            guard let desc = describe(button: b) else { continue }
            let id = (desc.id == .character) ? (desc.label ?? "") : desc.id.rawValue
            let frame = convert(b.bounds, from: b)
            frames.append(.init(id: id, frame: frame.insetBy(dx: -3, dy: -3))) // tiny expansion helps
        }
        // Note: FatFingerEngine doesn't need explicit reconfiguration
    }

    private func allButtons(in v: UIView) -> [UIButton] {
        var out: [UIButton] = []
        func walk(_ n: UIView) {
            if let b = n as? UIButton { out.append(b) }
            n.subviews.forEach(walk)
        }
        walk(v)
        return out
    }

    /// Normalize your various titles into canonical KeyID + label
    private struct KeyDesc { let id: KeyID; let label: String? }

    private func describe(button b: UIButton) -> KeyDesc? {
        let raw = (b.accessibilityValue ?? b.title(for: .normal) ?? "").trimmingCharacters(in: .whitespaces)
        let upper = raw.uppercased()

        switch upper {
        case "SPACE":               return .init(id: .space, label: nil)
        case "RETURN", "ENTER":     return .init(id: .returnKey, label: nil)
        case "⌫", "BACKSPACE":      return .init(id: .backspace, label: nil)
        case "⇧", "SHIFT":          return .init(id: .shift, label: nil)
        case "🌐", "GLOBE":         return .init(id: .globe, label: nil)
        case "SECURE":              return .init(id: .quickFix, label: nil)
        case "#+=":                 return .init(id: .symbols, label: "#+=")
        case "123":                 return .init(id: .mode, label: "123")
        case "ABC":                 return .init(id: .mode, label: "ABC")
        default:
            // Any single visible glyph we treat as a character key
            if raw.count == 1 { return .init(id: .character, label: raw) }
            return nil
        }
    }
    
    private func handleFatFingerEvent(_ e: FatFingerEngine.Event) {
        switch e {
        case .highlight(let id):
            setKeyHighlighted(id: id, true)
        case .unhighlight(let id):
            setKeyHighlighted(id: id, false)
        case .commit(let id):
            commitKeyByID(id)
        case .cancel(let id):
            setKeyHighlighted(id: id, false)
        }
    }

    private func setKeyHighlighted(id: String, _ on: Bool) {
        // optional: tint button while hovered
        guard let b = findButton(byID: id) else { return }
        UIView.animate(withDuration: 0.06) {
            b.backgroundColor = on ? .systemGray4 : .systemGray6
            b.transform = on ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
        }
    }

    private func findButton(byID id: String) -> UIButton? {
        guard let root = keyboardStackView else { return nil }
        for case let b as UIButton in allButtons(in: root) {
            if let d = describe(button: b) {
                let bid = (d.id == .character) ? (d.label ?? "") : d.id.rawValue
                if bid == id { return b }
            }
        }
        return nil
    }

    /// Mirrors your keyTapped(_:) switch but via IDs
    private func commitKeyByID(_ id: String) {
        guard let proxy = textDocumentProxy else { return }

        switch id {
        case KeyID.space.rawValue:
            handleSpaceTap()
        case KeyID.returnKey.rawValue:
            commitAndCleanup()
            proxy.insertText("\n")
            currentText += "\n"
            handleTextChange()
        case KeyID.backspace.rawValue:
            proxy.deleteBackward()
            if !currentText.isEmpty { currentText.removeLast() }
            refreshSpellCandidates()
        case KeyID.shift.rawValue:
            handleShiftPressed()
        case KeyID.mode.rawValue:
            handleModeSwitch()
        case KeyID.symbols.rawValue:
            handleSymbolsSwitch()
        case KeyID.globe.rawValue:
            handleGlobeKey()
        case KeyID.quickFix.rawValue:
            handleQuickFix()
        default:
            // character or number/symbol
            let ch = id
            let isAlphaMode = [.letters, .compact, .expanded].contains(currentMode)
            let out = isAlphaMode ? (isShifted ? ch.uppercased() : ch.lowercased()) : ch
            proxy.insertText(out)
            currentText += out

            // auto-unshift for single letters (same logic as your tap path)
            if isAlphaMode, isShifted, !isCapsLocked, ![".", "!", "?"].contains(out) {
                isShifted = false
                updateShiftButtonAppearance()
                updateKeyTitlesForShiftState()
            }

            if [".", ",", "!", "?", ":", ";"].contains(out) {
                proxy.deleteBackward()
                currentText = String(currentText.dropLast())
                handlePunctuationInsertion(out)
            } else {
                refreshSpellCandidates()
                handleTextChange()
            }
        }
    }

    // MARK: - Secure Fix profile builders (kept as-is)
    private func buildUserProfileForSecureFix() -> [String: Any] {
        let shared = UserDefaults(suiteName: "group.com.example.unsaid")
        var profile: [String: Any] = [:]
        if let v = shared?.string(forKey: "attachment_style") { profile["attachment_style"] = v }
        if let v = shared?.string(forKey: "currentEmotionalState") { profile["emotional_state"] = v }
        if let v = shared?.string(forKey: "communication_style") { profile["communication_style"] = v }
        if let v = shared?.string(forKey: "emotional_bucket") { profile["emotional_bucket"] = v }
        if let v = shared?.string(forKey: "personality_type") { profile["personality_type"] = v }
        return profile
    }
    private func buildUserPersonalityProfile() -> [String: Any] {
        let shared = UserDefaults(suiteName: "group.com.example.unsaid")
        var profile: [String: Any] = [:]
        if let v = shared?.string(forKey: "attachment_style") { profile["attachment_style"] = v }
        if let v = shared?.string(forKey: "currentEmotionalState") { profile["emotional_state"] = v }
        if let v = shared?.string(forKey: "communication_style") { profile["communication_style"] = v }
        if let v = shared?.string(forKey: "personality_type") { profile["personality_type"] = v }
        if let v = shared?.string(forKey: "emotional_bucket") { profile["emotional_bucket"] = v }
        return profile
    }

    // Replace ALL text content with new text, simulating typing behavior with animation
    private func replaceAllText(with newText: String, on proxy: UITextDocumentProxy) {
        // First, clear all existing text
        // Move cursor to beginning
        while let before = proxy.documentContextBeforeInput, !before.isEmpty {
            proxy.adjustTextPosition(byCharacterOffset: -before.count)
        }
        
        // Delete all text before cursor
        while let before = proxy.documentContextBeforeInput, !before.isEmpty {
            proxy.deleteBackward()
        }
        
        // Delete all text after cursor by selecting and deleting
        while let after = proxy.documentContextAfterInput, !after.isEmpty {
            // Move cursor to end of text after current position
            proxy.adjustTextPosition(byCharacterOffset: after.count)
            // Then delete backwards to remove the text
            for _ in 0..<after.count {
                proxy.deleteBackward()
            }
            // Check if there's still text after cursor
            if proxy.documentContextAfterInput?.isEmpty == false {
                break // Safety break to avoid infinite loop
            }
        }
        
        // Now simulate typing animation with the new text
        simulateTypingAnimation(text: newText, on: proxy)
    }
    
    // Simulate realistic typing animation
    private func simulateTypingAnimation(text: String, on proxy: UITextDocumentProxy) {
        let characters = Array(text)
        guard !characters.isEmpty else { return }
        
        // Start typing animation
        var index = 0
        
        func typeNextCharacter() {
            guard index < characters.count else { return }
            
            let char = String(characters[index])
            proxy.insertText(char)
            
            // Provide haptic feedback occasionally during typing
            if index % 5 == 0 {
                AudioServicesPlaySystemSound(1104) // Light click sound
            }
            
            index += 1
            
            // Schedule next character with realistic typing delay
            let baseDelay: TimeInterval = 0.08 // Base typing speed
            let variance: TimeInterval = 0.04 // Add some natural variance
            let delay = baseDelay + TimeInterval.random(in: 0...variance)
            
            // Slightly longer pause after punctuation for realism
            let finalDelay = [".", "!", "?", ",", ";", ":"].contains(char) ? delay + 0.1 : delay
            
            DispatchQueue.main.asyncAfter(deadline: .now() + finalDelay) {
                typeNextCharacter()
            }
        }
        
        // Start the typing animation
        typeNextCharacter()
    }

    // MARK: - Suggestion bar (gray strip)
    private func setupSuggestionBar() {
        let bar = UIView()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.backgroundColor = UIColor.systemGray5
        addSubview(bar)
        suggestionBar = bar

        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: topAnchor),
            bar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: trailingAnchor),
            bar.heightAnchor.constraint(equalToConstant: 50)
        ])

        let tone = UIButton(type: .custom)
        tone.translatesAutoresizingMaskIntoConstraints = false
        tone.backgroundColor = UIColor.systemGray6
        tone.layer.cornerRadius = keyCornerRadius
        tone.addTarget(self, action: #selector(toggleChipOrStrip), for: .touchUpInside)
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(forceAnalysisTap))
        doubleTap.numberOfTapsRequired = 2
        tone.addGestureRecognizer(doubleTap)
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(toggleSuggestionsDisplayLongPress(_:)))
        tone.addGestureRecognizer(hold)
        bar.addSubview(tone)
        toneIndicator = tone

        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        let extensionBundle = Bundle(for: KeyboardController.self)
        var logo: UIImage? = UIImage(named: "logo_icon", in: extensionBundle, compatibleWith: nil)
        if logo == nil { logo = UIImage(named: "logo_icon") }
        if let logo = logo {
            iv.image = logo.withRenderingMode(.alwaysTemplate)
            iv.tintColor = UIColor.keyboardRose
        }
        tone.addSubview(iv)
        logoImageView = iv

        NSLayoutConstraint.activate([
            tone.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 12),
            tone.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
            tone.widthAnchor.constraint(equalToConstant: 44),
            tone.heightAnchor.constraint(equalToConstant: 44),
            iv.centerXAnchor.constraint(equalTo: tone.centerXAnchor),
            iv.centerYAnchor.constraint(equalTo: tone.centerYAnchor),
            iv.widthAnchor.constraint(equalToConstant: 44),
            iv.heightAnchor.constraint(equalToConstant: 44)
        ])

        bar.addSubview(spellStrip)
        spellStrip.translatesAutoresizingMaskIntoConstraints = false

        let undoButton = UIButton(type: .system)
        undoButton.translatesAutoresizingMaskIntoConstraints = false
        undoButton.setTitle("↶", for: .normal)
        undoButton.setTitleColor(.systemBlue, for: .normal)
        undoButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        undoButton.backgroundColor = UIColor.systemGray6
        undoButton.layer.cornerRadius = 6
        undoButton.addTarget(self, action: #selector(undoButtonTapped), for: .touchUpInside)
        undoButton.isHidden = true
        bar.addSubview(undoButton)
        undoButtonRef = undoButton

        NSLayoutConstraint.activate([
            undoButton.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -8),
            undoButton.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
            undoButton.widthAnchor.constraint(equalToConstant: 32),
            undoButton.heightAnchor.constraint(equalToConstant: 32),
            spellStrip.leadingAnchor.constraint(equalTo: tone.trailingAnchor, constant: 8),
            spellStrip.trailingAnchor.constraint(equalTo: undoButton.leadingAnchor, constant: -8),
            spellStrip.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
            spellStrip.heightAnchor.constraint(equalTo: bar.heightAnchor, multiplier: 0.8)
        ])
        undoButton.tag = 999
    }

    // MARK: - Keyboard layout
    private func setupKeyboardLayout() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = verticalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        keyboardStackView = stack

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: suggestionBar!.bottomAnchor, constant: verticalSpacing),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: sideMargins),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -sideMargins),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])

        setupControlButtons()
        updateKeyboardForCurrentMode()
    }

    private func setupControlButtons() {
        spaceButton = makeControlButton(title: "space", background: .white, text: .label)
        spaceButton?.addTarget(self, action: #selector(handleSpaceKey), for: .touchUpInside)

        // Trackpad gesture on space bar
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleSpacePan(_:)))
        pan.minimumNumberOfTouches = 1
        spaceButton?.addGestureRecognizer(pan)
        self.spacePan = pan

        globeButton = makeControlButton(title: "🌐")
        globeButton?.addTarget(self, action: #selector(handleGlobeKey), for: .touchUpInside)

        modeButton = makeControlButton(title: "123")
        modeButton?.addTarget(self, action: #selector(handleModeSwitch), for: .touchUpInside)

        symbolsButton = makeControlButton(title: "#+=")
        symbolsButton?.addTarget(self, action: #selector(handleSymbolsSwitch), for: .touchUpInside)

        deleteButton = makeControlButton(title: "⌫")
        deleteButton?.addTarget(self, action: #selector(deleteTouchDown), for: .touchDown)
        deleteButton?.addTarget(self, action: #selector(deleteTouchUp), for: [.touchUpInside, .touchCancel, .touchDragExit, .touchUpOutside])

        shiftButton = makeControlButton(title: "⇧")
        shiftButton?.addTarget(self, action: #selector(handleShiftPressed), for: .touchUpInside)

        returnButton = makeControlButton(title: "return")
        returnButton?.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        returnButton?.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)

        quickFixButton = makeControlButton(title: "Secure", background: .systemPink, text: .white)
        quickFixButton?.addTarget(self, action: #selector(handleQuickFix), for: .touchUpInside)
        quickFixButton?.widthAnchor.constraint(equalToConstant: 65).isActive = true
        quickFixButton?.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        quickFixButton?.isEnabled = true
    }

    private func updateKeyboardForCurrentMode() {
        // Dismiss all key previews when rebuilding keyboard
        dismissAllKeyPreviews()
        
        keyboardStackView?.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let (top, mid, bot) = getKeysForCurrentMode()

        let topRow = rowStack(for: top)
        let midRow = rowStack(for: mid, centerNine: true)
        let botLetters = rowStack(for: bot)

        let left = ([.letters, .compact, .expanded].contains(currentMode)) ? shiftButton : symbolsButton
        let bottomRow = UIStackView(arrangedSubviews: [left, botLetters, deleteButton].compactMap { $0 as UIView? })
        bottomRow.axis = .horizontal
        bottomRow.spacing = horizontalSpacing
        bottomRow.alignment = .fill
        bottomRow.distribution = .fill

        let controlRow = controlRowStack()

        keyboardStackView?.addArrangedSubview(topRow)
        keyboardStackView?.addArrangedSubview(midRow)
        keyboardStackView?.addArrangedSubview(bottomRow)
        keyboardStackView?.addArrangedSubview(controlRow)

        updateModeButtonTitle()
        updateShiftButtonAppearance()
        updateSecureFixButtonState()
        refreshKeyHitRects()

    }

    private func rowStack(for titles: [String], centerNine: Bool = false) -> UIStackView {
        let buttons = titles.map(makeKeyButton)
        buttons.forEach {
            $0.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
            $0.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
            $0.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchCancel, .touchDragExit, .touchUpOutside])
        }
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.spacing = horizontalSpacing
        stack.alignment = .fill
        stack.distribution = .fillEqually
        buttons.forEach { $0.heightAnchor.constraint(equalToConstant: touchTargetHeight).isActive = true }
        if centerNine && titles.count == 9 {
            stack.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            stack.isLayoutMarginsRelativeArrangement = true
        }
        return stack
    }

    private func controlRowStack() -> UIStackView {
        let arranged = [modeButton, globeButton, spaceButton, quickFixButton, returnButton].compactMap { $0 }
        let stack = UIStackView(arrangedSubviews: arranged)
        stack.axis = .horizontal
        stack.spacing = horizontalSpacing
        stack.alignment = .fill
        stack.distribution = .fill
        stack.layoutMargins = UIEdgeInsets(top: 0, left: sideMargins, bottom: 0, right: sideMargins)
        stack.isLayoutMarginsRelativeArrangement = true

        let screenWidth = UIScreen.main.bounds.width
        let available = screenWidth - (2 * sideMargins) - (4 * horizontalSpacing)
        let standardW = available * 0.15
        let widerW = available * 0.18
        let spaceW = available * 0.37

        modeButton?.widthAnchor.constraint(equalToConstant: standardW).isActive = true
        globeButton?.widthAnchor.constraint(equalToConstant: standardW).isActive = true
        spaceButton?.widthAnchor.constraint(equalToConstant: spaceW).isActive = true
        quickFixButton?.widthAnchor.constraint(equalToConstant: standardW).isActive = true
        returnButton?.widthAnchor.constraint(equalToConstant: widerW).isActive = true

        [modeButton, globeButton, spaceButton, quickFixButton, returnButton]
            .compactMap { $0 }
            .forEach { $0.heightAnchor.constraint(equalToConstant: touchTargetHeight).isActive = true }

        return stack
    }

    // MARK: - Key Capitalization Helper
    private func shouldCapitalizeKey(_ key: String) -> Bool {
        return isShifted || isCapsLocked
    }

    // MARK: - Buttons
    private func makeKeyButton(title: String) -> UIButton {
        let b = ExtendedTouchButton(type: .system)
        let display = shouldCapitalizeKey(title) ? title.uppercased() : title.lowercased()
        b.setTitle(display, for: .normal)
        b.accessibilityValue = title
        applyModernKeyStyle(to: b)
        return b
    }

    private func makeControlButton(title: String, background: UIColor = .systemGray4, text: UIColor = .label) -> UIButton {
        let b = ExtendedTouchButton(type: .system)
        b.setTitle(title, for: .normal)
        b.accessibilityValue = title
        applySpecialKeyStyle(to: b, background: background, text: text)
        b.addTarget(self, action: #selector(specialButtonTouchDown(_:)), for: .touchDown)
        b.addTarget(self, action: #selector(specialButtonTouchUp(_:)), for: [.touchUpInside, .touchCancel, .touchDragExit, .touchUpOutside])
        return b
    }

    private func applyModernKeyStyle(to b: UIButton) {
        b.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        b.backgroundColor = .systemGray6
        b.setTitleColor(.label, for: .normal)
        b.layer.cornerRadius = keyCornerRadius
        b.translatesAutoresizingMaskIntoConstraints = false
        b.widthAnchor.constraint(greaterThanOrEqualToConstant: minKeyWidth).isActive = true
        b.layer.borderWidth = 0.5
        b.layer.borderColor = UIColor.keyBorder.cgColor
        b.layer.shadowColor = UIColor.keyShadow.cgColor
        b.layer.shadowOffset = CGSize(width: 0, height: 1.5)
        b.layer.shadowOpacity = 1.0
        b.layer.shadowRadius = 1.0
        b.layer.masksToBounds = false
    }

    private func applySpecialKeyStyle(to b: UIButton, background: UIColor, text: UIColor) {
        b.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        b.backgroundColor = background
        b.setTitleColor(text, for: .normal)
        b.layer.cornerRadius = keyCornerRadius
        b.translatesAutoresizingMaskIntoConstraints = false
        b.widthAnchor.constraint(greaterThanOrEqualToConstant: minKeyWidth).isActive = true
        b.layer.borderWidth = 0.5
        b.layer.borderColor = UIColor.keyBorder.cgColor
        b.layer.shadowColor = UIColor.keyShadow.cgColor
        b.layer.shadowOffset = CGSize(width: 0, height: 2)
        b.layer.shadowOpacity = 1.0
        b.layer.shadowRadius = 1.5
        b.layer.masksToBounds = false
    }

    // MARK: - Visual/feedback
    @objc private func buttonTouchDown(_ b: UIButton) {
        UIDevice.current.playInputClick()
        impact.impactOccurred(intensity: 0.7)
        showKeyPreview(for: b)
        UIView.animate(withDuration: 0.05) {
            b.backgroundColor = .systemGray4
            b.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }
    }
    @objc private func buttonTouchUp(_ b: UIButton) {
        hideKeyPreview(for: b)
        UIView.animate(withDuration: 0.12,
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.4) {
            b.backgroundColor = .systemGray6
            b.transform = .identity
        }
    }
    @objc private func specialButtonTouchDown(_ b: UIButton) {
        UIDevice.current.playInputClick()
        impact.impactOccurred(intensity: 0.7)
        UIView.animate(withDuration: 0.05) {
            b.backgroundColor = b.title(for: .normal) == "Secure" ? .systemPink.withAlphaComponent(0.85) : .systemGray3
            b.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
        }
    }
    @objc private func specialButtonTouchUp(_ b: UIButton) {
        UIView.animate(withDuration: 0.15,
                       delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.4) {
            b.backgroundColor = b.title(for: .normal) == "Secure" ? .systemPink : .systemGray4
            b.transform = .identity
        }
    }

    // MARK: - Enhanced Key Preview Management
    private func showKeyPreview(for button: UIButton) {
        // First, hide any existing preview for this button
        hideKeyPreview(for: button)
        
        guard let title = button.title(for: .normal), !title.isEmpty else { return }
        
        let preview = KeyPreview(text: title)
        keyPreviewTable.setObject(preview, forKey: button)
        
        addSubview(preview)
        let keyFrame = convert(button.bounds, from: button)
        preview.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            preview.centerXAnchor.constraint(equalTo: leftAnchor, constant: keyFrame.midX),
            preview.bottomAnchor.constraint(equalTo: topAnchor, constant: keyFrame.minY - 6),
            preview.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
            preview.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        
        // Animate preview appearance
        preview.alpha = 0
        preview.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveEaseOut]) {
            preview.alpha = 1
            preview.transform = .identity
        }
        
        // Set up auto-dismiss timer
        let timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.hideKeyPreview(for: button)
        }
        keyPreviewAutoDismissTimers[button] = timer
    }
    
    private func hideKeyPreview(for button: UIButton) {
        // Cancel auto-dismiss timer
        keyPreviewAutoDismissTimers[button]?.invalidate()
        keyPreviewAutoDismissTimers.removeValue(forKey: button)
        
        guard let preview = keyPreviewTable.object(forKey: button) else { return }
        keyPreviewTable.removeObject(forKey: button)
        
        UIView.animate(withDuration: 0.08, animations: {
            preview.alpha = 0
            preview.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            preview.removeFromSuperview()
        }
    }
    
    private func dismissAllKeyPreviews() {
        // Cancel all timers
        keyPreviewAutoDismissTimers.values.forEach { $0.invalidate() }
        keyPreviewAutoDismissTimers.removeAll()
        
        // Remove all previews
        let allPreviews = keyPreviewTable.objectEnumerator()?.allObjects as? [KeyPreview] ?? []
        for preview in allPreviews {
            UIView.animate(withDuration: 0.08, animations: {
                preview.alpha = 0
            }) { _ in
                preview.removeFromSuperview()
            }
        }
        keyPreviewTable.removeAllObjects()
    }

    // MARK: - Key input
    @objc private func keyTapped(_ sender: UIButton) {
        guard let proxy = textDocumentProxy else { return }
        let original = sender.accessibilityValue ?? sender.title(for: .normal) ?? ""

        switch original {
        case "⌫":
            proxy.deleteBackward()
            if !currentText.isEmpty { currentText.removeLast() }
            refreshSpellCandidates()
            return
        case "return":
            commitAndCleanup()
            proxy.insertText("\n")
            currentText += "\n"
            handleTextChange()
            return
        case "⇧":
            handleShiftPressed()
            return
        case "123", "ABC":
            handleModeSwitch()
            return
        case "#+=":
            handleSymbolsSwitch()
            return
        default:
            let ch: String
            if [.letters, .compact, .expanded].contains(currentMode) {
                ch = isShifted ? original.uppercased() : original.lowercased()
            } else { ch = original }
            proxy.insertText(ch)
            currentText += ch

            // auto-unshift for single letters
            if isShifted && !isCapsLocked && [.letters, .compact, .expanded].contains(currentMode) && ![".", "!", "?"].contains(ch) {
                isShifted = false
                updateShiftButtonAppearance()
                updateKeyTitlesForShiftState()
            }

            // Use enhanced punctuation handling for punctuation marks
            if [".", ",", "!", "?", ":", ";"].contains(ch) {
                // Remove the character we just inserted since handlePunctuationInsertion will re-insert it
                proxy.deleteBackward()
                currentText = String(currentText.dropLast())
                handlePunctuationInsertion(ch)
            } else {
    // No autocorrect on plain character keys (mid-word)
            refreshSpellCandidates()
            handleTextChange()
            }

            }
        }


    // MARK: - Enhanced Space Handling
    private var lastSpaceTapTime: TimeInterval = 0
    private let doubleSpaceWindow: TimeInterval = 0.35 // tune if you support double-space="."

    @objc private func handleSpaceKey() {
        handleSpaceTap()
    }

    private func handleSpaceTap() {
        guard let proxy = textDocumentProxy else { return }

        // Sync traits with spell checker for Apple-like behavior
        spellChecker.syncFromTextTraits(proxy)

        // (A) Apple-like double-space period handling
        if spellChecker.handleDoubleSpace(proxy) {
            // Spell checker handled it, update our current text
            let before = proxy.documentContextBeforeInput ?? ""
            if before.hasSuffix(". ") {
                // Update currentText to match the spell checker's change
                if currentText.hasSuffix("  ") {
                    currentText = String(currentText.dropLast(2)) + ". "
                }
            }
            autocorrectLastWordIfNeeded(afterTyping: ".")
            handleTextChange()
            enableShiftForNextCharacter()
            return
        }

        // (B) Insert exactly ONE space
        proxy.insertText(" ")
        currentText += " "
        
        // Apple-like: reevaluate previous word after space
        _ = spellChecker.reevaluatePreviousWord(before: proxy)
        
        autocorrectLastWordIfNeeded(afterTyping: " ")

        // (C) Normalize "!. " or "?. " → "! " / "? " and ".. " → ". "
        // This cleans up the system's auto-period if it sneaks in
        let before = proxy.documentContextBeforeInput ?? ""

        if before.hasSuffix("!. ") {
            proxy.deleteBackward() // space
            proxy.deleteBackward() // period
            proxy.insertText(" ")
            // Update currentText to match
            if currentText.hasSuffix("!. ") {
                currentText = String(currentText.dropLast(2)) + " "
            }
        } else if before.hasSuffix("?. ") {
            proxy.deleteBackward()
            proxy.deleteBackward()
            proxy.insertText(" ")
            // Update currentText to match
            if currentText.hasSuffix("?. ") {
                currentText = String(currentText.dropLast(2)) + " "
            }
        } else if before.hasSuffix(".. ") {
            proxy.deleteBackward() // space
            proxy.deleteBackward() // extra "."
            proxy.insertText(" ")
            // Update currentText to match
            if currentText.hasSuffix(".. ") {
                currentText = String(currentText.dropLast(2)) + " "
            }
        }

        // Don't run heavy autocorrect on every space - save for commit/send
        refreshSpellCandidates()
        handleTextChange()
        
        // Check if we should enable shift for next character after space
        let fullText = (proxy.documentContextBeforeInput ?? "") + currentText
        if LightweightSpellChecker.shared.shouldCapitalizeNext(afterText: fullText) {
            enableShiftForNextCharacter()
        }
    }

    @objc private func handleGlobeKey() {
        parentInputVC?.advanceToNextInputMode()
    }

    @objc private func handleShiftPressed() {
        let now = CACurrentMediaTime()
        if now - lastShiftTapAt < 0.35 {
            // double-tap → caps lock
            isCapsLocked.toggle()
            isShifted = isCapsLocked
        } else {
            if isCapsLocked {
                // exiting caps lock
                isCapsLocked = false
                isShifted = false
            } else {
                isShifted.toggle()
            }
        }
        lastShiftTapAt = now
        updateShiftButtonAppearance()
        updateKeyTitlesForShiftState()
    }

    private func updateShiftButtonAppearance() {
        guard let shiftButton = shiftButton else { return }
        if isCapsLocked {
            shiftButton.backgroundColor = .systemBlue
        } else if isShifted {
            shiftButton.backgroundColor = .keyboardRose
        } else {
            shiftButton.backgroundColor = .systemGray4
        }
    }

    private func updateKeyTitlesForShiftState() {
        let now = Date()
        guard now.timeIntervalSince(lastShiftUpdateTime) > 0.1 else { return }
        lastShiftUpdateTime = now
        guard [.letters, .compact, .expanded].contains(currentMode),
              let stack = keyboardStackView else { return }
        updateKeysInStackView(stack)
    }

    private func updateKeysInStackView(_ stack: UIStackView) {
        for sub in stack.arrangedSubviews {
            if let button = sub as? UIButton,
               let original = button.accessibilityValue,
               original.count == 1,
               original.rangeOfCharacter(from: .letters) != nil {
                let display = shouldCapitalizeKey(original) ? original.uppercased() : original.lowercased()
                button.setTitle(display, for: .normal)
            } else if let nested = sub as? UIStackView {
                updateKeysInStackView(nested)
            }
        }
    }

    private func getKeysForCurrentMode() -> ([String], [String], [String]) {
        switch currentMode {
        case .letters, .compact, .expanded: return (topRowKeys, midRowKeys, botRowKeys)
        case .numbers: return (topRowNumbers, midRowNumbers, botRowNumbers)
        case .symbols: return (topRowSymbols, midRowSymbols, botRowSymbols)
        case .suggestion, .analysis, .settings: return (topRowKeys, midRowKeys, botRowKeys)
        }
    }

    private func updateModeButtonTitle() {
        switch currentMode {
        case .letters, .compact, .expanded:
            modeButton?.setTitle("123", for: .normal)
            symbolsButton?.setTitle("#+=", for: .normal)
        case .numbers:
            modeButton?.setTitle("ABC", for: .normal)
            symbolsButton?.setTitle("#+=", for: .normal)
        case .symbols:
            modeButton?.setTitle("ABC", for: .normal)
            symbolsButton?.setTitle("123", for: .normal)
        case .suggestion, .analysis, .settings:
            modeButton?.setTitle("123", for: .normal)
            symbolsButton?.setTitle("#+=", for: .normal)
        }
    }

    @objc private func handleModeSwitch() {
        triggerHapticFeedback()
        currentMode = ([.letters, .compact, .expanded].contains(currentMode)) ? .numbers : .letters
        updateKeyboardForCurrentMode()
    }

    @objc private func handleSymbolsSwitch() {
        triggerHapticFeedback()
        currentMode = (currentMode == .symbols) ? .numbers : .symbols
        updateKeyboardForCurrentMode()
    }

    // MARK: - Delete repeat
    @objc private func deleteTouchDown() {
        deletePressBeganAt = CACurrentMediaTime()
        deleteDidRepeat = false

        // Start repeating only after a short delay (feels native ~0.45s)
        deleteInitialTimer?.invalidate()
        deleteInitialTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.deleteDidRepeat = true
            self.startDeleteRepeat() // begins fast ticks
            self.triggerHapticFeedback() // subtle long-press haptic
        }
    }
    @objc private func deleteTouchUp() {
        deleteInitialTimer?.invalidate()
        deleteInitialTimer = nil

        if deleteDidRepeat {
            stopDeleteRepeat()
        } else {
            // Treat as a tap → delete once
            performDeleteTick()
        }
    }
    private func startDeleteRepeat() {
        deleteInterval = 0.12
        deleteTimer?.invalidate()
        deleteTimer = Timer.scheduledTimer(timeInterval: deleteInterval,
                                           target: self,
                                           selector: #selector(handleDeleteRepeat),
                                           userInfo: nil,
                                           repeats: true)
    }
    
    @objc private func handleDeleteRepeat() {
        performDeleteTick()
        // gentle acceleration; don't go too fast
        deleteInterval = max(0.06, deleteInterval * 0.92)
        deleteTimer?.invalidate()
        deleteTimer = Timer.scheduledTimer(timeInterval: deleteInterval,
                                           target: self,
                                           selector: #selector(handleDeleteRepeat),
                                           userInfo: nil,
                                           repeats: true)
    }
    private func performDeleteTick() {
        guard let proxy = textDocumentProxy else { return }
        if UndoManagerLite.shared.tryUndo(in: proxy) { 
            refreshSpellCandidates()
            return
        }
        proxy.deleteBackward()
        if !currentText.isEmpty { currentText.removeLast() }
        refreshSpellCandidates()
    }
    private func stopDeleteRepeat() {
        deleteTimer?.invalidate()
        deleteTimer = nil
        deleteInterval = 0.12
    }

    // MARK: - Trackpad on space bar
    @objc private func handleSpacePan(_ gr: UIPanGestureRecognizer) {
        guard let proxy = textDocumentProxy else { return }
        let translation = gr.translation(in: self)
        switch gr.state {
        case .began:
            cursorAccumulator = 0
        case .changed:
            cursorAccumulator += translation.x
            let step: CGFloat = 6 // ~6pts per char feels close to iOS
            while abs(cursorAccumulator) >= step {
                let dir = cursorAccumulator > 0 ? 1 : -1
                proxy.adjustTextPosition(byCharacterOffset: dir)
                cursorAccumulator -= step * CGFloat(dir)
            }
            gr.setTranslation(.zero, in: self)
        default:
            cursorAccumulator = 0
        }
    }

    // MARK: - Secure Fix
    @objc private func handleQuickFix() {
        updateCurrentText()
        guard let proxy = textDocumentProxy else { return }
        let before = proxy.documentContextBeforeInput ?? ""
        let after = proxy.documentContextAfterInput ?? ""
        let fullText = (before + after).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !fullText.isEmpty, fullText.count <= 300 else { return }
        
        // Use OpenAI directly for secure communication fix
        let securePrompt = "Rewrite this message to be more professional, secure, and appropriate for workplace communication. Remove any informal language, emotional content, or potentially problematic phrasing. Make it clear, respectful, and business-appropriate: \(fullText)"
        
        callOpenAI(text: securePrompt) { [weak self] result in
            guard let self = self, let proxy = self.textDocumentProxy, let fixedText = result else { return }
            
            DispatchQueue.main.async {
                self.replaceAllText(with: fixedText, on: proxy)
                self.refreshSpellCandidates()
                self.handleTextChange()
            }
        }
    }

    private func updateSecureFixButtonState() {
        let available = !openAIAPIKey.isEmpty
        quickFixButton?.isEnabled = available
        quickFixButton?.alpha = available ? 1.0 : 0.5
    }

    // MARK: - ToneSuggestionDelegate
    func didUpdateSuggestions(_ suggestions: [String]) {
        #if DEBUG
        logger.debug("🎯 didUpdateSuggestions called with: \(suggestions)")
        logger.debug("📊 Current state - suggestionChip exists: \(self.suggestionChip != nil), isSuggestionBarVisible: \(self.isSuggestionBarVisible)")
        #endif
        
        let filteredSuggestions = suggestions.first.map { [$0] } ?? []
        self.suggestions = filteredSuggestions

        if isSuggestionBarVisible {
            if let suggestion = filteredSuggestions.first {
                #if DEBUG
                logger.debug("💬 Showing suggestion chip with text: '\(suggestion)'")
                #endif
                
                // Check text relevance for smart stickiness
                let currentTextHash = generateTextHash()
                let isRelevant = suggestionChip?.isRelevantToText(currentTextHash) ?? false
                
                showSuggestionChip(text: suggestion, toneString: coordinator?.getCurrentToneStatus())
                lastDisplayedSuggestions = filteredSuggestions
            } else {
                #if DEBUG
                logger.debug("📭 No suggestions in array")
                #endif
                
                // Smart hysteresis: keep showing last suggestion if still within sticky window and relevant
                let now = Date().timeIntervalSince1970
                let currentTextHash = generateTextHash()
                let isStillRelevant = suggestionChip?.isRelevantToText(currentTextHash) ?? false
                
                if now < suggestionStickyUntil, 
                   let lastSuggestion = lastSuggestionText,
                   isStillRelevant {
                    #if DEBUG
                    logger.debug("⏰ Keeping last suggestion during relevant sticky period: '\(lastSuggestion)'")
                    #endif
                    showSuggestionChip(text: lastSuggestion, toneString: coordinator?.getCurrentToneStatus())
                } else {
                    if suggestionChip == nil {
                        #if DEBUG
                        logger.debug("🫥 Hiding suggestion chip - no relevant suggestions")
                        #endif
                        hideSuggestionChip()
                        spellStrip.isHidden = false
                        lastDisplayedSuggestions = []
                    } else {
                        #if DEBUG
                        logger.debug("👀 Not hiding suggestion chip - current chip still visible")
                        #endif
                    }
                }
            }
        } else {
            #if DEBUG
            logger.debug("🚫 Suggestion bar not visible - skipping suggestions")
            #endif
        }
    }

    func didUpdateToneStatus(_ status: String) {
        #if DEBUG
        logger.debug("didUpdateToneStatus called with: '\(status)'")
        #endif
        
        // Check if this is actually a tone change for accessibility announcement
        let previousTone = logoImageView?.accessibilityValue
        let shouldAnnounce = previousTone != status && previousTone != nil
        
        guard let iv = logoImageView else { return }
        let tint: UIColor = {
            switch status {
            case "neutral": return .keyboardRose
            case "alert": return .systemRed
            case "caution": return .systemYellow
            case "clear": return .systemGreen
            default: 
                #if DEBUG
                logger.warning("⚠️ Unknown tone status received: '\(status)' - falling back to neutral")
                #endif
                return .keyboardRose
            }
        }()
        
        UIView.animate(withDuration: 0.15, animations: { iv.alpha = 0.3 }) { _ in
            iv.tintColor = tint
            iv.accessibilityValue = status // Store for comparison
            UIView.animate(withDuration: 0.25) { iv.alpha = 1.0 }
        }
        
        // Update chip theme live when tone changes
        suggestionChip?.updateTone(chipTone(from: status))
        
        // Accessibility announcement for tone changes
        if shouldAnnounce {
            let announcement: String
            switch status {
            case "alert": announcement = "Alert tone detected"
            case "caution": announcement = "Caution tone detected"  
            case "clear": announcement = "Clear tone detected"
            case "neutral": announcement = "Neutral tone"
            default: announcement = "Tone changed"
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIAccessibility.post(notification: .announcement, argument: announcement)
            }
        }
    }

    func didUpdateSecureFixButtonState() { updateSecureFixButtonState() }
    func getTextDocumentProxy() -> UITextDocumentProxy? { textDocumentProxy }

    // MARK: - Smart sentence boundary detection
    private func lastCompletedSentence(in text: String) -> String? {
        let before = text.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces)
        guard !before.isEmpty else { return nil }
        let terms: Set<Character> = [".","!","?"]
        guard let last = before.last, terms.contains(last) else { return nil }
        let scalars = Array(before.unicodeScalars)
        var i = max(0, scalars.count - 2)
        while i >= 0 {
            let c = Character(scalars[i])
            if terms.contains(c) { break }
            i -= 1
            if i < 0 { break }
        }
        let start = max(0, i + 1)
        let sentence = String(String.UnicodeScalarView(scalars[start..<scalars.count])).trimmingCharacters(in: .whitespaces)
        return sentence.isEmpty ? nil : sentence
    }

    private func lastNaturalClause(in text: String) -> String? {
        var before = text
        if before.contains("\n") {
            let parts = before.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            if let last = parts.last?.trimmingCharacters(in: .whitespaces), !last.isEmpty { return last }
        }
        if before.contains("  ") {
            let parts = before.components(separatedBy: "  ").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            if let last = parts.last?.trimmingCharacters(in: .whitespaces), !last.isEmpty { return last }
        }
        let joiners = [" but ", " because ", " and then ", " however ", " therefore ", " though ", " although "]
        let lower = before.lowercased()
        for j in joiners {
            if let r = lower.range(of: j, options: .backwards) {
                let idx = before.index(before.startIndex, offsetBy: lower.distance(from: lower.startIndex, to: r.upperBound))
                let tail = String(before[idx...]).trimmingCharacters(in: .whitespaces)
                if !tail.isEmpty { return tail }
            }
        }
        if let _ = before.range(of: "[,;:\\-—–]+\\s*", options: .regularExpression) {
            let parts = before
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .components(separatedBy: CharacterSet(charactersIn: ",;:-—–"))
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            if let last = parts.last, !last.isEmpty { return last }
        }
        let trimmed = before.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func meetsThresholds(_ sentence: String) -> Bool {
        if sentence.count < minCharsForAnalysis { return false }
        let words = sentence.split { $0.isWhitespace }
        return words.count >= minWordsForAnalysis
    }

    private func scheduleAnalysis(for sentence: String, delay: TimeInterval) {
        guard sentence != lastAnalyzedSentence else { return }
        analysisTimer?.invalidate()
        analysisTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.lastAnalyzedSentence = sentence
            self.coordinator?.analyzeFinalSentence(sentence)
        }
    }

    // MARK: - Tone Reset
    private func resetToneIndicatorToNeutral() {
        didUpdateToneStatus("neutral")
        // Don't automatically hide suggestion chip here - let the stickiness handle it
        // hideSuggestionChip(animated: false)
        // spellStrip.isHidden = false
        // suggestions = []
        // lastDisplayedSuggestions = []
    }

    // MARK: - Suggestion Chip Management
    private func chipTone(from status: String) -> SuggestionChipView.Tone {
        switch status {
        case "alert":   return .alert
        case "caution": return .caution
        case "clear":   return .clear
        case "neutral": return .neutral
        default:        
            logger.warning("⚠️ Unknown tone status for chip: '\(status)' - falling back to neutral")
            return .neutral
        }
    }

    // MARK: - Enhanced Suggestion Chip Management
    private func showSuggestionChip(text: String, toneString: String? = nil) {
        showSuggestionChip(suggestions: [text], toneString: toneString)
    }
    
    private func showSuggestionChip(suggestions: [String], toneString: String? = nil) {
        guard let bar = suggestionBar, let toneBtn = toneIndicator else { return }
        guard !suggestions.isEmpty else { return }

        #if DEBUG
        logger.debug("showSuggestionChip called with \(suggestions.count) suggestions")
        #endif

        // Generate text hash for smart stickiness
        let currentTextHash = generateTextHash()
        
        // Smart stickiness: reduce sticky time if user starts typing a new sentence
        let now = Date().timeIntervalSince1970
        let shouldCreateNew = suggestionChip == nil
        
        if shouldCreateNew {
            // Create new chip
            createSuggestionChip(in: bar, toneBtn: toneBtn)
        }
        
        // Configure or update the chip
        let tone = chipTone(from: toneString ?? (coordinator?.getCurrentToneStatus() ?? "neutral"))
        
        if shouldCreateNew {
            suggestionChip?.configureSuggestions(suggestions, tone: tone, textHash: currentTextHash)
            suggestionChip?.present(in: bar, from: 0)
            
            // Set stickiness for new suggestions
            let stickyTime = isNewSentenceContext() ? minSuggestionShowTime * 0.5 : minSuggestionShowTime
            suggestionStickyUntil = now + stickyTime
        } else {
            // Update existing chip
            suggestionChip?.updateSuggestions(suggestions, tone: tone, textHash: currentTextHash)
            
            // Adjust stickiness based on text relevance
            if currentTextHash != lastTextHash {
                suggestionStickyUntil = now + minSuggestionShowTime * 0.7 // Reduced sticky time for new context
            }
        }
        
        lastSuggestionText = suggestions.first
        lastTextHash = currentTextHash
        spellStrip.isHidden = true
        
        #if DEBUG
        logger.debug("Suggestion chip \(shouldCreateNew ? "created" : "updated") with stickiness until: \(self.suggestionStickyUntil)")
        #endif
    }
    
    private func createSuggestionChip(in bar: UIView, toneBtn: UIButton) {
        let chip = SuggestionChipView()
        
        // Analytics hooks
        chip.onSurfaced = { [weak self] in
            self?.incrementAnalyticsCounter("suggestions_surfaced")
        }
        chip.onExpanded = { [weak self] in
            self?.incrementAnalyticsCounter("suggestions_expanded")
        }
        chip.onApplied = { [weak self] in
            self?.incrementAnalyticsCounter("suggestions_applied")
        }
        chip.onDismissed = { [weak self] in
            self?.incrementAnalyticsCounter("suggestions_dismissed")
        }
        chip.onTimeout = { [weak self] in
            self?.incrementAnalyticsCounter("suggestions_timeout")
        }
        chip.onSwipeToNext = { [weak self] in
            self?.incrementAnalyticsCounter("suggestions_swiped")
        }
        chip.onSwipeToPrevious = { [weak self] in
            self?.incrementAnalyticsCounter("suggestions_swiped")
        }
        
        // Interaction handlers
        chip.onTap = { [weak self] in
            guard let self = self,
                  let suggestion = self.suggestionChip?.getCurrentSuggestion() else { return }
            self.applySuggestionText(suggestion)
        }
        chip.onCTATap = { [weak self] in
            guard let self = self,
                  let suggestion = self.suggestionChip?.getCurrentSuggestion() else { return }
            self.applySuggestionText(suggestion)
        }
        chip.onDismiss = { [weak self] in
            self?.suggestionChip = nil
            self?.spellStrip.isHidden = false
        }
        
        suggestionChip = chip
        spellStrip.isHidden = true
        chip.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(chip)
        
        // Smart layout constraints that handle undo button collisions
        let trailingAnchor = undoButtonRef?.leadingAnchor ?? bar.trailingAnchor
        let trailingConstant: CGFloat = undoButtonRef != nil ? -8 : -12
        
        NSLayoutConstraint.activate([
            chip.leadingAnchor.constraint(equalTo: toneBtn.trailingAnchor, constant: 8),
            chip.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: trailingConstant),
            chip.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
            // Allow chip to expand vertically if needed (line wrapping in expanded mode)
            chip.topAnchor.constraint(greaterThanOrEqualTo: bar.topAnchor, constant: 4),
            chip.bottomAnchor.constraint(lessThanOrEqualTo: bar.bottomAnchor, constant: -4)
        ])
    }
    
    private func generateTextHash() -> String {
        guard let proxy = textDocumentProxy else { return "" }
        let before = proxy.documentContextBeforeInput ?? ""
        
        // Hash the last sentence or last 50 characters for relevance checking
        let relevantText = lastCompletedSentence(in: before) ?? 
                          String(before.suffix(50))
        
        return String(relevantText.trimmingCharacters(in: .whitespacesAndNewlines).hash)
    }
    
    private func isNewSentenceContext() -> Bool {
        guard let proxy = textDocumentProxy else { return false }
        let before = proxy.documentContextBeforeInput ?? ""
        
        // Check if we're at the start of a new sentence
        return before.hasSuffix(". ") || 
               before.hasSuffix("! ") || 
               before.hasSuffix("? ") ||
               before.hasSuffix("\n")
    }
    
    private func incrementAnalyticsCounter(_ key: String) {
        analyticsCounters[key, default: 0] += 1
        
        // Send lightweight analytics event (implement based on your analytics system)
        #if DEBUG
        logger.debug("📊 Analytics: \(key) = \(self.analyticsCounters[key] ?? 0)")
        #endif
        
        // You can add your analytics service call here
        // Analytics.track(event: key, properties: ["count": analyticsCounters[key]])
    }

    private func hideSuggestionChip(animated: Bool = true) {
        #if DEBUG
        logger.debug("hideSuggestionChip called (animated: \(animated))")
        #endif
        
        // Only clear stickiness if we're explicitly hiding (not just replacing)
        if animated {
            suggestionStickyUntil = 0
            lastSuggestionText = nil
            lastTextHash = ""
        }
        
        suggestionChip?.dismiss(animated: animated)
        suggestionChip = nil
        spellStrip.isHidden = false
        
        #if DEBUG
        logger.debug("Suggestion chip hidden")
        #endif
    }

    private func applySuggestionText(_ text: String) {
        guard let proxy = textDocumentProxy else { return }
        triggerHapticFeedback()
        
        // Safer apply logic: replace last sentence or respect context
        let before = proxy.documentContextBeforeInput ?? ""
        
        if let lastSentence = lastCompletedSentence(in: before) {
            // Replace the last completed sentence
            let sentenceLength = lastSentence.count + 1 // +1 for the ending punctuation
            for _ in 0..<sentenceLength {
                proxy.deleteBackward()
            }
            proxy.insertText(text)
            
            // Handle punctuation intelligently
            if !text.hasSuffix(".") && !text.hasSuffix("!") && !text.hasSuffix("?") {
                // Check if original sentence had punctuation and preserve it
                if lastSentence.last?.isPunctuation == true {
                    proxy.insertText(String(lastSentence.last!))
                }
            }
        } else {
            // Simple append for incomplete sentences
            proxy.insertText(text)
        }
        
        // Add appropriate spacing
        if !text.hasSuffix(" ") && !text.hasSuffix("\n") {
            proxy.insertText(" ")
        }
        
        hideSuggestionChip()
        handleTextChange()
    }

    // MARK: - Toggle suggestions vs. spell candidates
    @objc private func toggleChipOrStrip() {
        #if DEBUG
        logger.debug("🔘 Tone indicator button tapped")
        #endif
        
        // Keep the bar visible; just swap chip <-> strip
        if suggestionChip != nil {
            #if DEBUG
            logger.debug("📱 Hiding suggestion chip, showing spell strip")
            #endif
            hideSuggestionChip(animated: false)
            spellStrip.isHidden = false
            coordinator?.requestSuggestions() // refresh strip content
        } else {
            if let s = suggestions.first {
                #if DEBUG
                logger.debug("💬 Showing suggestion chip with existing text: '\(s)'")
                #endif
                showSuggestionChip(text: s, toneString: coordinator?.getCurrentToneStatus())
            } else {
                #if DEBUG
                logger.debug("🔍 No suggestions available, forcing analysis")
                #endif
                forceAnalysis()
            }
            spellStrip.isHidden = true
        }
        }
    

    // Optional: still allow fully hiding the bar with a long-press
    @objc private func toggleSuggestionsDisplayLongPress(_ gr: UILongPressGestureRecognizer) {
        guard gr.state == .began else { return }
        isSuggestionBarVisible.toggle()
        if isSuggestionBarVisible {
            if let s = suggestions.first {
                showSuggestionChip(text: s, toneString: coordinator?.getCurrentToneStatus())
            } else {
                spellStrip.isHidden = false
                coordinator?.requestSuggestions()
            }
        } else {
            hideSuggestionChip(animated: false)
            spellStrip.isHidden = true
        }
    }

    @objc private func toggleSuggestionsDisplay() {
        isSuggestionBarVisible.toggle()
        if isSuggestionBarVisible {
            if let s = suggestions.first {
                showSuggestionChip(text: s, toneString: coordinator?.getCurrentToneStatus())
            } else {
                spellStrip.isHidden = true
                hideSuggestionChip(animated: false)
                coordinator?.requestSuggestions()
            }
        } else {
            hideSuggestionChip()
            coordinator?.resetState()
            refreshSpellCandidates()
        }
    }

    @objc private func forceAnalysisTap() { forceAnalysis() }
    private func forceAnalysis() {
        #if DEBUG
        logger.debug("🔍 forceAnalysis() called")
        #endif
        
        guard let proxy = textDocumentProxy else { 
            #if DEBUG
            logger.debug("❌ No textDocumentProxy available")
            #endif
            return 
        }
        
        let before = proxy.documentContextBeforeInput ?? ""
        #if DEBUG
        logger.debug("📝 Text before cursor: '\(before)'")
        #endif
        
        let candidate = lastCompletedSentence(in: before) ?? lastNaturalClause(in: before)
        #if DEBUG
        logger.debug("🎯 Analysis candidate: '\(candidate ?? "nil")'")
        #endif
        
        if let s = candidate, meetsThresholds(s) {
            #if DEBUG
            logger.debug("✅ Text meets thresholds, analyzing: '\(s)'")
            #endif
            analysisTimer?.invalidate()
            lastAnalyzedSentence = s
            coordinator?.analyzeFinalSentence(s)
        } else {
            #if DEBUG
            logger.debug("❌ Text doesn't meet thresholds or is nil")
            if let s = candidate {
                logger.debug("   - Text length: \(s.count) (min: \(self.minCharsForAnalysis))")
                logger.debug("   - Word count: \(s.split { $0.isWhitespace }.count) (min: \(self.minWordsForAnalysis))")
            }
            logger.debug("🔄 Requesting suggestions directly from coordinator")
            #endif
            
            // If no suitable text found, try to request suggestions anyway
            coordinator?.requestSuggestions()
        }
    }

    // MARK: - Tone/analysis hook
    func textDidChange() { handleTextChange() }
    private func handleTextChange() {
        updateCurrentText()
        refreshSpellCandidates()

        // If the entire document is effectively empty, snap tone back to neutral.
        let beforeCtx = textDocumentProxy?.documentContextBeforeInput ?? ""
        let afterCtx  = textDocumentProxy?.documentContextAfterInput ?? ""
        let fullText = beforeCtx + afterCtx
        
        #if DEBUG
        logger.debug("handleTextChange called. Text: '\(beforeCtx)' isSuggestionBarVisible: \(self.isSuggestionBarVisible)")
        #endif
        
        if beforeCtx.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
           afterCtx.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            resetToneIndicatorToNeutral()
            analysisTimer?.invalidate()
            lastAnalyzedSentence = ""
            return
        }

        lastInputAt = Date().timeIntervalSince1970
        let before = beforeCtx
        if let sentence = lastCompletedSentence(in: before), meetsThresholds(sentence) {
            logger.debug("Found completed sentence: '\(sentence)'")
            scheduleAnalysis(for: sentence, delay: boundaryDebounce)
            return
        }
        
        // Also try analyzing without punctuation if we have enough content
        let candidate = lastNaturalClause(in: before) ?? before.trimmingCharacters(in: .whitespacesAndNewlines)
        if meetsThresholds(candidate) {
            logger.debug("Found natural clause: '\(candidate)'")
            scheduleAnalysis(for: candidate, delay: idleDebounceNoPunct)
        } else {
            logger.debug("Text doesn't meet analysis thresholds. Length: \(candidate.count), words: \(candidate.split { $0.isWhitespace }.count)")
        }
    }

    private func updateCurrentText() {
        let before = textDocumentProxy?.documentContextBeforeInput ?? ""
        let after = textDocumentProxy?.documentContextAfterInput ?? ""
        currentText = before + after
        if currentText.count > 1000 {
            currentText = String(currentText.suffix(1000))
        }
    }

    // MARK: - Spell strip integration
    private func refreshSpellCandidates() {
        let before = textDocumentProxy?.documentContextBeforeInput ?? ""
        spellChecker.quickSpellCheckAsync(text: before) { [weak self] suggestions in
            guard let self = self else { return }
            self.spellStrip.setSuggestions(suggestions) { [weak self] candidate in
                self?.applySpellCandidate(candidate)
            }
        }
        updateUndoButtonVisibility()
    }

    private func applySpellCandidate(_ candidate: String) {
        guard let proxy = textDocumentProxy else { return }
        let before = proxy.documentContextBeforeInput ?? ""
        guard let currentWord = LightweightSpellChecker.lastToken(in: before), !currentWord.isEmpty else { return }
        replaceLastWordPreservingBoundary(with: candidate, expectCurrent: currentWord)
        spellChecker.applyInlineCorrection(candidate, originalWord: currentWord)
        refreshSpellCandidates()
    }

    private func autocorrectLastWordIfNeeded(afterTyping boundary: Character) {
    // Only run on commit boundaries; never during mid-word typing
    guard correctionBoundaries.contains(boundary) else { return }
    guard let proxy = textDocumentProxy else { return }

    // Look only at text before cursor
    let before = proxy.documentContextBeforeInput ?? ""
    guard !before.isEmpty else { return }

    // We just typed the boundary; work on the token before it
    // Remove the just-typed boundary so we can fetch the last token cleanly
    let core = String(before.dropLast())

    // Grab last token
    guard let lastWord = LightweightSpellChecker.lastToken(in: core),
          !lastWord.isEmpty
    else { return }

    // Skip handles you don’t want to autocorrect (URLs, @mentions, #tags, hex codes)
    let lw = lastWord.lowercased()
    if lw.hasPrefix("@") || lw.hasPrefix("#") || lw.contains("http") { return }
    if lw.contains("/") || lw.contains("_") { return } // often IDs/paths

    // Respect your checker’s heuristics
    guard spellChecker.shouldAutoCorrect(lastWord) else { return }
    guard let correction = spellChecker.getAutoCorrection(for: lastWord),
          correction != lastWord
    else { return }

    // Replace the last word, then reinsert the boundary
    proxy.deleteBackward()                  // remove boundary
    for _ in 0..<lastWord.count { proxy.deleteBackward() }
    proxy.insertText(correction)
    proxy.insertText(String(boundary))

    // Track for undo / intentional typing
    spellChecker.applyInlineCorrection(correction, originalWord: lastWord)
    spellChecker.recordAutocorrection(lastWord)
    
    // Record with UndoManagerLite for backspace undo
    UndoManagerLite.shared.record(original: lastWord, corrected: correction)
}

    private func replaceLastWordPreservingBoundary(with newWord: String, expectCurrent: String? = nil) {
        guard let proxy = textDocumentProxy else { return }
        let before = proxy.documentContextBeforeInput ?? ""
        guard !before.isEmpty else { return }
        let boundarySet = CharacterSet(charactersIn: " \n\t.,!?;:")
        let scalars = before.unicodeScalars
        var boundaryCount = 0
        var idx = scalars.index(before: scalars.endIndex)
        while idx >= scalars.startIndex && boundarySet.contains(scalars[idx]) {
            boundaryCount += 1
            if idx == scalars.startIndex { break }
            idx = scalars.index(before: idx)
        }
        let boundarySuffix = String(String.UnicodeScalarView(scalars.suffix(boundaryCount)))
        let core = String(String.UnicodeScalarView(scalars.dropLast(boundaryCount)))
        guard let last = LightweightSpellChecker.lastToken(in: core) else { return }
        if let expect = expectCurrent, last.lowercased() != expect.lowercased() { return }
        for _ in 0..<boundaryCount { proxy.deleteBackward() }
        for _ in 0..<last.count { proxy.deleteBackward() }
        proxy.insertText(newWord + boundarySuffix)
    }

    // MARK: - Undo
    @objc private func undoButtonTapped() {
        undoLastCorrection()
    }
    private func updateUndoButtonVisibility() {
        guard let suggestionBar = suggestionBar,
              let undoButton = suggestionBar.viewWithTag(999) else { return }
        undoButton.isHidden = !spellChecker.canUndoLastCorrection()
    }
    private func undoLastCorrection() {
        guard let proxy = textDocumentProxy,
              let last = spellChecker.getUndoCorrection() else { return }
        let before = proxy.documentContextBeforeInput ?? ""

        if let token = LightweightSpellChecker.lastToken(in: before),
           token == last.corrected {
            var boundarySuffix = ""
            var core = before
            while let lastChar = core.last,
                  " \n\t.,!?;:".contains(lastChar) {
                boundarySuffix = String(lastChar) + boundarySuffix
                proxy.deleteBackward()
                core.removeLast()
            }
            for _ in 0..<token.count { proxy.deleteBackward() }
            proxy.insertText(last.original + boundarySuffix)
        } else {
            proxy.insertText(last.original)
        }

        spellChecker.recordIntentionalWord(last.original)
        spellChecker.clearUndoHistory()
        updateUndoButtonVisibility()
    }
    
    // MARK: - Enhanced Punctuation and Mode Helpers
    private func handlePunctuationInsertion(_ punctuation: String) {
        guard let proxy = textDocumentProxy else { return }
        proxy.insertText(punctuation)
        currentText += punctuation
        
        // Get current context for spell checker recommendations
        let fullText = (proxy.documentContextBeforeInput ?? "") + currentText
        
        // For sentence-ending punctuation, add space and switch to alphabetic mode
        if [".", "!", "?"].contains(punctuation) {
            if let b = punctuation.first { autocorrectLastWordIfNeeded(afterTyping: b) }
            proxy.insertText(" ")
            currentText += " "
            // Apple-like: reevaluate previous word after punctuation
            _ = spellChecker.reevaluatePreviousWord(before: proxy)
            switchToAlphabeticKeyboard()
        } else if [",", ";", ":"].contains(punctuation) {
            if let b = punctuation.first { autocorrectLastWordIfNeeded(afterTyping: b) }
            proxy.insertText(" ")
            currentText += " "
            // Apple-like: reevaluate previous word after punctuation
            _ = spellChecker.reevaluatePreviousWord(before: proxy)
            
            // Check if spell checker recommends switching to ABC mode
            if let lastChar = punctuation.first,
               LightweightSpellChecker.shared.shouldSwitchToABCMode(afterText: fullText + " ", lastCharacter: lastChar) {
                switchToAlphabeticKeyboard()
            }
        }
        
         // Don't run autocorrect on every punctuation keystroke - save for commit/send
        refreshSpellCandidates()
        handleTextChange()
    }
    
    private func switchToAlphabeticKeyboard() {
        if [.numbers, .symbols].contains(currentMode) {
            triggerHapticFeedback()
            currentMode = .letters
            updateKeyboardForCurrentMode()
        }
        // Enable shift for next character using spell checker logic
        enableShiftForNextCharacter()
    }
    
    private func enableShiftForNextCharacter() {
        guard let proxy = textDocumentProxy else { return }
        let fullText = (proxy.documentContextBeforeInput ?? "") + currentText
        
        if LightweightSpellChecker.shared.shouldCapitalizeNext(afterText: fullText) {
            isShifted = true
            isCapsLocked = false
            updateShiftButtonAppearance()
            updateKeyTitlesForShiftState()
        }
    }
    
    // MARK: - Autocorrect Helper Functions
    func shouldCommitNow(before: String?, after: String?) -> Bool {
        // commit when the char just typed was space/punct or after is nil/space/punct
        let boundaryChars = CharacterSet.whitespaces.union(.punctuationCharacters)
        if let last = before?.last, boundaryChars.contains(last.unicodeScalars.first!) { return true }
        if let a = after, a.isEmpty || boundaryChars.contains(a.unicodeScalars.first!) { return true }
        return false
    }
    
    func applyTextReplacements(_ text: String) -> String {
        let pairs = UserDefaults.standard.array(forKey: "TextReplacements") as? [[String:String]] ?? []
        var out = text
        for map in pairs {
            guard let from = map["from"], let to = map["to"] else { continue }
            let pat = "\\b\(NSRegularExpression.escapedPattern(for: from))\\b"
            out = out.replacingOccurrences(of: pat, with: to, options: .regularExpression)
        }
        return out
    }
    
    func typographicNormalize(_ s: String) -> String {
        var t = s
        t = t.replacingOccurrences(of: "...", with: "…")
        t = t.replacingOccurrences(of: "--",  with: "—")
        t = t.replacingOccurrences(of: " \"", with: " \"")
        t = t.replacingOccurrences(of: "\" ", with: "\" ")
        t = t.replacingOccurrences(of: " 1/2", with: " ½")
        return t
    }
    
    func shouldCapNext(_ before: String) -> Bool {
        guard let last = before.last else { return true }
        let enders = ".!?\"')"
        return enders.contains(last)
    }
    
    // MARK: - Commit and Cleanup
    private func commitAndCleanup() {
        guard let proxy = textDocumentProxy else { return }
        guard var text = proxy.documentContextBeforeInput else { return }
        
        // Run your LightweightSpellChecker cleanup once, here:
        text = LightweightSpellChecker.shared.applyPunctuationRules(to: text)
        
        // Replace the existing text with the cleaned version
        let originalLength = (proxy.documentContextBeforeInput ?? "").count
        for _ in 0..<originalLength {
            proxy.deleteBackward()
        }
        
        // Insert the cleaned text
        proxy.insertText(text)
        
        // Update our local text cache
        currentText = text
    }
    
    private func triggerHapticFeedback() {
        impact.impactOccurred(intensity: 0.5)
    }
}
// MARK: - ExtendedTouchButton (bigger touch target)
private final class ExtendedTouchButton: UIButton {
    private let mainTouchTargetSize: CGFloat = 46.0
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let w = max(0, mainTouchTargetSize - bounds.width)
        let h = max(0, mainTouchTargetSize - bounds.height)
        let expanded = bounds.insetBy(dx: -w/2, dy: -h/2)
        return expanded.contains(point)
    }
}
private extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}

private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx*dx + dy*dy)
    }
}
