//
//  SuggestionChipView.swift
//  UnsaidKeyboard
//
//  Polished Single-Suggestion Chip with multi-suggestion support
//

import Foundation
import UIKit

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
            content.leadingAnchor.constraint(equalTo: leadingAnchor),
            content.trailingAnchor.constraint(equalTo: trailingAnchor),
            content.bottomAnchor.constraint(equalTo: bottomAnchor),
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

        // CTA button (initially hidden)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.setTitle("Apply", for: .normal)
        ctaButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        ctaButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        ctaButton.layer.cornerRadius = 12
        ctaButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        ctaButton.accessibilityLabel = "Apply suggestion"
        ctaButton.addAction(UIAction { [weak self] _ in
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
            compactStack.topAnchor.constraint(equalTo: content.topAnchor, constant: 8),
            compactStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 12),
            compactStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -12),
            compactStack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -8)
        ]

        expandedConstraints = [
            compactStack.topAnchor.constraint(equalTo: content.topAnchor, constant: 12),
            compactStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
            compactStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
            ctaButton.topAnchor.constraint(equalTo: compactStack.bottomAnchor, constant: 8),
            ctaButton.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            ctaButton.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -12)
        ]

        // Start with compact layout
        NSLayoutConstraint.activate(compactConstraints)

        // Tap behavior
        addAction(UIAction { [weak self] _ in
            self?.onTap?()
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
            let rotation = self?.isExpanded == true ? CGAffineTransform(rotationAngle: .pi/2) : .identity
            self?.chevronButton.transform = rotation
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) { [weak self] in
            guard let self = self else { return }
            
            NSLayoutConstraint.deactivate(self.isExpanded ? self.compactConstraints : self.expandedConstraints)
            NSLayoutConstraint.activate(self.isExpanded ? self.expandedConstraints : self.compactConstraints)
            
            self.ctaButton.alpha = self.isExpanded ? 1 : 0
            self.superview?.layoutIfNeeded()
        }
        
        // Update accessibility
        chevronButton.accessibilityLabel = isExpanded ? "Collapse suggestion" : "Expand suggestion"
    }

    // MARK: - Multi-suggestion support
    func configureSuggestions(_ suggestions: [String], tone: ToneStatus, textHash: String = "") {
        self.suggestions = suggestions
        self.currentIndex = 0
        self.associatedTextHash = textHash
        
        updatePagerDots()
        updateCurrentSuggestion()
        applyTone(tone, animated: false)
        
        // Analytics
        onSurfaced?()
    }
    
    func updateSuggestions(_ suggestions: [String], tone: ToneStatus, textHash: String = "") {
        let previousTextHash = self.associatedTextHash
        self.suggestions = suggestions
        self.associatedTextHash = textHash
        
        // Smart stickiness: only keep current index if text context is similar
        if previousTextHash != textHash {
            self.currentIndex = 0
        } else {
            // Keep current index within bounds
            self.currentIndex = min(self.currentIndex, suggestions.count - 1)
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
            dot.backgroundColor = UIColor.white.withAlphaComponent(0.5)
            dot.layer.cornerRadius = 3
            dot.widthAnchor.constraint(equalToConstant: 6).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 6).isActive = true
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
            stackView.topAnchor.constraint(equalTo: pagerView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: pagerView.leadingAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: pagerView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: pagerView.bottomAnchor)
        ])
    }
    
    private func updateCurrentSuggestion() {
        guard currentIndex < suggestions.count else { return }
        titleLabel.text = suggestions[currentIndex]
        accessibilityLabel = suggestions[currentIndex]
        
        // Update pager dots opacity
        for (i, dot) in pagerDots.enumerated() {
            let isActive = i == currentIndex
            dot.alpha = isActive ? 1.0 : 0.5
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
            self?.onTimeout?()
            self?.dismiss(animated: true)
        }
    }
    
    // MARK: - Text relevance checking
    func isRelevantToText(_ textHash: String) -> Bool {
        return associatedTextHash == textHash && !associatedTextHash.isEmpty
    }

    func configure(text: String, tone: ToneStatus) {
        configureSuggestions([text], tone: tone)
    }

    func updateTone(_ tone: ToneStatus) {
        applyTone(tone, animated: true)
    }
    
    func getCurrentSuggestion() -> String? {
        guard currentIndex < suggestions.count else { return nil }
        return suggestions[currentIndex]
    }

    private func applyTone(_ tone: ToneStatus, animated: Bool) {
        let (bg, icon, textColor, iconColor) = toneColors(tone)
        let apply = { [weak self] in
            self?.content.backgroundColor = bg
            self?.iconView.image = UIImage(systemName: icon)
            self?.titleLabel.textColor = textColor
            self?.iconView.tintColor = iconColor
        }
        if animated {
            UIView.transition(with: content, duration: 0.15, options: [.transitionCrossDissolve], animations: apply)
        } else {
            apply()
        }
    }

    /// (bg, icon, titleColor, iconColor)
    private func toneColors(_ tone: ToneStatus) -> (UIColor, String, UIColor, UIColor) {
        switch tone {
        case .neutral: return (UIColor.keyboardRose.withAlphaComponent(0.90), "sparkles", .white, .white)
        case .alert:   return (UIColor.systemRed.withAlphaComponent(0.95), "exclamationmark.triangle.fill", .white, .white)
        case .caution: return (UIColor.systemYellow.withAlphaComponent(0.95), "exclamationmark.triangle.fill", .black, .black)
        case .clear:   return (UIColor.systemGreen.withAlphaComponent(0.92), "checkmark.seal.fill", .white, .white)
        }
    }

    private func animateTap() {
        UIView.animate(withDuration: 0.08, animations: { [weak self] in
            self?.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }) { [weak self] _ in
            UIView.animate(withDuration: 0.08) {
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
            self?.transform = CGAffineTransform(translationX: 0, y: -6)
        }
        let done: (Bool) -> Void = { [weak self] _ in
            self?.removeFromSuperview()
        }
        if animated {
            UIView.animate(withDuration: 0.15, animations: work, completion: done)
        } else {
            work()
            done(true)
        }
    }
    
    deinit {
        autoHideTimer?.invalidate()
    }
}
