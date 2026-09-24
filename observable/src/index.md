---
title: World Data Analysis
---

```js
import * as Inputs from "npm:@observablehq/inputs";
const stats = FileAttachment("data/datasets-stats.json").json();
```

```js
const statsById = Object.fromEntries(stats.map((d) => [d.id, d]));
const v = statsById.vigilo ?? {};
const s = statsById.sirene ?? {};
const n = statsById.nafrev2 ?? {};

const fmtN = (x) => (x != null ? Number(x).toLocaleString("fr-FR") : "—");
const fmtDate = (ts) =>
  ts ? new Date(Number(ts) * 1000).toLocaleDateString("fr-FR") : null;

const totalObs =
  (v.total_obs ?? 0) +
  (s.total_etablissements ?? 0) +
  (n.total_sous_classes ?? 0);

const DATASETS = [
  {
    id: "vigilo",
    icon: "🚲",
    title: "Vigilo — Signalements citoyens",
    description:
      "Signalements liés à la pratique du vélo et des déplacements piétons, collectés par des collectifs cyclistes locaux via l'application Vigilo.",
    theme: "Mobilité",
    source: "vigilo.city",
    exploreUrl: "/vigilo",
    datasetUrl: "/dataset/vigilo",
    keyStats: [
      { label: "Signalements", value: fmtN(v.total_obs) },
      {
        label: "Instances actives",
        value: `${fmtN(v.active_scopes)} / ${fmtN(v.total_scopes)}`,
      },
      { label: "Dernière obs.", value: fmtDate(v.last_ts) ?? "—" },
    ],
  },
  {
    id: "sirene",
    icon: "🏢",
    title: "SIRENE — Registre national des entreprises",
    description:
      "Registre officiel des entreprises et établissements français géré par l'INSEE. Enrichi avec les coordonnées géographiques GeoNames.",
    theme: "Économie",
    source: "INSEE / data.gouv.fr",
    exploreUrl: "/sirene",
    datasetUrl: "/dataset/sirene",
    keyStats: [
      { label: "Établissements", value: fmtN(s.total_etablissements) },
      { label: "Sections NAF", value: fmtN(s.total_sections) },
    ],
  },
  {
    id: "nafrev2",
    icon: "📋",
    title: "NAF Rév. 2 — Nomenclature d'activités",
    description:
      "Référentiel hiérarchique des activités économiques françaises publié par l'INSEE, en vigueur depuis 2008. Structuré en 5 niveaux hiérarchiques.",
    theme: "Référentiel",
    source: "INSEE",
    exploreUrl: "/nafrev2",
    datasetUrl: "/dataset/nafrev2",
    keyStats: [
      { label: "Codes APE", value: fmtN(n.total_sous_classes) },
      { label: "Sections", value: fmtN(n.total_sections) },
      { label: "Divisions", value: fmtN(n.total_divisions) },
    ],
  },
];
```

<div class="hero">
  <h1>World Data Analysis</h1>
  <p>Exploration de données ouvertes françaises et mondiales : mobilité urbaine, activité économique, géographie. Des données fiables, des visualisations claires.</p>
  <div class="hero-stats">
    <div>
      <div class="hero-stat-value">${totalObs.toLocaleString("fr-FR")}</div>
      <div class="hero-stat-label">Entrées indexées</div>
    </div>
    <div>
      <div class="hero-stat-value">${DATASETS.length}</div>
      <div class="hero-stat-label">Datasets</div>
    </div>
    <div>
      <div class="hero-stat-value">3</div>
      <div class="hero-stat-label">Sources</div>
    </div>
  </div>
</div>

## Catalogue des datasets

<div class="datasets-search-bar">

```js
const search = view(
  Inputs.search(DATASETS, {
    label: "Rechercher",
    placeholder: "Vigilo, SIRENE, mobilité, INSEE…",
    columns: ["title", "description", "theme", "source"],
  }),
);
```

```js
const themes = [null, ...[...new Set(DATASETS.map((d) => d.theme))].sort()];
const selectedTheme = view(
  Inputs.select(themes, {
    label: "Thème",
    format: (t) => t ?? "Tous",
  }),
);
```

</div>

```js
const filtered = selectedTheme
  ? search.filter((d) => d.theme === selectedTheme)
  : search;

if (filtered.length === 0) {
  display(
    html`<p class="datasets-empty">
      Aucun dataset ne correspond à votre recherche.
    </p>`,
  );
} else {
  display(
    html`<div class="datasets-grid">
      ${filtered.map(
        (d) =>
          html`<div class="dataset-card">
            <div class="dataset-card-header">
              <span class="dataset-card-icon">${d.icon}</span>
              <div>
                <div class="dataset-card-theme">${d.theme}</div>
                <h2 class="dataset-card-title">
                  <a href="${d.exploreUrl}">${d.title}</a>
                </h2>
              </div>
            </div>
            <p class="dataset-card-desc">${d.description}</p>
            <div class="dataset-card-stats">
              ${d.keyStats.map(
                (s) =>
                  html`<div class="dataset-card-stat">
                    <div class="dataset-card-stat-value">${s.value}</div>
                    <div class="dataset-card-stat-label">${s.label}</div>
                  </div>`,
              )}
            </div>
            <div class="dataset-card-footer">
              <span class="dataset-card-source">Source : ${d.source}</span>
              <div class="dataset-card-actions">
                <a
                  class="dataset-btn dataset-btn--primary"
                  href="${d.exploreUrl}"
                  >Explorer →</a
                >
                <a class="dataset-btn" href="${d.datasetUrl}">Métadonnées</a>
              </div>
            </div>
          </div>`,
      )}
    </div>`,
  );
}
```
