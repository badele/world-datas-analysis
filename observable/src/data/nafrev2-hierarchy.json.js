import { createClient, query, toJSON } from "./db.js";

const client = createClient();
await client.connect();

const rows = await query(
  client,
  `
  SELECT
    ns.section_id,
    ns.section,
    nd.division_id,
    nd.division,
    ng.groupe_id,
    ng.groupe,
    nc.classe_id,
    nc.classe,
    nsc.sous_classe_id,
    nsc.sous_classe
  FROM nafrev2_sous_classes nsc
  JOIN nafrev2_classes      nc  ON nsc.classe_id    = nc.classe_id
  JOIN nafrev2_groupes      ng  ON nsc.groupe_id    = ng.groupe_id
  JOIN nafrev2_divisions    nd  ON nsc.division_id  = nd.division_id
  JOIN nafrev2_sections     ns  ON nsc.section_id   = ns.section_id
  ORDER BY nsc.sous_classe_id
`,
);

await client.end();
process.stdout.write(toJSON(rows));
