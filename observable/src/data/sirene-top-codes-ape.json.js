import { createClient, query, toJSON } from "./db.js";

const client = createClient();
await client.connect();

const rows = await query(
  client,
  `
  SELECT
    sc.section_id,
    sc.division_id,
    sc.groupe_id,
    sc.classe_id,
    sc.sous_classe_id,
    sc.sous_classe,
    COUNT(*) AS nb_etablissements
  FROM wda_sirene_etablissements e
  JOIN nafrev2_sous_classes sc ON e.insee_sous_classe_id = sc.sous_classe_id
  GROUP BY sc.section_id, sc.division_id, sc.groupe_id, sc.classe_id, sc.sous_classe_id, sc.sous_classe
  ORDER BY nb_etablissements DESC
`,
);

await client.end();
process.stdout.write(toJSON(rows));
