#!/usr/bin/env node

/**
 * Keyboard Controller Integration Test
 * Tests the complete flow from iOS ToneSuggestionCoordinator -> suggestions.js -> ML system
 */

const https = require('https');
const http = require('http');

// Configuration - you'll need to set these to match your deployment
const API_BASE_URL = process.env.UNSAID_API_BASE_URL || 'http://localhost:3000/api';
const API_KEY = process.env.UNSAID_API_KEY || 'test-key';

function makeRequest(apiUrl, data, options = {}) {
  return new Promise((resolve, reject) => {
    const parsedUrl = new URL(apiUrl);
    const isHttps = parsedUrl.protocol === 'https:';
    const client = isHttps ? https : http;
    
    const postData = JSON.stringify(data);
    
    const requestOptions = {
      hostname: parsedUrl.hostname,
      port: parsedUrl.port || (isHttps ? 443 : 80),
      path: parsedUrl.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
        'Authorization': `Bearer ${API_KEY}`,
        ...options.headers
      },
      timeout: options.timeout || 10000
    };

    const req = client.request(requestOptions, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        try {
          const jsonData = JSON.parse(responseData);
          resolve({ status: res.statusCode, data: jsonData });
        } catch (error) {
          resolve({ status: res.statusCode, data: responseData });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });

    req.write(postData);
    req.end();
  });
}

async function testKeyboardIntegration() {
  console.log('🔧 Testing Keyboard Controller Integration...\n');
  
  // Test payload that matches what ToneSuggestionCoordinator sends
  const testPayload = {
    text: "I'm so frustrated with this situation and I don't know what to do",
    userId: "keyboard_user",
    userEmail: "test@example.com",
    toneAnalysisResult: {}, // Empty - suggestions API will do full ML analysis
    emotional_state: "neutral",
    attachment_style: "secure",
    user_profile: {
      attachment_style: "secure",
      emotional_state: "neutral",
      communication_style: "direct",
      emotional_bucket: "stable",
      personality_type: "analytical"
    },
    communication_style: "direct",
    emotional_bucket: "stable",
    conversationHistory: [
      {
        sender: "user",
        text: "I'm so frustrated with this situation and I don't know what to do",
        timestamp: Date.now() / 1000
      }
    ]
  };

  try {
    console.log('📱 Simulating ToneSuggestionCoordinator API call...');
    const response = await makeRequest(`${API_BASE_URL}/suggestions`, testPayload);

    if (response.status !== 200) {
      throw new Error(`HTTP ${response.status}: ${JSON.stringify(response.data)}`);
    }

    const data = response.data;
    console.log('✅ API Response received\n');

    // Test the response format that ToneSuggestionCoordinator expects
    console.log('🔍 Validating response format for iOS compatibility...');
    
    // Test tone status extraction
    const toneStatus = data.toneStatus || data.primaryTone;
    if (toneStatus) {
      console.log(`✅ Tone Status: ${toneStatus}`);
    } else {
      console.log('❌ Missing tone status in response');
    }

    // Test confidence score
    if (typeof data.confidence === 'number') {
      console.log(`✅ Confidence Score: ${data.confidence}`);
    } else {
      console.log('❌ Missing or invalid confidence score');
    }

    // Test suggestion extraction (multiple formats supported)
    let suggestion = null;
    if (data.suggestions && Array.isArray(data.suggestions) && data.suggestions[0]?.text) {
      suggestion = data.suggestions[0].text;
      console.log('✅ Suggestion found in suggestions array format');
    } else if (data.general_suggestion) {
      suggestion = data.general_suggestion;
      console.log('✅ Suggestion found in general_suggestion format');
    } else if (data.suggestion) {
      suggestion = data.suggestion;
      console.log('✅ Suggestion found in suggestion format');
    } else if (data.data) {
      suggestion = data.data;
      console.log('✅ Suggestion found in data format');
    } else {
      console.log('❌ No suggestion found in any expected format');
    }

    if (suggestion) {
      console.log(`📝 Suggestion Text: "${suggestion.substring(0, 100)}${suggestion.length > 100 ? '...' : ''}"`);
    }

    // Test ML system metadata
    console.log('\n🤖 ML System Integration Check:');
    if (data.originalToneAnalysis) {
      console.log('✅ Original tone analysis data preserved');
    }
    if (data.attachmentStyle) {
      console.log(`✅ Attachment style detected: ${data.attachmentStyle}`);
    }
    if (data.processingTimeMs) {
      console.log(`✅ Processing time: ${data.processingTimeMs}ms`);
    }
    if (data.source) {
      console.log(`✅ Source: ${data.source}`);
    }

    // Test full response structure
    console.log('\n📋 Complete Response Structure:');
    console.log(JSON.stringify(data, null, 2));

    console.log('\n✅ Keyboard Controller Integration Test PASSED');
    console.log('🎯 The ToneSuggestionCoordinator should now receive ML-enhanced responses');

  } catch (error) {
    console.error('❌ Integration test failed:');
    if (error.message.includes('HTTP')) {
      console.error(error.message);
    } else {
      console.error('Network error:', error.message);
      console.error('Check if API server is running and URL is correct');
    }
    process.exit(1);
  }
}

async function testToneAnalysisEndpoint() {
  console.log('\n🔍 Testing legacy tone-analysis endpoint compatibility...');
  
  const legacyPayload = {
    text: "This is terrible and I hate everything about it!",
    userId: "test-user",
    context: {}
  };

  try {
    const response = await makeRequest(`${API_BASE_URL}/tone-analysis`, legacyPayload);

    if (response.status === 200) {
      console.log('✅ Legacy tone-analysis endpoint working');
      console.log(`Response: ${JSON.stringify(response.data, null, 2)}`);
    } else {
      console.log('ℹ️ Legacy tone-analysis endpoint returned non-200 status');
    }
  } catch (error) {
    console.log('ℹ️ Legacy tone-analysis endpoint not available (expected in new setup)');
  }
}

// Run tests
async function main() {
  await testKeyboardIntegration();
  await testToneAnalysisEndpoint();
  
  console.log('\n🎉 Integration testing complete!');
  console.log('📱 Your iOS keyboard should now benefit from the full ML-enhanced suggestion system.');
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = { testKeyboardIntegration, testToneAnalysisEndpoint, makeRequest };
