import UIKit
import Foundation
import NaturalLanguage

class SpellCheckerManager {
    
    // MARK: - Configuration
    private static let maxSuggestions = 5
    
    // MARK: - Performance Optimizations - Pre-compiled Regexes
    private static let precompiledRegexes: [String: NSRegularExpression] = {
        var regexes: [String: NSRegularExpression] = [:]
        let patterns = [
            "multipleSpaces": "  +",
            "spaceBeforePunctuation": " +([.!?,:;])",
            "spaceAfterPunctuation": "([.!?])([A-Za-z])",
            "spaceAfterComma": "([,:;])([A-Za-z])",
            "spaceAroundApostrophe": " +'|' +",
            "spaceAroundHyphens": " +- +",
            "spaceAroundParens": "\\( +| +\\)",
            "spaceAroundQuotes": "\" +| +\"",
            "sentenceCapitalization": "([.!?]\\s+)([a-z])",
            "standaloneI": "\\bi\\b",
            "doublePunctuation": "\\.{2,}|\\!{2,}|\\?{2,}",
            "commaSpacing": ",([A-Za-z])",
            "periodSpacing": "\\.([A-Za-z])",
            "wordBoundary": "\\b",
            "contractionPattern": "\\b(I|We|You|They|He|She|It|Don|Can|Won|Shouldn|Couldn|Wouldn|Hasn|Haven|Hadn|Didn|Doesn|Aren|Isn|Wasn|Weren)\\s*(t|ve|ll|d|m|re|s)\\b",
            "autoRepeatPattern": "(.)\\1{3,}",
            "doubleNegative": "\\b(don't|doesn't|didn't|won't|can't|shouldn't|couldn't|wouldn't)\\s+(no|nothing|nobody|none|never)\\b",
            "repeatedWords": "\\b(\\w+)\\s+\\1\\b"
        ]
        
        for (key, pattern) in patterns {
            do {
                regexes[key] = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            } catch {
                print("Failed to compile regex for \(key): \(error)")
            }
        }
        return regexes
    }()
    
    // MARK: - User Dictionary & Analytics
    private static var userDictionary: Set<String> = {
        if let data = UserDefaults.standard.data(forKey: "SpellCheckerUserDictionary"),
           let dictionary = try? JSONDecoder().decode(Set<String>.self, from: data) {
            return dictionary
        }
        return Set<String>()
    }()
    
    private static var suggestionUsageStats: [String: Int] = {
        if let data = UserDefaults.standard.data(forKey: "SpellCheckerUsageStats"),
           let stats = try? JSONDecoder().decode([String: Int].self, from: data) {
            return stats
        }
        return [:]
    }()
    
    private static var preferredCorrections: [String: String] = {
        if let data = UserDefaults.standard.data(forKey: "SpellCheckerPreferredCorrections"),
           let corrections = try? JSONDecoder().decode([String: String].self, from: data) {
            return corrections
        }
        return [:]
    }()
    
    // MARK: - N-gram Model for Next-Word Prediction
    private static var bigramModel: [String: [String: Int]] = {
        if let data = UserDefaults.standard.data(forKey: "SpellCheckerBigramModel"),
           let model = try? JSONDecoder().decode([String: [String: Int]].self, from: data) {
            return model
        }
        return [:]
    }()
    
    // MARK: - Settings & Toggles
    struct SpellCheckerSettings {
        static var enableTypoCorrection: Bool {
            get { UserDefaults.standard.bool(forKey: "SpellChecker_EnableTypoCorrection") }
            set { UserDefaults.standard.set(newValue, forKey: "SpellChecker_EnableTypoCorrection") }
        }
        
        static var enableSpacingCorrection: Bool {
            get { UserDefaults.standard.bool(forKey: "SpellChecker_EnableSpacingCorrection") }
            set { UserDefaults.standard.set(newValue, forKey: "SpellChecker_EnableSpacingCorrection") }
        }
        
        static var enableCapitalization: Bool {
            get { UserDefaults.standard.bool(forKey: "SpellChecker_EnableCapitalization") }
            set { UserDefaults.standard.set(newValue, forKey: "SpellChecker_EnableCapitalization") }
        }
        
        static var enableGrammarCorrection: Bool {
            get { UserDefaults.standard.bool(forKey: "SpellChecker_EnableGrammarCorrection") }
            set { UserDefaults.standard.set(newValue, forKey: "SpellChecker_EnableGrammarCorrection") }
        }
        
        static var enableAutoRepeatReduction: Bool {
            get { UserDefaults.standard.bool(forKey: "SpellChecker_EnableAutoRepeatReduction") }
            set { UserDefaults.standard.set(newValue, forKey: "SpellChecker_EnableAutoRepeatReduction") }
        }
        
        static func setDefaults() {
            if !UserDefaults.standard.bool(forKey: "SpellChecker_DefaultsSet") {
                enableTypoCorrection = true
                enableSpacingCorrection = true
                enableCapitalization = true
                enableGrammarCorrection = true
                enableAutoRepeatReduction = true
                UserDefaults.standard.set(true, forKey: "SpellChecker_DefaultsSet")
            }
        }
    }
    
    // MARK: - Enhanced User Dictionary Management
    static func addToUserDictionary(_ word: String) {
        let cleanWord = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
        guard !cleanWord.isEmpty else { return }
        
        userDictionary.insert(cleanWord)
        saveUserDictionary()
    }
    
    static func removeFromUserDictionary(_ word: String) {
        let cleanWord = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
        userDictionary.remove(cleanWord)
        saveUserDictionary()
    }
    
    static func isInUserDictionary(_ word: String) -> Bool {
        let cleanWord = word.trimmingCharacters(in: .punctuationCharacters).lowercased()
        return userDictionary.contains(cleanWord)
    }
    
    static func getUserDictionaryWords() -> [String] {
        return Array(userDictionary).sorted()
    }
    
    static func clearUserDictionary() {
        userDictionary.removeAll()
        saveUserDictionary()
    }
    
    private static func saveUserDictionary() {
        if let data = try? JSONEncoder().encode(userDictionary) {
            UserDefaults.standard.set(data, forKey: "SpellCheckerUserDictionary")
        }
    }
    
    // MARK: - Enhanced Analytics & Learning
    private static func trackSuggestionUsage(original: String, corrected: String) {
        let key = "\(original.lowercased())->\(corrected.lowercased())"
        suggestionUsageStats[key, default: 0] += 1
        
        // Update preferred corrections based on usage
        if suggestionUsageStats[key, default: 0] >= 3 {
            preferredCorrections[original.lowercased()] = corrected.lowercased()
            savePreferredCorrections()
        }
        
        // Save stats periodically
        if suggestionUsageStats.count % 10 == 0 {
            saveSuggestionStats()
        }
    }
    
    private static func saveSuggestionStats() {
        if let data = try? JSONEncoder().encode(suggestionUsageStats) {
            UserDefaults.standard.set(data, forKey: "SpellCheckerUsageStats")
        }
    }
    
    private static func savePreferredCorrections() {
        if let data = try? JSONEncoder().encode(preferredCorrections) {
            UserDefaults.standard.set(data, forKey: "SpellCheckerPreferredCorrections")
        }
    }
    
    // MARK: - Analytics Access
    static func getCorrectionAnalytics() -> [String: Any] {
        return [
            "totalCorrections": suggestionUsageStats.values.reduce(0, +),
            "uniqueCorrections": suggestionUsageStats.count,
            "userDictionarySize": userDictionary.count,
            "preferredCorrections": preferredCorrections.count,
            "topCorrections": getMostUsedCorrections()
        ]
    }
    
    private static func getMostUsedCorrections() -> [(original: String, corrected: String, count: Int)] {
        return suggestionUsageStats
            .sorted { $0.value > $1.value }
            .prefix(10)
            .compactMap { item in
                let components = item.key.components(separatedBy: "->")
                guard components.count == 2 else { return nil }
                return (original: components[0], corrected: components[1], count: item.value)
            }
    }
    
    private static func updateBigramModel(previousWord: String, currentWord: String) {
        let prev = previousWord.lowercased()
        let curr = currentWord.lowercased()
        
        if bigramModel[prev] == nil {
            bigramModel[prev] = [:]
        }
        bigramModel[prev]![curr, default: 0] += 1
        
        // Save periodically
        if arc4random_uniform(20) == 0 { // 5% chance to save
            saveBigramModel()
        }
    }
    
    private static func saveBigramModel() {
        if let data = try? JSONEncoder().encode(bigramModel) {
            UserDefaults.standard.set(data, forKey: "SpellCheckerBigramModel")
        }
    }
    
