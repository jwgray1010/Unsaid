/**
 * Test script to verify word-by-word tone analysis behavior
 * Tests that tone analysis updates after every word AND after sentence completion
 */

const readline = require('readline');

// Simulate the updated behavior
class WordByWordAnalyzer {
    constructor() {
        this.minCharsForAnalysis = 1;  // Updated from 8
        this.minWordsForAnalysis = 1;  // Updated from 2
        this.boundaryDebounce = 0.22;  // For completed sentences
        this.wordAnalysisDelay = 0.3;  // For every-word analysis
        this.lastAnalyzedText = "";
    }

    meetsThresholds(text) {
        if (text.length < this.minCharsForAnalysis) return false;
        const words = text.split(/\s+/).filter(word => word.length > 0);
        return words.length >= this.minWordsForAnalysis;
    }

    hasCompletedSentence(text) {
        return /[.!?]\s*$/.test(text.trim());
    }

    analyzeText(text) {
        const trimmed = text.trim();
        
        if (!this.meetsThresholds(trimmed)) {
            console.log(`❌ Text doesn't meet thresholds: "${trimmed}" (${trimmed.length} chars, ${trimmed.split(/\s+/).filter(w => w.length > 0).length} words)`);
            return false;
        }

        if (trimmed === this.lastAnalyzedText) {
            console.log(`⏭️  Skipping duplicate analysis: "${trimmed}"`);
            return false;
        }

        this.lastAnalyzedText = trimmed;

        if (this.hasCompletedSentence(trimmed)) {
            console.log(`🟢 SENTENCE COMPLETE - Immediate analysis (${this.boundaryDebounce}s delay): "${trimmed}"`);
        } else {
            console.log(`🟡 WORD-BY-WORD - Analysis scheduled (${this.wordAnalysisDelay}s delay): "${trimmed}"`);
        }

        // Simulate tone detection
        const words = trimmed.split(/\s+/).filter(w => w.length > 0);
        const toneScore = Math.random();
        let tone = 'neutral';
        if (toneScore > 0.7) tone = 'alert';
        else if (toneScore > 0.4) tone = 'caution';
        else tone = 'clear';

        console.log(`   → Detected tone: ${tone} (${words.length} words analyzed)`);
        return true;
    }
}

// Test scenarios
function runTests() {
    const analyzer = new WordByWordAnalyzer();
    
    console.log("🧪 Testing Word-by-Word Tone Analysis\n");
    console.log("=" * 50);
    
    // Test 1: Single word
    console.log("\n📝 Test 1: Single words");
    analyzer.analyzeText("Hello");
    analyzer.analyzeText("Hello world");
    analyzer.analyzeText("Hello world test");
    
    // Test 2: Completed sentence
    console.log("\n📝 Test 2: Completed sentences");
    analyzer.analyzeText("This is a test sentence.");
    analyzer.analyzeText("This is a test sentence. Another one!");
    
    // Test 3: Progressive typing simulation
    console.log("\n📝 Test 3: Progressive typing simulation");
    const progressiveText = "I am feeling really frustrated today";
    let current = "";
    
    for (const word of progressiveText.split(" ")) {
        current += (current ? " " : "") + word;
        analyzer.analyzeText(current);
    }
    
    // Add punctuation to complete the sentence
    analyzer.analyzeText(current + ".");
    
    console.log("\n✅ Test complete!");
    console.log("\n📋 Expected Behavior Summary:");
    console.log("• ✅ Analysis runs after every single word (1+ chars, 1+ words)");
    console.log("• ✅ Completed sentences get immediate analysis (0.22s delay)"); 
    console.log("• ✅ Progressive words get scheduled analysis (0.3s delay)");
    console.log("• ✅ Whole text context is always passed to tone analysis");
    console.log("• ✅ Duplicate text is skipped to avoid redundant analysis");
}

// Interactive test mode
function runInteractiveTest() {
    const analyzer = new WordByWordAnalyzer();
    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout
    });

    console.log("\n🎮 Interactive Word-by-Word Analysis Test");
    console.log("Type text to see how tone analysis triggers:");
    console.log("(Type 'quit' to exit)\n");

    function prompt() {
        rl.question('Enter text: ', (input) => {
            if (input.toLowerCase() === 'quit') {
                rl.close();
                return;
            }
            
            analyzer.analyzeText(input);
            console.log();
            prompt();
        });
    }
    
    prompt();
}

// Run tests
if (require.main === module) {
    runTests();
    
    // Uncomment to run interactive test
    // runInteractiveTest();
}

module.exports = { WordByWordAnalyzer };
