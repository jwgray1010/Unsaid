//
//  KeyboardController.swift
//  UnsaidKeyboard
//
//  Apple-style keyboard with Unsaid tone analysis and advice suggestions.
//  Recreates the exact Apple keyboard layout with custom Quick Fix functionality.
//  Suggestions are advice-only (no text insertion) and toggled via tone indicator.
//
//  Created by John Gray on 7/11/25.
//

import UIKit
import Foundation
import NaturalLanguage

/// Custom button that extends touch area beyond visual bounds for better accessibility
class ExtendedTouchButton: UIButton {
    private let minTouchTargetSize: CGFloat = 44.0
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Calculate expanded bounds to ensure minimum 44pt touch target
        let expandedBounds = bounds.insetBy(
            dx: min(0, (bounds.width - minTouchTargetSize) / 2),
            dy: min(0, (bounds.height - minTouchTargetSize) / 2)
        )
        
        return expandedBounds.contains(point)
    }
}

/// Advanced keyboard controller with tone analysis and AI-powered suggestions
class KeyboardController: UIInputView {
    
    // MARK: - Enhanced Tone Analysis Properties
    
    // Smart debouncing intervals - optimized for instant word/space feedback
    private let instantAnalysisDelay: TimeInterval = 0.0 // Immediate for word boundaries
    private let quickAnalysisDelay: TimeInterval = 0.01 // 10ms for very fast analysis
    private let standardAnalysisDelay: TimeInterval = 0.1 // 100ms for delayed analysis
    private let suggestionDelay: TimeInterval = 0.2 // 200ms for background suggestions
    
    // Timer management
    private var toneAnalysisWorkItem: DispatchWorkItem?
    private var suggestionWorkItem: DispatchWorkItem?
    private var lastAnalyzedText: String = ""
    private var lastAnalysisTime: Date = Date()
    private var toneChangeAnimationDuration: TimeInterval = 0.1 // Much faster animation (100ms)
    
    // Smart triggering properties
    private var isTypingPaused: Bool = false
    private var lastTypingTime: Date = Date()
    private var typingPauseThreshold: TimeInterval = 0.1 // 100ms pause threshold for responsiveness
    private var lastWordBoundary: Date = Date()
    private var isWordComplete: Bool = false
    
    // Performance tracking
    private var analysisCount: Int = 0
    private var lastPerformanceLog: Date = Date()
    
    // Fallback handling
    private var consecutiveFailures: Int = 0
    private let maxConsecutiveFailures: Int = 3
    
    // MARK: - Enhanced Tone Indicator Properties
    
    private var toneIndicatorPulseLayer: CAShapeLayer?
    private var shouldShowToneChanges: Bool = true
    
    // MARK: - Typing Animation Properties
    
    private var isTypingAnimation: Bool = false
    private var typingAnimationWorkItem: DispatchWorkItem?
    
    // MARK: - Core Components
    
    /// Reference to the parent input view controller for accessing textDocumentProxy
    weak var parentInputViewController: UIInputViewController?
    
    /// Computed property to access textDocumentProxy from parent
    var textDocumentProxy: UITextDocumentProxy? {
        return parentInputViewController?.textDocumentProxy
    }
    
    /// Smart inference manager for memory-efficient AI processing
    private let smartInferenceManager = SmartInferenceManager()
    
    /// Memory monitor for tracking usage
    private let memoryMonitor = MemoryMonitor.shared
    
    /// Spell checking functionality
    private let spellCheckerManager = SpellCheckerManager()
    
    /// Analytics storage for data flow to main app
    private let analyticsStorage = KeyboardAnalyticsStorage.shared
    
    private let roseColor = UIColor.keyboardRose
    
    // MARK: - Keyboard Mode
    
    private var currentMode: KeyboardMode = .letters
    
    // MARK: - Keys Layout
    
    private let topRowKeys = ["Q","W","E","R","T","Y","U","I","O","P"]
    private let midRowKeys = ["A","S","D","F","G","H","J","K","L"]
    private let botRowKeys = ["Z","X","C","V","B","N","M"]
    
    // Number keys layout
    private let topRowNumbers = ["1","2","3","4","5","6","7","8","9","0"]
    private let midRowNumbers = ["-","/",":",";","(",")","$","&","@","\""]
    private let botRowNumbers = [".",",","?","!","'","\"","_"]
    
    // Symbol keys layout
    private let topRowSymbols = ["[","]","{","}","#","%","^","*","+","="]
    private let midRowSymbols = ["_","\\","|","~","<",">","€","£","¥","•"]
    private let botRowSymbols = [".",",","?","!","'","\"","_"]
    
    // Special buttons
    private lazy var shiftButton: UIButton = {
        let btn = makeKeyButton(title: "⇧")
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        // Color already set in makeKeyButton - gray background, rose text
        return btn
    }()
    
    private lazy var deleteButton: UIButton = {
        let btn = makeKeyButton(title: "⌫")
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        return btn
    }()
    
    private lazy var modeButton: UIButton = {
        let btn = makeControlButton(title: "123")
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium) // Smaller font for narrower button
        btn.addTarget(self, action: #selector(handleModeSwitch), for: .touchUpInside)
        return btn
    }()
    
    private lazy var spaceButton: UIButton = {
        let btn = makeControlButton(title: "space")
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        btn.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
        return btn
    }()
    
