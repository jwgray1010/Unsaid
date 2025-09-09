#!/usr/bin/env node

/**
 * Direct Function Test for Tone Analysis & Therapy Suggestions
 * 
 * This script tests the suggestion functions directly without requiring a server.
 */

// Mock the require for modules that might not be available
const mockReq = (body) => ({
  method: 'POST',
  body: JSON.stringify(body)
});

const mockRes = () => {
  const res = {
    headers: {},
    statusCode: 200,
    setHeader(key, value) { this.headers[key] = value; },
    status(code) { this.statusCode = code; return this; },
    json(data) { 
      this.jsonData = data;
      console.log('Response:', JSON.stringify(data, null, 2));
      return this;
    },
    end() { return this; }
  };
  return res;
};

// Test scenarios
const testTexts = [
  {
    name: "Aggressive Communication",
    text: "You never listen to me! I'm sick of always having to repeat myself. Why can't you just do what I asked for once?",
    context: "relationship_conflict"
  },
  {
    name: "Passive-Aggressive Communication", 
    text: "Fine, whatever you want. I guess my opinion doesn't matter anyway. Thanks for asking me first... oh wait, you didn't.",
    context: "relationship_conflict"
  },
  {
    name: "Anxious Communication",
    text: "I'm really worried about us. I keep thinking something's wrong and I don't know what to do. Are we okay?",
    context: "relationship_anxiety"
  },
  {
    name: "Supportive Communication",
    text: "I can see this is really important to you. Thank you for sharing how you feel. How can I support you?",
    context: "relationship_support"
  },
  {
    name: "Co-parenting Conflict",
    text: "You're being impossible about this schedule. The kids need consistency and you keep changing plans.",
    context: "coparenting_conflict"
  }
];

// Simple tone analysis function (extracted from the main logic)
function analyzeTone(text) {
  const toneKeywords = {
    aggressive: ['never', 'always', 'sick of', 'why can\'t you', 'for once'],
    passive_aggressive: ['fine', 'whatever', 'i guess', 'thanks for', 'oh wait'],
    anxious: ['worried', 'keep thinking', 'don\'t know', 'are we okay'],
    supportive: ['i can see', 'thank you', 'how can i', 'support'],
    frustrated: ['impossible', 'need consistency', 'keep changing']
  };

  const textLower = text.toLowerCase();
  const scores = {};
  
  for (const [tone, keywords] of Object.entries(toneKeywords)) {
    scores[tone] = keywords.reduce((count, keyword) => {
      return count + (textLower.includes(keyword) ? 1 : 0);
    }, 0);
  }

  const primaryTone = Object.entries(scores).reduce((a, b) => 
    scores[a[0]] > scores[b[0]] ? a : b
  )[0];

  const confidence = Math.min(scores[primaryTone] / 2, 1); // Normalize to 0-1

  return {
    primaryTone,
    confidence,
    scores,
    emotionalIndicators: getEmotionalIndicators(textLower),
    communicationStyle: getCommunicationStyle(textLower)
  };
}

function getEmotionalIndicators(text) {
  const indicators = [];
  
  if (text.includes('worried') || text.includes('scared')) indicators.push('anxiety');
  if (text.includes('angry') || text.includes('sick of')) indicators.push('anger');
  if (text.includes('sad') || text.includes('hurt')) indicators.push('sadness');
  if (text.includes('love') || text.includes('care')) indicators.push('affection');
  if (text.includes('frustrated') || text.includes('impossible')) indicators.push('frustration');
  
  return indicators;
}

function getCommunicationStyle(text) {
  if (text.includes('i feel') || text.includes('i think')) return 'expressive';
  if (text.includes('you never') || text.includes('you always')) return 'accusatory';
  if (text.includes('can you') || text.includes('would you')) return 'requesting';
  if (text.includes('thank you') || text.includes('i appreciate')) return 'appreciative';
  return 'neutral';
}