    // MARK: - Enhanced Next-Word Prediction
    static func getNextWordPredictions(for text: String) -> [String] {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        guard let lastWord = words.last?.lowercased(), !lastWord.isEmpty else { return [] }
        
        var predictions: [String] = []
        
        // Check bigram model
        if let nextWords = bigramModel[lastWord] {
            let sortedWords = nextWords.sorted { $0.value > $1.value }
            predictions.append(contentsOf: sortedWords.prefix(3).map { $0.key })
        }

        // Add contextual predictions based on patterns
        predictions.append(contentsOf: getContextualNextWords(lastWord: lastWord))

        // Add completion predictions
        predictions.append(contentsOf: getCompletionPredictions(for: lastWord))

        return Array(Set(predictions).prefix(maxSuggestions))
    }

private static func getContextualNextWords(lastWord: String) -> [String] {
    switch lastWord {
    case "please":
        return ["let", "help", "send", "share", "consider", "confirm", "reply", "advise", "review", "update"]
    case "could":
        return ["you", "we", "this", "be", "have", "try", "focus", "explore", "explain", "support"]
    case "would":
        return ["you", "like", "be", "love", "prefer", "enjoy", "appreciate", "consider", "recommend", "acknowledge"]
    case "should":
        return ["we", "I", "you", "be", "have", "consider", "expect", "review", "address", "plan"]
    case "thank":
        return ["you", "everyone", "them", "so", "goodness", "you all", "you kindly", "you deeply", "you truly", "you sincerely"]
    case "looking":
        return ["forward", "at", "for", "into", "good", "ahead", "toward", "to", "beyond", "back"]
        
    // —— Pronouns —— //
    case "i":
        return ["am", "have", "will", "can", "think", "feel", "would", "could", "need", "want", "plan", "hope"]
    case "you":
        return ["are", "have", "will", "can", "should", "might", "could", "seem", "feel", "know", "think"]
    case "we":
        return ["are", "have", "should", "can", "will", "might", "could", "need", "want", "plan"]
    case "they":
        return ["are", "have", "will", "can", "might", "could", "seem", "want", "believe", "appear"]
        
    // —— Articles —— //
    case "the":
        return ["best", "same", "first", "last", "other", "most", "next", "only", "ideal", "ultimate", "key", "following"]
        
    // —— Demonstratives —— //
    case "this":
        return ["is", "seems", "means", "could", "will", "might", "feels", "works", "matters", "helps"]
    case "that":
        return ["is", "seems", "means", "could", "will", "might", "was", "felt", "impacts", "involves"]
        
    // —— Conjunctions —— //
    case "and":
        return ["I", "you", "we", "they", "so", "but", "also", "then", "therefore", "finally"]
    case "but":
        return ["I", "you", "we", "they", "still", "instead", "rather", "however", "maybe", "perhaps"]
        
    // —— Prepositions —— //
    case "for":
        return ["you", "me", "us", "them", "this", "that", "the", "your", "my", "one"]
    case "with":
        return ["you", "me", "us", "them", "it", "this", "that", "your", "our", "my"]
        
    default:
        return []
    }
}
    
    private static func getCompletionPredictions(for partialWord: String) -> [String] {
        guard partialWord.count >= 2 else { return [] }
        
        let commonWords = [
    "the", "and", "you", "that", "was", "for", "are", "with", "his", "they",
    "have", "this", "will", "your", "from", "know", "want", "been", "good",
    "much", "some", "time", "very", "when", "come", "here", "just", "like",
    "long", "make", "many", "over", "such", "take", "than", "them", "well",
    "work", "could", "would", "should", "think", "people", "about", "because",
    "before", "through", "without", "against", "between", "during", "example",
    "important", "different", "possible", "question", "information",

    // — Additional Common Words — //
    "not", "all", "any", "one", "get", "see", "back", "after", "also", "where",
    "need", "feel", "right", "only", "even", "might", "help", "keep", "say",
    "take", "give", "look", "use", "find", "tell", "ask", "put", "try", "ask",
    "keep", "turn", "leave", "call", "move", "play", "run", "start", "stop",
    "start", "end", "learn", "show", "give", "hold", "write", "read", "meet",
    "bring", "let", "set", "keep", "let", "follow", "change", "lead", "watch",
    "carry", "break", "build", "grow", "open", "close", "run", "sit", "stand",
    "sit", "stay", "pass", "fall", "cut", "reach", "reach", "serve", "buy",
    "sell", "love", "live", "die", "die"
        ]
        
        return commonWords.filter { $0.lowercased().hasPrefix(partialWord.lowercased()) }
    }
    
    static func learnFromUserInput(_ text: String) {
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        
        for i in 0..<words.count - 1 {
            let currentWord = words[i].trimmingCharacters(in: .punctuationCharacters)
            let nextWord = words[i + 1].trimmingCharacters(in: .punctuationCharacters)
            
            if !currentWord.isEmpty && !nextWord.isEmpty {
                updateBigramModel(previousWord: currentWord, currentWord: nextWord)
            }
        }
    }
    
