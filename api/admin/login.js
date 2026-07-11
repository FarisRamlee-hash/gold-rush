const auth = require('../../lib/auth');

// Best-effort per-instance rate limit against password guessing.
const HITS = new Map();
function rateLimited(ip) {
  const now = Date.now();
  const arr = (HITS.get(ip) || []).filter(t => now - t < 60000);
  arr.push(now);
  HITS.set(ip, arr);
  return arr.length > 8;
}

module.exports = async (req, res) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });
  if (!auth.configured()) return res.status(503).json({ error: 'Admin not configured. Set ADMIN_PASSWORD in Vercel.' });

  const ip = (req.headers['x-forwarded-for'] || '').split(',')[0].trim() || 'unknown';
  if (rateLimited(ip)) return res.status(429).json({ error: 'Too many attempts. Wait a minute.' });

  const password = (req.body && typeof req.body.password === 'string') ? req.body.password : '';
  if (!auth.checkPassword(password)) return res.status(401).json({ error: 'Wrong password' });

  // 12-hour session token.
  const token = auth.sign({ role: 'admin', exp: Date.now() + 12 * 3600 * 1000 });
  return res.status(200).json({ ok: true, token });
};
