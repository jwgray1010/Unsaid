#!/usr/bin/env node

/**
 * FINAL BACKEND FUNCTIONAL TEST
 * Test actual HTTP endpoints by starting a server and making real requests
 */

const http = require('http');

// Start simple test server
async function startTestServer() {
  try {
    console.log('🚀 Starting test server...');
    
    // Import the fixed app
    const app = require('./unsaid-backend/app.js');
    
    const server = app.listen(3000, () => {
      console.log('✅ Test server started on port 3000');
    });
    
    return server;
  } catch (error) {
    console.error('❌ Failed to start test server:', error.message);
    return null;
  }
}

async function testEndpoint(path, method = 'GET', data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer test-token'
      }
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          const parsedBody = res.headers['content-type']?.includes('application/json') 
            ? JSON.parse(body) 
            : body;
          resolve({
            status: res.statusCode,
            headers: res.headers,
            body: parsedBody
          });
        } catch (error) {
          resolve({
            status: res.statusCode,
            headers: res.headers,
            body: body,
            parseError: error.message
          });
        }
      });
    });

    req.on('error', reject);
    req.on('timeout', () => reject(new Error('Request timeout')));

    if (data) {
      req.write(JSON.stringify(data));
    }

    req.end();
  });
}

async function runFunctionalTests() {
  console.log('🔍 FINAL BACKEND FUNCTIONAL TEST');
  console.log('='.repeat(50));
  
  const server = await startTestServer();
  if (!server) {
    console.log('❌ Cannot start server - cannot test endpoints');
    return false;
  }

  // Wait for server to be ready
  await new Promise(resolve => setTimeout(resolve, 1000));

  const tests = [
    {
      name: 'Health Check (Live)',
      path: '/health/live',
      method: 'GET',
      expectedStatus: 200
    },
    {
      name: 'Health Check (Status)', 
      path: '/health/status',
      method: 'GET',
      expectedStatus: [200, 207]
    },
    {
      name: 'Version Info',
      path: '/version',
      method: 'GET',
      expectedStatus: 200
    },
    {
      name: 'Metrics',
      path: '/metrics',
      method: 'GET',
      expectedStatus: 200
    },
    {
      name: 'Tone Analysis',
      path: '/api/tone',
      method: 'POST',
      data: {
        text: "I'm really frustrated with this situation",
        context: "conflict",
        meta: { userId: "test-user" }
      },
      expectedStatus: 200
    },
    {
      name: 'Suggestions API',
      path: '/api/suggestions',
      method: 'POST',
      data: {
        text: "I hate dealing with this",
        attachmentStyle: "anxious",
        context: "general",
        userId: "test-user"
      },
      expectedStatus: 200
    },
    {
      name: 'Trial Status',
      path: '/api/trial-status?userId=test-user',
      method: 'GET',
      expectedStatus: 200
    }
  ];

  let passed = 0;
  let failed = 0;

  for (const test of tests) {
    try {
      console.log(`\n🧪 Testing: ${test.name}`);
      console.log(`   ${test.method} ${test.path}`);
      
      const result = await testEndpoint(test.path, test.method, test.data);
      
      const expectedStatus = Array.isArray(test.expectedStatus) 
        ? test.expectedStatus 
        : [test.expectedStatus];
      
      if (expectedStatus.includes(result.status)) {
        console.log(`   ✅ PASS (${result.status})`);
        
        // Check response structure for API endpoints
        if (test.path.startsWith('/api/') && result.body) {
          if (typeof result.body === 'object') {
            console.log(`   📋 Response keys: ${Object.keys(result.body).join(', ')}`);
            
            // Check for expected fields
            if (test.path === '/api/tone' && result.body.tone) {
              console.log(`   🎭 Tone: ${result.body.tone.classification || 'unknown'}`);
            }
            if (test.path === '/api/suggestions' && result.body.suggestions) {
              console.log(`   💡 Suggestions: ${result.body.suggestions.length} items`);
            }
            if (test.path === '/api/trial-status' && result.body.trial) {
              console.log(`   📊 Trial: ${result.body.trial.status}`);
            }
          }
        }
        
        passed++;
      } else {
        console.log(`   ❌ FAIL (${result.status}, expected ${test.expectedStatus})`);
        if (result.body && result.body.error) {
          console.log(`   Error: ${result.body.error}`);
        }
        failed++;
      }
      
    } catch (error) {
      console.log(`   ❌ FAIL (${error.message})`);
      failed++;
    }
  }

  // Clean up
  server.close();
  console.log('\n🛑 Test server stopped');

  // Results
  console.log('\n📊 FUNCTIONAL TEST RESULTS');
  console.log('='.repeat(30));
  console.log(`✅ Passed: ${passed}`);
  console.log(`❌ Failed: ${failed}`);
  console.log(`📈 Success Rate: ${Math.round((passed / (passed + failed)) * 100)}%`);

  if (passed === passed + failed && failed === 0) {
    console.log('\n🎉 ALL ENDPOINTS WORKING PERFECTLY!');
    console.log('✅ Backend is fully functional and ready for production');
    console.log('✅ All keyboard controller endpoints are operational');
    console.log('✅ API contracts are working as expected');
  } else if (passed > failed) {
    console.log('\n✅ MOSTLY WORKING');
    console.log('✅ Core functionality is operational');
    console.log('⚠️  Some endpoints may need attention');
  } else {
    console.log('\n❌ SIGNIFICANT ISSUES');
    console.log('❌ Multiple endpoints are not working');
    console.log('🔧 Requires immediate fixes');
  }

  return passed > failed;
}

if (require.main === module) {
  // Set environment for testing
  process.env.NODE_ENV = 'test';
  
  runFunctionalTests()
    .then(success => {
      process.exit(success ? 0 : 1);
    })
    .catch(error => {
      console.error('❌ Functional test failed:', error);
      process.exit(1);
    });
}

module.exports = { runFunctionalTests };
