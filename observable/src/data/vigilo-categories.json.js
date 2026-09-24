import { query, runLoader } from "./db.js";

await runLoader("vigilo-categories", (client) =>
  query(
    client,
    `
  SELECT id, name, name_en, color
  FROM vigilo_categories
  ORDER BY id
`,
  ),
);
