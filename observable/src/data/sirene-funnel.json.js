import { query, runLoader } from "./db.js";

await runLoader("sirene-funnel", (client) =>
  query(
    client,
    `
    SELECT
      sc.section_id,
      s.section                                        AS section_label,
      sc.division_id,
      d.division                                       AS division_label,
      sc.groupe_id,
      g.groupe                                         AS groupe_label,
      sc.classe_id,
      cl.classe                                        AS classe_label,
      sc.sous_classe_id                                AS ape_id,
      sc.sous_classe                                   AS ape_label,
      COUNT(e.ets_siret)::int                          AS nb_etabs
    FROM nafrev2_sous_classes sc
    JOIN nafrev2_sections  s  ON s.section_id   = sc.section_id
    JOIN nafrev2_divisions d  ON d.division_id  = sc.division_id
    JOIN nafrev2_groupes   g  ON g.groupe_id    = sc.groupe_id
    JOIN nafrev2_classes   cl ON cl.classe_id   = sc.classe_id
    LEFT JOIN wda_sirene_etablissements e ON e.insee_sous_classe_id = sc.sous_classe_id
    GROUP BY sc.section_id, s.section,
             sc.division_id, d.division,
             sc.groupe_id, g.groupe,
             sc.classe_id, cl.classe,
             sc.sous_classe_id, sc.sous_classe
    ORDER BY sc.section_id, sc.division_id, sc.groupe_id, sc.classe_id, sc.sous_classe_id
  `,
    [],
  ),
);
