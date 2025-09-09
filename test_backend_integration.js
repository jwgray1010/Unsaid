#!/usr/bin/env node
/**
 * Quick integration test for the new backend
 * Tests the suggestions API to ensure iOS compatibility
 */

const path = require('path');

// Set up paths - no need to change directory now

async function testSuggestionsAPI() {
    try {
        console.log('🧪 Testing new backend integration...\n');
        
        // Test the SuggestionsService directly
        const { SuggestionsService } = require('./unsaid-backend/services/suggestions_service');
        const { MLAdvancedToneAnalyzer } = require('./unsaid-backend/services/tone-analysis');
        
        const suggestionsService = new SuggestionsService();
        const toneAnalyzer = new MLAdvancedToneAnalyzer();
        
        // Test data
        const testText = "I'm really frustrated with this situation";
        const testParams = {
            text: testText,
            toneHint: 'alert',
            styleHint: 'anxious',
            features: ['rewrite', 'advice'],
            meta: { userId: 'test-user' },
            analysis: {
                primaryTone: 'alert',
                confidence: 0.85,
                evidence: ['frustration detected']
            }
        };
        
        console.log('📝 Test Input:');
        console.log(`Text: "${testText}"`);
        console.log(`Tone Hint: ${testParams.toneHint}`);
        console.log(`Style Hint: ${testParams.styleHint}\n`);
        
        // Test suggestions generation
        console.log('🔄 Generating suggestions...');
        const result = await suggestionsService.generate(testParams);
        
        console.log('✅ Suggestions API Response:');
        console.log('Rewrite:', result.rewrite);
        console.log('Quick Fixes:', result.quickFixes);
        console.log('Advice Count:', result.advice.length);
        console.log('iOS Compatibility Fields:');
        console.log('  - suggestions:', result.extras?.suggestions?.length || 0, 'items');
        console.log('  - primaryTone:', result.extras?.primaryTone);
        console.log('  - toneStatus:', result.extras?.toneStatus);
        console.log('  - confidence:', result.extras?.confidence);
        
        // Test tone analysis
        console.log('\n🔄 Testing tone analysis...');
        const toneResult = await toneAnalyzer.analyzeTone(testText, 'anxious', 'general');
        
        console.log('✅ Tone Analysis Response:');
        console.log('Success:', toneResult.success);
        console.log('Classification:', toneResult.tone?.classification);
        console.log('Confidence:', toneResult.tone?.confidence);
        
        console.log('\n🎉 Integration test completed successfully!');
        console.log('\n📋 Next Steps:');
        console.log('1. Deploy backend to Vercel');
        console.log('2. Update iOS app API URL');
        console.log('3. Test end-to-end flow');
        
        return true;
        
    } catch (error) {
        console.error('❌ Integration test failed:', error);
        console.error('\n🔧 Troubleshooting:');
        console.error('1. Check data files exist in unsaid-backend/data/');
        console.error('2. Verify all services are properly exported');
        console.error('3. Ensure package.json dependencies are installed');
        return false;
    }
}

// Run the test
if (require.main === module) {
    testSuggestionsAPI().then(success => {
        process.exit(success ? 0 : 1);
    });
}

module.exports = { testSuggestionsAPI };
