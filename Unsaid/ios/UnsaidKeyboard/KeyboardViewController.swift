//
//  KeyboardViewController.swift
//  UnsaidKeyboard
//
//  Created by John Gray on 8/5/25.
//

import UIKit
import os.log

class KeyboardViewController: UIInputViewController {
	// MARK: - Properties
	private var keyboardController: KeyboardController?
	private let logger = Logger(subsystem: "com.example.unsaid.UnsaidKeyboard", category: "KeyboardViewController")

	// MARK: - Constraint Management
	private var heightConstraint: NSLayoutConstraint?
	private var isKeyboardSetup = false

	// MARK: - Keyboard Height Calculation
	private var preferredKeyboardHeight: CGFloat {
		// IMPROVED: Less brittle height calculation using trait collection
		let isCompact = traitCollection.verticalSizeClass == .compact
		let baseHeight: CGFloat = isCompact ? 209 : 300
		// FUTURE-PROOF: Add safe area bottom inset for newer devices
		let bottomInset = view.safeAreaInsets.bottom
		let finalHeight = baseHeight + bottomInset
		logger.debug("📐 KeyboardViewController: Height calculation - base: \(baseHeight), inset: \(bottomInset), final: \(finalHeight)")
		return finalHeight
	}

	// MARK: - View Lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		logger.info("🎹 KeyboardViewController: viewDidLoad started")
		// CRITICAL: Only set up keyboard once to prevent crashes
		if !isKeyboardSetup {
			setupKeyboard()
			// FIXED: Only set flag after successful setup
		}
		logger.info("🎹 KeyboardViewController: viewDidLoad completed")
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		logger.debug("🎹 KeyboardViewController: viewWillAppear")
		// SAFE: Only prepare if keyboard is set up
		// KeyboardController doesn't need special preparation
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		logger.debug("🎹 KeyboardViewController: viewDidAppear")
		// SAFE: Update height only after keyboard is set up and visible
		if isKeyboardSetup {
			updateKeyboardHeight()
		}
	}

	override func updateViewConstraints() {
		super.updateViewConstraints()
		// SAFE: Only update height if keyboard is properly set up
		if isKeyboardSetup && heightConstraint == nil {
			updateKeyboardHeight()
		}
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		// SAFE: Only update appearance if keyboard is set up
		// KeyboardController handles its own layout in layoutSubviews()
	}

	// MARK: - Keyboard Setup
	private func setupKeyboard() {
		// CRASH PREVENTION: Guard against multiple setup calls
		guard keyboardController == nil else {
			logger.warning("⚠️ KeyboardViewController: setupKeyboard called multiple times - ignoring")
			return
		}
		logger.info("🔧 KeyboardViewController: Setting up custom keyboard")
		// Create the keyboard controller (no need for do-catch since it doesn't throw)
		keyboardController = KeyboardController()
		keyboardController?.configure(with: self)
		guard let keyboardController = keyboardController else {
			logger.error("❌ KeyboardViewController: Failed to create keyboard controller")
			return
		}
		// SAFE: Add with proper constraint setup
		setupKeyboardConstraints(keyboardController)
		// POLISH: Observe Dynamic Type changes for accessibility
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(contentSizeCategoryDidChange),
			name: UIContentSizeCategory.didChangeNotification,
			object: nil
		)
		// FIXED: Only set flag after successful setup
		isKeyboardSetup = true
		logger.info("✅ KeyboardViewController: Custom keyboard setup completed")
	}

	// MARK: - Constraint Setup
	private func setupKeyboardConstraints(_ keyboardController: KeyboardController) {
		// Add the keyboard controller as the input view
		view.addSubview(keyboardController)
		keyboardController.translatesAutoresizingMaskIntoConstraints = false
		// Set up constraints to fill the entire view (SAFE - no height constraint yet)
		NSLayoutConstraint.activate([
			keyboardController.topAnchor.constraint(equalTo: view.topAnchor),
			keyboardController.leadingAnchor.constraint(equalTo: view.leadingAnchor),
			keyboardController.trailingAnchor.constraint(equalTo: view.trailingAnchor),
			keyboardController.bottomAnchor.constraint(equalTo: view.bottomAnchor)
		])
		logger.debug("✅ KeyboardViewController: Keyboard constraints activated")
	}

	// MARK: - Height Management
	private func updateKeyboardHeight() {
		// CRASH PREVENTION: Guard against multiple height constraint creation
		guard heightConstraint == nil else {
			logger.debug("⚠️ KeyboardViewController: Height constraint already exists - skipping")
			return
		}
		let targetHeight = preferredKeyboardHeight
		// FIXED: Create new height constraint with proper priority
		heightConstraint = view.heightAnchor.constraint(equalToConstant: targetHeight)
		heightConstraint?.priority = UILayoutPriority(760) // Slightly higher to win over incidental low-priorities
		heightConstraint?.isActive = true
		logger.debug("📏 KeyboardViewController: Set keyboard height to \(targetHeight)pt (safe mode)")
	}

	// MARK: - Text Input Delegate Methods
	override func textWillChange(_ textInput: UITextInput?) {
		// SAFE: Check if keyboard is ready before delegating
		guard isKeyboardSetup else { return }
		super.textWillChange(textInput)
		// KeyboardController doesn't need these delegate methods
	}

	override func textDidChange(_ textInput: UITextInput?) {
		// SAFE: Check if keyboard is ready before delegating
		guard isKeyboardSetup else { return }
		super.textDidChange(textInput)
		// Forward text changes to KeyboardController
		keyboardController?.textDidChange()
	}

	// MARK: - Trait Collection Changes
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		// SAFE: Only update if keyboard is set up
		guard isKeyboardSetup else { return }
		// Update keyboard appearance for the new trait collection
		if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
			// KeyboardController handles its own appearance updates
		}
		// SAFE: Update height if orientation changed (but don't recreate constraint)
		if traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass ||
			traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
			// Only update the constraint constant, don't recreate the constraint
			let newHeight = preferredKeyboardHeight
			heightConstraint?.constant = newHeight
			// POLISH: Animate height changes for smooth orientation transitions
			UIView.animate(withDuration: 0.15) {
				self.view.layoutIfNeeded()
			}
			logger.debug("📏 KeyboardViewController: Updated height to \(newHeight)pt for orientation change")
		}
	}

	// MARK: - Memory Management
	deinit {
		// SAFE: Clean up observers
		NotificationCenter.default.removeObserver(self)
		// SAFE: Clean up height constraint
		if let constraint = heightConstraint {
			constraint.isActive = false
			heightConstraint = nil
		}
		// SAFE: Clean up keyboard controller
		keyboardController?.removeFromSuperview()
		keyboardController = nil
		logger.info("✅ KeyboardViewController: Deallocated safely")
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		logger.warning("⚠️ KeyboardViewController: Received memory warning")
		// SAFE: KeyboardController doesn't need special cleanup
	}

	// MARK: - Accessibility Support
	@objc private func contentSizeCategoryDidChange() {
		// POLISH: Update keyboard appearance when user changes text size
		logger.debug("📱 KeyboardViewController: Content size category changed")
		// KeyboardController handles its own appearance updates
	}

	// MARK: - Input Mode Switching
	override var needsInputModeSwitchKey: Bool {
		// RESPECT: System requirement for globe/dismiss key
		return true
	}
}