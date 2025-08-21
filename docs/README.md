# Unsaid API

Therapeutic communication intelligence API deployed on Vercel.

## 🚀 Quick Deploy

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/jwgray1010/Unsaid)

## 📡 API Endpoints

- **POST** `/api/suggestions` - Generate therapeutic suggestions
- **GET/POST** `/api/trial-status` - Manage user trials

## 🔧 Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
# Required
OPENAI_API_KEY=your_openai_key_here
UNSAID_API_KEY=your_api_key_here

# Optional
ADMIN_USERS=admin,test
```

## 🏗️ Project Structure

```
api/
├── suggestions.js          # Main suggestion endpoint
└── trial-status.js         # Trial management

services/
├── SuggestionService.js    # Core NLP logic
├── spacyservice.js         # Text processing
└── TrialManager.js         # Trial management

data/
├── context_classifiers.json
├── tone_patterns.json
├── tone_triggerwords.json
└── therapy_advice.json

public/
└── index.html              # Static landing page
```

## 🔗 iOS Integration

Configure your iOS app Info.plist:

```xml
<key>UNSAID_API_BASE_URL</key>
<string>https://api.myunsaidapp.com</string>
<key>UNSAID_API_KEY</key>
<string>your-api-key-here</string>
```

## 📖 Documentation

See `API_DEPLOYMENT_GUIDE.md` for detailed setup instructions.

## 🛠️ Local Development

```bash
npm install
npm run dev
```

## 📝 License

MIT License - see LICENSE file for details.
