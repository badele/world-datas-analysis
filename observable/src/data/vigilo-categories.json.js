import { createClient, query, toJSON } from "./db.js";

const client = createClient();
await client.connect();

const rows = await query(
  client,
  `
  SELECT id, name, name_en, color
  FROM vigilo_categories
  ORDER BY id
`,
);

await client.end();
process.stdout.write(toJSON(rows));
