---
title: NAF Rév. 2 — Nomenclature d'activités
---

```js
import * as Inputs from "npm:@observablehq/inputs";
import * as d3 from "npm:d3";
import { showPopup } from "./components/popup.js";
```

```js
const hierarchy = FileAttachment("data/nafrev2-hierarchy.json").json();
```

```js
const nbSections = new Set(hierarchy.map((d) => d.section_id)).size;
const nbDivisions = new Set(hierarchy.map((d) => d.division_id)).size;
const nbGroupes = new Set(hierarchy.map((d) => d.groupe_id)).size;
const nbClasses = new Set(hierarchy.map((d) => d.classe_id)).size;
const nbSousClasses = hierarchy.length;
```

<div class="page-header">
  <div class="breadcrumb"><a href="/">Accueil</a> › NAF Rév. 2</div>
  <h1>NAF Rév. 2 — Nomenclature d'activités françaises</h1>
  <p class="page-subtitle">Référentiel hiérarchique des activités économiques publié par l'INSEE, en vigueur depuis 2008.</p>
</div>

## Niveaux hiérarchiques

<div class="stat-grid">
  <div class="stat-card">
    <div class="stat-value">${nbSections}</div>
    <div class="stat-label">Sections</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${nbDivisions}</div>
    <div class="stat-label">Divisions</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${nbGroupes}</div>
    <div class="stat-label">Groupes</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${nbClasses}</div>
    <div class="stat-label">Classes</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${nbSousClasses}</div>
    <div class="stat-label">Codes APE</div>
  </div>
</div>

## Explorer la nomenclature

<div class="filter-bar">

<button class="filter-reset-btn" onclick="window.location.href = window.location.pathname" title="Réinitialiser tous les filtres">✕ Réinitialiser</button>

```js
// Recherche texte libre sur tous les champs
const searched = view(
  Inputs.search(hierarchy, {
    label: "Recherche",
    placeholder: "Code APE, libellé, section…",
    columns: [
      "section_id",
      "section",
      "division_id",
      "division",
      "groupe_id",
      "groupe",
      "classe_id",
      "classe",
      "sous_classe_id",
      "sous_classe",
    ],
  }),
);
```

```js
// Filtre Section (cascade sur résultat de la recherche)
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
        : `${v} — ${searched.find((d) => d.section_id === v)?.section ?? ""}`,
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
            afterSection.find((d) => d.division_id === v)?.division ?? ""
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
            afterDivision.find((d) => d.groupe_id === v)?.groupe ?? ""
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
        : `${v} — ${afterGroupe.find((d) => d.classe_id === v)?.classe ?? ""}`,
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
{
  const nSec = new Set(filtered.map((d) => d.section_id)).size;
  const nDiv = new Set(filtered.map((d) => d.division_id)).size;
  const nGrp = new Set(filtered.map((d) => d.groupe_id)).size;
  const nCls = new Set(filtered.map((d) => d.classe_id)).size;
  const nApe = filtered.length;
  const isFiltered = nApe < hierarchy.length;

  display(
    html`<div
      class="results-card ${isFiltered ? "results-card--filtered" : ""}"
    >
      <div class="results-card-count">
        <span class="results-card-number">${nApe.toLocaleString("fr-FR")}</span>
        <span class="results-card-unit"> code${nApe > 1 ? "s" : ""} APE</span>
        ${isFiltered
          ? html`<span class="results-card-total"
              >sur ${hierarchy.length}</span
            >`
          : ""}
      </div>
      <div class="results-card-breakdown">
        <span>${nSec} section${nSec > 1 ? "s" : ""}</span>
        <span class="sep">·</span>
        <span>${nDiv} division${nDiv > 1 ? "s" : ""}</span>
        <span class="sep">·</span>
        <span>${nGrp} groupe${nGrp > 1 ? "s" : ""}</span>
        <span class="sep">·</span>
        <span>${nCls} classe${nCls > 1 ? "s" : ""}</span>
      </div>
    </div>`,
  );
}
```

```js
// Expose le popup générique aux onclick inline du tableau
window.wdaShowApePopup = (event, cell) => {
  const ds = cell.dataset;
  showPopup(event, {
    title: `Code APE — ${ds.apeId}`,
    rows: [
      { label: "Section", id: ds.sectionId, value: ds.section },
      { label: "Division", id: ds.divisionId, value: ds.division },
      { label: "Groupe", id: ds.groupeId, value: ds.groupe },
      { label: "Classe", id: ds.classeId, value: ds.classe },
      { label: "Code APE", id: ds.apeId, value: ds.ape },
    ],
  });
};
```

```js
// Tri et calcul des rowspans
const sorted = filtered
  .slice()
  .sort((a, b) => a.sous_classe_id.localeCompare(b.sous_classe_id));

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
                  title="${d.section_id} — ${d.section}"
                >
                  <strong>${d.section_id}</strong> ${d.section}
                </td>`
              : ""} ${d.divisionSpan
              ? html`<td
                  rowspan="${d.divisionSpan}"
                  class="pivot-cell pivot-division"
                  title="${d.division_id} — ${d.division}"
                >
                  <strong>${d.division_id}</strong> ${d.division}
                </td>`
              : ""} ${d.groupeSpan
              ? html`<td
                  rowspan="${d.groupeSpan}"
                  class="pivot-cell pivot-groupe"
                  title="${d.groupe_id} — ${d.groupe}"
                >
                  <strong>${d.groupe_id}</strong> ${d.groupe}
                </td>`
              : ""} ${d.classeSpan
              ? html`<td
                  rowspan="${d.classeSpan}"
                  class="pivot-cell pivot-classe"
                  title="${d.classe_id} — ${d.classe}"
                >
                  <strong>${d.classe_id}</strong> ${d.classe}
                </td>`
              : ""}
            <td
              class="pivot-ape"
              data-section-id="${d.section_id}"
              data-section="${d.section}"
              data-division-id="${d.division_id}"
              data-division="${d.division}"
              data-groupe-id="${d.groupe_id}"
              data-groupe="${d.groupe}"
              data-classe-id="${d.classe_id}"
              data-classe="${d.classe}"
              data-ape-id="${d.sous_classe_id}"
              data-ape="${d.sous_classe}"
              title="Cliquez pour copier"
              onclick="window.wdaShowApePopup(event, this)"
            >
              <code>${d.sous_classe_id}</code> ${d.sous_classe}
            </td>
          </tr>`,
      )}
    </tbody>
  </table>`,
);
```

<div class="source-note">
  Source : <a href="/dataset/nafrev2">Dataset NAF Rév. 2</a> — nomenclature publiée par l'<a href="https://www.insee.fr/fr/information/2120875" target="_blank">INSEE</a>.
</div>

<div class="see-also">
  <h3>Voir aussi</h3>
  <div class="see-also-links">
    <a class="see-also-link" href="/sirene">🏢 Établissements SIRENE par secteur NAF</a>
    <a class="see-also-link" href="/dataset/nafrev2">📋 Dataset NAF Rév. 2</a>
  </div>
</div>
