---
title: GeoNames — Référentiel géographique mondial
---

```js
import * as Inputs from "npm:@observablehq/inputs";
import { createGeonamesMap } from "./components/geonames-map.js";
import {
  initChartActions,
  initBlockActions,
} from "./components/wda-chart-actions.js";
```

```js
const countries = await FileAttachment("data/geonames-countries.json").json();
```

```js
const CONTINENT_NAMES = {
  AF: "Afrique",
  AS: "Asie",
  EU: "Europe",
  NA: "Amérique du Nord",
  OC: "Océanie",
  SA: "Amérique du Sud",
  AN: "Antarctique",
};

const fmtPop = (n) =>
  n != null && n > 0 ? Number(n).toLocaleString("fr-FR") : "—";
const fmtArea = (n) =>
  n != null && n > 0
    ? Number(n).toLocaleString("fr-FR", { maximumFractionDigits: 0 }) + " km²"
    : "—";

const nbCountries = countries.length;
const nbContinents = new Set(countries.map((d) => d.continent)).size;
const totalPop = countries.reduce((s, d) => s + (d.population ?? 0), 0);
```

<div class="page-header">
  <div class="breadcrumb"><a href="./">Accueil</a> › GeoNames</div>
  <h1>GeoNames — Référentiel géographique mondial</h1>
  <p class="page-subtitle">Base de données mondiale des pays et entités géographiques, maintenue par GeoNames.org et utilisée comme référentiel de géolocalisation dans ce projet.</p>
</div>

## Vue d'ensemble

<div class="stat-grid">
  <div class="stat-card">
    <div class="stat-value">${nbCountries}</div>
    <div class="stat-label">Pays / territoires</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${nbContinents}</div>
    <div class="stat-label">Continents</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${totalPop.toLocaleString("fr-FR")}</div>
    <div class="stat-label">Population totale</div>
  </div>
</div>

Répartition de la population mondiale par pays, visualisée sur une carte choroplèthe.

<div class="wda-note">
  L'échelle de couleur est logarithmique : les petits pays restent visibles malgré les écarts extrêmes entre micro-États et géants démographiques (Chine, Inde).
</div>

```js
{
  const mapBlock = document.createElement("div");
  mapBlock.className = "wda-chart-block";

  const titleEl = document.createElement("p");
  titleEl.className = "wda-chart-title";
  titleEl.textContent = "Population par pays";

  const subtitleEl = document.createElement("p");
  subtitleEl.className = "wda-chart-subtitle";
  subtitleEl.textContent =
    "Densité de population relative — échelle logarithmique. Zoomez et déplacez la carte.";

  const mapDiv = document.createElement("div");
  mapDiv.className = "vigilo-map";

  const sourceEl = document.createElement("p");
  sourceEl.className = "wda-chart-source";
  sourceEl.innerHTML =
    `Source : <a href="dataset/geonames">Dataset GeoNames</a> — données publiées par ` +
    `<a href="https://www.geonames.org/" target="_blank">GeoNames.org</a>, fond de carte ` +
    `<a href="https://github.com/topojson/world-atlas" target="_blank">world-atlas</a>.`;

  mapBlock.append(titleEl, subtitleEl, mapDiv, sourceEl);
  display(mapBlock);
  initBlockActions(mapBlock);

  const map = await createGeonamesMap(mapDiv, countries);
  invalidation.then(() => map.remove());
}
```

Densité de population par pays (habitants par km²), sur la même échelle logarithmique.

<div class="wda-note">
  Les micro-États très denses (Monaco, Singapour, Bahreïn) dominent l'échelle ; les grands pays peu peuplés (Mongolie, Namibie, Australie) apparaissent en clair.
</div>

