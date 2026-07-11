const kv = require('../../lib/kv');
const auth = require('../../lib/auth');
const defaults = require('../../lib/defaults');

const CONTENT_TYPES = { dealers: 'content:dealers', faq: 'content:faq', events: 'content:events' };
const MAX_ITEMS = 200;

module.exports = async (req, res) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('Cache-Control', 'no-store');

  // Auth gate — bearer token only (no cookies), so no CSRF surface.
  if (!auth.authed(req)) return res.status(401).json({ error: 'Unauthorized' });

  const type = String((req.query && req.query.type) || '');

  // ---- Subscribers (read-only) ----
  if (type === 'subscribers') {
    if (req.method !== 'GET') return res.status(405).json({ error: 'Read only' });
    if (!kv.configured()) return res.json({ items: [], count: 0, dbConfigured: false });
    try {
      const items = await kv.lrange('subscribers', 0, 4999);
      return res.json({ items, count: items.length, dbConfigured: true });
    } catch (e) {
      return res.status(502).json({ error: 'DB read failed' });
    }
  }

  // ---- Content collections ----
  if (!CONTENT_TYPES[type]) return res.status(400).json({ error: 'Unknown type' });
  const key = CONTENT_TYPES[type];

  if (req.method === 'GET') {
    let items = defaults[type];
    let source = 'default';
    if (kv.configured()) {
      try {
        const v = await kv.getJSON(key);
        if (Array.isArray(v) && v.length) { items = v; source = 'db'; }
      } catch (e) { /* fall back to defaults */ }
    }
    return res.json({ items, source, dbConfigured: kv.configured() });
  }

  if (req.method === 'POST' || req.method === 'PUT') {
    if (!kv.configured()) return res.status(503).json({ error: 'Database not connected. Add Upstash from the Vercel Marketplace.' });
    const items = req.body && req.body.items;
    if (!Array.isArray(items)) return res.status(400).json({ error: 'items must be an array' });
    if (items.length > MAX_ITEMS) return res.status(400).json({ error: 'Too many items' });
    const raw = JSON.stringify(items);
    if (raw.length > 500000) return res.status(400).json({ error: 'Payload too large' });
    try {
      await kv.setJSON(key, items);
      return res.json({ ok: true, saved: items.length });
    } catch (e) {
      return res.status(502).json({ error: 'DB write failed' });
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
};
