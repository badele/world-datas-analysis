import { createClient, query, toJSON } from "./db.js";

const client = createClient();
await client.connect();

const rows = await query(
  client,
  `
  SELECT provider, dataset, wda_scope, source, nb_variables, nb_entries
  FROM wda_scopes_reference
  ORDER BY provider, dataset
`,
);

await client.end();
process.stdout.write(toJSON(rows));
