/**
 * api/tone.js
 *
 * Tone analysis endpoint (v1).
 * POST /tone → analyze a single text snippet
 *
 * Expects services/tone-analysis.js to export:
 *   - MLAdvancedToneAnalyzer (class with analyze({ text, context, meta, user }))
 */

console.log('[DEBUG] tone.js starting...');

const express = require("express");
const { z } = require("zod");
const path = require("path");

console.log('[DEBUG] tone.js basic imports loaded...');

const {
  CommunicatorProfile,
  InMemoryProfileStorage
} = require("../services/communicator_profile");

console.log('[DEBUG] tone.js communicator_profile imported...');

const router = express.Router();

console.log('[DEBUG] tone.js router created...');

// -------------------- Validation --------------------
const toneSchema = z.object({
  text: z.string().min(1).max(5000),
  context: z.enum(["conflict", "repair", "jealousy", "boundary", "general"]).optional(),
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

function incMetric(req, name) {
  const m = req.app.get("metrics");
  if (m && typeof m.inc === "function") m.inc(`tone_${name}`, { user: req.userId });
}

// Lazy require to avoid cold-start cost if unused elsewhere
function getAnalyzer() {
  // You can switch to a DI/container if preferred
  const { MLAdvancedToneAnalyzer } = require("../services/tone-analysis");
  return new MLAdvancedToneAnalyzer();
}

// -------------------- Routes --------------------

// Analyze tone
router.post("/", loadProfile, express.json(), async (req, res, next) => {
  try {
    const { text, context, meta } = toneSchema.parse(req.body);

    const analyzer = getAnalyzer();

    // Optionally pass attachment estimate to help the model bias decisions
    const attach = req.profile.getAttachmentEstimate();

    const result = await analyzer.analyze({
      text,
      context,
      meta: { ...meta, userId: req.userId },
      user: {
        id: req.userId,
        attachment: attach.primary || null,
        secondary: attach.secondary || null,
        windowComplete: attach.windowComplete
      }
    });

    incMetric(req, "analyze");

    return res.json({
      ok: true,
      userId: req.userId,
      attachmentEstimate: attach,
      tone: result.tone,          // e.g., "alert" | "caution" | "clear"
      confidence: result.confidence,
      scores: result.scores,      // per-bucket or per-label scores
      context: result.context,    // detected/confirmed context
      evidence: result.evidence,  // matched patterns, features, etc.
      rewritability: result.rewritability // optional signal for suggestions service
    });
  } catch (err) {
    if (err.name === "ZodError") {
      return res.status(400).json({ ok: false, error: err.errors });
    }
    next(err);
  }
});

module.exports = router;
