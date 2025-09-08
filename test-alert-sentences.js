#!/usr/bin/env node

// Test script for Unsaid API with alert sentences
const https = require('https');
const http = require('http');

const API_BASE = 'https://unsaid-backend-teal.vercel.app';

function makeRequest(endpoint, data) {
  return new Promise((resolve, reject) => {
    const url = `${API_BASE}${endpoint}`;
    const postData = JSON.stringify(data);

    const options = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
        'x-user-id': 'test-user-123'
      }
    };

    const req = https.request(url, options, (res) => {
      let body = '';
      res.on('data', (chunk) => {
        body += chunk;
      });
      res.on('end', () => {
        try {
          const response = JSON.parse(body);
          resolve({ status: res.statusCode, data: response });
        } catch (e) {
          resolve({ status: res.statusCode, data: body });
        }
      });
    });

    req.on('error', (err) => {
      reject(err);
    });

    req.write(postData);
    req.end();
  });
}

async function testAlertSentences() {
  console.log('🚨 Testing Unsaid API with Alert Sentences\n');

  const alertSentences = [
    "I can't believe you would say something so stupid!",
    "This is absolutely unacceptable behavior!",
    "You're being completely unreasonable right now!",
    "I am furious about this situation!",
    "This makes me absolutely sick!",
    "You're crossing a serious line here!",
    "This is completely outrageous!",
    "I won't tolerate this kind of disrespect!"
  ];

  for (let i = 0; i < alertSentences.length; i++) {
    const sentence = alertSentences[i];
    console.log(`\n📝 Test ${i + 1}: "${sentence}"`);
    console.log('─'.repeat(60));

    try {
      // Test Tone Analysis
      console.log('🎯 Testing Tone Analysis...');
      const toneResponse = await makeRequest('/api/v1/tone', {
        text: sentence,
        context: 'conflict'
      });

      if (toneResponse.status === 200) {
        const tone = toneResponse.data;
        console.log(`✅ Tone: ${tone.tone} (confidence: ${(tone.confidence * 100).toFixed(1)}%)`);
        console.log(`📊 Primary: ${tone.analysis.primary_tone}`);
        console.log(`🎭 Emotions: anger=${(tone.analysis.emotions.anger * 100).toFixed(0)}%, fear=${(tone.analysis.emotions.fear * 100).toFixed(0)}%`);
        console.log(`🏷️  New User: ${tone.isNewUser ? 'Yes' : 'No'}`);
      } else {
        console.log(`❌ Tone Analysis failed: ${toneResponse.status}`);
        console.log(toneResponse.data);
      }

      // Test Suggestions
      console.log('\n💡 Testing Suggestions...');
      const suggestionsResponse = await makeRequest('/api/v1/suggestions', {
        text: sentence,
        context: 'conflict',
        count: 3
      });

      if (suggestionsResponse.status === 200) {
        const suggestions = suggestionsResponse.data;
        console.log(`✅ Generated ${suggestions.suggestions.length} suggestions`);
        console.log(`🏷️  New User: ${suggestions.isNewUser ? 'Yes' : 'No'}`);

        suggestions.suggestions.slice(0, 2).forEach((suggestion, idx) => {
          console.log(`   ${idx + 1}. "${suggestion.text}" (${suggestion.category})`);
        });

        if (suggestions.suggestions.length > 2) {
          console.log(`   ... and ${suggestions.suggestions.length - 2} more`);
        }
      } else {
        console.log(`❌ Suggestions failed: ${suggestionsResponse.status}`);
        console.log(suggestionsResponse.data);
      }

    } catch (error) {
      console.log(`❌ Request failed: ${error.message}`);
    }

    // Wait a bit between requests to avoid rate limiting
    await new Promise(resolve => setTimeout(resolve, 1000));
  }

  console.log('\n🎉 Testing complete!');
}

testAlertSentences().catch(console.error);