    private lazy var quickFixButton: UIButton = {
        let btn = makeControlButton(title: "Secure")
        btn.backgroundColor = roseColor
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .bold) // Slightly smaller for 40pt width
        return btn
    }()
    
    private lazy var returnButton: UIButton = {
        let btn = makeControlButton(title: "return")
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14) // Appropriate for 40pt width
        // Color already set in makeControlButton - gray background, rose text
        return btn
    }()
    
    private lazy var symbolsButton: UIButton = {
        let btn = makeControlButton(title: "#+=")
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        // Color already set in makeControlButton - gray background, rose text
        return btn
    }()
    
    // Main keyboard stack view for dynamic updates
    private var keyboardStackView: UIStackView!
    
    // MARK: - UI Components (Suggestion Bar)
    
    private var suggestionBar: UIView!
    private var suggestionButtons: [UIButton] = []
    private var toneIndicator: UIView!
    
    // MARK: - State Management
    
    private var currentText: String = ""
    private var suggestions: [String] = []
    private var currentToneStatus: ToneStatus = .clear
    private var isSetupComplete = false
    private var isShifted = false
    private var isCapsLocked = false
    private var isExpanded = false
    private var isSuggestionBarVisible = false // Start with suggestion buttons hidden
    private var expandedSuggestionButton: UIButton? // Track expanded button
    
    // MARK: - Layout Constants
    
    private let keyboardHeight: CGFloat = 280  // Increased from 260 to give more room
    private let suggestionBarHeight: CGFloat = 60  // Increased height for better visual balance
    
    // Keyboard styling constants - Following Apple's iOS design guidelines
    private let keyBackground = UIColor.keyBackground
    private let keyFont = UIFont.systemFont(ofSize: 18)
    private let keyCornerRadius: CGFloat = 8
    private let horizontalSpacing: CGFloat = 6 // Apple standard spacing between keys
    private let verticalSpacing: CGFloat = 8 // Apple standard vertical spacing between rows
    private let rowInsets: CGFloat = 0
    private let sideMargins: CGFloat = 6 // Apple standard side margins
    private let keyCapHeight: CGFloat = 40 // Visible keycap height
    private let touchTargetHeight: CGFloat = 44 // Apple HIG minimum touch target height (44×44pt)
    private let minKeyWidth: CGFloat = 44 // Apple HIG minimum touch target width
    
    // Height constraint for managing keyboard size
    private var heightConstraint: NSLayoutConstraint?
    
    // MARK: - Settings and Configuration
     private let userDefaults = UserDefaults.standard
    private var enableSuggestions: Bool = true
    private var enableToneAnalysis: Bool = true
    private var enableInsights: Bool = true
    private var suggestionsEnabled: Bool = true
    private var feedbackEnabled: Bool = true
    
    // MARK: - Secure Transformations
    
    private let secureTransformations: [SecureTransformation] = [
        SecureTransformation(pattern: "\\bi'm\\s+so\\s+mad\\b", replacement: "I'm feeling frustrated"),
        SecureTransformation(pattern: "\\byou\\s+always\\b", replacement: "I notice that you often"),
        SecureTransformation(pattern: "\\byou\\s+never\\b", replacement: "I'd appreciate it if you could"),
        SecureTransformation(pattern: "\\bwhatever\\b", replacement: "I understand")
    ]
    
    // MARK: - Data Collection and Analytics
    
    private var keyboardInteractions: [KeyboardInteraction] = []
    private let maxStoredInteractions = 1000
    
    // MARK: - Initialization
    
    override init(frame: CGRect, inputViewStyle: UIInputView.Style) {
        super.init(frame: frame, inputViewStyle: inputViewStyle)
        setupKeyboardView()
    }
    
    convenience init(frame: CGRect) {
        self.init(frame: frame, inputViewStyle: .keyboard)
    }
    
    func configure(with inputViewController: UIInputViewController) {
        self.parentInputViewController = inputViewController
        
        // Note: When used as inputView, the keyboard extension framework manages the view hierarchy
        // No need to add as subview or set constraints - this is handled by setting as inputView
        
        print(" KeyboardController configured with parent view controller (inputView mode)")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupKeyboardView()
    }
    
    private func setupKeyboardView() {
        print("🔧 KeyboardController: Setting up keyboard view...")
        
        // Set up keyboard properties
        backgroundColor = UIColor.keyboardBackground // iPhone style light gray background
        isUserInteractionEnabled = true
        // Don't disable auto-resizing mask - let the parent handle constraints
        // translatesAutoresizingMaskIntoConstraints = false
        
        print(" KeyboardController: Background color set to black")
        print(" KeyboardController: User interaction enabled")
        
        setupKeyboard()
        loadSettings()
        syncPersonalityData()
        updateKeyboardSessionStatus(isActive: true)
        
        // Start analytics session
        analyticsStorage.startSession()
        
        print(" KeyboardController initialized successfully")
        print(" KeyboardController frame: \(frame)")
        print(" KeyboardController bounds: \(bounds)")
        print(" KeyboardController subviews count: \(subviews.count)")
    }
    
    // MARK: - Lifecycle
    
    func viewDidLoad() {
        // Monitor memory usage at startup
        memoryMonitor.logMemoryUsage(context: "Keyboard ViewDidLoad")
        
        // Set preferred content size for keyboard extension
        // This will be called from the parent view controller
        
        // Ensure proper keyboard height
        setNeedsLayout()
        layoutIfNeeded()
        
        print("📱 KeyboardController viewDidLoad completed")
    }
    
    func viewWillAppear(_ animated: Bool) {
        memoryMonitor.logMemoryUsage(context: "ViewWillAppear")
        
        // Ensure proper keyboard height
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func updateViewConstraints() {
        // Height is managed by parent UIInputViewController via preferredContentSize
        // No need to update height constraint here
    }
    
    func viewWillLayoutSubviews() {
        // Layout suggestion buttons if needed
        if suggestionButtons.count > 0 {
            layoutSuggestionButtons()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // Handle trait collection changes (dark mode, size class changes, etc.)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearanceForTraitCollection()
        }
        
        if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass ||
           traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass {
            setNeedsLayout()
        }
    }
    
    private func updateAppearanceForTraitCollection() {
        // Update keyboard appearance based on current trait collection
        backgroundColor = UIColor.keyboardBackground // iPhone style light gray background
        suggestionBar?.backgroundColor = UIColor.keyboardBackground
    }
    
    func viewDidDisappear(_ animated: Bool) {
        memoryMonitor.logMemoryUsage(context: "ViewDidDisappear")
        
        updateKeyboardSessionStatus(isActive: false)
        
        // End analytics session
        analyticsStorage.endSession()
        
        // Clean up timers
        cleanupTimers()
    }
    
    private func cleanupTimers() {
        // Cancel work items
        toneAnalysisWorkItem?.cancel()
        toneAnalysisWorkItem = nil
        
        suggestionWorkItem?.cancel()
        suggestionWorkItem = nil
        
        // Cancel typing animation
        cancelTypingAnimation()
        
        // Reset performance tracking
        analysisCount = 0
        
        // Clear last analyzed text
        lastAnalyzedText = ""
        
        print("🧹 Cleaned up tone analysis timers, work items, and typing animation")
    }
    
    // MARK: - Keyboard Setup
    
    private func setupKeyboard() {
        guard !isSetupComplete else { 
            print("SetupKeyboard: Already completed")
            return 
        }
        
        print("🔧 SetupKeyboard: Starting keyboard setup...")
        memoryMonitor.logMemoryUsage(context: "SetupKeyboard")
        
        setupSuggestionBar()
        print(" SetupKeyboard: Suggestion bar setup complete")
        
        setupKeyboardLayout()
        print(" SetupKeyboard: Keyboard layout setup complete")
        
        isSetupComplete = true
        print(" SetupKeyboard: Setup completed successfully")
        print("📱 SetupKeyboard: Final subviews count: \(subviews.count)")
    }
    
    private func setupSuggestionBar() {
        do {
            suggestionBar = UIView()
            suggestionBar.backgroundColor = UIColor.keyboardBackground
            suggestionBar.translatesAutoresizingMaskIntoConstraints = false
            suggestionBar.isHidden = false // Always show suggestion bar (contains tone indicator)
            addSubview(suggestionBar)
            
            // Add tone indicator
            setupToneIndicator()
            
            // Add suggestion bar constraints
            NSLayoutConstraint.activate([
                suggestionBar.topAnchor.constraint(equalTo: topAnchor),
                suggestionBar.leadingAnchor.constraint(equalTo: leadingAnchor),
                suggestionBar.trailingAnchor.constraint(equalTo: trailingAnchor),
                suggestionBar.heightAnchor.constraint(equalToConstant: suggestionBarHeight)
            ])
            
            print(" SetupSuggestionBar: Suggestion bar setup completed successfully")
        } catch {
            print(" SetupSuggestionBar: Error setting up suggestion bar: \(error)")
            // Create fallback suggestion bar
            suggestionBar = UIView()
            suggestionBar.backgroundColor = UIColor.keyboardBackground
            suggestionBar.translatesAutoresizingMaskIntoConstraints = false
            addSubview(suggestionBar)
            
            NSLayoutConstraint.activate([
                suggestionBar.topAnchor.constraint(equalTo: topAnchor),
                suggestionBar.leadingAnchor.constraint(equalTo: leadingAnchor),
                suggestionBar.trailingAnchor.constraint(equalTo: trailingAnchor),
                suggestionBar.heightAnchor.constraint(equalToConstant: suggestionBarHeight)
            ])
        }
    }
    
    private func setupToneIndicator() {
        do {
            // Create logo/icon container
            let logoContainer = UIView()
            logoContainer.translatesAutoresizingMaskIntoConstraints = false
            suggestionBar.addSubview(logoContainer)
            
            // Add tone indicator background (changes colors based on tone)
            toneIndicator = UIView()
            toneIndicator.backgroundColor = UIColor.white
            toneIndicator.layer.cornerRadius = 22  // Updated for larger size (44x44)
            toneIndicator.layer.shadowColor = UIColor.black.cgColor
            toneIndicator.layer.shadowOpacity = 0.1
            toneIndicator.layer.shadowOffset = CGSize(width: 0, height: 1)
            toneIndicator.layer.shadowRadius = 2
            toneIndicator.translatesAutoresizingMaskIntoConstraints = false
            logoContainer.addSubview(toneIndicator)
            
            // Add logo image
            let logoImageView = UIImageView()
            logoImageView.image = UIImage(systemName: "message.circle.fill") // Use filled version
            logoImageView.tintColor = UIColor(red: 0.8, green: 0.6, blue: 0.6, alpha: 1.0) // Remove transparency
            logoImageView.contentMode = .scaleAspectFill // Fill the entire circle
            logoImageView.backgroundColor = UIColor.clear // Ensure background is transparent
            logoImageView.translatesAutoresizingMaskIntoConstraints = false
            toneIndicator.addSubview(logoImageView) // Add to tone indicator instead of logo container
            
            // Add tap gesture to logo container
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleSuggestionsDisplay))
            logoContainer.addGestureRecognizer(tapGesture)
            logoContainer.isUserInteractionEnabled = true
            
            NSLayoutConstraint.activate([
                logoContainer.leadingAnchor.constraint(equalTo: suggestionBar.leadingAnchor, constant: 10),
                logoContainer.centerYAnchor.constraint(equalTo: suggestionBar.centerYAnchor),
                logoContainer.widthAnchor.constraint(equalToConstant: 52),  // Increased size
                logoContainer.heightAnchor.constraint(equalToConstant: 44), // Increased size
                
                // Tone indicator constraints
                toneIndicator.centerXAnchor.constraint(equalTo: logoContainer.centerXAnchor),
                toneIndicator.centerYAnchor.constraint(equalTo: logoContainer.centerYAnchor),
                toneIndicator.widthAnchor.constraint(equalToConstant: 44),  // Increased size
                toneIndicator.heightAnchor.constraint(equalToConstant: 44), // Increased size
                
                // Logo image constraints - fill the entire tone indicator
                logoImageView.centerXAnchor.constraint(equalTo: toneIndicator.centerXAnchor),
                logoImageView.centerYAnchor.constraint(equalTo: toneIndicator.centerYAnchor),
                logoImageView.widthAnchor.constraint(equalToConstant: 44),  // Fill entire circle
                logoImageView.heightAnchor.constraint(equalToConstant: 44)  // Fill entire circle
            ])
            
            updateToneIndicator(with: ToneAnalysis(status: .neutral, confidence: 0.5, suggestions: []))
            
            print(" SetupToneIndicator: Tone indicator setup completed successfully")
        } catch {
            print(" SetupToneIndicator: Error setting up tone indicator: \(error)")
            // Create fallback tone indicator
            toneIndicator = UIView()
            toneIndicator.backgroundColor = UIColor.white
            toneIndicator.layer.cornerRadius = 22
            toneIndicator.translatesAutoresizingMaskIntoConstraints = false
            suggestionBar.addSubview(toneIndicator)
            
            NSLayoutConstraint.activate([
                toneIndicator.leadingAnchor.constraint(equalTo: suggestionBar.leadingAnchor, constant: 10),
                toneIndicator.centerYAnchor.constraint(equalTo: suggestionBar.centerYAnchor),
                toneIndicator.widthAnchor.constraint(equalToConstant: 44),
                toneIndicator.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
    }
    
    private func setupKeyboardLayout() {
        do {
            print("🔧 SetupKeyboardLayout: Creating keyboard stack view...")
            
            keyboardStackView = UIStackView()
            keyboardStackView.axis = .vertical
            keyboardStackView.spacing = verticalSpacing
            keyboardStackView.alignment = .fill
            keyboardStackView.distribution = .fill // Allow different row heights
            keyboardStackView.translatesAutoresizingMaskIntoConstraints = false
            
            print(" SetupKeyboardLayout: Stack view created")
            
            // Build initial keyboard layout
            updateKeyboardForCurrentMode()
            
            print(" SetupKeyboardLayout: Keyboard mode layout updated")
            
            addSubview(keyboardStackView)
            print(" SetupKeyboardLayout: Stack view added to parent")
            
            // Ensure suggestionBar exists before setting up constraints
            guard suggestionBar != nil else {
                print(" SetupKeyboardLayout: suggestionBar is nil, cannot set up constraints")
                return
            }
            
            NSLayoutConstraint.activate([
                keyboardStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
                keyboardStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
                keyboardStackView.topAnchor.constraint(equalTo: suggestionBar.bottomAnchor, constant: rowInsets),
                keyboardStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -rowInsets)
            ])
            
            print(" SetupKeyboardLayout: Constraints activated")
            
            // Note: Height is managed by the parent UIInputViewController via preferredContentSize
            // Do not set height constraint here as it conflicts with keyboard extension framework
                 print(" SetupKeyboardLayout: Height managed by parent UIInputViewController")
        
        // Set initial shift button appearance
        updateShiftButtonAppearance()
        
        // Ensure all dynamically created buttons are connected when layout updates
        updateButtonTargets()
            
            print(" SetupKeyboardLayout: Setup completed successfully")
        } catch {
            print(" SetupKeyboardLayout: Error setting up keyboard layout: \(error)")
            // Create fallback keyboard layout
            keyboardStackView = UIStackView()
            keyboardStackView.axis = .vertical
            keyboardStackView.spacing = verticalSpacing
            keyboardStackView.alignment = .fill
            keyboardStackView.distribution = .fill
            keyboardStackView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(keyboardStackView)
            
            NSLayoutConstraint.activate([
                keyboardStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: rowInsets),
                keyboardStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -rowInsets),
                keyboardStackView.topAnchor.constraint(equalTo: topAnchor, constant: 60), // Fallback: 60pt from top
                keyboardStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -rowInsets)
            ])
        }
    }
    
    private func updateButtonTargets() {
        // Ensure main keyboard buttons have proper targets
        [shiftButton, deleteButton, spaceButton, quickFixButton, returnButton].forEach {
            $0.removeTarget(nil, action: nil, for: .allEvents)
            $0.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
        }
        
        // Update mode button specific target
        modeButton.removeTarget(nil, action: nil, for: .allEvents)
        modeButton.addTarget(self, action: #selector(handleModeSwitch), for: .touchUpInside)
        
        // Update symbols button specific target
        symbolsButton.removeTarget(nil, action: nil, for: .allEvents)
        symbolsButton.addTarget(self, action: #selector(handleSymbolsSwitch), for: .touchUpInside)
        
        // Update quickFixButton specific target
        quickFixButton.removeTarget(nil, action: nil, for: .allEvents)
        quickFixButton.addTarget(self, action: #selector(handleQuickFix), for: .touchUpInside)
        
        // Update suggestion buttons if they exist
        suggestionButtons.forEach { button in
            button.removeTarget(nil, action: nil, for: .allEvents)
            button.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)
        }
        
        print(" Button targets updated for all keyboard buttons")
    }
    
    private func updateKeyboardForCurrentMode() {
        print("🔧 UpdateKeyboardForCurrentMode: Starting for mode \(currentMode)")
        
        // Clear existing arranged subviews
        keyboardStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let (topRow, midRow, botRow) = getKeysForCurrentMode()
        
        print("🔧 UpdateKeyboardForCurrentMode: Creating top row with \(topRow.count) keys")
        keyboardStackView.addArrangedSubview(rowStack(for: topRow, leftOffset: 0, rightOffset: 0))
        
        print("🔧 UpdateKeyboardForCurrentMode: Creating mid row with \(midRow.count) keys")
        // Add proper QWERTY indentation for middle row in letters mode
        let midRowOffset: CGFloat = currentMode == .letters ? 20.0 : 0.0
        keyboardStackView.addArrangedSubview(rowStack(for: midRow, leftOffset: midRowOffset, rightOffset: midRowOffset))
        
        // Bottom row with special keys
        let bottomRowKeys = currentMode == .letters ? botRowKeys : botRow
        let bottomKeyButtons = bottomRowKeys.map(makeKeyButton)
        bottomKeyButtons.forEach { $0.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside) }
        
        print("🔧 UpdateKeyboardForCurrentMode: Creating bottom row with \(bottomRowKeys.count) keys")
        
        // Create bottom row based on current mode
        let bottomRowArrangedSubviews: [UIView]
        switch currentMode {
        case .letters:
            bottomRowArrangedSubviews = [shiftButton] + bottomKeyButtons + [deleteButton]
        case .numbers:
            bottomRowArrangedSubviews = [symbolsButton] + bottomKeyButtons + [deleteButton]
        case .symbols:
            bottomRowArrangedSubviews = [symbolsButton] + bottomKeyButtons + [deleteButton]
        case .compact, .expanded, .suggestion, .analysis, .settings:
            bottomRowArrangedSubviews = [shiftButton] + bottomKeyButtons + [deleteButton]
        }
        
        let bottomLetters = UIStackView(arrangedSubviews: bottomRowArrangedSubviews)
        bottomLetters.axis = .horizontal
        bottomLetters.spacing = horizontalSpacing
        bottomLetters.alignment = .fill
        bottomLetters.distribution = .fillEqually // Use fillEqually for consistent sizing
        bottomLetters.layoutMargins = UIEdgeInsets(top: 0, left: sideMargins, bottom: 0, right: sideMargins)
        bottomLetters.isLayoutMarginsRelativeArrangement = true
        
        // Make shift/symbols and delete buttons wider (Apple style) but ensure minimum touch target
        if currentMode == .letters {
            shiftButton.widthAnchor.constraint(equalToConstant: max(52, minKeyWidth)).isActive = true // ~1.7x standard key width or minimum
        } else {
            symbolsButton.widthAnchor.constraint(equalToConstant: max(52, minKeyWidth)).isActive = true
        }
        deleteButton.widthAnchor.constraint(equalToConstant: max(52, minKeyWidth)).isActive = true
        
        // Bottom row letter keys should maintain standard width
        // They will automatically adjust spacing to fill available space
        
        keyboardStackView.addArrangedSubview(bottomLetters)
        
        // Control row - Order: [123/ABC] [Quick Fix] [space] [return]
        // Following Apple's iOS control row layout with proper width constraints
        let controlRow = UIStackView(arrangedSubviews: [
            modeButton, quickFixButton, spaceButton, returnButton
        ])
        controlRow.axis = .horizontal
        controlRow.spacing = 4 // Apple standard compact spacing
        controlRow.alignment = .fill
        controlRow.distribution = .fill
        controlRow.layoutMargins = UIEdgeInsets(top: 0, left: sideMargins, bottom: 0, right: sideMargins)
        controlRow.isLayoutMarginsRelativeArrangement = true
        
        // Ensure control row has proper height to meet Apple HIG
        controlRow.heightAnchor.constraint(equalToConstant: touchTargetHeight).isActive = true
        
        // Set button widths following iOS standards with Apple HIG minimums:
        // Mode button (123/ABC): 50pt for better touch target (exceeds 44pt minimum)
        modeButton.widthAnchor.constraint(equalToConstant: max(50, minKeyWidth)).isActive = true
        
        // Quick Fix button: 60pt for "Secure" text (exceeds 44pt minimum)
        quickFixButton.widthAnchor.constraint(equalToConstant: max(60, minKeyWidth)).isActive = true
        
        // Return button: 50pt for "return" text (exceeds 44pt minimum)
        returnButton.widthAnchor.constraint(equalToConstant: max(50, minKeyWidth)).isActive = true
        
        // Space button: Takes remaining width automatically
        // This ensures proper proportions similar to iOS keyboard
        spaceButton.setContentHuggingPriority(UILayoutPriority(249), for: .horizontal)
        spaceButton.setContentCompressionResistancePriority(UILayoutPriority(749), for: .horizontal)
        
        keyboardStackView.addArrangedSubview(controlRow)
        
        print(" UpdateKeyboardForCurrentMode: Control row added")
        print(" UpdateKeyboardForCurrentMode: Keyboard layout complete")
        print(" UpdateKeyboardForCurrentMode: Stack view now has \(keyboardStackView.arrangedSubviews.count) rows")
        
        // Update mode button title
        updateModeButtonTitle()
    }
    
    private func getKeysForCurrentMode() -> ([String], [String], [String]) {
        switch currentMode {
        case .letters:
            return (topRowKeys, midRowKeys, botRowKeys)
        case .numbers:
            return (topRowNumbers, midRowNumbers, botRowNumbers)
        case .symbols:
            return (topRowSymbols, midRowSymbols, botRowSymbols)
        case .compact, .expanded, .suggestion, .analysis, .settings:
            return (topRowKeys, midRowKeys, botRowKeys)
        }
    }
    
    private func updateModeButtonTitle() {
        switch currentMode {
        case .letters:
            modeButton.setTitle("123", for: .normal)
        case .numbers:
            modeButton.setTitle("ABC", for: .normal)
        case .symbols:
            modeButton.setTitle("ABC", for: .normal)
        default:
            modeButton.setTitle("123", for: .normal)
        }
        
        // Update symbols button title based on mode
        switch currentMode {
        case .letters:
            symbolsButton.setTitle("#+=", for: .normal)
        case .numbers:
            symbolsButton.setTitle("#+=", for: .normal)
        case .symbols:
            symbolsButton.setTitle("123", for: .normal)
        default:
            symbolsButton.setTitle("#+=", for: .normal)
        }
    }
    
    private func rowStack(for titles: [String], leftOffset: CGFloat, rightOffset: CGFloat = 0) -> UIStackView {
        let buttons = titles.map(makeKeyButton)
        buttons.forEach { $0.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside) }
        
        let stack = UIStackView(arrangedSubviews: buttons)
        stack.axis = .horizontal
        stack.spacing = horizontalSpacing
        stack.alignment = .fill
        stack.distribution = .fillEqually // Use fillEqually for consistent key widths
        stack.layoutMargins = UIEdgeInsets(top: 0, left: leftOffset + sideMargins, bottom: 0, right: rightOffset + sideMargins)
        stack.isLayoutMarginsRelativeArrangement = true
        
        return stack
    }
    
    private func makeKeyButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = keyFont
        btn.backgroundColor = UIColor.keyBackground // iPhone style white keys
        
        // iPhone style black text
        btn.setTitleColor(UIColor.keyText, for: .normal)
        btn.layer.cornerRadius = keyCornerRadius
        btn.translatesAutoresizingMaskIntoConstraints = false
        
        // Apple iOS standard: 44pt minimum touch target height and width
        btn.heightAnchor.constraint(equalToConstant: touchTargetHeight).isActive = true
        btn.widthAnchor.constraint(greaterThanOrEqualToConstant: minKeyWidth).isActive = true
        
        // Use fillEqually distribution in stack view to ensure consistent sizing
        // while maintaining minimum touch targets
        
        // Ensure user interaction is enabled
        btn.isUserInteractionEnabled = true
        
        return btn
    }
    
    private func makeControlButton(title: String) -> UIButton {
        let btn = ExtendedTouchButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = keyFont
        btn.backgroundColor = UIColor.specialKeyBackground // iPhone style darker gray for special keys
        btn.setTitleColor(UIColor.keyText, for: .normal) // iPhone style black text
        btn.layer.cornerRadius = keyCornerRadius
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: touchTargetHeight).isActive = true // Use full 44pt for control buttons
        
        // Ensure user interaction is enabled
        btn.isUserInteractionEnabled = true
        
        return btn
    }
    
    // MARK: - Mode Switching
    
    @objc private func handleModeSwitch() {
        memoryMonitor.logMemoryUsage(context: "HandleModeSwitch")
        
        switch currentMode {
        case .letters:
            currentMode = .numbers
        case .numbers:
            currentMode = .letters  // Fixed: ABC button should go back to letters, not symbols
        case .symbols:
            currentMode = .letters
        case .compact, .expanded, .suggestion, .analysis, .settings:
            currentMode = .letters
        }
        updateKeyboardForCurrentMode()
    }
    
    @objc private func handleSymbolsSwitch() {
        memoryMonitor.logMemoryUsage(context: "HandleSymbolsSwitch")
        
        switch currentMode {
        case .letters:
            currentMode = .symbols
        case .numbers:
            currentMode = .symbols
        case .symbols:
            currentMode = .numbers
        case .compact, .expanded, .suggestion, .analysis, .settings:
            currentMode = .symbols
        }
        updateKeyboardForCurrentMode()
    }
    
    // MARK: - Key Actions
    
    @objc private func keyTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { 
            print("❌ KeyTapped: No title found for button")
            return 
        }
        
        memoryMonitor.logMemoryUsage(context: "KeyTapped: \(title)")
        
        // Cancel typing animation if user starts typing
        if isTypingAnimation {
            cancelTypingAnimation()
        }
        
        print("🎯 KeyTapped: '\(title)' button pressed")
        print("🎯 TextDocumentProxy available: \(textDocumentProxy != nil)")
        print("🎯 Current text before action: '\(currentText)'")
        
        switch title {
        case "⌫":
            textDocumentProxy?.deleteBackward()
            if !currentText.isEmpty {
                currentText.removeLast()
            }
        case "space":
            print("🎯 Space button pressed")
            
            // Check if we have a valid text document proxy
            guard let proxy = textDocumentProxy else {
                print("❌ No text document proxy available")
                return
            }
            
            print("🎯 Text proxy available, current context: '\(proxy.documentContextBeforeInput ?? "nil")'")
            
            // Apply spell checking to the last word before inserting space
            SpellCheckerManager.autocorrectLastWord(using: proxy)
            
            // Simple space insertion
            proxy.insertText(" ")
            
            // Update current text to reflect the space
            if let updatedContext = proxy.documentContextBeforeInput {
                currentText = updatedContext
            }
            
            print("🎯 Space inserted with spell check")
            
            // Mark word as complete for instant tone analysis
            isWordComplete = true
            lastWordBoundary = Date()
            
            // Reset tone indicator to neutral when space is pressed
            resetToneIndicator()
            
            // Update current text from the text document proxy
            updateCurrentText()
            return
        case "123", "ABC":
            handleModeSwitch()
            return
        case "#+=":
            handleSymbolsSwitch()
            return
        case "Secure":
            handleQuickFix()
            return
        case "return":
            textDocumentProxy?.insertText("\n")
            currentText += "\n"
            
            // Reset tone indicator when return is pressed
            resetToneIndicator()
            return
        case "⇧":
            handleShiftPressed()
            return
        default:
            // Handle letter/number/symbol input
            let character = isShifted ? title.uppercased() : title.lowercased()
            textDocumentProxy?.insertText(character)
            currentText += character
            
            // Check if this is a punctuation that ends a word
            let wordEndingPunctuation = [".", ",", "!", "?", ";", ":"]
            if wordEndingPunctuation.contains(character) {
                isWordComplete = true
                lastWordBoundary = Date()
            } else {
                isWordComplete = false
            }
            
            // Reset shift after typing (only for letters)
            if isShifted && !isCapsLocked && currentMode == .letters {
                isShifted = false
                updateShiftButtonAppearance()
            }
        }
        
        // Analyze text after input
        lastTypingTime = Date()
        handleTextChange()
    }
    
    @objc private func handleQuickFix() {
        // Handle Secure button - ONLY method that replaces/transforms the entire message
        // 1. Clears existing text from the message field
        // 2. Uses AI to transform text to secure communicator style
        // 3. Types out the new text character by character so user can see the transformation
        // 4. User can then hit send when ready, or cancel by typing
        // Note: This is different from suggestion buttons which only add to existing text
        
        print(" Secure Communicator: Starting transformation...")
        memoryMonitor.logMemoryUsage(context: "HandleQuickFix")
        
        // Update current text from document proxy first
        updateCurrentText()
        
        // Debug: Print current state
        print(" Current text before transformation: '\(currentText)'")
        print(" Document before input: '\(textDocumentProxy?.documentContextBeforeInput ?? "nil")'")
        print(" Document after input: '\(textDocumentProxy?.documentContextAfterInput ?? "nil")'")
        
        guard !currentText.isEmpty else {
            print(" Secure Communicator: No text to transform")
            // Show a quick visual feedback
            animateQuickFixButton()
            return
        }
        
        print("🔧 Secure Communicator: Processing text: '\(currentText)'")
        
        // Animate button to show it's working
        animateQuickFixButton()
        
        // Generate secure communicator version of current text
        Task {
            do {
                let improvedText = try await generateQuickFixSuggestion(for: currentText)
                // Apply the improved text on main thread
                DispatchQueue.main.async {
                    let originalText = self.currentText
                    print(" Secure Communicator: About to replace '\(originalText)' with '\(improvedText)'")
                    self.replaceCurrentText(with: improvedText)
                    // Record quick fix usage
                    self.analyticsStorage.recordQuickFixUsage(originalText: originalText, fixedText: improvedText, fixType: "secure_communicator")
                    print(" Secure Communicator applied: '\(originalText)' → '\(improvedText)'")
                }
            } catch {
                print(" Secure Communicator failed: \(error)")
                // Fallback to showing suggestions
                DispatchQueue.main.async {
                    self.showSuggestionsManually()
                }
            }
        }
    }
    
    private func animateQuickFixButton() {
        UIView.animate(withDuration: 0.1, animations: {
            self.quickFixButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.quickFixButton.transform = CGAffineTransform.identity
            }
        }
    }
    
    private func showSuggestionsManually() {
        // Use memory-efficient inference manager for manual suggestion generation
        print("🧠 Manual suggestions: Using SmartInferenceManager for: '\(currentText)'")
        memoryMonitor.logMemoryUsage(context: "ShowSuggestionsManually")
        
        let emotionalState = PersonalityDataManager.shared.getCurrentEmotionalState() ?? "neutral"
        
        smartInferenceManager.requestSuggestion(text: currentText, emotionalState: emotionalState) { [weak self] suggestion in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let suggestion = suggestion, !suggestion.isEmpty {
                    // Convert single suggestion to array format
                    self.suggestions = [suggestion]
                    print("✅ Manual suggestions: SmartInferenceManager successful")
                    
                    // Reset consecutive failures on success
                    self.consecutiveFailures = 0
                } else {
                    print("⚠️ Manual suggestions: SmartInferenceManager returned no results, using basic patterns")
                    // Use basic communication patterns as fallback
                    let basicSuggestions = self.generateBasicCommunicationSuggestions()
                        self.suggestions = Array(basicSuggestions.prefix(3))
                    }
                    
                    // Show suggestions in the suggestion bar
                    self.updateSuggestionButtons()
                    
                    // Animate tone change to indicate suggestion display
                    self.animateToneChange()
                    
                    print(" Manual suggestions completed: \(self.suggestions)")
                }
            } catch {
                print(" Manual suggestions: Local AI failed: \(error)")
                self.consecutiveFailures += 1
                
                await MainActor.run {
                    // Fallback to basic communication patterns
                    let basicSuggestions = self.generateBasicCommunicationSuggestions()
                    self.suggestions = Array(basicSuggestions.prefix(3))
                    
                    // Show suggestions in the suggestion bar
                    self.updateSuggestionButtons()
                    
                    // Animate tone change to indicate suggestion display
                    self.animateToneChange()
                    
                    print(" Manual suggestions: Using fallback basic patterns due to Local AI failure")
                }
            }
        }
    }
    
    /// Applies a suggestion by adding it to the current text (not replacing)
    private func applySuggestion(_ suggestion: String) {
        // Add suggestion to current text instead of replacing
        textDocumentProxy?.insertText(" " + suggestion)
        currentText += " " + suggestion
        
        // Reset tone indicator after applying suggestion
        resetToneIndicator()
    }
    
    // MARK: - Text Input Delegate Methods
    
    func textWillChange(_ textInput: UITextInput?) {
        print(" KeyboardController textWillChange")
    }
    
    func textDidChange(_ textInput: UITextInput?) {
        print(" KeyboardController textDidChange")
        memoryMonitor.logMemoryUsage(context: "TextDidChange")
        updateCurrentText()
        handleTextChange()
    }
    
    // MARK: - Enhanced Tone Analysis
    
    private func handleTextChange() {
        print("🔄 handleTextChange called for text: '\(currentText)'")
        memoryMonitor.logMemoryUsage(context: "HandleTextChange")
        
        // Cancel previous analysis to prevent lag
        toneAnalysisWorkItem?.cancel()
        
        // Check if we should trigger instant analysis
        let shouldAnalyzeInstantly = isWordComplete || isAtWordBoundary() || hasSignificantChange()
        
        print("🔄 Should analyze instantly: \(shouldAnalyzeInstantly) (word complete: \(isWordComplete), at boundary: \(isAtWordBoundary()), significant change: \(hasSignificantChange()))")
        
        if shouldAnalyzeInstantly {
            // Instant analysis for word completion, spaces, and significant changes
            performInstantToneAnalysis()
            print("⚡ Instant tone analysis triggered")
        } else {
            // For mid-word typing, use a short delay to avoid excessive analysis
            scheduleDelayedAnalysis()
        }
        
        // Reset word complete flag
        isWordComplete = false
    }
    
    private func performInstantToneAnalysis() {
        print("🔍 performInstantToneAnalysis: Starting for text: '\(currentText)'")
        memoryMonitor.logMemoryUsage(context: "PerformInstantToneAnalysis")
        
        // Update tracking
        lastAnalyzedText = currentText
        lastAnalysisTime = Date()
        
        // Use memory-efficient tone analysis
        print("🔍 Starting tone analysis with SmartInferenceManager for: '\(currentText)'")
        
        let emotionalState = PersonalityDataManager.shared.getCurrentEmotionalState() ?? "neutral"
        
        smartInferenceManager.requestSuggestion(text: currentText, emotionalState: emotionalState) { [weak self] suggestion in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // For now, derive tone status from suggestion availability
                let status: ToneStatus = suggestion != nil ? .neutral : .warning
                let analysisResult = ToneAnalysis(status: status, confidence: 0.8, suggestions: [])
                
                self.updateToneIndicator(with: analysisResult)
                self.currentToneStatus = status
                
                print("✅ SmartInferenceManager tone analysis complete: '\(currentText)' → \(status)")
                
                // Reset consecutive failures on success
            consecutiveFailures = 0
            
        } catch {
            print("❌ Local AI tone analysis failed: \(error)")
            consecutiveFailures += 1
            
            // Fallback to neutral tone if Local AI fails
            let fallbackResult = ToneAnalysis(status: .neutral, confidence: 0.5, suggestions: [])
            updateToneIndicator(with: fallbackResult)
            currentToneStatus = .neutral
        }
        
        // Generate suggestions using Local AI if text is substantial
        if currentText.count >= 3 {
            generateLocalAISuggestions()
        }
        
        // Generate suggestions in background if text is substantial
        if currentText.count >= 5 {
            generateSuggestionsInBackground()
        }
        
        // Log analysis performance
        logAnalysisPerformance()
    }
    
    private func scheduleDelayedAnalysis() {
        // Short delay for mid-word changes to avoid excessive analysis
        let delay: TimeInterval = 0.1 // 100ms delay for smoother typing experience
        
        toneAnalysisWorkItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.performInstantToneAnalysis()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: toneAnalysisWorkItem!)
    }
    
    private func isAtWordBoundary() -> Bool {
        // Check if we just added a space, punctuation, or word-ending character
        guard !currentText.isEmpty else { return false }
        
        let lastChar = currentText.last!
        let wordBoundaryChars = CharacterSet(charactersIn: " .,!?;:-()[]{}\"'")
        
        return wordBoundaryChars.contains(lastChar.unicodeScalars.first!)
    }
    
    private func hasSignificantChange() -> Bool {
        // Check if the text has changed significantly since last analysis
        let textChanged = lastAnalyzedText != currentText
        let hasMinimumLength = currentText.count >= 3
        
        // Analyze if we've added/removed a complete word
        let wordCountDifference = abs(currentText.components(separatedBy: .whitespaces).count - 
                                    lastAnalyzedText.components(separatedBy: .whitespaces).count)
        
        return textChanged && hasMinimumLength && wordCountDifference > 0
    }
    
    private func generateSuggestionsInBackground() {
        // Use memory-efficient inference manager for background suggestions
        print("🧠 Generating background suggestions with SmartInferenceManager for: '\(currentText)'")
        memoryMonitor.logMemoryUsage(context: "GenerateSuggestionsInBackground")
        
        let emotionalState = PersonalityDataManager.shared.getCurrentEmotionalState() ?? "neutral"
        
        smartInferenceManager.requestSuggestion(text: currentText, emotionalState: emotionalState) { [weak self] suggestion in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let suggestion = suggestion, !suggestion.isEmpty {
                    self.suggestions = [suggestion]
                    // Only update suggestion buttons if suggestion bar is visible
                    if self.isSuggestionBarVisible {
                        self.updateSuggestionButtons()
                    }
                    print("✅ SmartInferenceManager background suggestions successful: \(suggestion)")
                    
                    // Reset consecutive failures on success
                    self.consecutiveFailures = 0
                } else {
                    print("⚠️ SmartInferenceManager returned no suggestions, using fallback")
                    // Use basic communication patterns as fallback
                    let fallbackSuggestions = self.generateBasicCommunicationSuggestions()
                    self.suggestions = Array(fallbackSuggestions.prefix(3))
                    if self.isSuggestionBarVisible {
                        self.updateSuggestionButtons()
                    }
                }
            }
        }
    }
    
    private func generateLocalAISuggestions() {
        // Use memory-efficient inference manager for suggestions
        print("🧠 Generating SmartInferenceManager suggestions for: '\(currentText)'")
        memoryMonitor.logMemoryUsage(context: "GenerateLocalAISuggestions")
        
        let emotionalState = PersonalityDataManager.shared.getCurrentEmotionalState() ?? "neutral"
        
        smartInferenceManager.requestSuggestion(text: currentText, emotionalState: emotionalState) { [weak self] suggestion in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let suggestion = suggestion, !suggestion.isEmpty {
                    self.suggestions = [suggestion]
                    self.updateSuggestionButtons()
                    print("✅ SmartInferenceManager suggestions generated successfully: \(suggestion)")
                    
                    // Reset consecutive failures on success
                    self.consecutiveFailures = 0
                } else {
                    print("⚠️ SmartInferenceManager returned no suggestions, using basic patterns")
                    // Fallback to basic communication patterns
                    let fallbackSuggestions = self.generateBasicCommunicationSuggestions()
                    self.suggestions = Array(fallbackSuggestions.prefix(3))
                    self.updateSuggestionButtons()
                }
            }
        }
    }
    
    private func generateBasicCommunicationSuggestions() -> [String] {
        // Provide basic communication-focused suggestions when no other suggestions are available
        // These are contextual phrases that help with communication, not spelling corrections
        
        let text = currentText.lowercased()
        
        // Handle negative emotions with secure communication alternatives
        if text.contains("hate") {
            return ["I'm frustrated", "I'm upset", "I disagree"]
        }
        
        if text.contains("angry") || text.contains("mad") {
            return ["I'm frustrated", "I need to discuss this", "I feel upset"]
        }
        
        if text.contains("stupid") || text.contains("dumb") {
            return ["I disagree with this", "This is challenging", "I see it differently"]
        }
        
        if text.contains("shut up") || text.contains("leave me alone") {
            return ["I need space", "I need a moment", "Let me think"]
        }
        
        // Common communication starters
        if text.isEmpty || text.hasSuffix(" ") {
            return ["I understand", "Thank you", "I appreciate"]
        }
        
        // Response patterns based on current text
        if text.contains("sorry") || text.contains("apologize") {
            return ["I understand", "Thank you for", "I appreciate"]
        }
        
        if text.contains("thank") {
            return ["you're welcome", "my pleasure", "anytime"]
        }
        
        if text.contains("how") && text.contains("you") {
            return ["I'm doing well", "Thank you for asking", "I'm good"]
        }
        
        if text.contains("help") {
            return ["I'd be happy to", "Of course", "Absolutely"]
        }
        
        if text.contains("what") && text.contains("think") {
            return ["I believe", "In my opinion", "I feel that"]
        }
        
        // General positive communication phrases
        return ["I understand", "That sounds good", "I appreciate"]
    }
    
    private func updateSuggestions(with result: ToneAnalysis) {
        // Update suggestions based on tone analysis result
        suggestions = result.suggestions
        
        // Only update suggestion buttons if suggestion bar is visible
        if isSuggestionBarVisible {
            updateSuggestionButtons()
        }
    }
    
    private func logAnalysisPerformance() {
        analysisCount += 1
        
        // Log performance metrics every 10 analyses
        if analysisCount % 10 == 0 {
            let elapsed = Date().timeIntervalSince(lastPerformanceLog)
            print(" Analysis performance: \(analysisCount) analyses, avg time: \(elapsed * 1000 / 10) ms")
            lastPerformanceLog = Date()
        }
    }
    
    private func updateToneIndicator(with result: ToneAnalysis) {
        print("🎨 updateToneIndicator called with status: \(result.status)")
        
        // Update tone indicator color based on analysis result
        let color = result.status.color
        print("🎨 Setting tone indicator color to: \(color)")
        
        // Check if tone indicator exists
        guard let toneIndicator = toneIndicator else {
            print("❌ Tone indicator is nil!")
            return
        }
        
        print("🎨 Tone indicator current background: \(toneIndicator.backgroundColor?.description ?? "nil")")
        
        // Animate tone change
        UIView.animate(withDuration: toneChangeAnimationDuration) {
            self.toneIndicator.backgroundColor = color
            print("🎨 Animation: Setting background to \(color)")
        }
        
        // Update pulse animation for clear tone
        if result.status == .clear {
            startTonePulseAnimation()
        } else {
            stopTonePulseAnimation()
        }
        
        print("🎨 Tone indicator update completed")
    }
    
    private func startTonePulseAnimation() {
        guard let toneIndicator = toneIndicator else { return }
        
        let pulseLayer = CAShapeLayer()
        pulseLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 40, height: 40)).cgPath
        pulseLayer.fillColor = UIColor.white.cgColor
        pulseLayer.opacity = 0.0
        
        toneIndicator.layer.addSublayer(pulseLayer)
        
        // Animate pulse effect
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.8
        animation.toValue = 0.0
        animation.duration = toneChangeAnimationDuration
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        animation.repeatCount = .infinity
        animation.autoreverses = true
        
        pulseLayer.add(animation, forKey: "pulse")
    }
    
    private func stopTonePulseAnimation() {
        // Remove all pulse layers from tone indicator
        toneIndicator?.layer.sublayers?.forEach { layer in
            if layer is CAShapeLayer {
                layer.removeFromSuperlayer()
            }
        }
    }
    
    private func updateSuggestionButtons() {
        print("📱 updateSuggestionButtons called with \(suggestions.count) suggestions: \(suggestions)")
        
        // Remove existing buttons
        suggestionButtons.forEach { $0.removeFromSuperview() }
        suggestionButtons.removeAll()
        
        // Only show the first (best) suggestion
        if let bestSuggestion = suggestions.first {
            let button = makeSuggestionButton(title: bestSuggestion)
            button.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)
            button.isHidden = !isSuggestionBarVisible // Hide if suggestion bar is not visible
            suggestionButtons.append(button)
            suggestionBar.addSubview(button)
            
            print("📱 Added best suggestion button: \(bestSuggestion)")
            
            // Layout the single suggestion button
            layoutSuggestionButtons()
        }
        
        print(" Finished updating suggestion buttons")
    }
    
    private func makeSuggestionButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        
        // Clean the title to ensure only plain text is shown (no metadata or explanations)
        let cleanTitle = cleanSuggestionText(title)
        btn.setTitle(cleanTitle, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        btn.titleLabel?.numberOfLines = 1  // Only one line initially
        btn.titleLabel?.lineBreakMode = .byTruncatingTail  // Add ... if text is too long
        btn.titleLabel?.textAlignment = .center
        
        // Store the full clean text for expansion
        btn.accessibilityHint = cleanTitle  // Store full text in accessibility hint
        
        // Single tap to expand/collapse
        btn.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)
        
        // Solid white background for better readability
        btn.backgroundColor = UIColor.white
        btn.setTitleColor(UIColor.black, for: .normal)
        
        // Add subtle border and shadow
        btn.layer.cornerRadius = 8
        btn.layer.borderWidth = 1
        btn.layer.borderColor = UIColor.lightGray.cgColor
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOffset = CGSize(width: 0, height: 2)
        btn.layer.shadowOpacity = 0.2
        btn.layer.shadowRadius = 4
        
        // Make the button meet Apple HIG minimum touch target (44×44pt)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: touchTargetHeight).isActive = true
        
        // Add padding for better text appearance
        btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        
        btn.isUserInteractionEnabled = true
        btn.isHidden = false
        
        // Bring to front so it can overlap other elements
        btn.layer.zPosition = 10
        
        print(" Created suggestion button: \(title)")
        return btn
    }
    
    private func layoutSuggestionButtons() {
        guard let suggestionButton = suggestionButtons.first else { return }
        
        // Make the suggestion button span the remaining width after the tone indicator
        let logoWidth: CGFloat = 62  // Updated for new larger logo container size (52 + 10 margin)
        let rightMargin: CGFloat = 10
        
        print("📱 Laying out single suggestion button")
        
        // Position the button centered vertically within the suggestion bar
        NSLayoutConstraint.activate([
            suggestionButton.leadingAnchor.constraint(equalTo: suggestionBar.leadingAnchor, constant: logoWidth),
            suggestionButton.trailingAnchor.constraint(equalTo: suggestionBar.trailingAnchor, constant: -rightMargin),
            suggestionButton.centerYAnchor.constraint(equalTo: suggestionBar.centerYAnchor), // Center in suggestion bar
        ])
    }
    
    /// Cleans suggestion text to ensure only plain text is displayed
    private func cleanSuggestionText(_ text: String) -> String {
        var cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common metadata patterns
        cleanText = cleanText.replacingOccurrences(of: "Suggestion: ", with: "")
        cleanText = cleanText.replacingOccurrences(of: "Alternative: ", with: "")
        cleanText = cleanText.replacingOccurrences(of: "Try: ", with: "")
        
        // Remove explanatory text in parentheses or brackets
        cleanText = cleanText.replacingOccurrences(of: #"\([^)]*\)"#, with: "", options: .regularExpression)
        cleanText = cleanText.replacingOccurrences(of: #"\[[^\]]*\]"#, with: "", options: .regularExpression)
        
        // Remove repair scripts or technical terms
        cleanText = cleanText.replacingOccurrences(of: "Script:", with: "")
        cleanText = cleanText.replacingOccurrences(of: "Command:", with: "")
        cleanText = cleanText.replacingOccurrences(of: "Fix:", with: "")
        
        // Remove multiple spaces and trim again
        cleanText = cleanText.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        cleanText = cleanText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleanText.isEmpty ? text : cleanText // Return original if cleaning resulted in empty string
    }
    
    // MARK: - Animations
    
    /// Animates tone change transitions
    private func animateToneChange() {
        // Simple animation for tone change
        UIView.animate(withDuration: self.toneChangeAnimationDuration) {
            self.toneIndicator.alpha = 0.8
        } completion: { _ in
            UIView.animate(withDuration: self.toneChangeAnimationDuration) {
                self.toneIndicator.alpha = 1.0
            }
        }
    }
    
    // MARK: - Suggestion Display Toggle
    
    @objc private func toggleSuggestionsDisplay() {
        memoryMonitor.logMemoryUsage(context: "ToggleSuggestionsDisplay")
        
        // Toggle the visibility of the suggestion advice buttons (advice-only, no text insertion)
        isSuggestionBarVisible.toggle()
        UIView.animate(withDuration: 0.3) {
            self.suggestionButtons.forEach { button in
                button.isHidden = !self.isSuggestionBarVisible
            }
        }
        if isSuggestionBarVisible {
            // Generate fresh tone-based advice suggestions when tone indicator is tapped
            generateToneBasedSuggestions()
            animateToneChange()
        }
    }

    private func generateToneBasedSuggestions() {
        // Always prioritize Local AI for tone-based advice generation (advice-only display)
        print("📱 Tone-based advice: Using Local AI first for: '\(currentText)'")
        memoryMonitor.logMemoryUsage(context: "GenerateToneBasedSuggestions")
        
        Task {
            let currentText = self.currentText
            
            do {
                // Generate advice suggestions using SmartInferenceManager as primary method
                let emotionalState = PersonalityDataManager.shared.getCurrentEmotionalState() ?? "neutral"
                
                smartInferenceManager.requestSuggestion(text: currentText, emotionalState: emotionalState) { [weak self] suggestion in
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        
                        if let suggestion = suggestion, !suggestion.isEmpty {
                            // Store SmartInferenceManager advice suggestions
                            self.suggestions = [suggestion]
                            self.updateSuggestionButtons()
                            print("✅ Tone-based suggestions: SmartInferenceManager successful: \(suggestion)")
                            
                            // Reset consecutive failures on success
                            self.consecutiveFailures = 0
                        } else {
                            print("⚠️ Tone-based suggestions: SmartInferenceManager returned no results, using basic patterns")
                            // Fallback to basic communication patterns
                            let fallbackSuggestions = self.generateBasicCommunicationSuggestions()
                            self.suggestions = Array(fallbackSuggestions.prefix(3))
                            self.updateSuggestionButtons()
                        }
                    }
                }
            } catch {
                print(" Tone-based suggestions: Local AI failed: \(error)")
                self.consecutiveFailures += 1
                
                await MainActor.run {
                    // Fallback to basic communication patterns
                    let fallbackSuggestions = self.generateBasicCommunicationSuggestions()
                    self.suggestions = Array(fallbackSuggestions.prefix(3))
                    self.updateSuggestionButtons()
                    print(" Tone-based suggestions: Using fallback basic patterns due to Local AI failure")
                }
            }
        }
    }

    // MARK: - Shift Handling
    @objc private func handleShiftPressed() {
        isShifted.toggle()
        updateShiftButtonAppearance()
    }

    private func updateShiftButtonAppearance() {
        shiftButton.setTitle("⇧", for: .normal)
        if isShifted {
            shiftButton.backgroundColor = roseColor // Keep rose when activated
            shiftButton.setTitleColor(.white, for: .normal)
        } else {
            shiftButton.backgroundColor = UIColor.specialKeyBackground // iPhone style darker gray
            shiftButton.setTitleColor(UIColor.keyText, for: .normal) // iPhone style black text
        }
    }

    // MARK: - Local AI Quick Fix
    func generateQuickFixSuggestion(for text: String) async throws -> String {
        // Use SmartInferenceManager as primary option for quick fix suggestions
        print("🔧 SmartInferenceManager Quick Fix: Processing text: '\(text)'")
        memoryMonitor.logMemoryUsage(context: "GenerateQuickFixSuggestion")
        
        let emotionalState = PersonalityDataManager.shared.getCurrentEmotionalState() ?? "neutral"
        
        return await withCheckedContinuation { continuation in
            smartInferenceManager.requestSuggestion(text: text, emotionalState: emotionalState) { [weak self] suggestion in
                if let suggestion = suggestion, !suggestion.isEmpty {
                    print("✅ SmartInferenceManager Quick Fix successful: '\(suggestion)'")
                    continuation.resume(returning: suggestion)
                } else {
                    print("⚠️ SmartInferenceManager Quick Fix failed, using fallback")
                    // Fallback to basic secure transformations if SmartInferenceManager fails
                    let fallbackResult = self?.applySecureTransformations(to: text) ?? text
                    continuation.resume(returning: fallbackResult)
                }
            }
        }
    }
    // MARK: - Settings Handling
    
    func loadSettings() {
        // Load settings from user defaults
        enableSuggestions = userDefaults.bool(forKey: "enableSuggestions")
        enableToneAnalysis = userDefaults.bool(forKey: "enableToneAnalysis")
        enableInsights = userDefaults.bool(forKey: "enableInsights")
        suggestionsEnabled = userDefaults.bool(forKey: "suggestionsEnabled")
        feedbackEnabled = userDefaults.bool(forKey: "feedbackEnabled")
    }
    
    func updateKeyboardSessionStatus(isActive: Bool) {
        // Update the keyboard session status in the analytics storage
        if isActive {
            analyticsStorage.startSession()
        } else {
            analyticsStorage.endSession()
        }
    }
    // MARK: - Data Synchronization
    
    /// Sync personality data from main app to keyboard extension
    private func syncPersonalityData() {
        print(" Syncing personality data for LocalAI...")
        
        // Note: Personality data is now handled internally by LocalAI
        // The keyboard no longer needs to manage attachment styles, communication preferences, etc.
        // LocalAI accesses this data directly through PersonalityDataManager
        
        PersonalityDataManager.shared.syncFromMainApp()
        print(" Personality data sync completed - LocalAI will handle context internally")
    }
    // MARK: - Local Tone Analysis Only
        
    /// Analyzes tone using SmartInferenceManager only
    func analyzeWithLocalOnly(text: String) -> ToneStatus {
        print("🧠 SmartInferenceManager tone analysis for: '\(text)'")
        
        let emotionalState = PersonalityDataManager.shared.getCurrentEmotionalState() ?? "neutral"
        
        // For sync function, return a default and update async
        smartInferenceManager.requestSuggestion(text: text, emotionalState: emotionalState) { [weak self] suggestion in
            DispatchQueue.main.async {
                // Update tone based on suggestion availability
                let status: ToneStatus = suggestion != nil ? .neutral : .warning
                self?.currentToneStatus = status
                print("✅ SmartInferenceManager tone result: \(status)")
            }
        }
        
        // Return current status immediately
        return currentToneStatus
    }
    // MARK: - AI Suggestion Generation
        
    /// Generates AI-powered suggestions using SmartInferenceManager only
    func generateAISuggestions(for text: String, toneStatus: ToneStatus) async throws -> [AdvancedSuggestion] {
        // Skip AI suggestions for very short text
        guard text.count >= 3 else {
            return generateFallbackSuggestions(for: toneStatus)
        }
        
        print("🧠 Generating SmartInferenceManager suggestions for: '\(text)' with tone: \(toneStatus)")
        
        let emotionalState = PersonalityDataManager.shared.getCurrentEmotionalState() ?? "neutral"
        
        return await withCheckedContinuation { continuation in
            smartInferenceManager.requestSuggestion(text: text, emotionalState: emotionalState) { suggestion in
                if let suggestion = suggestion, !suggestion.isEmpty {
                    // Convert to AdvancedSuggestion format
                    let advancedSuggestion = AdvancedSuggestion(
                        text: suggestion,
                        type: .toneImprovement,
                        priority: .medium,
                attachmentStyleSpecific: true, // LocalAI determines this internally
                reasoning: "Generated by Local AI processor",
                expectedOutcome: "Improved communication"
            )
        }
        
        print(" Generated \(advancedSuggestions.count) Local AI suggestions")
        return advancedSuggestions
    }
    // Applies secure communicator transformations to the given text
    func applySecureTransformations(to text: String) -> String {
        var improvedText = text
        
        // Apply secure communicator transformations
        for transformation in secureTransformations {
            let regex = try? NSRegularExpression(pattern: transformation.pattern, options: [.caseInsensitive])
            let range = NSRange(location: 0, length: improvedText.count)
            improvedText = regex?.stringByReplacingMatches(in: improvedText, options: [], range: range, withTemplate: transformation.replacement) ?? improvedText
        }
        
        // Clean up extra spaces from removals
        improvedText = improvedText.replacingOccurrences(of: "  ", with: " ")
        improvedText = improvedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Ensure proper capitalization
        if let firstChar = improvedText.first, firstChar.isLowercase {
            improvedText = improvedText.prefix(1).uppercased() + improvedText.dropFirst()
        }
        
        print(" Secure communicator transformation: '\(text)' → '\(improvedText)'")
        return improvedText
    }
    
    /// Generates fallback suggestions when AI is unavailable
    func generateFallbackSuggestions(for toneStatus: ToneStatus) -> [AdvancedSuggestion] {
        print(" Using Local AI fallback suggestions")
        
        // Use SmartInferenceManager for fallback suggestions too
        let emotionalState = PersonalityDataManager.shared.getCurrentEmotionalState() ?? "neutral"
        
        smartInferenceManager.requestSuggestion(text: currentText, emotionalState: emotionalState) { [weak self] suggestion in
            // This is async, so we don't return from here
            if let suggestion = suggestion, !suggestion.isEmpty {
                print("✅ SmartInferenceManager fallback suggestion: \(suggestion)")
            }
        }
        
        // Return basic suggestions for immediate use
                expectedOutcome: "Improved communication"estions()
            )sicSuggestions.enumerated().map { index, text in
        }dvancedSuggestion(
    }       text: text,
            type: .toneImprovement,
    /// Replaces the current text with improved version using animated typing: index + 1) ?? .medium,
    func replaceCurrentText(with newText: String) {
        guard let proxy = textDocumentProxy else {
                expectedOutcome: "Improved communication"
            )
        }
    }
    
    /// Replaces the current text with improved version using animated typing
    func replaceCurrentText(with newText: String) {
        guard let proxy = textDocumentProxy else {
            print(" Secure Communicator: No text document proxy available")
            return
        }
        
        print(" Secure Communicator: Starting animated text replacement")
        memoryMonitor.logMemoryUsage(context: "ReplaceCurrentText")
        
        // Get the current text context
        let beforeInput = proxy.documentContextBeforeInput ?? ""
        let afterInput = proxy.documentContextAfterInput ?? ""
        let fullText = beforeInput + afterInput
        
        print("   Before cursor: '\(beforeInput)'")
        print("   After cursor: '\(afterInput)'")
        print("   Full text: '\(fullText)'")
        print("   New text: '\(newText)'")
        
        // Step 1: Clear all existing text
        clearAllText(proxy: proxy, beforeInput: beforeInput, afterInput: afterInput, fullText: fullText)
        
        // Step 2: Brief pause before starting to type (makes it feel more natural)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Step 3: Animate typing the new text
            self.animateTyping(newText: newText, proxy: proxy)
        }
        
        // Update our current text tracking
        currentText = newText
        
        // Reset tone indicator to neutral after text replacement
        resetToneIndicator()
        
        print("✨ Secure Communicator: Animated replacement initiated")
    }
    
    /// Clears all existing text from the input field
    func clearAllText(proxy: UITextDocumentProxy, beforeInput: String, afterInput: String, fullText: String) {
        // Update button to show clearing in progress
        quickFixButton.setTitle("Clearing...", for: .normal)
        quickFixButton.backgroundColor = UIColor.systemOrange
        quickFixButton.isEnabled = false
        
        if afterInput.isEmpty {
            // Simple case: only text before cursor
            for _ in beforeInput {
                proxy.deleteBackward()
            }
        } else {
            // Complex case: text exists after cursor
            // Move cursor to the beginning
            proxy.adjustTextPosition(byCharacterOffset: -beforeInput.count)
            
            // Delete all text character by character
            for _ in fullText {
                proxy.deleteBackward()
            }
        }
        
        print(" Cleared all existing text")
    }
    
    /// Animates typing the new text character by character
    func animateTyping(newText: String, proxy: UITextDocumentProxy) {
        let characters = Array(newText)
        let typingSpeed: TimeInterval = 0.05 // 50ms per character for natural typing feel
        
        print(" Starting animated typing for \(characters.count) characters")
        memoryMonitor.logMemoryUsage(context: "AnimateTyping")
        
        // Cancel any existing typing animation
        typingAnimationWorkItem?.cancel()
        isTypingAnimation = true
        
        // Update button appearance to show typing in progress
        updateSecureButtonForTyping(isTyping: true)
        
        func typeNextCharacter(index: Int) {
            guard index < characters.count && isTypingAnimation else {
                print(" Animated typing completed or cancelled")
                // Reset button appearance when done
                isTypingAnimation = false
                updateSecureButtonForTyping(isTyping: false)
                return
            }
            
            let character = String(characters[index])
            proxy.insertText(character)
            
            // Create work item for next character
            typingAnimationWorkItem = DispatchWorkItem {
                typeNextCharacter(index: index + 1)
            }
            
            // Schedule next character
            DispatchQueue.main.asyncAfter(deadline: .now() + typingSpeed, execute: typingAnimationWorkItem!)
        }
        
        // Start typing the first character
        typeNextCharacter(index: 0)
    }
    
    /// Cancels the current typing animation
    @objc private func cancelTypingAnimation() {
        if isTypingAnimation {
            typingAnimationWorkItem?.cancel()
            isTypingAnimation = false
            updateSecureButtonForTyping(isTyping: false)
            print(" Typing animation cancelled")
        }
    }
    
    /// Updates the Secure button appearance during typing animation
    func updateSecureButtonForTyping(isTyping: Bool) {
        if isTyping {
            quickFixButton.setTitle("Typing...", for: .normal)
            quickFixButton.backgroundColor = UIColor.systemBlue
            quickFixButton.isEnabled = false
        } else {
            quickFixButton.setTitle("Secure", for: .normal)
            quickFixButton.backgroundColor = roseColor
            quickFixButton.isEnabled = true
        }
    }
    
    /// Resets the tone indicator to neutral state
    @objc func resetToneIndicator() {
        // Reset to neutral tone
        currentToneStatus = .neutral
        
        // Create neutral analysis result
        let neutralAnalysis = ToneAnalysis(status: .neutral, confidence: 0.5, suggestions: [])
        
        // Update tone indicator
        updateToneIndicator(with: neutralAnalysis)
        
        // Clear suggestions
        suggestions = []
        updateSuggestionButtons()
        
        print(" Tone indicator reset to neutral")
    }

    // MARK: - Personality Data Integration
    
    // Note: All personality context (attachment styles, relationship context, etc.) 
    // is now handled internally by LocalAI. The keyboard just passes text and receives results.

    // MARK: - Text Update Methods
    
    /// Updates the current text from the text document proxy
    func updateCurrentText() {
        // If we have a selection, we need to be more careful
        if let selectedText = textDocumentProxy?.selectedText, !selectedText.isEmpty {
            // For now, use just the before input since selection handling is complex
            currentText = textDocumentProxy?.documentContextBeforeInput ?? ""
        } else {
            currentText = textDocumentProxy?.documentContextBeforeInput ?? ""
        }
    }
    
    // MARK: - Debugging
    
    func printCurrentState() {
        Swift.print(" Current Text: \(currentText)")
        Swift.print(" Suggestions: \(suggestions)")
        Swift.print(" Current Tone Status: \(currentToneStatus)")
    }
    
    @objc private func suggestionTapped(_ sender: UIButton) {
        print(" SuggestionTapped called!")
        memoryMonitor.logMemoryUsage(context: "SuggestionTapped")
        
        // Toggle expansion of the suggestion button
        if expandedSuggestionButton == sender {
            // Collapse the button
            collapseSuggestionButton(sender)
        } else {
            // Expand the button  
            expandSuggestionButton(sender)
        }

        guard let suggestion = sender.title(for: .normal) else { 
        print("No suggestion title found")
            return 
        }
        print(" Suggestion advice viewed: \(suggestion)")
        
        // Note: Suggestion buttons now only display advice - they do not modify the message text
        // Only the secure fix button replaces the entire message
        // No text insertion - this is advice-only display
        
        // Record suggestion viewing (not insertion)
        let interaction = KeyboardInteraction(
            timestamp: Date(),
            textBefore: currentText,
            textAfter: currentText, // Text remains unchanged
            toneStatus: currentToneStatus,
            suggestionAccepted: false, // Not accepted since no text was inserted
            suggestionText: suggestion,
            analysisTime: 0.1,
            context: "suggestion_viewed",
            interactionType: .suggestion,
            userAcceptedSuggestion: false // Viewed but not applied
        )
        analyticsStorage.recordInteraction(interaction)
    }

    private func collapseSuggestionButton(_ button: UIButton) {
        guard let fullText = button.accessibilityHint else { return }
        
        // Mark as collapsed
        expandedSuggestionButton = nil
        
        // Truncate text for collapsed state
        let truncatedText = String(fullText.prefix(30)) + (fullText.count > 30 ? "..." : "")
        
        // Update button appearance for collapsed state
        UIView.animate(withDuration: 0.3) {
            button.titleLabel?.numberOfLines = 1
            if let titleLabel = button.titleLabel {
                titleLabel.lineBreakMode = .byTruncatingTail
            }
            button.setTitle(truncatedText, for: .normal)
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.lightGray.cgColor
            button.transform = CGAffineTransform.identity
        }
        
        Swift.print("📱 Suggestion collapsed: \(truncatedText)")
    }
    
    private func expandSuggestionButton(_ button: UIButton) {
        guard let fullText = button.accessibilityHint else { return }
        
        // Mark as expanded
        expandedSuggestionButton = button
        
        // Update button appearance for expanded state
        UIView.animate(withDuration: 0.3) {
            button.titleLabel?.numberOfLines = 0  // Allow multiple lines
            button.setTitle(fullText, for: .normal)
            button.layer.borderWidth = 2
            button.layer.borderColor = UIColor.systemBlue.cgColor
            button.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            button.layoutIfNeeded()
        }
        
        Swift.print("📱 Suggestion expanded: \(fullText)")
    }
}

// MARK: - Suggestion Button Expansion

extension KeyboardController {
    @objc private func expandSuggestion(_ gesture: UITapGestureRecognizer) {
        guard let button = gesture.view as? UIButton,
              let fullText = button.accessibilityHint else { return }
        
        // Toggle between expanded and collapsed states
        if button.titleLabel?.numberOfLines == 1 {
            // Expand to show full text
            button.titleLabel?.numberOfLines = 0  // Allow multiple lines
            button.setTitle(fullText, for: .normal)
            
            // Animate the expansion
            UIView.animate(withDuration: 0.3) {
                button.layoutIfNeeded()
            }
        } else {
            // Collapse back to one line
            button.titleLabel?.numberOfLines = 1
            button.setTitle(fullText, for: .normal)  // This will auto-truncate
            
            // Animate the collapse
            UIView.animate(withDuration: 0.3) {
                button.layoutIfNeeded()
            }
        }
    }
    
    @objc private func delaySingleTap(_ gesture: UITapGestureRecognizer) {
        // Delay to allow for potential double tap
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let button = gesture.view as? UIButton else { return }
            self.suggestionTapped(button)
        }
    }
}


// MARK: - Keyboard Mode
