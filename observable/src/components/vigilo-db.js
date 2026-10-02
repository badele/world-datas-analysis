import * as duckdb from "npm:@duckdb/duckdb-wasm";

function vigiloParquetUrl(file, baseUrl) {
  return `${baseUrl}/raw__${file}`;
}

const _parquetCache = new Map();

async function fetchBuffer(url) {
  if (!_parquetCache.has(url)) {
    const resp = await fetch(url);
    if (!resp.ok) throw new Error(`Failed to fetch ${url}: ${resp.status}`);
    _parquetCache.set(url, new Uint8Array(await resp.arrayBuffer()));
  }
  return _parquetCache.get(url);
}

let _dbPromise = null;

export async function initVigiloDB(baseUrl, invalidation = null) {
  if (_dbPromise) return _dbPromise;
  _dbPromise = (async () => {
    const bundles = duckdb.getJsDelivrBundles();
    const bundle = await duckdb.selectBundle(bundles);
    const workerUrl = URL.createObjectURL(
      new Blob([`importScripts("${bundle.mainWorker}");`], { type: "text/javascript" }),
    );
    const worker = new Worker(workerUrl);
    const db = new duckdb.AsyncDuckDB(new duckdb.VoidLogger(), worker);
    await db.instantiate(bundle.mainModule, bundle.pthreadWorker);
    for (const f of ["observations.parquet", "scopes.parquet", "categories.parquet"]) {
      await db.registerFileBuffer(f, await fetchBuffer(vigiloParquetUrl(f, baseUrl)));
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
