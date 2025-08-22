import Foundation
import NaturalLanguage
import QuartzCore
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Personal Dictionary
final class UserLexicon {
    static let shared = UserLexicon()
    private let keyLearn = "lex_learned"
    private let keyIgnore = "lex_ignored"
    private let ud = UserDefaults(suiteName: "group.com.unsaid.shared")!

    private(set) var learned: Set<String> = []
    private(set) var ignored: Set<String> = []

    private init() {
        learned = Set(ud.stringArray(forKey: keyLearn) ?? [])
        ignored = Set(ud.stringArray(forKey: keyIgnore) ?? [])
    }
    
    func learn(_ w: String) { 
        learned.insert(w.lowercased())
        ud.set(Array(learned), forKey: keyLearn) 
    }
    
    func ignore(_ w: String) { 
        ignored.insert(w.lowercased())
        ud.set(Array(ignored), forKey: keyIgnore) 
    }
    
    func isUserKnown(_ w: String) -> Bool { 
        learned.contains(w.lowercased()) || ignored.contains(w.lowercased()) 
    }
    
    func removeFromLearned(_ w: String) {
        learned.remove(w.lowercased())
        ud.set(Array(learned), forKey: keyLearn)
    }
    
    func removeFromIgnored(_ w: String) {
        ignored.remove(w.lowercased())
        ud.set(Array(ignored), forKey: keyIgnore)
    }
    
    func getLearnedWords() -> [String] { Array(learned).sorted() }
    func getIgnoredWords() -> [String] { Array(ignored).sorted() }
}

// MARK: - Context-Aware Bigram Scorer
final class BigramScorer {
    private let freq: [String: Int]
    
    // Static default bigram table for performance
    private static let defaultTable: [String: Int] = [
        "the the": 1, "to be": 50, "of the": 45, "in the": 40, "and the": 35,
        "a lot": 30, "you are": 25, "it is": 25, "that is": 20, "this is": 20,
        "would have": 15, "could have": 15, "should have": 15, "going to": 15,
        "want to": 12, "have to": 12, "used to": 10, "how to": 10,
        "there are": 8, "there is": 8, "they are": 8, "we are": 8,
        "won't be": 5, "can't be": 5, "don't have": 5, "doesn't have": 5
    ]
    
    init(freq: [String: Int] = [:]) { 
        self.freq = freq.isEmpty ? Self.defaultTable : freq
    }
    
    func score(prev: String?, cand: String, next: String?) -> Int {
        var s = 0
        if let p = prev { s += freq["\(p.lowercased()) \(cand.lowercased())"] ?? 0 }
        if let n = next { s += freq["\(cand.lowercased()) \(n.lowercased())"] ?? 0 }
        return s
    }
}

// MARK: - Spell Work Queue (Non-blocking)
final class SpellWorkQueue {
    static let shared = SpellWorkQueue()
    private let queue = DispatchQueue(label: "spell.queue", qos: .userInitiated)
    private var pendingToken: UUID?
    
    private init() {}
    
    func coalesced<T>(_ work: @escaping () -> T, deliver: @escaping (T) -> Void) {
        let token = UUID()
        pendingToken = token
        queue.async { [weak self] in
            let result = work()
            DispatchQueue.main.async {
                guard self?.pendingToken == token else { return }
                deliver(result)
            }
        }
    }
}

// MARK: - String Extensions
extension String {
    var normalizedForSpell: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: "\u{2019}", with: "'")  // curly → straight
            .replacingOccurrences(of: "\u{201C}", with: "\"") // smart quotes
            .replacingOccurrences(of: "\u{201D}", with: "\"")
            // Strip soft-hyphen & zero-width chars that can lead to weird splits
            .replacingOccurrences(of: "\u{00AD}", with: "")   // soft hyphen
            .replacingOccurrences(of: "\u{200B}", with: "")   // zero-width space
            .replacingOccurrences(of: "\u{200C}", with: "")   // zero-width non-joiner
            .replacingOccurrences(of: "\u{200D}", with: "")   // zero-width joiner
    }
    
    var isEmojiOrSymbol: Bool {
        // IMPROVED: Use Unicode scalar properties for accurate emoji detection
        for scalar in unicodeScalars {
            let properties = scalar.properties
            if properties.isEmojiPresentation || properties.isEmoji {
                return true
            }
        }
        // Check for symbols/punctuation without letters
        let symbolChars = CharacterSet.symbols.union(.punctuationCharacters)
        return rangeOfCharacter(from: symbolChars) != nil &&
               rangeOfCharacter(from: .letters) == nil
    }
    
    // OPTIMIZED: Reuse expensive NSDataDetector
    private static let linkDetector: NSDataDetector? = {
        try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    }()
    
    var isURL: Bool {
        guard let detector = Self.linkDetector else { return false }
        let ns = self as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let match = detector.matches(in: self, options: [], range: range).first else { return false }
        // URL only if the *entire* token is a link
        return match.range.location == 0 && match.range.length == ns.length
    }
    
    var isMentionOrHashtag: Bool { hasPrefix("@") || hasPrefix("#") }
}

/// Enhanced spell checker for keyboard extension with advanced features
/// Features: Personal Dictionary, Context-Aware Ranking, Smart Tokenization, Multi-word Autocorrect
final class LightweightSpellChecker {

    // MARK: - Singleton
    static let shared = LightweightSpellChecker()
    
    // MARK: - Precompiled Regexes for Performance
    private static let sentenceEndRegex = try! NSRegularExpression(pattern: "([.!?])\\s+([a-z])", options: [])
    private static let punctuationSpaceRegex = try! NSRegularExpression(pattern: "\\s+([.,!?;:])", options: [])
    private static let doubleSpaceRegex = try! NSRegularExpression(pattern: "\\s{2,}", options: [])
    
    // MARK: - Core Components
    #if canImport(UIKit)
    private let textChecker = UITextChecker()
    #endif
    private let userLex = UserLexicon.shared
    private let bgScorer = BigramScorer()
    private let workQueue = SpellWorkQueue.shared
    private let languageRecognizer = NLLanguageRecognizer()
    
    // MARK: - State Management
    private var domainMode: DomainMode = .general
    private var languageCache: [String: String] = [:]
    private var lastUndoableCorrection: (original: String, replacement: String, range: NSRange)?

