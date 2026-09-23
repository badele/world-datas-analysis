---
title: Vigilo — Vue globale
---

<div class="page-header">
  <div class="breadcrumb"><a href="/">Accueil</a> › Vigilo</div>
  <h1>Signalements Vigilo</h1>
  <p class="page-subtitle">
    Répartition des signalements citoyens liés à la pratique du vélo et des déplacements piétons,
    par instance Vigilo. L’application <a href="https://vigilo.city" target="_blank">Vigilo</a>
    a été créée par Quentin Hess suite au mouvement
    <a href="https://lemouvement.info/2018/11/11/montpellier-manif-citoyenne-1200-cyclistes-en-colere/" target="_blank">#JeSuisUnDesDeux</a>
    à Montpellier.
  </p>
</div>

```js
const stats = FileAttachment("data/vigilo-stats.json").json();
const statsByCategory = FileAttachment(
  "data/vigilo-stats-by-category.json",
).json();
```

```js
const total = stats.reduce((s, d) => s + Number(d.count), 0);
const grandTotalObs = Number(stats[0]?.grand_total_obs ?? 0);
const activeScopes = stats[0]?.active_scopes ?? 0;
const totalScopes = stats[0]?.total_scopes ?? 0;
const lastTs = Math.max(...stats.map((d) => d.last_ts).filter(Boolean));
const lastDate = new Date(Number(lastTs) * 1000).toLocaleDateString("fr-FR");
```

<div class="stat-grid">
  <div class="stat-card">
    <div class="stat-value">${grandTotalObs.toLocaleString("fr-FR")}</div>
    <div class="stat-label">Total signalements</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${activeScopes} / ${totalScopes}</div>
    <div class="stat-label">Instances actives</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${lastDate}</div>
    <div class="stat-label">Dernière observation</div>
  </div>
</div>

```js
const activeList = stats.filter((d) => d.is_active);
const inactiveList = stats.filter((d) => !d.is_active);

const pills = document.createElement("div");
pills.innerHTML = `
  <p class="section-label">${activeList.length} instance${
    activeList.length > 1 ? "s actives" : " active"
  } sur ${totalScopes}</p>
  <div class="instance-grid">
    ${activeList
      .sort((a, b) => b.count - a.count)
      .map(
        (d) =>
          `<a class="instance-pill" href="/vigilo/${d.id}">${
            d.display_name
          }<span class="instance-pill-count">${Number(d.count).toLocaleString(
            "fr-FR",
          )}</span></a>`,
      )
      .join("")}
    ${inactiveList
      .sort((a, b) => b.count - a.count)
      .map(
        (d) =>
          `<a class="instance-pill instance-pill--inactive" href="/vigilo/${
            d.id
          }" title="Instance inactive">${
            d.display_name
          }<span class="instance-pill-count">${Number(d.count).toLocaleString(
            "fr-FR",
          )}</span></a>`,
      )
      .join("")}
  </div>
`;
display(pills);
```

## Périodes d'activité et signalements par instance

Pour étudier les incivilités urbaines liées aux mobilités douces, nous disposons
d'un panel de **${totalScopes} instances** Vigilo représentant
**${grandTotalObs.toLocaleString("fr-FR")} signalements**. Seules les instances
comptant plus de **200 observations** sont incluses dans les graphiques
(**${stats.length} instances** et **${total.toLocaleString("fr-FR")}
signalements** sélectionnés). Bien que le mouvement `#JeSuisUnDesDeux` ait
démarré en 2018 et que l'application Vigilo soit sortie en 2019, les
signalements peuvent avoir été saisis rétrospectivement, Vigilo se basant sur la
date de prise de photo plutôt que sur la date de saisie.

<div class="chart-description">
Chronologie des instances : date du premier et dernier signalement enregistré.
</div>

