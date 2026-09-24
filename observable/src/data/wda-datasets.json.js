import { query, runLoader } from "./db.js";

await runLoader("wda-datasets", (client) =>
  query(
    client,
    `
  SELECT
    d.provider,
    d.dataset,
    d.wda_scope,
    d.wda_scope_ref,
    d.description,
    d.source,
    d.nb_variables,
    d.nb_observations,
    d.nb_scopes,
    p.website,
    p.description AS provider_description
  FROM wda_datasets d
  JOIN wda_providers p ON p.provider = d.provider
  ORDER BY d.provider
`,
  ),
);
