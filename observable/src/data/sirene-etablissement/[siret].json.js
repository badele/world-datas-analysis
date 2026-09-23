import { createClient, query, toJSON } from "../db.js";

const siretArg = process.argv.find((a) => a.startsWith("--siret="));
const siret = siretArg ? siretArg.slice("--siret=".length) : process.argv[2];

const client = createClient();
let row = null;

try {
  await client.connect();
  const rows = await query(
    client,
    `
    SELECT
      e.ets_siret                         AS siret,
      e.ets_siren                         AS siren,
      e.ets_nic                           AS nic,
      COALESCE(
        NULLIF(TRIM(e.ets_denominationusuelleetablissement), ''),
        NULLIF(TRIM(e.ets_enseigne1etablissement), ''),
        NULLIF(TRIM(e.ens_denominationunitelegale), ''),
        e.ets_siret
      )                                   AS name,
      e.ens_denominationunitelegale       AS legal_name,
      e.ens_sigleunitelegalale            AS sigle,
      TRIM(CONCAT_WS(' ',
        NULLIF(TRIM(e.ets_numerovoieetablissement), ''),
        NULLIF(TRIM(e.ets_typevoieetablissement), ''),
        NULLIF(TRIM(e.ets_libellevoieetablissement), '')
      ))                                  AS street,
      e.ets_codepostaletablissement       AS postal,
      e.ets_libellecommuneetablissement   AS city,
      e.ets_departementetablissement      AS dept,
      e.ets_datecreationetablissement     AS date_creation,
      e.ets_minnbeffectifsetablissement   AS effectifs_min,
      e.ets_etablissementsiege            AS is_siege,
      e.ens_nicsiegerunitelegalale        AS nic_siege,
      e.ets_activiteprincipaleEtablissement AS ape_code,
      e.insee_sous_classe                 AS ape_label,
      e.insee_section_id,
      e.insee_division_id,
      e.insee_groupe_id,
      e.insee_classe_id,
      e.insee_sous_classe_id,
      e.insee_section,
      e.insee_division,
      e.ens_categorieentreprise           AS categorie,
      e.ens_datecreationunitelegalale     AS date_creation_ue,
      e.ets_latitude                      AS latitude,
      e.ets_longitude                     AS longitude
    FROM wda_sirene_etablissements e
    WHERE e.ets_siret = $1
    LIMIT 1
    `,
    [siret],
  );
  row = rows[0] ?? null;
} catch (err) {
  process.stderr.write(`sirene-etablissement [${siret}]: ${err.message}\n`);
} finally {
  await client.end().catch(() => {});
}

process.stdout.write(toJSON(row));
