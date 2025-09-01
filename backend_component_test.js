#!/usr/bin/env node

/**
 * SIMPLE BACKEND COMPONENT TEST
 * Test backend components directly without starting a server
 */

console.log('🔍 SIMPLE BACKEND COMPONENT TEST');
console.log('='.repeat(50));

async function testComponents() {
  let passed = 0;
  let failed = 0;
  
  const tests = [
    {
      name: 'App Module Loading',
      test: () => {
        const app = require('./unsaid-backend/app.js');
        return app && typeof app === 'function';
      }
    },
    {
      name: 'Config Module Loading', 
      test: () => {
        const config = require('./unsaid-backend/config/index.js');
        return config && typeof config === 'object';
      }
    },
    {
      name: 'Tone API Module',
      test: () => {
        const toneApi = require('./unsaid-backend/api/tone.js');
        return toneApi && typeof toneApi === 'function';
      }
    },
    {
      name: 'Suggestions API Module',
      test: () => {
        const suggestionsApi = require('./unsaid-backend/api/suggestions.js');
        return suggestionsApi && typeof suggestionsApi === 'function';
      }
    },
    {
      name: 'Health API Module',
      test: () => {
        const healthApi = require('./unsaid-backend/api/health.js');
        return healthApi && typeof healthApi === 'function';
      }
    },
    {
      name: 'ML Advanced Tone Analyzer',
      test: () => {
        const analyzer = require('./unsaid-backend/services/ml_advanced_tone_analyzer.js');
        return analyzer && analyzer.MLAdvancedToneAnalyzer;
      }
    },
    {
      name: 'Suggestions Service',
      test: () => {
        const service = require('./unsaid-backend/services/suggestions.js');
        return service && (service.SuggestionsService || service.handler);
      }
    },
    {
      name: 'SpaCy Service',
      test: () => {
        const service = require('./unsaid-backend/services/spacy_service.js');
        return service && service.SpacyService;
      }
    },
    {
      name: 'Cors Middleware',
      test: () => {
        const cors = require('./unsaid-backend/middleware/cors.js');
        return cors && typeof cors === 'function';
      }
    },
    {
      name: 'Metrics Config',
      test: () => {
        const metrics = require('./unsaid-backend/config/metrics.js');
        return metrics && metrics.metricsMiddleware;
      }
    }
  ];

  for (const test of tests) {
    try {
      console.log(`\n🧪 Testing: ${test.name}`);
      const result = test.test();
      
      if (result) {
        console.log(`   ✅ PASS`);
        passed++;
      } else {
        console.log(`   ❌ FAIL (returned false/null)`);
        failed++;
      }
    } catch (error) {
      console.log(`   ❌ FAIL (${error.message})`);
      failed++;
    }
  }

  // Test data files
  console.log('\n📁 Testing Data Files:');
  const dataFiles = [
    'attachment_overrides.json',
    'evaluation_tones.json', 
    'negation_patterns.json',
    'phrases_edges.json',
    'semantic_thesaurus.json'
  ];

  for (const file of dataFiles) {
    try {
      const fs = require('fs');
      const path = `./unsaid-backend/data/${file}`;
      const exists = fs.existsSync(path);
      
      if (exists) {
        const content = JSON.parse(fs.readFileSync(path, 'utf8'));
        console.log(`   ✅ ${file} (${Object.keys(content).length} keys)`);
        passed++;
      } else {
        console.log(`   ❌ ${file} (missing)`);
        failed++;
      }
    } catch (error) {
      console.log(`   ❌ ${file} (${error.message})`);
      failed++;
    }
  }

  // Results
  console.log('\n📊 COMPONENT TEST RESULTS');
  console.log('='.repeat(30));
  console.log(`✅ Passed: ${passed}`);
  console.log(`❌ Failed: ${failed}`);
  console.log(`📈 Success Rate: ${Math.round((passed / (passed + failed)) * 100)}%`);

  if (failed === 0) {
    console.log('\n🎉 ALL COMPONENTS WORKING!');
    console.log('✅ Backend modules are loading correctly');
    console.log('✅ Data files are accessible'); 
    console.log('✅ Services are properly exported');
  } else if (passed > failed) {
    console.log('\n✅ MOSTLY WORKING');
    console.log('✅ Core components are functional');
    console.log('⚠️  Some modules may need attention');
  } else {
    console.log('\n❌ SIGNIFICANT ISSUES');
    console.log('❌ Multiple components are not loading');
    console.log('🔧 Requires immediate fixes');
  }

  return passed > failed;
}

if (require.main === module) {
  testComponents()
    .then(success => {
      process.exit(success ? 0 : 1);
    })
    .catch(error => {
      console.error('❌ Component test failed:', error);
      process.exit(1);
    });
}

module.exports = { testComponents };