    // PERSISTENCE: Acceptance learning (misspelling -> correction)
    private let acceptanceCountsKey = "spell_acceptance_counts"
    private var acceptanceCounts: [String: Int] = [:]
    private let acceptanceBoostThreshold = 3
    
    // CACHING: Allow-list optimization
    private var cachedAllowList: Set<String> = []
    private var allowCacheTimestamp: TimeInterval = 0
    
    // BEHAVIORAL: Terminal period insertion (off by default for iOS-style behavior)
    var autoInsertTerminalPeriod = false
    
    enum DomainMode {
        case general, email, url, numeric
        var shouldSkipSpellCheck: Bool {
            switch self {
            case .email, .url, .numeric: return true
            case .general: return false
            }
        }
    }
    
    struct SpellSuggestion {
        let word: String
        let confidence: Double
        let isFromUserDict: Bool
        let editDistance: Int
        let contextScore: Int
        
        var totalScore: Double {
            let baseScore = confidence * 100
            let distancePenalty = Double(editDistance) * -10
            let contextBonus = Double(contextScore) * 5
            let userBonus = isFromUserDict ? 50 : 0
            return baseScore + distancePenalty + contextBonus + Double(userBonus)
        }
    }
    
    private init() {
        // PERSISTENCE: Load acceptance learning data
        if let ud = UserDefaults(suiteName: "group.com.unsaid.shared"),
           let saved = ud.dictionary(forKey: acceptanceCountsKey) as? [String: Int] {
            acceptanceCounts = saved
        }
    }

    // MARK: - Language prefs
    private var preferredLanguage: String = "en_US"
    
    private func resolvedLanguage(_ override: String? = nil) -> String {
        #if canImport(UIKit)
        let langs = UITextChecker.availableLanguages
        let candidate = (override ?? preferredLanguage)
        if langs.contains(candidate) { return candidate }
        let prefix2 = String(candidate.prefix(2))
        if let match = langs.first(where: { $0.hasPrefix(prefix2) }) { return match }
        if let en = langs.first(where: { $0.hasPrefix("en") }) { return en }
        return langs.first ?? "en_US"
        #else
        return override ?? preferredLanguage
        #endif
    }

    func setPreferredLanguage(_ bcp47: String?) {
        guard let b = bcp47, !b.isEmpty else { return }
        let normalized = b.replacingOccurrences(of: "-", with: "_")
        #if canImport(UIKit)
        let langs = UITextChecker.availableLanguages
        if langs.contains(normalized) { preferredLanguage = normalized; return }
        let prefix2 = String(normalized.prefix(2))
        if let match = langs.first(where: { $0.hasPrefix(prefix2) }) { preferredLanguage = match; return }
        #endif
        preferredLanguage = normalized
    }
    
    // CONTEXT-AWARE: Set document language from textDocumentProxy
    func setDocumentPrimaryLanguage(_ bcp47: String?) {
        setPreferredLanguage(bcp47)
    }
    
    // MARK: - Allow-list for common colloquial words (CACHED)
    private func allowedWords() -> Set<String> {
        guard let ud = UserDefaults(suiteName: "group.com.unsaid.shared") else {
            return Set(seedColloquials)
        }
        
        let currentTimestamp = ud.double(forKey: "profanity_allowlist_ts")
        if currentTimestamp == allowCacheTimestamp && !cachedAllowList.isEmpty {
            return cachedAllowList
        }
        
        let defaults = (ud.array(forKey: "profanity_allowlist") as? [String]) ?? []
        cachedAllowList = Set(defaults.map{ $0.lowercased() } + seedColloquials)
        allowCacheTimestamp = currentTimestamp
        return cachedAllowList
    }
    
    private let seedColloquials = [
        "crap","shit","damn","hell","fuck","suck","wtf","lol","omg","nah","ok","okay","yo",
        "tbh", "imo", "fyi", "brb", "ttyl", "smh", "rn", "af", "ik", "ngl", "fr", "bet",
        "lowkey", "highkey", "bestie", "vibes", "sus", "periodt", "slay", "stan",
        "thicc", "yeet", "fam", "bae", "lit", "woke", "simp", "flex", "clout", "vibe"
    ]

    // MARK: - Autocorrect safety rails
    private let riskyCorrections: Set<String> = [
        // common bad flips we want to avoid
        "suck", // avoid suck -> sunk
        "duck", // avoid duck -> deck
        "hell", // avoid hell -> hello
        "damn", // avoid damn -> damp
        "shit", // avoid shit -> shift
        "fuck", // avoid profanity corrections
        "crap",  // avoid crap -> carp
        "bitch",
        "tit",
        "cunt",
        "dick",
        "fucking"
    ]
    
    // KEYBOARD-ADJACENCY: Common tap-slip patterns for smarter autocorrect
    private let qwertyNeighbors: [Character: Set<Character>] = [
        "q": ["w", "a"], "w": ["q", "e", "a", "s"], "e": ["w", "r", "s", "d"],
        "r": ["e", "t", "d", "f"], "t": ["r", "y", "f", "g"], "y": ["t", "u", "g", "h"],
        "u": ["y", "i", "h", "j"], "i": ["u", "o", "j", "k"], "o": ["i", "p", "k", "l"],
        "p": ["o", "l"], "a": ["q", "w", "s", "z"], "s": ["a", "w", "e", "d", "z", "x"],
        "d": ["s", "e", "r", "f", "x", "c"], "f": ["d", "r", "t", "g", "c", "v"],
        "g": ["f", "t", "y", "h", "v", "b"], "h": ["g", "y", "u", "j", "b", "n"],
        "j": ["h", "u", "i", "k", "n", "m"], "k": ["j", "i", "o", "l", "m"],
        "l": ["k", "o", "p"], "z": ["a", "s", "x"], "x": ["z", "s", "d", "c"],
        "c": ["x", "d", "f", "v"], "v": ["c", "f", "g", "b"], "b": ["v", "g", "h", "n"],
        "n": ["b", "h", "j", "m"], "m": ["n", "j", "k"]
    ]

