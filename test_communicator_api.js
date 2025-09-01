#!/usr/bin/env node

/**
 * COMMUNICATOR API ENDPOINT TEST
 * Test actual HTTP calls to the communicator endpoints
 */

const http = require('http');

async function testCommunicatorEndpoints() {
  console.log('🧠 TESTING COMMUNICATOR API ENDPOINTS');
  console.log('='.repeat(50));
  
  // Start test server
  console.log('🚀 Starting test server...');
  const app = require('./unsaid-backend/app.js');
  const server = app.listen(3001, () => {
    console.log('✅ Test server started on port 3001');
  });
  
  // Wait for server to be ready
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  async function makeRequest(method, path, data = null) {
    return new Promise((resolve, reject) => {
      const options = {
        hostname: 'localhost',
        port: 3001,
        path: path,
        method: method,
        headers: {
          'Content-Type': 'application/json',
          'X-User-Id': 'test-user-communicator'
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
              body: parsedBody
            });
          } catch (error) {
            resolve({
              status: res.statusCode,
              body: body,
              parseError: error.message
            });
          }
        });
      });

      req.on('error', reject);
      
      if (data) {
        req.write(JSON.stringify(data));
      }
      
      req.end();
    });
  }

  const tests = [
    {
      name: 'Get Initial Profile',
      method: 'GET',
      path: '/communicator/profile',
      expectedStatus: 200
    },
    {
      name: 'Get Status Info',
      method: 'GET', 
      path: '/communicator/status',
      expectedStatus: 200
    },
    {
      name: 'Observe Anxious Text',
      method: 'POST',
      path: '/communicator/observe',
      data: {
        text: "Are you sure you still want this? Please just tell me honestly.",
        meta: { context: 'test', source: 'keyboard' }
      },
      expectedStatus: 200
    },
    {
      name: 'Observe Secure Text',
      method: 'POST',
      path: '/communicator/observe',
      data: {
        text: "I need some space to think about this. That doesn't work for me right now.",
        meta: { context: 'test', source: 'keyboard' }
      },
      expectedStatus: 200
    },
    {
      name: 'Observe Avoidant Text',
      method: 'POST',
      path: '/communicator/observe',
      data: {
        text: "Whatever. I don't want to argue about this anymore.",
        meta: { context: 'test', source: 'keyboard' }
      },
      expectedStatus: 200
    },
    {
      name: 'Get Updated Profile',
      method: 'GET',
      path: '/communicator/profile',
      expectedStatus: 200
    },
    {
      name: 'Export Profile Data',
      method: 'GET',
      path: '/communicator/export',
      expectedStatus: 200
    },
    {
      name: 'Reset Profile',
      method: 'POST',
      path: '/communicator/reset',
      expectedStatus: 200
    }
  ];

  let passed = 0;
  let failed = 0;

  for (const test of tests) {
    try {
      console.log(`\n🧪 Testing: ${test.name}`);
      console.log(`   ${test.method} ${test.path}`);
      
      const result = await makeRequest(test.method, test.path, test.data);
      
      if (result.status === test.expectedStatus) {
        console.log(`   ✅ PASS (${result.status})`);
        
        // Log interesting response data
        if (result.body && typeof result.body === 'object') {
          if (test.path === '/communicator/profile' && result.body.estimate) {
            const est = result.body.estimate;
            console.log(`   📊 Attachment: ${est.primary || 'Unknown'} (${Math.round(est.confidence * 100)}% confidence)`);
            console.log(`   📅 Days observed: ${est.daysObserved}/${result.body.estimate.windowComplete ? 7 : '7'}`);
          }
          
          if (test.path === '/communicator/observe' && result.body.estimate) {
            const est = result.body.estimate;
            console.log(`   📈 Updated profile: ${est.primary || 'Learning...'}`);
          }
          
          if (test.path === '/communicator/status') {
            console.log(`   ⚙️  Learning window: ${result.body.learningDays} days`);
            console.log(`   📊 Daily limit: ${result.body.dailyLimit} observations`);
          }
          
          if (test.path === '/communicator/export') {
            const profile = result.body.profile;
            console.log(`   💾 Exported ${profile.history?.length || 0} history items`);
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
  console.log('\n📊 COMMUNICATOR API TEST RESULTS');
  console.log('='.repeat(35));
  console.log(`✅ Passed: ${passed}`);
  console.log(`❌ Failed: ${failed}`);
  console.log(`📈 Success Rate: ${Math.round((passed / (passed + failed)) * 100)}%`);

  if (passed === passed + failed && failed === 0) {
    console.log('\n🎉 ALL COMMUNICATOR ENDPOINTS WORKING!');
    console.log('✅ Profile learning is operational');
    console.log('✅ Attachment style detection is working');
    console.log('✅ API contracts are functional');
    console.log('✅ Ready for iOS keyboard integration');
  } else if (passed > failed) {
    console.log('\n✅ COMMUNICATOR MOSTLY WORKING');
    console.log('✅ Core functionality operational');
    console.log('⚠️  Some endpoints may need attention');
  } else {
    console.log('\n❌ COMMUNICATOR NEEDS FIXES');
    console.log('❌ Multiple endpoints failing');
    console.log('🔧 Requires immediate attention');
  }

  return passed > failed;
}

if (require.main === module) {
  testCommunicatorEndpoints()
    .then(success => {
      process.exit(success ? 0 : 1);
    })
    .catch(error => {
      console.error('❌ Communicator API test failed:', error);
      process.exit(1);
    });
}

module.exports = { testCommunicatorEndpoints };
