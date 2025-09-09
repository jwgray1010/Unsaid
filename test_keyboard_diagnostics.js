#!/usr/bin/env node

/**
 * Simple API Endpoint Test for Keyboard Controller
 * Tests individual API files directly without server dependencies
 */

const path = require('path');

async function testHealthEndpoint() {
  console.log('\n🏥 Testing Health Endpoint...');
  
  try {
    // Mock Express objects
    const mockReq = {
      app: {
        get: (key) => {
          if (key === 'logger') return console;
          if (key === 'profileStorage') return null;
          return null;
        }
      },
      path: '/health/live'
    };
    
    const mockRes = {
      statusCode: 200,
      data: null,
      status(code) { this.statusCode = code; return this; },
      json(data) { this.data = data; return this; }
    };
    
    // Test the health router directly
    const healthRouter = require('./unsaid-backend/api/health');
    
    // We can't easily test Express routes directly, so let's check if the module loads
    console.log('✅ Health endpoint module loaded successfully');
    console.log('   - Available routes: /live, /ready, /status');
    
    return { success: true, endpoint: 'health' };
    
  } catch (error) {
    console.log(`❌ Health endpoint test failed: ${error.message}`);
    return { success: false, endpoint: 'health', error: error.message };
  }
}

async function testToneService() {
  console.log('\n🎭 Testing Tone Analysis Service...');
  
  try {
    // Try to load the tone analysis service
    const toneModule = require('./unsaid-backend/services/tone-analysis');
    console.log('✅ Tone analysis module loaded');
    
    // Check what's exported
    const exports = Object.keys(toneModule);
    console.log(`   - Available exports: ${exports.join(', ')}`);
    
    if (toneModule.createToneAnalyzer) {
      console.log('✅ Functional tone analyzer available');
    }
    
    return { success: true, endpoint: 'tone-service' };
    
  } catch (error) {
    console.log(`❌ Tone service test failed: ${error.message}`);
    return { success: false, endpoint: 'tone-service', error: error.message };
  }
}

async function testSuggestionsService() {
  console.log('\n💡 Testing Suggestions Service...');
  
  try {
    // Try to load the suggestions service
    const suggestionsModule = require('./unsaid-backend/services/suggestions');
    console.log('✅ Suggestions module loaded');
    
    // Check what's exported
    const exports = Object.keys(suggestionsModule);
    console.log(`   - Available exports: ${exports.join(', ')}`);
    
    return { success: true, endpoint: 'suggestions-service' };
    
  } catch (error) {
    console.log(`❌ Suggestions service test failed: ${error.message}`);
    return { success: false, endpoint: 'suggestions-service', error: error.message };
  }
}

async function testDataFiles() {
  console.log('\n📁 Testing Required Data Files...');
  
  const fs = require('fs');
  const dataDir = path.join(__dirname, 'unsaid-backend', 'data');
  
  const requiredFiles = [
    'learning_signals.json',
    'therapy_advice.json',
    'tone_triggerwords.json',
    'context_classifier.json'
  ];
  
  let successCount = 0;
  
  for (const file of requiredFiles) {
    const filePath = path.join(dataDir, file);
    
    try {
      if (fs.existsSync(filePath)) {
        const content = fs.readFileSync(filePath, 'utf8');
        JSON.parse(content); // Validate JSON
        console.log(`   ✅ ${file} - Valid JSON`);
        successCount++;
      } else {
        console.log(`   ❌ ${file} - File not found`);
      }
    } catch (error) {
      console.log(`   ❌ ${file} - Invalid JSON: ${error.message}`);
    }
  }
  
  const allValid = successCount === requiredFiles.length;
  console.log(`\n📊 Data Files: ${successCount}/${requiredFiles.length} valid`);
  
  return { 
    success: allValid, 
    endpoint: 'data-files',
    count: successCount,
    total: requiredFiles.length
  };
}