    /// Keyboard-adjacent fast fixes (before UITextChecker), kept ultra safe (edit distance 1)
    private let fastTypos: [String: String] = [
        // “the” cluster
        "hte": "the", "teh": "the", "thw": "the", "thr": "the", "tge": "the", "tye": "the", "tghe": "the", "thhe": "the",
        // "you" cluster
        "yuo": "you", "yoi": "you", "tou": "you", "youu": "you", "yoh": "you", "yok": "you", "yoou": "you", "oyu": "you",
        // "this" cluster
        "tjis": "this", "tjhis": "this", "ths": "this", "thsi": "this", "tihs": "this", "thix": "this",
        // "what" cluster
        "waht": "what", "hwta": "what", "wha": "what", "whst": "what", "whar": "what", "wjat": "what",
        // "that" cluster
        "taht": "that", "thta": "that", "thqt": "that", "thay": "that", "thwt": "that",
        // "and" cluster
        "adn": "and", "annd": "and", "amd": "and", "anb": "and",
        // "are" cluster
        "aer": "are", "arr": "are", "rae": "are", "aree": "are",
        // "was" cluster
        "wsa": "was", "awsa": "was", "ws": "was", "waz": "was",
        // "with" cluster
        "wiht": "with", "witj": "with", "woth": "with", "wih": "with", "wifh": "with",
        // "your" cluster
        "yuor": "your", "yur": "your", "yoru": "your", "youe": "your", "yout": "your",
        // "from" cluster
        "form": "from", "fron": "from", "fro": "from", "fom": "from",
        // "have" cluster
        "ahve": "have", "haev": "have", "hvae": "have", "hae": "have",
        // "just" cluster
        "jsut": "just", "jsu": "just", "jist": "just", "juts": "just",
        // "like" cluster
        "liek": "like", "likr": "like", "ljke": "like", "liekd": "liked",
        // "because" cluster
        "becuase": "because", "bcause": "because", "beacause": "because", "becasue": "because",
        // "people" cluster
        "peopel": "people", "poeple": "people", "peple": "people",
        // "would" cluster
        "woudl": "would", "wolud": "would", "wouls": "would",
        // "could" cluster
        "coudl": "could", "colud": "could", "couls": "could",
        // "should" cluster
        "shoudl": "should", "sholud": "should", "shoud": "should",
        // "about" cluster
        "abuot": "about", "abot": "about", "abotu": "about",
        // "know" cluster
        "knwo": "know", "konw": "know", "kbow": "know", "nkow": "know",
        // "going" cluster
        "gonig": "going", "giong": "going", "goin": "going",
        // "really" cluster
        "relaly": "really", "realy": "really", "rellay": "really",
        // "probably" cluster
        "probaly": "probably", "probbaly": "probably", "propably": "probably",
    ]

    private func isWordBoundary(_ c: Character) -> Bool {
        return c == " " || c == "\n" || c == "." || c == "!" || c == "?"
    }

    /// Gatekeeper to prevent sketchy autocorrections
    private func shouldApplyCorrection(original: String, suggestion: String) -> Bool {
        let o = original.trimmingCharacters(in: .whitespacesAndNewlines)
        let s = suggestion.trimmingCharacters(in: .whitespacesAndNewlines)

        // No hyphens, no spaces added/removed (avoid per-son, or splitting/merging)
        if s.contains("-") { return false }
        if o.contains(" ") || s.contains(" ") { return false }

        // Be very conservative: only allow single character errors for autocorrect
        let editDist = editDistance(o.lowercased(), s.lowercased())
        if editDist != 1 { return false } // Changed from > 1 to != 1 for extra caution
        
        // KEYBOARD-ADJACENCY: Allow if it's a likely tap slip (boost confidence)
        if isLikelyTapSlip(o, s) { return true }

        // Don't change the word if the vowel/consonant pattern completely shifts (often wrong)
        // Allow phonetic shift if it's still a single edit (e.g., tge→the)
        if drasticallyChangesPhonetics(o, s) && editDistance(o, s) > 1 { return false }

        // Extra safety: don't correct words that are already plausible
        // Check if original might be an abbreviation, name, or technical term
        if o.count >= 4 && o.uppercased() == o { return false } // Likely acronym
        if o.count >= 3 && o.first?.isUppercase == true && !s.first!.isUppercase { return false } // Proper noun protection

        return true
    }
    
    // KEYBOARD-ADJACENCY: Check if correction is likely a tap slip
    private func isLikelyTapSlip(_ a: String, _ b: String) -> Bool {
        guard a.count == b.count, a.count >= 1 else { return false }
        let aChars = Array(a.lowercased())
        let bChars = Array(b.lowercased())
        var diffs: [(Character, Character)] = []
        
        for i in 0..<aChars.count where aChars[i] != bChars[i] {
            diffs.append((aChars[i], bChars[i]))
        }
        
        guard diffs.count == 1 else { return false }
        let (from, to) = diffs[0]
        return qwertyNeighbors[from]?.contains(to) == true
    }

    /// Simple Levenshtein distance (fast enough for short words)
    private func editDistance(_ a: String, _ b: String) -> Int {
        if a == b { return 0 }
        let aChars = Array(a), bChars = Array(b)
        var dp = Array(repeating: Array(repeating: 0, count: bChars.count + 1), count: aChars.count + 1)
        for i in 0...aChars.count { dp[i][0] = i }
        for j in 0...bChars.count { dp[0][j] = j }
        for i in 1...aChars.count {
            for j in 1...bChars.count {
                if aChars[i-1] == bChars[j-1] {
                    dp[i][j] = dp[i-1][j-1]
                } else {
                    dp[i][j] = min(dp[i-1][j], dp[i][j-1], dp[i-1][j-1]) + 1
                }
            }
        }
        return dp[aChars.count][bChars.count]
    }

    private func drasticallyChangesPhonetics(_ a: String, _ b: String) -> Bool {
        func skeleton(_ s: String) -> String {
            let vowels = Set("aeiou")
            return s.lowercased().filter { ("a"..."z").contains($0) }.map { vowels.contains($0) ? "v" : "c" }.joined()
        }
        // If the v/c pattern diverges a lot, it's probably a bad correction
        return editDistance(skeleton(a), skeleton(b)) > 1
    }

