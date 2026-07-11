// Thin Upstash Redis REST client (no dependency — uses fetch).
// Env vars are auto-injected when you add Upstash/KV from the Vercel Marketplace.
const URL_ = process.env.KV_REST_API_URL || process.env.UPSTASH_REDIS_REST_URL || '';
const TOKEN = process.env.KV_REST_API_TOKEN || process.env.UPSTASH_REDIS_REST_TOKEN || '';

function configured() { return !!(URL_ && TOKEN); }

async function cmd(args) {
  const r = await fetch(URL_, {
    method: 'POST',
    headers: { Authorization: 'Bearer ' + TOKEN, 'Content-Type': 'application/json' },
    body: JSON.stringify(args),
    signal: AbortSignal.timeout(6000),
  });
  if (!r.ok) throw new Error('kv ' + r.status);
  const d = await r.json();
  if (d.error) throw new Error('kv ' + d.error);
  return d.result;
}

async function getJSON(key) {
  const v = await cmd(['GET', key]);
  if (v == null) return null;
  try { return JSON.parse(v); } catch (e) { return null; }
}
async function setJSON(key, val) { return cmd(['SET', key, JSON.stringify(val)]); }
async function lpush(key, val) { return cmd(['LPUSH', key, JSON.stringify(val)]); }
async function lrange(key, a, b) {
  const v = await cmd(['LRANGE', key, String(a), String(b)]);
  return Array.isArray(v) ? v.map(x => { try { return JSON.parse(x); } catch (e) { return x; } }) : [];
}
async function llen(key) { return cmd(['LLEN', key]); }

module.exports = { configured, cmd, getJSON, setJSON, lpush, lrange, llen };
