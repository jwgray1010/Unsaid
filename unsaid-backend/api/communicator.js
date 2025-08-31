/**
 * api/communicator.js
 *
 * Advanced Communicator Profile API (production-ready).
 *
 * Endpoints:
 *   GET    /communicator/profile
 *   POST   /communicator/observe
 *   GET    /communicator/export
 *   POST   /communicator/reset
 *   GET    /communicator/status
 */

const express = require("express");
const path = require("path");
const { z } = require("zod");

const {
  CommunicatorProfile,
  InMemoryProfileStorage,
} = require("../services/communicator_profile");

const router = express.Router();

// -------------------- Validation --------------------
const observeSchema = z.object({
  text: z.string().min(1).max(2000),
  meta: z.record(z.any()).optional(),
});

// -------------------- Helpers --------------------
function getLogger(req) {
  return req.app.get("logger") || console;
}

function getUserId(req) {
  // Prefer JWT if middleware added user object
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

async function loadProfile(req, res, next) {
  try {
    req.userId = getUserId(req);
    req.profile = new CommunicatorProfile({
      userId: req.userId,
      storage: getStorage(req),
      learningConfigPath: getLearningConfigPath(),
    });
    await req.profile.init();
    next();
  } catch (err) {
    next(err);
  }
}

// -------------------- Metrics --------------------
function incMetric(req, name) {
  const m = req.app.get("metrics");
  if (m && typeof m.inc === "function") {
    m.inc(`communicator_${name}`, { user: req.userId });
  }
}

// -------------------- Routes --------------------

// Summary profile (primary/secondary style + scores)
router.get("/profile", loadProfile, async (req, res, next) => {
  try {
    const estimate = req.profile.getAttachmentEstimate();
    incMetric(req, "profile");
    return res.json({
      ok: true,
      userId: req.userId,
      estimate,
      rawScores: estimate.scores,
      daysObserved: estimate.daysObserved,
      windowComplete: estimate.windowComplete,
    });
  } catch (err) {
    next(err);
  }
});

// Learn from text (within learning window)
router.post("/observe", loadProfile, express.json(), async (req, res, next) => {
  try {
    const parsed = observeSchema.parse(req.body);

    await req.profile.updateFromText(parsed.text, parsed.meta || {});
    incMetric(req, "observe");

    const estimate = req.profile.getAttachmentEstimate();
    return res.json({
      ok: true,
      userId: req.userId,
      estimate,
      windowComplete: estimate.windowComplete,
    });
  } catch (err) {
    if (err.name === "ZodError") {
      return res.status(400).json({ ok: false, error: err.errors });
    }
    next(err);
  }
});

// Privacy-safe export (no raw text)
router.get("/export", loadProfile, async (req, res, next) => {
  try {
    const snapshot = req.profile.export();

    // Strip sensitive text from history
    const safeHistory = (snapshot.history || []).map((h) => {
      const { text, ...rest } = h;
      return rest;
    });

    incMetric(req, "export");
    return res.json({
      ok: true,
      userId: req.userId,
      profile: { ...snapshot, history: safeHistory },
    });
  } catch (err) {
    next(err);
  }
});

// Reset profile
router.post("/reset", loadProfile, async (req, res, next) => {
  try {
    await req.profile.reset();
    incMetric(req, "reset");
    const estimate = req.profile.getAttachmentEstimate();
    return res.json({
      ok: true,
      userId: req.userId,
      message: "Profile reset.",
      estimate,
    });
  } catch (err) {
    next(err);
  }
});

// Status & thresholds
router.get("/status", loadProfile, async (req, res, next) => {
  try {
    const estimate = req.profile.getAttachmentEstimate();
    const cfg = req.profile.cfg;
    incMetric(req, "status");

    return res.json({
      ok: true,
      userId: req.userId,
      learningDays: cfg.learningDays,
      thresholds: cfg.scoring.thresholds,
      dailyLimit: cfg.scoring.dailyLimit,
      daysObserved: estimate.daysObserved,
      windowComplete: estimate.windowComplete,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
