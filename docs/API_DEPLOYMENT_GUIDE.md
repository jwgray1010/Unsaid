# Unsaid API Deployment Configuration

## Vercel Deployment

Your API is configured to deploy to: **`https://api.myunsaidapp.com`**

### API Endpoints Available:
- `POST https://api.myunsaidapp.com/api/suggestions` - Generate therapeutic suggestions
- `GET/POST https://api.myunsaidapp.com/api/trial-status` - Manage user trials

## iOS App Configuration

The iOS app has been configured to connect to your Vercel API:

### Main App (Runner/Info.plist):
```xml
<key>UNSAID_API_BASE_URL</key>
<string>https://api.myunsaidapp.com</string>
<key>UNSAID_API_KEY</key>
<string>your-api-key-here</string>
```

### Keyboard Extension (UnsaidKeyboard/Info.plist):
```xml
<key>UNSAID_API_BASE_URL</key>
<string>https://api.myunsaidapp.com</string>
<key>UNSAID_API_KEY</key>
<string>your-api-key-here</string>
```

### Network Security:
Both app targets allow HTTPS connections to `api.myunsaidapp.com` in NSAppTransportSecurity.

## Data Flow:
1. **User types in keyboard** → `KeyboardController.swift`
2. **Text analysis** → `ToneSuggestionCoordinator.swift`
3. **API call** → `https://api.myunsaidapp.com/api/suggestions`
4. **Backend processing** → `suggestions.js` → `SuggestionService.js`
5. **NLP analysis** → Uses `context_classifiers.json`, `tone_patterns.json`, etc.
6. **Returns** → Therapeutic suggestions to iOS app
7. **UI update** → Keyboard shows suggestions and tone indicators

## Deployment Steps:
1. Deploy to Vercel (should point to `api.myunsaidapp.com`)
2. Update `UNSAID_API_KEY` in both Info.plist files with your actual API key
3. Build and test iOS app

## File Structure:
```
Unsaid/
├── vercel.json                 # Vercel deployment config
├── package.json               # Node.js dependencies
├── Unsaid/ios/
│   ├── api/
│   │   ├── suggestions.js     # Main API endpoint
│   │   └── trial-status.js    # Trial management
│   ├── services/
│   │   ├── SuggestionService.js   # Core NLP logic
│   │   ├── spacyservice.js        # Text processing
│   │   └── TrialManager.js        # Trial management
│   ├── data/
│   │   ├── context_classifiers.json
│   │   ├── tone_patterns.json
│   │   ├── tone_triggerwords.json
│   │   └── therapy_advice.json
│   └── UnsaidKeyboard/
│       ├── ToneSuggestionCoordinator.swift  # iOS API client
│       └── KeyboardController.swift         # Main keyboard logic
```
