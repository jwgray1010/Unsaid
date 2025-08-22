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
		// ADAPTIVE: Scale height based on screen size and device type for better UX
		let screenHeight = UIScreen.main.bounds.height
		let isPad = traitCollection.userInterfaceIdiom == .pad
		
		// Base height roughly 38-42% of portrait phone height, smaller on iPad
		let baseHeight: CGFloat
		if isPad {
			baseHeight = max(290, screenHeight * 0.28)
		} else {
			baseHeight = max(280, screenHeight * 0.38)
		}
		
		// SAFE: Add safe area bottom inset (handles early lifecycle when inset may be 0)
		let bottomInset = view.safeAreaInsets.bottom
		let finalHeight = floor(baseHeight + bottomInset)
		
		logger.debug("📐 KeyboardViewController: Height calculation - screen: \(screenHeight), base: \(baseHeight), inset: \(bottomInset), final: \(finalHeight)")
		return finalHeight
	}

	// MARK: - View Lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()
		logger.info("🎹 KeyboardViewController: viewDidLoad started")
		
		// HANDSHAKE: Register keyboard presence with app
		registerKeyboardPresence()
		
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
		
		// HANDSHAKE: Update presence each time keyboard appears
		registerKeyboardPresence()
		
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
		
		// HANDSHAKE: Write status to App Group for host app detection
		writeKeyboardHandshake()
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

	// MARK: - App Group Handshake
	private func registerKeyboardPresence() {
		// Use the standard App Group identifier
		guard let sharedDefaults = UserDefaults(suiteName: "group.com.unsaid.shared") else {
			logger.error("❌ KeyboardViewController: Failed to access App Group")
			return
		}
		
		// Register that keyboard is active
		sharedDefaults.set(Date().timeIntervalSince1970, forKey: "keyboard_last_seen")
		
		// Test if we can write to the App Group (indicates Allow Full Access is enabled)
		let testKey = "keyboard_full_access_test"
		let testValue = UUID().uuidString
		sharedDefaults.set(testValue, forKey: testKey)
		
		// Verify we can read it back
		let canAccessAppGroup = sharedDefaults.string(forKey: testKey) == testValue
		sharedDefaults.set(canAccessAppGroup, forKey: "keyboard_full_access_ok")
		
		// Clean up test data
		sharedDefaults.removeObject(forKey: testKey)
		
		logger.debug("🤝 KeyboardViewController: Registered presence - Full Access: \(canAccessAppGroup)")
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
		// OPTIMAL: Create height constraint with standard high priority to avoid conflicts
		heightConstraint = view.heightAnchor.constraint(equalToConstant: targetHeight)
		heightConstraint?.priority = UILayoutPriority(750) // Standard "high" priority
		heightConstraint?.isActive = true
		logger.debug("📏 KeyboardViewController: Set keyboard height to \(targetHeight)pt")
	}
	
	// MARK: - Safe Area Handling
	override func viewSafeAreaInsetsDidChange() {
		super.viewSafeAreaInsetsDidChange()
		guard isKeyboardSetup else { return }
		
		// ADAPTIVE: Update height when safe area changes (fixes early lifecycle timing)
		let newHeight = preferredKeyboardHeight
		if let constraint = heightConstraint, constraint.constant != newHeight {
			constraint.constant = newHeight
			// SMOOTH: Animate height changes for polished UX
			UIView.animate(withDuration: 0.12) {
				self.view.layoutIfNeeded()
			}
			logger.debug("📏 KeyboardViewController: Updated height to \(newHeight)pt (safe-area change)")
		}
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
		// DYNAMIC: Update keyboard appearance when user changes text size
		logger.debug("📱 KeyboardViewController: Dynamic Type changed; refreshing keyboard layout")
		// Forward to KeyboardController for typography updates
		keyboardController?.setNeedsLayout()
		keyboardController?.layoutIfNeeded()
	}

	// MARK: - Input Mode Switching
	override var needsInputModeSwitchKey: Bool {
		// SAFE: Keep system globe key for App Review compliance
		// Note: KeyboardController also has its own globe button for redundancy
		return true
	}
	
	// MARK: - Keyboard Handshake
	private func writeKeyboardHandshake() {
		// HANDSHAKE: Write status to shared App Group for reliable host app detection
		guard let appGroup = UserDefaults(suiteName: "group.com.unsaid.shared") else {
			logger.error("❌ KeyboardViewController: Failed to access App Group for handshake")
			return
		}
		
		// Write last seen timestamp
		appGroup.set(Date().timeIntervalSince1970, forKey: "kb_last_seen")
		
		// Test full access by trying to write/read from App Group
		let testKey = "kb_full_access_test"
		let testValue = "test_\(Date().timeIntervalSince1970)"
		appGroup.set(testValue, forKey: testKey)
		let canReadBack = appGroup.string(forKey: testKey) == testValue
		appGroup.set(canReadBack, forKey: "kb_full_access_ok")
		
		// Clean up test data
		appGroup.removeObject(forKey: testKey)
		
		logger.debug("✅ KeyboardViewController: Handshake written - full access: \(canReadBack)")
	}
}