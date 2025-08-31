#!/usr/bin/env node
/**
 * jobs/validate_data.mjs
 *
 * Advanced validator for /data JSON knowledge files.
 *
 * Features:
 * - CLI flags:
 *    --data-dir <dir>       (default ../data)
 *    --strict               (treat any warning as error)
 *    --fail-on-warn         (exit non-zero on warnings)
 *    --report <path>        (JSONL report)
 *    --concurrency <num>    (default 8)
 * - Validates presence of required files; warns on unexpected files
 * - Per-file schema checks (types, required keys)
 * - Extra checks: unique ids, regex compilation, numeric range sanity
 * - Parallel execution + clean summary
 *
 * Usage:
 *   node jobs/validate_data.mjs --strict --fail-on-warn --report ./reports/data-validate.jsonl
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// --------------------------- CLI / paths ---------------------------
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const args = parseArgs(process.argv.slice(2));

const DATA_DIR = path.resolve(args['data-dir'] || path.join(__dirname, '..', 'data'));
const STRICT = !!args['strict'];
const FAIL_ON_WARN = !!args['fail-on-warn'];
const REPORT = args['report'] ? path.resolve(args['report']) : null;
const CONCURRENCY = Math.max(1, Number(args['concurrency'] || 8));

// Keep this list in sync with your project
const REQUIRED_FILES = [
  'learning_signals.json',
  'tone_triggerwords.json',
  'intensity_modifiers.json',
  'sarcasm_indicators.json',
  'negation_patterns.json',
  'context_classifier.json',
  'therapy_advice.json',
  'onboarding_playbook.json',
  'phrases_edges.json',
  'severity_collaboration.json',
  'weight_modifiers.json',
  'semantic_thesaurus.json',
  'profanity_lexicon.json',
];

// --------------------------- Utility helpers ---------------------------
function parseArgs(argv) {
  const o = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (!a.startsWith('--')) continue;
    const key = a.slice(2);
    const next = argv[i + 1];
    if (!next || next.startsWith('--')) {
      o[key] = true;
    } else {
      o[key] = next;
      i++;
    }
  }
  return o;
}

function readJSON(filePath) {
  const raw = fs.readFileSync(filePath, 'utf8');
  try {
    return { parsed: JSON.parse(raw), raw };
  } catch (err) {
    throw new Error(`Invalid JSON: ${err.message}`);
  }
}

async function writeReportLine(obj) {
  if (!REPORT) return;
  await fs.promises.mkdir(path.dirname(REPORT), { recursive: true });
  await fs.promises.appendFile(REPORT, JSON.stringify(obj) + '\n', 'utf8');
}

function isObject(x) {
  return x && typeof x === 'object' && !Array.isArray(x);
}
function isNonEmptyArray(a) {
  return Array.isArray(a) && a.length > 0;
}
function hasKeys(o, keys) {
  return isObject(o) && keys.every(k => Object.prototype.hasOwnProperty.call(o, k));
}

function tryRegex(pattern) {
  try {
    // Allow patterns provided either as raw string or pre-escaped string
    // If it looks like a JS-style literal (starts/ends with /), strip slashes and flags.
    let source = pattern;
    let flags = '';
    if (typeof pattern === 'string' && pattern.startsWith('/') && pattern.lastIndexOf('/') > 0) {
      const last = pattern.lastIndexOf('/');
      source = pattern.slice(1, last);
      flags = pattern.slice(last + 1);
    }
    // eslint-disable-next-line no-new
    new RegExp(source, flags);
    return null;
  } catch (e) {
    return e.message;
  }
}

function inRange(num, { min = Number.NEGATIVE_INFINITY, max = Number.POSITIVE_INFINITY } = {}) {
  return typeof num === 'number' && num >= min && num <= max;
}

// --------------------------- Per-file validators ---------------------------
/**
 * Each validator returns an array of issues:
 *   { level: 'error'|'warn', message: string, path?: string }
 */
