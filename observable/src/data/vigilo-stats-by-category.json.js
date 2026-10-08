import { runDuckDBLoader, parquetPath } from "./db.js";

const scopes = parquetPath("vigilo", "scopes.parquet");
const obs = parquetPath("vigilo", "observations.parquet");
const cats = parquetPath("vigilo", "categories.parquet");

await runDuckDBLoader(
  "vigilo-stats-by-category",
  `SELECT s.id AS scope_id, s.display_name AS scope_name,
          c.name AS category, c.color, COUNT(*)::INTEGER AS count
   FROM read_parquet(${JSON.stringify(obs)}) o
   JOIN read_parquet(${JSON.stringify(scopes)}) s ON s.id = o.scopeid
   JOIN read_parquet(${JSON.stringify(cats)}) c ON c.id = o.catid
   WHERE s.id IN (
     SELECT scopeid FROM read_parquet(${JSON.stringify(obs)})
     GROUP BY scopeid HAVING COUNT(*) > 200
   )
   GROUP BY s.id, s.display_name, c.name, c.color
   ORDER BY s.display_name, c.name`,
);
