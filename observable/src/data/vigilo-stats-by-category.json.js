import { createClient, query, toJSON } from "./db.js";

const client = createClient();
await client.connect();

const rows = await query(
  client,
  `
  SELECT
    s.id            AS scope_id,
    s.display_name  AS scope_name,
    c.name          AS category,
    c.color         AS color,
    COUNT(*)        AS count
  FROM wda_vigilo_observations o
  JOIN vigilo_scopes     s ON s.id = o.obs_scopeid
  JOIN vigilo_categories c ON c.id = o.obs_catid
  WHERE s.id IN (
    SELECT obs_scopeid FROM wda_vigilo_observations
    GROUP BY obs_scopeid HAVING COUNT(*) > 200
  )
  GROUP BY s.id, s.display_name, c.name, c.color
  ORDER BY s.display_name, c.name
`,
);

await client.end();
process.stdout.write(toJSON(rows));
