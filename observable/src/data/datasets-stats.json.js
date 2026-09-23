import { createClient, query, toJSON } from "./db.js";

const client = createClient();
await client.connect();

const [vigilo] = await query(
  client,
  `
  SELECT
    COUNT(*)                                                        AS total_obs,
    (SELECT COUNT(*) FROM vigilo_scopes)                           AS total_scopes,
    (SELECT COUNT(*) FROM vigilo_scopes WHERE is_active = true)    AS active_scopes,
    MAX(obs_ts)                                                    AS last_ts
  FROM wda_vigilo_observations
`,
);

const [sirene] = await query(
  client,
  `
  SELECT
    COUNT(*)                         AS total_etablissements,
    COUNT(DISTINCT insee_section_id) AS total_sections
  FROM wda_sirene_etablissements
`,
);

const [nafrev2] = await query(
  client,
  `
  SELECT
    (SELECT COUNT(*) FROM nafrev2_sections)     AS total_sections,
    (SELECT COUNT(*) FROM nafrev2_divisions)    AS total_divisions,
    (SELECT COUNT(*) FROM nafrev2_groupes)      AS total_groupes,
    (SELECT COUNT(*) FROM nafrev2_classes)      AS total_classes,
    (SELECT COUNT(*) FROM nafrev2_sous_classes) AS total_sous_classes
`,
);

await client.end();

process.stdout.write(
  toJSON([
    {
      id: "vigilo",
      total_obs: Number(vigilo.total_obs),
      total_scopes: Number(vigilo.total_scopes),
      active_scopes: Number(vigilo.active_scopes),
      last_ts: vigilo.last_ts,
    },
    {
      id: "sirene",
      total_etablissements: Number(sirene.total_etablissements),
      total_sections: Number(sirene.total_sections),
    },
    {
      id: "nafrev2",
      total_sections: Number(nafrev2.total_sections),
      total_divisions: Number(nafrev2.total_divisions),
      total_groupes: Number(nafrev2.total_groupes),
      total_classes: Number(nafrev2.total_classes),
      total_sous_classes: Number(nafrev2.total_sous_classes),
    },
  ]),
);
