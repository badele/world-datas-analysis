import { createClient, query, toJSON } from "./db.js";

const client = createClient();
await client.connect();

const rows = await query(
  client,
  `
  SELECT
    e.insee_sous_classe_id                                                              AS ape_id,
    e.ets_geonames_cityid                                                               AS city_id,
    e.ets_geonames_city                                                                 AS city,
    ROUND(MAX(e.ets_latitude)::numeric,  4)::float                                     AS lat,
    ROUND(MAX(e.ets_longitude)::numeric, 4)::float                                     AS lon,
    COUNT(*)                                                                            AS nb,
    SUM(CASE WHEN e.ets_minNbEffectifsEtablissement = 0  THEN 1 ELSE 0 END)            AS nb_0,
    SUM(CASE WHEN e.ets_minNbEffectifsEtablissement BETWEEN  1 AND  9 THEN 1 ELSE 0 END) AS nb_1_9,
    SUM(CASE WHEN e.ets_minNbEffectifsEtablissement BETWEEN 10 AND 49 THEN 1 ELSE 0 END) AS nb_10_49,
    SUM(CASE WHEN e.ets_minNbEffectifsEtablissement >= 50 THEN 1 ELSE 0 END)           AS nb_50plus
  FROM wda_sirene_etablissements e
  WHERE e.ets_latitude  IS NOT NULL
    AND e.ets_longitude IS NOT NULL
    AND e.insee_sous_classe_id IS NOT NULL
  GROUP BY e.insee_sous_classe_id, e.ets_geonames_cityid, e.ets_geonames_city
  ORDER BY e.insee_sous_classe_id, nb DESC
  `,
);

await client.end();

// Group by APE code to allow O(1) lookup on the client
const byApe = {};
for (const r of rows) {
  const k = r.ape_id;
  if (!byApe[k]) byApe[k] = [];
  byApe[k].push([
    r.lat,
    r.lon,
    Number(r.nb),
    Number(r.nb_0),
    Number(r.nb_1_9),
    Number(r.nb_10_49),
    Number(r.nb_50plus),
    r.city,
  ]);
}

process.stdout.write(toJSON(byApe));