```js
// Graphe 3 — période d'activité par instance
const statsWithDates = stats
  .filter((d) => d.first_ts && d.last_ts)
  .map((d) => ({
    ...d,
    first_date: new Date(Number(d.first_ts) * 1000),
    last_date: new Date(Number(d.last_ts) * 1000),
  }));

const scopeOrderByDate = [...statsWithDates]
  .sort((a, b) => a.first_date - b.first_date)
  .map((d) => d.display_name);

const fmtDate = (d) => d.toLocaleDateString("fr-FR");
const recentCutoff = new Date(Date.now() - 15 * 86400_000);

const timelineData = [
  ...statsWithDates.map((d) => ({ ...d, x: d.first_date, status: "Début" })),
  ...statsWithDates.map((d) => ({
    ...d,
    x: d.last_date,
    status: d.last_date > recentCutoff ? "Observation récente" : "Inactif",
  })),
];

const fig3 = Plot.plot({
  style: plotStyle,
  ...barOpts,
  width,
  x: { label: "Période d'activité", type: "utc" },
  y: { label: null, domain: scopeOrderByDate },
  color: {
    domain: ["Début", "Inactif", "Observation récente"],
    range: [chart2Palette[7], chart2Palette[0], chart2Palette[1]],
    legend: true,
  },
  marks: [
    Plot.link(statsWithDates, {
      x1: "first_date",
      x2: "last_date",
      y1: "display_name",
      y2: "display_name",
      stroke: theme.chart1Bar,
      strokeWidth: 2,
    }),
    Plot.dot(timelineData, {
      x: "x",
      y: "display_name",
      fill: "status",
      r: 5,
      tip: {
        format: { y: false, x: (d) => fmtDate(d.x) },
        fill: theme.surface,
        stroke: theme.border,
      },
    }),
  ],
});
display(applyThemeToLegend(fig3));
```

<div class="chart-description">
Nombre de signallements par instances.
</div>

