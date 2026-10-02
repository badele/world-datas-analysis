---
title: SIRENE — Recherche par APE
---

```js
import * as Inputs from "npm:@observablehq/inputs";
import * as d3 from "npm:d3";
import * as duckdb from "npm:@duckdb/duckdb-wasm";
import { showPopup } from "./components/popup.js";
import { createSireneMap } from "./components/sirene-map.js";
import { initSireneStatsDB } from "./components/sirene-stats-db.js";
```

```js
display(
  html`<div id="sirene-stats-loading" class="map-loading" style="margin:2rem 0">
    <div class="map-loading-spinner"></div>
    <span>Chargement des statistiques SIRENE…</span>
  </div>`,
);

const { conn: _statsConn } = await initSireneStatsDB(invalidation);

const _funnelResult = await _statsConn.query(
  `SELECT * FROM read_parquet('funnel.parquet')`,
);
const funnelData = _funnelResult.toArray().map((r) => ({
  section_id: r.section_id,
  section_label: r.section_label,
  division_id: r.division_id,
  division_label: r.division_label,
  groupe_id: r.groupe_id,
  groupe_label: r.groupe_label,
  classe_id: r.classe_id,
  classe_label: r.classe_label,
  ape_id: r.ape_id,
  ape_label: r.ape_label,
  nb_etabs: Number(r.nb_etabs),
}));

const _secResult = await _statsConn.query(
  `SELECT * FROM read_parquet('stats-by-section.parquet')`,
);
const statsBySection = _secResult.toArray().map((r) => ({
  section_id: r.section_id,
  section: r.section,
  nb_etablissements: Number(r.nb_etablissements),
}));

document.getElementById("sirene-stats-loading")?.remove();
```

```js
const R2_BASE = "https://pub-6526c18d68154746a16baf2f76a38544.r2.dev/sirene";
const MAX_MAP_ETABS = 2_000_000;

function apeParquetUrls(apeCodes) {
  return [...new Set(apeCodes)].map(
    (a) => `${R2_BASE}/observable__ape.${a}__data_0.parquet`,
  );
}

const parquetCache = new Map();
const registeredFiles = new Set(); // tracks files already in _mapDb virtual FS

async function fetchAndRegisterParquets(instance, urls) {
  const entries = [];
  for (const url of urls) {
    const baseName = url.split("/").pop();
    const apeMatch = baseName.match(
      /^observable__ape\.(.+?)__data_0\.parquet$/,
    );
    const apeCode = apeMatch ? apeMatch[1] : null;
    if (!parquetCache.has(url)) {
      const resp = await fetch(url);
      if (!resp.ok) throw new Error(`Failed to fetch ${url}: ${resp.status}`);
      parquetCache.set(url, await resp.arrayBuffer());
    }
    if (!registeredFiles.has(baseName)) {
      await instance.registerFileBuffer(
        baseName,
        new Uint8Array(parquetCache.get(url).slice(0)),
      );
      registeredFiles.add(baseName);
    }
    entries.push({ fileName: baseName, apeCode });
  }
  return entries;
}
```

```js
const totalEtablissements = d3.sum(statsBySection, (d) => +d.nb_etablissements);
```

<div class="page-header">
  <div class="breadcrumb"><a href="/">Accueil</a> › SIRENE</div>
  <h1>SIRENE — Recherche par APE</h1>
  <p class="page-subtitle">Répartition des ${totalEtablissements.toLocaleString("fr-FR")} établissements du registre SIRENE selon la nomenclature NAF Rév. 2.</p>
</div>

<div class="stat-grid">
  <div class="stat-card">
    <div class="stat-value">${totalEtablissements.toLocaleString("fr-FR")}</div>
    <div class="stat-label">Total établissements</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${new Set(funnelData.map(d => d.section_id)).size}</div>
    <div class="stat-label">Sections</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${new Set(funnelData.map(d => d.division_id)).size}</div>
    <div class="stat-label">Divisions</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${new Set(funnelData.map(d => d.groupe_id)).size}</div>
    <div class="stat-label">Groupes</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${new Set(funnelData.map(d => d.classe_id)).size}</div>
    <div class="stat-label">Classes</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${new Set(funnelData.map(d => d.ape_id)).size}</div>
    <div class="stat-label">Codes APE</div>
  </div>
