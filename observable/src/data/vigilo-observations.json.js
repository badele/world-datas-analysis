import { createClient, query, toJSON } from "./db.js";

const client = createClient();
await client.connect();

const rows = await query(
  client,
  `
  SELECT
    o.obs_scopeid                       AS scopeid,
    o.obs_token                         AS token,
    o.obs_ts                            AS ts,
    ROUND(o.obs_latitude::numeric, 6)   AS latitude,
    ROUND(o.obs_longitude::numeric, 6)  AS longitude,
    o.obs_address                       AS address,
    o.obs_comment                       AS comment,
    o.obs_catid                         AS catid,
    o.cat_name                          AS category,
    c.color,
    o.obs_approved                      AS approved,
    o.obs_city                          AS geonames_city,
    o.obs_district                      AS geonames_district
  FROM wda_vigilo_observations o
  LEFT JOIN vigilo_categories c ON c.id = o.obs_catid
  WHERE o.obs_latitude IS NOT NULL AND o.obs_longitude IS NOT NULL
  ORDER BY o.obs_ts DESC
`,
);

await client.end();
process.stdout.write(toJSON(rows));
