import { query, runLoader } from "./db.js";

await runLoader("wda-scopes-reference", (client) =>
  query(
    client,
    `
  SELECT provider, dataset, wda_scope, source, nb_variables, nb_entries
  FROM wda_scopes_reference
  ORDER BY provider, dataset
`,
  ),
);