</div>

## Explorer la nomenclature

<div class="filter-bar">

```js
const searched = view(
  Inputs.search(funnelData, {
    label: "Recherche",
    placeholder: "Code APE, libellé, secteur…",
    columns: [
      "section_id",
      "section_label",
      "division_id",
      "division_label",
      "groupe_id",
      "groupe_label",
      "classe_id",
      "classe_label",
      "ape_id",
      "ape_label",
    ],
  }),
);
```

```js
const sectionOptions = [
  null,
  ...[...new Set(searched.map((d) => d.section_id))].sort(),
];
const selectedSection = view(
  Inputs.select(sectionOptions, {
    label: "Section",
    value: null,
    format: (v) =>
      v === null
        ? "— Toutes —"
        : `${v} — ${
            searched.find((d) => d.section_id === v)?.section_label ?? ""
          }`,
  }),
);
```

```js
const afterSection =
  selectedSection === null
    ? searched
    : searched.filter((d) => d.section_id === selectedSection);

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
        : `${v} — ${
            afterSection.find((d) => d.division_id === v)?.division_label ?? ""
          }`,
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
        : `${v} — ${
            afterDivision.find((d) => d.groupe_id === v)?.groupe_label ?? ""
          }`,
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
        : `${v} — ${
            afterGroupe.find((d) => d.classe_id === v)?.classe_label ?? ""
          }`,
  }),
);
```

```js
const filtered =
  selectedClasse === null
    ? afterGroupe
    : afterGroupe.filter((d) => d.classe_id === selectedClasse);
```

</div>

```js
const nSec = new Set(filtered.map((d) => d.section_id)).size;
const nDiv = new Set(filtered.map((d) => d.division_id)).size;
const nGrp = new Set(filtered.map((d) => d.groupe_id)).size;
const nCls = new Set(filtered.map((d) => d.classe_id)).size;
const nApe = filtered.length;
const nEtabs = d3.sum(filtered, (d) => +d.nb_etabs);

display(
  html`<div class="filter-stat-grid">
    <div class="filter-stat-card">
      <div class="filter-stat-value">${nSec}</div>
      <div class="filter-stat-label">Section${nSec > 1 ? "s" : ""}</div>
    </div>
    <div class="filter-stat-card">
      <div class="filter-stat-value">${nDiv}</div>
      <div class="filter-stat-label">Division${nDiv > 1 ? "s" : ""}</div>
    </div>
    <div class="filter-stat-card">
      <div class="filter-stat-value">${nGrp}</div>
      <div class="filter-stat-label">Groupe${nGrp > 1 ? "s" : ""}</div>
    </div>
    <div class="filter-stat-card">
      <div class="filter-stat-value">${nCls}</div>
      <div class="filter-stat-label">Classe${nCls > 1 ? "s" : ""}</div>
    </div>
    <div class="filter-stat-card filter-stat-card--accent">
      <div class="filter-stat-value">${nApe}</div>
      <div class="filter-stat-label">Code${nApe > 1 ? "s" : ""} APE</div>
    </div>
    <div class="filter-stat-card filter-stat-card--green">
      <div class="filter-stat-value">${nEtabs.toLocaleString("fr-FR")}</div>
      <div class="filter-stat-label">Établissements</div>
    </div>
  </div>`,
);
```

```js
// DuckDB instance initialisée une seule fois au chargement de la page
const _mapDb = await (async () => {
  const bundles = duckdb.getJsDelivrBundles();
  const bundle = await duckdb.selectBundle(bundles);
  const workerUrl = URL.createObjectURL(
    new Blob([`importScripts("${bundle.mainWorker}");`], {
      type: "text/javascript",
    }),
  );
  const worker = new Worker(workerUrl);
  const instance = new duckdb.AsyncDuckDB(new duckdb.VoidLogger(), worker);
  await instance.instantiate(bundle.mainModule, bundle.pthreadWorker);
  invalidation.then(() => instance.terminate());
  return instance;
})();
```