    // MARK: - Grammar Patterns
    private static let grammarPatterns: [(pattern: String, suggestion: String, description: String)] = [
        ("\\bdon't need no\\b", "don't need any", "Double negative correction"),
        ("\\bcan't get no\\b", "can't get any", "Double negative correction"),
        ("\\b(\\w+)\\s+\\1\\b", "$1", "Repeated word removal"),
        ("\\bin order to\\b", "to", "Phrase simplification"),
        ("\\bon the other hand\\b", "alternatively", "Phrase alternative"),
        ("\\bas soon as possible\\b", "ASAP", "Abbreviation suggestion"),
        ("\\bfor the purpose of\\b", "to", "Concise alternative"),
        ("\\ba\\s+([aeiouAEIOU])", "an $1", "Article correction before vowels"),
        ("\\ban\\s+([bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ])", "a $1", "Article correction before consonants"),
        ("\\bwould of\\b", "would have", "Common grammar error"),
        ("\\bcould of\\b", "could have", "Common grammar error"),
        ("\\bshould of\\b", "should have", "Common grammar error"),
        ("\\byour welcome\\b", "you're welcome", "Contraction correction"),
        ("\\bits ok\\b", "it's ok", "Contraction correction"),
        ("\\bthere house\\b", "their house", "Possessive correction"),
        ("\\bwhos house\\b", "whose house", "Possessive correction"),
        ("\\bI and\\b", "I and", "Pronoun order"),
        ("\\bme and (\\w+)\\b", "$1 and I", "Pronoun case correction"),
        ("\\bbetween you and I\\b", "between you and me", "Pronoun case correction"),
        ("\\bdifferent than\\b", "different from", "Preposition correction"),
        ("\\btry and\\b", "try to", "Infinitive correction"),
        ("\\bmore better\\b", "better", "Comparative correction"),
        ("\\bmost best\\b", "best", "Superlative correction"),
        ("\\bless worse\\b", "worse", "Comparative correction"),
        ("\\bvery unique\\b", "unique", "Absolute adjective correction"),
        ("\\bmore perfect\\b", "perfect", "Absolute adjective correction"),
        
        // Advanced grammatical constructions
        ("\\bregardless of the fact that\\b", "although", "Concise conjunction"),
        ("\\bin the event that\\b", "if", "Concise conditional"),
        ("\\bdue to the fact that\\b", "because", "Concise causation"),
        ("\\bat this point in time\\b", "now", "Temporal redundancy"),
        ("\\bin spite of the fact that\\b", "although", "Concise contrast"),
        ("\\bby means of\\b", "by", "Preposition simplification"),
        ("\\bin the vicinity of\\b", "near", "Location simplification"),
        ("\\bfor the reason that\\b", "because", "Causation simplification"),
        
        // Subject-verb agreement patterns
        ("\\b(everyone|someone|anyone|no one)\\s+(are|were)\\b", "$1 is", "Singular subject agreement"),
        ("\\b(neither|either)\\s+of\\s+\\w+\\s+(are|were)\\b", "$1 of them is", "Singular with either/neither"),
        ("\\b(each|every)\\s+\\w+\\s+(are|were)\\b", "$1 $2 is", "Singular with each/every"),
        
        // Pronoun case corrections
        ("\\b(him|her)\\s+and\\s+I\\b", "$1 and me", "Object pronoun case"),
        ("\\bbetween\\s+(he|she)\\s+and\\s+I\\b", "between $1 and me", "Object case after preposition"),
        ("\\bfor\\s+(he|she)\\s+and\\s+I\\b", "for $1 and me", "Object case after preposition"),
        ("\\bwith\\s+(he|she)\\s+and\\s+I\\b", "with $1 and me", "Object case after preposition"),
        
        // Verb tense consistency
        ("\\bI\\s+have\\s+went\\b", "I have gone", "Past participle correction"),
        ("\\bI\\s+have\\s+came\\b", "I have come", "Past participle correction"),
        ("\\bI\\s+have\\s+ran\\b", "I have run", "Past participle correction"),
        ("\\bI\\s+have\\s+began\\b", "I have begun", "Past participle correction"),
        ("\\bI\\s+had\\s+ate\\b", "I had eaten", "Past participle correction"),
        ("\\bI\\s+had\\s+drank\\b", "I had drunk", "Past participle correction"),
        
        // Adverb vs adjective
        ("\\bfeel\\s+badly\\b", "feel bad", "Linking verb with adjective"),
        ("\\btaste\\s+badly\\b", "taste bad", "Linking verb with adjective"),
        ("\\breal\\s+good\\b", "really good", "Adverb modification"),
        ("\\breal\\s+quick\\b", "really quick", "Adverb modification"),
        ("\\bmost\\s+importantly\\b", "more importantly", "Comparative adverb"),
        
        // Apostrophe corrections
        ("\\bits'\\s+(\\w+)\\b", "its $1", "Possessive pronoun correction"),
        ("\\bits\\s+not\\b", "it's not", "Contraction correction"),
        ("\\bits\\s+been\\b", "it's been", "Contraction correction"),
        ("\\byour\\s+going\\b", "you're going", "Contraction correction"),
        ("\\byour\\s+right\\b", "you're right", "Contraction correction"),
        ("\\bthere\\s+going\\b", "they're going", "Contraction correction"),
        
        // Preposition corrections
        ("\\bdifferent\\s+than\\b", "different from", "Preposition usage"),
        ("\\bcompare\\s+to\\b", "compare with", "Preposition usage"),
        ("\\bagreed\\s+to\\s+the\\s+plan\\b", "agreed with the plan", "Preposition usage"),
        ("\\bin\\s+regards\\s+to\\b", "with regard to", "Preposition phrase"),
        ("\\bon\\s+accident\\b", "by accident", "Preposition correction"),
        
        // Redundancy eliminations
        ("\\badvance\\s+planning\\b", "planning", "Redundancy removal"),
        ("\\bfuture\\s+plans\\b", "plans", "Redundancy removal"),
        ("\\bpast\\s+history\\b", "history", "Redundancy removal"),
        ("\\bfree\\s+gift\\b", "gift", "Redundancy removal"),
        ("\\btrue\\s+fact\\b", "fact", "Redundancy removal"),
        ("\\bunexpected\\s+surprise\\b", "surprise", "Redundancy removal"),
        ("\\bexact\\s+same\\b", "same", "Redundancy removal"),
        
        // Comparative and superlative errors
        ("\\bmore\\s+funner\\b", "more fun", "Comparative correction"),
        ("\\bmore\\s+easier\\b", "easier", "Comparative correction"),
        ("\\bmost\\s+funnest\\b", "most fun", "Superlative correction"),
        ("\\bmore\\s+faster\\b", "faster", "Comparative correction"),
        ("\\bmore\\s+slower\\b", "slower", "Comparative correction"),
        
        // Split infinitive suggestions (optional)
        ("\\bto\\s+really\\s+understand\\b", "really to understand", "Split infinitive alternative"),
        ("\\bto\\s+quickly\\s+finish\\b", "quickly to finish", "Split infinitive alternative"),
        
        // Dangling modifier patterns
        ("\\bwalking\\s+down\\s+the\\s+street,\\s+the\\s+house\\b", "walking down the street, I saw the house", "Dangling modifier correction"),
        ("\\bhaving\\s+finished\\s+the\\s+work,\\s+the\\s+TV\\b", "having finished the work, I watched TV", "Dangling modifier correction"),
        
        // Common phrase corrections
        ("\\bfor\\s+all\\s+intensive\\s+purposes\\b", "for all intents and purposes", "Phrase correction"),
        ("\\bi\\s+could\\s+care\\s+less\\b", "I couldn't care less", "Phrase correction"),
        ("\\bnip\\s+it\\s+in\\s+the\\s+butt\\b", "nip it in the bud", "Phrase correction"),
        ("\\bone\\s+in\\s+the\\s+same\\b", "one and the same", "Phrase correction"),
        ("\\becscape\\s+goat\\b", "scapegoat", "Compound word correction"),
        
        // Technical writing improvements
        ("\\bdue\\s+to\\b", "because of", "Causal preposition"),
        ("\\bcurrently\\s+is\\b", "is", "Redundant adverb"),
        ("\\bbasically\\s+is\\b", "is", "Redundant adverb"),
        ("\\bactually\\s+is\\b", "is", "Redundant adverb"),
        
        // Formal writing patterns
        ("\\ba\\s+lot\\s+of\\b", "many", "Formal quantifier"),
        ("\\bkind\\s+of\\b", "somewhat", "Formal qualifier"),
        ("\\bsort\\s+of\\b", "somewhat", "Formal qualifier"),
        ("\\bstuff\\s+like\\s+that\\b", "such things", "Formal expression"),
        
        // Business writing corrections
        ("\\bplease\\s+don't\\s+hesitate\\s+to\\b", "please", "Concise business language"),
        ("\\bat\\s+your\\s+earliest\\s+convenience\\b", "soon", "Concise business language"),
        ("\\bper\\s+your\\s+request\\b", "as requested", "Business phrase correction")
    ]
    
    private static let commonTypos: [String: String] = [
     "teh": "the",
  "adn": "and",
  "recieve": "receive",
  "seperate": "separate",
  "definately": "definitely",
  "occured": "occurred",
  "neccessary": "necessary",
  "acommodate": "accommodate",
  "embarass": "embarrass",
  "wierd": "weird",
  "freind": "friend",
  "thier": "their",
  "wich": "which",
  "becuase": "because",
  "alot": "a lot",
  "cant": "can't",
  "dont": "don't",
  "wont": "won't",
  "youre": "you're",
  "its": "it's",
  "im": "I'm",
  "ive": "I've",
  "ill": "I'll",
  "id": "I'd",
  "adress": "address",
  "calender": "calendar",
  "goverment": "government",
  "occurance": "occurrence",
  "tommorow": "tomorrow",
  "tomorow": "tomorrow",
  "arguement": "argument",
  "beleive": "believe",
  "acheive": "achieve",
  "surpise": "surprise",
  "persue": "pursue",
  "untill": "until",
  "reccommend": "recommend",
  "propably": "probably",
  "happend": "happened",
  "seperately": "separately",
  "ocassion": "occasion",
  "occassional": "occasional",
  "concious": "conscious",
  "existance": "existence",
  "enviroment": "environment",
  "wichout": "without",
  "wierdst": "weirdest",
  "maintainance": "maintenance",
  "priviledge": "privilege",
  "restaraunt": "restaurant",
  "begining": "beginning",
  "neccessarily": "necessarily",
  "seige": "siege",
  "accross": "across",
  "embarased": "embarrassed",
  "rythm": "rhythm",
  "negligeable": "negligible",
  "mischevious": "mischievous",
  "gaurd": "guard",
  "commited": "committed",
  "occuring": "occurring",
  "publically": "publicly",
  "recommendationn": "recommendation",
  "sucess": "success",
  "treshold": "threshold",
  "tendancy": "tendency",
  "noticable": "noticeable",
  "wierdly": "weirdly",
  "acomodation": "accommodation",
  "mispell": "misspell",
  "commitee": "committee",
  "occassionally": "occasionally",
  "priviledged": "privileged",
  "tolerrance": "tolerance",
  "definate": "definite",
  "refered": "referred",
  "buisness": "business",
  "enviromental": "environmental",
  "moslty": "mostly",
  "succesful": "successful",
  "lieing": "lying",
  "wichh": "which",
  "adresss": "address",
  "beleiveing": "believing",
  "acheivement": "achievement",
  "arguementative": "argumentative",
  "calendering": "calendaring",
  "comitte": "committee",
  "conciously": "consciously",
  "definatelye": "definitely",
  "embarres": "embarrass",
  "enviromentalism": "environmentalism",
  "govermental": "governmental",
  "hieght": "height",
  "imediately": "immediately",
  "independant": "independent",
  "intrest": "interest",
  "jist": "gist",
  "maintenence": "maintenance",
  "medeval": "medieval",
  "millenium": "millennium",
  "neice": "niece",
  "none-the-less": "nonetheless",
  "ocurrance": "occurrence",
  "passible": "possible",
  "posession": "possession",
  "reciept": "receipt",
  "relevent": "relevant",
  "restaraunts": "restaurants",
  "rythmic": "rhythmic",
  "seigeing": "sieging",
  "seperation": "separation",
  "signiture": "signature",
  "succesfully": "successfully",
  "tommorrow": "tomorrow",
  "truely": "truly",
  "vaccum": "vacuum",
  "wierness": "weirdness",
  "writting": "writing",
  "wierdness": "weirdness",
  "acomadate": "accommodate",
  "accomodate": "accommodate",
  "accomodation": "accommodation",
  "acquaintence": "acquaintance",
  "acknowlege": "acknowledge",
  "acknowlegement": "acknowledgement",
  "agressive": "aggressive",
  "apparant": "apparent",
  "apparantly": "apparently",
  "athelete": "athlete",
  "atheletic": "athletic",
  "bacause": "because",
  "beliveable": "believable",
  "bizzare": "bizarre",
  "brocoli": "broccoli",
  "busyness": "business",
  "cemetary": "cemetery",
  "changable": "changeable",
  "collegue": "colleague",
  "collectable": "collectible",
  "completly": "completely",
  "congradulate": "congratulate",
  "congradulations": "congratulations",
  "conciencious": "conscientious",
  "consistant": "consistent",
  "couldnt": "couldn't",
  "creatable": "creatable",
  "dependant": "dependent",
  "dilemna": "dilemma",
  "dilema": "dilemma",
  "dimention": "dimension",
  "dissapear": "disappear",
  "dissapoint": "disappoint",
  "equipement": "equipment",
  "exhilerate": "exhilarate",
  "febuary": "February",
  "finaly": "finally",
  "fluoresant": "fluorescent",
  "foriegn": "foreign",
  "harrass": "harass",
  "harrassment": "harassment",
  "heighth": "height",
  "hierachy": "hierarchy",
  "jewelery": "jewellery",
  "judgement": "judgment",
  "knowlege": "knowledge",
  "maintanence": "maintenance",
  "miniatureing": "miniaturing",
  "mispell": "misspell",
  "negligeable": "negligible",
  "nintey": "ninety",
  "occurence": "occurrence",
  "occassion": "occasion",
  "occasionly": "occasionally",
  "ommission": "omission",
  "occurrance": "occurrence",
  "officialy": "officially",
  "parliment": "parliament",
  "pasttime": "pastime",
  "perseverence": "perseverance",
  "personell": "personnel",
  "plagarism": "plagiarism",
  "probabl y": "probably",
  "publically": "publicly",
  "reccommend": "recommend",
  "recomend": "recommend",
  "religous": "religious",
  "sieze": "seize",
  "sobriety?": "",
  "suprise": "surprise",
  "supercede": "supersede",
  "tatoo": "tattoo",
  "twelth": "twelfth",
  "tyrany": "tyranny",
  "yr": "year"
    ]
    
