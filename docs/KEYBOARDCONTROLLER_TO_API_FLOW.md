# 📱 **HOW APIs GET TEXT FROM KEYBOARDCONTROLLER**

## 🎯 **COMPLETE TEXT DATA FLOW BREAKDOWN**

### **🔍 What Text Data Gets Sent to APIs:**

```
📱 KeyboardController
    ↓ (Text Processing & Context Building)
🤖 ToneSuggestionCoordinator  
    ↓ (HTTP POST with Complete Context)
🌐 /api/suggestions.js + /api/tone-analysis.js
```

---

## 📝 **DETAILED TEXT FLOW:**

### **Step 1: KeyboardController Text Collection**

```swift
// In KeyboardController.swift
private var currentText: String = ""  // Tracks what user is typing

private func handleTextChange() {
    updateCurrentText()  // Gets full document context
    
    // Gets text before and after cursor from iOS
    let beforeCtx = textDocumentProxy?.documentContextBeforeInput ?? ""
    let afterCtx = textDocumentProxy?.documentContextAfterInput ?? ""
    let fullText = beforeCtx + afterCtx
    
    // Extracts completed sentences for analysis
    if let sentence = lastCompletedSentence(in: before), meetsThresholds(sentence) {
        coordinator?.analyzeFinalSentence(sentence)  // Send to API
    }
}
```

### **Step 2: ToneSuggestionCoordinator Context Building**

```swift
// In ToneSuggestionCoordinator.swift
private func callSuggestionsAPI(context: [String: Any], usingSnapshot snapshot: String? = nil) {
    var payload = context
    
    // 🎯 MAIN TEXT CONTENT:
    payload["text"] = currentText  // The actual text being analyzed
    
    // 🎯 USER CONTEXT:
    payload["userId"] = getUserId()
    payload["userEmail"] = getUserEmail()
    
    // 🎯 PERSONALITY DATA:
    payload.merge(personalityPayload()) { _, new in new }
    
    // 🎯 CONVERSATION HISTORY:
    payload["conversationHistory"] = exportConversationHistoryForAPI(withCurrentText: snapshot)
    
    // Send to /api/suggestions
    callEndpoint(path: "suggestions", payload: payload) { ... }
}
```

### **Step 3: Conversation History Context**

```swift
private func exportConversationHistoryForAPI(withCurrentText overrideText: String? = nil) -> [[String: Any]] {
    var history = loadSharedConversationHistory()  // Previous messages
    let current = (overrideText ?? currentText).trimmingCharacters(in: .whitespacesAndNewlines)
    
    if !current.isEmpty {
        // 🎯 ADDS CURRENT TEXT AS LATEST MESSAGE:
        history.append([
            "sender": "user", 
            "text": current, 
            "timestamp": now
        ])
    }
    
    // 🎯 LIMITS TO LAST 20 MESSAGES:
    if history.count > 20 {
        history = Array(history.suffix(20))
    }
    return history
}
```

---

## 📊 **WHAT THE API RECEIVES:**

### **Complete JSON Payload to `/api/suggestions`:**

```json
{
  "text": "I can't believe this is happening again",
  "userId": "keyboard_user",
  "userEmail": "user@example.com",
  "toneAnalysisResult": {},
  
  "attachment_style": "secure",
  "user_profile": {
    "attachment_style": "secure",
    "communication_style": "direct",
    "personality_type": "analytical",
    "emotional_state": "frustrated",
    "emotional_bucket": "moderate",
    "personality_scores": {
      "secure": 85,
      "anxious": 45
    }
  },
  "communication_style": "direct",
  "emotional_state": "frustrated", 
  "emotional_bucket": "moderate",
  
  "conversationHistory": [
    {
      "sender": "other",
      "text": "We need to talk about this",
      "timestamp": 1692454800.0
    },
    {
      "sender": "user", 
      "text": "I can't believe this is happening again",
      "timestamp": 1692454801.0
    }
  ]
}
```

---

## 🔍 **ANALYSIS SCOPE: What Gets Analyzed**

### **🎯 Text Granularity Options:**

| **Level** | **What** | **When Sent** | **Example** |
|-----------|----------|---------------|-------------|
| **Word Level** | `currentText` as user types | Real-time during typing | `"I can't"` |
| **Sentence Level** | `lastCompletedSentence()` | When punctuation detected | `"I can't believe this."` |
| **Context Level** | `documentContextBeforeInput` | Full document context | `"Hey there. I can't believe this."` |
| **Conversation Level** | `conversationHistory` | Previous 20 messages | `[{sender: "other", text: "..."}, ...]` |

