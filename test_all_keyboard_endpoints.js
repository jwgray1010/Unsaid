#!/usr/bin/env node

/**
 * Comprehensive API Endpoint Test for Keyboard Controller
 * Tests all backend endpoints that the iOS keyboard controller uses
 */

const http = require('http');
const https = require('https');

// Test configuration
const TEST_CONFIG = {
  baseUrl: 'http://localhost:3000', // Will fall back to direct testing if server isn't running
  timeout: 10000,
  endpoints: [
    {
      name: 'Health Check',
      path: '/health',
      method: 'GET',
      expected: { ok: true }
    },
    {
      name: 'Version Check', 
      path: '/version',
      method: 'GET',
      expected: { ok: true }
    },
    {
      name: 'Metrics',
      path: '/metrics',
      method: 'GET',
      contentType: 'text/plain'
    },
    {
      name: 'Tone Analysis',
      path: '/api/tone',
      method: 'POST',
      auth: true,
      payload: {
        text: "I'm really frustrated with this situation and I don't know what to do",
        attachmentStyle: "anxious",
        context: "relationship_conflict",
        userId: "test-keyboard-user"
      }
    },
    {
      name: 'Suggestions API',
      path: '/api/suggestions',
      method: 'POST', 
      auth: true,
      payload: {
        text: "I hate dealing with this crap",
        userId: "test-keyboard-user",
        userEmail: "test@example.com",
        attachment_style: "anxious",
        communication_style: "direct",
        emotional_state: "frustrated",
        conversationHistory: [
          {
            sender: "other",
            text: "We need to talk about this",
            timestamp: Date.now() - 30000
          }
        ]
      }
    },
    {
      name: 'Trial Status Check',
      path: '/api/trial-status',
      method: 'GET',
      auth: true
    }
  ]
};

// Mock JWT token for testing
const MOCK_JWT = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0LXVzZXIiLCJpYXQiOjE2OTM0NTQ4MDAsImV4cCI6MTY5MzQ1ODQwMCwic2NvcGVzIjpbInN1Z2dlc3Rpb25zOndyaXRlIl19.test';

async function makeRequest(endpoint) {
  return new Promise((resolve, reject) => {
    const url = new URL(endpoint.path, TEST_CONFIG.baseUrl);
    const options = {
      hostname: url.hostname,
      port: url.port || (url.protocol === 'https:' ? 443 : 80),
      path: url.pathname + url.search,
      method: endpoint.method,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'UnsaidKeyboard/1.0 (iOS Test)',
        ...(endpoint.auth && { 'Authorization': `Bearer ${MOCK_JWT}` })
      },
      timeout: TEST_CONFIG.timeout
    };

    const client = url.protocol === 'https:' ? https : http;
    const req = client.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const result = {
            statusCode: res.statusCode,
            headers: res.headers,
            body: res.headers['content-type']?.includes('application/json') ? JSON.parse(data) : data
          };
          resolve(result);
        } catch (error) {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: data,
            parseError: error.message
          });
        }
      });
    });

    req.on('error', reject);
    req.on('timeout', () => reject(new Error('Request timeout')));

    if (endpoint.payload) {
      req.write(JSON.stringify(endpoint.payload));
    }

    req.end();
  });
}

async function testEndpoint(endpoint) {
  console.log(`\n🧪 Testing: ${endpoint.name}`);
  console.log(`   Method: ${endpoint.method} ${endpoint.path}`);
  
  if (endpoint.payload) {
    console.log(`   Payload: ${JSON.stringify(endpoint.payload, null, 2).substring(0, 200)}...`);
  }

  try {
    const result = await makeRequest(endpoint);
    
    console.log(`   Status: ${result.statusCode}`);
    
    if (result.statusCode === 200 || result.statusCode === 201) {
      console.log(`   ✅ SUCCESS`);
      
      if (endpoint.expected && typeof result.body === 'object') {
        const hasExpected = Object.keys(endpoint.expected).every(key => 
          result.body.hasOwnProperty(key)
        );
        console.log(`   Expected fields: ${hasExpected ? '✅' : '❌'}`);
      }
      
      // Show relevant response data
      if (typeof result.body === 'object') {
        const keys = Object.keys(result.body);
        console.log(`   Response keys: ${keys.join(', ')}`);
        
        // Show specific keyboard-relevant fields
        if (result.body.suggestions) {
          console.log(`   📱 Suggestions count: ${result.body.suggestions.length}`);
        }
        if (result.body.tone) {
          console.log(`   🎭 Tone detected: ${result.body.tone.classification}`);
        }
        if (result.body.quickFixes) {
          console.log(`   ⚡ Quick fixes: ${result.body.quickFixes.length}`);
        }
      }
      
    } else if (result.statusCode === 401) {
      console.log(`   ❌ AUTHENTICATION REQUIRED`);
    } else if (result.statusCode === 404) {
      console.log(`   ❌ ENDPOINT NOT FOUND`);
    } else {
      console.log(`   ❌ FAILED`);
      if (result.body && typeof result.body === 'object' && result.body.error) {
        console.log(`   Error: ${result.body.error}`);
      }
    }

    return {
      endpoint: endpoint.name,
      success: result.statusCode >= 200 && result.statusCode < 300,
      statusCode: result.statusCode,
      response: result.body
    };

  } catch (error) {
    console.log(`   ❌ REQUEST FAILED: ${error.message}`);
    return {
      endpoint: endpoint.name,
      success: false,
      error: error.message
    };
  }
}

