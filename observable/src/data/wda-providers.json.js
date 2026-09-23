import { createClient, query, toJSON } from "./db.js";

const client = createClient();
await client.connect();

const rows = await query(
  client,
  `
  SELECT provider, description, website, nb_datasets, nb_observations
  FROM wda_providers
  ORDER BY provider
`,
);

await client.end();
process.stdout.write(toJSON(rows));
