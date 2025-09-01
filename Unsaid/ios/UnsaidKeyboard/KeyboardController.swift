//
//  KeyboardController.swift
//  UnsaidKeyboard
//
//  SIMPLIFIED COORDINATOR VERSION
//  Main keyboard controller that orchestrates managers and services
//  Following the architecture documented at the top of the original file
//

import Foundation
import os.log
import AudioToolbox
import UIKit

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
            // Perform analysis here
            let result = AnalysisResult(topSuggestion: nil, rewrite: nil, confidence: 0.0)
            
            DispatchQueue.main.async {
                self?.cache[key] = result
                completion(result)
            }
        }
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
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setSuggestions(_ suggestions: [String], onTap: @escaping (String) -> Void) {
        self.onTap = onTap
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if suggestions.isEmpty {
            isHidden = true
            return
        }
        isHidden = false
        for s in suggestions.prefix(3) { stack.addArrangedSubview(pill(s)) }
    }
    
    func updateCandidates(_ suggestions: [String]) {
        setSuggestions(suggestions) { _ in }
    }

    private func pill(_ title: String) -> UIButton {
        // Use KeyButtonFactory for consistent styling
        let button = KeyButtonFactory.makeControlButton(title: title, background: .systemGray6, text: .label)
        button.addAction(UIAction { [weak self] _ in
            self?.onTap?(title)
        }, for: .touchUpInside)
        return button
    }
}

// MARK: - Keyboard Modes
enum KeyboardMode {
    case letters
    case numbers
    case symbols
}