```js
const mapQuery = await (async () => {
  // Debounce 400ms — attend l'arrêt de frappe avant de lancer le fetch
  await new Promise((resolve) => {
    const t = setTimeout(resolve, 400);
    invalidation.then(() => clearTimeout(t));
  });

  if (nEtabs === 0) return { tooMany: false, rows: [] };
  if (nEtabs > MAX_MAP_ETABS) return { tooMany: true, rows: [] };

  const apeIds = filtered.map((d) => d.ape_id);
  const urls = apeParquetUrls(apeIds);
  const entries = await fetchAndRegisterParquets(_mapDb, urls);

  const conn = await _mapDb.connect();
  invalidation.then(() => conn.close().catch(() => {}));
  try {
    // UNION ALL avec APE en literal — hive_partitioning non supporté sur registerFileBuffer
    const parts = entries.map(
      ({ fileName, apeCode }) =>
        `SELECT latitude, longitude, name, legal_name, adresse, siret,
                nb_effectifs_min, is_siege, date_creation, dept,
                '${apeCode.replace(/'/g, "''")}' AS ape
         FROM read_parquet('${fileName}')`,
    );
    const result = await conn.query(
      parts.join("\nUNION ALL\n") +
        "\nORDER BY nb_effectifs_min DESC NULLS LAST",
    );
    const rows = result
      .toArray()
      .map((r) => [
        r.latitude,
        r.longitude,
        r.name ?? "",
        r.adresse ?? "",
        r.siret ?? "",
        Number(r.nb_effectifs_min ?? 0),
        r.is_siege ? 1 : 0,
        r.date_creation ?? null,
        r.legal_name ?? "",
        r.dept ?? "",
        r.ape ?? "",
      ]);
    return { tooMany: false, rows };
  } finally {
    await conn.close().catch(() => {});
  }
})();
```

## Répartition géographique

```js
if (nEtabs > 0 && nEtabs <= MAX_MAP_ETABS) {
  display(
    html`<div id="sirene-map-loading" class="map-loading">
      <div class="map-loading-spinner"></div>
      <span>Chargement des données géographiques…</span>
    </div>`,
  );
}
```

```js
{
  document.getElementById("sirene-map-loading")?.remove();

  if (nEtabs === 0) {
    // nothing
  } else if (mapQuery.tooMany) {
    display(
      html`<div class="too-many-warning">
        <svg
          class="too-many-icon"
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path
            d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"
          />
          <line x1="12" y1="9" x2="12" y2="13" />
          <line x1="12" y1="17" x2="12.01" y2="17" />
        </svg>
        <span>
          <strong>${nEtabs.toLocaleString("fr-FR")} établissements</strong>
          — trop pour afficher la carte (limite : ${MAX_MAP_ETABS.toLocaleString(
            "fr-FR",
          )}). Affinez la sélection jusqu'à la classe ou au code APE pour voir la
          répartition géographique.
        </span>
      </div>`,
    );
  } else if (mapQuery.rows.length > 0) {
    const container = document.createElement("div");
    display(container);
    const apeLabel =
      filtered.length === 1
        ? filtered[0].ape_id
        : `${filtered.length} codes APE`;
    createSireneMap(container, "", mapQuery.rows, { title: apeLabel });
  }
}
```

```js
window.wdaShowApePopup = (event, cell) => {
  const ds = cell.dataset;
  showPopup(event, {
    title: `Code APE — ${ds.apeId}`,
    rows: [
      { label: "Code APE", id: ds.apeId, value: ds.ape },
      { label: "Classe", id: ds.classeId, value: ds.classe },
      { label: "Groupe", id: ds.groupeId, value: ds.groupe },
      { label: "Division", id: ds.divisionId, value: ds.division },
      { label: "Section", id: ds.sectionId, value: ds.section },
      {
        label: "Établissements",
        id: "",
        value: Number(ds.nbEtabs).toLocaleString("fr-FR"),
      },
    ],
  });
};
```

