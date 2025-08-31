#!/usr/bin/env node

/**
 * Comprehensive Test Suite for Tone Analysis & Therapy Suggestions
 * 
 * This script tests the suggestions API with multiple text scenarios
 * to validate tone analysis and therapeutic recommendations.
 */

const https = require('https');
const http = require('http');

// Test scenarios with different communication styles and contexts
const testScenarios = [
  {
    name: "Aggressive Communication",
    text: "You never listen to me! I'm sick of always having to repeat myself. Why can't you just do what I asked for once?",
    context: "relationship_conflict",
    expectedTone: "aggressive",
    description: "Testing hostile, demanding language"
  },
  {
    name: "Passive-Aggressive Communication", 
    text: "Fine, whatever you want. I guess my opinion doesn't matter anyway. Thanks for asking me first... oh wait, you didn't.",
    context: "relationship_conflict",
    expectedTone: "passive_aggressive",
    description: "Testing indirect hostility and sarcasm"
  },
  {
    name: "Anxious/Worried Communication",
    text: "I'm really worried about us. I keep thinking something's wrong and I don't know what to do. Are we okay? I need to know we're okay.",
    context: "relationship_anxiety",
    expectedTone: "anxious",
    description: "Testing anxiety and reassurance-seeking"
  },
  {
    name: "Dismissive/Avoidant Communication",
    text: "I don't see what the big deal is. You're overreacting. Can we just move on? I have more important things to worry about.",
    context: "relationship_conflict",
    expectedTone: "dismissive",
    description: "Testing emotional minimization and avoidance"
  },
  {
    name: "Supportive Communication",
    text: "I can see this is really important to you. Thank you for sharing how you feel. How can I support you through this?",
    context: "relationship_support",
    expectedTone: "supportive",
    description: "Testing empathetic and validating language"
  },
  {
    name: "Vulnerable Communication",
    text: "I'm scared to tell you this, but I've been feeling really lonely lately. I miss feeling close to you like we used to.",
    context: "relationship_vulnerability",
    expectedTone: "vulnerable", 
    description: "Testing emotional openness and intimacy"
  },
  {
    name: "Co-parenting Conflict",
    text: "You're being impossible about this schedule. The kids need consistency and you keep changing plans last minute.",
    context: "coparenting_conflict",
    expectedTone: "frustrated",
    description: "Testing co-parenting specific communication"
  },
  {
    name: "Co-parenting Collaboration",
    text: "I think Emma had a rough day at school. Maybe we should both check in with her tonight and see how she's feeling?",
    context: "coparenting_collaboration",
    expectedTone: "collaborative",
    description: "Testing positive co-parenting communication"
  },
  {
    name: "Workplace Stress",
    text: "This deadline is killing me and I'm bringing that stress home. I know I've been short with you and that's not fair.",
    context: "external_stress",
    expectedTone: "stressed_but_aware",
    description: "Testing external stressor acknowledgment"
  },
  {
    name: "Neutral/Practical",
    text: "Can you pick up milk on your way home? Also, don't forget we have dinner with your parents tomorrow at 7.",
    context: "daily_logistics",
    expectedTone: "neutral",
    description: "Testing everyday practical communication"
  }
];

// Different user profiles to test attachment-style-aware suggestions
const userProfiles = [
  {
    name: "Anxious Attachment",
    profile: {
      attachmentStyle: "anxious",
      communicationStyle: "emotional_expressive",
      primaryConcerns: ["abandonment", "reassurance_seeking"],
      preferredTone: "gentle"
    }
  },
  {
    name: "Avoidant Attachment", 
    profile: {
      attachmentStyle: "avoidant",
      communicationStyle: "logical_direct",
      primaryConcerns: ["independence", "emotional_regulation"],
      preferredTone: "direct"
    }
  },
  {
    name: "Secure Attachment",
    profile: {
      attachmentStyle: "secure", 
      communicationStyle: "balanced",
      primaryConcerns: ["mutual_understanding", "problem_solving"],
      preferredTone: "balanced"
    }
  }
];

// API configuration
const API_CONFIG = {
  // For local testing
  local: {
    hostname: 'localhost',
    port: 3000,
    protocol: 'http:',
    path: '/api/suggestions'
  },
  // For Vercel deployment testing
  vercel: {
    hostname: 'your-app-name.vercel.app',
    port: 443,
    protocol: 'https:',
    path: '/api/suggestions'
  }
};

// Choose which environment to test
const ENVIRONMENT = 'local'; // Change to 'vercel' for production testing

/**
 * Make HTTP request to the suggestions API
 */