```js
{
  const mapBlock = document.createElement("div");
  mapBlock.className = "wda-chart-block";

  const titleEl = document.createElement("p");
  titleEl.className = "wda-chart-title";
  titleEl.textContent = "Densité de population par pays";

  const subtitleEl = document.createElement("p");
  subtitleEl.className = "wda-chart-subtitle";
  subtitleEl.textContent =
    "Habitants par km² — échelle logarithmique. Zoomez et déplacez la carte.";

  const mapDiv = document.createElement("div");
  mapDiv.className = "vigilo-map";

  const sourceEl = document.createElement("p");
  sourceEl.className = "wda-chart-source";
  sourceEl.innerHTML =
    `Source : <a href="dataset/geonames">Dataset GeoNames</a> — données publiées par ` +
    `<a href="https://www.geonames.org/" target="_blank">GeoNames.org</a>, fond de carte ` +
    `<a href="https://github.com/topojson/world-atlas" target="_blank">world-atlas</a>.`;

  mapBlock.append(titleEl, subtitleEl, mapDiv, sourceEl);
  display(mapBlock);
  initBlockActions(mapBlock);

  const map = await createGeonamesMap(mapDiv, countries, { metric: "density" });
  invalidation.then(() => map.remove());
}
```

## Explorer les pays

<div class="filter-bar">

<button class="filter-reset-btn" onclick="window.location.href = window.location.pathname" title="Réinitialiser tous les filtres">✕ Réinitialiser</button>

```js
const searched = view(
  Inputs.search(countries, {
    label: "Recherche",
    placeholder: "Pays, capitale, devise, code ISO…",
    columns: ["iso", "iso3", "country", "capital", "currency_name", "tld"],
  }),
);
```

```js
const continentOptions = [
  null,
  ...[...new Set(searched.map((d) => d.continent))]
    .filter(Boolean)
    .sort((a, b) =>
      (CONTINENT_NAMES[a] ?? a).localeCompare(CONTINENT_NAMES[b] ?? b),
    ),
];
const selectedContinent = view(
  Inputs.select(continentOptions, {
    label: "Continent",
    value: null,
    format: (v) =>
      v === null ? "— Tous —" : `${CONTINENT_NAMES[v] ?? v} (${v})`,
  }),
);
```

</div>

```js
const filtered =
  selectedContinent === null
    ? searched
    : searched.filter((d) => d.continent === selectedContinent);
```

```js
{
  const n = filtered.length;
  const isFiltered = n < countries.length;
  const popFiltered = filtered.reduce((s, d) => s + (d.population ?? 0), 0);

  display(
    html`<div
      class="results-card ${isFiltered ? "results-card--filtered" : ""}"
    >
      <div class="results-card-count">
        <span class="results-card-number">${n.toLocaleString("fr-FR")}</span>
        <span class="results-card-unit"> pay${n > 1 ? "s" : ""}</span>
        ${isFiltered
          ? html`<span class="results-card-total"
              >sur ${countries.length}</span
            >`
          : ""}
      </div>
      <div class="results-card-breakdown">
        <span>Population : ${popFiltered.toLocaleString("fr-FR")}</span>
      </div>
    </div>`,
  );
}
```

```js
display(
  html`<table class="wda-table">
    <thead>
      <tr>
        <th>ISO</th>
        <th>Pays</th>
        <th>Capitale</th>
        <th>Continent</th>
        <th class="num">Population</th>
        <th class="num">Superficie</th>
        <th>Devise</th>
        <th>Domaine</th>
      </tr>
    </thead>
    <tbody>
      ${filtered.map(
        (d) =>
          html`<tr>
            <td><code>${d.iso}</code></td>
            <td>${d.country}</td>
            <td>${d.capital || "—"}</td>
            <td title="${d.continent}">
              ${CONTINENT_NAMES[d.continent] ?? d.continent ?? "—"}
            </td>
            <td class="num">${fmtPop(d.population)}</td>
            <td class="num">${fmtArea(d.area_km2)}</td>
            <td>${d.currency_name || "—"}</td>
            <td>${d.tld || "—"}</td>
          </tr>`,
      )}
    </tbody>
  </table>`,
);
```

<div class="source-note">
  Source : <a href="dataset/geonames">Dataset GeoNames</a> — données publiées par <a href="https://www.geonames.org/" target="_blank">GeoNames.org</a> sous licence Creative Commons Attribution 4.0.
</div>

<div class="see-also">
  <h3>Voir aussi</h3>
  <div class="see-also-links">
    <a class="see-also-link" href="sirene">🏢 Établissements SIRENE géolocalisés</a>
    <a class="see-also-link" href="dataset/geonames">📋 Dataset GeoNames</a>
  </div>
</div>