```js
import * as Plot from "npm:@observablehq/plot";
import { theme, plotStyle } from "./components/theme.js";

// Fusion des catégories dont le total global est < 2% en "Autres"
const MIN_CAT_PCT = 2;
const grandTotal = statsByCategory.reduce((s, d) => s + Number(d.count), 0);
const catGrandTotals = Map.groupBy(statsByCategory, (d) => d.category);
const isSmallCat = (cat) =>
  ((catGrandTotals.get(cat) ?? []).reduce((s, r) => s + Number(r.count), 0) /
    grandTotal) *
    100 <
  MIN_CAT_PCT;

const statsMerged = Object.values(
  statsByCategory.reduce((acc, d) => {
    const cat = isSmallCat(d.category) ? "Autres" : d.category;
    const key = `${d.scope_name}__${cat}`;
    if (!acc[key])
      acc[key] = { scope_name: d.scope_name, category: cat, count: 0 };
    acc[key].count += Number(d.count);
    return acc;
  }, {}),
);

// Ordre fixe des catégories
const totalsByCatMerged = Map.groupBy(statsMerged, (d) => d.category);
const CATEGORY_ORDER = [
  "Véhicule ou objet gênant",
  "Incivilité récurrente sur la route",
  "Aménagement mal conçu",
  "Défaut d'entretien",
  "Absence d'aménagement",
  "Absence d'arceaux de stationnement",
  "Signalisation, marquage",
  "Autres",
];
const categoryOrder = CATEGORY_ORDER.filter((cat) =>
  totalsByCatMerged.has(cat),
);
const knownCats = new Set(CATEGORY_ORDER);
const unknownCats = [...totalsByCatMerged.keys()].filter(
  (cat) => !knownCats.has(cat),
);
categoryOrder.splice(categoryOrder.indexOf("Autres"), 0, ...unknownCats);

const chart2Palette = [
  "#E63946",
  "#8338EC",
  "#F4A261",
  "#FFBE0B",
  "#3A86FF",
  "#457B9D",
  "#2A9D8F",
  "#06D6A0",
];
const colorRange = categoryOrder.map(
  (_, i) => chart2Palette[i % chart2Palette.length],
);
const colorByCategory = new Map(
  categoryOrder.map((cat, i) => [cat, chart2Palette[i % chart2Palette.length]]),
);

// Totaux globaux par catégorie (toutes instances confondues)
const globalCatData = categoryOrder.map((cat) => ({
  category: cat,
  count: [...(totalsByCatMerged.get(cat) ?? [])].reduce(
    (s, r) => s + r.count,
    0,
  ),
}));
const globalTotal = globalCatData.reduce((s, d) => s + d.count, 0);

// Scopes triés par total décroissant — graphes 1 et 3
const totalsPerScope = Map.groupBy(statsMerged, (d) => d.scope_name);
const scopeOrder = [...totalsPerScope.entries()]
  .map(([name, rows]) => ({
    name,
    total: rows.reduce((s, r) => s + r.count, 0),
  }))
  .sort((a, b) => b.total - a.total)
  .map((d) => d.name);

// Ordre graphe 2 : par % des 2 premières catégories décroissant
const TOP2_CATS = [categoryOrder[0], categoryOrder[1]];
const scopeOrder2 = [...totalsPerScope.entries()]
  .map(([name, rows]) => {
    const total = rows.reduce((s, r) => s + r.count, 0);
    const top2 = rows
      .filter((r) => TOP2_CATS.includes(r.category))
      .reduce((s, r) => s + r.count, 0);
    return { name, top2Pct: total > 0 ? top2 / total : 0 };
  })
  .sort((a, b) => b.top2Pct - a.top2Pct)
  .map((d) => d.name);

const barOpts = {
  marginLeft: 220,
  marginRight: 80,
  height: Math.max(300, scopeOrder.length * 36),
};

const scopeTotalMap = new Map(
  [...totalsPerScope.entries()].map(([name, rows]) => [
    name,
    rows.reduce((s, r) => s + r.count, 0),
  ]),
);

function applyThemeToLegend(fig) {
  fig.querySelectorAll("div, span").forEach((el) => {
    el.style.color = theme.text;
    el.style.backgroundColor = theme.bg;
    el.style.marginBottom = "0";
  });
  return fig;
}

// fig2 — construit ici, affiché plus bas après fig3
const fig2 = Plot.plot({
  style: plotStyle,
  ...barOpts,
  width,
  x: {
    label: "Répartition (%)",
    grid: true,
    tickFormat: (d) => `${(d * 100).toFixed(0)}%`,
  },
  y: { label: null, domain: scopeOrder2 },
  color: { domain: categoryOrder, range: colorRange, legend: true },
  marks: [
    Plot.barX(
      statsMerged,
      Plot.stackX({
        offset: "normalize",
        order: categoryOrder,
        y: "scope_name",
        x: (d) => d.count,
        fill: "category",
        channels: {
          Détail: (d) => {
            const pct = (
              (d.count / scopeTotalMap.get(d.scope_name)) *
              100
            ).toFixed(1);
            return `${pct}% (${Number(d.count).toLocaleString("fr-FR")} obs)`;
          },
        },
        tip: {
          format: { fill: true, Détail: true, y: false, x: false },
          fill: theme.surface,
          stroke: theme.border,
        },
      }),
    ),
    Plot.text(
      statsMerged,
      Plot.stackX({
        offset: "normalize",
        order: categoryOrder,
        z: "category",
        y: "scope_name",
        x: (d) => d.count,
        text: (d) => {
          const pct = (d.count / scopeTotalMap.get(d.scope_name)) * 100;
          return pct >= 2 ? `${Math.round(pct)}%` : "";
        },
        textAnchor: "middle",
        fill: "black",
        fontSize: 11,
        fontWeight: "bold",
      }),
    ),
    Plot.ruleX([0]),
  ],
});

// fig1 — volume par instance (affiché ici)
display(
  Plot.plot({
    style: plotStyle,
    ...barOpts,
    width,
    x: {
      label: "Signalements",
      grid: true,
      tickFormat: (d) => d.toLocaleString("fr-FR"),
    },
    y: { label: null, domain: scopeOrder },
    marks: [
      Plot.barX(stats, {
        y: "display_name",
        x: (d) => Number(d.count),
        fill: theme.chart1Bar,
        tip: {
          format: { y: false, x: (d) => d.toLocaleString("fr-FR") },
          fill: theme.surface,
          stroke: theme.border,
        },
      }),
      Plot.text(stats, {
        y: "display_name",
        x: (d) => Number(d.count) / 2,
        text: (d) => Number(d.count).toLocaleString("fr-FR"),
        textAnchor: "middle",
        fill: "black",
        fontWeight: "bold",
      }),
      Plot.ruleX([0]),
    ],
  }),
);
```

