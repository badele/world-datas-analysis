---
title: Vigilo — Instance
---

```js
import { createVigiloMap } from "../components/vigilo-map.js";
import { createMultiSelect } from "../components/wda-multiselect.js";
import * as Plot from "npm:@observablehq/plot";
import * as d3 from "npm:d3";
```

```js
const scopeId = observable.params.scope;
const allObs = FileAttachment("../data/vigilo-observations.json").json();
const scopes = FileAttachment("../data/vigilo-scopes.json").json();
const categories = FileAttachment("../data/vigilo-categories.json").json();
const statsByCat = FileAttachment(
  "../data/vigilo-stats-by-category.json",
).json();
```

```js
const scopeMeta = scopes.find((s) => s.id === scopeId) ?? {};
const scopeLabel = scopeMeta.display_name ?? scopeId;
const observations = allObs.filter((d) => d.scopeid === scopeId);
const firstTs = Math.min(...observations.map((d) => d.ts).filter(Boolean));
const lastTs = Math.max(...observations.map((d) => d.ts).filter(Boolean));
const fmtDate = (ts) =>
  ts && isFinite(ts)
    ? new Date(Number(ts) * 1000).toLocaleDateString("fr-FR")
    : "—";

const catCounts = categories
  .map((c) => ({
    name: c.name,
    count: observations.filter(
      (d) => d.catid === c.id || d.catid === Number(c.id),
    ).length,
    color: c.color,
  }))
  .filter((d) => d.count > 0)
  .sort((a, b) => b.count - a.count);

const cities = [
  ...new Set(observations.map((d) => d.geonames_city).filter(Boolean)),
].sort((a, b) => a.localeCompare(b));
```

<div class="page-header">
  <div class="breadcrumb"><a href="/">Accueil</a> › <a href="/vigilo">Vigilo</a> › ${scopeLabel}</div>
  <h1>${scopeLabel}</h1>
  <p class="page-subtitle">Signalements citoyens liés aux déplacements vélo et piétons — ${observations.length.toLocaleString("fr-FR")} observations. Zoomez pour passer de la heatmap de densité aux points individuels.</p>
</div>

## Vue d'ensemble

<div class="grid grid-cols-2">

<div class="card">
<h3>À propos</h3>
<div class="meta-row">
  <div class="meta-item">
    <div class="meta-label">Instance</div>
    <div class="meta-value">${scopeLabel}</div>
  </div>
  <div class="meta-item">
    <div class="meta-label">Région</div>
    <div class="meta-value">${scopeMeta.country ?? "—"} — Dép. ${scopeMeta.department ?? "—"}</div>
  </div>
  <div class="meta-item">
    <div class="meta-label">Période</div>
    <div class="meta-value">${fmtDate(firstTs)} → ${fmtDate(lastTs)}</div>
  </div>
  <div class="meta-item">
    <div class="meta-label">Signalements</div>
    <div class="meta-value">${observations.length.toLocaleString("fr-FR")}</div>
  </div>
  <div class="meta-item">
    <div class="meta-label">Catégories actives</div>
    <div class="meta-value">${catCounts.length} / ${categories.length}</div>
  </div>
  <div class="meta-item">
    <div class="meta-label">Source</div>
    <div class="meta-value"><a href="/dataset/vigilo">Dataset Vigilo</a> (<a href="https://vigilo.city" target="_blank">vigilo.city</a>)</div>
  </div>
</div>
</div>

<div class="card">
<h3>Comparaison à la moyenne nationale</h3>