// Generate therapy suggestions based on tone and context
function generateSuggestions(toneAnalysis, context, text) {
  const suggestions = [];
  
  const suggestionTemplates = {
    aggressive: [
      "Try rephrasing with 'I feel...' instead of 'You never...' to express your needs without blame.",
      "Take a pause before responding when feeling frustrated to avoid escalation.",
      "Focus on specific behaviors rather than using absolute terms like 'always' or 'never'."
    ],
    passive_aggressive: [
      "Express your needs directly rather than through sarcasm or indirect statements.",
      "Use 'I' statements to communicate what you actually want or need.",
      "Address concerns when they arise rather than letting resentment build up."
    ],
    anxious: [
      "Ask for specific reassurance about what you need to feel secure.",
      "Share your worries openly rather than keeping them to yourself.",
      "Suggest regular check-ins to maintain connection and reduce anxiety."
    ],
    supportive: [
      "Continue using empathetic language that validates your partner's feelings.",
      "Ask follow-up questions to better understand their perspective.",
      "Offer specific ways you can provide support."
    ],
    frustrated: [
      "Express your frustration while acknowledging the complexity of the situation.",
      "Suggest concrete solutions rather than focusing only on the problem.",
      "Validate that coordination challenges are difficult for everyone involved."
    ]
  };

  const baseSuggestions = suggestionTemplates[toneAnalysis.primaryTone] || [
    "Take time to understand your partner's perspective before responding.",
    "Use clear, direct communication about your needs and feelings.",
    "Focus on finding solutions together rather than assigning blame."
  ];

  baseSuggestions.forEach((suggestion, index) => {
    suggestions.push({
      text: suggestion,
      type: 'reframe',
      confidence: Math.max(0.7 - (index * 0.1), 0.5),
      rationale: `Helps address ${toneAnalysis.primaryTone} communication pattern`
    });
  });

  return suggestions;
}

// Generate therapy advice
function generateTherapyAdvice(toneAnalysis, context) {
  const adviceTemplates = {
    relationship_conflict: [
      {
        advice: "Focus on understanding each other's underlying needs rather than winning the argument.",
        reasoning: "Conflicts often arise from unmet emotional needs rather than the surface-level disagreement."
      },
      {
        advice: "Use the 'pause and reflect' technique when emotions run high.",
        reasoning: "Taking breaks prevents reactive responses and allows for more thoughtful communication."
      }
    ],
    relationship_anxiety: [
      {
        advice: "Practice sharing specific concerns rather than general worries.",
        reasoning: "Specific concerns can be addressed more effectively than vague anxieties."
      },
      {
        advice: "Establish regular check-ins to maintain emotional connection.",
        reasoning: "Consistent communication reduces uncertainty and builds security."
      }
    ],
    coparenting_conflict: [
      {
        advice: "Keep the focus on what's best for the children in each decision.",
        reasoning: "Child-centered thinking helps move past personal conflicts toward collaborative solutions."
      },
      {
        advice: "Create clear, written agreements about schedules and expectations.",
        reasoning: "Clear structures reduce misunderstandings and provide stability for everyone."
      }
    ]
  };

  return adviceTemplates[context] || [
    {
      advice: "Practice active listening by reflecting back what you hear before responding.",
      reasoning: "This ensures understanding and shows respect for your partner's perspective."
    }
  ];
}

// Main test function
async function runDirectTests() {
  console.log('🧪 Direct Function Testing: Tone Analysis & Therapy Suggestions\n');
  console.log('=' * 80);

  for (const testCase of testTexts) {
    console.log(`\n📝 Testing: ${testCase.name}`);
    console.log(`Text: "${testCase.text}"`);
    console.log('-'.repeat(60));

    // Analyze tone
    const toneAnalysis = analyzeTone(testCase.text);
    console.log(`\n📊 Tone Analysis:`);
    console.log(`   Primary Tone: ${toneAnalysis.primaryTone}`);
    console.log(`   Confidence: ${(toneAnalysis.confidence * 100).toFixed(1)}%`);
    console.log(`   Emotional Indicators: ${toneAnalysis.emotionalIndicators.join(', ') || 'None detected'}`);
    console.log(`   Communication Style: ${toneAnalysis.communicationStyle}`);

    // Generate suggestions
    const suggestions = generateSuggestions(toneAnalysis, testCase.context, testCase.text);
    console.log(`\n💡 Suggestions (${suggestions.length}):`);
    suggestions.forEach((suggestion, index) => {
      console.log(`   ${index + 1}. ${suggestion.text}`);
      console.log(`      Confidence: ${(suggestion.confidence * 100).toFixed(1)}%`);
    });

    // Generate therapy advice
    const therapyAdvice = generateTherapyAdvice(toneAnalysis, testCase.context);
    console.log(`\n🧠 Therapy Advice (${therapyAdvice.length}):`);
    therapyAdvice.forEach((advice, index) => {
      console.log(`   ${index + 1}. ${advice.advice}`);
      console.log(`      Reasoning: ${advice.reasoning}`);
    });

    console.log('\n' + '='.repeat(80));
  }

  console.log('\n✅ Direct testing completed!');
  console.log(`📊 Tested ${testTexts.length} different communication scenarios`);
}

// Run the tests
runDirectTests().catch(console.error);
