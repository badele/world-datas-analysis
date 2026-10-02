---
title: SIRENE — Recherche établissements
---

```js
import * as Inputs from "npm:@observablehq/inputs";
import * as d3 from "npm:d3";
import * as duckdb from "npm:@duckdb/duckdb-wasm";
import { createSireneMap, effectifsLabel } from "../components/sirene-map.js";
import { initSireneStatsDB } from "../components/sirene-stats-db.js";
```

```js
const R2_BASE = "https://pub-6526c18d68154746a16baf2f76a38544.r2.dev/sirene";
const MAX_ETABS_FETCH = 50_000;

function apeParquetUrls(apeCodes) {
  return [...new Set(apeCodes)].map((a) =>
    `${R2_BASE}/observable__ape.${a}__data_0.parquet`,
  );
}

const parquetCache = new Map();
const registeredFiles = new Set(); // tracks files already in db virtual FS

async function fetchAndRegisterParquets(instance, urls) {
  const entries = [];
  for (const url of urls) {
    const baseName = url.split("/").pop();
    const apeMatch = baseName.match(/^observable__ape\.(.+?)__data_0\.parquet$/);
    const apeCode = apeMatch ? apeMatch[1] : null;
    if (!parquetCache.has(url)) {
      const resp = await fetch(url);
      if (!resp.ok) throw new Error(`Failed to fetch ${url}: ${resp.status}`);
      parquetCache.set(url, await resp.arrayBuffer());
    }
    if (!registeredFiles.has(baseName)) {
      await instance.registerFileBuffer(baseName, new Uint8Array(parquetCache.get(url).slice(0)));
      registeredFiles.add(baseName);
    }
    entries.push({ fileName: baseName, apeCode });
  }
  return entries;
}

const db = await (async () => {
  const bundles = duckdb.getJsDelivrBundles();
  const bundle = await duckdb.selectBundle(bundles);
  const workerUrl = URL.createObjectURL(
    new Blob([`importScripts("${bundle.mainWorker}");`], { type: "text/javascript" }),
  );
  const worker = new Worker(workerUrl);
  const instance = new duckdb.AsyncDuckDB(new duckdb.VoidLogger(), worker);
  await instance.instantiate(bundle.mainModule, bundle.pthreadWorker);
  invalidation.then(() => instance.terminate());
  return instance;
})();
```

```js
const { conn: _statsConn } = await initSireneStatsDB(invalidation);
const _funnelResult = await _statsConn.query(`SELECT * FROM read_parquet('funnel.parquet')`);
const funnelData = _funnelResult.toArray().map((r) => ({
  section_id: r.section_id, section_label: r.section_label,
  division_id: r.division_id, division_label: r.division_label,
  groupe_id: r.groupe_id, groupe_label: r.groupe_label,
  classe_id: r.classe_id, classe_label: r.classe_label,
  ape_id: r.ape_id, ape_label: r.ape_label,
  nb_etabs: Number(r.nb_etabs),
}));
```

<div class="page-header">
  <div class="breadcrumb"><a href="/">Accueil</a> › <a href="/sirene">SIRENE</a> › Établissements</div>
  <h1>SIRENE — Recherche d'établissements</h1>
  <p class="page-subtitle">Recherchez des établissements par secteur d'activité (APE) et/ou par nom. Les données sont chargées à la demande depuis le registre SIRENE.</p>
</div>

## Filtres

<div class="filter-bar">

```js
const sectionOptions = [
  null,
  ...[...new Set(funnelData.map((d) => d.section_id))].sort(),
];
const selectedSection = view(
  Inputs.select(sectionOptions, {
    label: "Section",
    value: null,
    format: (v) =>
      v === null
        ? "— Toutes —"
        : `${v} — ${funnelData.find((d) => d.section_id === v)?.section_label ?? ""}`,
  }),
);
```

