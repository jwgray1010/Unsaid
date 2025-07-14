//
//  KeyboardViewController.swift
//  Unsaid
//
//  Created by John Gray on 7/9/25.
//

import UIKit

class KeyboardViewController: UIInputViewController {

    @IBOutlet var nextKeyboardButton: UIButton!
    
    // MARK: - Managers
    var uiSetupManager: KeyboardUISetupManager?
    private var toneAnalyzer: KeyboardToneAnalyzer?
    private var suggestionManager: KeyboardSuggestionManager?
    private var settingsManager: KeyboardSettingsManager?
    
    // MARK: - State
    private var currentText: String = ""
    private var debounceTimer: Timer?
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        // Add custom view sizing constraints here
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize all managers
        setupManagers()
        
        // Setup Grammarly-style keyboard UI
        setupKeyboardUI()
        
        // Start listening for text changes
        setupTextObserving()
    }
    
    private func setupManagers() {
        // Initialize UI Setup Manager
        uiSetupManager = KeyboardUISetupManager(viewController: self)
        
        // Initialize tone analyzer
        toneAnalyzer = KeyboardToneAnalyzer()
        
        // Initialize suggestion manager
        suggestionManager = KeyboardSuggestionManager.shared
        suggestionManager?.viewController = self
        
        // Initialize settings manager
        settingsManager = KeyboardSettingsManager.shared
    }
    
    private func setupKeyboardUI() {
        // Setup the Grammarly-style keyboard interface
        uiSetupManager?.setupGrammarlyStyleKeyboard()
        
        // Setup next keyboard button (for switching keyboards)
        setupNextKeyboardButton()
    }
    
    private func setupNextKeyboardButton() {
        self.nextKeyboardButton = UIButton(type: .system)
        self.nextKeyboardButton.setTitle("🌐", for: [])
        self.nextKeyboardButton.sizeToFit()
        self.nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        
        self.view.addSubview(self.nextKeyboardButton)
        
        // Position the button in the corner
        NSLayoutConstraint.activate([
            self.nextKeyboardButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -8),
            self.nextKeyboardButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -8),
            self.nextKeyboardButton.widthAnchor.constraint(equalToConstant: 30),
            self.nextKeyboardButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupTextObserving() {
        // Start observing text changes for real-time analysis
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChangeNotification),
            name: UITextInputMode.currentInputModeDidChangeNotification,
            object: nil
        )
    }
    
    override func viewWillLayoutSubviews() {
        self.nextKeyboardButton?.isHidden = !self.needsInputModeSwitchKey
        super.viewWillLayoutSubviews()
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        
        // Update button appearance based on keyboard theme
        updateButtonAppearance()
        
        // Get current text and perform real-time analysis
        getCurrentTextAndAnalyze()
    }
    
    private func updateButtonAppearance() {
        var textColor: UIColor
        let proxy = self.textDocumentProxy
        if proxy.keyboardAppearance == UIKeyboardAppearance.dark {
            textColor = UIColor.white
        } else {
            textColor = UIColor.black
        }
        self.nextKeyboardButton?.setTitleColor(textColor, for: [])
    }
    
    private func getCurrentTextAndAnalyze() {
        // Get the current text from the document proxy
        let proxy = self.textDocumentProxy
        let beforeInput = proxy.documentContextBeforeInput ?? ""
        let afterInput = proxy.documentContextAfterInput ?? ""
        let fullText = beforeInput + afterInput
        
        // Only analyze if text has changed
        if fullText != currentText {
            currentText = fullText
            
            // Debounce the analysis to avoid too many calls
            debounceTimer?.invalidate()
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                self?.performRealTimeAnalysis(fullText)
            }
        }
    }
    
    private func performRealTimeAnalysis(_ text: String) {
        guard !text.isEmpty else {
            // Clear suggestions if text is empty
            suggestionManager?.clearSuggestions()
            return
        }
        
        // Perform real-time tone analysis and suggestions
        suggestionManager?.performRealTimeAnalysis(text)
    }
    
    @objc private func textDidChangeNotification() {
        getCurrentTextAndAnalyze()
    }
    
    // MARK: - Public Methods for UI Manager
    
    /// Shows detailed tone analysis UI
    func showDetailedToneAnalysis() {
        // Display detailed tone analysis interface
        print("Showing detailed tone analysis for: \(currentText)")
        
        if let toneAnalyzer = toneAnalyzer {
            let analysis = toneAnalyzer.getDetailedAnalysis(currentText)
            // Show analysis in console for now (can be enhanced later)
            print("Detailed analysis: \(analysis)")
            
            // Optionally show a simple alert or expand the keyboard height
            self.preferredContentSize = CGSize(width: 0, height: 120)
        }
    }
    
    /// Applies a suggestion to the current text
    /// - Parameter suggestion: The suggested text to apply
    func applySuggestion(_ suggestion: String) {
        guard !suggestion.isEmpty else { return }
        
        let textDocumentProxy = self.textDocumentProxy
        
        // Get the current text before the cursor
        if let beforeInput = textDocumentProxy.documentContextBeforeInput {
            // Delete the current text
            for _ in 0..<beforeInput.count {
                textDocumentProxy.deleteBackward()
            }
        }
        
        // Insert the suggestion
        textDocumentProxy.insertText(suggestion)
        
        print("Applied suggestion: \(suggestion)")
        
        // Clear suggestions after applying
        suggestionManager?.clearSuggestions()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        debounceTimer?.invalidate()
    }
}
