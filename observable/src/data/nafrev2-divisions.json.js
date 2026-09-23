import { createClient, query, toJSON } from "./db.js";

const client = createClient();
await client.connect();

const rows = await query(
  client,
  `
  SELECT
    d.section_id,
    d.division_id,
    d.division,
    COUNT(DISTINCT g.groupe_id)       AS nb_groupes,
    COUNT(DISTINCT c.classe_id)       AS nb_classes,
    COUNT(DISTINCT sc.sous_classe_id) AS nb_sous_classes
  FROM nafrev2_divisions d
  LEFT JOIN nafrev2_groupes      g  ON g.division_id = d.division_id
  LEFT JOIN nafrev2_classes      c  ON c.division_id = d.division_id
  LEFT JOIN nafrev2_sous_classes sc ON sc.division_id = d.division_id
  GROUP BY d.section_id, d.division_id, d.division
  ORDER BY d.section_id, d.division_id
`,
);

await client.end();
process.stdout.write(toJSON(rows));
