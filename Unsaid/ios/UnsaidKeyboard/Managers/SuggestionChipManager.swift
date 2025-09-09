//
//  SuggestionChipManager.swift
//  UnsaidKeyboard
//
//  Manages the polished suggestion chip UI and its interactions
//

import Foundation
import UIKit

protocol SuggestionChipManagerDelegate: AnyObject {
    func didTapSuggestion(_ suggestion: String)
    func didDismissSuggestion()
    func didExpandSuggestion()
    func didSwipeToNextSuggestion()
    func didSwipeToPreviousSuggestion()
}

enum ToneStatus: String, CaseIterable {
    case neutral = "neutral"
    case alert = "alert"
    case caution = "caution" 
    case clear = "clear"
}

final class SuggestionChipManager {
    weak var delegate: SuggestionChipManagerDelegate?
    
    private var currentChip: SuggestionChipView?
    private var suggestionBar: UIView?
    private var toneButton: UIButton?
    
    // State tracking
    private var lastSuggestionText: String?
    private var suggestionStickyUntil: TimeInterval = 0
    private let minSuggestionShowTime: TimeInterval = 8.0
    
    init() {}
    
    // MARK: - Public Interface
    
    func configure(suggestionBar: UIView, toneButton: UIButton) {
        self.suggestionBar = suggestionBar
        self.toneButton = toneButton
    }
    
    func showSuggestionChip(text: String, toneString: String? = nil) {
        showSuggestionChip(suggestions: [text], toneString: toneString)
    }
    
    func showSuggestionChip(suggestions: [String], toneString: String? = nil) {
        guard !suggestions.isEmpty,
              let suggestionBar = suggestionBar,
              let toneButton = toneButton else { return }
        
        let tone = chipTone(from: toneString)
        
        // Remove existing chip
        hideSuggestionChip(animated: false)
        
        // Create new chip
        let chip = createSuggestionChip(in: suggestionBar, toneBtn: toneButton)
        chip.configureSuggestions(suggestions, tone: tone, textHash: generateTextHash())
        
        // Setup callbacks
        setupChipCallbacks(chip)
        
        // Present with animation
        chip.present(in: suggestionBar, from: 0)
        
        // Update state
        currentChip = chip
        lastSuggestionText = suggestions.first
        suggestionStickyUntil = CACurrentMediaTime() + minSuggestionShowTime
    }
    
    func hideSuggestionChip(animated: Bool = true) {
        currentChip?.dismiss(animated: animated)
        currentChip = nil
        lastSuggestionText = nil
        suggestionStickyUntil = 0
    }
    
    func updateSuggestions(_ suggestions: [String], toneString: String? = nil) {
        guard let chip = currentChip else {
            showSuggestionChip(suggestions: suggestions, toneString: toneString)
            return
        }
        
        let tone = chipTone(from: toneString)
        chip.updateSuggestions(suggestions, tone: tone, textHash: generateTextHash())
    }
    
    func shouldShowSuggestions() -> Bool {
        return CACurrentMediaTime() > suggestionStickyUntil
    }
    
    // MARK: - Private Implementation
    
    private func createSuggestionChip(in bar: UIView, toneBtn: UIButton) -> SuggestionChipView {
        let chip = SuggestionChipView()
        bar.addSubview(chip)
        
        NSLayoutConstraint.activate([
            chip.leadingAnchor.constraint(equalTo: toneBtn.trailingAnchor, constant: 12),
            chip.trailingAnchor.constraint(lessThanOrEqualTo: bar.trailingAnchor, constant: -12),
            chip.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
            chip.heightAnchor.constraint(lessThanOrEqualToConstant: 44)
        ])
        
        return chip
    }
    
    private func setupChipCallbacks(_ chip: SuggestionChipView) {
        chip.onTap = { [weak self] in
            guard let suggestion = chip.getCurrentSuggestion() else { return }
            self?.delegate?.didTapSuggestion(suggestion)
            self?.incrementAnalyticsCounter("suggestion_applied")
        }
        
        chip.onDismiss = { [weak self] in
            self?.delegate?.didDismissSuggestion()
            self?.hideSuggestionChip(animated: true)
            self?.incrementAnalyticsCounter("suggestion_dismissed")
        }
        
        chip.onExpanded = { [weak self] in
            self?.delegate?.didExpandSuggestion()
            self?.incrementAnalyticsCounter("suggestion_expanded")
        }
        
        chip.onSwipeToNext = { [weak self] in
            self?.delegate?.didSwipeToNextSuggestion()
            self?.incrementAnalyticsCounter("suggestion_swipe_next")
        }
        
        chip.onSwipeToPrevious = { [weak self] in
            self?.delegate?.didSwipeToPreviousSuggestion()
            self?.incrementAnalyticsCounter("suggestion_swipe_previous")
        }
        
        chip.onSurfaced = { [weak self] in
            self?.incrementAnalyticsCounter("suggestion_surfaced")
        }
        
        chip.onApplied = { [weak self] in
            self?.incrementAnalyticsCounter("suggestion_applied")
        }
        
        chip.onDismissed = { [weak self] in
            self?.incrementAnalyticsCounter("suggestion_dismissed")
        }
        
        chip.onTimeout = { [weak self] in
            self?.incrementAnalyticsCounter("suggestion_timeout")
        }
    }
    
    private func chipTone(from status: String?) -> ToneStatus {
        guard let status = status?.lowercased() else { return .neutral }
        
        switch status {
        case "alert", "harsh", "aggressive", "angry": return .alert
        case "caution", "warning", "passive aggressive": return .caution
        case "clear", "positive", "supportive", "kind": return .clear
        default: return .neutral
        }
    }
    
    private func generateTextHash() -> String {
        let text = "current_context" // This would be passed from the main controller
        var hasher = Hasher()
        hasher.combine(text)
        return String(hasher.finalize())
    }
    
    private func incrementAnalyticsCounter(_ key: String) {
        // Use SafeKeyboardDataStorage for analytics
        SafeKeyboardDataStorage.shared.incrementCounter(key)
    }
}
