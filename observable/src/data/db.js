import pg from "pg";
import Database from "duckdb";
import { fileURLToPath } from "url";
import path from "path";

export function createClient() {
  return new pg.Client({
    host: process.env.PGHOST ?? "psql",
    port: parseInt(process.env.PGPORT ?? "5432"),
    database: process.env.PGDATABASE ?? "wda",
    user: process.env.PGUSER ?? "wda",
    password: process.env.PGPASSWORD ?? "wda",
  });
}

export async function query(client, sql, params) {
  const { rows } = await client.query(sql, params);
  return rows;
}

export const toJSON = (v) =>
  JSON.stringify(v, (_, val) => (typeof val === "bigint" ? Number(val) : val));

// Returns parquet URL for a given provider and file (relative to raw/).
// Priority: local path > R2 > GitHub releases
export function parquetPath(provider, file) {
  if (process.env.WDA_DATASET_PATH) {
    return path
      .join(process.env.WDA_DATASET_PATH, provider, "raw", file)
      .replace(/\\/g, "/");
  }
  const flatName = `raw__${file.replace(/\//g, "__")}`;
  if (process.env.WDA_PUBLIC_DATASET_URL) {
    return `${process.env.WDA_PUBLIC_DATASET_URL}/${provider}/${flatName}`;
  }
  return `https://github.com/badele/world-datas-analysis/releases/download/dataset-${provider}/${flatName}`;
}

const SIRENE_SECTIONS = [
  "A",
  "B",
  "C",
  "D",
  "E",
  "F",
  "G",
  "H",
  "I",
  "J",
  "K",
  "L",
  "M",
  "N",
  "O",
  "P",
  "Q",
  "R",
  "S",
  "T",
  "U",
];

// Returns a SQL-ready expression for read_parquet() covering all sirene section files.
// Usage in SQL: `FROM read_parquet(${sireneParquets()})`
export function sireneParquets(sections = null) {
  const secs = sections ?? SIRENE_SECTIONS;
  if (process.env.WDA_DATASET_PATH) {
    const glob = path
      .join(
        process.env.WDA_DATASET_PATH,
        "sirene",
        "raw",
        "section_id=*",
        "*.parquet",
      )
      .replace(/\\/g, "/");
    return `'${glob}'`;
  }
  const base = process.env.WDA_PUBLIC_DATASET_URL
    ? `${process.env.WDA_PUBLIC_DATASET_URL}/sirene`
    : "https://github.com/badele/world-datas-analysis/releases/download/dataset-sirene";
  const urls = secs.map((s) => `${base}/raw__section_id.${s}__data_0.parquet`);
  return JSON.stringify(urls);
}

// Returns { src, ccExpr } for querying allentries parquet partitions.
// - src: SQL-ready expression for read_parquet(...)
// - ccExpr: SQL expression that resolves to the country_code value
//
// Locally, hive_partitioning=true reconstructs country_code from the path.
// Remotely, flat-named R2 files (country_code.FR) can't be parsed by DuckDB
// hive partitioning, so we extract country_code via regexp on the filename.
export async function allentriesParquets() {
  if (process.env.WDA_DATASET_PATH) {
    const glob = path
      .join(
        process.env.WDA_DATASET_PATH,
        "geonames",
        "raw",
        "allentries.parquet",
        "**",
        "*.parquet",
      )
      .replace(/\\/g, "/");
    return { src: `'${glob}', hive_partitioning=true`, ccExpr: "country_code" };
  }
  const base = process.env.WDA_PUBLIC_DATASET_URL
    ? `${process.env.WDA_PUBLIC_DATASET_URL}/geonames`
    : "https://github.com/badele/world-datas-analysis/releases/download/dataset-geonames";
  const manifestUrl = process.env.WDA_PUBLIC_DATASET_URL
    ? `${process.env.WDA_PUBLIC_DATASET_URL}/geonames/manifest-geonames.json`
    : null;
  if (manifestUrl) {
    const manifest = await fetch(manifestUrl)
      .then((r) => r.json())
      .catch(() => ({}));
    const urls = Object.keys(manifest)
      .filter((k) => k.startsWith("raw__allentries.parquet__"))
      .map((k) => `${base}/${k}`);
    if (urls.length) {
      // flat-name format: raw__allentries.parquet__country_code.FR__data_0.parquet
      const ccExpr = `regexp_extract(filename, 'country_code\\.([A-Z]+)__', 1)`;
      return { src: `${JSON.stringify(urls)}, filename=true`, ccExpr };
    }
  }
  return null;
}

export async function runDuckDBQuery(name, sql) {
  return new Promise((resolve) => {
    const db = new Database.Database(":memory:");
    db.all(sql, (err, rows) => {
      db.close();
      if (err) {
        process.stderr.write(`[DUCKDB ERROR] ${name}: ${err.message}\n`);
        resolve([]);
      } else {
        resolve(rows);
      }
    });
  });
}

export async function runDuckDBLoader(name, sql) {
  return new Promise((resolve, reject) => {
    const db = new Database.Database(":memory:");
    db.all(sql, (err, rows) => {
      db.close();
      if (err) {
        process.stderr.write(`\n${"=".repeat(60)}\n`);
        process.stderr.write(`[DUCKDB LOADER ERROR] ${name}: ${err.message}\n`);
        process.stderr.write(`${"=".repeat(60)}\n\n`);
        reject(err);
      } else {
        process.stdout.write(toJSON(rows));
        resolve();
      }
    });
  });
}

export async function runLoader(name, fn, defaultValue = []) {
  const client = createClient();
  let result = defaultValue;
  try {
    await client.connect();
    result = await fn(client);
  } catch (err) {
    process.stderr.write(`\n${"=".repeat(60)}\n`);
    process.stderr.write(`[LOADER ERROR] ${name}: ${err.message}\n`);
    process.stderr.write(`${"=".repeat(60)}\n\n`);
  } finally {
    await client.end().catch(() => {});
  }
  process.stdout.write(toJSON(result));
}