## Analyse des incivilités

<div class="chart-description">
Répartition globale de l'ensemble des signalements, toutes instances confondues.
</div>

```js
// figA — répartition globale par catégorie
display(
  Plot.plot({
    style: plotStyle,
    marginLeft: 260,
    marginRight: 100,
    height: Math.max(200, categoryOrder.length * 36),
    width,
    x: {
      label: "Signalements",
      grid: true,
      tickFormat: (d) => d.toLocaleString("fr-FR"),
    },
    y: {
      label: null,
      domain: [...globalCatData]
        .sort((a, b) => b.count - a.count)
        .map((d) => d.category),
    },
    marks: [
      Plot.barX(globalCatData, {
        y: "category",
        x: "count",
        fill: (d) => colorByCategory.get(d.category),
        tip: {
          format: {
            y: false,
            x: (d) =>
              `${((d / globalTotal) * 100).toFixed(1)}% — ${d.toLocaleString(
                "fr-FR",
              )} obs`,
          },
          fill: theme.surface,
          stroke: theme.border,
        },
      }),
      Plot.text(globalCatData, {
        y: "category",
        x: (d) => d.count,
        text: (d) => `${((d.count / globalTotal) * 100).toFixed(1)}%`,
        dx: 6,
        textAnchor: "start",
        fill: theme.text,
        fontSize: 11,
        fontWeight: "bold",
      }),
      Plot.ruleX([0]),
    ],
  }),
);

// Répartition par instance (fig2 construit dans le bloc précédent)
display(
  html`<h3 style="margin-top:2rem;margin-bottom:.5rem">
      Répartition par instance
    </h3>
    <p class="chart-description" style="margin-bottom:1rem">
      Distribution des catégories pour chaque instance (100% empilé), classées
      par proportion des deux premières catégories.
    </p>`,
);
display(applyThemeToLegend(fig2));
```

## Détail par instance

```js
const fmt = (ts) =>
  ts && Number(ts)
    ? new Date(Number(ts) * 1000).toLocaleDateString("fr-FR")
    : "—";

display(
  Inputs.table(
    stats
      .filter((d) => d.count > 0)
      .map((d) => ({
        Instance: d.display_name,
        Statut: d.is_active ? "Actif" : "Inactif",
        Signalements: Number(d.count),
        "Première obs.": fmt(d.first_ts),
        "Dernière obs.": fmt(d.last_ts),
      })),
    {
      sort: "Signalements",
      reverse: true,
      format: {
        Statut: (v) => {
          const span = document.createElement("span");
          span.textContent = v;
          span.style.cssText =
            v === "Actif" ? "color:#4caf50;font-weight:600" : "color:#9e9e9e";
          return span;
        },
      },
    },
  ),
);
```

<div class="source-note">
  Source : <a href="/dataset/vigilo">Dataset Vigilo</a> — données collectées par des collectifs cyclistes locaux via <a href="https://vigilo.city" target="_blank">vigilo.city</a>.
</div>

<div class="see-also">
  <h3>Voir aussi</h3>
  <div class="see-also-links">
    <a class="see-also-link" href="/vigilo/cities">🗺 Carte de toutes les villes</a>
    <a class="see-also-link" href="/">← Retour à l'accueil</a>
  </div>
</div>
