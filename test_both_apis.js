#!/usr/bin/env node

/**
 * Test Both API Endpoints: Tone Analysis + Suggestions
 * 
 * This tests the complete flow:
 * 1. Call tone-analysis endpoint to get tone
 * 2. Call suggestions endpoint with the tone result
 */

const toneAnalysisHandler = require('./z-api2/services/tone-analysis-endpoint.js');
const suggestionsHandler = require('./z-api2/services/suggestions.js');

// Mock request and response objects
function createMockReq(body, method = 'POST') {
  return {
    method: method,
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

// Test scenarios
const testScenarios = [
  {
    name: "Aggressive Communication",
    text: "You never listen to me! I'm sick of always having to repeat myself. Why can't you just do what I asked for once?",
    attachmentStyle: "anxious",
    context: "relationship_conflict"
  },
  {
    name: "Anxious Communication",
    text: "I'm really worried about us. I keep thinking something's wrong and I don't know what to do. Are we okay?",
    attachmentStyle: "anxious", 
    context: "relationship_anxiety"
  }
];

async function testCompleteFlow() {
  console.log('🧪 Testing Complete API Flow: Tone Analysis → Suggestions\n');
  console.log('=' * 80);

  for (const scenario of testScenarios) {
    console.log(`\n📝 Testing: ${scenario.name}`);
    console.log(`Text: "${scenario.text}"`);
    console.log(`Attachment Style: ${scenario.attachmentStyle}`);
    console.log(`Context: ${scenario.context}`);
    console.log('-'.repeat(80));

    try {
      // STEP 1: Call tone analysis endpoint
      console.log('\n🔍 STEP 1: Calling Tone Analysis API...');
      
      const toneReq = createMockReq({
        text: scenario.text,
        attachmentStyle: scenario.attachmentStyle,
        context: scenario.context
      });
      const toneRes = createMockRes();

      await toneAnalysisHandler(toneReq, toneRes);

      if (toneRes.statusCode !== 200 || !toneRes.data?.success) {
        console.log(`❌ Tone analysis failed: ${toneRes.data?.error || 'Unknown error'}`);
        continue;
      }

      const toneResult = toneRes.data;
      console.log(`✅ Tone Analysis Result:`);
      console.log(`   Primary Tone: ${toneResult.primaryTone}`);
      console.log(`   Confidence: ${(toneResult.confidence * 100).toFixed(1)}%`);
      console.log(`   Emotional Indicators: ${toneResult.emotionalIndicators.join(', ') || 'None'}`);
      console.log(`   Communication Style: ${toneResult.communicationStyle}`);

      // STEP 2: Call suggestions endpoint with tone result
      console.log('\n💡 STEP 2: Calling Suggestions API...');
      
      const suggestionsReq = createMockReq({
        text: scenario.text,
        toneAnalysisResult: {
          primaryTone: toneResult.primaryTone,
          confidence: toneResult.confidence,
          emotionalIndicators: toneResult.emotionalIndicators,
          communicationStyle: toneResult.communicationStyle
        },
        attachmentStyle: scenario.attachmentStyle,
        context: scenario.context
      });
      const suggestionsRes = createMockRes();

      await suggestionsHandler(suggestionsReq, suggestionsRes);

      if (suggestionsRes.statusCode !== 200 || !suggestionsRes.data) {
        console.log(`❌ Suggestions failed: ${suggestionsRes.data?.error || 'Unknown error'}`);
        continue;
      }

      const suggestionsResult = suggestionsRes.data;
      console.log(`✅ Suggestions Result:`);
      
      if (suggestionsResult.suggestions) {
        console.log(`\n💭 Suggestions (${suggestionsResult.suggestions.length}):`);
        suggestionsResult.suggestions.slice(0, 3).forEach((suggestion, index) => {
          console.log(`   ${index + 1}. ${suggestion.text}`);
          console.log(`      Confidence: ${(suggestion.confidence * 100).toFixed(1)}%`);
        });
      }

      if (suggestionsResult.therapyAdvice) {
        console.log(`\n🧠 Therapy Advice (${suggestionsResult.therapyAdvice.length}):`);
        suggestionsResult.therapyAdvice.slice(0, 2).forEach((advice, index) => {
          console.log(`   ${index + 1}. ${advice.advice}`);
          console.log(`      Reasoning: ${advice.reasoning}`);
        });
      }

    } catch (error) {
      console.log(`❌ Error in complete flow: ${error.message}`);
      if (error.stack) {
        console.log(`   Stack: ${error.stack.split('\n')[1]?.trim()}`);
      }
    }

    console.log('\n' + '='.repeat(80));
  }

  console.log('\n✅ Complete flow testing completed!');
  console.log('📊 This demonstrates the two-step process:');
  console.log('   1. 🔍 Tone Analysis API → Gets tone, confidence, emotional indicators');
  console.log('   2. 💡 Suggestions API → Uses tone result to generate suggestions');
}

// Run the tests
testCompleteFlow().catch(console.error);
