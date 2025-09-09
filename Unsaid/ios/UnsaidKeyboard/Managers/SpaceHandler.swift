//
//  SpaceHandler.swift
//  UnsaidKeyboard
//
//  Manages space bar functionality including double-space period and trackpad pan
//

import Foundation
import UIKit

protocol SpaceHandlerDelegate: AnyObject {
    func insertText(_ text: String)
    func moveSelection(by offset: Int)
    func getTextDocumentProxy() -> UITextDocumentProxy?
}

final class SpaceHandler {
    weak var delegate: SpaceHandlerDelegate?
    
    // Double-space configuration
    private var lastSpaceTapTime: TimeInterval = 0
    private let doubleSpaceWindow: TimeInterval = 0.35
    
    // Trackpad pan gesture
    private var spacePan: UIPanGestureRecognizer?
    private var cursorAccumulator: CGFloat = 0
    
    init() {}
    
    // MARK: - Public Interface
    
    func setupSpaceButton(_ button: UIButton) {
        // Setup trackpad pan gesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSpacePan(_:)))
        button.addGestureRecognizer(panGesture)
        spacePan = panGesture
    }
    
    func handleSpaceKey() {
        let now = CACurrentMediaTime()
        let timeSinceLastTap = now - lastSpaceTapTime
        
        if timeSinceLastTap <= doubleSpaceWindow {
            // Double-space: insert period and space
            handleDoubleSpacePeriod()
        } else {
            // Single space
            handleSingleSpace()
        }
        
        lastSpaceTapTime = now
    }
    
    // MARK: - Private Implementation
    
    private func handleSingleSpace() {
        delegate?.insertText(" ")
    }
    
    private func handleDoubleSpacePeriod() {
        guard let proxy = delegate?.getTextDocumentProxy() else {
            delegate?.insertText(" ")
            return
        }
        
        // Get text before cursor
        let beforeText = proxy.documentContextBeforeInput ?? ""
        
        // Check if we should do double-space period insertion
        let shouldInsertPeriod = shouldInsertPeriodForDoubleSpace(beforeText: beforeText)
        
        if shouldInsertPeriod {
            // Remove the previous space and insert period + space
            proxy.deleteBackward()
            delegate?.insertText(". ")
        } else {
            // Just insert a regular space
            delegate?.insertText(" ")
        }
    }
    
    private func shouldInsertPeriodForDoubleSpace(beforeText: String) -> Bool {
        // Don't insert period if text is empty or only whitespace
        let trimmed = beforeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        // Don't insert period if the last character is already punctuation
        if let lastChar = trimmed.last, CharacterSet.punctuationCharacters.contains(Unicode.Scalar(String(lastChar))!) {
            return false
        }
        
        // Don't insert period after common abbreviations or URLs
        let words = trimmed.split(separator: " ")
        if let lastWord = words.last?.lowercased() {
            let commonAbbreviations = ["mr", "mrs", "dr", "vs", "etc", "inc", "ltd", "www"]
            if commonAbbreviations.contains(String(lastWord)) {
                return false
            }
            
            // Don't insert period in URLs or email addresses
            if lastWord.contains(".") || lastWord.contains("@") {
                return false
            }
        }
        
        return true
    }
    
    @objc private func handleSpacePan(_ gr: UIPanGestureRecognizer) {
        let translation = gr.translation(in: gr.view)
        let velocity = gr.velocity(in: gr.view)
        
        switch gr.state {
        case .began:
            cursorAccumulator = 0
            
        case .changed:
            // Accumulate horizontal movement
            cursorAccumulator += translation.x
            gr.setTranslation(.zero, in: gr.view)
            
            // Calculate cursor movement (adjust sensitivity as needed)
            let sensitivity: CGFloat = 20.0
            let movement = Int(cursorAccumulator / sensitivity)
            
            if abs(movement) >= 1 {
                delegate?.moveSelection(by: movement)
                cursorAccumulator -= CGFloat(movement) * sensitivity
            }
            
        case .ended, .cancelled, .failed:
            // Apply any remaining movement with velocity consideration
            if abs(velocity.x) > 200 {
                let momentumMovement = Int(velocity.x / 500)
                if momentumMovement != 0 {
                    delegate?.moveSelection(by: momentumMovement)
                }
            }
            cursorAccumulator = 0
            
        default:
            break
        }
    }
}
