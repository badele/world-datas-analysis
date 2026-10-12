---
title: GeoNames — Lieux géographiques
---

```js
import * as maplibregl from "npm:maplibre-gl";
import { fixGeometry } from "./components/geonames-map.js";
import {
  initChartActions,
  initBlockActions,
} from "./components/wda-chart-actions.js";
```

```js
const summary = await FileAttachment(
  "data/geonames-allentries-summary.json",
).json();
const countries = await FileAttachment("data/geonames-countries.json").json();
```

```js
const { stats, feature_codes, capitals } = summary;
const countryName = new Map(countries.map((d) => [d.iso, d.country]));

const fmtN = (n) => (n != null ? Number(n).toLocaleString("fr-FR") : "—");

const FEATURE_CODE_LABELS = {
  PPLC: "Capitale nationale",
  PPLA: "Chef-lieu régional (ADM1)",
  PPLA2: "Chef-lieu de département (ADM2)",
  PPLA3: "Chef-lieu d'arrondissement (ADM3)",
  PPLA4: "Chef-lieu (ADM4)",
  PPLA5: "Chef-lieu (ADM5)",
  PPL: "Lieu habité (village, hameau…)",
  PPLX: "Section ou quartier d'un lieu habité",
  PPLF: "Village rural",
  PPLL: "Lieu habité lacustre",
  PPLQ: "Lieu habité abandonné",
  PPLR: "Lieu habité religieux",
  PPLS: "Lieu habité saisonnier",
  PPLW: "Lieu habité détruit ou englouti",
  PPLH: "Lieu habité historique",
  PPLCH: "Siège de collectivité",
  PPLG: "Siège de gouvernement",
  STLMT: "Lieu habité (variante)",
};
```

<div class="page-header">
  <div class="breadcrumb"><a href="./">Accueil</a> › <a href="geonames">GeoNames</a> › Lieux géographiques</div>
  <h1>GeoNames — Lieux géographiques</h1>
  <p class="page-subtitle">Référentiel mondial des lieux habités et zones administratives — capitales, villes, villages et subdivisions pour ${fmtN(stats.total_countries)} pays.</p>
</div>

## Vue d'ensemble

<div class="stat-grid">
  <div class="stat-card">
    <div class="stat-value">${fmtN(stats.total_entries)}</div>
    <div class="stat-label">Entrées totales</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${fmtN(stats.populated_places)}</div>
    <div class="stat-label">Lieux habités (classe P)</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${fmtN(stats.admin_entries)}</div>
    <div class="stat-label">Zones admin. (classe A)</div>
  </div>
  <div class="stat-card">
    <div class="stat-value">${fmtN(stats.total_countries)}</div>
    <div class="stat-label">Pays couverts</div>
  </div>
</div>

## Capitales mondiales

Les ${fmtN(capitals.length)} capitales nationales (`feature_code = PPLC`) géolocalisées dans le référentiel, affichées sur une carte mondiale. La taille des cercles est proportionnelle à la population.

