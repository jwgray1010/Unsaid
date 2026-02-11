type Bucket = {
  hits: number[];
};

const buckets = new Map<string, Bucket>();

export function applyRateLimit(options: {
  key: string;
  max: number;
  windowMs: number;
}) {
  const now = Date.now();
  const bucket = buckets.get(options.key) ?? { hits: [] };

  bucket.hits = bucket.hits.filter((timestamp) => now - timestamp < options.windowMs);
  if (bucket.hits.length >= options.max) {
    buckets.set(options.key, bucket);
    return {
      allowed: false,
      remaining: 0,
      resetInMs: options.windowMs - (now - bucket.hits[0]),
    };
  }

  bucket.hits.push(now);
  buckets.set(options.key, bucket);

  return {
    allowed: true,
    remaining: Math.max(options.max - bucket.hits.length, 0),
    resetInMs: 0,
  };
}