function makeRequest(data, profile = null) {
  return new Promise((resolve, reject) => {
    const config = API_CONFIG[ENVIRONMENT];
    const postData = JSON.stringify({
      text: data.text,
      context: data.context,
      userProfile: profile,
      requestId: `test_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      platform: 'test_suite',
      includeFullAnalysis: true
    });

    const options = {
      hostname: config.hostname,
      port: config.port,
      path: config.path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
        'User-Agent': 'Unsaid-Test-Suite/1.0'
      }
    };

    const reqModule = config.protocol === 'https:' ? https : http;
    const req = reqModule.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const response = JSON.parse(body);
          resolve({ status: res.statusCode, data: response, headers: res.headers });
        } catch (e) {
          reject(new Error(`Failed to parse response: ${e.message}\nBody: ${body}`));
        }
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

/**
 * Format and display test results
 */
function displayResults(scenarioName, profileName, response, expectedTone) {
  console.log(`\n${'='.repeat(80)}`);
  console.log(`TEST: ${scenarioName} | PROFILE: ${profileName}`);
  console.log(`${'='.repeat(80)}`);
  
  if (response.status !== 200) {
    console.log(`❌ ERROR: HTTP ${response.status}`);
    console.log(JSON.stringify(response.data, null, 2));
    return;
  }

  const data = response.data;
  
  // Display tone analysis results
  console.log(`\n📊 TONE ANALYSIS:`);
  if (data.toneAnalysis) {
    console.log(`   Primary Tone: ${data.toneAnalysis.primaryTone || 'N/A'}`);
    console.log(`   Confidence: ${data.toneAnalysis.confidence || 'N/A'}`);
    console.log(`   Expected: ${expectedTone}`);
    console.log(`   Match: ${data.toneAnalysis.primaryTone === expectedTone ? '✅' : '⚠️'}`);
    
    if (data.toneAnalysis.emotionalIndicators) {
      console.log(`   Emotional Indicators: ${data.toneAnalysis.emotionalIndicators.join(', ')}`);
    }
    
    if (data.toneAnalysis.communicationStyle) {
      console.log(`   Communication Style: ${data.toneAnalysis.communicationStyle}`);
    }
  } else {
    console.log(`   ❌ No tone analysis found`);
  }

  // Display suggestions
  console.log(`\n💡 SUGGESTIONS (${data.suggestions?.length || 0} total):`);
  if (data.suggestions && data.suggestions.length > 0) {
    data.suggestions.slice(0, 3).forEach((suggestion, index) => {
      console.log(`   ${index + 1}. ${suggestion.text}`);
      if (suggestion.rationale) {
        console.log(`      Rationale: ${suggestion.rationale}`);
      }
      console.log(`      Type: ${suggestion.type || 'N/A'} | Confidence: ${suggestion.confidence || 'N/A'}`);
    });
  } else {
    console.log(`   ❌ No suggestions generated`);
  }

  // Display therapy advice if available
  if (data.therapyAdvice && data.therapyAdvice.length > 0) {
    console.log(`\n🧠 THERAPY ADVICE (${data.therapyAdvice.length} items):`);
    data.therapyAdvice.slice(0, 2).forEach((advice, index) => {
      console.log(`   ${index + 1}. ${advice.advice}`);
      if (advice.reasoning) {
        console.log(`      Reasoning: ${advice.reasoning}`);
      }
    });
  }

  // Display metadata
  console.log(`\n📈 METADATA:`);
  console.log(`   Response Time: ${data.metadata?.processingTime || 'N/A'}ms`);
  console.log(`   Quality Score: ${data.metadata?.qualityScore || 'N/A'}`);
  console.log(`   Features Used: ${data.metadata?.featuresUsed || 'N/A'}`);
}

/**
 * Run comprehensive test suite
 */
async function runTests() {
  console.log(`🚀 Starting Comprehensive Tone Analysis & Therapy Suggestions Test Suite`);
  console.log(`📡 Testing against: ${ENVIRONMENT} environment`);
  console.log(`🎯 Scenarios: ${testScenarios.length} | Profiles: ${userProfiles.length}`);
  console.log(`📊 Total Tests: ${testScenarios.length * userProfiles.length}`);

  let successCount = 0;
  let failureCount = 0;

  // Test each scenario with each user profile
  for (const scenario of testScenarios) {
    for (const profile of userProfiles) {
      try {
        console.log(`\n⏳ Testing: ${scenario.name} with ${profile.name}...`);
        
        const response = await makeRequest(scenario, profile.profile);
        displayResults(scenario.name, profile.name, response, scenario.expectedTone);
        
        if (response.status === 200) {
          successCount++;
        } else {
          failureCount++;
        }
        
        // Small delay between requests to avoid overwhelming the API
        await new Promise(resolve => setTimeout(resolve, 500));
        
      } catch (error) {
        console.log(`\n❌ ERROR in ${scenario.name} with ${profile.name}:`);
        console.log(error.message);
        failureCount++;
      }
    }
  }

  // Final summary
  console.log(`\n${'='.repeat(80)}`);
  console.log(`📊 TEST SUMMARY`);
  console.log(`${'='.repeat(80)}`);
  console.log(`✅ Successful: ${successCount}`);
  console.log(`❌ Failed: ${failureCount}`);
  console.log(`📈 Success Rate: ${((successCount / (successCount + failureCount)) * 100).toFixed(1)}%`);
  console.log(`⏱️  Total Tests: ${successCount + failureCount}`);
}

/**
 * Test a single scenario quickly
 */
async function quickTest() {
  console.log(`🚀 Quick Test: Testing single scenario`);
  
  const scenario = testScenarios[0]; // Test first scenario
  const profile = userProfiles[0];   // With first profile
  
  try {
    const response = await makeRequest(scenario, profile.profile);
    displayResults(scenario.name, profile.name, response, scenario.expectedTone);
  } catch (error) {
    console.log(`❌ Quick test failed: ${error.message}`);
  }
}

// Command line interface
const args = process.argv.slice(2);
if (args.includes('--quick')) {
  quickTest();
} else if (args.includes('--help')) {
  console.log(`
🧪 Unsaid Tone Analysis & Therapy Suggestions Test Suite

Usage:
  node test_tone_analysis.js          # Run full test suite
  node test_tone_analysis.js --quick  # Run quick single test
  node test_tone_analysis.js --help   # Show this help

Environment Configuration:
  Edit ENVIRONMENT constant in script to switch between 'local' and 'vercel'
  
Test Coverage:
  - ${testScenarios.length} communication scenarios
  - ${userProfiles.length} attachment style profiles  
  - ${testScenarios.length * userProfiles.length} total test combinations
  `);
} else {
  runTests();
}
