import { query, runLoader } from "./db.js";

await runLoader("wda-providers", (client) =>
  query(
    client,
    `
  SELECT provider, description, website, nb_datasets, nb_observations
  FROM wda_providers
  ORDER BY provider
`,
  ),
);
