import UIKit

class SpellCheckerManager {
    static func autocorrectLastWord(using proxy: UITextDocumentProxy, language: String = "en_US") {
        guard let context = proxy.documentContextBeforeInput else { return }
        let words = context.components(separatedBy: .whitespacesAndNewlines)
        guard let lastWord = words.last, !lastWord.isEmpty else { return }

        let checker = UITextChecker()
        let range = NSRange(location: 0, length: lastWord.utf16.count)

        let misspelledRange = checker.rangeOfMisspelledWord(
            in: lastWord,
            range: range,
            startingAt: 0,
            wrap: false,
            language: language
        )

        if misspelledRange.location != NSNotFound,
           let guesses = checker.guesses(forWordRange: misspelledRange, in: lastWord, language: language),
           let firstSuggestion = guesses.first {

            for _ in 0..<lastWord.count {
                proxy.deleteBackward()
            }

            proxy.insertText(firstSuggestion + " ")
        } else {
            proxy.insertText(" ")
        }
    }

    static func getSpellingSuggestions(for text: String, language: String = "en_US") -> [String] {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        guard let lastWord = words.last, !lastWord.isEmpty else { return [] }

        let checker = UITextChecker()
        let range = NSRange(location: 0, length: lastWord.utf16.count)

        let misspelledRange = checker.rangeOfMisspelledWord(
            in: lastWord,
            range: range,
            startingAt: 0,
            wrap: false,
            language: language
        )

        if misspelledRange.location != NSNotFound,
           let guesses = checker.guesses(forWordRange: misspelledRange, in: lastWord, language: language) {
            return Array(guesses.prefix(3)) // Return top 3 suggestions
        }

        return []
    }

    static func isWordMisspelled(_ word: String, language: String = "en_US") -> Bool {
        guard !word.isEmpty else { return false }

        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)

        let misspelledRange = checker.rangeOfMisspelledWord(
            in: word,
            range: range,
            startingAt: 0,
            wrap: false,
            language: language
        )

        return misspelledRange.location != NSNotFound
    }
}
