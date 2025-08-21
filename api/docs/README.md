# Unsaid API

This directory contains the Unsaid API serverless functions for Vercel deployment.

## API Endpoints

### Core Endpoints
- `/api/tone-analysis` - Advanced ML-based tone analysis with attachment style integration
- `/api/suggestions` - Generate therapeutic suggestions based on tone analysis
- `/api/trial-status` - Manage user trials and access control

### Endpoint Details

#### POST /api/tone-analysis
Advanced ML-driven tone analysis using 16 JSON feature generators.

**Request Body:**
```json
{
  "text": "I feel frustrated and angry right now",
  "attachmentStyle": "anxious",
  "userId": "user123",
  "context": "relationship"
}
```

**Response:**
```json
{
  "primaryTone": "alert",
  "tone_status": "alert", 
  "confidence": 0.85,
  "attachmentStyle": "anxious",
  "probabilities": {
    "alert": 0.85,
    "caution": 0.10,
    "clear": 0.05
  },
  "features": {
    "textLength": 35,
    "emotionalIntensity": 2.1,
    "conflictSignals": 1
  },
  "advice": [
    {
      "text": "Take a deep breath and remember that your feelings are valid...",
      "confidence": 0.85,
      "category": "emotional-regulation"
    }
  ]
}
```

#### POST /api/suggestions
Generate personalized therapeutic suggestions.

**Request Body:**
```json
{
  "text": "I don't know how to handle this situation",
  "toneAnalysisResult": { /* Optional - will run ML analysis if not provided */ },
  "attachmentStyle": "secure",
  "userId": "user123",
  "context": "general"
}
```

**Response:**
```json
{
  "success": true,
  "suggestions": [
    {
      "text": "Consider taking time to identify your specific feelings...",
      "type": "therapy_suggestion",
      "confidence": 0.8,
      "category": "emotional-expression"
    }
  ],
  "primaryTone": "caution",
  "confidence": 0.75,
  "attachmentStyle": "secure",
  "mlAnalysisUsed": true
}
```

#### GET /api/trial-status
Check user trial status and access permissions.

## Architecture

### ML System Components
- **AdvancedFeatureExtractor**: Converts 16 JSON data files into feature vectors
- **CalibratedEnsemble**: ML-driven tone classification with Logistic + MLP + XGBoost
- **LearningToRankAdviceSelector**: Personalized therapy advice ranking
- **MLAdvancedToneAnalyzer**: Main orchestrator for real-time analysis

### Attachment Style Integration
The system supports four attachment styles with customized therapeutic approaches:
- **Secure**: Standard evidence-based advice
- **Anxious**: Validation-focused with reassurance elements
- **Avoidant**: Encourages emotional engagement while respecting autonomy
- **Disorganized**: Grounding techniques with extra support suggestions

### Data Sources
16 JSON configuration files provide signals for:
- Tone patterns and trigger words
- Context classification
- Intensity modifiers and negation indicators
- Profanity detection and guardrails
- Therapeutic advice templates
- User preferences and weight modifiers

## Deployment

This project is configured for Vercel serverless functions deployment.

### Prerequisites
- Node.js 18+
- Vercel CLI
- Access to Unsaid data files

### Deploy
```bash
vercel --prod
```

### Environment Variables
Set these in your Vercel dashboard:
- `NODE_ENV=production`
- Any API keys for external services

## Development

### Local Testing
```bash
# Test tone analysis
node -e "const ta = require('./tone-analysis.js'); /* test code */"

# Test suggestions  
node -e "const sg = require('./suggestions.js'); /* test code */"
```

### Service Dependencies
- `TrialManager`: Handles user access and trial status
- `SuggestionService`: Processes therapeutic recommendations
- `SpacyService`: NLP processing and tokenization
- ML Services: Feature extraction and tone classification

## API Features

✅ **Real-time tone analysis** with <500ms latency  
✅ **Attachment-aware suggestions** customized by psychological profile  
✅ **ML-driven classification** with 16 data source integration  
✅ **Trial management** with access control  
✅ **Active learning** for continuous model improvement  
✅ **Therapeutic framework** based on evidence-based practices  

## Support

For API issues or integration questions, contact the Unsaid development team.
