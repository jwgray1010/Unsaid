// api/_lib/services/spacyBridge.ts
import crypto from 'crypto';
import { logger } from '../logger';
import { spacyClient as lite } from './spacyClient'; // your current TS "lite" implementation

type CompactDoc = {
  tokens?: Array<{ text: string; lemma: string; pos: string; i: number }>;
  sents?: Array<{ start: number; end: number }>;
  deps?: Array<{ head?: number; dep?: string; rel?: string; i?: number }>;
  sarcasm?: { present: boolean; score?: number };
  context?: { label: string; score: number };
  phraseEdges?: { hits: string[] } | string[];
};

const CFG = {
  backend: process.env.SPACY_BACKEND ?? 'lite',   // 'lite' | 'python'
  url: process.env.SPACY_URL ?? '',
  timeoutMsTyping: Number(process.env.SPACY_TIMEOUT_MS_TYPING ?? 450),
  timeoutMsFinalize: Number(process.env.SPACY_TIMEOUT_MS_FINALIZE ?? 1200),
  breakerThreshold: Number(process.env.SPACY_BREAKER_THRESHOLD ?? 4),
  breakerCooldownMs: Number(process.env.SPACY_BREAKER_COOLDOWN_MS ?? 120_000),
  maxChars: Number(process.env.SPACY_MAX_CHARS ?? 1200),
  authKey: process.env.SPACY_INTERNAL_KEY ?? '',
};

let breaker = { open: false, fails: 0, openedAt: 0 };
const lru = new Map<string, CompactDoc>(); // tiny LRU
const LRU_MAX = 64;

function lruGet(k: string) { return lru.get(k); }
function lruSet(k: string, v: CompactDoc) {
  if (lru.has(k)) lru.delete(k);
  lru.set(k, v);
  if (lru.size > LRU_MAX) lru.delete(lru.keys().next().value);
}
function sha(text: string) { return crypto.createHash('sha1').update(text).digest('hex'); }

function withTimeout<T>(p: Promise<T>, ms: number): Promise<T> {
  return new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error('SPACY_TIMEOUT')), ms);
    p.then(v => { clearTimeout(t); resolve(v); }, e => { clearTimeout(t); reject(e); });
  });
}

async function callPythonSpaCy(text: string, timeoutMs: number): Promise<CompactDoc> {
  if (!CFG.url) throw new Error('SPACY_URL_NOT_SET');
  const body = {
    text,
    wantTokens: true,
    wantSents: true,
    wantDeps: true
  };
  const res = await withTimeout(fetch(CFG.url, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      ...(CFG.authKey ? { 'x-internal-key': CFG.authKey } : {})
    },
    body: JSON.stringify(body)
  }), timeoutMs);

  if (!res.ok) throw new Error(`SPACY_HTTP_${res.status}`);
  const json: any = await res.json();

  // Normalize to your compact shape
  const out: CompactDoc = {
    tokens: (json.tokens || []).map((t: any, i: number) => ({
      text: t.text || '',
      lemma: (t.lemma || t.text || '').toLowerCase(),
      pos: (t.pos || 'X').toUpperCase(),
      i
    })),
    sents: (json.sents || []).map((s: any) => ({ start: s.start ?? 0, end: s.end ?? text.length })),
    deps: (json.deps || []).map((d: any, i: number) => ({ head: d.head, dep: d.dep || d.rel, i })),
    sarcasm: json.sarcasm ?? { present: false, score: 0 },
    context: { label: json.contextLabel ?? json.context?.label ?? 'general', score: json.context?.score ?? 0.1 },
    phraseEdges: Array.isArray(json.phraseEdges) ? json.phraseEdges : (json.phraseEdges?.hits ?? []),
  };
  return out;
}

function breakerFail() {
  breaker.fails++;
  if (!breaker.open && breaker.fails >= CFG.breakerThreshold) {
    breaker.open = true;
    breaker.openedAt = Date.now();
    logger.warn('spaCy breaker opened (too many failures)');
  }
}
function breakerMaybeClose() {
  if (breaker.open && Date.now() - breaker.openedAt > CFG.breakerCooldownMs) {
    breaker.open = false; breaker.fails = 0;
    logger.info('spaCy breaker closed after cooldown');
  }
}

export async function processWithSpacy(
  text: string,
  phase: 'typing' | 'finalize' = 'typing'
): Promise<CompactDoc> {
  // Always cap text length (use last N chars which matter most for tone)
  const T = text.slice(-CFG.maxChars);
  const key = `${phase}:${sha(T)}`;
  const cached = lruGet(key);
  if (cached) return cached;

  // If not enabled, or breaker is open → fallback
  if (CFG.backend !== 'python') return lite.process(T, { wantTokens: true, wantSents: true, wantDeps: true }) as any;
  if (breaker.open) { breakerMaybeClose(); return lite.process(T, { wantTokens: true, wantSents: true, wantDeps: true }) as any; }

  const timeout = phase === 'finalize' ? CFG.timeoutMsFinalize : CFG.timeoutMsTyping;

  try {
    const doc = await callPythonSpaCy(T, timeout);
    lruSet(key, doc);
    // success → heal breaker
    breaker.fails = 0;
    return doc;
  } catch (err: any) {
    logger.warn('spaCy call failed, falling back to lite', { msg: err?.message });
    breakerFail();
    return lite.process(T, { wantTokens: true, wantSents: true, wantDeps: true }) as any;
  }
}
