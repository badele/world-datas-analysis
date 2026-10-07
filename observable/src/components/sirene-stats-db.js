import * as duckdb from "npm:@duckdb/duckdb-wasm";

const R2_BASE = "https://pub-6526c18d68154746a16baf2f76a38544.r2.dev/sirene";
const STATS_FILES = [
  "funnel",
  "stats-by-section",
  "stats-by-division",
  "stats-by-groupe",
  "stats-by-classe",
  "top-codes-ape",
];

const _parquetCache = new Map();

async function fetchBuffer(url) {
  if (!_parquetCache.has(url)) {
    const resp = await fetch(url);
    if (!resp.ok) throw new Error(`Failed to fetch ${url}: ${resp.status}`);
    _parquetCache.set(url, await resp.arrayBuffer());
  }
  return new Uint8Array(_parquetCache.get(url).slice(0));
}

let _dbPromise = null;

export async function initSireneStatsDB(invalidation = null) {
  if (_dbPromise) return _dbPromise;
  _dbPromise = (async () => {
    const bundles = duckdb.getJsDelivrBundles();
    const bundle = await duckdb.selectBundle(bundles);
    const workerUrl = URL.createObjectURL(
      new Blob([`importScripts("${bundle.mainWorker}");`], {
        type: "text/javascript",
      }),
    );
    const worker = new Worker(workerUrl);
    const db = new duckdb.AsyncDuckDB(new duckdb.VoidLogger(), worker);
    await db.instantiate(bundle.mainModule, bundle.pthreadWorker);
    for (const f of STATS_FILES) {
      await db.registerFileBuffer(
        `${f}.parquet`,
        await fetchBuffer(`${R2_BASE}/observable__${f}.parquet`),
      );
    }
    const conn = await db.connect();
    return { db, conn };
  })();
  if (invalidation) {
    invalidation.then(async () => {
      const cached = _dbPromise;
      _dbPromise = null;
      if (cached) (await cached).db.terminate();
    });
  }
  return _dbPromise;
}
