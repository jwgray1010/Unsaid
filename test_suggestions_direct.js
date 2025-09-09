#!/usr/bin/env node

/**
 * Test Suggestions API Function Directly
 * 
 * This script tests the suggestions.js handler function directly without requiring a server.
 */

const suggestionsHandler = require('./z-api2/services/suggestions.js');

// Mock request and response objects
function createMockReq(body) {
  return {
    method: 'POST',
    body: body, // Send body directly, not stringified
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

// Test scenarios
const testScenarios = [
  {
    name: "Aggressive Communication",
    data: {
      text: "You never listen to me! I'm sick of always having to repeat myself. Why can't you just do what I asked for once?",
      attachmentStyle: "anxious",
      context: "relationship_conflict",
      toneAnalysisResult: {
        primaryTone: "aggressive",
        confidence: 0.9,
        emotionalIndicators: ["anger", "frustration"],
        communicationStyle: "accusatory"
      }
    }
  },
  {
    name: "Passive-Aggressive Communication",
    data: {
      text: "Fine, whatever you want. I guess my opinion doesn't matter anyway. Thanks for asking me first... oh wait, you didn't.",
      attachmentStyle: "avoidant", 
      context: "relationship_conflict",
      toneAnalysisResult: {
        primaryTone: "passive_aggressive",
        confidence: 0.85,
        emotionalIndicators: ["resentment"],
        communicationStyle: "indirect"
      }
    }
  },
  {
    name: "Anxious Communication",
    data: {
      text: "I'm really worried about us. I keep thinking something's wrong and I don't know what to do. Are we okay?",
      attachmentStyle: "anxious",
      context: "relationship_anxiety",
      toneAnalysisResult: {
        primaryTone: "anxious",
        confidence: 0.92,
        emotionalIndicators: ["anxiety", "worry"],
        communicationStyle: "seeking_reassurance"
      }
    }
  },
  {
    name: "Supportive Communication",
    data: {
      text: "I can see this is really important to you. Thank you for sharing how you feel. How can I support you?",
      attachmentStyle: "secure",
      context: "relationship_support",
      toneAnalysisResult: {
        primaryTone: "supportive",
        confidence: 0.95,
        emotionalIndicators: ["empathy", "care"],
        communicationStyle: "supportive"
      }
    }
  }
];

async function runTests() {
  console.log('🧪 Testing Suggestions API Handler Directly\n');
  console.log('=' * 80);

  for (const scenario of testScenarios) {
    console.log(`\n📝 Testing: ${scenario.name}`);
    console.log(`Text: "${scenario.data.text}"`);
    console.log(`Attachment Style: ${scenario.data.attachmentStyle}`);
    console.log(`Context: ${scenario.data.context}`);
    console.log('-'.repeat(60));

    try {
      const mockReq = createMockReq(scenario.data);
      const mockRes = createMockRes();

      // Call the handler
      await suggestionsHandler(mockReq, mockRes);

      if (mockRes.data) {
        console.log(`\n✅ Success! Status: ${mockRes.statusCode}`);
        
        if (mockRes.data.suggestions) {
          console.log(`\n💡 Suggestions (${mockRes.data.suggestions.length}):`);
          mockRes.data.suggestions.slice(0, 3).forEach((suggestion, index) => {
            console.log(`   ${index + 1}. ${suggestion.text}`);
            console.log(`      Type: ${suggestion.type}, Confidence: ${(suggestion.confidence * 100).toFixed(1)}%`);
          });
        }

        if (mockRes.data.therapyAdvice) {
          console.log(`\n🧠 Therapy Advice (${mockRes.data.therapyAdvice.length}):`);
          mockRes.data.therapyAdvice.slice(0, 2).forEach((advice, index) => {
            console.log(`   ${index + 1}. ${advice.advice}`);
            console.log(`      Reasoning: ${advice.reasoning}`);
          });
        }

        if (mockRes.data.mlAnalysis) {
          console.log(`\n📊 ML Analysis:`);
          console.log(`   Primary Tone: ${mockRes.data.mlAnalysis.primaryTone}`);
          console.log(`   Confidence: ${(mockRes.data.mlAnalysis.confidence * 100).toFixed(1)}%`);
          console.log(`   Context: ${mockRes.data.mlAnalysis.context}`);
        }

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

  console.log('\n✅ Testing completed!');
}

// Run the tests
runTests().catch(console.error);
