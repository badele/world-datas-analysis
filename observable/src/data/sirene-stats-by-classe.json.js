import { createClient, query, toJSON } from "./db.js";

const client = createClient();
await client.connect();

const rows = await query(
  client,
  `
  SELECT
    c.section_id,
    c.division_id,
    c.groupe_id,
    c.classe_id,
    c.classe,
    COUNT(*) AS nb_etablissements
  FROM wda_sirene_etablissements e
  JOIN nafrev2_classes c ON e.insee_classe_id = c.classe_id
  GROUP BY c.section_id, c.division_id, c.groupe_id, c.classe_id, c.classe
  ORDER BY nb_etablissements DESC
`,
);

await client.end();
process.stdout.write(toJSON(rows));
