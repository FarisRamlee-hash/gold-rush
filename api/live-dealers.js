// Live dealer-price crosscheck. Scrapes published primary sources so the
// site never has to assume a price: dealers found here get a ✓ LIVE badge,
// everything else falls back to calibrated multipliers shown as ≈ EST.
// Every parsed number passes sanity bounds — a broken or redesigned source
// page can never leak garbage to users.
const BOUNDS = { g999: [400, 900], g916: [350, 850] }; // sane RM/gram ranges

async function fetchText(url, timeout = 7000) {
  const r = await fetch(url, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
      'Accept': 'text/html',
    },
    signal: AbortSignal.timeout(timeout),
  });
  if (!r.ok) throw new Error('HTTP ' + r.status);
  return r.text();
}
const num = s => parseFloat(String(s).replace(/,/g, ''));
const inB = (v, [lo, hi]) => Number.isFinite(v) && v >= lo && v <= hi;

// rates.my server-renders one price card per provider: a context block with
// the provider/product name, then "Anda Bayar (Beli)" and "Anda Terima (Jual)"
// values as RM<span>123.45</span>.
async function scrapeRatesMy() {
  const h = await fetchText('https://rates.my/harga-emas-hari-ini');
  const KEYS = [
    ['MIGA', 'maybankMiga'], ['BIGA', 'bankIslam'], ['eGIA', 'cimb'],
    ['MyGold', 'bsn'], ['MCA Precious', 'rhb'], ['Public Gold', 'publicGold'],
    ['Public Bank', 'pbb'], ['UOB', 'uob'], ['Maybank', 'maybankGia'],
  ];
  const out = {};
  let idx = 0;
  while ((idx = h.indexOf('Anda Bayar', idx + 1)) !== -1) {
    const ctx = h.slice(Math.max(0, idx - 1200), idx);
    const prices = [...h.slice(idx, idx + 900).matchAll(/RM<span[^>]*>([0-9,]+\.?[0-9]*)<\/span>/g)]
      .map(m => num(m[1]));
    const hit = KEYS.find(([kw]) => ctx.includes(kw));
    if (hit && !out[hit[1]] && prices.length >= 2 && inB(prices[0], BOUNDS.g999) && inB(prices[1], BOUNDS.g999)) {
      out[hit[1]] = { buy: prices[0], sell: prices[1] };
    }
  }
  return out;
}

// Public Gold publishes its GAP sell price as "RM 581 = 1.0000 gram".
async function scrapePublicGold() {
  const h = await fetchText('https://publicgold.com.my/');
  const m = h.match(/RM\s*([0-9,]+\.?[0-9]*)\s*=\s*1\.0000\s*gram/);
  const v = m && num(m[1]);
  return inB(v, BOUNDS.g999) ? { buy: v } : null;
}

// Poh Kong's footer carries the standard trade retail price:
// "999 Gold/Gram - RM660" / "916 Gold/Gram - RM610".
async function scrapePohKong() {
  const h = await fetchText('https://www.pohkong.com.my/');
  const m999 = h.match(/999 Gold\/Gram\s*-\s*RM\s*([0-9,]+\.?[0-9]*)/i);
  const m916 = h.match(/916 Gold\/Gram\s*-\s*RM\s*([0-9,]+\.?[0-9]*)/i);
  const out = {};
  if (m999 && inB(num(m999[1]), BOUNDS.g999)) out[999] = num(m999[1]);
  if (m916 && inB(num(m916[1]), BOUNDS.g916)) out[916] = num(m916[1]);
  return Object.keys(out).length ? out : null;
}

// Jeweller chains all charge the same standard trade retail price per gram
// (workmanship fees differ, per-gram gold price does not). They inherit the
// live standard price but stay flagged std:true — shown as ≈, never ✓.
const STANDARD_JEWELLERS = ['habib', 'tomei', 'wahChan', 'zhulian', 'deGem', 'selberan'];

module.exports = async (req, res) => {
  if (req.method !== 'GET') {
    res.setHeader('Allow', 'GET');
    return res.status(405).json({ error: 'Method not allowed' });
  }
  // CDN-cached 30 min: sources are scraped at most twice an hour per region.
  res.setHeader('Cache-Control', 's-maxage=1800, stale-while-revalidate=21600');
  res.setHeader('X-Content-Type-Options', 'nosniff');

  const [ratesR, pgR, pkR] = await Promise.allSettled([scrapeRatesMy(), scrapePublicGold(), scrapePohKong()]);
  const rates = ratesR.status === 'fulfilled' ? ratesR.value : {};
  const pg = pgR.status === 'fulfilled' ? pgR.value : null;
  const pk = pkR.status === 'fulfilled' ? pkR.value : null;

  const live = {};
  for (const [id, v] of Object.entries(rates)) {
    live[id] = { buy: { 999: v.buy }, sell: { 999: v.sell }, src: 'rates.my' };
  }
  if (pg) {
    // Two-source crosscheck: PG's own site vs rates.my must agree within 1.5%.
    const cross = rates.publicGold;
    const agree = cross && Math.abs(pg.buy - cross.buy) / cross.buy < 0.015;
    live.publicGold = {
      buy: { 999: pg.buy },
      sell: cross ? { 999: cross.sell } : undefined,
      src: agree ? 'publicgold.com.my ✓ rates.my' : 'publicgold.com.my',
      crosschecked: !!agree,
    };
  }
  if (pk) {
    live.pohKong = { buy: { 999: pk[999], 916: pk[916] }, src: 'pohkong.com.my' };
    for (const id of STANDARD_JEWELLERS) {
      live[id] = { buy: { 999: pk[999], 916: pk[916] }, src: 'standard trade retail', std: true };
    }
  }

  return res.json({ ts: Date.now(), count: Object.keys(live).length, live });
};
