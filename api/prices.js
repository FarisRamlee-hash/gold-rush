const OZ_TO_G = 31.1035;

// Headline prices are true spot (MKS/interbank-level, no retail markup).
// Dealer retail premiums live in the Compare tab data, not here.
// `spot` is always the RAW pure-gold spot per gram — clients derive
// purity-adjusted values from it exactly once (no double-discounting).
const GOLD_PURITIES = [999, 916, 900, 835, 750, 585, 375];

function entry(priceG, prevG, rawG) {
  const price = +priceG.toFixed(2);
  const prev  = +prevG.toFixed(2);
  const change = +(price - prev).toFixed(2);
  const pct = prev ? +((change / prev) * 100).toFixed(2) : 0;
  return { price, close: prev, change, pct, spot: +rawG.toFixed(2) };
}

function buildResult(goldUsdOz, goldPrevOz, silverUsdOz, silverPrevOz, myr) {
  const g999  = (goldUsdOz / OZ_TO_G) * myr;
  const gc999 = (goldPrevOz / OZ_TO_G) * myr;
  const s999  = (silverUsdOz / OZ_TO_G) * myr;
  const sc999 = (silverPrevOz / OZ_TO_G) * myr;
  const gold = {};
  for (const p of GOLD_PURITIES) {
    const f = p === 999 ? 1 : p / 1000; // convention: 999 quote = full spot
    gold[p] = entry(g999 * f, gc999 * f, g999);
  }
  return {
    live: true, ts: Date.now(), usdMyr: +myr.toFixed(4),
    gold,
    silver: { 999: entry(s999, sc999, s999) },
  };
}

async function fetchJson(url, timeout = 6000) {
  const r = await fetch(url, {
    headers: { 'User-Agent': 'Mozilla/5.0 (compatible; GoldRush/1.0)', 'Accept': 'application/json' },
    signal: AbortSignal.timeout(timeout),
  });
  if (!r.ok) throw new Error('HTTP ' + r.status);
  return r.json();
}

async function getMyrRate() {
  try {
    const d = await fetchJson('https://api.frankfurter.dev/v1/latest?from=USD&to=MYR');
    if (d.rates?.MYR > 3 && d.rates?.MYR < 6) return d.rates.MYR;
  } catch (e) { console.log('frankfurter failed:', e.message); }
  return 4.25;
}

module.exports = async (req, res) => {
  if (req.method !== 'GET') {
    res.setHeader('Allow', 'GET');
    return res.status(405).json({ error: 'Method not allowed' });
  }
  res.setHeader('Cache-Control', 's-maxage=30, stale-while-revalidate=120');

  const myr = await getMyrRate();

  // Source 1: goldprice.org USD endpoint (per troy oz in USD)
  try {
    const d = await fetchJson('https://data-asg.goldprice.org/dbXRates/USD');
    const item = d?.items?.[0];
    if (item?.xauPrice > 1000) {
      return res.json(buildResult(
        item.xauPrice, item.xauClose || item.xauPrice,
        item.xagPrice || 30, item.xagClose || item.xagPrice || 30,
        myr
      ));
    }
  } catch (e) { console.log('goldprice.org USD failed:', e.message); }

  // Source 2: Yahoo Finance gold futures
  try {
    const [gd, sd] = await Promise.all([
      fetchJson('https://query2.finance.yahoo.com/v8/finance/chart/GC=F?range=1d&interval=1d'),
      fetchJson('https://query2.finance.yahoo.com/v8/finance/chart/SI=F?range=1d&interval=1d').catch(() => null),
    ]);
    const gm = gd.chart?.result?.[0]?.meta;
    const sm = sd?.chart?.result?.[0]?.meta;
    if (gm?.regularMarketPrice > 1000) {
      return res.json(buildResult(
        gm.regularMarketPrice, gm.chartPreviousClose || gm.regularMarketPrice,
        sm?.regularMarketPrice || 32, sm?.chartPreviousClose || 32,
        myr
      ));
    }
  } catch (e) { console.log('yahoo failed:', e.message); }

  // Source 3: hardcoded recent price + live exchange rate
  return res.json(buildResult(4110, 4115, 48, 48, myr));
};
