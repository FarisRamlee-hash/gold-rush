const OZ_TO_G = 31.1035;

const TF = {
  '1D': { range: '1d',  interval: '15m', cache: 300 },
  '7D': { range: '7d',  interval: '1h',  cache: 900 },
  '1M': { range: '1mo', interval: '1d',  cache: 3600 },
  '3M': { range: '3mo', interval: '1d',  cache: 3600 },
  '6M': { range: '6mo', interval: '1d',  cache: 3600 },
  '1Y': { range: '1y',  interval: '1d',  cache: 3600 },
};

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

  const tf = TF[req.query?.tf] ? req.query.tf : '1Y';
  const metal = req.query?.metal === 'silver' ? 'silver' : 'gold';
  const sym = metal === 'silver' ? 'SI=F' : 'GC=F';
  const cfg = TF[tf];
  res.setHeader('Cache-Control', `s-maxage=${cfg.cache}, stale-while-revalidate=${cfg.cache * 2}`);

  const myr = await getMyrRate();

  try {
    const d = await fetchJson(`https://query2.finance.yahoo.com/v8/finance/chart/${sym}?range=${cfg.range}&interval=${cfg.interval}`);
    const r0 = d.chart?.result?.[0];
    const ts = r0?.timestamp || [];
    const closes = r0?.indicators?.quote?.[0]?.close || [];
    const points = [];
    for (let i = 0; i < ts.length; i++) {
      const c = closes[i];
      if (typeof c === 'number' && c > 0) points.push({ t: ts[i] * 1000, y: +((c / OZ_TO_G) * myr).toFixed(2) });
    }
    if (points.length < 5) throw new Error('insufficient data');
    return res.json({ live: true, tf, metal, usdMyr: +myr.toFixed(4), count: points.length, points });
  } catch (e) {
    console.log('history failed:', e.message);
    return res.status(502).json({ live: false, error: 'history unavailable' });
  }
};