```js
const natMap = new Map();
for (const row of statsByCat) {
  const prev = natMap.get(row.category) ?? { count: 0, color: row.color };
  natMap.set(row.category, {
    count: prev.count + Number(row.count),
    color: row.color,
  });
}
const natTotal = [...natMap.values()].reduce((s, d) => s + d.count, 0);
const scopeTotal = catCounts.reduce((s, d) => s + d.count, 0);

const barData = [];
for (const c of categories) {
  const local = catCounts.find((d) => d.name === c.name);
  const nat = natMap.get(c.name);
  const localPct = local ? (local.count / scopeTotal) * 100 : 0;
  const natPct = nat ? (nat.count / natTotal) * 100 : 0;
  if (localPct < 1 && natPct < 1) continue;
  barData.push({
    name: c.name,
    type: "Instance",
    pct: localPct,
    color: c.color,
    tip: `${c.name}\nCette instance : ${localPct.toFixed(
      1,
    )} %\nNationale : ${natPct.toFixed(1)} %`,
  });
  barData.push({
    name: c.name,
    type: "Nationale",
    pct: natPct,
    color: "#ccc",
    tip: `${c.name}\nMoyenne nationale : ${natPct.toFixed(
      1,
    )} %\nCette instance : ${localPct.toFixed(1)} %`,
  });
}

const sortedNames = [
  ...new Set(
    barData
      .filter((d) => d.type === "Instance")
      .sort((a, b) => b.pct - a.pct)
      .map((d) => d.name),
  ),
];

display(
  Plot.plot({
    marginBottom: 100,
    height: 320,
    fx: {
      label: null,
      domain: sortedNames,
      tickRotate: -40,
      tickFormat: (n) => (n.length > 18 ? n.slice(0, 16) + "…" : n),
    },
    x: { label: null, axis: null },
    y: {
      label: "% des signalements",
      grid: true,
      tickFormat: (d) => d.toFixed(0) + " %",
    },
    color: { type: "identity" },
    marks: [
      Plot.barY(barData, {
        fx: "name",
        x: "type",
        y: "pct",
        fill: "color",
        rx: 2,
        title: "tip",
        tip: true,
      }),
      Plot.ruleY([0]),
    ],
  }),
);
```

</div>

</div>

<div class="filter-bar">

```js
const selectedCities = view(createMultiSelect(cities, { label: "Ville" }));
```

<span class="obs-count">${(selectedCities.length === 0 ? observations : observations.filter(d => selectedCities.includes(d.geonames_city))).length.toLocaleString("fr-FR")} signalement(s)</span>

</div>

```js
const filtered =
  selectedCities.length === 0
    ? observations
    : observations.filter((d) => selectedCities.includes(d.geonames_city));
```

```js
const obsWithCoords = observations.filter(
  (d) => d.latitude != null && d.longitude != null && d.latitude !== "",
);
let clat = 46.5,
  clon = 2.35,
  autoZoom = 11;
if (obsWithCoords.length) {
  const lats = obsWithCoords.map((d) => +d.latitude).sort((a, b) => a - b);
  const lons = obsWithCoords.map((d) => +d.longitude).sort((a, b) => a - b);
  clat = (lats[0] + lats[lats.length - 1]) / 2;
  clon = (lons[0] + lons[lons.length - 1]) / 2;
  const span = Math.max(
    lats[lats.length - 1] - lats[0],
    lons[lons.length - 1] - lons[0],
  );
  if (span > 0)
    autoZoom = Math.max(
      9,
      Math.min(14, Math.round(Math.log2(0.5 / span) + 10)),
    );
}
const mapDiv = display(document.createElement("div"));
mapDiv.className = "vigilo-map";
const map = createVigiloMap(mapDiv, filtered, {
  center: [clon, clat],
  zoom: autoZoom,
});
invalidation.then(() => map.remove());
```

## Évolution temporelle

<div class="chart-description">Nombre de signalements par mois. Permet de voir si l'activité de l'instance est stable, en croissance ou saisonnière.</div>

