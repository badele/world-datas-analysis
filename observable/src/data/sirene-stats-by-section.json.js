import { createClient, query, toJSON } from "./db.js";

const client = createClient();
await client.connect();

const rows = await query(
  client,
  `
  SELECT
    ns.section_id,
    ns.section,
    COUNT(*) AS nb_etablissements
  FROM wda_sirene_etablissements e
  JOIN nafrev2_sections ns ON e.insee_section_id = ns.section_id
  GROUP BY ns.section_id, ns.section
  ORDER BY nb_etablissements DESC
`,
);

await client.end();
process.stdout.write(toJSON(rows));
