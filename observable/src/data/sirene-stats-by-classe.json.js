import { query, runLoader } from "./db.js";

await runLoader("sirene-stats-by-classe", (client) =>
  query(
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
  ),
);
