#!/usr/bin/env node

/**
 * COMPREHENSIVE BACKEND AUDIT
 * Systematically tests every file, route, service, and configuration
 */

const fs = require('fs');
const path = require('path');

// Audit Results Tracking
const auditResults = {
  files: [],
  services: [],
  routes: [],
  middleware: [],
  config: [],
  errors: [],
  warnings: [],
  summary: {}
};

function logResult(category, item, status, details = null, error = null) {
  const result = {
    category,
    item,
    status, // 'PASS', 'FAIL', 'WARNING'
    details,
    error: error?.message || error,
    timestamp: new Date().toISOString()
  };
  
  auditResults[category].push(result);
  
  const statusIcon = status === 'PASS' ? '✅' : status === 'FAIL' ? '❌' : '⚠️';
  console.log(`${statusIcon} ${category.toUpperCase()}: ${item} - ${status}`);
  if (details) console.log(`   ${details}`);
  if (error) console.log(`   Error: ${error.message || error}`);
}

async function auditFile(filePath, expectedExports = null) {
  try {
    // Check if file exists
    if (!fs.existsSync(filePath)) {
      logResult('files', filePath, 'FAIL', 'File does not exist');
      return false;
    }

    // Check file size (empty files are suspicious)
    const stats = fs.statSync(filePath);
    if (stats.size === 0) {
      logResult('files', filePath, 'WARNING', 'File is empty');
      return false;
    }

    // Try to read and parse file
    const content = fs.readFileSync(filePath, 'utf8');
    
    // Check for basic syntax issues
    if (content.includes('module.exports') && !content.includes('module.exports =') && !content.includes('module.exports.')) {
      logResult('files', filePath, 'WARNING', 'Malformed module.exports');
    }

    // Try to require the file
    delete require.cache[require.resolve(filePath)];
    const module = require(filePath);

    // Check expected exports
    if (expectedExports) {
      for (const exportName of expectedExports) {
        if (!module[exportName] && !module.default?.[exportName]) {
          logResult('files', filePath, 'WARNING', `Missing expected export: ${exportName}`);
        }
      }
    }

    logResult('files', filePath, 'PASS', `${stats.size} bytes, loads successfully`);
    return true;

  } catch (error) {
    logResult('files', filePath, 'FAIL', null, error);
    return false;
  }
}

async function auditMiddleware(middlewarePath) {
  try {
    const middleware = require(middlewarePath);
    
    // Check if it's a function or returns a function
    if (typeof middleware !== 'function' && typeof middleware.default !== 'function') {
      logResult('middleware', middlewarePath, 'WARNING', 'Does not export a function');
      return false;
    }

    // Test middleware function signature
    const fn = typeof middleware === 'function' ? middleware : middleware.default;
    
    // Check if it accepts the right number of parameters
    if (fn.length !== 3 && fn.length !== 4) {
      logResult('middleware', middlewarePath, 'WARNING', `Unexpected parameter count: ${fn.length} (expected 3 or 4)`);
    }

    logResult('middleware', middlewarePath, 'PASS', `Function with ${fn.length} parameters`);
    return true;

  } catch (error) {
    logResult('middleware', middlewarePath, 'FAIL', null, error);
    return false;
  }
}

async function auditRoute(routePath) {
  try {
    const route = require(routePath);
    
    // Check if it's an Express router
    if (!route || typeof route !== 'function') {
      logResult('routes', routePath, 'FAIL', 'Does not export Express router');
      return false;
    }

    // Check if it has routes defined (router.stack exists and has entries)
    if (route.stack && route.stack.length === 0) {
      logResult('routes', routePath, 'WARNING', 'No routes defined');
    }

    logResult('routes', routePath, 'PASS', `Express router with ${route.stack?.length || 'unknown'} routes`);
    return true;

  } catch (error) {
    logResult('routes', routePath, 'FAIL', null, error);
    return false;
  }
}

async function auditService(servicePath, expectedMethods = []) {
  try {
    const service = require(servicePath);
    
    // Check exports
    const exports = Object.keys(service);
    if (exports.length === 0) {
      logResult('services', servicePath, 'WARNING', 'No exports found');
    }

    // Check for expected methods
    for (const method of expectedMethods) {
      if (!service[method]) {
        logResult('services', servicePath, 'WARNING', `Missing expected method: ${method}`);
      }
    }

    // Check if service exports classes or functions
    let hasValidExports = false;
    for (const [name, value] of Object.entries(service)) {
      if (typeof value === 'function' || typeof value === 'object') {
        hasValidExports = true;
        break;
      }
    }

    if (!hasValidExports) {
      logResult('services', servicePath, 'WARNING', 'No valid function or class exports');
    }

    logResult('services', servicePath, 'PASS', `Exports: ${exports.join(', ')}`);
    return true;

  } catch (error) {
    logResult('services', servicePath, 'FAIL', null, error);
    return false;
  }
}

