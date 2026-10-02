import { parquetPath, sireneParquets, runDuckDBQuery, toJSON } from "./db.js";

const vigiloObs = parquetPath("vigilo", "observations.parquet");
const vigiloScopes = parquetPath("vigilo", "scopes.parquet");
const sireneEts = sireneParquets();

const [vigilo = {}] = await runDuckDBQuery(
  "datasets-stats-vigilo",
  `
  SELECT
    COUNT(*)                                                                          AS total_obs,
    (SELECT COUNT(*) FROM read_parquet('${vigiloScopes}'))                            AS total_scopes,
    (SELECT COUNT(*) FROM read_parquet('${vigiloScopes}') WHERE is_active)            AS active_scopes,
    MAX(ts)                                                                           AS last_ts
  FROM read_parquet('${vigiloObs}')
`,
);

let sirene = { total_etablissements: 0, total_sections: 0 };
try {
  const [row] = await runDuckDBQuery(
    "datasets-stats-sirene",
    `
    SELECT COUNT(*) AS total_etablissements, COUNT(DISTINCT section_id) AS total_sections
    FROM read_parquet(${sireneEts})
  `,
  );
  if (row) sirene = row;
} catch (_) {}

const [nafrev2 = {}] = await runDuckDBQuery(
  "datasets-stats-nafrev2",
  `
  SELECT
    (SELECT COUNT(*) FROM read_parquet('${parquetPath(
      "nafrev2",
      "sections.parquet",
    )}'))     AS total_sections,
    (SELECT COUNT(*) FROM read_parquet('${parquetPath(
      "nafrev2",
      "divisions.parquet",
    )}'))    AS total_divisions,
    (SELECT COUNT(*) FROM read_parquet('${parquetPath(
      "nafrev2",
      "groupes.parquet",
    )}'))      AS total_groupes,
    (SELECT COUNT(*) FROM read_parquet('${parquetPath(
      "nafrev2",
      "classes.parquet",
    )}'))      AS total_classes,
    (SELECT COUNT(*) FROM read_parquet('${parquetPath(
      "nafrev2",
      "sous_classes.parquet",
    )}')) AS total_sous_classes
`,
);

process.stdout.write(
  toJSON([
    {
      id: "vigilo",
      total_obs: Number(vigilo.total_obs ?? 0),
      total_scopes: Number(vigilo.total_scopes ?? 0),
      active_scopes: Number(vigilo.active_scopes ?? 0),
      last_ts: vigilo.last_ts ?? null,
    },
    {
      id: "sirene",
      total_etablissements: Number(sirene.total_etablissements ?? 0),
      total_sections: Number(sirene.total_sections ?? 0),
    },
    {
      id: "nafrev2",
      total_sections: Number(nafrev2.total_sections ?? 0),
      total_divisions: Number(nafrev2.total_divisions ?? 0),
      total_groupes: Number(nafrev2.total_groupes ?? 0),
      total_classes: Number(nafrev2.total_classes ?? 0),
      total_sous_classes: Number(nafrev2.total_sous_classes ?? 0),
    },
  ]),
);