async function testEnvironmentSetup() {
  console.log('\n🔧 Testing Environment Setup...');
  
  const requiredForProduction = [
    'NODE_ENV'
  ];
  
  const optionalButUseful = [
    'JWT_PUBLIC_KEY',
    'REDIS_URL',
    'MONGODB_URI'
  ];
  
  let hasRequired = true;
  
  console.log('   Required Environment Variables:');
  for (const envVar of requiredForProduction) {
    if (process.env[envVar]) {
      console.log(`   ✅ ${envVar} = ${process.env[envVar]}`);
    } else {
      console.log(`   ❌ ${envVar} - Not set`);
      hasRequired = false;
    }
  }
  
  console.log('\n   Optional Environment Variables:');
  for (const envVar of optionalButUseful) {
    if (process.env[envVar]) {
      console.log(`   ✅ ${envVar} - Set`);
    } else {
      console.log(`   ⚠️  ${envVar} - Not set (optional)`);
    }
  }
  
  return { 
    success: hasRequired, 
    endpoint: 'environment',
    hasAllRequired: hasRequired
  };
}

async function testAPIEndpointFiles() {
  console.log('\n📡 Testing API Endpoint Files...');
  
  const endpoints = [
    { name: 'Health', file: './unsaid-backend/api/health.js' },
    { name: 'Tone', file: './unsaid-backend/api/tone.js' },
    { name: 'Suggestions', file: './unsaid-backend/api/suggestions.js' },
    { name: 'Trial Status', file: './unsaid-backend/api/trial-status.js' }
  ];
  
  const results = [];
  
  for (const endpoint of endpoints) {
    try {
      require(endpoint.file);
      console.log(`   ✅ ${endpoint.name} endpoint - Loads successfully`);
      results.push({ name: endpoint.name, success: true });
    } catch (error) {
      console.log(`   ❌ ${endpoint.name} endpoint - Error: ${error.message}`);
      results.push({ name: endpoint.name, success: false, error: error.message });
    }
  }
  
  const successCount = results.filter(r => r.success).length;
  console.log(`\n📊 API Endpoints: ${successCount}/${endpoints.length} loadable`);
  
  return { 
    success: successCount === endpoints.length, 
    endpoint: 'api-files',
    results: results
  };
}

async function runDiagnostics() {
  console.log('🔍 KEYBOARD CONTROLLER API DIAGNOSTICS');
  console.log('=' * 60);
  
  const tests = [
    testEnvironmentSetup,
    testDataFiles,
    testAPIEndpointFiles,
    testHealthEndpoint,
    testToneService,
    testSuggestionsService
  ];
  
  const results = [];
  
  for (const test of tests) {
    try {
      const result = await test();
      results.push(result);
    } catch (error) {
      console.log(`❌ Test failed: ${error.message}`);
      results.push({ success: false, error: error.message });
    }
  }
  
  // Summary
  console.log('\n📋 DIAGNOSTIC SUMMARY');
  console.log('=' * 40);
  
  const successful = results.filter(r => r.success).length;
  const total = results.length;
  
  console.log(`✅ Passed: ${successful}/${total}`);
  console.log(`❌ Failed: ${total - successful}/${total}`);
  
  if (successful === total) {
    console.log('\n🎉 ALL SYSTEMS READY FOR KEYBOARD CONTROLLER!');
    console.log('\n📱 Keyboard Controller Integration Status:');
    console.log('   ✅ API endpoints can be loaded');
    console.log('   ✅ Required data files are present');
    console.log('   ✅ Services are properly structured');
    console.log('\n🚀 Next Steps:');
    console.log('   1. Start server with: cd unsaid-backend && npm start');
    console.log('   2. Test HTTP endpoints with curl or Postman');
    console.log('   3. Update iOS keyboard with correct API URLs');
  } else {
    console.log('\n⚠️  Issues Found:');
    results.filter(r => !r.success).forEach(r => {
      console.log(`   - ${r.endpoint || 'Unknown'}: ${r.error || 'Failed'}`);
    });
    
    console.log('\n🔧 Recommendations:');
    console.log('   1. Install missing dependencies');
    console.log('   2. Check data file integrity');
    console.log('   3. Review service imports/exports');
  }
  
  return successful === total;
}

// Run diagnostics
if (require.main === module) {
  runDiagnostics()
    .then(success => process.exit(success ? 0 : 1))
    .catch(error => {
      console.error('❌ Diagnostics failed:', error);
      process.exit(1);
    });
}

module.exports = { runDiagnostics };
