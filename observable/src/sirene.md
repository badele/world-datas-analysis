---
title: SIRENE — Établissements par secteur
---

```js
import * as Inputs from "npm:@observablehq/inputs";
import * as d3 from "npm:d3";
import { createSireneMap, effectifsLabel } from "./components/sirene-map.js";
import { showPopup } from "./components/popup.js";
```

```js
const funnelData = FileAttachment("data/sirene-funnel.json").json();
const statsBySection = FileAttachment(
  "data/sirene-stats-by-section.json",
).json();
```

```js
const totalEtablissements = d3.sum(statsBySection, (d) => +d.nb_etablissements);
```

<div class="page-header">
  <div class="breadcrumb"><a href="/">Accueil</a> › SIRENE</div>
  <h1>SIRENE — Établissements par secteur d'activité</h1>
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

```js
const etabNameSearch = view(
  Inputs.text({
    label: "Nom établissement",
    placeholder: "Nom, raison sociale, SIRET, SIREN…",
  }),
);
```

</div>

```js
const nSec = new Set(filtered.map((d) => d.section_id)).size;
const nDiv = new Set(filtered.map((d) => d.division_id)).size;
const nGrp = new Set(filtered.map((d) => d.groupe_id)).size;
const nCls = new Set(filtered.map((d) => d.classe_id)).size;
const nApe = filtered.length;

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
  </div>`,
);
```

```js
display(
  html`<div class="filter-stat-grid">
    ${etabNameSearch
      ? html`<div class="filter-stat-card filter-stat-card--orange">
          <div class="filter-stat-value">
            ${tooMany ? "—" : etabs.length.toLocaleString("fr-FR")}
          </div>
          <div class="filter-stat-label">
            Après filtre nom ${!tooMany
              ? html`<a href="#carte" class="filter-stat-map-link"
                  >voir sur la carte</a
                >`
              : ""}
          </div>
        </div>`
      : ""}
    <div class="filter-stat-card filter-stat-card--green">
      <div class="filter-stat-value">
        ${tooMany
          ? ">" + (100_000).toLocaleString("fr-FR")
          : totalFilteredEtabs.toLocaleString("fr-FR")}
      </div>
      <div class="filter-stat-label">Établissements (APE)</div>
    </div>
  </div>`,
);
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

