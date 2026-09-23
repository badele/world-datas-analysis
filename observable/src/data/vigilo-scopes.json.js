import { createClient, query, toJSON } from "./db.js";

const client = createClient();
await client.connect();

const rows = await query(
  client,
  `
  SELECT
    id, name, display_name, iso, country, department,
    lat_min, lat_max, lon_min, lon_max,
    map_center_string, map_zoom
  FROM vigilo_scopes
  ORDER BY display_name
`,
);

await client.end();
process.stdout.write(toJSON(rows));
