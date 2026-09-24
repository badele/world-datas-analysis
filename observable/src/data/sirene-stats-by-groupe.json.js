import { query, runLoader } from "./db.js";

await runLoader("sirene-stats-by-groupe", (client) =>
  query(
    client,
    `
  SELECT
    g.section_id,
    g.division_id,
    g.groupe_id,
    g.groupe,
    COUNT(*) AS nb_etablissements
  FROM wda_sirene_etablissements e
  JOIN nafrev2_groupes g ON e.insee_groupe_id = g.groupe_id
  GROUP BY g.section_id, g.division_id, g.groupe_id, g.groupe
  ORDER BY nb_etablissements DESC
`,
  ),
);