    // MARK: - Core Spell Check Functions
    static func checkSpelling(text: String) -> String {
        // Initialize settings if not set
        SpellCheckerSettings.setDefaults()
        
        var processedText = text
        
        // Process in order for optimal results
        if SpellCheckerSettings.enableAutoRepeatReduction {
            processedText = reduceAutoRepeatedLetters(processedText)
        }
        
        if SpellCheckerSettings.enableSpacingCorrection {
            processedText = fixSpacingIssuesOptimized(processedText)
        }
        
        if SpellCheckerSettings.enableCapitalization {
            processedText = applyCapitalizationRules(processedText)
        }
        
        if SpellCheckerSettings.enableGrammarCorrection {
            // first do your regex-based phrase fixes
            processedText = correctGrammarAndPhrases(processedText)
            // then run a broader grammar pass
            processedText = performGrammarCorrections(processedText)
        }
        
        if SpellCheckerSettings.enableTypoCorrection {
            processedText = correctTyposWithBatchOptimization(processedText)
        }
        
        return processedText
    }
    
    // MARK: - Enhanced Grammar and Phrase Correction
    static func correctGrammarAndPhrases(_ text: String) -> String {
        var correctedText = text
        
        // Fix double negatives using pre-compiled regex
        if let regex = precompiledRegexes["doubleNegative"] {
            let matches = regex.matches(in: correctedText, options: [], range: NSRange(location: 0, length: correctedText.count))
            for match in matches.reversed() {
                if let range = Range(match.range, in: correctedText) {
                    let matchedText = String(correctedText[range])
                    let fixedText = fixDoubleNegative(matchedText)
                    correctedText.replaceSubrange(range, with: fixedText)
                }
            }
        }
        
        // Remove repeated words using pre-compiled regex
        if let regex = precompiledRegexes["repeatedWords"] {
            correctedText = regex.stringByReplacingMatches(
                in: correctedText,
                options: [],
                range: NSRange(location: 0, length: correctedText.count),
                withTemplate: "$1"
            )
        }
        
        // Simplify common phrases
        correctedText = simplifyCommonPhrases(correctedText)
        
        return correctedText
    }
    
    private static func fixDoubleNegative(_ text: String) -> String {
        // Convert double negatives to positive forms
        let negativeMap = [
            "don't have no": "don't have any",
    "doesn't have no": "doesn't have any",
    "didn't see no": "didn't see any",
    "won't take no": "won't take any",
    "can't find no": "can't find any",
    "shouldn't do nothing": "shouldn't do anything",
    "couldn't find nothing": "couldn't find anything",
    "wouldn't say nothing": "wouldn't say anything",
    
    // Additional patterns
    "ain't got no": "don't have any",
    "aren't got no": "don't have any",
    "don't want no": "don't want any",
    "didn't hear nothing": "didn't hear anything",
    "you don't know nothing": "you don't know anything",
    "I didn't see nothing": "I didn't see anything",
    "there isn't no": "there isn't any",
    "we don't need no": "we don't need any",
    "he didn't say nothing": "he didn't say anything",
    "they haven't got no": "they haven't got any",
    "I can't do nothing": "I can't do anything",
    "she won't eat nothing": "she won't eat anything",
    "we couldn't find no": "we couldn't find any",
    "they didn't get no": "they didn't get any",
    "you can't do nothing": "you can't do anything",
    "he shouldn't say nothing": "he shouldn't say anything",
    "we don't know nothing": "we don't know anything",
    "I haven't done nothing": "I haven't done anything",
    "she didn't have nothing": "she didn't have anything",
    "you don't got no": "you don't have any",
    "we won't have no": "we won't have any",
    "they didn't bring no": "they didn't bring any",
    "I don't see no": "I don't see any",
    "he didn't want no": "he didn't want any",
    "she doesn't need no": "she doesn't need any",
    "you wouldn't get no": "you wouldn't get any",
    "they can't make no": "they can't make any",
    "we couldn't hear nothing": "we couldn't hear anything"
        ]
        
        var result = text.lowercased()
        for (negative, positive) in negativeMap {
            result = result.replacingOccurrences(of: negative, with: positive)
        }
        
        return result
    }
    
    private static func simplifyCommonPhrases(_ text: String) -> String {
        let simplifications = [
             "at this point in time": "now",
    "due to the fact that": "because",
    "in order to": "to",
    "for the purpose of": "to",
    "in the event that": "if",
    "with regard to": "about",
    "in spite of the fact that": "although",
    "it is important to note that": "",
    "please be advised that": "",
    "it should be noted that": "",
    "in the near future": "soon",
    "for all intents and purposes": "essentially",
    "in a timely manner": "promptly",
    "with the exception of": "except",
    "in close proximity to": "near",
    "on a daily basis": "daily",
    "at the present moment": "now",
    "in the amount of": "amounting to",
    "in light of the fact that": "since",
    "for the time being": "for now",
    "in the final analysis": "ultimately",
    "in the majority of cases": "usually",
    "in the process of": "while",
    "on the occasion of": "when",
    "in the near term": "soon",
    "in the long run": "eventually",
    "in the event of": "if",
    "in reference to": "regarding",
    "in conjunction with": "with",
    "for the most part": "mostly",
    "in excess of": "over",
    "in accordance with": "per",
    "with respect to": "regarding",
    "so as to": "to",
    "in connection with": "about",
    "with the aim of": "to",
    "in terms of": "about",
    "for those who": "for people who"
        ]
        
        var result = text
        for (complex, simple) in simplifications {
            result = result.replacingOccurrences(of: complex, with: simple, options: .caseInsensitive)
        }
        
        return result
    }
    // MARK: - Enhanced Batch Autocorrect with Performance Optimization
    static func autocorrectLastWord(using proxy: UITextDocumentProxy, language: String = "en_US") {
        guard let context = proxy.documentContextBeforeInput else { 
            proxy.insertText(" ")
            return 
        }
        
        // Extract just the last word for efficient correction
        let words = context.components(separatedBy: .whitespacesAndNewlines)
        guard let lastWord = words.last, !lastWord.isEmpty else {
            proxy.insertText(" ")
            return
        }
        
        // Check if word is in user dictionary first (fastest path)
        if isInUserDictionary(lastWord) {
            proxy.insertText(" ")
            return
        }
        
        let correctedWord = performWordCorrection(lastWord, language: language)
        
        if correctedWord != lastWord {
            // Batch operation: delete only the last word and replace
            for _ in 0..<lastWord.count {
                proxy.deleteBackward()
            }
            proxy.insertText(correctedWord + " ")
            
            // Track successful correction
            trackSuggestionUsage(original: lastWord, corrected: correctedWord)
        } else {
            proxy.insertText(" ")
        }
    }
    