```js
const sorted = filtered
  .slice()
  .sort((a, b) => a.ape_id.localeCompare(b.ape_id));

const rows = sorted.map((d, i, arr) => ({
  ...d,
  sectionSpan:
    i === 0 || d.section_id !== arr[i - 1].section_id
      ? arr.filter((r) => r.section_id === d.section_id).length
      : 0,
  divisionSpan:
    i === 0 || d.division_id !== arr[i - 1].division_id
      ? arr.filter((r) => r.division_id === d.division_id).length
      : 0,
  groupeSpan:
    i === 0 || d.groupe_id !== arr[i - 1].groupe_id
      ? arr.filter((r) => r.groupe_id === d.groupe_id).length
      : 0,
  classeSpan:
    i === 0 || d.classe_id !== arr[i - 1].classe_id
      ? arr.filter((r) => r.classe_id === d.classe_id).length
      : 0,
}));

display(
  html`<table class="wda-table wda-pivot">
    <thead>
      <tr>
        <th class="col-section">Section</th>
        <th class="col-division">Division</th>
        <th class="col-groupe">Groupe</th>
        <th class="col-classe">Classe</th>
        <th class="col-ape">Code APE</th>
        <th class="col-etabs" style="text-align:right">Établissements</th>
      </tr>
    </thead>
    <tbody>
      ${rows.map(
        (d) =>
          html`<tr>
            ${d.sectionSpan
              ? html`<td
                  rowspan="${d.sectionSpan}"
                  class="pivot-cell pivot-section"
                  title="${d.section_id} — ${d.section_label}"
                >
                  <strong>${d.section_id}</strong> ${d.section_label}
                </td>`
              : ""} ${d.divisionSpan
              ? html`<td
                  rowspan="${d.divisionSpan}"
                  class="pivot-cell pivot-division"
                  title="${d.division_id} — ${d.division_label}"
                >
                  <strong>${d.division_id}</strong> ${d.division_label}
                </td>`
              : ""} ${d.groupeSpan
              ? html`<td
                  rowspan="${d.groupeSpan}"
                  class="pivot-cell pivot-groupe"
                  title="${d.groupe_id} — ${d.groupe_label}"
                >
                  <strong>${d.groupe_id}</strong> ${d.groupe_label}
                </td>`
              : ""} ${d.classeSpan
              ? html`<td
                  rowspan="${d.classeSpan}"
                  class="pivot-cell pivot-classe"
                  title="${d.classe_id} — ${d.classe_label}"
                >
                  <strong>${d.classe_id}</strong> ${d.classe_label}
                </td>`
              : ""}
            <td
              class="pivot-ape"
              data-section-id="${d.section_id}"
              data-section="${d.section_label}"
              data-division-id="${d.division_id}"
              data-division="${d.division_label}"
              data-groupe-id="${d.groupe_id}"
              data-groupe="${d.groupe_label}"
              data-classe-id="${d.classe_id}"
              data-classe="${d.classe_label}"
              data-ape-id="${d.ape_id}"
              data-ape="${d.ape_label}"
              data-nb-etabs="${d.nb_etabs}"
              title="Cliquez pour voir le détail"
              onclick="window.wdaShowApePopup(event, this)"
            >
              <code>${d.ape_id}</code> ${d.ape_label}
            </td>
            <td style="text-align:right;font-variant-numeric:tabular-nums">
              ${(+d.nb_etabs).toLocaleString("fr-FR")}
            </td>
          </tr>`,
      )}
    </tbody>
  </table>`,
);
```

<div class="source-note">
  Source : <a href="/dataset/sirene">Dataset SIRENE</a> — registre national des entreprises géré par l'<a href="https://www.sirene.fr" target="_blank">INSEE</a>. Codes d'activité : <a href="/nafrev2">NAF Rév. 2</a>.
</div>

```js
display(
  html`<div class="see-also">
    <h3>Voir aussi</h3>
    <div class="see-also-links">
      <a class="see-also-link" href="/sirene/etablissements"
        >Rechercher des établissements</a
      >
      <a class="see-also-link" href="/nafrev2">Référentiel NAF Rév. 2</a>
      <a class="see-also-link" href="/dataset/sirene">Dataset SIRENE</a>
    </div>
  </div>`,
);
```