const validators = {
  'learning_signals.json': (data) => {
    const issues = [];
    if (!hasKeys(data, ['styles', 'scoring'])) {
      issues.push({ level: 'error', message: 'Missing "styles" or "scoring" root keys' });
    } else {
      if (!isObject(data.styles) || !Object.keys(data.styles).length) {
        issues.push({ level: 'error', message: '"styles" must be a non-empty object' });
      }
      if (!isObject(data.scoring) || !Object.keys(data.scoring).length) {
        issues.push({ level: 'error', message: '"scoring" must be a non-empty object' });
      }
    }
    return issues;
  },

  'tone_triggerwords.json': (data) => {
    const issues = [];
    if (!data.version) {
      issues.push({ level: 'error', message: 'Missing "version"' });
    }
    // Optional: enforce structure by attachmentStyle -> tone -> items[]
    // We’ll just sanity-check nested objects and arrays
    for (const style of ['secure', 'anxious', 'avoidant', 'disorganized']) {
      const bucket = data[style];
      if (bucket && !isObject(bucket)) {
        issues.push({ level: 'warn', message: `Expected object for style "${style}"` });
      }
      if (isObject(bucket)) {
        for (const tone of ['clear', 'caution', 'alert']) {
          const arr = bucket[tone];
          if (arr && !Array.isArray(arr)) {
            issues.push({ level: 'warn', message: `Expected array for ${style}.${tone}` });
          }
        }
      }
    }
    return issues;
  },

  'intensity_modifiers.json': (data) => {
    const issues = [];
    if (!data.version) issues.push({ level: 'warn', message: 'Missing "version"' });
    if (!isObject(data.profiles)) issues.push({ level: 'error', message: '"profiles" must be an object' });
    if (isObject(data.bounds)) {
      if (!inRange(data.bounds.min, { max: data.bounds.max })) {
        issues.push({ level: 'error', message: '"bounds.min" must be <= "bounds.max"' });
      }
    }
    return issues;
  },

  'sarcasm_indicators.json': (data) => {
    const issues = [];
    if (!data.version) issues.push({ level: 'warn', message: 'Missing "version"' });
    if (!isNonEmptyArray(data.sarcasm_indicators)) {
      issues.push({ level: 'error', message: '"sarcasm_indicators" must be a non-empty array' });
      return issues;
    }
    const ids = new Set();
    data.sarcasm_indicators.forEach((item, i) => {
      if (!item.id) issues.push({ level: 'error', message: `Item #${i} missing "id"` });
      if (item.id) {
        if (ids.has(item.id)) issues.push({ level: 'error', message: `Duplicate id "${item.id}"` });
        ids.add(item.id);
      }
      if (!item.pattern) issues.push({ level: 'error', message: `Item ${item.id || i} missing "pattern"` });
      const err = item.pattern ? tryRegex(item.pattern) : null;
      if (err) issues.push({ level: 'error', message: `Invalid regex for ${item.id}: ${err}` });
      if (item.impact != null && !inRange(item.impact, { min: -1, max: 1 })) {
        issues.push({ level: 'warn', message: `Item ${item.id} "impact" out of expected [-1,1]` });
      }
    });
    return issues;
  },

  'negation_patterns.json': (data) => {
    const issues = [];
    if (!isNonEmptyArray(data.patterns)) {
      issues.push({ level: 'error', message: '"patterns" must be a non-empty array' });
      return issues;
    }
    data.patterns.forEach((p, i) => {
      if (!p.id) issues.push({ level: 'error', message: `Pattern #${i} missing "id"` });
      if (!p.regex) issues.push({ level: 'error', message: `Pattern ${p.id || i} missing "regex"` });
      const err = p.regex ? tryRegex(p.regex) : null;
      if (err) issues.push({ level: 'error', message: `Invalid regex for ${p.id}: ${err}` });
    });
    return issues;
  },

  'context_classifier.json': (data) => {
    const issues = [];
    if (!isNonEmptyArray(data.contexts)) {
      issues.push({ level: 'error', message: '"contexts" must be a non-empty array' });
      return issues;
    }
    const ids = new Set();
    for (const ctx of data.contexts) {
      if (!ctx.id) issues.push({ level: 'error', message: 'Context missing "id"' });
      if (ctx.id) {
        if (ids.has(ctx.id)) issues.push({ level: 'error', message: `Duplicate context id "${ctx.id}"` });
        ids.add(ctx.id);
      }
      if (!isNonEmptyArray(ctx.match)) issues.push({ level: 'error', message: `"${ctx.id}" missing non-empty "match"` });
      ctx.match.forEach((m) => {
        const err = tryRegex(m);
        if (err) issues.push({ level: 'error', message: `Invalid regex in "${ctx.id}": ${err}` });
      });
    }
    return issues;
  },

  'therapy_advice.json': (data) => {
    const issues = [];
    if (!isNonEmptyArray(data)) {
      issues.push({ level: 'error', message: 'Expected an array of advice entries' });
      return issues;
    }
    const ids = new Set();
    for (const item of data) {
      if (!item.id) issues.push({ level: 'error', message: 'Advice entry missing "id"' });
      if (item.id) {
        if (ids.has(item.id)) issues.push({ level: 'error', message: `Duplicate advice id "${item.id}"` });
        ids.add(item.id);
      }
      if (!item.advice) issues.push({ level: 'error', message: `Advice ${item.id} missing "advice"` });
      if (item.spacyPattern && !Array.isArray(item.spacyPattern)) {
        issues.push({ level: 'warn', message: `Advice ${item.id} "spacyPattern" should be an array` });
      }
      if (item.matchKeywords && !Array.isArray(item.matchKeywords)) {
        issues.push({ level: 'warn', message: `Advice ${item.id} "matchKeywords" should be an array` });
      }
    }
    return issues;
  },

  'onboarding_playbook.json': (data) => {
    const issues = [];
    if (!isObject(data) || !isNonEmptyArray(data.days)) {
      issues.push({ level: 'error', message: 'Expected { days: [] } with at least one day' });
      return issues;
    }
    data.days.forEach((d, i) => {
      if (!d.id) issues.push({ level: 'error', message: `Day #${i} missing "id"` });
      if (!isNonEmptyArray(d.cards)) issues.push({ level: 'error', message: `Day ${d.id || i} missing non-empty "cards"` });
    });
    return issues;
  },

  'phrases_edges.json': (data) => {
    const issues = [];
    if (!isObject(data) || !isNonEmptyArray(data.edges)) {
      issues.push({ level: 'error', message: 'Expected { edges: [] } with at least one edge' });
      return issues;
    }
    const cats = new Set(['rupture', 'repair', 'opener', 'boundary', 'escalation', 'deescalation']);
    data.edges.forEach((e, i) => {
      if (!e.pattern) issues.push({ level: 'error', message: `Edge #${i} missing "pattern"` });
      const err = e.pattern ? tryRegex(e.pattern) : null;
      if (err) issues.push({ level: 'error', message: `Invalid regex in edge #${i}: ${err}` });
      if (e.category && !cats.has(e.category)) issues.push({ level: 'warn', message: `Edge #${i} unknown category "${e.category}"` });
      if (e.boost != null && !inRange(e.boost, { min: -1, max: 1 })) {
        issues.push({ level: 'warn', message: `Edge #${i} "boost" out of expected [-1,1]` });
      }
    });
    return issues;
  },

  'severity_collaboration.json': (data) => {
    const issues = [];
    if (!isObject(data) || !isObject(data.thresholds)) {
      issues.push({ level: 'error', message: 'Expected { thresholds: {...} }' });
      return issues;
    }
    for (const k of Object.keys(data.thresholds)) {
      const v = data.thresholds[k];
      if (!inRange(v, { min: 0, max: 1 })) {
        issues.push({ level: 'warn', message: `thresholds.${k} should be within [0,1]` });
      }
    }
    return issues;
  },

  'weight_modifiers.json': (data) => {
    const issues = [];
    if (!isObject(data)) {
      issues.push({ level: 'error', message: 'Expected root object' });
      return issues;
    }
    if (isObject(data.bounds)) {
      if (data.bounds.min > data.bounds.max) {
        issues.push({ level: 'error', message: '"bounds.min" must be <= "bounds.max"' });
      }
    }
    return issues;
  },

  'semantic_thesaurus.json': (data) => {
    const issues = [];
    if (!isObject(data)) {
      issues.push({ level: 'error', message: 'Expected root object { key: [synonyms...] }' });
      return issues;
    }
    for (const [k, v] of Object.entries(data)) {
      if (!Array.isArray(v)) issues.push({ level: 'error', message: `Entry "${k}" must be an array` });
      else if (!v.every(x => typeof x === 'string')) issues.push({ level: 'warn', message: `Entry "${k}" should contain only strings` });
    }
    return issues;
  },

  'profanity_lexicon.json': (data) => {
    const issues = [];
    if (!isNonEmptyArray(data.words)) {
      issues.push({ level: 'error', message: 'Expected { words: [] } with entries' });
      return issues;
    }
    return issues;
  },
};

