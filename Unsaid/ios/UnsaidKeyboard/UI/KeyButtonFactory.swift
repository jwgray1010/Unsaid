//
//  KeyButtonFactory.swift
//  UnsaidKeyboard
//
//  Factory for creating and styling keyboard buttons
//

import Foundation
import UIKit

final class KeyButtonFactory {
    
    // Layout constants
    static let touchTargetHeight: CGFloat = 50
    static let minKeyWidth: CGFloat = 44
    static let keyCornerRadius: CGFloat = 6
    
    // MARK: - Button Creation
    
    static func makeKeyButton(title: String) -> UIButton {
        let button = ExtendedTouchButton(type: .system)
        button.setTitle(title, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: touchTargetHeight).isActive = true
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: minKeyWidth).isActive = true
        
        applyModernKeyStyle(to: button)
        return button
    }
    
    static func makeControlButton(title: String, background: UIColor = .systemGray4, text: UIColor = .label) -> UIButton {
        let button = ExtendedTouchButton(type: .system)
        button.setTitle(title, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: touchTargetHeight).isActive = true
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: minKeyWidth).isActive = true
        
        applySpecialKeyStyle(to: button, background: background, text: text)
        return button
    }
    
    static func makeSpaceButton() -> UIButton {
        let button = ExtendedTouchButton(type: .system)
        button.setTitle("space", for: .normal)
        button.accessibilityValue = "SPACE"
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: touchTargetHeight).isActive = true
        
        applySpecialKeyStyle(to: button, background: .systemGray4, text: .label)
        return button
    }
    
    static func makeDeleteButton() -> UIButton {
        let button = ExtendedTouchButton(type: .system)
        button.setTitle("⌫", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: touchTargetHeight).isActive = true
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: minKeyWidth).isActive = true
        
        applySpecialKeyStyle(to: button, background: .systemGray4, text: .label)
        return button
    }
    
    static func makeShiftButton() -> UIButton {
        let button = ExtendedTouchButton(type: .system)
        button.setTitle("⇧", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: touchTargetHeight).isActive = true
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: minKeyWidth).isActive = true
        
        applySpecialKeyStyle(to: button, background: .systemGray4, text: .label)
        return button
    }
    
    static func makeReturnButton() -> UIButton {
        let button = ExtendedTouchButton(type: .system)
        button.setTitle("return", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: touchTargetHeight).isActive = true
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: minKeyWidth).isActive = true
        
        applySpecialKeyStyle(to: button, background: .systemBlue, text: .white)
        return button
    }
    
    // MARK: - Styling
    
    private static func applyModernKeyStyle(to button: UIButton) {
        button.backgroundColor = .systemBackground
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 22, weight: .medium)
        button.layer.cornerRadius = keyCornerRadius
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.keyBorder.cgColor
        button.layer.shadowColor = UIColor.keyShadow.cgColor
        button.layer.shadowOpacity = 0.12
        button.layer.shadowRadius = 1
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
    }
    
    private static func applySpecialKeyStyle(to button: UIButton, background: UIColor, text: UIColor) {
        button.backgroundColor = background
        button.setTitleColor(text, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = keyCornerRadius
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.keyBorder.cgColor
        button.layer.shadowColor = UIColor.keyShadow.cgColor
        button.layer.shadowOpacity = 0.12
        button.layer.shadowRadius = 1
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
    }
    
    // MARK: - Visual Effects
    
    static func animateButtonPress(_ button: UIButton) {
        UIView.animate(withDuration: 0.08, animations: {
            button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            button.alpha = 0.7
        }) { _ in
            UIView.animate(withDuration: 0.08) {
                button.transform = .identity
                button.alpha = 1.0
            }
        }
    }
    
    static func animateSpecialButtonPress(_ button: UIButton) {
        UIView.animate(withDuration: 0.06, animations: {
            button.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }) { _ in
            UIView.animate(withDuration: 0.06) {
                button.transform = .identity
            }
        }
    }
    
    // MARK: - State Updates
    
    static func updateShiftButtonAppearance(_ button: UIButton, isShifted: Bool, isCapsLocked: Bool) {
        if isCapsLocked {
            button.backgroundColor = .systemBlue
            button.setTitleColor(.white, for: .normal)
        } else if isShifted {
            button.backgroundColor = .systemGray3
            button.setTitleColor(.label, for: .normal)
        } else {
            button.backgroundColor = .systemGray4
            button.setTitleColor(.label, for: .normal)
        }
    }
    
    static func updateReturnButtonAppearance(_ button: UIButton, for type: UIReturnKeyType) {
        let label: String
        switch type {
        case .go: label = "Go"
        case .google: label = "Google"
        case .join: label = "Join"
        case .next: label = "Next"
        case .route: label = "Route"
        case .search: label = "Search"
        case .send: label = "Send"
        case .yahoo: label = "Yahoo"
        case .done: label = "Done"
        case .continue: label = "Continue"
        default: label = "return"
        }
        button.setTitle(label, for: .normal)
    }
}

// MARK: - ExtendedTouchButton (bigger touch target)
final class ExtendedTouchButton: UIButton {
    private let mainTouchTargetSize: CGFloat = 46.0
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let expandedBounds = bounds.insetBy(dx: -8, dy: -4)
        return expandedBounds.contains(point)
    }
}

// MARK: - UIColor Extensions
extension UIColor {
    static var keyboardBackground: UIColor { .systemGray6 }
    static var keyboardRose: UIColor { .systemPink }
    static var keyBorder: UIColor { .systemGray3 }
    static var keyShadow: UIColor { .systemGray2 }
}
