import { query, runLoader } from "./db.js";

await runLoader("sirene-stats-by-division", (client) =>
  query(
    client,
    `
  SELECT
    d.section_id,
    d.division_id,
    d.division,
    COUNT(*) AS nb_etablissements
  FROM wda_sirene_etablissements e
  JOIN nafrev2_divisions d ON e.insee_division_id = d.division_id
  GROUP BY d.section_id, d.division_id, d.division
  ORDER BY d.section_id, nb_etablissements DESC
`,
  ),
);
