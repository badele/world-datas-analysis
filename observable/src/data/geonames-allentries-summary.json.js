import { allentriesParquets, runDuckDBQuery, toJSON } from "./db.js";
import { existsSync } from "fs";
import { fileURLToPath } from "url";
import path from "path";

let fromExpr, ccExpr;

// Observable dev server runs from observable/, so resolve from this script's location
// (observable/src/data/) up to the project root (../../../)
const projectRoot = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../../..",
);

// Priority: local parquets → local allCountries.txt → remote R2
const rawFile = path.join(
  projectRoot,
  "downloaded",
  "geonames",
  "allCountries.txt",
);
const parquetResult = await allentriesParquets();

if (parquetResult && process.env.WDA_DATASET_PATH) {
  // Docker build: local parquets available
  fromExpr = `read_parquet(${parquetResult.src})`;
  ccExpr = parquetResult.ccExpr;
} else if (existsSync(rawFile)) {
  // Local dev: query allCountries.txt directly (avoids R2 rate limiting)
  const cols =
    `{'id':'INTEGER','name':'VARCHAR','asciiname':'VARCHAR','alternatenames':'VARCHAR',` +
    `'latitude':'DOUBLE','longitude':'DOUBLE','feature_class':'VARCHAR','feature_code':'VARCHAR',` +
    `'country_code':'VARCHAR','cc2':'VARCHAR','admin1_code':'VARCHAR','admin2_code':'VARCHAR',` +
    `'admin3_code':'VARCHAR','admin4_code':'VARCHAR','population':'BIGINT',` +
    `'elevation':'INTEGER','dem':'INTEGER','timezone':'VARCHAR','modification':'DATE'}`;
  fromExpr = `read_csv('${rawFile}', delim='\\t', header=false, quote='', columns=${cols})`;
  ccExpr = "country_code";
} else if (parquetResult) {
  // Last resort: R2 URLs (may hit rate limits with 388 files)
  fromExpr = `read_parquet(${parquetResult.src})`;
  ccExpr = parquetResult.ccExpr;
} else {
  process.stdout.write(
    toJSON({ stats: {}, top_cities: [], feature_codes: [], top_countries: [] }),
  );
  process.exit(0);
}

const [statsRows, citiesRows, featureRows, countriesRows, capitalsRows] =
  await Promise.all([
    runDuckDBQuery(
      "allentries-stats",
      `
    SELECT
      COUNT(*)                                                      AS total_entries,
      COUNT(DISTINCT ${ccExpr})                                     AS total_countries,
      SUM(CASE WHEN feature_class = 'P' THEN 1 ELSE 0 END)         AS populated_places,
      SUM(CASE WHEN feature_class = 'A' THEN 1 ELSE 0 END)         AS admin_entries,
      SUM(CASE WHEN feature_class = 'P' AND population > 0
               THEN population ELSE 0 END)                         AS total_population
    FROM ${fromExpr}
  `,
    ),

    runDuckDBQuery(
      "allentries-top-cities",
      `
    SELECT name, ${ccExpr} AS country_code, admin1_code, population, latitude, longitude, feature_code
    FROM ${fromExpr}
    WHERE feature_class = 'P'
      AND feature_code IN ('PPLC', 'PPLA', 'PPLA2', 'PPL')
      AND population > 0
    ORDER BY population DESC
    LIMIT 50
  `,
    ),

    runDuckDBQuery(
      "allentries-feature-codes",
      `
    SELECT feature_code, COUNT(*) AS count
    FROM ${fromExpr}
    WHERE feature_class = 'P'
    GROUP BY feature_code
    ORDER BY count DESC
    LIMIT 15
  `,
    ),

    runDuckDBQuery(
      "allentries-top-countries",
      `
    SELECT ${ccExpr} AS country_code, COUNT(*) AS count
    FROM ${fromExpr}
    WHERE feature_class = 'P'
    GROUP BY ${ccExpr}
    ORDER BY count DESC
    LIMIT 30
  `,
    ),

    runDuckDBQuery(
      "allentries-capitals",
      `
    SELECT name, ${ccExpr} AS country_code, population, latitude, longitude
    FROM ${fromExpr}
    WHERE feature_code = 'PPLC'
      AND latitude IS NOT NULL AND longitude IS NOT NULL
    ORDER BY population DESC NULLS LAST
  `,
    ),
  ]);

process.stdout.write(
  toJSON({
    stats: statsRows[0] ?? {},
    top_cities: citiesRows,
    feature_codes: featureRows,
    top_countries: countriesRows,
    capitals: capitalsRows,
  }),
);
