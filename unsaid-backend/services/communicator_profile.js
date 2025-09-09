/**
 * services/communicator_profile.js
 *
 * Attachment-style learner for the first 7 days of usage.
 * - Requires data/attachment_learning.json (no fallback)
 * - Incremental scoring with decay & daily cap
 * - Primary/secondary determination with thresholds
 *
 * Usage:
 *   const storage = new InMemoryProfileStorage();
 *   const prof = new CommunicatorProfile({
 *     userId: "u_123",
 *     storage,
 *     learningConfigPath: path.join(__dirname, "../data/attachment_learning.json")
 *   });
 *   await prof.init();
 *   await prof.updateFromText("Are you sure you still want this?");
 *   const est = prof.getAttachmentEstimate();
 *   await prof.save();
 */

const fs = require("fs");
const path = require("path");

// -----------------------------
// Utilities
// -----------------------------
const todayKey = () => new Date().toISOString().slice(0, 10); // YYYY-MM-DD
const rx = (p) => new RegExp(p, "i");
const clamp = (n, a, b) => Math.max(a, Math.min(b, n));
const sum = (o) => Object.values(o).reduce((a, b) => a + b, 0);

// -----------------------------
// Storage Adapter (swap for Redis/Mongo/Firestore)
// -----------------------------
class InMemoryProfileStorage {
  constructor() { this.store = new Map(); }
  async get(userId) { return this.store.get(userId) || null; }
  async set(userId, data) { this.store.set(userId, data); }
  async delete(userId) { this.store.delete(userId); }
}

// -----------------------------
// CommunicatorProfile
// -----------------------------
class CommunicatorProfile {
  /**
   * @param {Object} opts
   * @param {string} opts.userId
   * @param {Object} opts.storage  pluggable storage {get,set,delete}
   * @param {string} opts.learningConfigPath absolute or relative path to attachment_learning.json
   * @param {number} [opts.historyLimit=120] rolling history events cap
   */
  constructor({
    userId,
    storage,
    learningConfigPath,
    historyLimit = 120
  }) {
    if (!userId) throw new Error("CommunicatorProfile requires userId");
    if (!storage) throw new Error("CommunicatorProfile requires storage");
    if (!learningConfigPath) throw new Error("learningConfigPath is required");

    this.userId = userId;
    this.storage = storage;
    this.learningConfigPath = learningConfigPath;
    this.historyLimit = historyLimit;

    this.cfg = null;          // loaded attachment_learning.json
    this.state = null;        // persisted user state
  }

  // ---------- Lifecycle ----------
  async init() {
    this.cfg = this._loadLearningConfig(this.learningConfigPath);

    // Load profile or create new
    const existing = await this.storage.get(this.userId);
    if (existing) {
      this.state = existing;
      // Defensive: normalize if schema changed
      this._ensureStateShape();
    } else {
      this.state = this._freshState();
      await this.save();
    }

    // Roll day if needed (apply decay & reset counters)
    await this._rollDayIfNeeded();
  }

  async save() {
    await this.storage.set(this.userId, this.state);
  }

  async reset() {
    this.state = this._freshState();
    await this.save();
  }

  export() {
    const { userId, createdAt, updatedAt, firstSeenDay, history, scores, counters, daysObserved } = this.state;
    return { userId, createdAt, updatedAt, firstSeenDay, history, scores, counters, daysObserved };
  }

  // ---------- Public API ----------
  /**
   * Update profile from a piece of user text during the learning window.
   * @param {string} text
   * @param {object} meta optional {source, context, timestamp}
   */
  async updateFromText(text, meta = {}) {
    if (!text || typeof text !== "string") return;

    await this._rollDayIfNeeded();

    // Only learn inside the configured learning window
    if (!this._isWithinLearningWindow()) {
      this._pushHistory({ type: "observe_skipped", reason: "outside_learning_window", text, meta });
      return;
    }

    // Respect daily cap
    const totalToday = this._totalTodayIncrements();
    if (totalToday >= this.cfg.scoring.dailyLimit) {
      this._pushHistory({ type: "observe_skipped", reason: "daily_limit", text, meta });
      return;
    }

    const matches = this._matchSignals(text);

    // Apply weighted increments (bounded by remaining daily cap)
    let applied = 0;
    for (const m of matches) {
      if (applied >= (this.cfg.scoring.dailyLimit - totalToday)) break;
      this._incrementStyle(m.style, m.weight, m.signalId);
      applied++;
    }

    this.state.updatedAt = new Date().toISOString();
    this._pushHistory({
      type: "observe",
      text,
      meta,
      matches,
      dayKey: this.state.counters.dayKey
    });

    await this.save();
  }

