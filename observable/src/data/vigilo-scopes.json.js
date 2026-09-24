import { query, runLoader } from "./db.js";

await runLoader("vigilo-scopes", (client) =>
  query(
    client,
    `
  SELECT
    id, name, display_name, iso, country, department,
    lat_min, lat_max, lon_min, lon_max,
    map_center_string, map_zoom
  FROM vigilo_scopes
  ORDER BY display_name
`,
  ),
);
