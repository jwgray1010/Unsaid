//
//  KeyboardViewController.swift
//  UnsaidKeyboard
//
//  Created by John Gray on 7/15/25.
//

import UIKit

class KeyboardViewController: UIInputViewController {
    
    // Custom keyboard controller
    private var keyboardController: KeyboardController?
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Update keyboard controller constraints
        keyboardController?.updateViewConstraints()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(" KeyboardViewController viewDidLoad")
        print(" View bounds: \(view.bounds)")
        print(" View frame: \(view.frame)")
        print(" Has full access: \(hasFullAccess)")
        
        // Configure keyboard to prevent system takeover
        configureKeyboardBehavior()
        
        // Create and setup custom keyboard controller
        setupKeyboardController()
        
        print("📱 Final view bounds: \(view.bounds)")
        print("📱 Final view frame: \(view.frame)")
        
        // Force layout to ensure everything is properly set up
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        print(" KeyboardViewController viewDidLoad completed")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("📱 KeyboardViewController viewWillAppear")
        
        // Set up preferred content size for the keyboard extension
        // Do this in viewWillAppear when view bounds are established
        let keyboardWidth = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        
        // Use the keyboard controller's intrinsic content size if available
        let keyboardHeight: CGFloat
        if let keyboardController = keyboardController {
            keyboardHeight = keyboardController.intrinsicContentSize.height
        } else {
            keyboardHeight = 320  // Fallback height
        }
        
        let keyboardSize = CGSize(width: keyboardWidth, height: keyboardHeight)
        preferredContentSize = keyboardSize
        
        print(" Preferred content size set to: \(keyboardSize)")
        print(" View bounds at viewWillAppear: \(view.bounds)")
        print(" View frame at viewWillAppear: \(view.frame)")
        
        keyboardController?.viewWillAppear(animated)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        keyboardController?.viewWillLayoutSubviews()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        print(" KeyboardViewController viewDidDisappear")
        keyboardController?.viewDidDisappear(animated)
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        super.textWillChange(textInput)
        
        keyboardController?.textWillChange(textInput)
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)
        
        keyboardController?.textDidChange(textInput)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        keyboardController?.traitCollectionDidChange(previousTraitCollection)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print(" KeyboardViewController viewDidAppear")
        print(" View bounds: \(view.bounds)")
        print(" View frame: \(view.frame)")
        print(" Has full access: \(hasFullAccess)")
        
        // Ensure the keyboard is properly visible
        if let keyboardController = keyboardController {
            print(" KeyboardController frame: \(keyboardController.frame)")
            print(" KeyboardController bounds: \(keyboardController.bounds)")
            print(" KeyboardController superview: \(keyboardController.superview != nil)")
            print(" KeyboardController subviews count: \(keyboardController.subviews.count)")
            
            // Ensure it's visible
            keyboardController.isHidden = false
            keyboardController.alpha = 1.0
            
            // Force layout one more time
            view.setNeedsLayout()
            view.layoutIfNeeded()
            keyboardController.setNeedsLayout()
            keyboardController.layoutIfNeeded()
        } else {
            print(" KeyboardController is nil in viewDidAppear")
        }
    }
    
    // MARK: - Private Methods
    
    private func setupKeyboardController() {
        print("🔧 Setting up KeyboardController...")
        
        // Create keyboard controller with proper initial frame (use view bounds like backup)
        let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        let initialFrame = CGRect(x: 0, y: 0, width: width, height: 320)
        keyboardController = KeyboardController(frame: initialFrame)
        
        guard let keyboardController = keyboardController else {
            print(" Failed to create KeyboardController")
            return
        }
        
        print(" KeyboardController created with frame: \(keyboardController.frame)")
        print(" KeyboardController backgroundColor: \(keyboardController.backgroundColor?.description ?? "nil")")
        print(" KeyboardController isUserInteractionEnabled: \(keyboardController.isUserInteractionEnabled)")
        
        // Configure the keyboard controller with this input view controller
        keyboardController.configure(with: self)
        
        // Set the keyboard controller as the main view for this keyboard extension
        self.view = keyboardController
        
        print("📱 KeyboardController configured and set as main view")
        print("📱 View subviews count: \(view.subviews.count)")
        
        // Force layout
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        print(" KeyboardController final frame: \(keyboardController.frame)")
        print(" KeyboardController final bounds: \(keyboardController.bounds)")
        
        // Call viewDidLoad equivalent
        keyboardController.viewDidLoad()
        
        print(" KeyboardController setup complete")
    }
    
    // MARK: - Configuration
    
    private func configureKeyboardBehavior() {
        // Prevent automatic keyboard switching
        if responds(to: #selector(getter: hasFullAccess)) {
            print(" Keyboard has full access: \(hasFullAccess)")
        }
        
        // Configure keyboard appearance
        if responds(to: #selector(getter: primaryLanguage)) {
            print(" Primary language: \(primaryLanguage ?? "unknown")")
        }
    }
    
    // MARK: - Prevent System Keyboard Takeover
    
    override func selectionWillChange(_ textInput: UITextInput?) {
        super.selectionWillChange(textInput)
        // Don't allow selection changes to trigger system keyboard
    }
    
    override func selectionDidChange(_ textInput: UITextInput?) {
        super.selectionDidChange(textInput)
        // Handle selection changes without triggering system keyboard
    }
}