    /// Preserve the original token's casing on the suggestion (e.g., Yoi→You, Tge→The)
    private func matchCasing(of original: String, to suggestion: String) -> String {
        // ALL CAPS → ALL CAPS
        if original == original.uppercased() {
            return suggestion.uppercased()
        }
        // Title-case first letter only
        if original.prefix(1) == original.prefix(1).uppercased(),
           original.dropFirst() == original.dropFirst().lowercased() {
            return suggestion.prefix(1).uppercased() + suggestion.dropFirst().lowercased()
        }
        return suggestion
    }
    
    /// Filter UITextChecker suggestions to prevent risky and hyphenated autocorrects
    private func isSafeSuggestion(original: String, suggestion: String) -> Bool {
        let o = original.lowercased()
        let s = suggestion.lowercased()

        // never split / hyphenate
        if s.contains("-") { return false }

        // profanity & frequently-wrong flips
        if riskyCorrections.contains(o) || riskyCorrections.contains(s) { return false }

        // must pass your correctness gate
        if !shouldApplyCorrection(original: o, suggestion: s) { return false }

        return true
    }
    
    // MARK: - Capitalization / punctuation configs
    private let sentenceEnders: CharacterSet = CharacterSet(charactersIn: ".!?")
    private let commonAbbreviations = Set(["dr","mr","mrs","ms","prof","inc","ltd","corp","etc","vs","st","ave","blvd","dept","govt","assn"])
    private let alwaysCapitalize = Set(["i","i'm","i'll","i've","i'd"]) // common "I" forms

    // MARK: - Inline correction state
    private var lastCorrectedWord: String?
    private var lastOriginalWord: String?
    
    // MARK: - Intentional typing tracking
    private struct IntentionalEntry { var count: Int; var lastSeen: CFTimeInterval }
    private var intentionalWords: [String: IntentionalEntry] = [:]
    private let intentionalTTL: CFTimeInterval = 10 * 60 // 10 minutes

    // MARK: - Core spell work

    private func localCorrections(for word: String, language: String? = nil) -> [String] {
        #if canImport(UIKit)
        guard !word.isEmpty else { return [] }
        
        // Honor allow-list for common colloquial words
        if allowedWords().contains(word.lowercased()) { return [] }
        
        // FAST PATH: keyboard-adjacent typos (single-word, no hyphens)
        let lower = word.lowercased()
        if let fast = fastTypos[lower] {
            let cased = matchCasing(of: word, to: fast)
            if isSafeSuggestion(original: word, suggestion: cased) {
                return [cased]
            }
        }
        
        let lang = resolvedLanguage(language)
        let nsWord = word as NSString
        let range = NSRange(location: 0, length: nsWord.length)

        let miss = textChecker.rangeOfMisspelledWord(
            in: word, range: range, startingAt: 0, wrap: false, language: lang
        )
        guard miss.location != NSNotFound else { return [] } // already correct

        let guesses = textChecker.guesses(forWordRange: miss, in: word, language: lang) ?? []
        // map suggestions to match original casing, then filter for safety
        let filtered = guesses
            .map { matchCasing(of: word, to: $0) }
            .filter { isSafeSuggestion(original: word, suggestion: $0) }
        return Array(filtered.prefix(3))
        #else
        return []
        #endif
    }

    func isWordCorrect(_ word: String, language: String? = nil) -> Bool {
        #if canImport(UIKit)
        guard !word.isEmpty else { return true }
        // Honor allow-list for common colloquial words
        if allowedWords().contains(word.lowercased()) { return true }
        
        let lang = resolvedLanguage(language)
        let nsWord = word as NSString
        let range = NSRange(location: 0, length: nsWord.length)
        let miss = textChecker.rangeOfMisspelledWord(
            in: word, range: range, startingAt: 0, wrap: false, language: lang
        )
        return miss.location == NSNotFound
        #else
        return true
        #endif
    }

    /// Async last-token check with coalescing
    func quickSpellCheckAsync(text: String, completion: @escaping ([String]) -> Void) {
        guard text.count >= 2, text.count <= 2000 else { completion([]); return }
        workQueue.coalesced({
            let last = self.lastWord(in: text)
            guard let currentWord = last,
                  currentWord.count >= 2, currentWord.count <= 24,
                  currentWord.rangeOfCharacter(from: .letters) != nil else { return [] }
            return self.localCorrections(for: currentWord)
        }, deliver: completion)
    }

    func getAutoCorrection(for word: String) -> String? {
        guard word.count >= 2, word.count <= 24 else { return nil }
        return localCorrections(for: word).first
    }

    // PATCH #1: Allow short, ultra-common fixes like "Yoi" → "You"
    func shouldAutoCorrect(_ word: String) -> Bool {
        guard word.count >= 3 else { return false } // lowered from 4 → 3
        // Honor allow-list for common colloquial words
        if allowedWords().contains(word.lowercased()) { return false }
        // Only block if explicitly marked intentional (via undo/ignore), not after accept
        if isIntentionallyTyped(word) { return false }
        guard !isWordCorrect(word) else { return false }
        
        // Be very conservative - only autocorrect extremely obvious typos
        let corrections = localCorrections(for: word)
        guard !corrections.isEmpty else { return false }
        
        if let first = corrections.first {
            // PATCH #3: acceptance-learning fast path
            let key = "\(word.lowercased())->\(first.lowercased())"
            if acceptanceCounts[key, default: 0] >= acceptanceBoostThreshold {
                return true // user has accepted this enough times—go for it
            }
            let editDist = editDistance(word.lowercased(), first.lowercased())
            let isCommonTypo = fastTypos[word.lowercased()] != nil
            return editDist == 1 && isCommonTypo
        }
        return false
    }

    func requestSuggestions(for text: String, range: NSRange, completion: @escaping ([String]?) -> Void) {
        guard range.length >= 2, range.length <= 24 else { completion(nil); return }
        let ns = text as NSString
        guard range.location + range.length <= ns.length else { completion(nil); return }
        let sub = ns.substring(with: range)
        let suggestions = localCorrections(for: sub)
        completion(suggestions.isEmpty ? nil : suggestions)
    }

    func quickSpellCheck(text: String) -> [String] { [] }

    // MARK: - Inline correction state
    func applyInlineCorrection(_ suggestion: String, originalWord: String) {
        lastCorrectedWord = suggestion
        lastOriginalWord = originalWord
    }
    func canUndoLastCorrection() -> Bool { lastCorrectedWord != nil && lastOriginalWord != nil }
    func getUndoCorrection() -> (original: String, corrected: String)? {
        guard let corrected = lastCorrectedWord, let original = lastOriginalWord else { return nil }
        return (original, corrected)
    }
    func clearUndoState() { lastCorrectedWord = nil; lastOriginalWord = nil }
    
