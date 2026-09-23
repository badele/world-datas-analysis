import { createClient, query, toJSON } from "./db.js";

const client = createClient();
await client.connect();

const rows = await query(
  client,
  `
  SELECT
    s.section_id,
    s.section,
    COUNT(DISTINCT d.division_id)     AS nb_divisions,
    COUNT(DISTINCT g.groupe_id)       AS nb_groupes,
    COUNT(DISTINCT c.classe_id)       AS nb_classes,
    COUNT(DISTINCT sc.sous_classe_id) AS nb_sous_classes
  FROM nafrev2_sections s
  LEFT JOIN nafrev2_divisions    d  ON d.section_id  = s.section_id
  LEFT JOIN nafrev2_groupes      g  ON g.section_id  = s.section_id
  LEFT JOIN nafrev2_classes      c  ON c.section_id  = s.section_id
  LEFT JOIN nafrev2_sous_classes sc ON sc.section_id = s.section_id
  GROUP BY s.section_id, s.section
  ORDER BY s.section_id
`,
);

await client.end();
process.stdout.write(toJSON(rows));
