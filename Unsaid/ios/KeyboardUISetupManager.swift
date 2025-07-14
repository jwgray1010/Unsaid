//
//  KeyboardUISetupManager.swift
//  Unsaid - AI-Powered Keyboard Extension (Grammarly-style)
//
//  Created by John Gray on 7/7/25.
//
import Foundation
// If needed for color extensions:
#if canImport(UIKit)
import UIKit
#endif 

class KeyboardUISetupManager {
    
    weak var viewController: KeyboardViewController?
    
    // UI Components
    private var suggestionBanner: UIView?
    private var toneIndicator: UIView?
    private var suggestionLabel: UILabel?
    private var fixButton: UIButton?
    
    // Private Properties
    private var currentSuggestedFix: String = ""

    init(viewController: KeyboardViewController) {
        self.viewController = viewController
    }
    
    func setupGrammarlyStyleKeyboard() {
        setupBaseKeyboard()
        setupToneIndicator()
        setupSuggestionBanner()
        setupKeyboardButtons()
    }
    
    private func setupBaseKeyboard() {
        guard let viewController = viewController else { return }
        
        // Use Apple's default keyboard appearance with gray suggestion area
        viewController.view.backgroundColor = UIColor.systemGray6
        
        // Set initial height for the gray suggestion bar (compact)
        viewController.preferredContentSize = CGSize(width: 0, height: 44)
    }
    
    
    private func setupToneIndicator() {
        guard let viewController = viewController else { return }
        
        // Create the tone indicator container (circular like Grammarly)
        toneIndicator = UIView()
        toneIndicator?.translatesAutoresizingMaskIntoConstraints = false
        toneIndicator?.backgroundColor = UIColor.systemGray6
        toneIndicator?.layer.cornerRadius = 14 // Circular with 28x28 size
        toneIndicator?.layer.borderWidth = 1
        toneIndicator?.layer.borderColor = UIColor.systemGray4.cgColor
        toneIndicator?.layer.shadowColor = UIColor.black.cgColor
        toneIndicator?.layer.shadowOffset = CGSize(width: 0, height: 1)
        toneIndicator?.layer.shadowRadius = 2
        toneIndicator?.layer.shadowOpacity = 0.1
        toneIndicator?.isHidden = true // Initially hidden
        
        // Create the logo image view
        let logoImageView = UIImageView()
        logoImageView.image = UIImage(named: "logo_icon")?.withRenderingMode(.alwaysOriginal)
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.tag = 999 // Tag to identify the logo for color changes
        
        // Add tap gesture to toggle suggestion display
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toneIndicatorTapped))
        toneIndicator?.addGestureRecognizer(tapGesture)
        toneIndicator?.isUserInteractionEnabled = true
        
        guard let toneIndicator = toneIndicator else { return }
        toneIndicator.addSubview(logoImageView)
        viewController.view.addSubview(toneIndicator)
        
        // Position in the gray suggestion bar area (left side)
        NSLayoutConstraint.activate([
            toneIndicator.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor),
            toneIndicator.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 8),
            toneIndicator.widthAnchor.constraint(equalToConstant: 28),
            toneIndicator.heightAnchor.constraint(equalToConstant: 28),
            
            // Logo image constraints
            logoImageView.centerXAnchor.constraint(equalTo: toneIndicator.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: toneIndicator.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 24),
            logoImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    private func setupSuggestionBanner() {
        guard let viewController = viewController else { return }
        
        // Create the suggestion area in the gray space above keyboard (like Grammarly)
        suggestionBanner = UIView()
        suggestionBanner?.translatesAutoresizingMaskIntoConstraints = false
        suggestionBanner?.backgroundColor = UIColor.systemGray6 // Match the gray suggestion bar
        suggestionBanner?.isHidden = true // Initially hidden
        
        // Suggestion text (appears to the right of the tone indicator)
        suggestionLabel = UILabel()
        suggestionLabel?.translatesAutoresizingMaskIntoConstraints = false
        suggestionLabel?.font = UIFont.systemFont(ofSize: 13)
        suggestionLabel?.textColor = UIColor.label
        suggestionLabel?.numberOfLines = 0 // Allow multiple lines if needed
        suggestionLabel?.text = "Consider rephrasing to sound more professional"
        
        // Fix button (positioned on the right side)
        fixButton = UIButton(type: .system)
        fixButton?.setTitle("Fix", for: .normal)
        fixButton?.backgroundColor = UIColor.systemBlue
        fixButton?.setTitleColor(.white, for: .normal)
        fixButton?.layer.cornerRadius = 6
        fixButton?.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        fixButton?.translatesAutoresizingMaskIntoConstraints = false
        fixButton?.addTarget(self, action: #selector(fixButtonTapped), for: .touchUpInside)
        
        guard let suggestionBanner = suggestionBanner,
              let suggestionLabel = suggestionLabel,
              let fixButton = fixButton else { return }
        
        suggestionBanner.addSubview(suggestionLabel)
        suggestionBanner.addSubview(fixButton)
        viewController.view.addSubview(suggestionBanner)
        
        // Layout the suggestion banner to fill the gray space
        NSLayoutConstraint.activate([
            // Banner fills the full width and height of keyboard view
            suggestionBanner.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            suggestionBanner.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            suggestionBanner.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            suggestionBanner.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
            
            // Suggestion label (next to tone indicator with padding)
            suggestionLabel.centerYAnchor.constraint(equalTo: suggestionBanner.centerYAnchor),
            suggestionLabel.leadingAnchor.constraint(equalTo: suggestionBanner.leadingAnchor, constant: 44), // Leave space for tone indicator
            suggestionLabel.trailingAnchor.constraint(equalTo: fixButton.leadingAnchor, constant: -8),
            
            // Fix button (right side)
            fixButton.centerYAnchor.constraint(equalTo: suggestionBanner.centerYAnchor),
            fixButton.trailingAnchor.constraint(equalTo: suggestionBanner.trailingAnchor, constant: -8),
            fixButton.widthAnchor.constraint(equalToConstant: 50),
            fixButton.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
    
    
    private func setupKeyboardButtons() {
        guard let viewController = viewController else { return }
        
        // Next Keyboard Button (globe icon)
        viewController.nextKeyboardButton = UIButton(type: .system)
        viewController.nextKeyboardButton.setTitle("🌐", for: [])
        viewController.nextKeyboardButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        viewController.nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        viewController.nextKeyboardButton.addTarget(viewController, action: #selector(KeyboardViewController.handleInputModeList(from:with:)), for: .allTouchEvents)
        
        viewController.view.addSubview(viewController.nextKeyboardButton)
        
        NSLayoutConstraint.activate([
            viewController.nextKeyboardButton.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor, constant: -8),
            viewController.nextKeyboardButton.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 8),
            viewController.nextKeyboardButton.widthAnchor.constraint(equalToConstant: 44),
            viewController.nextKeyboardButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    // MARK: - Public Methods
    
    func showToneIndicator(status: ToneStatus) {
        guard let toneIndicator = toneIndicator else { return }
        
        DispatchQueue.main.async {
            // Find the logo image view
            guard let logoImageView = toneIndicator.viewWithTag(999) as? UIImageView else { return }
            
            // Apply background color changes only - keep logo original colors
            switch status {
            case .clear:
                // Green background container, original logo colors
                toneIndicator.backgroundColor = UIColor.systemGreen
                toneIndicator.layer.borderColor = UIColor.systemGreen.cgColor
                toneIndicator.layer.borderWidth = 2
            case .caution:
                // Orange background container, original logo colors
                toneIndicator.backgroundColor = UIColor.systemOrange
                toneIndicator.layer.borderColor = UIColor.systemOrange.cgColor
                toneIndicator.layer.borderWidth = 2
            case .alert:
                // Red background container, original logo colors
                toneIndicator.backgroundColor = UIColor.systemRed
                toneIndicator.layer.borderColor = UIColor.systemRed.cgColor
                toneIndicator.layer.borderWidth = 2
            case .neutral, .analyzing:
                // White background container, original logo colors
                toneIndicator.backgroundColor = UIColor.white
                toneIndicator.layer.borderColor = UIColor.systemGray4.cgColor
                toneIndicator.layer.borderWidth = 1
            }
            
            // Keep the logo in its original colors (don't change tint)
            logoImageView.image = logoImageView.image?.withRenderingMode(.alwaysOriginal)
            
            toneIndicator.isHidden = false
            
            // Animate appearance
            toneIndicator.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                toneIndicator.transform = .identity
            }
        }
    }
    
    func hideToneIndicator() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2) {
                self.toneIndicator?.alpha = 0
            } completion: { _ in
                self.toneIndicator?.isHidden = true
                self.toneIndicator?.alpha = 1
            }
        }
    }
    
    func showSuggestion(text: String, suggestedFix: String) {
        guard let suggestionBanner = suggestionBanner,
              let suggestionLabel = suggestionLabel else { return }
        
        DispatchQueue.main.async {
            suggestionLabel.text = text
            
            // Store the suggested fix for the fix button
            self.currentSuggestedFix = suggestedFix
            
            // Calculate required height based on text length
            let requiredHeight = self.calculateRequiredHeight(for: text)
            
            // Expand keyboard height if needed to accommodate longer suggestions
            self.viewController?.preferredContentSize = CGSize(width: 0, height: requiredHeight)
            
            // Show the suggestion in the gray bar
            suggestionBanner.isHidden = false
            
            // Subtle fade-in animation
            suggestionBanner.alpha = 0
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.1) {
                suggestionBanner.alpha = 1
            }
        }
    }
    
    func hideSuggestion() {
        guard let suggestionBanner = suggestionBanner else { return }
        
        DispatchQueue.main.async {
            // Fade out animation
            UIView.animate(withDuration: 0.2) {
                suggestionBanner.alpha = 0
            } completion: { _ in
                suggestionBanner.isHidden = true
                suggestionBanner.alpha = 1
                
                // Return to compact height
                self.viewController?.preferredContentSize = CGSize(width: 0, height: 44)
            }
        }
    }
    
    // Calculate required height based on suggestion text length
    private func calculateRequiredHeight(for text: String) -> CGFloat {
        let maxWidth = UIScreen.main.bounds.width - 110 // Account for icon and button space
        let font = UIFont.systemFont(ofSize: 13)
        
        let boundingRect = text.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        
        let textHeight = ceil(boundingRect.height)
        let minHeight: CGFloat = 44 // Minimum compact height
        let maxHeight: CGFloat = 88 // Maximum before it gets too tall
        
        // Add padding and ensure it's within bounds
        let requiredHeight = max(minHeight, min(maxHeight, textHeight + 20))
        
        return requiredHeight
    }
    
    // MARK: - Action Methods
    
    @objc private func toneIndicatorTapped() {
        // Toggle suggestion visibility when tone indicator is tapped
        guard let suggestionBanner = suggestionBanner else { return }
        
        if suggestionBanner.isHidden {
            // Show suggestion if we have one stored
            if !currentSuggestedFix.isEmpty {
                let suggestionText = suggestionLabel?.text ?? "Tap for suggestion"
                showSuggestion(text: suggestionText, suggestedFix: currentSuggestedFix)
            } else {
                // Show detailed tone analysis if no suggestion
                viewController?.showDetailedToneAnalysis()
            }
        } else {
            // Hide suggestion if currently showing
            hideSuggestion()
        }
    }
    
    @objc private func fixButtonTapped() {
        // Apply the AI suggestion
        viewController?.applySuggestion(currentSuggestedFix)
        hideSuggestion()
    }
    
    @objc private func dismissSuggestion() {
        hideSuggestion()
    }
    
    func calculateOptimalHeight() -> CGFloat {
        let hasSuggestion = !(suggestionBanner?.isHidden ?? true)
        if hasSuggestion, let suggestionText = suggestionLabel?.text {
            return calculateRequiredHeight(for: suggestionText)
        }
        return 44 // Compact height for gray bar
    }
    
    // Store suggestion for later display when user taps tone indicator
    func storeSuggestionForLater(text: String, suggestedFix: String) {
        suggestionLabel?.text = text
        currentSuggestedFix = suggestedFix
        // Don't show immediately - wait for user to tap tone indicator
    }
    
    // Check if we have a stored suggestion
    func hasStoredSuggestion() -> Bool {
        return !currentSuggestedFix.isEmpty
    }
    
    // Clear stored suggestion
    func clearStoredSuggestion() {
        currentSuggestedFix = ""
        suggestionLabel?.text = ""
    }
}