// --------------------------- Validator Runner ---------------------------
async function main() {
  console.log(`🔍 Validating JSON data files in: ${DATA_DIR}`);
  if (REPORT) {
    await writeReportLine({ type: 'start', at: new Date().toISOString(), dir: DATA_DIR });
  }

  // Ensure data dir
  if (!fs.existsSync(DATA_DIR) || !fs.statSync(DATA_DIR).isDirectory()) {
    fail(`Data directory not found: ${DATA_DIR}`);
  }

  const present = fs.readdirSync(DATA_DIR).filter(f => f.endsWith('.json')).sort();
  const missing = REQUIRED_FILES.filter(f => !present.includes(f));
  const unexpected = present.filter(f => !REQUIRED_FILES.includes(f));

  // Report presence
  if (missing.length) {
    console.warn(`⚠️  Missing required files (${missing.length}): ${missing.join(', ')}`);
    await writeReportLine({ type: 'missing', files: missing });
    if (STRICT) fail('Missing required files under --strict.');
  }
  if (unexpected.length) {
    console.warn(`ℹ️  Extra files found (${unexpected.length}): ${unexpected.join(', ')}`);
    await writeReportLine({ type: 'unexpected', files: unexpected });
  }

  // Validate required files that exist
  const toValidate = REQUIRED_FILES.filter(f => present.includes(f));

  const results = await runWithConcurrency(toValidate, CONCURRENCY, async (file) => {
    const filePath = path.join(DATA_DIR, file);
    try {
      const { parsed } = readJSON(filePath);
      const v = validators[file];
      const issues = v ? v(parsed) : [{ level: 'warn', message: 'No validator implemented for this file' }];
      const errors = issues.filter(i => i.level === 'error');
      const warns = issues.filter(i => i.level === 'warn');

      if (errors.length === 0 && warns.length === 0) {
        console.log(`✅ ${file} is valid`);
      } else {
        if (errors.length) {
          console.error(`❌ ${file}: ${errors.length} error(s)`);
          errors.forEach(e => console.error(`   • ${e.message}`));
        }
        if (warns.length) {
          console.warn(`⚠️  ${file}: ${warns.length} warning(s)`);
          warns.forEach(w => console.warn(`   • ${w.message}`));
        }
      }

      await writeReportLine({ type: 'file', file, errors, warnings: warns });
      return { file, errors, warns };
    } catch (err) {
      console.error(`❌ ${file} failed to parse: ${err.message}`);
      await writeReportLine({ type: 'file', file, errors: [{ message: err.message }], warnings: [] });
      return { file, errors: [{ message: err.message }], warns: [] };
    }
  });

  // Summarize
  const sum = summarize(results);
  await writeReportLine({ type: 'summary', ...sum, at: new Date().toISOString() });

  const exitWithWarns = FAIL_ON_WARN && (sum.warns > 0);
  const exitCode = (sum.errors > 0 || (STRICT && missing.length > 0) || exitWithWarns) ? 1 : 0;

  console.log('\n—— Summary ——');
  console.log(`Files checked: ${results.length}/${REQUIRED_FILES.length}`);
  console.log(`Errors: ${sum.errors}  Warnings: ${sum.warns}`);
  if (missing.length) console.log(`Missing required files: ${missing.length}`);
  if (unexpected.length) console.log(`Unexpected files: ${unexpected.length}`);
  console.log(exitCode === 0 ? '🎉 Validation complete (OK)' : '❗ Validation complete (issues found)');

  if (REPORT) console.log(`Report: ${REPORT}`);
  process.exit(exitCode);
}

function summarize(results) {
  let errors = 0, warns = 0;
  for (const r of results) {
    errors += (r.errors?.length || 0);
    warns += (r.warns?.length || 0);
  }
  return { errors, warns };
}

async function runWithConcurrency(items, limit, worker) {
  const out = [];
  let idx = 0;
  const active = new Set();

  async function spawn() {
    if (idx >= items.length) return;
    const i = idx++;
    const p = worker(items[i]).then(r => (out[i] = r)).catch(e => (out[i] = { error: e.message }));
    active.add(p);
    p.finally(() => active.delete(p));
    if (active.size < limit && idx < items.length) await spawn();
  }

  const n = Math.min(limit, items.length);
  for (let i = 0; i < n; i++) await spawn();
  while (active.size) {
    await Promise.race([...active]);
    if (idx < items.length) await spawn();
  }
  return out;
}

function fail(msg) {
  console.error(`❌ ${msg}`);
  process.exit(1);
}

// --------------------------- Run ---------------------------
main().catch((err) => {
  console.error('❌ Validation failed:', err);
  process.exit(1);
});