```js
{
  const mapBlock = document.createElement("div");
  mapBlock.className = "wda-chart-block";

  const titleEl = document.createElement("p");
  titleEl.className = "wda-chart-title";
  titleEl.textContent = "Capitales mondiales";

  const subtitleEl = document.createElement("p");
  subtitleEl.className = "wda-chart-subtitle";
  subtitleEl.textContent = `${capitals.length} capitales géolocalisées — cercles proportionnels à la population. Zoomez et déplacez la carte.`;

  const mapDiv = document.createElement("div");
  mapDiv.className = "vigilo-map";

  const sourceEl = document.createElement("p");
  sourceEl.className = "wda-chart-source";
  sourceEl.innerHTML =
    `Source : <a href="dataset/geonames">Dataset GeoNames</a> — données publiées par ` +
    `<a href="https://www.geonames.org/" target="_blank">GeoNames.org</a>.`;

  mapBlock.append(titleEl, subtitleEl, mapDiv, sourceEl);
  display(mapBlock);
  initBlockActions(mapBlock);

  // MapLibre map with circle markers sized by population
  maplibregl.setWorkerUrl(
    "https://unpkg.com/maplibre-gl@6.12.0/dist/maplibre-gl-worker.mjs",
  );

  const popValues = capitals.map((d) => d.population).filter((p) => p > 0);
  const popMax = Math.max(...popValues);

  const geojson = {
    type: "FeatureCollection",
    features: capitals.map((d) => ({
      type: "Feature",
      geometry: { type: "Point", coordinates: [d.longitude, d.latitude] },
      properties: {
        name: d.name,
        country_code: d.country_code,
        country: countryName.get(d.country_code) ?? d.country_code,
        population: d.population ?? 0,
        // radius 4–20px proportional to sqrt(population) for visual balance
        radius:
          d.population > 0
            ? Math.max(
                4,
                Math.min(20, 4 + 16 * Math.sqrt(d.population / popMax)),
              )
            : 4,
      },
    })),
  };

  const map = new maplibregl.Map({
    container: mapDiv,
    style: {
      version: 8,
      sources: {},
      layers: [
        {
          id: "background",
          type: "background",
          paint: { "background-color": "#d4e9f7" },
        },
      ],
      projection: { type: "globe" },
    },
    center: [10, 20],
    zoom: 1.2,
    minZoom: 0.5,
    maxZoom: 10,
    preserveDrawingBuffer: true,
    attributionControl: false,
  });

  mapDiv._wdaMap = map;

  await new Promise((resolve) => map.on("load", resolve));

  // Load world borders from world-atlas (same source as choropleth maps)
  const { feature } = await import(
    "https://cdn.jsdelivr.net/npm/topojson-client@3/+esm"
  );
  const world = await fetch(
    "https://cdn.jsdelivr.net/npm/world-atlas@2/countries-110m.json",
  ).then((r) => r.json());
  const worldGeojson = {
    ...feature(world, world.objects.countries),
    features: feature(world, world.objects.countries).features.map((f) => ({
      ...f,
      geometry: fixGeometry(f.geometry),
    })),
  };

  map.addSource("world", { type: "geojson", data: worldGeojson });
  map.addLayer({
    id: "countries-fill",
    type: "fill",
    source: "world",
    paint: { "fill-color": "#e8f0f7", "fill-opacity": 0.8 },
  });
  map.addLayer({
    id: "countries-border",
    type: "line",
    source: "world",
    paint: { "line-color": "#aabbcc", "line-width": 0.5, "line-opacity": 0.8 },
  });

  map.addSource("capitals", { type: "geojson", data: geojson });

  map.addLayer({
    id: "capitals-circle",
    type: "circle",
    source: "capitals",
    paint: {
      "circle-radius": ["get", "radius"],
      "circle-color": "#0c2c84",
      "circle-opacity": 0.75,
      "circle-stroke-width": 1,
      "circle-stroke-color": "#ffffff",
    },
  });

  // Dark popup (reuse geonames style)
  if (!document.getElementById("wda-geonames-popup-style")) {
    const style = document.createElement("style");
    style.id = "wda-geonames-popup-style";
    style.textContent = `
      .wda-geonames-popup .maplibregl-popup-content {
        background: #000; color: #e0e0e0;
        padding: 6px 10px; border-radius: 4px; font-size: 13px; line-height: 1.4;
      }
      .wda-geonames-popup .maplibregl-popup-tip { border-top-color: #000; border-bottom-color: #000; }
    `;
    document.head.appendChild(style);
  }

  const popup = new maplibregl.Popup({
    closeButton: false,
    closeOnClick: false,
    maxWidth: "200px",
    className: "wda-geonames-popup",
  });

  map.on("mousemove", "capitals-circle", (e) => {
    map.getCanvas().style.cursor = "pointer";
    const p = e.features[0].properties;
    const pop =
      p.population > 0
        ? `${Number(p.population).toLocaleString("fr-FR")} hab.`
        : "—";
    popup
      .setLngLat(e.lngLat)
      .setHTML(`<strong>${p.name}</strong><br>${p.country}<br>${pop}`)
      .addTo(map);
  });

  map.on("mouseleave", "capitals-circle", () => {
    map.getCanvas().style.cursor = "";
    popup.remove();
  });

  invalidation.then(() => map.remove());
}
```

## Dictionnaire des types de lieux

Définition des `feature_code` pour la classe P (lieux habités) utilisés dans le référentiel.

```js
display(
  html`<table class="wda-table">
    <thead>
      <tr>
        <th>Code</th>
        <th>Description</th>
        <th class="num">Entrées</th>
      </tr>
    </thead>
    <tbody>
      ${feature_codes.map(
        (d) =>
          html`<tr>
            <td><code>${d.feature_code}</code></td>
            <td>${FEATURE_CODE_LABELS[d.feature_code] ?? d.feature_code}</td>
            <td class="num">${Number(d.count).toLocaleString("fr-FR")}</td>
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
    <a class="see-also-link" href="geonames">🌍 Explorer les pays</a>
    <a class="see-also-link" href="dataset/geonames">📋 Dataset GeoNames</a>
  </div>
</div>