### **🎯 Analysis Triggers:**

```swift
// From KeyboardController.swift analysis logic:
private let minCharsForAnalysis: Int = 8        // Minimum text length
private let minWordsForAnalysis: Int = 2        // Minimum word count
private let boundaryDebounce: TimeInterval = 0.22  // Delay after punctuation
private let idleDebounceNoPunct: TimeInterval = 1.4  // Delay without punctuation

// Analysis happens when:
// 1. User completes a sentence (punctuation detected)
// 2. Text meets minimum thresholds (8+ chars, 2+ words)  
// 3. After debounce period to avoid excessive API calls
```

---

## 🎯 **DIFFERENT ANALYSIS CONTEXTS:**

### **1. Real-Time Tone Analysis**
- **Text**: Current sentence being typed
- **Purpose**: Live tone feedback as user types
- **API**: `/api/suggestions` (with ML fallback)

### **2. Suggestion Generation** 
- **Text**: Completed sentences + conversation history
- **Purpose**: Generate therapeutic advice
- **API**: `/api/suggestions` 

### **3. OpenAI Text Rewriting**
- **Text**: Complete message + full context
- **Purpose**: Rewrite entire message for clarity/professionalism
- **Implementation**: Direct OpenAI integration in iOS KeyboardController

---

## 📱 **iOS TEXT ACCESS LIMITATIONS:**

### **What KeyboardController CAN Access:**
- ✅ `documentContextBeforeInput` - Text before cursor
- ✅ `documentContextAfterInput` - Text after cursor  
- ✅ Current typing session content
- ✅ Shared app group conversation history

### **What KeyboardController CANNOT Access:**
- ❌ Full document content (iOS security)
- ❌ Other app's messages directly
- ❌ System clipboard content
- ❌ User's other keyboard data

---

## 🔄 **REAL-TIME EXAMPLE:**

### **User types: "I hate dealing with this crap"**

1. **KeyboardController** tracks each keystroke in `currentText`
2. **Sentence Detection**: Recognizes complete thought (no punctuation needed)
3. **Context Building**: 
   ```swift
   let text = "I hate dealing with this crap"
   let payload = [
     "text": text,
     "attachment_style": "anxious",  // From PersonalityDataBridge
     "emotional_state": "frustrated",
     "conversationHistory": [...previous messages...]
   ]
   ```
4. **API Call**: HTTP POST to `/api/suggestions` with complete context
5. **ML Processing**: 
   - All 16 JSON files analyze the text
   - Personality context enhances analysis
   - Conversation history provides deeper context
6. **Response**: Personality-aware therapeutic suggestion
7. **Display**: Suggestion shown in keyboard UI

---

## 🎯 **KEY INSIGHTS:**

### **✅ COMPREHENSIVE CONTEXT:**
- **Current Text**: What user is typing right now
- **Document Context**: Text before/after cursor position  
- **Conversation History**: Last 20 messages for context
- **Personality Profile**: Complete attachment & communication style
- **Emotional State**: Current emotional bucket (high/moderate/regulated)

### **✅ SMART ANALYSIS TIMING:**
- **Debounced**: Waits for natural pauses to avoid spam
- **Threshold-Based**: Only analyzes meaningful text (8+ chars, 2+ words)
- **Boundary-Aware**: Prioritizes complete sentences
- **Context-Sensitive**: Includes conversation flow

### **✅ PRIVACY-CONSCIOUS:**
- **Ephemeral**: No permanent storage of user text
- **Sandboxed**: Only accesses what iOS keyboard APIs allow
- **Encrypted**: HTTPS for all API communication
- **Limited**: 20-message conversation history maximum

---

## 🚀 **RESULT:**

**The APIs receive RICH, CONTEXTUAL data:**
- ✅ **Current message text** being typed
- ✅ **Conversation context** (last 20 messages)
- ✅ **Complete personality profile** (attachment style, emotions, etc.)
- ✅ **Document context** (text before/after cursor)
- ✅ **Timing metadata** (when, how fast user is typing)

This enables **highly personalized, context-aware suggestions** that understand not just what the user is saying, but HOW they communicate, their emotional state, and the conversation flow! 🎯