async function auditConfig(configPath) {
  try {
    const config = require(configPath);
    
    if (typeof config !== 'object' && typeof config !== 'function') {
      logResult('config', configPath, 'WARNING', 'Does not export object or function');
    }

    logResult('config', configPath, 'PASS', `Type: ${typeof config}`);
    return true;

  } catch (error) {
    logResult('config', configPath, 'FAIL', null, error);
    return false;
  }
}

async function testEndpointIntegrity() {
  console.log('\n🔍 TESTING ENDPOINT INTEGRITY...\n');

  // Test app.js
  try {
    const app = require('./unsaid-backend/app.js');
    logResult('routes', 'app.js', 'PASS', 'Main app loads successfully');
  } catch (error) {
    logResult('routes', 'app.js', 'FAIL', null, error);
  }

  // Test individual API endpoints
  const apiEndpoints = [
    { path: './unsaid-backend/api/health.js', name: 'Health API' },
    { path: './unsaid-backend/api/tone.js', name: 'Tone API' },
    { path: './unsaid-backend/api/suggestions.js', name: 'Suggestions API' },
    { path: './unsaid-backend/api/trial-status.js', name: 'Trial Status API' },
    { path: './unsaid-backend/api/communicator.js', name: 'Communicator API' }
  ];

  for (const endpoint of apiEndpoints) {
    await auditRoute(endpoint.path);
  }
}

async function testServiceIntegrity() {
  console.log('\n🛠️ TESTING SERVICE INTEGRITY...\n');

  const services = [
    { 
      path: './unsaid-backend/services/spacyservice.js', 
      methods: ['SpacyService'] 
    },
    { 
      path: './unsaid-backend/services/tone-analysis.js', 
      methods: ['createToneAnalyzer', 'MLAdvancedToneAnalyzer'] 
    },
    { 
      path: './unsaid-backend/services/suggestions.js', 
      methods: ['SuggestionsService'] 
    },
    { 
      path: './unsaid-backend/services/communicator_profile.js', 
      methods: ['CommunicatorProfile'] 
    }
  ];

  for (const service of services) {
    await auditService(service.path, service.methods);
  }
}

async function testMiddlewareIntegrity() {
  console.log('\n🔗 TESTING MIDDLEWARE INTEGRITY...\n');

  const middlewares = [
    './unsaid-backend/middleware/cors.js',
    './unsaid-backend/middleware/rateLimiter.js',
    './unsaid-backend/middleware/errorHandler.js',
    './unsaid-backend/middleware/requestLogger.js',
    './unsaid-backend/middleware/jwAuth.js'
  ];

  for (const middleware of middlewares) {
    await auditMiddleware(middleware);
  }
}

async function testConfigIntegrity() {
  console.log('\n⚙️ TESTING CONFIG INTEGRITY...\n');

  const configs = [
    './unsaid-backend/config/logger.js',
    './unsaid-backend/config/metrics.js',
    './unsaid-backend/config/env.js',
    './unsaid-backend/config/cors.js'
  ];

  for (const config of configs) {
    await auditConfig(config);
  }
}

async function testDataFiles() {
  console.log('\n📁 TESTING DATA FILES...\n');

  const dataDir = './unsaid-backend/data';
  const requiredDataFiles = [
    'context_classifier.json',
    'tone_triggerwords.json',
    'therapy_advice.json',
    'intensity_modifiers.json',
    'learning_signals.json'
  ];

  if (!fs.existsSync(dataDir)) {
    logResult('files', dataDir, 'FAIL', 'Data directory does not exist');
    return;
  }

  const dataFiles = fs.readdirSync(dataDir);
  
  for (const file of requiredDataFiles) {
    const filePath = path.join(dataDir, file);
    
    if (!dataFiles.includes(file)) {
      logResult('files', filePath, 'WARNING', 'Required data file missing');
      continue;
    }

    try {
      const content = fs.readFileSync(filePath, 'utf8');
      JSON.parse(content);
      logResult('files', filePath, 'PASS', 'Valid JSON data file');
    } catch (error) {
      logResult('files', filePath, 'FAIL', 'Invalid JSON', error);
    }
  }

  // Check for extra files
  const extraFiles = dataFiles.filter(f => !requiredDataFiles.includes(f) && f.endsWith('.json'));
  for (const file of extraFiles) {
    const filePath = path.join(dataDir, file);
    try {
      const content = fs.readFileSync(filePath, 'utf8');
      JSON.parse(content);
      logResult('files', filePath, 'PASS', 'Additional valid JSON data file');
    } catch (error) {
      logResult('files', filePath, 'WARNING', 'Additional file with invalid JSON', error);
    }
  }
}

async function testDependencies() {
  console.log('\n📦 TESTING DEPENDENCIES...\n');

  try {
    const packageJson = JSON.parse(fs.readFileSync('./unsaid-backend/package.json', 'utf8'));
    const dependencies = { ...packageJson.dependencies, ...packageJson.devDependencies };

    for (const [dep, version] of Object.entries(dependencies)) {
      try {
        require(dep);
        logResult('config', `dependency: ${dep}`, 'PASS', `Version: ${version}`);
      } catch (error) {
        logResult('config', `dependency: ${dep}`, 'FAIL', `Version: ${version}`, error);
      }
    }
  } catch (error) {
    logResult('config', 'package.json', 'FAIL', null, error);
  }
}

