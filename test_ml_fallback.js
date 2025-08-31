#!/usr/bin/env node

/**
 * Test ML Fallback Functionality
 * 
 * Tests suggestions API when NO tone analysis is provided (should trigger ML analysis)
 */

const suggestionsHandler = require('./z-api2/services/suggestions.js');

// Mock request and response objects
function createMockReq(body) {
  return {
    method: 'POST',
    body: body,
    headers: {
      'content-type': 'application/json'
    }
  };
}

function createMockRes() {
  const res = {
    headers: {},
    statusCode: 200,
    data: null,
    
    setHeader(key, value) { 
      this.headers[key] = value; 
    },
    
    status(code) { 
      this.statusCode = code; 
      return this; 
    },
    
    json(data) { 
      this.data = data;
      return this;
    },
    
    end() { 
      return this; 
    }
  };
  return res;
}

// Test scenarios WITHOUT tone analysis (should trigger ML)
const testScenarios = [
  {
    name: "Angry Text (No Tone Analysis - ML Fallback)",
    data: {
      text: "I'm absolutely furious! You never listen to what I'm saying and it's driving me crazy!",
      attachmentStyle: "anxious",
      context: "relationship_conflict"
      // NOTE: No toneAnalysisResult provided - should trigger ML
    }
  },
  {
    name: "Anxious Text (No Tone Analysis - ML Fallback)", 
    data: {
      text: "I'm really worried about where our relationship is going. Are we okay? I keep thinking something's wrong.",
      attachmentStyle: "anxious",
      context: "relationship_anxiety"
      // NOTE: No toneAnalysisResult provided - should trigger ML
    }
  },
  {
    name: "Supportive Text (No Tone Analysis - ML Fallback)",
    data: {
      text: "I really appreciate you sharing your feelings with me. How can I best support you through this?",
      attachmentStyle: "secure", 
      context: "relationship_support"
      // NOTE: No toneAnalysisResult provided - should trigger ML
    }
  }
];

async function runMLFallbackTests() {
  console.log('🤖 Testing ML Fallback Functionality (No Tone Analysis Provided)\n');
  console.log('=' * 80);

  for (const scenario of testScenarios) {
    console.log(`\n📝 Testing: ${scenario.name}`);
    console.log(`Text: "${scenario.data.text}"`);
    console.log(`Attachment Style: ${scenario.data.attachmentStyle}`);
    console.log(`Context: ${scenario.data.context}`);
    console.log(`Has Tone Analysis: ${scenario.data.toneAnalysisResult ? 'YES' : 'NO (should trigger ML)'}`);
    console.log('-'.repeat(60));

    try {
      const mockReq = createMockReq(scenario.data);
      const mockRes = createMockRes();

      // Call the handler
      await suggestionsHandler(mockReq, mockRes);

      if (mockRes.data) {
        console.log(`\n✅ Success! Status: ${mockRes.statusCode}`);
        
        // Check if ML was used
        if (mockRes.data.mlAnalysis) {
          console.log(`\n🤖 ML Analysis Used:`);
          console.log(`   Detected Tone: ${mockRes.data.mlAnalysis.primaryTone}`);
          console.log(`   Confidence: ${(mockRes.data.mlAnalysis.confidence * 100).toFixed(1)}%`);
          console.log(`   Feature Count: ${mockRes.data.mlAnalysis.featureCount}`);
        }

        if (mockRes.data.suggestions) {
          console.log(`\n💡 Generated Suggestions (${mockRes.data.suggestions.length}):`);
          mockRes.data.suggestions.forEach((suggestion, index) => {
            console.log(`   ${index + 1}. ${suggestion.text}`);
            console.log(`      Type: ${suggestion.type}, Confidence: ${(suggestion.confidence * 100).toFixed(1)}%`);
            console.log(`      Based on: ${suggestion.basedOnTone}`);
          });
        }

        if (mockRes.data.therapyAdvice) {
          console.log(`\n🧠 Therapy Advice (${mockRes.data.therapyAdvice.length}):`);
          mockRes.data.therapyAdvice.forEach((advice, index) => {
            console.log(`   ${index + 1}. ${advice.advice}`);
            console.log(`      Category: ${advice.category}`);
          });
        }

        console.log(`\n📊 Metadata:`);
        console.log(`   ML Generated: ${mockRes.data.metadata.mlGenerated}`);
        console.log(`   Tone Used: ${mockRes.data.metadata.toneUsed}`);
        console.log(`   Version: ${mockRes.data.metadata.version}`);

      } else {
        console.log(`❌ No response data received`);
      }

    } catch (error) {
      console.log(`❌ Error: ${error.message}`);
      if (error.stack) {
        console.log(`   Stack: ${error.stack.split('\n')[1]?.trim()}`);
      }
    }

    console.log('\n' + '='.repeat(80));
  }

  console.log('\n✅ ML Fallback testing completed!');
  console.log('🧪 All tests should show "ML Generated: true" in metadata');
}

// Run the tests
runMLFallbackTests().catch(console.error);