    // MARK: - Intentional typing helpers (PATCH #2)

    /// Only words that the user explicitly rejected/undid are treated as "intentional".
    private func isIntentionallyTyped(_ word: String) -> Bool {
        let key = word.lowercased()
        guard let e = intentionalWords[key] else { return false }
        if CACurrentMediaTime() - e.lastSeen > intentionalTTL {
            intentionalWords.removeValue(forKey: key)
            return false
        }
        return e.count >= 1 // set only by markIntentional()
    }
    
    /// Accepting a correction should NOT mark the misspelling as intentional — make this a no-op.
    private func markAutocorrected(_ word: String) {
        // Intentionally left blank (no-op)
    }
    
    private func markIntentional(_ word: String) {
        // used when user explicitly rejects/undos
        intentionalWords[word.lowercased()] = IntentionalEntry(count: 1, lastSeen: CACurrentMediaTime())
    }

    // MARK: - Capitalization & punctuation (local heuristics)

    /// Keep misspelling to match your controller: both names exist
    func applyCaptializationRules(to text: String) -> String { applyCapitalizationRules(to: text) }

    private func applyCapitalizationRules(to text: String) -> String {
        guard !text.isEmpty else { return text }
        var result = text

        // 1) Capitalize first character
        result = capitalizeFirstLetter(result)

        // 2) Capitalize after sentence endings (avoid common abbrevs)
        result = capitalizeAfterSentenceEndings(result)

        // 3) Proper nouns (very lightweight)
        result = capitalizeCommonProperNouns(result)

        // 4) Capitalize “I” and common contractions
        for phrase in alwaysCapitalize {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: phrase))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: (result as NSString).length)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: phrase.capitalized)
            }
        }

        // 5) Start-of-text “i ”/“i'”
        if result.hasPrefix("i ") || result.hasPrefix("i'") {
            result = "I" + result.dropFirst()
        }

        return result
    }

    func applyPunctuationRules(to text: String) -> String {
        guard !text.isEmpty else { return text }
        var result = text
        result = addSpaceAfterPunctuation(result)
        result = removeSpaceBeforePunctuation(result)
        result = fixCommonContractions(result)
        result = addPeriodIfNeeded(result)
        result = fixCommonGrammarMistakes(result)
        result = condenseSpaces(result)
        return result
    }

    func getCapitalizationAndPunctuationSuggestions(for text: String) -> [String] {
        guard text.count > 5 else { return [] }
        var suggestions: [String] = []
        let cap = applyCaptializationRules(to: text)
        if cap != text { suggestions.append(cap) }
        let punct = applyPunctuationRules(to: text)
        if punct != text { suggestions.append(punct) }
        let both = applyPunctuationRules(to: cap)
        if both != text && both != cap && both != punct { suggestions.append(both) }
        return Array(suggestions.prefix(3))
    }

    func getRealTimeGrammarSuggestions(for text: String, cursorPosition: Int = -1) -> [String] {
        guard !text.isEmpty else { return [] }
        let pos = cursorPosition >= 0 ? cursorPosition : text.count
        let working = String(text.prefix(pos))

        var out: [String] = []

        // Last two words quick grammar pass
        let words = working.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if words.count >= 2 {
            let lastTwo = words.suffix(2).joined(separator: " ")
            let fixed = fixCommonGrammarMistakes(lastTwo)
            if fixed != lastTwo { out.append(fixed) }
        }

        // Capitalize next word after sentence ender
        if let last = working.unicodeScalars.last, sentenceEnders.contains(last) {
            out.append("Capitalize next word")
        }

        // Common contractions
        if let lastWord = words.last?.lowercased() {
            switch lastWord {
            case "wont": out.append("won't")
            case "cant": out.append("can't")
            case "dont": out.append("don't")
            case "im": out.append("I'm")
            case "youre": out.append("you're")
            case "theyre": out.append("they're")
            case "ive": out.append("I've")
            case "id": out.append("I'd")
            case "youve": out.append("you've")
            case "youd": out.append("you'd")
            case "youdve": out.append("you'd've")
            case "weve": out.append("we've")
            case "wed": out.append("we'd")
            case "were": out.append("we're")
            case "theyve": out.append("they've")
            case "theyd": out.append("they'd")
            case "theres": out.append("there's")
            case "thered": out.append("there'd")
            case "thatll": out.append("that'll")
            case "thats": out.append("that's")
            case "whos": out.append("who's")
            case "whod": out.append("who'd")
            case "wholl": out.append("who'll")
            case "whove": out.append("who've")
            case "whats": out.append("what's")
            case "whatre": out.append("what're")
            case "whatll": out.append("what'll")
            case "where's": out.append("where's")
            case "whereve": out.append("where've")
            case "how's": out.append("how's")
            case "howve": out.append("how've")
            case "isnt": out.append("isn't")
            case "arent": out.append("aren't")
            case "wasnt": out.append("wasn't")
            case "werent": out.append("weren't")
            case "hasnt": out.append("hasn't")
            case "havent": out.append("haven't")
            case "hadnt": out.append("hadn't")
            case "shouldnt": out.append("shouldn't")
            case "wouldnt": out.append("wouldn't")
            case "couldnt": out.append("couldn't")
            case "mustnt": out.append("mustn't")
            case "mightnt": out.append("mightn't")
            case "daren't": out.append("daren't")
            default: break
            }
        }

        return Array(out.prefix(2))
    }

    // MARK: - Capitalization helpers
    private func capitalizeFirstLetter(_ text: String) -> String {
        guard let first = text.first else { return text }
        return String(first).uppercased() + text.dropFirst()
    }

    /// Safer UTF-16 index handling: replace capture group 2 (the letter) in reverse order
    private func capitalizeAfterSentenceEndings(_ text: String) -> String {
        var result = text
        let ns = result as NSString
        let fullRange = NSRange(location: 0, length: ns.length)
        let matches = Self.sentenceEndRegex.matches(in: result, options: [], range: fullRange)

        // Apply from the end to keep ranges valid as we mutate
        for match in matches.reversed() {
            // Check abbreviation before the ender (group 1)
            let enderRange = match.range(at: 1)
            if let swiftEnder = Range(enderRange, in: result) {
                let beforePeriod = String(result[..<swiftEnder.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                if let lastWord = beforePeriod.components(separatedBy: .whitespacesAndNewlines).last?.lowercased(),
                   commonAbbreviations.contains(lastWord) {
                    continue
                }
            }

            let letterRange = match.range(at: 2)
            let nsNow = result as NSString
            let letter = nsNow.substring(with: letterRange).uppercased()
            result = nsNow.replacingCharacters(in: letterRange, with: letter)
        }
        return result
    }

    private func capitalizeCommonProperNouns(_ text: String) -> String {
        let weekdays = ["monday","tuesday","wednesday","thursday","friday","saturday","sunday"]
        let months = ["january","february","march","april","may","june","july","august","september","october","november","december"]
        let languages = ["english","spanish","french","german","chinese","japanese","italian","portuguese","russian","arabic"]
        let countries = ["america","american","usa","canada","canadian","mexico","mexican","england","british","france","french","germany","german","china","chinese","japan","japanese"]

        let nouns = weekdays + months + languages + countries

        var result = text
        let ns = result as NSString

        for noun in nouns {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: noun))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: ns.length)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: noun.capitalized)
            }
        }
        return result
    }

    // MARK: - Punctuation helpers
    private func addSpaceAfterPunctuation(_ text: String) -> String {
        var result = text
        for p in [".", ",", "!", "?", ":", ";"] {
            let pattern = "\\\(p)([A-Za-z])"
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(location: 0, length: (result as NSString).length)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "\(p) $1")
            }
        }
        return result
    }

    /// Remove spaces before punctuation (e.g., "word !" -> "word!")
    private func removeSpaceBeforePunctuation(_ text: String) -> String {
        let ns = text as NSString
        let full = NSRange(location: 0, length: ns.length)
        // Replace any whitespace immediately before punctuation with just the punctuation
        return Self.punctuationSpaceRegex.stringByReplacingMatches(in: text, options: [], range: full, withTemplate: "$1")
    }

    private func fixCommonContractions(_ text: String) -> String {
        // SAFER: Skip if token is URL, mention, or ALL-CAPS
        if text.isURL || text.isMentionOrHashtag || text == text.uppercased() {
            return text
        }
        
        // 1) remove unsafe mapping
        let map: [String:String] = [
            "wont":"won't","cant":"can't","dont":"don't","isnt":"isn't","wasnt":"wasn't",
            /* "were":"we're",  ← remove this (ambiguous) */
            "hasnt":"hasn't","havent":"haven't","shouldnt":"shouldn't","couldnt":"couldn't","wouldnt":"wouldn't",
            "thats":"that's","whats":"what's","hes":"he's","shes":"she's","its":"it's",
            "im":"I'm","youre":"you're","theyre":"they're",
            "ill":"I'll","ive":"I've","id":"I'd",
            "lets":"let's","itll":"it'll","weve":"we've"
        ]

        var result = text

        // 2) apply replacements, preserving casing of the match
        for (wrong, correct) in map {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: wrong))\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            // collect matches first (so we can replace from end)
            let matches = regex.matches(in: result, options: [], range: NSRange(location: 0, length: (result as NSString).length))
            guard !matches.isEmpty else { continue }
            for m in matches.reversed() {
                let matched = (result as NSString).substring(with: m.range)
                let cased = preserveCase(template: correct, like: matched)
                result = (result as NSString).replacingCharacters(in: m.range, with: cased)
            }
        }

        // 3) normalize quotes (smart → straight)
        result = result
            .replacingOccurrences(of: "\u{201C}", with: "\"")
            .replacingOccurrences(of: "\u{201D}", with: "\"")
            .replacingOccurrences(of: "''", with: "\"")
            .replacingOccurrences(of: "`", with: "\"")
        return result
    }

    private func addPeriodIfNeeded(_ text: String) -> String {
        guard autoInsertTerminalPeriod else { return text }
        guard text.count > 10 else { return text }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let last = trimmed.last, [".","!","?",";", ":"].contains(String(last)) { return text }
        let words = trimmed.split(whereSeparator: { $0.isWhitespace })
        if words.count >= 3 { return trimmed + "." }
        return text
    }

    private func fixCommonGrammarMistakes(_ text: String) -> String {
        var result = text
        let fixes: [(String,String)] = [
            ("\\btheir\\b(?=\\s+(is|are|was|were))", "there"),
            ("\\bthere\\b(?=\\s+(car|house|phone|computer))", "their"),
            ("\\byour\\b(?=\\s+(welcome|right))", "you're"),
            ("\\byoure\\b", "you're"),
            ("\\bto\\b(?=\\s+(much|many))", "too"),
            ("\\btoo\\b(?=\\s+(go|be|see|do))", "to"),
            ("\\bwould\\s+of\\b", "would have"),
            ("\\bcould\\s+of\\b", "could have"),
            ("\\bshould\\s+of\\b", "should have"),
            ("\\balot\\b", "a lot"),
            ("\\bwanna\\b", "want to"),
            ("\\bgonna\\b", "going to")
        ]
        for (pattern, replacement) in fixes {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: (result as NSString).length)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: replacement)
            }
        }
        return result
    }

    private func condenseSpaces(_ text: String) -> String {
        let ns = text as NSString
        let full = NSRange(location: 0, length: ns.length)
        return Self.doubleSpaceRegex.stringByReplacingMatches(in: text, options: [], range: full, withTemplate: " ")
    }

    // MARK: - Language Detection & Domain Awareness
    func detectLanguage(for text: String) -> String? {
        // Use a window of text for performance (limit to 200 chars)
        let windowedText = String(text.prefix(200))
        if let cached = languageCache[windowedText] { return cached }
        languageRecognizer.reset()
        languageRecognizer.processString(windowedText)
        if let lang = languageRecognizer.dominantLanguage?.rawValue {
            let resolved = lang.replacingOccurrences(of: "-", with: "_")
            languageCache[windowedText] = resolved
            return resolved
        }
        return nil
    }
    
    func setDomainMode(_ mode: DomainMode) { domainMode = mode }
    
    func detectDomainMode(for text: String) -> DomainMode {
        let lower = text.lowercased()
        if lower.contains("@") && lower.contains(".") { return .email }
        if lower.hasPrefix("http") || lower.contains("www.") { return .url }
        if text.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil { return .numeric }
        return .general
    }
    
    // MARK: - Smart Tokenization
    func smartTokenize(_ text: String) -> [(word: String, range: NSRange)] {
        var tokens: [(String, NSRange)] = []
        let nsText = text as NSString
        let tagger = NLTagger(tagSchemes: [.tokenType])
        tagger.string = text
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word,
                             scheme: .tokenType,
                             options: [.omitWhitespace, .omitPunctuation, .joinNames]) { tag, range in
            let nsRange = NSRange(range, in: text)
            let word = nsText.substring(with: nsRange)
            if let tag = tag {
                switch tag {
                case .other, .otherWord:
                    if !word.isEmojiOrSymbol && !word.isURL && !word.isMentionOrHashtag {
                        tokens.append((word, nsRange))
                    }
                case .word:
                    tokens.append((word, nsRange))
                default:
                    break
                }
            } else if word.rangeOfCharacter(from: .letters) != nil {
                tokens.append((word, nsRange))
            }
            return true
        }
        return tokens
    }
    
    // MARK: - Enhanced Spell Checking
    func enhancedSpellCheck(text: String,
                            previousWord: String? = nil,
                            nextWord: String? = nil,
                            completion: @escaping ([SpellSuggestion]) -> Void) {
        workQueue.coalesced({
            self.performEnhancedSpellCheck(text: text, previousWord: previousWord, nextWord: nextWord)
        }, deliver: completion)
    }
    
    private func performEnhancedSpellCheck(text: String,
                                           previousWord: String?,
                                           nextWord: String?) -> [SpellSuggestion] {
        let normalized = text.normalizedForSpell
        let detectedMode = detectDomainMode(for: text)
        if detectedMode.shouldSkipSpellCheck { return [] }
        if userLex.isUserKnown(normalized) { return [] }
        let language = detectLanguage(for: text) ?? preferredLanguage
        #if canImport(UIKit)
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        let misspelledRange = textChecker.rangeOfMisspelledWord(in: text,
                                                                range: range,
                                                                startingAt: 0,
                                                                wrap: false,
                                                                language: language)
        guard misspelledRange.location != NSNotFound else { return [] }
        let suggestions = textChecker.guesses(forWordRange: misspelledRange, in: text, language: language) ?? []
        var enhanced: [SpellSuggestion] = []
        for suggestion in suggestions {
            let editDist = editDistance(text, suggestion)
            let contextScore = bgScorer.score(prev: previousWord, cand: suggestion, next: nextWord)
            let isUserWord = userLex.learned.contains(suggestion.lowercased())
            enhanced.append(SpellSuggestion(word: suggestion,
                                            confidence: 0.8,
                                            isFromUserDict: isUserWord,
                                            editDistance: editDist,
                                            contextScore: contextScore))
        }
        for learnedWord in userLex.learned {
            let editDist = editDistance(text.lowercased(), learnedWord)
            if editDist <= 2 && !suggestions.contains(learnedWord) {
                let contextScore = bgScorer.score(prev: previousWord, cand: learnedWord, next: nextWord)
                enhanced.append(SpellSuggestion(word: learnedWord,
                                                confidence: 0.9,
                                                isFromUserDict: true,
                                                editDistance: editDist,
                                                contextScore: contextScore))
            }
        }
        return enhanced.sorted { $0.totalScore > $1.totalScore }.prefix(5).map { $0 }
        #else
        return []
        #endif
    }
    
    // MARK: - Multi-word Autocorrect
    func checkMultiWordCorrection(_ text: String) -> (original: String, correction: String)? {
        let multiWordPatterns: [String: String] = [
            "alot": "a lot",
            "incase": "in case",
            "infact": "in fact",
            "aswell": "as well",
            "eachother": "each other",
            "thankyou": "thank you",
            "atleast": "at least",
            "cannot": "can not",  // stylistic   
            "everyday": "every day",
        ]
        let normalized = text.normalizedForSpell.lowercased()
        if let correction = multiWordPatterns[normalized] { return (text, correction) }
        return nil
    }
    
    // MARK: - Personal Dictionary Management
    func learnWord(_ word: String) {
        userLex.learn(word)
        #if DEBUG
        print("Learned word: \(word)")
        #endif
    }
    func ignoreWord(_ word: String) {
        userLex.ignore(word)
        #if DEBUG
        print("Ignoring word: \(word)")
        #endif
    }
    func forgetWord(_ word: String) {
        userLex.removeFromLearned(word)
        userLex.removeFromIgnored(word)
        #if DEBUG
        print("Forgot word: \(word)")
        #endif
    }
    func getPersonalDictionary() -> (learned: [String], ignored: [String]) {
        (userLex.getLearnedWords(), userLex.getIgnoredWords())
    }
    func actionsForWord(_ word: String) -> [(title: String, handler: () -> Void)] {
        var items: [(String, () -> Void)] = []
        if !userLex.isUserKnown(word) {
            items.append(("Learn \"\(word)\"", { self.learnWord(word) }))
            items.append(("Ignore \"\(word)\"", { self.ignoreWord(word) }))
        } else {
            items.append(("Forget \"\(word)\"", { self.forgetWord(word) }))
        }
        return items
    }
    
    // MARK: - Undo Functionality
    func recordCorrection(original: String, replacement: String, range: NSRange) {
        lastUndoableCorrection = (original, replacement, range)
    }
    func getLastCorrection() -> (original: String, replacement: String, range: NSRange)? {
        lastUndoableCorrection
    }
    func clearUndoHistory() { lastUndoableCorrection = nil }
    
    // MARK: - Acceptance Learning (PATCH #3 - PERSISTENT)
    func recordAcceptedCorrection(original: String, corrected: String) {
        let key = "\(original.lowercased())->\(corrected.lowercased())"
        acceptanceCounts[key, default: 0] += 1
        
        // PERSISTENCE: Save to UserDefaults
        if let ud = UserDefaults(suiteName: "group.com.unsaid.shared") {
            ud.set(acceptanceCounts, forKey: acceptanceCountsKey)
        }
    }
    
    // MARK: - ONE-SHOT DECISION HELPER
    struct Decision {
        let replacement: String?
        let suggestions: [String]
        let applyAuto: Bool
    }
    
    /// Single entry point for keyboard controller - runs complete pipeline
    func decide(for currentWord: String,
                prev: String? = nil,
                next: String? = nil,
                langOverride: String? = nil) -> Decision {
        
        setDocumentPrimaryLanguage(langOverride)
        
        // Skip if user knows this word or it's in allow-list
        if isWordKnownByUser(currentWord) || allowedWords().contains(currentWord.lowercased()) {
            return Decision(replacement: nil, suggestions: [], applyAuto: false)
        }
        
        // Check multi-word corrections
        if let multi = checkMultiWordCorrection(currentWord) {
            return Decision(replacement: multi.correction, suggestions: [multi.correction], applyAuto: true)
        }
        
        // Check for single-word autocorrect
        if shouldAutoCorrect(currentWord), let auto = getAutoCorrection(for: currentWord) {
            return Decision(replacement: auto, suggestions: [auto], applyAuto: true)
        }
        
        // Get suggestions for manual selection
        let enhanced = performEnhancedSpellCheck(text: currentWord, previousWord: prev, nextWord: next)
        let suggestions = enhanced.map { $0.word }
        
        return Decision(replacement: nil, suggestions: suggestions, applyAuto: false)
    }
    
    // MARK: - Utilities
    private func lastWord(in text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\u{00AD}", with: "")   // soft hyphen
            .replacingOccurrences(of: "\u{200B}", with: "")   // zero-width space
            .replacingOccurrences(of: "\u{200C}", with: "")   // zero-width non-joiner
            .replacingOccurrences(of: "\u{200D}", with: "")   // zero-width joiner
        guard !trimmed.isEmpty else { return nil }
        let parts = trimmed.components(separatedBy: .whitespacesAndNewlines)
        guard let raw = parts.last, !raw.isEmpty else { return nil }
        return raw.trimmingCharacters(in: CharacterSet(charactersIn: ".,!?;:()[]{}\"'"))
    }
    
    // MARK: - Keyboard Helper Methods
    
    #if canImport(UIKit)
    /// Handle punctuation insertion with automatic spacing and keyboard mode switching
    private func handlePunctuation(_ punctuation: String, with textProxy: UITextDocumentProxy) {
        textProxy.insertText(punctuation)
        
        // Optional: add a space after punctuation
        if [".", "!", "?"].contains(punctuation) {
            textProxy.insertText(" ")
        }

        // Force back to alphabetic mode (implementation would be in KeyboardController)
        // switchToAlphabeticKeyboard()
    }
    #endif
    
    /// Switch to alphabetic keyboard mode
    /// Note: This is a helper template - actual implementation should be in KeyboardController
    private func switchToAlphabeticKeyboard() {
        // This method tells the UIInputViewController to switch to letters
        // self.advanceToNextInputMode() // This cycles, so be careful — better is below if you track layouts
        // If you have a custom keyboard layout manager:
        // keyboardLayout = .alphabetic
        // renderKeyboardLayout()
    }
    
    // MARK: - Status / lifecycle
    func getAPIStatus() -> [String: Any] {
        return [
            "spell_checker": "UITextChecker_only",
            "local_checker_available": canUseLocalChecker(),
            "preferred_language": preferredLanguage,
            "resolved_language": preferredLanguage,
            "can_undo_correction": canUndoLastCorrection(),
            "features": [
                "spelling","capitalization","punctuation","contractions",
                "smart_quotes","proper_nouns","grammar_fixes","abbreviation_awareness",
                "real_time_suggestions"
            ]
        ]
    }

    private func canUseLocalChecker() -> Bool {
        #if canImport(UIKit)
        return true
        #else
        return false
        #endif
    }

    func initializeForKeyboardExtension() { clearUndoState() }
    func cleanup() { clearUndoState() }
    
    // MARK: - Public Utilities
    
    /// Extract the last token from text (used by KeyboardController)
    static func lastToken(in text: String) -> String? {
        let cleaned = text
            .replacingOccurrences(of: "\u{00AD}", with: "")   // soft hyphen
            .replacingOccurrences(of: "\u{200B}", with: "")   // zero-width space
            .replacingOccurrences(of: "\u{200C}", with: "")   // zero-width non-joiner
            .replacingOccurrences(of: "\u{200D}", with: "")   // zero-width joiner
        let parts = cleaned.components(separatedBy: .whitespacesAndNewlines)
        guard let raw = parts.last, !raw.isEmpty else { return nil }
        return raw.trimmingCharacters(in: CharacterSet(charactersIn: ".,!?;:()[]{}\"'"))
    }
    
    /// Check if a word is known by the user (learned or ignored)
    func isWordKnownByUser(_ word: String) -> Bool {
        return userLex.isUserKnown(word)
    }
    
    /// Mark a word as autocorrected (for intentional typing tracking)
    func recordAutocorrection(_ word: String) {
        // no-op by design (do not mark as intentional)
        markAutocorrected(word)
    }
    
    /// Mark a word as intentional (when user undoes correction)
    func recordIntentionalWord(_ word: String) {
        markIntentional(word)
    }
}

// MARK: - Apple-style data structures
struct SpellIssue {
    let word: String
    let range: NSRange
    let suggestions: [String]
    let isTypo: Bool // True for clear typos, false for contextual suggestions
    init(word: String, range: NSRange, suggestions: [String], isTypo: Bool = true) {
        self.word = word
        self.range = range
        self.suggestions = suggestions
        self.isTypo = isTypo
    }
}

struct AutoCorrectionCandidate {
    let original: String
    let correction: String
    let confidence: Double // 0.0 to 1.0
    let source: CorrectionSource
    enum CorrectionSource { case local, remote, cached }
}

// Simple case mirror: ALLCAPS → ALLCAPS, Titlecase → Titlecase, else lower/normal
private func preserveCase(template: String, like sample: String) -> String {
    if sample == sample.uppercased() { return template.uppercased() }               // YOURE → YOU'RE
    if sample == sample.capitalized {                                              // Youre → You're
        let first = template.prefix(1).uppercased()
        return first + template.dropFirst()
    }
    return template                                                                // youre → you're
}