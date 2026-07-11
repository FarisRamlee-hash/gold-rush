const kv = require('../lib/kv');
const defaults = require('../lib/defaults');

// Public endpoint. Returns the effective site content: database overrides where
// present, otherwise the built-in defaults. Never errors — the site depends on it.
module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Cache-Control', 's-maxage=60, stale-while-revalidate=300');

  const out = { dealers: defaults.dealers, faq: defaults.faq, events: defaults.events, source: 'default' };
  if (kv.configured()) {
    try {
      const [dealers, faq, events] = await Promise.all([
        kv.getJSON('content:dealers'),
        kv.getJSON('content:faq'),
        kv.getJSON('content:events'),
      ]);
      if (Array.isArray(dealers) && dealers.length) out.dealers = dealers;
      if (Array.isArray(faq) && faq.length) out.faq = faq;
      if (Array.isArray(events) && events.length) out.events = events;
      out.source = 'db';
    } catch (e) {
      console.log('content db read failed:', e.message);
    }
  }
  return res.json(out);
};
