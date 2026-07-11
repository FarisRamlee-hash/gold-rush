const crypto = require('crypto');

// Signing key: prefer a dedicated ADMIN_SECRET, else derive from ADMIN_PASSWORD
// so the admin only has to set one secret to get started.
function secret() { return process.env.ADMIN_SECRET || process.env.ADMIN_PASSWORD || ''; }
function configured() { return !!process.env.ADMIN_PASSWORD; }

// Stateless signed session token: base64url(payload).base64url(HMAC-SHA256).
function sign(payload) {
  const body = Buffer.from(JSON.stringify(payload)).toString('base64url');
  const sig = crypto.createHmac('sha256', secret()).update(body).digest('base64url');
  return body + '.' + sig;
}

function verify(token) {
  const s = secret();
  if (!token || !s || typeof token !== 'string') return null;
  const parts = token.split('.');
  if (parts.length !== 2) return null;
  const [body, sig] = parts;
  const expect = crypto.createHmac('sha256', s).update(body).digest('base64url');
  const a = Buffer.from(sig), b = Buffer.from(expect);
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) return null;
  try {
    const p = JSON.parse(Buffer.from(body, 'base64url').toString());
    if (!p.exp || Date.now() > p.exp) return null;
    return p;
  } catch (e) { return null; }
}

// Constant-time password comparison.
function checkPassword(input) {
  const pw = process.env.ADMIN_PASSWORD || '';
  if (!pw || typeof input !== 'string') return false;
  const a = Buffer.from(input), b = Buffer.from(pw);
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}

// Pull a bearer token from the Authorization header and verify it.
function authed(req) {
  const h = req.headers['authorization'] || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : '';
  return verify(token);
}

module.exports = { sign, verify, checkPassword, authed, configured };
