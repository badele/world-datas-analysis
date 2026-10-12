import { runDuckDBLoader, parquetPath, toJSON } from "./db.js";

const countries = parquetPath("geonames", "countries.parquet");

try {
  await runDuckDBLoader(
    "geonames-countries",
    `SELECT iso, iso3, iso_numeric, country, capital, continent, population, area_km2,
            currency_code, currency_name, tld, languages, phone_prefix,
            neighbours, geonameid
     FROM read_parquet(${JSON.stringify(countries)})
     ORDER BY country`,
  );
} catch {
  process.stdout.write(toJSON([]));
}
