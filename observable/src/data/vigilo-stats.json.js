import { query, runLoader } from "./db.js";

await runLoader("vigilo-stats", (client) =>
  query(
    client,
    `
  SELECT
    s.id,
    s.display_name,
    s.is_active,
    s.map_center_string,
    s.map_zoom,
    s.lat_min, s.lat_max, s.lon_min, s.lon_max,
    COUNT(o.obs_token)                    AS count,
    MIN(o.obs_ts)                         AS first_ts,
    MAX(o.obs_ts)                         AS last_ts,
    (SELECT COUNT(*) FROM vigilo_scopes)                        AS total_scopes,
    (SELECT COUNT(*) FROM vigilo_scopes WHERE is_active = true) AS active_scopes,
    (SELECT COUNT(*) FROM wda_vigilo_observations)              AS grand_total_obs
  FROM vigilo_scopes s
  LEFT JOIN wda_vigilo_observations o ON o.obs_scopeid = s.id
  GROUP BY s.id, s.display_name, s.is_active, s.map_center_string, s.map_zoom,
           s.lat_min, s.lat_max, s.lon_min, s.lon_max
  HAVING COUNT(o.obs_token) > 200
  ORDER BY count DESC
`,
  ),
);