```js
const afterSection =
  selectedSection === null
    ? funnelData
    : funnelData.filter((d) => d.section_id === selectedSection);

const divisionOptions = [
  null,
  ...[...new Set(afterSection.map((d) => d.division_id))].sort(),
];
const selectedDivision = view(
  Inputs.select(divisionOptions, {
    label: "Division",
    value: null,
    format: (v) =>
      v === null
        ? "— Toutes —"
        : `${v} — ${afterSection.find((d) => d.division_id === v)?.division_label ?? ""}`,
  }),
);
```

```js
const afterDivision =
  selectedDivision === null
    ? afterSection
    : afterSection.filter((d) => d.division_id === selectedDivision);

const groupeOptions = [
  null,
  ...[...new Set(afterDivision.map((d) => d.groupe_id))].sort(),
];
const selectedGroupe = view(
  Inputs.select(groupeOptions, {
    label: "Groupe",
    value: null,
    format: (v) =>
      v === null
        ? "— Tous —"
        : `${v} — ${afterDivision.find((d) => d.groupe_id === v)?.groupe_label ?? ""}`,
  }),
);
```

```js
const afterGroupe =
  selectedGroupe === null
    ? afterDivision
    : afterDivision.filter((d) => d.groupe_id === selectedGroupe);

const classeOptions = [
  null,
  ...[...new Set(afterGroupe.map((d) => d.classe_id))].sort(),
];
const selectedClasse = view(
  Inputs.select(classeOptions, {
    label: "Classe",
    value: null,
    format: (v) =>
      v === null
        ? "— Toutes —"
        : `${v} — ${afterGroupe.find((d) => d.classe_id === v)?.classe_label ?? ""}`,
  }),
);
```

```js
const filtered =
  selectedClasse === null
    ? afterGroupe
    : afterGroupe.filter((d) => d.classe_id === selectedClasse);
```

```js
const etabNameSearch = view(
  Inputs.text({
    label: "Nom établissement",
    placeholder: "Commence par… (ex: Renault, 77812…)",
    title: "Recherche par préfixe : saisir le début du nom, de la raison sociale ou du SIRET",
    debounce: 400,
  }),
);
```

</div>

```js
// etab row = [lat, lon, name, address, siret, effectifs_min, is_siege, date_creation, legal_name, dept, ape]
const etabsQuery = await (async () => {
  const apeList = filtered.map((d) => d.ape_id);
  if (apeList.length === 0) return { count: 0, rows: [] };

  const nameTerm = (etabNameSearch ?? "").trim();

  // Early-exit based on funnel counts (no parquet fetch needed)
  if (!nameTerm) {
    const estimatedCount = d3.sum(filtered, (d) => d.nb_etabs);
    if (estimatedCount > MAX_ETABS_FETCH) return { count: estimatedCount, rows: [] };
  }

  const urls = apeParquetUrls(apeList);
  const entries = await fetchAndRegisterParquets(db, urls);

  const nameTerm2 = nameTerm; // alias for closure
  const whereClause = nameTerm2
    ? `WHERE (name LIKE '${nameTerm2.replace(/'/g, "''")}%' OR siret LIKE '${nameTerm2.replace(/'/g, "''")}%')`
    : "";

  // UNION ALL avec APE en literal — hive_partitioning non supporté sur registerFileBuffer
  const unionSQL = entries
    .map(
      ({ fileName, apeCode }) =>
        `SELECT latitude, longitude, name, adresse, siret,
                nb_effectifs_min, is_siege,
                CAST(date_creation AS VARCHAR) AS date_creation,
                legal_name, dept,
                '${apeCode.replace(/'/g, "''")}' AS ape
         FROM read_parquet('${fileName}')`,
    )
    .join("\nUNION ALL\n");

  const conn = await db.connect();
  invalidation.then(() => conn.close().catch(() => {}));
  try {
    const countResult = await conn.query(
      `SELECT COUNT(*) AS cnt FROM (${unionSQL}) t ${whereClause}`,
    );
    const count = Number(countResult.toArray()[0].cnt);

    if (count > MAX_ETABS_FETCH) return { count, rows: [] };

    const result = await conn.query(
      `SELECT latitude, longitude, name, adresse, siret,
              nb_effectifs_min, is_siege, date_creation, legal_name, dept, ape
       FROM (${unionSQL}) t ${whereClause}
       ORDER BY nb_effectifs_min DESC NULLS LAST`,
    );

    const rows = result.toArray().map((r) => [
      r.latitude, r.longitude,
      r.name ?? "", r.adresse ?? "", r.siret ?? "",
      Number(r.nb_effectifs_min ?? 0), r.is_siege ? 1 : 0,
      r.date_creation ?? null, r.legal_name ?? "", r.dept ?? "", r.ape ?? "",
    ]);

    return { count, rows };
  } finally {
    await conn.close().catch(() => {});
  }
})();

const etabs = etabsQuery.rows;
const tooMany = etabsQuery.count > MAX_ETABS_FETCH;
```

