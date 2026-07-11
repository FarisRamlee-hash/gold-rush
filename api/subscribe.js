// Best-effort per-instance rate limiter. Serverless instances are ephemeral
// and shared, so this is a first line of defence against naive floods, not a
// hard guarantee — a durable KV store would be needed for that.
const HITS = new Map();
const WINDOW_MS = 60_000;
const MAX_PER_WINDOW = 5;

function rateLimited(ip) {
  const now = Date.now();
  const arr = (HITS.get(ip) || []).filter(t => now - t < WINDOW_MS);
  arr.push(now);
  HITS.set(ip, arr);
  if (HITS.size > 5000) { // bound memory
    for (const [k, v] of HITS) if (!v.length || now - v[v.length - 1] > WINDOW_MS) HITS.delete(k);
  }
  return arr.length > MAX_PER_WINDOW;
}

// RFC 5321 caps addresses at 254 chars. Reject control chars / angle brackets
// outright so a malicious value can never reach logs, storage or an email tool.
const EMAIL_RE = /^[^\s@<>"'`]{1,64}@[^\s@<>"'`]{1,190}\.[^\s@<>"'`]{2,24}$/;

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.setHeader('X-Content-Type-Options', 'nosniff');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const ip = (req.headers['x-forwarded-for'] || '').split(',')[0].trim() || 'unknown';
  if (rateLimited(ip)) return res.status(429).json({ error: 'Too many requests' });

  const body = req.body || {};
  const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';

  if (email.length > 254 || !EMAIL_RE.test(email)) {
    return res.status(400).json({ error: 'Invalid email' });
  }

  console.log(`[SUBSCRIBE] ${new Date().toISOString()} — ${email}`);

  // Persist to the database if connected (viewable in the admin dashboard).
  try {
    const kv = require('../lib/kv');
    if (kv.configured()) await kv.lpush('subscribers', { email, ts: Date.now() });
  } catch (e) {
    console.log('subscriber store failed:', e.message);
  }

  return res.status(200).json({ ok: true, message: 'Subscribed successfully' });
};