if (tooMany) {
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
      <span
        ><strong
          >${totalFilteredEtabs.toLocaleString("fr-FR")} établissements</strong
        >
        correspondent aux filtres actuels — trop pour afficher la carte. ${etabNameSearch
          ? `Affinez les filtres APE (section, division, groupe, classe) pour descendre sous 500 000 établissements avant de rechercher par nom.`
          : `Affinez les filtres (division, groupe, classe) ou saisissez un nom d'établissement pour descendre sous 100 000 établissements.`}</span
      >
    </div>`,
  );
}

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

## Carte

```js
const MAX_ETABS = 100_000;
const MAX_ETABS_WITH_NAME = 500_000;
const totalFilteredEtabs = d3.sum(filtered, (d) => +d.nb_etabs);
const tooMany = etabNameSearch
  ? totalFilteredEtabs > MAX_ETABS_WITH_NAME
  : totalFilteredEtabs > MAX_ETABS;
```

```js
// Titre contextuel selon le niveau de filtrage actif
const mapTitle = (() => {
  if (selectedClasse) return `Classe ${selectedClasse}`;
  if (selectedGroupe) return `Groupe ${selectedGroupe}`;
  if (selectedDivision) return `Division ${selectedDivision}`;
  if (selectedSection) return `Section ${selectedSection}`;
  return "Tous secteurs";
})();
```

```js
const etabsAll = tooMany
  ? []
  : (
      await Promise.all(
        filtered.map((d) =>
          fetch(`/_file/data/sirene-etabs/${encodeURIComponent(d.ape_id)}.json`)
            .then((r) => (r.ok ? r.json() : []))
            .catch(() => []),
        ),
      )
    ).flat();
```

```js
// etab row = [lat, lon, name, address, siret, effectifs_min, is_siege, date_creation, legal_name, dept, ape]
const etabs = (() => {
  if (!etabNameSearch) return etabsAll;
  const terms = etabNameSearch.toLowerCase().split(/\s+/).filter(Boolean);
  return etabsAll.filter((r) => {
    const haystack = `${r[2] ?? ""} ${r[8] ?? ""} ${r[4] ?? ""}`.toLowerCase();
    return terms.every((t) => haystack.includes(t));
  });
})();
```

```js
{
  display(
    html`<div class="filter-stat-grid">
      ${etabNameSearch
        ? html`<div class="filter-stat-card filter-stat-card--orange">
            <div class="filter-stat-value">
              ${tooMany ? "—" : etabs.length.toLocaleString("fr-FR")}
            </div>
            <div class="filter-stat-label">
              Après filtre nom ${!tooMany
                ? html`<a href="#carte" class="filter-stat-map-link"
                    >voir sur la carte</a
                  >`
                : ""}
            </div>
          </div>`
        : ""}
      <div class="filter-stat-card filter-stat-card--green">
        <div class="filter-stat-value">
          ${tooMany
            ? ">" + (100_000).toLocaleString("fr-FR")
            : totalFilteredEtabs.toLocaleString("fr-FR")}
        </div>
        <div class="filter-stat-label">Établissements (APE)</div>
      </div>
    </div>`,
  );

  if (tooMany) {
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
        <span
          ><strong
            >${totalFilteredEtabs.toLocaleString("fr-FR")} établissements</strong
          >
          correspondent aux filtres actuels — trop pour afficher la carte. ${etabNameSearch
            ? `Affinez les filtres APE (section, division, groupe, classe) pour descendre sous 500 000 établissements avant de rechercher par nom.`
            : `Affinez les filtres (division, groupe, classe) ou saisissez un nom d'établissement pour descendre sous 100 000 établissements.`}</span
        >
      </div>`,
    );
  }

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
            ${
              p.is_siege
                ? `<span class="etab-badge etab-badge-siege">Siège social</span>`
                : ""
            }
          </div>
          <button class="etab-detail-close" title="Fermer">✕</button>
        </div>
        <div class="etab-detail-body">
          <div class="etab-detail-col">
            ${
              p.address
                ? `<div class="etab-info-row"><span class="etab-info-label">Adresse</span><span class="etab-info-value">${p.address}</span></div>`
                : ""
            }
            ${
              p.dept
                ? `<div class="etab-info-row"><span class="etab-info-label">Département</span><span class="etab-info-value">${p.dept}</span></div>`
                : ""
            }
            ${
              dateStr
                ? `<div class="etab-info-row"><span class="etab-info-label">Ouverture</span><span class="etab-info-value">${dateStr}</span></div>`
                : ""
            }
            <div class="etab-info-row"><span class="etab-info-label">Effectifs</span><span class="etab-info-value">${effLabel}</span></div>
          </div>
          <div class="etab-detail-col">
            ${
              p.legal_name
                ? `<div class="etab-info-row"><span class="etab-info-label">Raison sociale</span><span class="etab-info-value">${p.legal_name}</span></div>`
                : ""
            }
            <div class="etab-info-row"><span class="etab-info-label">SIRET</span><span class="etab-info-value">
              ${p.siret}
              <a href="https://annuaire-entreprises.data.gouv.fr/etablissement/${
                p.siret
              }" target="_blank" class="etab-source-link etab-source-link-datagouv">data.gouv</a>
              <a href="https://data.inpi.fr/entreprises/${siren}?q=${
                p.siret
              }" target="_blank" class="etab-source-link etab-source-link-inpi">inpi</a>
            </span></div>
            <div class="etab-info-row"><span class="etab-info-label">SIREN</span><span class="etab-info-value">
              <code class="etab-siret-copy" data-siret="${siren}" title="Cliquer pour copier" onclick="navigator.clipboard.writeText(this.dataset.siret).then(()=>{this.classList.add('copied');setTimeout(()=>this.classList.remove('copied'),1200)})">${siren}</code>
              <a href="https://annuaire-entreprises.data.gouv.fr/entreprise/${siren}" target="_blank" class="etab-source-link etab-source-link-datagouv">data.gouv</a>
              <a href="https://www.pappers.fr/entreprise/${siren}" target="_blank" class="etab-source-link etab-source-link-pappers">pappers</a>
            </span></div>
            ${
              p.ape
                ? `<div class="etab-info-row"><span class="etab-info-label">Code APE</span><span class="etab-info-value"><code class="etab-siret-copy" data-siret="${p.ape}" title="Cliquer pour copier" onclick="navigator.clipboard.writeText(this.dataset.siret).then(()=>{this.classList.add('copied');setTimeout(()=>this.classList.remove('copied'),1200)})">${p.ape}</code></span></div>`
                : ""
            }
          </div>
        </div>`;
      detailEl.querySelector(".etab-detail-close").onclick = () => {
        detailEl.style.display = "none";
      };
      detailEl.classList.remove("etab-detail-panel--flash");
      void detailEl.offsetWidth; // force reflow pour relancer l'animation
      detailEl.classList.add("etab-detail-panel--flash");
      detailEl.scrollIntoView({ behavior: "smooth", block: "nearest" });
    },
  });

  // ── Tableau des établissements ─────────────────────────────────────
  if (!tooMany) {
    const TABLE_MAX_ROWS = 1_000;
    const tableData = etabs.slice(0, TABLE_MAX_ROWS);
    const truncated = etabs.length > TABLE_MAX_ROWS;

    display(
      html`<div style="margin-top:1.25rem">
        ${truncated
          ? html`<div class="too-many-warning" style="margin-bottom:0.75rem">
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
              <span
                >Tableau limité aux
                <strong>${TABLE_MAX_ROWS.toLocaleString("fr-FR")}</strong>
                premiers résultats sur ${etabs.length.toLocaleString("fr-FR")} établissements
                — affinez vos filtres pour réduire la sélection.</span
              >
            </div>`
          : html`<p class="etab-table-count">
              ${etabs.length.toLocaleString("fr-FR")} établissement${etabs.length >
              1
                ? "s"
                : ""}
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
                    ${r[6]
                      ? html`<span class="etab-badge etab-badge-siege"
                          >Siège</span
                        >`
                      : ""} ${showLegal
                      ? html`<span class="etab-legal">${legal}</span>`
                      : ""}
                  </td>
                  <td>
                    ${dept
                      ? html`<span class="etab-dept-tag">${dept}</span>`
                      : ""}${addr}
                  </td>
                  <td>
                    <code
                      class="etab-siret-copy"
                      data-siret="${ape}"
                      title="Cliquer pour copier"
                      onclick="navigator.clipboard.writeText(this.dataset.siret).then(()=>{this.classList.add('copied');setTimeout(()=>this.classList.remove('copied'),1200)})"
                      >${ape}</code
                    >
                  </td>
                  <td style="white-space:nowrap">
                    <code
                      class="etab-siret-copy"
                      data-siret="${siren}"
                      title="Cliquer pour copier"
                      onclick="navigator.clipboard.writeText(this.dataset.siret).then(()=>{this.classList.add('copied');setTimeout(()=>this.classList.remove('copied'),1200)})"
                      >${siren}</code
                    ><br />
                    <a
                      href="https://annuaire-entreprises.data.gouv.fr/entreprise/${siren}"
                      target="_blank"
                      class="etab-source-link etab-source-link-datagouv"
                      >data.gouv</a
                    >
                    <a
                      href="https://www.pappers.fr/entreprise/${siren}"
                      target="_blank"
                      class="etab-source-link etab-source-link-pappers"
                      >pappers</a
                    >
                  </td>
                  <td style="white-space:nowrap">
                    <code
                      class="etab-siret-copy"
                      data-siret="${siret}"
                      title="Cliquer pour copier"
                      onclick="navigator.clipboard.writeText(this.dataset.siret).then(()=>{this.classList.add('copied');setTimeout(()=>this.classList.remove('copied'),1200)})"
                      >${siret}</code
                    ><br />
                    <a
                      href="https://annuaire-entreprises.data.gouv.fr/etablissement/${siret}"
                      target="_blank"
                      class="etab-source-link etab-source-link-datagouv"
                      >data.gouv</a
                    >
                    <a
                      href="https://data.inpi.fr/entreprises/${siren}?q=${siret}"
                      target="_blank"
                      class="etab-source-link etab-source-link-inpi"
                      >inpi</a
                    >
                  </td>
                  <td>
                    <span class="etab-effectifs-badge"
                      >${effectifsLabel(r[5])}</span
                    >
                  </td>
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
      <a class="see-also-link" href="/nafrev2">Référentiel NAF Rév. 2</a>
      <a class="see-also-link" href="/dataset/sirene">Dataset SIRENE</a>
    </div>
  </div>`,
);
```