```js
const byMonth = d3
  .rollups(
    filtered.filter((d) => d.ts),
    (v) => v.length,
    (d) => {
      const dt = new Date(Number(d.ts) * 1000);
      return new Date(dt.getFullYear(), dt.getMonth(), 1);
    },
  )
  .map(([date, count]) => ({ date, count }))
  .sort((a, b) => a.date - b.date);

display(
  Plot.plot({
    height: 200,
    x: { type: "time", label: null },
    y: { label: "Signalements", grid: true },
    marks: [
      Plot.areaY(byMonth, {
        x: "date",
        y: "count",
        fill: "#4fc3f7",
        fillOpacity: 0.25,
      }),
      Plot.lineY(byMonth, {
        x: "date",
        y: "count",
        stroke: "#4fc3f7",
        strokeWidth: 2,
      }),
      Plot.dot(byMonth, {
        x: "date",
        y: "count",
        fill: "#4fc3f7",
        r: 3,
        tip: {
          format: {
            x: (d) =>
              d.toLocaleDateString("fr-FR", { month: "long", year: "numeric" }),
            fill: false,
            stroke: false,
          },
        },
      }),
    ],
  }),
);
```

## Top adresses

<div class="chart-description">Les 10 lieux les plus souvent signalés dans l'instance.</div>

```js
const topAddresses = d3
  .rollups(
    filtered.filter((d) => d.address),
    (v) => v.length,
    (d) => d.address,
  )
  .map(([address, count]) => ({ address, count }))
  .sort((a, b) => b.count - a.count)
  .slice(0, 10);

display(
  Plot.plot({
    marginLeft: 220,
    height: Math.max(120, topAddresses.length * 28),
    x: { label: null, grid: true },
    y: { label: null },
    marks: [
      Plot.barX(topAddresses, {
        y: "address",
        x: "count",
        fill: "#4fc3f7",
        sort: { y: "-x" },
        rx: 2,
        tip: {
          format: {
            x: (d) => d.toLocaleString("fr-FR") + " signalement(s)",
            fill: false,
          },
        },
      }),
      Plot.ruleX([0]),
    ],
  }),
);
```

## Activité par jour et heure

<div class="chart-description">Densité des signalements selon le jour de la semaine et l'heure de dépôt.</div>

```js
const DAYS = ["Dim", "Lun", "Mar", "Mer", "Jeu", "Ven", "Sam"];
const heatRaw = d3.rollups(
  filtered.filter((d) => d.ts),
  (v) => v.length,
  (d) => {
    const dt = new Date(Number(d.ts) * 1000);
    return `${dt.getDay()}_${dt.getHours()}`;
  },
);
const heatMap = new Map(heatRaw.map(([k, v]) => [k, v]));
const heatData = d3.range(7).flatMap((day) =>
  d3.range(24).map((hour) => ({
    day,
    hour,
    count: heatMap.get(`${day}_${hour}`) ?? 0,
  })),
);
const heatMax = d3.max(heatData, (d) => d.count);

display(
  Plot.plot({
    marginLeft: 40,
    height: 220,
    x: { domain: d3.range(24), label: "Heure", tickFormat: (d) => d + "h" },
    y: {
      domain: [1, 2, 3, 4, 5, 6, 0],
      tickFormat: (d) => DAYS[d],
      label: null,
    },
    color: { scheme: "Blues", label: "Signalements" },
    marks: [
      Plot.cell(heatData, {
        x: "hour",
        y: "day",
        fill: "count",
        rx: 2,
        tip: {
          format: {
            fill: (d) => `${d} signalement(s)`,
            x: (d) => d + "h",
            y: (d) => DAYS[d],
          },
        },
      }),
      Plot.text(
        heatData.filter((d) => d.count > 0),
        {
          x: "hour",
          y: "day",
          text: (d) => d.count,
          fill: (d) => (d.count > heatMax * 0.55 ? "white" : "#333"),
          fontSize: 9,
        },
      ),
    ],
  }),
);
```

<div class="source-note">
  Source : <a href="/dataset/vigilo">Dataset Vigilo</a> — signalements collectés par des collectifs cyclistes locaux via <a href="https://vigilo.city" target="_blank">vigilo.city</a>.
</div>

<div class="see-also">
  <h3>Voir aussi</h3>
  <div class="see-also-links">
    <a class="see-also-link" href="/vigilo">📊 Vue d'ensemble toutes instances</a>
    <a class="see-also-link" href="/vigilo/cities">🗺 Carte de toutes les villes</a>
  </div>
</div>