  /**
   * Returns attachment estimate with primary/secondary and confidence.
   * {
   *   primary: 'anxious' | 'avoidant' | 'disorganized' | 'secure' | null,
   *   secondary: '...' | null,
   *   scores: { anxious, avoidant, disorganized, secure },
   *   confidence: 0..1,
   *   daysObserved: number,
   *   windowComplete: boolean
   * }
   */
  getAttachmentEstimate() {
    const s = this.state.scores;
    const { primary: pThr, secondary: sThr } = this.cfg.scoring.thresholds;

    // Normalize scores to 0..1 (softmax-like ratio)
    const total = sum(s) || 1e-9;
    const norm = {
      anxious: s.anxious / total,
      avoidant: s.avoidant / total,
      disorganized: s.disorganized / total,
      secure: s.secure / total
    };

    // Rank
    const ranked = Object.entries(norm).sort((a, b) => b[1] - a[1]); // [ [style, score], ... ]
    const [pStyle, pScore] = ranked[0];
    const [secStyle, secScore] = ranked[1];

    const primary = pScore >= pThr ? pStyle : null;
    const secondary = primary && secScore >= sThr ? secStyle : null;

    // Confidence heuristic: distance between top1 and top2, weighted by days observed progress
    const distance = Math.max(0, pScore - secScore);
    const progress = clamp(this.state.daysObserved / this.cfg.learningDays, 0, 1);
    const confidence = clamp(0.25 * distance + 0.75 * progress, 0, 1);

    return {
      primary,
      secondary,
      scores: { ...norm },
      confidence,
      daysObserved: this.state.daysObserved,
      windowComplete: this.state.daysObserved >= this.cfg.learningDays
    };
  }

  // ---------- Internals ----------
  _loadLearningConfig(p) {
    const resolved = path.isAbsolute(p) ? p : path.join(process.cwd(), p);
    if (!fs.existsSync(resolved)) {
      throw new Error(`attachment_learning.json not found at: ${resolved}`);
    }
    const raw = fs.readFileSync(resolved, "utf8");
    const cfg = JSON.parse(raw);

    // Minimal required schema checks
    const required = ["learningDays", "styles", "scoring"];
    for (const k of required) {
      if (!(k in cfg)) throw new Error(`attachment_learning.json missing "${k}"`);
    }
    if (!cfg.scoring.thresholds || typeof cfg.scoring.dailyLimit !== "number") {
      throw new Error(`attachment_learning.json must include scoring.thresholds and scoring.dailyLimit`);
    }
    return cfg;
  }

  _freshState() {
    return {
      userId: this.userId,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      firstSeenDay: todayKey(),
      daysObserved: 0,
      scores: { anxious: 0, avoidant: 0, disorganized: 0, secure: 0 },
      counters: { dayKey: todayKey(), incrementsToday: 0 },
      history: [] // rolling array of {type, text?, matches?, meta?, dayKey?, reason?}
    };
  }

  _ensureStateShape() {
    const s = this.state;
    s.scores = s.scores || { anxious: 0, avoidant: 0, disorganized: 0, secure: 0 };
    s.counters = s.counters || { dayKey: todayKey(), incrementsToday: 0 };
    s.history = Array.isArray(s.history) ? s.history : [];
    s.daysObserved = typeof s.daysObserved === "number" ? s.daysObserved : 0;
    s.firstSeenDay = s.firstSeenDay || todayKey();
  }

  _isWithinLearningWindow() {
    return this.state.daysObserved < this.cfg.learningDays;
    // Note: daysObserved increments on day roll; first day is 0
  }

  _rollDayIfNeeded() {
    const current = todayKey();
    if (this.state.counters.dayKey === current) return Promise.resolve();

    // New day: apply decay, reset counters, increment observed days
    this._applyDecay();
    this.state.counters.dayKey = current;
    this.state.counters.incrementsToday = 0;
    this.state.daysObserved = Math.min(this.state.daysObserved + 1, this.cfg.learningDays + 30); // cap just in case
    this.state.updatedAt = new Date().toISOString();
    this._pushHistory({ type: "day_roll", dayKey: current });

    return this.save();
  }

  _applyDecay() {
    // Per-style decay from config
    const { styles } = this.cfg;
    for (const style of Object.keys(this.state.scores)) {
      const decay = styles[style]?.decayRate ?? 1.0;
      this.state.scores[style] = clamp(this.state.scores[style] * decay, 0, 1e9);
    }
  }

  _totalTodayIncrements() {
    return this.state.counters.incrementsToday;
  }

  _incrementStyle(style, weight, signalId) {
    if (!(style in this.state.scores)) return;
    this.state.scores[style] = clamp(this.state.scores[style] + weight, 0, 1e9);
    this.state.counters.incrementsToday++;
    this._pushHistory({ type: "increment", style, weight, signalId, dayKey: this.state.counters.dayKey });
  }

  _matchSignals(text) {
    const matches = [];
    const { styles } = this.cfg;

    for (const [style, def] of Object.entries(styles)) {
      if (!def.signals) continue;
      for (const [signalId, signal] of Object.entries(def.signals)) {
        const weight = signal.weight || 0;
        const patterns = Array.isArray(signal.patterns) ? signal.patterns : [];
        for (const p of patterns) {
          try {
            if (rx(p).test(text)) {
              matches.push({ style, signalId, weight, pattern: p });
              break; // one pattern match per signal is enough
            }
          } catch {
            // skip bad regex
          }
        }
      }
    }

    // Sort strongest-first so high-weight signals consume daily cap first
    matches.sort((a, b) => (b.weight || 0) - (a.weight || 0));
    return matches;
  }

  _pushHistory(entry) {
    const e = { ...entry, at: new Date().toISOString() };
    this.state.history.push(e);
    if (this.state.history.length > this.historyLimit) {
      this.state.history.splice(0, this.state.history.length - this.historyLimit);
    }
  }
}

module.exports = {
  CommunicatorProfile,
  InMemoryProfileStorage
};
