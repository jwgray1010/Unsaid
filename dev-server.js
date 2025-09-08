const http = require('http');
const url = require('url');
const path = require('path');

// Simple development server for testing API endpoints
const PORT = 3000;

// Import API handlers (we'll simulate them for testing)
async function handleRequest(req, res) {
  const { pathname, query } = url.parse(req.url, true);
  
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, x-user-id');
  
  if (req.method === 'OPTIONS') {
    res.statusCode = 200;
    res.end();
    return;
  }

  // Parse request body
  let body = '';
  req.on('data', chunk => {
    body += chunk.toString();
  });

  req.on('end', async () => {
    try {
      const requestData = body ? JSON.parse(body) : {};
      
      // Route to appropriate handler
      if (pathname === '/api/v1/health') {
        handleHealth(req, res);
      } else if (pathname === '/api/v1/tone') {
        handleTone(req, res, requestData);
      } else if (pathname === '/api/v1/suggestions') {
        handleSuggestions(req, res, requestData);
      } else {
        res.statusCode = 404;
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify({ error: 'Endpoint not found' }));
      }
    } catch (error) {
      res.statusCode = 400;
      res.setHeader('Content-Type', 'application/json');
      res.end(JSON.stringify({ error: 'Invalid JSON' }));
    }
  });
}

function handleHealth(req, res) {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  }));
}

function handleTone(req, res, data) {
  console.log('🎭 Tone analysis request:', data.text);
  
  // Simulate tone analysis based on text content
  const text = (data.text || '').toLowerCase();
  let tone = 'neutral';
  let confidence = 0.75;
  let emotionalIndicators = ['neutral'];

  // Simple rule-based tone detection for testing
  if (text.includes('frustrated') || text.includes('angry') || text.includes('sick of') || text.includes('tired of')) {
    tone = 'alert';
    confidence = 0.9;
    emotionalIndicators = ['anger', 'frustration'];
  } else if (text.includes('worried') || text.includes('anxious') || text.includes('maybe') || text.includes('great,') || text.includes('sure,')) {
    tone = 'caution';
    confidence = 0.85;
    emotionalIndicators = ['anxiety', 'uncertainty'];
  } else if (text.includes('appreciate') || text.includes('thank') || text.includes('please review')) {
    tone = 'clear';
    confidence = 0.8;
    emotionalIndicators = ['gratitude', 'positivity'];
  }

  const response = {
    success: true,
    tone,
    confidence,
    analysis: {
      primaryTone: tone,
      emotionalIndicators,
      textMetrics: {
        wordCount: data.text ? data.text.split(' ').length : 0,
        sentenceCount: data.text ? data.text.split(/[.!?]+/).length : 0
      }
    },
    meta: {
      analysisTime: 120,
      source: 'dev_server'
    }
  };

  console.log('📤 Tone response:', tone, 'confidence:', confidence);
  
  res.statusCode = 200;
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(response));
}

function handleSuggestions(req, res, data) {
  console.log('💡 Suggestions request:', data.text);
  
  const text = data.text || '';
  let rewrite = text;
  let advice = 'Your message is clear and appropriate for the context.';

  // Simple suggestion logic for testing
  if (text.toLowerCase().includes('frustrated') || text.toLowerCase().includes('sick of')) {
    rewrite = "I'm feeling frustrated about this situation. Could we discuss how to handle this better going forward?";
    advice = "Consider expressing your feelings more directly while staying calm. This helps the other person understand your perspective better.";
  } else if (text.toLowerCase().includes('worried') || text.toLowerCase().includes('maybe')) {
    rewrite = "I'd like to discuss this with you. When would be a good time to talk?";
    advice = "Try being more direct about your needs. Confident communication often gets better results than tentative language.";
  } else if (text.toLowerCase().includes('great,') || text.toLowerCase().includes('sure,')) {
    rewrite = "I have some concerns about this approach. Could we discuss alternative options?";
    advice = "Direct communication about your concerns is more effective than passive responses.";
  }

  const response = {
    success: true,
    rewrite,
    advice,
    extras: {
      toneStatus: 'processed',
      confidence: 0.87,
      suggestions: [
        {
          text: rewrite,
          type: 'rewrite',
          confidence: 0.87
        }
      ]
    },
    meta: {
      processingTime: 340,
      source: 'dev_server'
    }
  };

  console.log('📤 Suggestions response generated');
  
  res.statusCode = 200;
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(response));
}

const server = http.createServer(handleRequest);

server.listen(PORT, () => {
  console.log(`🚀 Development server running on http://localhost:${PORT}`);
  console.log('📋 Available endpoints:');
  console.log('   • POST /api/v1/health');
  console.log('   • POST /api/v1/tone');
  console.log('   • POST /api/v1/suggestions');
  console.log('\n✅ Ready for live testing!');
});

server.on('error', (error) => {
  console.error('❌ Server error:', error.message);
});