    // MARK: - Batch Autocorrect Optimization (Replace only last word)
    static func correctTyposWithBatchOptimization(_ text: String) -> String {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        guard !words.isEmpty else { return text }
        
        // Only correct the last word for performance
        let lastWordIndex = words.count - 1
        let lastWord = words[lastWordIndex]
        
        if lastWord.isEmpty || isInUserDictionary(lastWord) {
            return text
        }
        
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: lastWord.count)
        
        if checker.rangeOfMisspelledWord(in: lastWord, range: range, startingAt: 0, wrap: false, language: "en").location != NSNotFound {
            // Check for preferred correction first
            if let preferredCorrection = getPreferredCorrection(for: lastWord) {
                var correctedWords = words
                correctedWords[lastWordIndex] = preferredCorrection
                return correctedWords.joined(separator: " ")
            }
            
            // Get system suggestions
            let suggestions = checker.guesses(forWordRange: range, in: lastWord, language: "en") ?? []
            
            if let firstSuggestion = suggestions.first {
                var correctedWords = words
                correctedWords[lastWordIndex] = firstSuggestion
                
                // Track suggestion usage
                trackSuggestionUsage(original: lastWord, corrected: firstSuggestion)
                
                return correctedWords.joined(separator: " ")
            }
        }
        
        return text
    }
    
    // MARK: - Auto-Repeat Deduplication (Enhanced)
    static func reduceAutoRepeatedLetters(_ text: String) -> String {
        guard let regex = precompiledRegexes["autoRepeatPattern"] else { return text }
        
        return regex.stringByReplacingMatches(
            in: text,
            options: [],
            range: NSRange(location: 0, length: text.count),
            withTemplate: "$1$1"
        )
    }
    
    // MARK: - Enhanced Word-Level Correction (Optimized)
    private static func performWordCorrection(_ word: String, language: String) -> String {
        var corrected = word
        
        // 1. Common typos (fastest)
        if let commonCorrection = commonTypos[word.lowercased()] {
            return commonCorrection
        }
        
        // 2. Smart contractions with pattern matching
        corrected = fixSmartContractions(corrected)
        
        // 3. Check learned preferences (user-specific corrections)
        if let preferredCorrection = preferredCorrections[word.lowercased()] {
            return preferredCorrection
        }
        
        // 4. Auto-repeat reduction
        corrected = reduceAutoRepeatedLetters(corrected)
        
        // 5. Spell check as last resort
        if let suggestion = getBestSpellingSuggestion(for: corrected, language: language) {
            return suggestion
        }
        
        return corrected
    }
    
    // MARK: - Enhanced Preferred Corrections (Learning)
    private static func getPreferredCorrection(for word: String) -> String? {
        let wordLower = word.lowercased()
        
        // Direct lookup first
        if let preferred = preferredCorrections[wordLower] {
            return preferred
        }
        
        // Find the most frequently accepted correction for this word
        let corrections = suggestionUsageStats.filter { $0.key.hasPrefix(wordLower + "->") }
        guard let bestCorrection = corrections.max(by: { $0.value < $1.value }) else { return nil }
        
        return String(bestCorrection.key.split(separator: ">").last ?? "")
    }
    
    // MARK: - Advanced Text Correction Engine with Grammar
    static func performAdvancedCorrection(context: String, language: String = "en_US") -> String {
        var correctedText = context
        
        // Step 1: Grammar corrections
        correctedText = performGrammarCorrections(correctedText)
        
        // Step 2: Fix common typos (optimized with pre-compiled regex)
        correctedText = fixCommonTypos(correctedText)
        
        // Step 3: Fix spacing issues (using pre-compiled regex)
        correctedText = fixSpacingIssuesOptimized(correctedText)
        
        // Step 4: Apply auto-capitalization rules
        correctedText = applyCapitalizationRules(correctedText)
        
        // Step 5: Smart contractions
        correctedText = fixSmartContractions(correctedText)
        
        // Step 6: Auto-repeat deduplication
        correctedText = deduplicateRepeatedCharacters(correctedText)
        
        // Step 7: Spell check individual words
        correctedText = performSpellCheck(correctedText, language: language)
        
        // Step 8: Final punctuation and formatting cleanup
        correctedText = finalFormatCleanup(correctedText)
        
        return correctedText
    }
    
    // MARK: - Grammar Corrections (Enhanced)
    static func performGrammarCorrections(_ text: String) -> String {
        var result = text
        
        for pattern in grammarPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern.pattern, options: [.caseInsensitive]) {
                let range = NSRange(location: 0, length: result.count)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: pattern.suggestion)
            }
        }
        
        // Additional grammar fixes using pre-compiled regexes
        result = correctGrammarAndPhrases(result)
        
        // NEW: quick POS-based rule: no orphaned verbs at sentence start
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = result
        result = result
            .split(separator: ".")
            .map { sentence in
                let s = String(sentence.trimmingCharacters(in: .whitespaces))
                guard !s.isEmpty else { return s }
                tagger.string = s
                let (tag, _) = tagger.tag(at: s.startIndex, unit: .word, scheme: .lexicalClass)
                if tag == .verb {
                    // e.g. "Run the report" → "Please run the report"
                    return "Please " + s
                }
                return s
            }
            .joined(separator: ". ")
        
        // finally, re-run your phrase corrections to catch knock-on effects
        result = correctGrammarAndPhrases(result)
        
        return result
    }
    
    // MARK: - Auto-repeat Deduplication
    private static func deduplicateRepeatedCharacters(_ text: String) -> String {
        // Collapse excessive repeated characters (heyyyy -> hey)
        let pattern = "([a-zA-Z])\\1{3,}"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let range = NSRange(location: 0, length: text.count)
            return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "$1$1")
        }
        return text
    }
    
    // MARK: - Common Typo Correction
    private static func fixCommonTypos(_ text: String) -> String {
        var result = text
        
        for (typo, correction) in commonTypos {
            // Word boundary replacement to avoid partial matches
            let pattern = "\\b" + NSRegularExpression.escapedPattern(for: typo) + "\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(location: 0, length: result.count)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: correction)
            }
        }
        
        return result
    }
    
    // MARK: - Optimized Spacing Correction (Using Pre-compiled Regex)
    private static func fixSpacingIssuesOptimized(_ text: String) -> String {
        var result = text
        
        // Use pre-compiled regexes for better performance
        let spacingFixes: [(regex: String, replacement: String)] = [
            ("multipleSpaces", " "),
            ("spacePunctuation", "$1"),
            ("punctuationLetter", "$1 $2"),
            ("commaSemicolon", "$1 $2"),
            ("apostropheSpaces", "'"),
            ("hyphenSpaces", "-"),
            ("parenthesesSpaces", result.contains("( ") ? "(" : ")"),
            ("quoteSpaces", "\"")
        ]
        
        for (regexKey, replacement) in spacingFixes {
            if let regex = precompiledRegexes[regexKey] {
                let range = NSRange(location: 0, length: result.count)
                result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: replacement)
            }
        }
        
        return result
    }
    
    // MARK: - Smart Contractions (Pattern-Based)
    private static func fixSmartContractions(_ text: String) -> String {
        var result = text
        
        // Smart contraction detection using pattern matching
        if let regex = precompiledRegexes["contractionsPattern"] {
            let matches = regex.matches(in: result, options: [], range: NSRange(location: 0, length: result.count))
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: result) {
                    let matchedText = String(result[range]).lowercased()
                    if let correction = getContractionCorrection(matchedText) {
                        result.replaceSubrange(range, with: correction)
                    }
                }
            }
        }
        
        return result
    }
    
    private static func getContractionCorrection(_ text: String) -> String? {
        let contractionMap = [
            "cant": "can't", "dont": "don't", "wont": "won't", "isnt": "isn't",
            "arent": "aren't", "wasnt": "wasn't", "werent": "weren't", "hasnt": "hasn't",
            "havent": "haven't", "hadnt": "hadn't", "didnt": "didn't", "doesnt": "doesn't",
            "shouldnt": "shouldn't", "couldnt": "couldn't", "wouldnt": "wouldn't",
            "im": "I'm", "id": "I'd", "ill": "I'll", "ive": "I've",
            "youre": "you're", "youve": "you've", "youll": "you'll", "youd": "you'd",
            "theyre": "they're", "theyve": "they've", "theyll": "they'll", "theyd": "they'd",
            "were": "we're", "weve": "we've", "well": "we'll", "wed": "we'd",
            "its": "it's", "thats": "that's", "whats": "what's", "wheres": "where's",
            "whos": "who's", "lets": "let's", "theres": "there's"
        ]
        
        return contractionMap[text]
    }
    
    // MARK: - Auto-Capitalization
    private static func applyCapitalizationRules(_ text: String) -> String {
        var result = text
        
        // Capitalize first letter of text
        if let firstChar = result.first, firstChar.isLowercase {
            result = result.prefix(1).uppercased() + result.dropFirst()
        }
        
        // Capitalize after sentence endings
        let sentenceEndPattern = "([.!?]\\s+)([a-z])"
        if let regex = try? NSRegularExpression(pattern: sentenceEndPattern, options: []) {
            let range = NSRange(location: 0, length: result.count)
            let matches = regex.matches(in: result, options: [], range: range)
            
            // Process matches in reverse order to maintain indices
            for match in matches.reversed() {
                if match.numberOfRanges >= 3 {
                    let fullRange = match.range
                    let punctuationRange = match.range(at: 1)
                    let letterRange = match.range(at: 2)
                    
                    if let punctuationString = Range(punctuationRange, in: result).map({ String(result[$0]) }),
                       let letterString = Range(letterRange, in: result).map({ String(result[$0]) }),
                       let fullRangeInString = Range(fullRange, in: result) {
                        let replacement = punctuationString + letterString.uppercased()
                        result.replaceSubrange(fullRangeInString, with: replacement)
                    }
                }
            }
        }
        
        // Capitalize "I" when standalone
        result = result.replacingOccurrences(of: "\\bi\\b", with: "I", options: .regularExpression)
        
        // Capitalize proper nouns (basic list)
        let properNouns = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
                          "january", "february", "march", "april", "may", "june", "july", "august", 
                          "september", "october", "november", "december"]
        
        for noun in properNouns {
            let pattern = "\\b" + noun + "\\b"
            result = result.replacingOccurrences(of: pattern, with: noun.capitalized, options: [.regularExpression, .caseInsensitive])
        }
        
        return result
    }
    
    // MARK: - Contraction Fixing
    private static func fixContractions(_ text: String) -> String {
        let contractionFixes = [
    ("\\bcan't\\b", "can't"),
    ("\\bcant\\b", "can't"),
    ("\\bdon't\\b", "don't"),
    ("\\bdont\\b", "don't"),
    ("\\bwon't\\b", "won't"),
    ("\\bwont\\b", "won't"),
    ("\\bisn't\\b", "isn't"),
    ("\\bisnt\\b", "isn't"),
    ("\\baren't\\b", "aren't"),
    ("\\barent\\b", "aren't"),
    ("\\bwasn't\\b", "wasn't"),
    ("\\bwasnt\\b", "wasn't"),
    ("\\bweren't\\b", "weren't"),
    ("\\bwerent\\b", "weren't"),
    ("\\bhasn't\\b", "hasn't"),
    ("\\bhasnt\\b", "hasn't"),
    ("\\bhaven't\\b", "haven't"),
    ("\\bhavent\\b", "haven't"),
    ("\\bhadn't\\b", "hadn't"),
    ("\\bhadnt\\b", "hadn't"),
    ("\\bdidn't\\b", "didn't"),
    ("\\bdidnt\\b", "didn't"),
    ("\\bdoesn't\\b", "doesn't"),
    ("\\bdoesnt\\b", "doesn't"),
    ("\\bshouldn't\\b", "shouldn't"),
    ("\\bshouldnt\\b", "shouldn't"),
    ("\\bcouldn't\\b", "couldn't"),
    ("\\bcouldnt\\b", "couldn't"),
    ("\\bwouldn't\\b", "wouldn't"),
    ("\\bwouldnt\\b", "wouldn't"),
    ("\\bI'm\\b", "I'm"),
    ("\\bIm\\b", "I'm"),
    ("\\bI'm\\b", "I'm"),
    ("\\bI'm\\b", "I'm"),
    ("\\bI'd\\b", "I'd"),
    ("\\bId\\b", "I'd"),
    ("\\bI'll\\b", "I'll"),
    ("\\bIll\\b", "I'll"),
    ("\\bI've\\b", "I've"),
    ("\\bIve\\b", "I've"),
    ("\\byou're\\b", "you're"),
    ("\\byoure\\b", "you're"),
    ("\\byou've\\b", "you've"),
    ("\\byouve\\b", "you've"),
    ("\\byou'll\\b", "you'll"),
    ("\\byoull\\b", "you'll"),
    ("\\byou'd\\b", "you'd"),
    ("\\byoud\\b", "you'd"),
    ("\\bthey're\\b", "they're"),
    ("\\btheyre\\b", "they're"),
    ("\\bthey've\\b", "they've"),
    ("\\btheyve\\b", "they've"),
    ("\\bthey'll\\b", "they'll"),
    ("\\btheyll\\b", "they'll"),
    ("\\bthey'd\\b", "they'd"),
    ("\\btheyd\\b", "they'd"),
    ("\\bwe're\\b", "we're"),
    ("\\bwere\\b", "we're"),
    ("\\bwe've\\b", "we've"),
    ("\\bweve\\b", "we've"),
    ("\\bwe'll\\b", "we'll"),
    ("\\bwell\\b", "we'll"),
    ("\\bwe'd\\b", "we'd"),
    ("\\bwed\\b", "we'd"),
    ("\\bit's\\b", "it's"),
    ("\\bits\\b", "it's"),
    ("\\bthat's\\b", "that's"),
    ("\\bthats\\b", "that's"),
    ("\\bwhat's\\b", "what's"),
    ("\\bwhats\\b", "what's"),
    ("\\bwhere's\\b", "where's"),
    ("\\bwheres\\b", "where's"),
    ("\\bwho's\\b", "who's"),
    ("\\bwhos\\b", "who's"),
    ("\\blet's\\b", "let's"),
    ("\\blets\\b", "let's"),
    ("\\bthat's\\b", "that's"),
    ("\\btheres\\b", "there's"),
    ("\\bthere's\\b", "there's"),
    ("\\bshould've\\b", "should've"),
    ("\\bshouldve\\b", "should've"),
    ("\\bcould've\\b", "could've"),
    ("\\bcouldve\\b", "could've"),
    ("\\bwould've\\b", "would've"),
    ("\\bwouldve\\b", "would've"),
    ("\\bmust've\\b", "must've"),
    ("\\bmustve\\b", "must've"),
    ("\\bI'm not\\b", "I'm not"),
    ("\\bain't\\b", "ain't"),
    ("\\baint\\b", "ain't"),
    ("\\bmight've\\b", "might've"),
    ("\\bmightve\\b", "might've")
        ]
        
        var result = text
        for (pattern, replacement) in contractionFixes {
            result = result.replacingOccurrences(of: pattern, with: replacement, options: [.regularExpression, .caseInsensitive])
        }
        
        return result
    }
    
    // MARK: - Spell Check
    private static func performSpellCheck(_ text: String, language: String) -> String {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        var correctedWords: [String] = []
        
        for word in words {
            let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
            if !cleanWord.isEmpty && isWordMisspelled(cleanWord, language: language) {
                if let suggestion = getBestSpellingSuggestion(for: cleanWord, language: language) {
                    // Preserve punctuation
                    let correctedWord = word.replacingOccurrences(of: cleanWord, with: suggestion)
                    correctedWords.append(correctedWord)
                } else {
                    correctedWords.append(word)
                }
            } else {
                correctedWords.append(word)
            }
        }
        
        return correctedWords.joined(separator: " ")
    }
    
    // MARK: - Final Formatting Cleanup
    private static func finalFormatCleanup(_ text: String) -> String {
        var result = text
        
        // Remove trailing spaces
        result = result.trimmingCharacters(in: .whitespaces)
        
        // Fix double punctuation
        result = result.replacingOccurrences(of: "\\.{2,}", with: ".", options: .regularExpression)
        result = result.replacingOccurrences(of: "\\!{2,}", with: "!", options: .regularExpression)
        result = result.replacingOccurrences(of: "\\?{2,}", with: "?", options: .regularExpression)
        
        // Fix comma and period spacing
        result = result.replacingOccurrences(of: ",([A-Za-z])", with: ", $1", options: .regularExpression)
        result = result.replacingOccurrences(of: "\\.([A-Za-z])", with: ". $1", options: .regularExpression)
        
        return result
    }
    
    // MARK: - Enhanced Spell Checking
    private static func getBestSpellingSuggestion(for word: String, language: String) -> String? {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        
        let misspelledRange = checker.rangeOfMisspelledWord(
            in: word,
            range: range,
            startingAt: 0,
            wrap: false,
            language: language
        )
        
        if misspelledRange.location != NSNotFound,
           let guesses = checker.guesses(forWordRange: misspelledRange, in: word, language: language),
           let firstSuggestion = guesses.first {
            return firstSuggestion
        }
        
        return nil
    }
    
    // MARK: - Enhanced Suggestion System
    static func getSpellingSuggestions(for text: String, language: String = "en_US") -> [String] {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        guard let lastWord = words.last, !lastWord.isEmpty else { return [] }
        
        // Clean the word of punctuation for checking
        let cleanWord = lastWord.trimmingCharacters(in: .punctuationCharacters)
        
        var suggestions: [String] = []
        
        // Check common typos first
        if let commonCorrection = commonTypos[cleanWord.lowercased()] {
            suggestions.append(commonCorrection)
        }
        
        // Get spell checker suggestions
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: cleanWord.utf16.count)
        
        let misspelledRange = checker.rangeOfMisspelledWord(
            in: cleanWord,
            range: range,
            startingAt: 0,
            wrap: false,
            language: language
        )
        
        if misspelledRange.location != NSNotFound,
           let guesses = checker.guesses(forWordRange: misspelledRange, in: cleanWord, language: language) {
            suggestions.append(contentsOf: guesses.prefix(maxSuggestions - suggestions.count))
        }
        
        return Array(suggestions.prefix(maxSuggestions))
    }
    
    // MARK: - Smart Text Completion
    static func getSmartCompletions(for text: String) -> [String] {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        guard let lastWord = words.last, lastWord.count >= 2 else { return [] }
        
        // Common word completions
        let completions: [String: [String]] = [
   "th": ["the", "that", "this", "they", "there", "then", "think", "through", "though", "thorough", "theme", "threat", "third", "thanks", "threshold", "theory", "thesis", "thirty", "thrive", "thyroid", "thread", "thistle"],
  "wh": ["what", "when", "where", "which", "why", "who", "while", "whole", "whom", "whose", "whether", "whenever", "whistle", "white", "wheel", "whisper", "whilst", "whittle", "wholesale", "wharf", "wheat"],
  "yo": ["you", "your", "you're", "young", "yours", "yourself", "youth", "yoga", "yodel", "yolk", "yonder", "youthful", "yodeler", "yummy", "yoga‑mat", "yogi", "yoking", "yowling", "yowza", "younger"],
  "ca": ["can", "can't", "call", "came", "case", "carry", "care", "card", "camera", "camp", "cancel", "capture", "carbon", "career", "castle", "catalyst", "category", "caution", "canvas", "capital", "captive"],
  "ha": ["have", "has", "had", "happy", "hand", "hard", "hate", "half", "happen", "handle", "harm", "harbor", "harvest", "hazard", "harmony", "headline", "health", "hearth", "heaven", "haunt", "habitat"],
  "wi": ["with", "will", "would", "without", "within", "win", "wise", "wish", "wings", "winter", "wire", "witch", "wizard", "widen", "wild", "wilderness", "wiring", "withdraw", "witness", "width", "windmill"],
  "be": ["because", "been", "before", "being", "best", "better", "between", "behind", "believe", "beauty", "benefit", "beyond", "begin", "behavior", "beneath", "beside", "belief", "belong", "bench", "behold", "betray"],
  "fr": ["from", "first", "friend", "free", "front", "fresh", "frame", "fruit", "frozen", "frequency", "fragment", "frank", "frame", "fridge", "frost", "fringe", "frugal", "frown", "friction", "frankly", "franklin"],
  "pr": ["please", "probably", "problem", "project", "provide", "program", "process", "profile", "product", "promise", "protect", "private", "protocol", "progress", "property", "prove", "probable", "propose", "province", "prospect", "pride"],
  "st": ["start", "still", "state", "story", "street", "strong", "student", "study", "stop", "strategy", "structure", "studio", "status", "steel", "steep", "steam", "stitch", "storage", "strewn", "sturdy", "stumble"],
  "co": ["could", "come", "company", "course", "continue", "control", "cost", "copy", "cover", "code", "context", "corner", "council", "courage", "counsel", "couple", "counter", "couple", "coupon", "coconut", "collar"],
  "in": ["in", "into", "information", "interest", "include", "instead", "inside", "industry", "income", "initial", "invest", "invite", "insert", "intend", "ingredient", "injury", "inquiry", "insight", "install", "impact", "impulse"],
  "de": ["detail", "develop", "design", "define", "decide", "deliver", "describe", "device", "degree", "debate", "depend", "derive", "dedicate", "decode", "defend", "defuse", "delight", "demand", "denote", "deposit", "desire"],
  "ex": ["example", "experience", "expect", "execute", "extend", "exchange", "exclude", "exit", "external", "extra", "expert", "expand", "examine", "exceed", "excite", "exclude", "excuse", "explore", "export", "express", "extract"],
  "ma": ["make", "many", "matter", "manage", "market", "major", "master", "match", "material", "maximum", "maintain", "manual", "manner", "margin", "marine", "market", "martial", "marvel", "matrix", "mature", "measure"],
  "mi": ["might", "mind", "minute", "miss", "mission", "middle", "million", "mixed", "mirror", "minor", "minimum", "mistake", "similarity", "mighty", "migrate", "mild", "mingle", "mini", "mineral", "minimum", "mirror"],
  "lo": ["look", "long", "local", "lose", "love", "lower", "loan", "logic", "location", "loud", "logo", "loop", "lodge", "lonely", "lollipop", "lorry", "lottery", "lounge", "lotion", "lobby", "locality"],
  "si": ["since", "simple", "similar", "site", "signal", "sign", "situation", "silver", "single", "sincerely", "silence", "silent", "siren", "sizable", "sister", "sizzle", "side", "sigh", "signature", "simplicity", "sibling"],
  "sp": ["special", "specific", "space", "speak", "sport", "supply", "support", "span", "speed", "split", "spill", "spell", "sphere", "spirit", "spite", "sponsor", "spray", "spring", "sprinkle", "splash", "spoil"],
  "su": ["such", "sure", "submit", "supply", "support", "survey", "sustain", "summary", "summer", "subject", "sugar", "suggest", "super", "sudden", "suffer", "suitable", "surface", "surge", "surprise", "surround", "suppress"],
  "po": ["possible", "power", "point", "policy", "position", "positive", "popular", "potential", "pocket", "post", "portfolio", "poverty", "poison", "poetry", "pointer", "pollution", "ponder", "portion", "portable", "portrait", "possess"],
  "re": ["return", "recent", "remember", "require", "response", "result", "review", "recommend", "reduce", "research", "represent", "replace", "refund", "refuse", "regard", "region", "regret", "relate", "release", "remain", "remote"],
  "tr": ["true", "try", "track", "trade", "tree", "trend", "treat", "train", "travel", "truck", "trigger", "trial", "trace", "transfer", "transform", "translate", "transmit", "tribute", "trim", "triumph", "trophy"],
  "un": ["under", "until", "unit", "unique", "union", "unlikely", "unless", "unlike", "unlock", "update", "upload", "understand", "undertake", "undo", "unfold", "uniform", "united", "unload", "uncover", "unusual", "unwind"],
  "en": ["ensure", "enter", "enough", "environment", "energy", "engage", "enable", "enforce", "entire", "engine", "enhance", "enjoy", "enlist", "enrich", "enroll", "enclose", "encounter", "endorse", "endure", "endless", "enemy"]
        ]
        
        let prefix = String(lastWord.prefix(2)).lowercased()
        return completions[prefix] ?? []
    }
    
    // MARK: - Context-Aware Suggestions
    static func getContextualSuggestions(for text: String) -> [String] {
        var suggestions: [String] = []
        
        // Add contractions if appropriate
        if text.lowercased().contains("do not") {
            suggestions.append("don't")
        }
        if text.lowercased().contains("can not") {
            suggestions.append("can't")
        }
        if text.lowercased().contains("will not") {
            suggestions.append("won't")
        }
        
        // Add common phrase completions
        let lastWords = text.components(separatedBy: .whitespacesAndNewlines).suffix(2).joined(separator: " ").lowercased()
        
        let phraseCompletions = [
       "thank you": ["very much", "so much", "for", "for your help", "for being here", "for understanding", "for everything", "for your support", "for your time", "for listening", "for the update", "for sharing", "for the feedback", "for your patience", "for your generosity", "for your consideration", "for caring", "for your dedication", "for the opportunity", "for responding"],
  "I am": ["going", "sorry", "happy", "excited", "grateful", "here", "uncertain", "thrilled", "confident", "hopeful", "concerned", "overwhelmed", "relieved", "ready", "prepared", "available", "incredibly busy", "on track", "feeling better", "at peace"],
  "how are": ["you", "you doing", "things", "you feeling", "you holding up", "you today", "you lately", "your day going", "you this morning", "things on your end", "you this week", "you so far", "you handling that", "you coping", "you doing these days"],
  "what do": ["you think", "you want", "you mean", "you suggest", "you recommend", "you feel", "you make of this", "you expect", "you plan", "you have in mind", "you intend", "you propose", "you need", "you decide", "you see as next"],
  "I would": ["like", "love", "prefer", "appreciate", "suggest", "recommend", "advise", "enjoy", "encourage", "welcome", "be grateful", "ask", "value", "hope", "request"],
  "can you": ["help me", "tell me", "explain", "share", "clarify", "show me", "provide", "offer", "give", "let me know", "confirm", "point out", "suggest", "walk me through", "send me"],
  "let me": ["know", "see", "show you", "help you", "explain", "ask you", "offer", "guide you", "share", "take a look", "update you", "reach out", "check in", "know your thoughts", "confirm"],
  "I feel": ["that", "like", "worried", "excited", "confident", "anxious", "happy", "sad", "uncertain", "overwhelmed", "relieved", "curious", "hesitant", "optimistic", "inspired"],
  "I think": ["that", "we", "you", "this", "about", "we should", "we could", "it might", "it seems", "therefore", "it would", "it's best", "perhaps we", "I might", "we need to"],
  "it is": ["important", "necessary", "possible", "clear", "worthwhile", "difficult", "easy", "interesting", "urgent", "optional", "recommended", "wise", "logical", "time to", "your responsibility"],
  "we need": ["to", "more time", "a plan", "clarity", "support", "to discuss", "to decide", "to agree", "to focus", "an update", "resources", "a solution", "to coordinate", "to prioritize", "to act"],
  "let's": ["talk", "meet", "review", "plan", "consider", "explore", "take a break", "work on this", "schedule", "sync up", "move forward", "discuss options", "set goals", "get started", "align"],
  "I'm": ["sorry", "grateful", "happy", "concerned", "on track", "with you", "excited", "available", "open", "ready", "aware", "impressed", "surprised", "focused", "thankful"],
  "you are": ["amazing", "important", "valued", "appreciated", "understood", "supported", "heard", "respected", "welcome", "not alone", "doing great", "incredible", "insightful", "on the right track", "the best"],
  "thank": ["you", "you so much", "you for", "you for your", "you immensely", "you kindly", "you deeply", "you again", "you in advance", "you wholeheartedly", "you sincerely", "you profusely", "you very kindly", "you genuinely", "you always"],
  "please let": ["me know", "me know if", "me know when", "me know what", "me know your", "me know how", "me know where", "me know why", "me know details", "me know changes", "me know updates", "me know options", "me know availability", "me know timing", "me know thoughts"],
  "see you": ["soon", "later", "tomorrow", "at the meeting", "this afternoon", "next week", "online", "in a bit", "this evening", "on Friday", "next month", "around", "on Zoom", "at the event", "for the demo"],
  "looking forward": ["to it", "to hearing", "to seeing", "to working", "to collaborating", "to learning", "to discussing", "to our meeting", "to your response", "to the event", "to feedback", "to making progress", "to the next steps", "to continuing", "to that conversation"],
  "as soon as": ["possible", "you can", "you're ready", "we can", "you're available", "you like", "you prefer", "you hear", "it completes", "we decide", "we confirm", "you get back", "you finish", "you arrive", "you see fit"],
  "if you": ["want", "need", "have time", "agree", "can", "prefer", "feel comfortable", "wish", "decide", "think it's okay", "see value", "have questions", "see fit", "require", "plan to"],
  "just": ["checking in", "letting you know", "a reminder", "to say", "to update you", "to ask", "to confirm", "to share", "to ensure", "to highlight", "to double‑check", "to follow up", "to touch base", "to nudge", "to confirm receipt"],
  "I appreciate": ["your help", "your support", "your feedback", "your patience", "your time", "your understanding", "your input", "your efforts", "your willingness", "your cooperation", "your honesty", "your dedication", "your perspective", "your partnership", "your generosity"],
  "looking at": ["this", "that", "the issue", "our plan", "the data", "the schedule", "the proposal", "the report", "the results", "the summary", "the numbers", "the feedback", "the email", "the chart", "the findings"],
  "as we": ["discussed", "planned", "agreed", "decided", "reviewed", "considered", "outlined", "mentioned", "noted", "determined", "established", "prepared", "concluded", "forecasted", "highlighted"],
  "before we": ["proceed", "move on", "decide", "continue", "finalize", "confirm", "start", "commit", "sign off", "close", "agree", "advance", "execute", "address", "evaluate"],
  "I'm looking": ["forward to", "into", "at", "for", "to hearing", "to seeing", "into that", "into working", "into trying", "into reviewing", "into exploring", "into measuring", "into engaging", "into participating", "into managing"],
  "we'll": ["see", "discuss", "plan", "review", "address", "meet", "get back", "follow up", "determine", "revisit", "align", "schedule", "confirm", "evaluate", "start"],
  "feel free": ["to reach out", "to ask", "to connect", "to share", "to suggest", "to propose", "to explore", "to discuss", "to email", "to call", "to ping me", "to drop a line", "to grab coffee", "to stop by", "to schedule"],
  "here's": ["what", "an update", "a summary", "the plan", "the proposal", "the overview", "the agenda", "the details", "the schedule", "the draft", "the report", "the outline", "the calculation", "the timeline", "the link"],
  "to ensure": ["clarity", "alignment", "success", "accuracy", "agreement", "understanding", "compliance", "quality", "consistency", "safety", "timeliness", "efficiency", "coverage", "security", "continuity"],
  "in order to": ["help", "improve", "address", "resolve", "prepare", "ensure", "optimize", "facilitate", "streamline", "complete", "enhance", "support", "validate", "coordinate", "mitigate"],
  "let us": ["know", "see", "discuss", "consider", "plan", "talk", "review", "explore", "evaluate", "determine", "confirm", "coordinate", "align", "finalize", "approve"],
  "don't hesitate": ["to ask", "to reach out", "to let me know", "to contact me", "to share", "to suggest", "to clarify", "to provide feedback", "to drop a note", "to propose", "to get in touch", "to speak up", "to message", "to follow up", "to call"],
  "I'm aware": ["that", "of the", "of your", "of this", "of how", "of the fact", "of these", "of some", "of our", "of the challenges", "of the importance", "of the deadline", "of your concerns", "of potential issues", "of the situation"],
  "based on": ["that", "the data", "the feedback", "our discussion", "your input", "the findings", "this analysis", "the report", "recent trends", "the results", "previous experience", "our goals", "market research", "the survey", "the performance"]
        ]
        
        for (phrase, completions) in phraseCompletions {
            if lastWords.contains(phrase) {
                suggestions.append(contentsOf: completions)
            }
        }
        
        return suggestions
    }
    
    // MARK: - Advanced Features
    static func isWordMisspelled(_ word: String, language: String = "en_US") -> Bool {
        guard !word.isEmpty else { return false }
        
        // Skip checking words that are likely intentional (URLs, emails, etc.)
        if word.contains("@") || word.contains(".com") || word.contains("http") {
            return false
        }
        
        // Skip checking words with numbers
        if word.rangeOfCharacter(from: .decimalDigits) != nil {
            return false
        }
        
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
    
    // MARK: - Real-time Text Analysis
    static func analyzeAndCorrectText(_ text: String, language: String = "en_US") -> (corrected: String, suggestions: [String]) {
        let correctedText = performAdvancedCorrection(context: text, language: language)
        let suggestions = getSpellingSuggestions(for: text, language: language)
        let completions = getSmartCompletions(for: text)
        let contextual = getContextualSuggestions(for: text)
        
        let allSuggestions = Array(Set(suggestions + completions + contextual).prefix(maxSuggestions))
        
        return (corrected: correctedText, suggestions: allSuggestions)
    }
}