async function generateAuditReport() {
  console.log('\n📊 GENERATING AUDIT REPORT...\n');

  const totalTests = Object.values(auditResults).reduce((sum, category) => {
    return sum + (Array.isArray(category) ? category.length : 0);
  }, 0);

  const passedTests = Object.values(auditResults).reduce((sum, category) => {
    if (!Array.isArray(category)) return sum;
    return sum + category.filter(result => result.status === 'PASS').length;
  }, 0);

  const failedTests = Object.values(auditResults).reduce((sum, category) => {
    if (!Array.isArray(category)) return sum;
    return sum + category.filter(result => result.status === 'FAIL').length;
  }, 0);

  const warningTests = Object.values(auditResults).reduce((sum, category) => {
    if (!Array.isArray(category)) return sum;
    return sum + category.filter(result => result.status === 'WARNING').length;
  }, 0);

  auditResults.summary = {
    total: totalTests,
    passed: passedTests,
    failed: failedTests,
    warnings: warningTests,
    successRate: Math.round((passedTests / totalTests) * 100),
    timestamp: new Date().toISOString()
  };

  console.log('=' * 60);
  console.log('🔍 BACKEND AUDIT SUMMARY');
  console.log('=' * 60);
  console.log(`📊 Total Tests: ${totalTests}`);
  console.log(`✅ Passed: ${passedTests}`);
  console.log(`❌ Failed: ${failedTests}`);
  console.log(`⚠️  Warnings: ${warningTests}`);
  console.log(`📈 Success Rate: ${auditResults.summary.successRate}%`);
  console.log('');

  // Category breakdown
  for (const [category, results] of Object.entries(auditResults)) {
    if (!Array.isArray(results) || results.length === 0) continue;
    
    const categoryPassed = results.filter(r => r.status === 'PASS').length;
    const categoryFailed = results.filter(r => r.status === 'FAIL').length;
    const categoryWarnings = results.filter(r => r.status === 'WARNING').length;
    
    console.log(`📁 ${category.toUpperCase()}:`);
    console.log(`   ✅ ${categoryPassed}  ❌ ${categoryFailed}  ⚠️  ${categoryWarnings}`);
  }

  console.log('');

  // Show critical failures
  const criticalFailures = Object.values(auditResults).flat()
    .filter(result => result.status === 'FAIL');

  if (criticalFailures.length > 0) {
    console.log('🚨 CRITICAL FAILURES:');
    criticalFailures.forEach(failure => {
      console.log(`   ❌ ${failure.item}: ${failure.error}`);
    });
    console.log('');
  }

  // Show warnings
  const warnings = Object.values(auditResults).flat()
    .filter(result => result.status === 'WARNING');

  if (warnings.length > 0) {
    console.log('⚠️  WARNINGS:');
    warnings.forEach(warning => {
      console.log(`   ⚠️  ${warning.item}: ${warning.details || warning.error}`);
    });
    console.log('');
  }

  // Overall assessment
  if (auditResults.summary.successRate >= 90) {
    console.log('🎉 OVERALL STATUS: EXCELLENT');
    console.log('   Backend is in excellent condition for production deployment.');
  } else if (auditResults.summary.successRate >= 75) {
    console.log('✅ OVERALL STATUS: GOOD');
    console.log('   Backend is functional with minor issues to address.');
  } else if (auditResults.summary.successRate >= 50) {
    console.log('⚠️  OVERALL STATUS: NEEDS ATTENTION');
    console.log('   Backend has significant issues that should be addressed.');
  } else {
    console.log('❌ OVERALL STATUS: CRITICAL ISSUES');
    console.log('   Backend requires immediate fixes before deployment.');
  }

  return auditResults;
}

async function runComprehensiveAudit() {
  console.log('🔍 STARTING COMPREHENSIVE BACKEND AUDIT');
  console.log('=' * 60);
  console.log('This will test every file, service, route, middleware, and configuration...\n');

  // Set environment
  process.env.NODE_ENV = 'test';

  try {
    await testDataFiles();
    await testDependencies();
    await testConfigIntegrity();
    await testMiddlewareIntegrity();
    await testServiceIntegrity();
    await testEndpointIntegrity();
    
    const results = await generateAuditReport();
    
    // Save detailed results
    fs.writeFileSync('./backend_audit_results.json', JSON.stringify(results, null, 2));
    console.log('📄 Detailed results saved to: backend_audit_results.json');
    
    return results.summary.successRate >= 75;

  } catch (error) {
    console.error('❌ Audit failed:', error);
    return false;
  }
}

if (require.main === module) {
  runComprehensiveAudit()
    .then(success => process.exit(success ? 0 : 1))
    .catch(error => {
      console.error('❌ Audit crashed:', error);
      process.exit(1);
    });
}

module.exports = { runComprehensiveAudit };