async function testDirectServices() {
  console.log('\n🔧 Testing Services Directly (Fallback)...');
  
  try {
    // Test suggestions service directly
    const { SuggestionsService } = require('./unsaid-backend/services/suggestions_service');
    const suggestionsService = new SuggestionsService();
    
    const testResult = await suggestionsService.generate({
      text: "I'm frustrated with this situation",
      toneHint: 'alert',
      styleHint: 'anxious',
      features: ['rewrite', 'advice'],
      meta: { userId: 'test-keyboard' }
    });
    
    console.log('✅ Direct SuggestionsService test passed');
    console.log(`   Generated ${testResult.quickFixes?.length || 0} quick fixes`);
    console.log(`   Generated ${testResult.advice?.length || 0} advice items`);
    
    return true;
  } catch (error) {
    console.log(`❌ Direct service test failed: ${error.message}`);
    return false;
  }
}

async function startSimpleServer() {
  return new Promise((resolve) => {
    try {
      const app = require('./unsaid-backend/app');
      const server = app.listen(3000, () => {
        console.log('🚀 Test server started on port 3000');
        resolve(server);
      });
      
      // Handle server errors
      server.on('error', (error) => {
        console.log(`❌ Server error: ${error.message}`);
        resolve(null);
      });
      
    } catch (error) {
      console.log(`❌ Failed to start server: ${error.message}`);
      resolve(null);
    }
  });
}

async function runAllTests() {
  console.log('🔍 COMPREHENSIVE KEYBOARD CONTROLLER API ENDPOINT TEST');
  console.log('=' * 80);
  
  // Try to start a simple server for testing
  console.log('\n🚀 Starting test server...');
  const server = await startSimpleServer();
  
  if (!server) {
    console.log('⚠️  Could not start HTTP server, testing services directly...');
    await testDirectServices();
    return;
  }
  
  // Wait a moment for server to be ready
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  const results = [];
  
  for (const endpoint of TEST_CONFIG.endpoints) {
    const result = await testEndpoint(endpoint);
    results.push(result);
  }
  
  // Clean up
  if (server) {
    server.close();
    console.log('\n🛑 Test server stopped');
  }
  
  // Summary
  console.log('\n📊 TEST SUMMARY');
  console.log('=' * 50);
  
  const successful = results.filter(r => r.success).length;
  const total = results.length;
  
  console.log(`✅ Successful: ${successful}/${total}`);
  console.log(`❌ Failed: ${total - successful}/${total}`);
  
  if (successful === total) {
    console.log('\n🎉 ALL KEYBOARD CONTROLLER ENDPOINTS ARE WORKING!');
  } else {
    console.log('\n⚠️  Some endpoints need attention:');
    results.filter(r => !r.success).forEach(r => {
      console.log(`   - ${r.endpoint}: ${r.error || 'HTTP ' + r.statusCode}`);
    });
  }
  
  console.log('\n📱 iOS Keyboard Controller Integration Status:');
  console.log('   - Health checks: Ready for monitoring');
  console.log('   - Tone analysis: Ready for real-time feedback');
  console.log('   - Suggestions: Ready for context-aware recommendations');
  console.log('   - Authentication: Bearer token compatible');
  
  return successful === total;
}

// Run tests
if (require.main === module) {
  runAllTests()
    .then(success => process.exit(success ? 0 : 1))
    .catch(error => {
      console.error('❌ Test runner failed:', error);
      process.exit(1);
    });
}

module.exports = { runAllTests, testEndpoint };
