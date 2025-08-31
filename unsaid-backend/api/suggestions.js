/**
 * api/suggestions.js
 *
 * Suggestions (therapy advice) endpoint.
 * POST /suggestions → generate therapy advice for a message
 *
 * Expects services/suggestions.js to export:
 *   - SuggestionsService with generate({ text, toneHint, styleHint, features, meta, analysis })
 */

const express = require("express");
const { z } = require("zod");
const path = require("path");

// Use functional tone analyzer interface
const { createToneAnalyzer } = require("../services/tone-analysis");

const {
  CommunicatorProfile,
  InMemoryProfileStorage
} = require("../services/communicator_profile");

const router = express.Router();

// -------------------- Validation --------------------
const suggSchema = z.object({
  text: z.string().min(1).max(2000),
  toneOverride: z.enum(["alert", "caution", "clear"]).optional(),
  attachmentStyle: z.enum(["anxious", "avoidant", "disorganized", "secure"]).optional(),
  features: z.array(z.string()).max(8).optional(), // e.g., ["advice","evidence"]
  meta: z.record(z.any()).optional()
});

// -------------------- Helpers --------------------
function getLogger(req) {
  return req.app.get("logger") || console;
}

function getUserId(req) {
  return (req.user && (req.user.id || req.user.sub)) ||
         req.header("X-User-Id") ||
         "anonymous";
}

function getStorage(req) {
  return req.app.get("profileStorage") || new InMemoryProfileStorage();
}

function getLearningConfigPath() {
  return path.join(__dirname, "..", "data", "learning_signals.json");
}

async function loadProfile(req, _res, next) {
  try {
    req.userId = getUserId(req);
    req.profile = new CommunicatorProfile({
      userId: req.userId,
      storage: getStorage(req),
      learningConfigPath: getLearningConfigPath()
    });
    await req.profile.init();
    next();
  } catch (err) {
    next(err);
  }
}

// Create functional tone analyzer instance
const analyzer = createToneAnalyzer({
  premium: true, // Can be made dynamic based on user tier
  confidenceThreshold: 0.3,
  dataDir: path.join(__dirname, '../data')
});

function incMetric(req, name) {
  const m = req.app.get("metrics");
  if (m && typeof m.inc === "function") m.inc(`suggestions_${name}`, { user: req.userId });
}

// Lazy require to avoid cold starts when unused
function getServices() {
  const { SuggestionsService } = require("../services/suggestions");
  return {
    analyzer, // Use the functional analyzer
    sugg: new SuggestionsService()
  };
}

// -------------------- Routes --------------------

router.post("/", loadProfile, express.json(), async (req, res, next) => {
  try {
    const { text, toneOverride, attachmentStyle, features = [], meta } = suggSchema.parse(req.body);

    const { analyzer, sugg } = getServices();

    // 1) Run tone analysis using functional interface
    const attach = req.profile.getAttachmentEstimate();
    const attachmentStyleToUse = attachmentStyle || attach.primary || 'secure';
    
    // Use the functional analyzer pattern you requested
    const analysis = await analyzer.analyzeTone(text, attachmentStyleToUse, 'general');
    
    // Map tone to buckets for suggestion categorization
    const { buckets } = analyzer.mapToneToBuckets(
      analysis.tone,
      attachmentStyleToUse,
      analysis.features?.features?.context_best || 'default'
    );

    // 2) Determine hints (allow overrides from client)
    const toneHint = toneOverride || analysis.tone?.classification || 'neutral';
    const styleHint = attachmentStyleToUse;

    // 3) Generate suggestions with enhanced analysis data
    const result = await sugg.generate({
      text,
      toneHint,
      styleHint,
      features,
      meta: { ...meta, userId: req.userId },
      analysis, // pass whole analysis for richer evidence-driven suggestions
      buckets   // pass tone buckets for categorization
    });

    incMetric(req, "generate");

    return res.json({
      ok: true,
      userId: req.userId,
      attachmentEstimate: attach,
      tone: toneHint,
      buckets, // Include buckets in response for client
      features,
      // SuggestionsService should return these keys; example shape below:
      quickFixes: result.quickFixes || [],       // small edits/phrases
      advice: result.advice || [],               // therapy/coach suggestions
      evidence: result.evidence || analysis.evidence || [], // matched rules, patterns
      extras: result.extras || {}                // knobs, sliders, debug hints
    });
  } catch (err) {
    if (err.name === "ZodError") {
      return res.status(400).json({ ok: false, error: err.errors });
    }
    next(err);
  }
});

module.exports = router;
