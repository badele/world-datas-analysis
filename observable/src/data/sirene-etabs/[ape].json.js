import { createClient, query, toJSON } from "../db.js";

const apeArg = process.argv.find((a) => a.startsWith("--ape="));
const apeId = apeArg ? apeArg.slice("--ape=".length) : process.argv[2];

const client = createClient();
let rows = [];

try {
  await client.connect();
  rows = await query(
    client,
    `
    SELECT
      ROUND(e.ets_latitude::numeric,  5)::float AS lat,
      ROUND(e.ets_longitude::numeric, 5)::float AS lon,
      COALESCE(
        NULLIF(TRIM(e.ets_denominationusuelleetablissement), ''),
        NULLIF(TRIM(e.ets_enseigne1etablissement), ''),
        NULLIF(TRIM(e.ens_denominationunitelegale), ''),
        e.ets_siret
      ) AS name,
      TRIM(CONCAT_WS(' ',
        NULLIF(TRIM(e.ets_numerovoieetablissement), ''),
        NULLIF(TRIM(e.ets_typevoieetablissement), ''),
        NULLIF(TRIM(e.ets_libellevoieetablissement), '')
      )) AS street,
      e.ets_codepostaletablissement  AS postal,
      e.ets_libellecommuneetablissement AS city,
      e.ets_siret                        AS siret,
      e.ets_minnbeffectifsetablissement  AS effectifs_min,
      e.ets_etablissementsiege           AS is_siege,
      e.ets_datecreationetablissement    AS date_creation,
      e.ens_denominationunitelegale      AS legal_name,
      e.ets_departementetablissement     AS dept
    FROM wda_sirene_etablissements e
    WHERE e.insee_sous_classe_id = $1
      AND e.ets_latitude  IS NOT NULL
      AND e.ets_longitude IS NOT NULL
    ORDER BY e.ets_minnbeffectifsetablissement DESC NULLS LAST
    `,
    [apeId],
  );
} catch (err) {
  process.stderr.write(`sirene-etabs [${apeId}]: ${err.message}\n`);
} finally {
  await client.end().catch(() => {});
}

// Compact array format: [lat, lon, name, address, siret, effectifs_min, is_siege, date_creation, legal_name, dept, ape]
const out = rows.map((r) => [
  r.lat,
  r.lon,
  r.name ?? "",
  [r.street, r.postal, r.city].filter(Boolean).join(" ") || r.city || "",
  r.siret ?? "",
  Number(r.effectifs_min ?? 0),
  r.is_siege ? 1 : 0,
  r.date_creation ?? null,
  r.legal_name ?? "",
  r.dept ?? "",
  apeId ?? "",
]);

process.stdout.write(toJSON(out));
