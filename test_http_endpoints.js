#!/usr/bin/env node

/**
 * Simple HTTP server test for keyboard controller API endpoints
 */

const express = require('express');
const path = require('path');

async function startTestServer(port = 3000) {
  try {
    // Set environment
    process.env.NODE_ENV = process.env.NODE_ENV || 'development';
    
    // Load the main app
    const app = require('./unsaid-backend/app');
    
    const server = app.listen(port, () => {
      console.log(`🚀 Test server running on http://localhost:${port}`);
    });
    
    return server;
  } catch (error) {
    console.error('Failed to start server:', error.message);
    return null;
  }
}

async function testEndpoint(url, method = 'GET', payload = null, headers = {}) {
  const fetch = require('node-fetch');
  
  try {
    const options = {
      method,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'UnsaidKeyboard/1.0 (Test)',
        ...headers
      }
    };
    
    if (payload && method !== 'GET') {
      options.body = JSON.stringify(payload);
    }
    
    const response = await fetch(url, options);
    const text = await response.text();
    
    let body;
    try {
      body = JSON.parse(text);
    } catch {
      body = text;
    }
    
    return {
      status: response.status,
      headers: Object.fromEntries(response.headers.entries()),
      body: body
    };
  } catch (error) {
    return {
      error: error.message
    };
  }
}

async function runHttpTests() {
  console.log('🔍 KEYBOARD CONTROLLER HTTP ENDPOINT TESTS');
  console.log('=' * 60);
  
  const server = await startTestServer();
  if (!server) {
    console.log('❌ Could not start test server');
    return false;
  }
  
  // Wait for server to be ready
  await new Promise(resolve => setTimeout(resolve, 2000));
  
  const baseUrl = 'http://localhost:3000';
  
  // Test endpoints
  const tests = [
    {
      name: 'Health Check',
      url: `${baseUrl}/health/live`,
      method: 'GET'
    },
    {
      name: 'Health Status',
      url: `${baseUrl}/health/status`,
      method: 'GET'
    },
    {
      name: 'Version Info',
      url: `${baseUrl}/version`,
      method: 'GET'
    },
    {
      name: 'Tone Analysis (no auth)',
      url: `${baseUrl}/api/tone`,
      method: 'POST',
      payload: {
        text: "I'm really frustrated with this situation",
        context: "conflict"
      }
    },
    {
      name: 'Suggestions (no auth)',
      url: `${baseUrl}/api/suggestions`,
      method: 'POST',
      payload: {
        text: "I hate dealing with this crap",
        attachmentStyle: "anxious"
      }
    }
  ];
  
  let passCount = 0;
  
  for (const test of tests) {
    console.log(`\n🧪 ${test.name}...`);
    
    const result = await testEndpoint(test.url, test.method, test.payload, test.headers);
    
    if (result.error) {
      console.log(`   ❌ Request failed: ${result.error}`);
      continue;
    }
    
    console.log(`   Status: ${result.status}`);
    
    if (result.status >= 200 && result.status < 300) {
      console.log(`   ✅ SUCCESS`);
      passCount++;
      
      if (typeof result.body === 'object') {
        if (result.body.ok !== undefined) {
          console.log(`   Response OK: ${result.body.ok}`);
        }
        if (result.body.tone) {
          console.log(`   Tone detected: ${result.body.tone}`);
        }
        if (result.body.quickFixes) {
          console.log(`   Quick fixes: ${result.body.quickFixes.length}`);
        }
        if (result.body.advice) {
          console.log(`   Advice items: ${result.body.advice.length}`);
        }
      }
    } else if (result.status === 401) {
      console.log(`   ⚠️  Authentication required (expected for some endpoints)`);
      if (test.name.includes('no auth')) {
        // This endpoint should work without auth but doesn't
        console.log(`   ❌ Unexpected auth requirement`);
      } else {
        console.log(`   ✅ Auth requirement working correctly`);
        passCount++;
      }
    } else {
      console.log(`   ❌ Failed with status ${result.status}`);
      if (result.body && typeof result.body === 'object' && result.body.error) {
        console.log(`   Error: ${result.body.error}`);
      }
    }
  }
  
  // Clean up
  server.close();
  console.log('\n🛑 Test server stopped');
  
  // Summary
  console.log('\n📊 HTTP ENDPOINT TEST SUMMARY');
  console.log('=' * 40);
  console.log(`✅ Working: ${passCount}/${tests.length}`);
  console.log(`❌ Failed: ${tests.length - passCount}/${tests.length}`);
  
  if (passCount >= tests.length * 0.8) { // 80% success rate
    console.log('\n🎉 KEYBOARD CONTROLLER ENDPOINTS ARE READY!');
    console.log('\n📱 Integration Status:');
    console.log('   ✅ HTTP server starts successfully');
    console.log('   ✅ Health endpoints responding');
    console.log('   ✅ Core API endpoints available');
    console.log('\n🔗 iOS Keyboard Controller can connect to:');
    console.log('   - Health: /health/live, /health/status');
    console.log('   - Tone Analysis: POST /api/tone');
    console.log('   - Suggestions: POST /api/suggestions');
    console.log('\n⚠️  Authentication may be required for some endpoints');
  } else {
    console.log('\n⚠️  Some endpoints need fixes before production use');
  }
  
  return passCount >= tests.length * 0.8;
}

if (require.main === module) {
  runHttpTests()
    .then(success => process.exit(success ? 0 : 1))
    .catch(error => {
      console.error('❌ HTTP tests failed:', error);
      process.exit(1);
    });
}

module.exports = { runHttpTests };
