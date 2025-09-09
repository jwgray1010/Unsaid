//
//  SpellCheckerIntegration.swift
//  UnsaidKeyboard
//
//  Service wrapper for spell checking functionality
//

import Foundation
import UIKit

protocol SpellCheckerIntegrationDelegate: AnyObject {
    func didUpdateSpellingSuggestions(_ suggestions: [String])
    func didApplySpellCorrection(_ correction: String, original: String)
}

final class SpellCheckerIntegration {
    weak var delegate: SpellCheckerIntegrationDelegate?
    
    private let spellChecker = LightweightSpellChecker.shared
    private let correctionBoundaries = Set<Character>([" ", "\n", ".", ",", "!", "?", ":", ";"])
    
    init() {}
    
    // MARK: - Public Interface
    
    func refreshSpellCandidates(for text: String) {
        guard let lastWord = LightweightSpellChecker.lastToken(in: text),
              !lastWord.isEmpty,
              shouldCheckSpelling(for: lastWord) else {
            delegate?.didUpdateSpellingSuggestions([])
            return
        }
        
        let suggestions = spellChecker.getSuggestions(for: lastWord)
        delegate?.didUpdateSpellingSuggestions(suggestions)
    }
    
    func applySpellCandidate(_ candidate: String, in proxy: UITextDocumentProxy) {
        guard let before = proxy.documentContextBeforeInput,
              let lastWord = LightweightSpellChecker.lastToken(in: before),
              !lastWord.isEmpty else { return }
        
        // Replace the last word
        for _ in 0..<lastWord.count {
            proxy.deleteBackward()
        }
        proxy.insertText(candidate)
        
        delegate?.didApplySpellCorrection(candidate, original: lastWord)
    }
    
    func autocorrectLastWordIfNeeded(afterTyping boundary: Character, in proxy: UITextDocumentProxy) {
        // Only run on commit boundaries; never during mid-word typing
        guard correctionBoundaries.contains(boundary) else { return }
        
        // Look only at text before cursor
        let before = proxy.documentContextBeforeInput ?? ""
        guard !before.isEmpty else { return }
        
        // We just typed the boundary; work on the token before it
        // Remove the just-typed boundary so we can fetch the last token cleanly
        let core = String(before.dropLast())
        
        // Grab last token
        guard let lastWord = LightweightSpellChecker.lastToken(in: core),
              !lastWord.isEmpty else { return }
        
        // Skip handles you don't want to autocorrect (URLs, @mentions, #tags, hex codes)
        guard shouldAutoCorrect(lastWord) else { return }
        
        // Respect your checker's heuristics
        guard spellChecker.shouldAutoCorrect(lastWord) else { return }
        guard let correction = spellChecker.getAutoCorrection(for: lastWord),
              correction != lastWord else { return }
        
        // Replace the last word, then reinsert the boundary
        proxy.deleteBackward()                  // remove boundary
        for _ in 0..<lastWord.count { proxy.deleteBackward() }
        proxy.insertText(correction)
        proxy.insertText(String(boundary))
        
        // Track for undo / intentional typing
        spellChecker.applyInlineCorrection(correction, originalWord: lastWord)
        spellChecker.recordAutocorrection(lastWord)
        
        // Record with UndoManagerLite for backspace undo
        UndoManagerLite.shared.record(original: lastWord, corrected: correction)
        
        delegate?.didApplySpellCorrection(correction, original: lastWord)
    }
    
    func undoLastCorrection(in proxy: UITextDocumentProxy) -> Bool {
        return UndoManagerLite.shared.tryUndo(in: proxy)
    }
    
    // MARK: - Private Helpers
    
    private func shouldCheckSpelling(for word: String) -> Bool {
        let lowercased = word.lowercased()
        
        // Skip URLs, mentions, hashtags, etc.
        if lowercased.hasPrefix("@") || lowercased.hasPrefix("#") || lowercased.contains("http") {
            return false
        }
        if lowercased.contains("/") || lowercased.contains("_") {
            return false // often IDs/paths
        }
        
        return true
    }
    
    private func shouldAutoCorrect(_ word: String) -> Bool {
        let lowercased = word.lowercased()
        
        // Skip handles you don't want to autocorrect
        if lowercased.hasPrefix("@") || lowercased.hasPrefix("#") || lowercased.contains("http") {
            return false
        }
        if lowercased.contains("/") || lowercased.contains("_") {
            return false // often IDs/paths
        }
        
        return true
    }
}

// MARK: - UndoManagerLite for autocorrect undo
final class UndoManagerLite {
    static let shared = UndoManagerLite()
    private var last: (original: String, corrected: String, chars: Int)?
    
    private init() {}
    
    func record(original: String, corrected: String) {
        last = (original, corrected, corrected.count)
    }
    
    func tryUndo(in proxy: UITextDocumentProxy) -> Bool {
        guard let l = last else { return false }
        for _ in 0..<l.chars { proxy.deleteBackward() }
        proxy.insertText(l.original)
        last = nil
        return true
    }
}
