//
//  SuggestionPopupManager.swift
//  UnsaidKeyboard
//
//  Created by John Gray on 7/17/25.
//

import UIKit

protocol SuggestionPopupDelegate: AnyObject {
    func suggestionPopupDidSelectSuggestion(_ suggestion: String)
    func suggestionPopupDidDismiss()
}

class SuggestionPopupManager {
    
    // MARK: - Properties
    
    weak var delegate: SuggestionPopupDelegate?
    private var containerView: UIView?
    
    // Popup UI elements
    private var popupContainer: UIView?
    private var suggestionLabel: UILabel?
    private var dismissTimer: Timer?
    
    // Animation properties
    private let animationDuration: TimeInterval = 0.3
    private let autoDismissDelay: TimeInterval = 4.0
    
    // MARK: - Initialization
    
    init() {
        setupPopupUI()
    }
    
    deinit {
        dismissTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    func configure(with containerView: UIView) {
        self.containerView = containerView
    }
    
    func showSuggestion(_ suggestion: String, fromButton button: UIButton) {
        guard let containerView = containerView else {
            print(" SuggestionPopupManager: No container view configured")
            return
        }
        
        // Cancel any existing timer
        dismissTimer?.invalidate()
        
        // Hide existing popup if showing
        hidePopup(animated: false)
        
        // Update suggestion text
        suggestionLabel?.text = suggestion
        
        // Add popup to container
        if let popupContainer = popupContainer {
            containerView.addSubview(popupContainer)
            setupPopupConstraints(relativeTo: button)
            
            // Animate in
            showPopupWithAnimation()
            
            // Set auto-dismiss timer
            startAutoDismissTimer()
        }
    }
    
    func hidePopup(animated: Bool = true) {
        guard let popupContainer = popupContainer, popupContainer.superview != nil else {
            return
        }
        
        dismissTimer?.invalidate()
        
        if animated {
            UIView.animate(withDuration: animationDuration, animations: {
                popupContainer.alpha = 0
                popupContainer.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }) { _ in
                popupContainer.removeFromSuperview()
                popupContainer.transform = .identity
            }
        } else {
            popupContainer.removeFromSuperview()
            popupContainer.transform = .identity
        }
        
        delegate?.suggestionPopupDidDismiss()
    }
    
    // MARK: - Private Methods
    
    private func setupPopupUI() {
        // Create popup container with iOS message bubble styling
        popupContainer = UIView()
        popupContainer?.backgroundColor = UIColor.systemBlue
        popupContainer?.layer.cornerRadius = 18
        popupContainer?.layer.shadowColor = UIColor.black.cgColor
        popupContainer?.layer.shadowOpacity = 0.2
        popupContainer?.layer.shadowOffset = CGSize(width: 0, height: 2)
        popupContainer?.layer.shadowRadius = 8
        popupContainer?.alpha = 0
        popupContainer?.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        // Create suggestion label
        suggestionLabel = UILabel()
        suggestionLabel?.textColor = .white
        suggestionLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        suggestionLabel?.textAlignment = .center
        suggestionLabel?.numberOfLines = 0
        suggestionLabel?.translatesAutoresizingMaskIntoConstraints = false
        
        // Add label to container
        if let popupContainer = popupContainer, let suggestionLabel = suggestionLabel {
            popupContainer.addSubview(suggestionLabel)
            
            // Set up label constraints
            NSLayoutConstraint.activate([
                suggestionLabel.topAnchor.constraint(equalTo: popupContainer.topAnchor, constant: 12),
                suggestionLabel.leadingAnchor.constraint(equalTo: popupContainer.leadingAnchor, constant: 16),
                suggestionLabel.trailingAnchor.constraint(equalTo: popupContainer.trailingAnchor, constant: -16),
                suggestionLabel.bottomAnchor.constraint(equalTo: popupContainer.bottomAnchor, constant: -12)
            ])
        }
        
        // Add tap gesture to apply suggestion
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(popupTapped))
        popupContainer?.addGestureRecognizer(tapGesture)
        popupContainer?.isUserInteractionEnabled = true
    }
    
    private func setupPopupConstraints(relativeTo button: UIButton) {
        guard let popupContainer = popupContainer,
              let containerView = containerView else {
            return
        }
        
        popupContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Convert button frame to container view coordinates
        let buttonFrame = containerView.convert(button.bounds, from: button)
        
        NSLayoutConstraint.activate([
            // Center horizontally above the button
            popupContainer.centerXAnchor.constraint(equalTo: containerView.leadingAnchor, constant: buttonFrame.midX),
            
            // Position above the button with some spacing
            popupContainer.bottomAnchor.constraint(equalTo: containerView.topAnchor, constant: buttonFrame.minY - 10),
            
            // Width constraints
            popupContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            popupContainer.widthAnchor.constraint(lessThanOrEqualToConstant: 280),
            
            // Height constraint
            popupContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        
        // Force layout
        containerView.layoutIfNeeded()
    }
    
    private func showPopupWithAnimation() {
        guard let popupContainer = popupContainer else { return }
        
        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.3, options: .curveEaseOut, animations: {
            popupContainer.alpha = 1
            popupContainer.transform = .identity
        }, completion: nil)
    }
    
    private func startAutoDismissTimer() {
        dismissTimer = Timer.scheduledTimer(withTimeInterval: autoDismissDelay, repeats: false) { [weak self] _ in
            self?.hidePopup(animated: true)
        }
    }
    
    @objc private func popupTapped() {
        guard let suggestion = suggestionLabel?.text else {
            return
        }
        
        // Hide popup immediately
        hidePopup(animated: true)
        
        // Notify delegate
        delegate?.suggestionPopupDidSelectSuggestion(suggestion)
    }
}

// MARK: - iOS Message Bubble Styling Extension

extension SuggestionPopupManager {
    
    func updatePopupStyle(for traitCollection: UITraitCollection) {
        guard let popupContainer = popupContainer else { return }
        
        // Update colors based on appearance
        if traitCollection.userInterfaceStyle == .dark {
            popupContainer.backgroundColor = UIColor.systemBlue
            suggestionLabel?.textColor = .white
        } else {
            popupContainer.backgroundColor = UIColor.systemBlue
            suggestionLabel?.textColor = .white
        }
    }
    
    func setPopupBackgroundColor(_ color: UIColor) {
        popupContainer?.backgroundColor = color
    }
    
    func setPopupTextColor(_ color: UIColor) {
        suggestionLabel?.textColor = color
    }
}
