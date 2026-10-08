import { runDuckDBLoader, parquetPath } from "./db.js";

const scopes = parquetPath("vigilo", "scopes.parquet");
const obs = parquetPath("vigilo", "observations.parquet");

await runDuckDBLoader(
  "vigilo-stats",
  `SELECT s.id, s.display_name, s.is_active,
          COUNT(o.token)::INTEGER AS count,
          MIN(o.ts) AS first_ts, MAX(o.ts) AS last_ts,
          (SELECT COUNT(*)::INTEGER FROM read_parquet(${JSON.stringify(
            scopes,
          )})) AS total_scopes,
          (SELECT COUNT(*)::INTEGER FROM read_parquet(${JSON.stringify(
            scopes,
          )}) WHERE is_active = true) AS active_scopes,
          (SELECT COUNT(*)::INTEGER FROM read_parquet(${JSON.stringify(
            obs,
          )})) AS grand_total_obs
   FROM read_parquet(${JSON.stringify(scopes)}) s
   LEFT JOIN read_parquet(${JSON.stringify(obs)}) o ON o.scopeid = s.id
   GROUP BY s.id, s.display_name, s.is_active
   HAVING COUNT(o.token) > 200
   ORDER BY count DESC`,
);