```js
{
  display(
    html`<div class="filter-stat-grid">
      <div class="filter-stat-card filter-stat-card--${tooMany ? "orange" : "green"}">
        <div class="filter-stat-value">
          ${tooMany
            ? ">" + MAX_ETABS_FETCH.toLocaleString("fr-FR")
            : etabsQuery.count.toLocaleString("fr-FR")}
        </div>
        <div class="filter-stat-label">Établissements trouvés</div>
      </div>
    </div>`,
  );

  if (tooMany) {
    display(
      html`<div class="too-many-warning">
        <svg class="too-many-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
          fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
          <line x1="12" y1="9" x2="12" y2="13"/>
          <line x1="12" y1="17" x2="12.01" y2="17"/>
        </svg>
        <span><strong>${etabsQuery.count.toLocaleString("fr-FR")} établissements</strong>
          correspondent aux filtres — trop pour afficher (limite : ${MAX_ETABS_FETCH.toLocaleString("fr-FR")}).
          ${etabNameSearch
            ? `Affinez les filtres APE ou le préfixe du nom.`
            : `Affinez les filtres (division, groupe, classe) ou saisissez le début du nom d'un établissement.`}
        </span>
      </div>`,
    );
  }

  if (!tooMany && etabs.length > 0) {
    const mapTitle = (() => {
      if (selectedClasse) return `Classe ${selectedClasse}`;
      if (selectedGroupe) return `Groupe ${selectedGroupe}`;
      if (selectedDivision) return `Division ${selectedDivision}`;
      if (selectedSection) return `Section ${selectedSection}`;
      return etabNameSearch ? `"${etabNameSearch}…"` : "Tous secteurs";
    })();

    const mapEl = document.createElement("div");
    display(mapEl);

    const detailEl = document.createElement("div");
    detailEl.className = "etab-detail-panel";
    detailEl.style.display = "none";
    display(detailEl);

    createSireneMap(mapEl, "", etabs, {
      title: mapTitle,
      onEtabSelect(p) {
        const siren = p.siret?.slice(0, 9) ?? "";
        const dateStr = p.date_creation
          ? new Date(p.date_creation).toLocaleDateString("fr-FR", {
              year: "numeric",
              month: "long",
              day: "numeric",
            })
          : null;
        const effLabel = effectifsLabel(p.effectifs_min);
        detailEl.style.display = "block";
        detailEl.innerHTML = `
          <div class="etab-detail-header">
            <div style="display:flex;align-items:center;gap:0.6rem;flex-wrap:wrap">
              <strong class="etab-detail-name">${p.name}</strong>
              ${p.is_siege ? `<span class="etab-badge etab-badge-siege">Siège social</span>` : ""}
            </div>
            <button class="etab-detail-close" title="Fermer">✕</button>
          </div>
          <div class="etab-detail-body">
            <div class="etab-detail-col">
              ${p.address ? `<div class="etab-info-row"><span class="etab-info-label">Adresse</span><span class="etab-info-value">${p.address}</span></div>` : ""}
              ${p.dept ? `<div class="etab-info-row"><span class="etab-info-label">Département</span><span class="etab-info-value">${p.dept}</span></div>` : ""}
              ${dateStr ? `<div class="etab-info-row"><span class="etab-info-label">Ouverture</span><span class="etab-info-value">${dateStr}</span></div>` : ""}
              <div class="etab-info-row"><span class="etab-info-label">Effectifs</span><span class="etab-info-value">${effLabel}</span></div>
            </div>
            <div class="etab-detail-col">
              ${p.legal_name ? `<div class="etab-info-row"><span class="etab-info-label">Raison sociale</span><span class="etab-info-value">${p.legal_name}</span></div>` : ""}
              <div class="etab-info-row"><span class="etab-info-label">SIRET</span><span class="etab-info-value">
                ${p.siret}
                <a href="https://annuaire-entreprises.data.gouv.fr/etablissement/${p.siret}" target="_blank" class="etab-source-link etab-source-link-datagouv">data.gouv</a>
                <a href="https://data.inpi.fr/entreprises/${siren}?q=${p.siret}" target="_blank" class="etab-source-link etab-source-link-inpi">inpi</a>
              </span></div>
              <div class="etab-info-row"><span class="etab-info-label">SIREN</span><span class="etab-info-value">
                <code class="etab-siret-copy" data-siret="${siren}" title="Cliquer pour copier" onclick="navigator.clipboard.writeText(this.dataset.siret).then(()=>{this.classList.add('copied');setTimeout(()=>this.classList.remove('copied'),1200)})">${siren}</code>
                <a href="https://annuaire-entreprises.data.gouv.fr/entreprise/${siren}" target="_blank" class="etab-source-link etab-source-link-datagouv">data.gouv</a>
                <a href="https://www.pappers.fr/entreprise/${siren}" target="_blank" class="etab-source-link etab-source-link-pappers">pappers</a>
              </span></div>
              ${p.ape ? `<div class="etab-info-row"><span class="etab-info-label">Code APE</span><span class="etab-info-value"><code class="etab-siret-copy" data-siret="${p.ape}" title="Cliquer pour copier" onclick="navigator.clipboard.writeText(this.dataset.siret).then(()=>{this.classList.add('copied');setTimeout(()=>this.classList.remove('copied'),1200)})">${p.ape}</code></span></div>` : ""}
            </div>
          </div>`;
        detailEl.querySelector(".etab-detail-close").onclick = () => {
          detailEl.style.display = "none";
        };
        detailEl.classList.remove("etab-detail-panel--flash");
        void detailEl.offsetWidth;
        detailEl.classList.add("etab-detail-panel--flash");
        detailEl.scrollIntoView({ behavior: "smooth", block: "nearest" });
      },
    });

    // ── Tableau des établissements ───────────────────────────────────
    const TABLE_MAX_ROWS = 1_000;
    const tableData = etabs.slice(0, TABLE_MAX_ROWS);
    const truncated = etabs.length > TABLE_MAX_ROWS;

    display(
      html`<div style="margin-top:1.25rem">
        ${truncated
          ? html`<div class="too-many-warning" style="margin-bottom:0.75rem">
              <svg class="too-many-icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"
                fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/>
                <line x1="12" y1="9" x2="12" y2="13"/>
                <line x1="12" y1="17" x2="12.01" y2="17"/>
              </svg>
              <span>Tableau limité aux <strong>${TABLE_MAX_ROWS.toLocaleString("fr-FR")}</strong>
                premiers résultats sur ${etabs.length.toLocaleString("fr-FR")} établissements
                — affinez vos filtres pour réduire la sélection.</span>
            </div>`
          : html`<p class="etab-table-count">
              ${etabs.length.toLocaleString("fr-FR")} établissement${etabs.length > 1 ? "s" : ""}
            </p>`}
        <div style="overflow-x:auto">
          <table class="wda-table">
            <thead>
              <tr>
                <th>Établissement</th>
                <th>Adresse</th>
                <th>APE</th>
                <th>SIREN</th>
                <th>SIRET</th>
                <th>Effectifs</th>
                <th>Création</th>
              </tr>
            </thead>
            <tbody>
              ${tableData.map((r) => {
                const nom = r[2] ?? "";
                const legal = r[8] ?? "";
                const showLegal = legal && legal !== nom;
                const dept = r[9] ?? "";
                const addr = r[3] ?? "";
                const siret = r[4] ?? "";
                const siren = siret.slice(0, 9);
                const ape = r[10] ?? "";
                const dateStr = r[7]
                  ? new Date(r[7]).toLocaleDateString("fr-FR", {
                      year: "numeric",
                      month: "short",
                    })
                  : "";
                return html`<tr>
                  <td>
                    <span class="etab-nom">${nom}</span>
                    ${r[6] ? html`<span class="etab-badge etab-badge-siege">Siège</span>` : ""}
                    ${showLegal ? html`<span class="etab-legal">${legal}</span>` : ""}
                  </td>
                  <td>
                    ${dept ? html`<span class="etab-dept-tag">${dept}</span>` : ""}${addr}
                  </td>
                  <td>
                    <code class="etab-siret-copy" data-siret="${ape}" title="Cliquer pour copier"
                      onclick="navigator.clipboard.writeText(this.dataset.siret).then(()=>{this.classList.add('copied');setTimeout(()=>this.classList.remove('copied'),1200)})"
                      >${ape}</code>
                  </td>
                  <td style="white-space:nowrap">
                    <code class="etab-siret-copy" data-siret="${siren}" title="Cliquer pour copier"
                      onclick="navigator.clipboard.writeText(this.dataset.siret).then(()=>{this.classList.add('copied');setTimeout(()=>this.classList.remove('copied'),1200)})"
                      >${siren}</code><br/>
                    <a href="https://annuaire-entreprises.data.gouv.fr/entreprise/${siren}" target="_blank" class="etab-source-link etab-source-link-datagouv">data.gouv</a>
                    <a href="https://www.pappers.fr/entreprise/${siren}" target="_blank" class="etab-source-link etab-source-link-pappers">pappers</a>
                  </td>
                  <td style="white-space:nowrap">
                    <code class="etab-siret-copy" data-siret="${siret}" title="Cliquer pour copier"
                      onclick="navigator.clipboard.writeText(this.dataset.siret).then(()=>{this.classList.add('copied');setTimeout(()=>this.classList.remove('copied'),1200)})"
                      >${siret}</code><br/>
                    <a href="https://annuaire-entreprises.data.gouv.fr/etablissement/${siret}" target="_blank" class="etab-source-link etab-source-link-datagouv">data.gouv</a>
                    <a href="https://data.inpi.fr/entreprises/${siren}?q=${siret}" target="_blank" class="etab-source-link etab-source-link-inpi">inpi</a>
                  </td>
                  <td><span class="etab-effectifs-badge">${effectifsLabel(r[5])}</span></td>
                  <td style="white-space:nowrap">${dateStr}</td>
                </tr>`;
              })}
            </tbody>
          </table>
        </div>
      </div>`,
    );
  }
}
```

<div class="source-note">
  Source : <a href="/dataset/sirene">Dataset SIRENE</a> — registre national des entreprises géré par l'<a href="https://www.sirene.fr" target="_blank">INSEE</a>. Codes d'activité : <a href="/nafrev2">NAF Rév. 2</a>.
</div>

```js
display(
  html`<div class="see-also">
    <h3>Voir aussi</h3>
    <div class="see-also-links">
      <a class="see-also-link" href="/sirene">Nomenclature APE</a>
      <a class="see-also-link" href="/nafrev2">Référentiel NAF Rév. 2</a>
      <a class="see-also-link" href="/dataset/sirene">Dataset SIRENE</a>
    </div>
  </div>`,
);
```