// MARK: - Main Keyboard Controller (Simplified Coordinator)
final class KeyboardController: UIInputView, 
                                ToneSuggestionDelegate, 
                                UIInputViewAudioFeedback, 
                                UIGestureRecognizerDelegate,
                                DeleteManagerDelegate,
                                SuggestionChipManagerDelegate,
                                SpaceHandlerDelegate,
                                SpellCheckerIntegrationDelegate,
                                SecureFixManagerDelegate {

    // MARK: - Services and Managers
    private let logger = Logger(subsystem: "com.example.unsaid.unsaid.UnsaidKeyboard", category: "KeyboardController")
    private var coordinator: ToneSuggestionCoordinator?
    
    // Managers (UIKit-heavy, per-feature)
    private let deleteManager = DeleteManager()
    private let keyPreviewManager = KeyPreviewManager()
    private let suggestionChipManager = SuggestionChipManager()
    private let spaceHandler = SpaceHandler()
    private let secureFixManager = SecureFixManager()
    
    // Services (Logic, async, networking)
    private let spellCheckerIntegration = SpellCheckerIntegration()
    
    // MARK: - OpenAI Configuration
    private var openAIAPIKey: String {
        let extBundle = Bundle(for: KeyboardController.self)
        let mainBundle = Bundle.main
        let fromExt = extBundle.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String
        let fromMain = mainBundle.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String
        return (fromExt?.trimmingCharacters(in: .whitespacesAndNewlines) ?? fromMain?.trimmingCharacters(in: .whitespacesAndNewlines)) ?? ""
    }
    
    // MARK: - Native feedback
    private let impact = UIImpactFeedbackGenerator(style: .light)
    var enableInputClicksWhenVisible: Bool { true }

    // MARK: - Spell checking
    private let spellStrip = SpellCandidatesStrip()

    // MARK: - Parent VC
    private weak var parentInputVC: UIInputViewController?

    // MARK: - UI Components
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
    
    // Host trait sync
    private var smartQuotesEnabled = true
    private var smartDashesEnabled = true
    private var smartInsertDeleteEnabled = true

    // Suggestions
    private var suggestions: [String] = []
    private var isSuggestionBarVisible = true
    private var lastDisplayedSuggestions: [String] = []

    // Text cache
    private var currentText: String = ""

    // Layout constants
    private let verticalSpacing: CGFloat = 8
    private let horizontalSpacing: CGFloat = 6
    private let sideMargins: CGFloat = 8

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

    // MARK: - Analysis properties
    private let analyzer = SwitchInAnalyzer.shared
    private var analysisTimer: Timer?
    private var lastAnalyzedSentence: String = ""
    private var lastInputAt: TimeInterval = 0

    // Context refresh properties
    private var beforeContext: String = ""
    private var afterContext: String = ""
    
    // Safe area constraint management
    private var safeAreaBottomConstraint: NSLayoutConstraint?

    // MARK: - Convenience
    private var textDocumentProxy: UITextDocumentProxy? {
        return parentInputVC?.textDocumentProxy
    }

    // MARK: - Lifecycle
    override var intrinsicContentSize: CGSize {
        if let superView = superview, superView.bounds.height > 0 {
            return CGSize(width: UIView.noIntrinsicMetric, height: superView.bounds.height)
        }
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

    func configure(with inputVC: UIInputViewController) {
        parentInputVC = inputVC
        coordinator = ToneSuggestionCoordinator(delegate: self)
        refreshContext()
        syncHostTraits()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateAppearance(traitCollection.userInterfaceStyle == .dark ? .dark : .default)
    }

    private func commonInit() {
        setupDelegates()
        setupKeyboardLayout()
        setupSuggestionBar()
        analyzer.prewarm()
    }
    
    private func setupDelegates() {
        // Setup all manager delegates
        deleteManager.delegate = self
        suggestionChipManager.delegate = self
        spaceHandler.delegate = self
        spellCheckerIntegration.delegate = self
        secureFixManager.delegate = self
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview != nil {
            analyzer.prewarm()
        }
    }
    
    override func removeFromSuperview() {
        coordinator?.cleanup()
        analysisTimer?.invalidate()
        keyPreviewManager.dismissAllKeyPreviews()
        super.removeFromSuperview()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Trigger manager updates if needed
    }

    // MARK: - DeleteManagerDelegate
    func performDelete() {
        guard let proxy = textDocumentProxy else { return }
        
        // Try undo first
        if spellCheckerIntegration.undoLastCorrection(in: proxy) {
            return
        }
        
        proxy.deleteBackward()
        impact.impactOccurred()
        textDidChange()
    }
    
    func performDeleteTick() {
        guard let proxy = textDocumentProxy else { return }
        proxy.deleteBackward()
        textDidChange()
    }

    // MARK: - SuggestionChipManagerDelegate
    func didTapSuggestion(_ suggestion: String) {
        applySuggestionText(suggestion)
    }
    
    func didDismissSuggestion() {
        // Handle dismissal analytics or cleanup
    }
    
    func didExpandSuggestion() {
        // Handle expansion analytics
    }
    
    func didSwipeToNextSuggestion() {
        // Handle swipe analytics
    }
    
    func didSwipeToPreviousSuggestion() {
        // Handle swipe analytics
    }

    // MARK: - SpaceHandlerDelegate
    func insertText(_ text: String) {
        guard let proxy = textDocumentProxy else { return }
        proxy.insertText(text)
        
        // Handle autocorrection on space
        if text == " " {
            spellCheckerIntegration.autocorrectLastWordIfNeeded(afterTyping: " ", in: proxy)
        }
        
        textDidChange()
    }
    
    func moveSelection(by offset: Int) {
        guard let proxy = textDocumentProxy else { return }
        
        if offset > 0 {
            for _ in 0..<offset {
                proxy.adjustTextPosition(byCharacterOffset: 1)
            }
        } else {
            for _ in 0..<abs(offset) {
                proxy.adjustTextPosition(byCharacterOffset: -1)
            }
        }
    }
    
    func getTextDocumentProxy() -> UITextDocumentProxy? {
        return textDocumentProxy
    }

    // MARK: - SpellCheckerIntegrationDelegate
    func didUpdateSpellingSuggestions(_ suggestions: [String]) {
        spellStrip.updateCandidates(suggestions)
    }
    
    func didApplySpellCorrection(_ correction: String, original: String) {
        // Handle spell correction analytics
    }

    // MARK: - SecureFixManagerDelegate
    func getOpenAIAPIKey() -> String {
        return openAIAPIKey
    }
    
    func getCurrentTextForAnalysis() -> String {
        let before = beforeContext
        let after = afterContext
        
        // Simple combination - could be more sophisticated
        return before + after
    }
    
    func replaceCurrentMessage(with newText: String) {
        guard let proxy = textDocumentProxy else { return }
        replaceAllText(with: newText, on: proxy)
    }
    
    func buildUserProfileForSecureFix() -> [String: Any] {
        // Build user profile from analytics and preferences
        return [
            "typing_style": "casual",
            "communication_tone": "friendly"
        ]
    }
    
    func showUsageLimitAlert(message: String) {
        // Show alert to user about usage limits
        // This could be implemented as a temporary overlay or chip
        suggestionChipManager.showSuggestionChip(text: message, toneString: "caution")
    }

    // MARK: - Host Traits Sync
    private func syncHostTraits() {
        guard let proxy = textDocumentProxy else { return }
        
        // Autocapitalization
        switch proxy.autocapitalizationType ?? .none {
        case .sentences, .words, .allCharacters:
            updateShiftButtonAppearance()
            updateKeyTitlesForShiftState()
        default:
            break
        }

        // Autocorrection / spell strip
        let wantsAutocorrect = (proxy.autocorrectionType ?? .default) != .no
        spellStrip.isHidden = !wantsAutocorrect

        // Smart quotes / dashes / insert-delete
        smartQuotesEnabled = (proxy.smartQuotesType ?? .default) != .no
        smartDashesEnabled = (proxy.smartDashesType ?? .default) != .no
        smartInsertDeleteEnabled = (proxy.smartInsertDeleteType ?? .default) != .no

        // Return key label and behavior
        if let returnButton = returnButton {
            KeyButtonFactory.updateReturnButtonAppearance(returnButton, for: proxy.returnKeyType ?? .default)
        }

        // Keyboard appearance
        updateAppearance(proxy.keyboardAppearance ?? .default)
    }
    
    private func updateAppearance(_ appearance: UIKeyboardAppearance) {
        let isDark = (appearance == .dark || (appearance == .default && traitCollection.userInterfaceStyle == .dark))
        let bg: UIColor = isDark ? UIColor.black : UIColor.keyboardBackground
        backgroundColor = bg
        suggestionBar?.backgroundColor = isDark ? .systemGray5.withAlphaComponent(0.25) : .systemGray5
    }

    // MARK: - Suggestion bar setup
    private func setupSuggestionBar() {
        let bar = UIView()
        bar.backgroundColor = .systemGray5
        bar.translatesAutoresizingMaskIntoConstraints = false
        
        // Tone indicator button
        let toneBtn = UIButton(type: .system)
        toneBtn.setTitle("✨", for: .normal)
        toneBtn.titleLabel?.font = .systemFont(ofSize: 18)
        toneBtn.backgroundColor = .systemGray4
        toneBtn.layer.cornerRadius = 16
        toneBtn.translatesAutoresizingMaskIntoConstraints = false
        toneBtn.addTarget(self, action: #selector(performEnhancedToneAnalysis), for: .touchUpInside)
        
        // Undo button
        let undoBtn = UIButton(type: .system)
        undoBtn.setTitle("↶", for: .normal)
        undoBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        undoBtn.backgroundColor = .systemGray4
        undoBtn.layer.cornerRadius = 16
        undoBtn.translatesAutoresizingMaskIntoConstraints = false
        undoBtn.addTarget(self, action: #selector(undoButtonTapped), for: .touchUpInside)
        undoBtn.isHidden = true
        
        bar.addSubview(toneBtn)
        bar.addSubview(undoBtn)
        bar.addSubview(spellStrip)
        
        NSLayoutConstraint.activate([
            toneBtn.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 12),
            toneBtn.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
            toneBtn.widthAnchor.constraint(equalToConstant: 32),
            toneBtn.heightAnchor.constraint(equalToConstant: 32),
            
            undoBtn.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -12),
            undoBtn.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
            undoBtn.widthAnchor.constraint(equalToConstant: 32),
            undoBtn.heightAnchor.constraint(equalToConstant: 32),
            
            spellStrip.leadingAnchor.constraint(equalTo: toneBtn.trailingAnchor, constant: 8),
            spellStrip.trailingAnchor.constraint(equalTo: undoBtn.leadingAnchor, constant: -8),
            spellStrip.topAnchor.constraint(equalTo: bar.topAnchor, constant: 4),
            spellStrip.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: -4)
        ])
        
        suggestionBar = bar
        toneIndicator = toneBtn
        undoButtonRef = undoBtn
        
        // Configure suggestion chip manager
        suggestionChipManager.configure(suggestionBar: bar, toneButton: toneBtn)
        
        addSubview(bar)
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: topAnchor),
            bar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: trailingAnchor),
            bar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Keyboard layout
    private func setupKeyboardLayout() {
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = verticalSpacing
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Create keyboard rows
        let (topKeys, midKeys, botKeys) = getKeysForCurrentMode()
        
        let topRow = rowStack(for: topKeys)
        let midRow = rowStack(for: midKeys, centerNine: currentMode == .letters)
        let botRow = rowStack(for: botKeys)
        let controlRow = controlRowStack()
        
        mainStack.addArrangedSubview(topRow)
        mainStack.addArrangedSubview(midRow)
        mainStack.addArrangedSubview(botRow)
        mainStack.addArrangedSubview(controlRow)
        
        addSubview(mainStack)
        keyboardStackView = mainStack
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: suggestionBar?.bottomAnchor ?? topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: sideMargins),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -sideMargins),
            mainStack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
    }

    private func rowStack(for titles: [String], centerNine: Bool = false) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = horizontalSpacing
        
        if centerNine && titles.count == 9 {
            // Add spacers for middle row centering
            let spacer1 = UIView()
            spacer1.widthAnchor.constraint(equalToConstant: 22).isActive = true
            stack.addArrangedSubview(spacer1)
        }
        
        for title in titles {
            let button = KeyButtonFactory.makeKeyButton(title: shouldCapitalizeKey(title) ? title.uppercased() : title)
            button.addTarget(self, action: #selector(keyTapped(_:)), for: .touchUpInside)
            button.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(buttonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])
            stack.addArrangedSubview(button)
        }
        
        if centerNine && titles.count == 9 {
            let spacer2 = UIView()
            spacer2.widthAnchor.constraint(equalToConstant: 22).isActive = true
            stack.addArrangedSubview(spacer2)
        }
        
        return stack
    }

    private func controlRowStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = horizontalSpacing
        stack.distribution = .fill
        
        // Shift button
        let shift = KeyButtonFactory.makeShiftButton()
        shift.addTarget(self, action: #selector(handleShiftPressed), for: .touchUpInside)
        shift.addTarget(self, action: #selector(specialButtonTouchDown(_:)), for: .touchDown)
        shift.addTarget(self, action: #selector(specialButtonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])
        shiftButton = shift
        
        // Mode button (123/ABC)
        let mode = KeyButtonFactory.makeControlButton(title: currentMode == .letters ? "123" : "ABC")
        mode.addTarget(self, action: #selector(handleModeSwitch), for: .touchUpInside)
        mode.addTarget(self, action: #selector(specialButtonTouchDown(_:)), for: .touchDown)
        mode.addTarget(self, action: #selector(specialButtonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])
        modeButton = mode
        
        // Globe button
        let globe = KeyButtonFactory.makeControlButton(title: "🌐")
        globe.addTarget(self, action: #selector(handleGlobeKey), for: .touchUpInside)
        globe.addTarget(self, action: #selector(specialButtonTouchDown(_:)), for: .touchDown)
        globe.addTarget(self, action: #selector(specialButtonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])
        globeButton = globe
        
        // Space button
        let space = KeyButtonFactory.makeSpaceButton()
        space.addTarget(self, action: #selector(handleSpaceKey), for: .touchUpInside)
        space.addTarget(self, action: #selector(specialButtonTouchDown(_:)), for: .touchDown)
        space.addTarget(self, action: #selector(specialButtonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])
        spaceButton = space
        spaceHandler.setupSpaceButton(space)
        
        // Secure Fix button
        let secureFix = KeyButtonFactory.makeControlButton(title: "Secure", background: .systemBlue, text: .white)
        secureFix.addTarget(self, action: #selector(handleQuickFix), for: .touchUpInside)
        secureFix.addTarget(self, action: #selector(specialButtonTouchDown(_:)), for: .touchDown)
        secureFix.addTarget(self, action: #selector(specialButtonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])
        quickFixButton = secureFix
        
        // Return button
        let returnBtn = KeyButtonFactory.makeReturnButton()
        returnBtn.addTarget(self, action: #selector(handleReturnKey), for: .touchUpInside)
        returnBtn.addTarget(self, action: #selector(specialButtonTouchDown(_:)), for: .touchDown)
        returnBtn.addTarget(self, action: #selector(specialButtonTouchUp(_:)), for: [.touchUpInside, .touchUpOutside])
        returnButton = returnBtn
        
        // Delete button
        let delete = KeyButtonFactory.makeDeleteButton()
        delete.addTarget(self, action: #selector(deleteTouchDown), for: .touchDown)
        delete.addTarget(self, action: #selector(deleteTouchUp), for: [.touchUpInside, .touchUpOutside])
        deleteButton = delete
        
        // Add to stack with proper constraints
        stack.addArrangedSubview(shift)
        stack.addArrangedSubview(mode)
        stack.addArrangedSubview(globe)
        stack.addArrangedSubview(space)
        stack.addArrangedSubview(secureFix)
        stack.addArrangedSubview(returnBtn)
        stack.addArrangedSubview(delete)
        
        // Space button should take more space
        space.widthAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
        
        return stack
    }

    // MARK: - Key input handling
    @objc private func keyTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal), let proxy = textDocumentProxy else { return }
        
        var textToInsert = title
        
        // Apply smart quotes/dashes if enabled
        if smartQuotesEnabled {
            textToInsert = applyTextReplacements(textToInsert)
        }
        
        proxy.insertText(textToInsert)
        impact.impactOccurred()
        
        // Handle shift state after character insertion
        if currentMode == .letters && isShifted && !isCapsLocked {
            isShifted = false
            updateShiftButtonAppearance()
            updateKeyTitlesForShiftState()
        }
        
        textDidChange()
    }
    
    @objc private func handleSpaceKey() {
        spaceHandler.handleSpaceKey()
        impact.impactOccurred()
    }
    
    @objc private func handleReturnKey() {
        guard let proxy = textDocumentProxy else { return }
        proxy.insertText("\n")
        impact.impactOccurred()
        textDidChange()
    }
    
    @objc private func handleGlobeKey() {
        // Advance to next keyboard
        parentInputVC?.advanceToNextInputMode()
    }
    
    @objc private func handleShiftPressed() {
        let now = CACurrentMediaTime()
        let timeSinceLastTap = now - lastShiftTapAt
        
        if timeSinceLastTap < 0.3 {
            // Double tap - toggle caps lock
            isCapsLocked.toggle()
            isShifted = isCapsLocked
        } else {
            // Single tap - toggle shift
            if isCapsLocked {
                isCapsLocked = false
                isShifted = false
            } else {
                isShifted.toggle()
            }
        }
        
        lastShiftTapAt = now
        updateShiftButtonAppearance()
        updateKeyTitlesForShiftState()
        impact.impactOccurred()
    }
    
    @objc private func handleModeSwitch() {
        currentMode = currentMode == .letters ? .numbers : .letters
        updateKeyboardForCurrentMode()
        impact.impactOccurred()
    }
    
    @objc private func handleQuickFix() {
        secureFixManager.handleQuickFix()
        impact.impactOccurred()
    }
    
    @objc private func deleteTouchDown() {
        deleteManager.beginDeleteRepeat()
    }
    
    @objc private func deleteTouchUp() {
        deleteManager.endDeleteRepeat()
    }

    // MARK: - Visual feedback
    @objc private func buttonTouchDown(_ button: UIButton) {
        KeyButtonFactory.animateButtonPress(button)
        keyPreviewManager.showKeyPreview(for: button)
    }
    
    @objc private func buttonTouchUp(_ button: UIButton) {
        keyPreviewManager.hideKeyPreview(for: button)
    }
    
    @objc private func specialButtonTouchDown(_ button: UIButton) {
        KeyButtonFactory.animateSpecialButtonPress(button)
    }
    
    @objc private func specialButtonTouchUp(_ button: UIButton) {
        // No special handling needed
    }

    // MARK: - State updates
    private func updateShiftButtonAppearance() {
        guard let shiftButton = shiftButton else { return }
        KeyButtonFactory.updateShiftButtonAppearance(shiftButton, isShifted: isShifted, isCapsLocked: isCapsLocked)
    }
    
    private func updateKeyTitlesForShiftState() {
        guard let stack = keyboardStackView else { return }
        updateKeysInStackView(stack)
    }
    
    private func updateKeysInStackView(_ stack: UIStackView) {
        for view in stack.arrangedSubviews {
            if let button = view as? UIButton,
               let title = button.title(for: .normal),
               title.count == 1 {
                let newTitle = shouldCapitalizeKey(title) ? title.uppercased() : title.lowercased()
                button.setTitle(newTitle, for: .normal)
            } else if let nestedStack = view as? UIStackView {
                updateKeysInStackView(nestedStack)
            }
        }
    }
    
    private func updateKeyboardForCurrentMode() {
        // Rebuild keyboard layout for new mode
        keyboardStackView?.removeFromSuperview()
        setupKeyboardLayout()
        
        // Update mode button title
        modeButton?.setTitle(currentMode == .letters ? "123" : "ABC", for: .normal)
    }
    
    private func shouldCapitalizeKey(_ key: String) -> Bool {
        guard currentMode == .letters else { return false }
        return isShifted || isCapsLocked
    }
    
    private func getKeysForCurrentMode() -> ([String], [String], [String]) {
        switch currentMode {
        case .letters:
            return (topRowKeys, midRowKeys, botRowKeys)
        case .numbers:
            return (topRowNumbers, midRowNumbers, botRowNumbers)
        case .symbols:
            return (topRowSymbols, midRowSymbols, botRowSymbols)
        }
    }

    // MARK: - Text change handling
    func textDidChange() {
        handleTextChange()
    }
    
    private func handleTextChange() {
        updateCurrentText()
        refreshContext()
        spellCheckerIntegration.refreshSpellCandidates(for: currentText)
    }
    
    private func updateCurrentText() {
        guard let proxy = textDocumentProxy else {
            currentText = ""
            return
        }
        
        let before = proxy.documentContextBeforeInput ?? ""
        let after = proxy.documentContextAfterInput ?? ""
        currentText = before + after
    }
    
    private func refreshContext() {
        guard let proxy = textDocumentProxy else { return }
        beforeContext = proxy.documentContextBeforeInput ?? ""
        afterContext = proxy.documentContextAfterInput ?? ""
        
        // Clamp for performance
        beforeContext = String(beforeContext.suffix(600))
        afterContext = String(afterContext.prefix(200))
    }

    // MARK: - Text replacement helpers
    private func applyTextReplacements(_ text: String) -> String {
        var result = text
        
        if smartQuotesEnabled {
            // Simple smart quotes logic
            if result == "\"" {
                let beforeText = beforeContext
                let hasOpenQuote = beforeText.filter { $0 == "\"" }.count % 2 != 0
                result = hasOpenQuote ? "\"" : "\""
            }
        }
        
        return result
    }
    
    private func replaceAllText(with newText: String, on proxy: UITextDocumentProxy) {
        // Clear all existing text
        if let selectedRange = proxy.selectedTextRange {
            proxy.setSelectedTextRange(selectedRange)
        }
        
        // Delete all content
        while let before = proxy.documentContextBeforeInput, !before.isEmpty {
            proxy.deleteBackward()
        }
        
        // Insert new text
        proxy.insertText(newText)
    }
    
    private func applySuggestionText(_ text: String) {
        guard let proxy = textDocumentProxy else { return }
        
        // Simple replacement - could be more sophisticated
        let words = beforeContext.split(separator: " ")
        if let lastWord = words.last {
            // Replace last word
            for _ in 0..<lastWord.count {
                proxy.deleteBackward()
            }
        }
        
        proxy.insertText(text)
        textDidChange()
    }

    // MARK: - Undo functionality
    @objc private func undoButtonTapped() {
        _ = spellCheckerIntegration.undoLastCorrection(in: textDocumentProxy!)
        impact.impactOccurred()
    }

    // MARK: - Enhanced Tone Analysis
    @objc func performEnhancedToneAnalysis() {
        let currentText = getCurrentTextForAnalysis()
        guard !currentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        coordinator?.analyzeFinalSentence(currentText)
        impact.impactOccurred()
    }

    // MARK: - ToneSuggestionDelegate
    func didUpdateSuggestions(_ suggestions: [String]) {
        guard !suggestions.isEmpty else { return }
        suggestionChipManager.showSuggestionChip(suggestions: suggestions)
    }

    func didUpdateToneStatus(_ status: String) {
        // Update tone indicator
        let toneEmoji: String
        switch status.lowercased() {
        case "alert": toneEmoji = "⚠️"
        case "caution": toneEmoji = "⚡"
        case "clear": toneEmoji = "✅"
        default: toneEmoji = "✨"
        }
        
        toneIndicator?.setTitle(toneEmoji, for: .normal)
    }

    func didUpdateSecureFixButtonState() {
        let remaining = secureFixManager.getRemainingSecureFixUses()
        let alpha: CGFloat = remaining > 0 ? 1.0 : 0.5
        quickFixButton?.alpha = alpha
    }
}
